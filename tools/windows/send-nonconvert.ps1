Start-Sleep -Milliseconds 200

function Send-NonConvert {
  Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class Keyboard {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    public const byte VK_NONCONVERT = 0x1D;
    public const uint KEYEVENTF_KEYUP = 0x0002;
}
"@ -ErrorAction SilentlyContinue

  [Keyboard]::keybd_event([Keyboard]::VK_NONCONVERT, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 30
  [Keyboard]::keybd_event([Keyboard]::VK_NONCONVERT, 0, [Keyboard]::KEYEVENTF_KEYUP, [UIntPtr]::Zero)
}

Send-NonConvert
