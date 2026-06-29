#pragma once

#include <windows.h>

namespace glassface
{
    // Draws the little ghost used for the tray icon (the same motif as the macOS menu-bar
    // glyph) and returns an HICON. Drawn light with a dark outline so it reads on both light
    // and dark taskbars. Caller owns the returned icon (DestroyIcon when done).
    HICON CreateGhostIcon(int size = 32);
}
