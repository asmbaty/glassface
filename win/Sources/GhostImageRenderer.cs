using System.Drawing;
using System.Drawing.Drawing2D;

namespace GlassFace;

/// <summary>
/// Draws the little ghost used for the tray icon (the same motif as the macOS menu-bar
/// glyph). Stateless rendering helper — one job, no dependencies. Drawn light with a dark
/// outline so it reads on both light and dark taskbars.
/// </summary>
internal static class GhostImageRenderer
{
    internal static Icon TrayIcon(int size = 32)
    {
        using var bitmap = new Bitmap(size, size);
        using (var g = Graphics.FromImage(bitmap))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.Clear(Color.Transparent);

            float s = size;
            float gw = s * 0.72f, gh = s * 0.82f;
            float gx = (s - gw) / 2f;
            float gTop = s * 0.09f;                 // GDI+ origin is top-left (y grows down)
            float domeR = gw / 2f;
            float domeCY = gTop + domeR;
            const int bumps = 3;
            float bumpW = gw / bumps;
            float bumpR = bumpW / 2f;
            float waveY = gTop + gh - bumpR;

            using var body = new GraphicsPath();
            // Dome across the top.
            body.AddArc(gx, gTop, gw, gw, 180f, 180f);
            body.AddLine(gx + gw, domeCY, gx + gw, waveY);
            // Three scalloped bumps along the bottom, right to left.
            for (int i = 0; i < bumps; i++)
            {
                float cx = gx + gw - bumpW - i * bumpW;
                body.AddArc(cx, waveY - bumpR, bumpW, bumpW, 0f, 180f);
            }
            body.CloseFigure();

            using var fill = new SolidBrush(Color.FromArgb(240, 245, 245, 245));
            using var pen = new Pen(Color.FromArgb(200, 40, 40, 40), s * 0.05f);
            g.FillPath(fill, body);
            g.DrawPath(pen, body);

            // Two eyes.
            float eyeY = domeCY + s * 0.02f;
            float eyeDX = gw * 0.18f;
            float eyeR = s * 0.075f;
            using var eyeBrush = new SolidBrush(Color.FromArgb(220, 40, 40, 40));
            foreach (float dx in new[] { -eyeDX, eyeDX })
                g.FillEllipse(eyeBrush, s / 2f + dx - eyeR, eyeY - eyeR, 2 * eyeR, 2 * eyeR);
        }

        return Icon.FromHandle(bitmap.GetHicon());
    }
}
