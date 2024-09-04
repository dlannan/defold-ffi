local ffi = package.preload.ffi()

-- Load in the user32 runtime library into the ffi.C interface
local user32 	    = ffi.load( "user32.dll" )
local kernel32      = ffi.load( "kernel32.dll" )

ffi.cdef[[

typedef uint32_t BOOL;
typedef int32_t  DWORD;
typedef uint64_t HWND;
typedef uint64_t  HMENU;
typedef uint64_t  HINSTANCE;
typedef uint64_t  HMODULE;
typedef uint64_t  HANDLE;

typedef const char * LPCSTR;
typedef void * LPVOID;

typedef intptr_t (__stdcall *WNDPROC)(HWND hwnd, unsigned int message, uintptr_t wparam, intptr_t lparam);

typedef struct WNDCLASSEXA {
    uint32_t cbSize, style;
    WNDPROC lpfnWndProc;
    int32_t cbClsExtra, cbWndExtra;
    HINSTANCE hInstance;
    HANDLE hIcon;
    HANDLE hCursor;
    HANDLE hbrBackground;
    const char* lpszMenuName;
    const char* lpszClassName;
    HANDLE hIconSm;
} WNDCLASSEXA;


HMODULE GetModuleHandleA(LPCSTR lpModuleName);
uint16_t 	RegisterClassExA(const WNDCLASSEXA*);

HWND CreateWindowExA(
        DWORD     dwExStyle,
        LPCSTR    lpClassName,
        LPCSTR    lpWindowName,    
        DWORD     dwStyle,
        int32_t       x,
        int32_t       y,
        int32_t       nWidth,
        int32_t       nHeight,
        HWND      hWndParent,
        HMENU     hMenu,
        HINSTANCE hInstance,
        LPVOID    lpParam
    );
intptr_t 	DefWindowProcA(HWND hwnd, uint32_t msg, uintptr_t wparam, uintptr_t lparam);

BOOL DestroyWindow( HWND hWnd );
BOOL UpdateWindow( HWND hWnd );
BOOL ShowWindow( HWND hWnd, int  nCmdShow );
DWORD GetLastError();
        
void Sleep(uint32_t ms);
]]

-- Reference -- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow
local wnd_show = {
    SW_HIDE  =    0, --	Hides the window and activates another window.
    SW_SHOWNORMAL  = 1, 
    SW_NORMAL = 1, --	Activates and displays a window. If the window is minimized, maximized, or arranged, the system restores it to its original size and position. An application should specify this flag when displaying the window for the first time.
    SW_SHOWMINIMIZED =    2, --	Activates the window and displays it as a minimized window.
    SW_SHOWMAXIMIZED = 3, 
    SW_MAXIMIZE = 3, --	Activates the window and displays it as a maximized window.
    SW_SHOWNOACTIVATE = 4, --	Displays a window in its most recent size and position. This value is similar to SW_SHOWNORMAL, except that the window is not activated.
    SW_SHOW = 5,
}

-- Reference -- https://learn.microsoft.com/en-us/windows/win32/winmsg/window-styles
local wnd_style = {
    WS_BORDER           = 0x00800000,
    WS_CHILD            = 0x40000000,
    WS_CHILDWINDOW      = 0x40000000,
    WS_DLGFRAME	        = 0x00400000,
    WS_OVERLAPPED	    = 0x00000000,
    WS_POPUP	        = 0x80000000,
    WS_CAPTION          = 0x00C00000,
    WS_SYSMENU 		    = 0x00080000,
    WS_THICKFRAME 	    = 0x00040000,
}
wnd_style.WS_POPUPWINDOW = bit.bor(wnd_style.WS_POPUP, wnd_style.WS_BORDER)
wnd_style.WS_OVERLAPPEDWINDOW = bit.bor(bit.bor(bit.bor(wnd_style.WS_OVERLAPPED, wnd_style.WS_CAPTION), wnd_style.WS_SYSMENU), wnd_style.WS_THICKFRAME)

-- Reference -- https://learn.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
local wnd_ex_style = {
    WS_EX_ACCEPTFILES    = 0x00000010,
    WS_EX_APPWINDOW      = 0x00040000,
    WS_EX_CLIENTEDGE     = 0x00000200,
    WS_EX_COMPOSITED     = 0x02000000, 
    WS_EX_LAYERED        = 0x00080000,
    WS_EX_TOPMOST        = 0x00000008,
}
local ex_settings = wnd_ex_style.WS_EX_TOPMOST

-- Some of the parameters of CreateWindow are not required (optional) 
--   see: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-createwindowa

function WndProc(hwnd, msg, wparam, lparam)
    return user32.DefWindowProcA(hwnd, msg, wparam, lparam)
end

local function makeWindow()
    local hInstance = kernel32.GetModuleHandleA(nil)
    pprint("hInstance: ", hInstance)
    
    local CLASS_NAME = 'TestWindowClass'

    local classstruct = {}
    classstruct.cbSize 		    = ffi.sizeof( "WNDCLASSEXA" )
    classstruct.lpfnWndProc     = WndProc
    classstruct.hInstance 		= hInstance	
    classstruct.lpszClassName 	= CLASS_NAME
    local wndclass = ffi.new( "WNDCLASSEXA", classstruct )	    

    -- Dodgy way to make sure we only register once for this process run.
    if(reg == nil) then 
        reg = user32.RegisterClassExA( wndclass )
    
        if (reg == 0) then
            error('error #' .. kernel32.GetLastError())
        end
    end    
    pprint("Registered Class.")

    local hwnd = user32.CreateWindowExA( ex_settings, CLASS_NAME, "My FFI Window", wnd_style.WS_OVERLAPPEDWINDOW, 10, 10, 300, 200, 0,0, hInstance, nil )
    if (hwnd == 0) then
        print("Unable to create window.")
        pprint("Error: "..tostring(kernel32.GetLastError()))
    else
        pprint(hwnd)
        user32.ShowWindow(hwnd, wnd_show.SW_SHOW)
        ffi.C.Sleep(2000)
        user32.DestroyWindow(hwnd)
        pprint("Window closed....")
    end
end

return {
    makeWindow = makeWindow
}