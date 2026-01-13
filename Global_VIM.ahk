#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================================
; 初始化与全局状态
; ==========================================================
SetCapsLockState "AlwaysOff"
global IsNavMode := false
global IsShiftSticky := false
global HasMoved := false 
global IsHookActive := false 

UpdateStatus() {
    if (IsNavMode) {
        status := IsShiftSticky ? "🔥 选中模式 (VISUAL)" : "💡 移动模式 (NORMAL)"
        ToolTip(status)
    } else {
        ToolTip("✅ 编辑模式")
        SetTimer(() => ToolTip(), 800)
    }
}

; 【核心清理】退出导航模式
ExitNav(shouldCollapse := true) {
    global IsNavMode := false
    global IsShiftSticky := false
    global IsHookActive := false
    
    Send("{Shift Up}{Ctrl Up}") ; 确保状态彻底重置
    Sleep(20)
    
    if (shouldCollapse && HasMoved) {
        Send("{Left}") ; 采用左移坍缩，防止跳行
    }
    
    global HasMoved := false
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
        ExitNav(HasMoved ? true : false) 
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

; --- 独立按键逻辑 (只有在非 Hook 状态下触发) ---
#HotIf IsNavMode and !IsHookActive

; 1. 选中整行
h:: {
    global HasMoved := true 
    Send("{Shift Up}")
    Send("{Home 2}") 
    Sleep(20)
    Send("+{End}") 
}

; 2. 【新增】不断向后选中单词
w:: {
    global HasMoved := true
    ; 根据当前是否是 Visual 模式决定是否带 Shift
    Send(IsShiftSticky ? "^+{Right}" : "^{Right}")
}

; 3. 【新增】不断向前选中单词
b:: {
    global HasMoved := true
    Send(IsShiftSticky ? "^+{Left}" : "^{Left}")
}

#HotIf IsNavMode
; --- 核心 1：多态 d 键 ---
d:: {
    if (HasMoved) {
        Send("{Del}")
        ExitNav(false)
        return
    }
    
    global IsHookActive := true 
    ih := InputHook("L1 T0.5", "{Esc}{CapsLock}")
    ih.Start(), ih.Wait()
    global IsHookActive := false 
    
    if (ih.Input == "h") {
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
        ExitNav(true)
        return
    }
    
    global IsHookActive := true
    ih := InputHook("L1 T0.5", "{Esc}{CapsLock}")
    ih.Start(), ih.Wait()
    global IsHookActive := false
    
    if (ih.Input == "h") {
        Send("{Shift Up}{Home 2}")
        Sleep(20)
        Send("+{End}^c")
        ExitNav(true) 
    } else if (ih.Input == "w") { 
        Send("{Shift Up}^+{Right}^c")
        ExitNav(true)
    } else if (ih.Input == "b") { 
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
    ExitNav(false)
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