#include "pch.h"
#include "GhostIcon.h"

using namespace Gdiplus;

namespace glassface
{
    static ULONG_PTR g_gdiplusToken = 0;

    static void EnsureGdiplus()
    {
        if (g_gdiplusToken == 0)
        {
            GdiplusStartupInput input;
            GdiplusStartup(&g_gdiplusToken, &input, nullptr);
        }
    }

    HICON CreateGhostIcon(int size)
    {
        EnsureGdiplus();

        Bitmap bitmap(size, size, PixelFormat32bppARGB);
        Graphics g(&bitmap);
        g.SetSmoothingMode(SmoothingModeAntiAlias);
        g.Clear(Color(0, 0, 0, 0));   // transparent

        float s = static_cast<float>(size);
        float gw = s * 0.72f, gh = s * 0.82f;
        float gx = (s - gw) / 2.0f;
        float gTop = s * 0.09f;        // GDI+ origin is top-left (y grows down)
        float domeR = gw / 2.0f;
        float domeCY = gTop + domeR;
        const int bumps = 3;
        float bumpW = gw / bumps;
        float bumpR = bumpW / 2.0f;
        float waveY = gTop + gh - bumpR;

        GraphicsPath body;
        body.AddArc(gx, gTop, gw, gw, 180.0f, 180.0f);              // dome across the top
        body.AddLine(gx + gw, domeCY, gx + gw, waveY);              // right side
        for (int i = 0; i < bumps; ++i)                            // scalloped bottom, right→left
        {
            float cx = gx + gw - bumpW - i * bumpW;
            body.AddArc(cx, waveY - bumpR, bumpW, bumpW, 0.0f, 180.0f);
        }
        body.CloseFigure();

        SolidBrush fill(Color(240, 245, 245, 245));
        Pen pen(Color(200, 40, 40, 40), s * 0.05f);
        g.FillPath(&fill, &body);
        g.DrawPath(&pen, &body);

        float eyeY = domeCY + s * 0.02f;
        float eyeDX = gw * 0.18f;
        float eyeR = s * 0.075f;
        SolidBrush eye(Color(220, 40, 40, 40));
        g.FillEllipse(&eye, s / 2.0f - eyeDX - eyeR, eyeY - eyeR, 2 * eyeR, 2 * eyeR);
        g.FillEllipse(&eye, s / 2.0f + eyeDX - eyeR, eyeY - eyeR, 2 * eyeR, 2 * eyeR);

        HBITMAP color = nullptr;
        bitmap.GetHBITMAP(Color(0, 0, 0, 0), &color);
        HBITMAP mask = CreateBitmap(size, size, 1, 1, nullptr);

        ICONINFO info{};
        info.fIcon = TRUE;
        info.hbmColor = color;
        info.hbmMask = mask;
        HICON icon = CreateIconIndirect(&info);

        DeleteObject(color);
        DeleteObject(mask);
        return icon;
    }
}
