#include "pch.h"
#include "HotKeyCenter.h"

namespace glassface
{
    static const wchar_t* kClassName = L"GlassFaceHotKeyWindow";
    static const UINT kModifiers = MOD_CONTROL | MOD_ALT | MOD_SHIFT | MOD_NOREPEAT;

    void HotKeyCenter::Install()
    {
        WNDCLASSEXW wc{};
        wc.cbSize = sizeof(wc);
        wc.lpfnWndProc = &HotKeyCenter::WndProc;
        wc.hInstance = GetModuleHandleW(nullptr);
        wc.lpszClassName = kClassName;
        RegisterClassExW(&wc);   // harmless if already registered

        // Message-only window: receives posted messages (incl. WM_HOTKEY), never shown.
        m_window = CreateWindowExW(0, kClassName, L"", 0, 0, 0, 0, 0,
                                   HWND_MESSAGE, nullptr, wc.hInstance, this);
    }

    void HotKeyCenter::Bind(UINT virtualKey, std::function<void()> handler)
    {
        if (!m_window) return;
        int id = m_nextId++;
        if (RegisterHotKey(m_window, id, kModifiers, virtualKey))
            m_handlers.emplace(id, std::move(handler));
    }

    LRESULT CALLBACK HotKeyCenter::WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
    {
        if (msg == WM_CREATE)
        {
            auto cs = reinterpret_cast<CREATESTRUCTW*>(lParam);
            SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
            return 0;
        }

        if (msg == WM_HOTKEY)
        {
            auto self = reinterpret_cast<HotKeyCenter*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
            if (self)
            {
                auto it = self->m_handlers.find(static_cast<int>(wParam));
                if (it != self->m_handlers.end() && it->second)
                    it->second();   // already on the UI thread
            }
            return 0;
        }

        return DefWindowProcW(hwnd, msg, wParam, lParam);
    }

    HotKeyCenter::~HotKeyCenter()
    {
        if (!m_window) return;
        for (auto const& [id, _] : m_handlers)
            UnregisterHotKey(m_window, id);
        DestroyWindow(m_window);
        m_window = nullptr;
    }
}
