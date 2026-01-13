#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================================
; 初始化与全局状态
; ==========================================================
SetCapsLockState "AlwaysOff"
global IsNavMode := false
global IsShiftSticky := false

; 状态提示气泡
UpdateStatus() {
    if (IsNavMode) {
        status := IsShiftSticky ? "🔥 选中模式 (VISUAL)" : "💡 导航模式 (NORMAL)"
        ToolTip(status)
    } else {
        ToolTip("⌨️ 编辑模式 (INSERT)")
        SetTimer(() => ToolTip(), 100000)
    }
}

; 彻底退出所有模式
ExitNav() {
    global IsNavMode := false
    global IsShiftSticky := false
    UpdateStatus()
}

; ==========================================================
; 【核心新增逻辑】CapsLock 作为临时组合键 (在任何模式下生效)
; 当你按住 CapsLock 并按下这些键时，它只是一次性的方向操作，不会切换模式
; ==========================================================

CapsLock & i::Send("{Blind}{Up}")
CapsLock & k::Send("{Blind}{Down}")
CapsLock & j::Send("{Blind}{Left}")
CapsLock & l::Send("{Blind}{Right}")
CapsLock & u::Send("{Blind}{Home}")
CapsLock & o::Send("{Blind}{End}")
CapsLock & w::Send("{Blind}^{Right}") ; 临时跳单词
CapsLock & b::Send("{Blind}^{Left}")  ; 临时跳单词

; ==========================================================
; 【模式切换逻辑】CapsLock 作为单击键
; AHK 机制：如果 CapsLock 已经作为上面的组合键使用了，这里的逻辑在松开时【不会】触发
; ==========================================================
CapsLock::
{
    global IsNavMode := !IsNavMode
    global IsShiftSticky := false
    UpdateStatus()
}

; ==========================================================
; 【全局快捷键】
; ==========================================================
^Enter::
{
    Send("{End}{Enter}")
    if (IsNavMode)
        ExitNav()
}

+CapsLock::CapsLock ; Shift + CapsLock 切换大写灯

; ==========================================================
; 【导航模式专属逻辑】
; ==========================================================
#HotIf IsNavMode

; 直接按 IJKL (无需 CapsLock)
*i::Send "{Blind}" (IsShiftSticky ? "+" : "") "{Up}"
*k::Send "{Blind}" (IsShiftSticky ? "+" : "") "{Down}"
*j::Send "{Blind}" (IsShiftSticky ? "+" : "") "{Left}"
*l::Send "{Blind}" (IsShiftSticky ? "+" : "") "{Right}"
*u::Send "{Blind}" (IsShiftSticky ? "+" : "") "{Home}"
*o::Send "{Blind}" (IsShiftSticky ? "+" : "") "{End}"
*w::Send "{Blind}" (IsShiftSticky ? "^+" : "^") "{Right}"
*b::Send "{Blind}" (IsShiftSticky ? "^+" : "^") "{Left}"

v:: ; 粘滞选中
{
    global IsShiftSticky := !IsShiftSticky
    UpdateStatus()
}

y:: ; 复制
{
    Send("^c")
    global IsShiftSticky := false
    UpdateStatus()
}

x:: ; 剪切
{
    Send("^x")
    global IsShiftSticky := false
    UpdateStatus()
}

p:: ; 粘贴
{
    Send("^v")
    global IsShiftSticky := false
    UpdateStatus()
}

d::Send("{End}+{Home}{BackSpace}{Del}") 
n::Send("{End}{Enter}")
z::Send("^z")
r::Send("^y")
m::Send("^{Left}^+{Right}")

Esc::ExitNav()

#HotIf

; 物理按键监听同步
~^c::
~^v::
~^x::
{
    if (IsNavMode) {
        global IsShiftSticky := false
        UpdateStatus()
    }
}