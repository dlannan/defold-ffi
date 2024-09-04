local ffi = package.preload.ffi()

-- Load in the user32 runtime library into the ffi.C interface
local user32 	    = ffi.load( "user32.dll" )

-- Declare some methods for use in script
ffi.cdef[[
int MessageBoxA(uint32_t hWnd, const char * lpText, const char * lpCaption, uint32_t uType);
]]

-- Some MSDN constants 
local mb_type = {
	MB_ABORTRETRYIGNORE 	= 0x00000002, -- The message box contains three push buttons: Abort, Retry, and Ignore.
	MB_CANCELTRYCONTINUE	= 0x00000006, -- The message box contains three push buttons: Cancel, Try Again, Continue. Use this message box type instead of MB_ABORTRETRYIGNORE.
	MB_HELP = 0x00004000, -- Adds a Help button to the message box. When the user clicks the Help button or presses F1, the system sends a WM_HELP message to the owner.
	MB_OK = 0x00000000, -- The message box contains one push button: OK. This is the default.
	MB_OKCANCEL = 0x00000001, -- The message box contains two push buttons: OK and Cancel.
	MB_RETRYCANCEL = 0x00000005, -- The message box contains two push buttons: Retry and Cancel.
	MB_YESNO = 0x00000004, -- The message box contains two push buttons: Yes and No.
	MB_YESNOCANCEL = 0x00000003, -- The message box contains three push buttons: Yes, No, and Cancel.
}

local result = user32.MessageBoxA( 0, "Test", "Heading", mb_type.MB_OK)
pprint(result)
result = user32.MessageBoxA( 0, "Test", "Heading", mb_type.MB_RETRYCANCEL)
pprint(result)