#pragma once

// Win32
#include <windows.h>
#include <shellapi.h>
#include <unknwn.h>
#include <restrictederrorinfo.h>
#include <hstring.h>
#include <objbase.h>
#include <gdiplus.h>

// C++ standard library
#include <memory>
#include <vector>
#include <functional>
#include <unordered_map>
#include <atomic>
#include <cmath>

// C++/WinRT — Windows (system) namespaces used by the camera pipeline.
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Devices.Enumeration.h>
#include <winrt/Windows.Graphics.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Media.Capture.h>
#include <winrt/Windows.Media.Capture.Frames.h>
#include <winrt/Windows.Media.MediaProperties.h>
#include <winrt/Windows.UI.h>

// C++/WinRT — WinUI 3 (Windows App SDK) namespaces.
#include <winrt/Microsoft.UI.h>
#include <winrt/Microsoft.UI.Dispatching.h>
#include <winrt/Microsoft.UI.Windowing.h>
#include <winrt/Microsoft.UI.Xaml.h>
#include <winrt/Microsoft.UI.Xaml.Controls.h>
#include <winrt/Microsoft.UI.Xaml.Markup.h>
#include <winrt/Microsoft.UI.Xaml.Media.h>
#include <winrt/Microsoft.UI.Xaml.Media.Imaging.h>

// Native interop to reach each Window's HWND.
#include <microsoft.ui.xaml.window.h>
