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

; 【核心改进】彻底退出导航模式并确保取消选中
ExitNav() {
    global IsNavMode := false
    ; 如果退出时还在选中状态，按一下右键释放选区
    if (IsShiftSticky) {
        Send("{Right}")
    }
    global IsShiftSticky := false
    UpdateStatus()
}

; ==========================================================
; 【模式切换与微调】
; ==========================================================

; 1. 模式切换：单击 CapsLock
CapsLock::
{
    global IsNavMode := !IsNavMode
    
    ; 【关键逻辑】如果是从导航/选中模式切回编辑模式
    if (!IsNavMode) {
        if (IsShiftSticky) {
            Send("{Right}") ; 取消选中
        }
    }
    
    global IsShiftSticky := false ; 重置选中状态
    UpdateStatus()
}

; 2. 组合键逻辑：按住 CapsLock + IJKL 时作为临时方向键
CapsLock & i::Send("{Blind}{Up}")
CapsLock & k::Send("{Blind}{Down}")
CapsLock & j::Send("{Blind}{Left}")
CapsLock & l::Send("{Blind}{Right}")
CapsLock & u::Send("{Blind}{Home}")
CapsLock & o::Send("{Blind}{End}")

; ==========================================================
; 【全域快捷键】无论模式，逻辑一致
; ==========================================================

; 1. [区块级] 5行跳跃
^i::Send(IsNavMode && IsShiftSticky ? "+{Up 5}" : "{Up 5}")
^k::Send(IsNavMode && IsShiftSticky ? "+{Down 5}" : "{Down 5}")

; 2. [单词级] 左右跳单词
^j::Send(IsNavMode && IsShiftSticky ? "^+{Left}" : "^{Left}")
^l::Send(IsNavMode && IsShiftSticky ? "^+{Right}" : "^{Right}")

; 3. [行级] 智能换行：自动取消选中并退出模式
^Enter::
{
    Send("{End}{Enter}")
    ExitNav()
}

; 4. 大写锁定补偿
+CapsLock::CapsLock

; ==========================================================
; 【导航模式专属逻辑】
; ==========================================================
#HotIf IsNavMode

; [一级导航：基础移动]
*i::Send "{Blind}" (IsShiftSticky ? "+" : "") "{Up}"
*k::Send "{Blind}" (IsShiftSticky ? "+" : "") "{Down}"
*j::Send "{Blind}" (IsShiftSticky ? "+" : "") "{Left}"
*l::Send "{Blind}" (IsShiftSticky ? "+" : "") "{Right}"
*u::Send "{Blind}" (IsShiftSticky ? "+" : "") "{Home}"
*o::Send "{Blind}" (IsShiftSticky ? "+" : "") "{End}"

; [选中模式开关]
v:: {
    global IsShiftSticky := !IsShiftSticky
    if (!IsShiftSticky) {
        Send("{Right}") ; 手动关闭 v 时取消选中
    }
    UpdateStatus()
}

; [动作处理] 执行后均回到 Normal 导航状态
y:: {
    Send("^c")
    global IsShiftSticky := false
    UpdateStatus()
}
x:: {
    Send("^x")
    global IsShiftSticky := false
    UpdateStatus()
}
p:: {
    Send("^v")
    global IsShiftSticky := false
    UpdateStatus()
}

; [程序员连招]
d::Send("{End}+{Home}{BackSpace}{Del}") 
n::Send("{End}{Enter}")
z::Send("^z")
r::Send("^y")
m::Send("^{Left}^+{Right}")

Esc::ExitNav()

#HotIf

; ==========================================================
; 物理监听 (同步状态)
; ==========================================================
~^c::
~^v::
~^x::
{
    if (IsNavMode) {
        global IsShiftSticky := false
        UpdateStatus()
    }
}