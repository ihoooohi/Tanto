#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================================
; 初始化与全局状态
; ==========================================================
SetCapsLockState "AlwaysOff"
global IsNavMode := false
global IsShiftSticky := false
global HasMoved := false 

UpdateStatus() {
    if (IsNavMode) {
        status := IsShiftSticky ? "🔥 选中模式 (VISUAL)" : "💡 移动模式 (NORMAL)"
        ToolTip(status)
    } else {
        ToolTip("✅ 已回归编辑模式")
        SetTimer(() => ToolTip(), 800)
    }
}

; 【核心清理函数】增加参数：shouldCollapse (是否需要按右键合并选区)
ExitNav(shouldCollapse := true) {
    global IsNavMode := false
    global IsShiftSticky := false
    global HasMoved := false
    
    Send("{Shift Up}") 
    Sleep(20)
    
    ; 如果是复制(y)或手动退出，需要 Right 来合并选区
    ; 如果是删除(d)或粘贴(p)，选区已经没了，不需要 Right
    if (shouldCollapse) {
        Send("{Right}") 
    }
    
    UpdateStatus()
}

; ==========================================================
; 【模式切换】
; ==========================================================
CapsLock::
{
    global IsNavMode := !IsNavMode
    if (IsNavMode) {
        global IsShiftSticky := true 
        global HasMoved := false 
        UpdateStatus()
    } else {
        ExitNav(true) ; 手动退出需要合并选区
    }
}

; 组合键微调
CapsLock & i::Send("{Blind}{Up}")
CapsLock & k::Send("{Blind}{Down}")
CapsLock & j::Send("{Blind}{Left}")
CapsLock & l::Send("{Blind}{Right}")
CapsLock & u::Send("{Blind}{Home}")
CapsLock & o::Send("{Blind}{End}")

; ==========================================================
; 【全域快捷键】
; ==========================================================
^i::Send(IsNavMode && IsShiftSticky ? "+{Up 5}" : "{Up 5}")
^k::Send(IsNavMode && IsShiftSticky ? "+{Down 5}" : "{Down 5}")
^j::Send(IsNavMode && IsShiftSticky ? "^+{Left}" : "^{Left}")
^l::Send(IsNavMode && IsShiftSticky ? "^+{Right}" : "^{Right}")

+CapsLock::CapsLock

; ==========================================================
; 【导航模式专属逻辑】
; ==========================================================
#HotIf IsNavMode

; --- 直接按 h 选中整行 ---
h:: {
    global HasMoved := true 
    Send("{Shift Up}")
    Send("{Home 2}") 
    Sleep(20)
    Send("+{End}") 
}

; --- 核心 1：多态 d 键 ---
d:: {
    ; 情况 1：如果有选区（比如按了 h 之后）
    if (HasMoved) {
        Send("{Del}")       ; 直接删除选区，不需要 ^x (剪切) 那么重
        ExitNav(false)      ; <--- 关键：删除后不需要 Right 换行
        return
    }

    ; 情况 2：原地等待 dh, dw, db
    ih := InputHook("L1 T0.5", "{Esc}{CapsLock}")
    ih.Start(), ih.Wait()
    
    if (ih.Input == "h") {        ; dh: 依然保留删除整行的“宏”
        Send("{Shift Up}{Home 2}")
        Sleep(20)
        Send("+{End}{BackSpace}{Delete}")
        ExitNav(false) 
    } else if (ih.Input == "w") { 
        Send("^{Del}")
        ExitNav(false)
    } else if (ih.Input == "b") { 
        Send("^{BackSpace}")
        ExitNav(false)
    }
}

; --- 核心 2：多态 c 键 ---
c:: {
    if (HasMoved) {
        Send("^c")
        ExitNav(true) ; 复制完文字还在，需要 Right 合并选区
        return
    }
    ih := InputHook("L1 T0.5", "{Esc}{CapsLock}")
    ih.Start(), ih.Wait()
    if (ih.Input == "h") {        ; ch: 复制整行
        Send("{Shift Up}{Home 2}")
        Sleep(20)
        Send("+{End}^c")
        ExitNav(true) 
    } else if (ih.Input == "w") { ; cw: 复制后一个词
        Send("{Shift Up}^+{Right}^c")
        ExitNav(true)
    } else if (ih.Input == "b") { ; cb: 复制前一个词
        Send("{Shift Up}^+{Left}^c")
        ExitNav(true)
    }
}

; --- 基础移动 ---
*i:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Up}")
}
*k:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Down}")
}
*j:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Left}")
}
*l:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Right}")
}
*u:: { 
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Home}")
}
*o:: { 
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{End}")
}

; --- 统一动作 ---
y::
^c:: { 
    Send("^c")       
    Sleep(100)       
    ExitNav(true)        
}

p::
^v:: { 
    Send("^v")
    ExitNav(false) ; 粘贴后不需要 Right
}

x::
^x:: { 
    Send("^x")
    ExitNav(false) 
}

v:: {
    global IsShiftSticky := !IsShiftSticky
    global HasMoved := false 
    if (!IsShiftSticky) Send("{Shift Up}{Right}")
    UpdateStatus()
}

n:: {
    Send("{End}{Enter}")
    ExitNav(false)
}

z::Send("^z")
r::Send("^y")
Esc::ExitNav(true)

#HotIf