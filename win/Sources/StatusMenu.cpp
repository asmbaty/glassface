#include "pch.h"
#include "StatusMenu.h"
#include "GhostIcon.h"
#include <string>

namespace glassface
{
    static const wchar_t* kClassName = L"GlassFaceTrayWindow";
    static const UINT kTrayCallback = WM_APP + 1;
    static const UINT kTrayId = 1;

    enum Command : UINT { CmdNone = 0, CmdIncrease = 1, CmdDecrease = 2, CmdQuit = 3 };

    void StatusMenu::Install()
    {
        WNDCLASSEXW wc{};
        wc.cbSize = sizeof(wc);
        wc.lpfnWndProc = &StatusMenu::WndProc;
        wc.hInstance = GetModuleHandleW(nullptr);
        wc.lpszClassName = kClassName;
        RegisterClassExW(&wc);

        // A hidden top-level window (not message-only, so TrackPopupMenu's foreground rules work).
        m_window = CreateWindowExW(0, kClassName, L"GlassFace", WS_POPUP,
                                   0, 0, 0, 0, nullptr, nullptr, wc.hInstance, this);

        m_icon = CreateGhostIcon(32);

        m_nid.cbSize = sizeof(m_nid);
        m_nid.hWnd = m_window;
        m_nid.uID = kTrayId;
        m_nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
        m_nid.uCallbackMessage = kTrayCallback;
        m_nid.hIcon = m_icon;
        wcscpy_s(m_nid.szTip, L"GlassFace");
        Shell_NotifyIconW(NIM_ADD, &m_nid);
    }

    void StatusMenu::UpdateOpacity(float opacity)
    {
        m_opacityPercent = static_cast<int>(std::lround(opacity * 100.0f));
    }

    void StatusMenu::ShowMenu()
    {
        HMENU menu = CreatePopupMenu();

        std::wstring opacityLabel = L"Opacity: " + std::to_wstring(m_opacityPercent) + L"%";
        AppendMenuW(menu, MF_STRING | MF_GRAYED, CmdNone, opacityLabel.c_str());
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
        AppendMenuW(menu, MF_STRING, CmdIncrease, L"Increase Opacity\tCtrl+Alt+Shift +");
        AppendMenuW(menu, MF_STRING, CmdDecrease, L"Decrease Opacity\tCtrl+Alt+Shift -");
        AppendMenuW(menu, MF_STRING | MF_GRAYED, CmdNone, L"Set Opacity: Ctrl+Alt+Shift 1-9, 0 = 100%");
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
        AppendMenuW(menu, MF_STRING, CmdQuit, L"Quit GlassFace\tCtrl+Alt+Shift Q");

        POINT cursor{};
        GetCursorPos(&cursor);
        SetForegroundWindow(m_window);   // required so the menu dismisses correctly

        UINT chosen = TrackPopupMenu(menu, TPM_RIGHTBUTTON | TPM_RETURNCMD | TPM_NONOTIFY,
                                     cursor.x, cursor.y, 0, m_window, nullptr);
        PostMessageW(m_window, WM_NULL, 0, 0);
        DestroyMenu(menu);

        switch (chosen)
        {
            case CmdIncrease: if (onIncrease) onIncrease(); break;
            case CmdDecrease: if (onDecrease) onDecrease(); break;
            case CmdQuit:     if (onQuit)     onQuit();     break;
            default: break;
        }
    }

    LRESULT CALLBACK StatusMenu::WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
    {
        if (msg == WM_CREATE)
        {
            auto cs = reinterpret_cast<CREATESTRUCTW*>(lParam);
            SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
            return 0;
        }

        if (msg == kTrayCallback)
        {
            UINT mouse = LOWORD(lParam);
            if (mouse == WM_LBUTTONUP || mouse == WM_RBUTTONUP || mouse == WM_CONTEXTMENU)
            {
                auto self = reinterpret_cast<StatusMenu*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
                if (self) self->ShowMenu();
            }
            return 0;
        }

        return DefWindowProcW(hwnd, msg, wParam, lParam);
    }

    StatusMenu::~StatusMenu()
    {
        if (m_window)
        {
            Shell_NotifyIconW(NIM_DELETE, &m_nid);
            DestroyWindow(m_window);
            m_window = nullptr;
        }
        if (m_icon)
        {
            DestroyIcon(m_icon);
            m_icon = nullptr;
        }
    }
}
