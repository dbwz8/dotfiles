#Requires AutoHotkey v2.0

; Use Caps Lock as Zellij's Ctrl-F1 leader in Windows Terminal, including WSL tabs.
#HotIf WinActive("ahk_exe WindowsTerminal.exe") || WinActive("ahk_exe WindowsTerminalPreview.exe")
CapsLock::Send "^{F1}"
#HotIf
