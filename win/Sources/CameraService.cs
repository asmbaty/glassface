using System;
using System.Linq;
using System.Threading.Tasks;
using Windows.Devices.Enumeration;
using Windows.Graphics.Imaging;
using Windows.Media.Capture;
using Windows.Media.Capture.Frames;
using Windows.Media.MediaProperties;
using Windows.Storage.Streams;

namespace GlassFace;

/// <summary>A single BGRA8 camera frame (tightly packed, stride = Width * 4).</summary>
public sealed class CameraFrame
{
    public byte[] Bgra { get; }
    public int Width { get; }
    public int Height { get; }

    public CameraFrame(byte[] bgra, int width, int height)
    {
        Bgra = bgra;
        Width = width;
        Height = height;
    }
}

/// <summary>
/// Receives raw camera frames. Implemented by whatever wants to render or analyze them
/// (here, the overlay) — <see cref="CameraService"/> depends on this abstraction, not the
/// concrete type. Mirrors the macOS <c>FrameConsumer</c> protocol.
/// </summary>
public interface IFrameConsumer
{
    /// <summary>Called on a capture thread (off the UI thread).</summary>
    void Consume(CameraFrame frame);
}

/// <summary>
/// Owns the WinRT <see cref="MediaCapture"/> graph: device discovery, the frame reader,
/// and starting/stopping capture. Its single responsibility is supplying camera frames as
/// BGRA8 to its <see cref="FrameConsumer"/>. Knows nothing about windows or layers.
/// </summary>
public sealed class CameraService
{
    public IFrameConsumer? FrameConsumer { get; set; }

    private MediaCapture? _capture;
    private MediaFrameReader? _reader;

    private readonly object _gate = new();
    private byte[]? _buffer;                       // reused across frames to avoid churn
    private Windows.Storage.Streams.Buffer? _winrtBuffer;
    private bool _running;

    /// <summary>
    /// Builds the capture graph. Throws <see cref="UnauthorizedAccessException"/> if the user
    /// has denied camera access, or <see cref="NotSupportedException"/> if no camera is usable.
    /// </summary>
    public async Task ConfigureAsync()
    {
        var device = await FrontCameraAsync();    // throws NotSupportedException if none

        var settings = new MediaCaptureInitializationSettings
        {
            VideoDeviceId = device.Id,
            StreamingCaptureMode = StreamingCaptureMode.Video,
            MemoryPreference = MediaCaptureMemoryPreference.Cpu,   // CPU frames -> easy to blit
            SharingMode = MediaCaptureSharingMode.ExclusiveControl
        };

        _capture = new MediaCapture();
        await _capture.InitializeAsync(settings);  // triggers the OS camera-consent check

        var source = _capture.FrameSources.Values.FirstOrDefault(s =>
                         s.Info.SourceKind == MediaFrameSourceKind.Color)
                     ?? throw new NotSupportedException("No color camera frame source available.");

        _reader = await _capture.CreateFrameReaderAsync(source, MediaEncodingSubtypes.Bgra8);
        _reader.AcquisitionMode = MediaFrameReaderAcquisitionMode.Realtime;  // drop late frames
        _reader.FrameArrived += OnFrameArrived;
    }

    public Task StartAsync() => SetRunningAsync(true);

    /// <summary>Starts/stops the reader. Stopping turns the camera (and its privacy light) off.</summary>
    public async Task SetRunningAsync(bool running)
    {
        if (_reader is null) return;
        if (running && !_running)
        {
            await _reader.StartAsync();
            _running = true;
        }
        else if (!running && _running)
        {
            await _reader.StopAsync();
            _running = false;
        }
    }

    private void OnFrameArrived(MediaFrameReader sender, MediaFrameArrivedEventArgs args)
    {
        using var frame = sender.TryAcquireLatestFrame();
        var bitmap = frame?.VideoMediaFrame?.SoftwareBitmap;
        if (bitmap is null) return;

        // Normalize to opaque BGRA8 (matches the WriteableBitmap's Bgr32 layout).
        SoftwareBitmap? converted = null;
        if (bitmap.BitmapPixelFormat != BitmapPixelFormat.Bgra8 ||
            bitmap.BitmapAlphaMode != BitmapAlphaMode.Ignore)
        {
            converted = SoftwareBitmap.Convert(bitmap, BitmapPixelFormat.Bgra8, BitmapAlphaMode.Ignore);
            bitmap = converted;
        }

        try
        {
            int w = bitmap.PixelWidth, h = bitmap.PixelHeight, size = w * h * 4;
            lock (_gate)
            {
                if (_buffer is null || _buffer.Length != size)
                {
                    _buffer = new byte[size];
                    _winrtBuffer = new Windows.Storage.Streams.Buffer((uint)size);
                }

                bitmap.CopyToBuffer(_winrtBuffer);
                using var reader = DataReader.FromBuffer(_winrtBuffer);
                reader.ReadBytes(_buffer);

                // Consume synchronously (see OverlayCoordinator) so _buffer is safe to reuse.
                FrameConsumer?.Consume(new CameraFrame(_buffer, w, h));
            }
        }
        finally
        {
            converted?.Dispose();
        }
    }

    /// <summary>Prefers the front-facing (selfie) camera; falls back to any available camera.</summary>
    private static async Task<DeviceInformation> FrontCameraAsync()
    {
        var devices = await DeviceInformation.FindAllAsync(DeviceClass.VideoCapture);
        if (devices.Count == 0)
            throw new NotSupportedException("No camera device found.");

        return devices.FirstOrDefault(d => d.EnclosureLocation?.Panel == Panel.Front)
               ?? devices[0];
    }
}
