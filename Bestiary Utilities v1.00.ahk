; ##################
; Bestiary Utilities
; ##################

#IfWinActive Path of Exile
#NoEnv
#SingleInstance Force
#MaxThreadsPerHotkey 2
#If GetKeyState("CapsLock", "T")

SetMouseDelay 40
SetWorkingDir %A_ScriptDir%
SendMode Input

; --- Config & State ---
ConfigINI    := A_ScriptDir "\Config.ini"
F11_State    := 0
;CurrentGridIndex := 1   ; ← removed: unused
AutoRunning  := false
AutoIndex    := 1
F1_Mode      := 1        ; 1 = Beast STORING, 2 = Beast DELETING
DeleteToggle := false
SearchIndex  := 1

; Ensure INI file exists with required sections and defaults
if not FileExist(ConfigINI) {
    IniWrite, 0, %ConfigINI%, GridPos,    gridposX1
    IniWrite, 0, %ConfigINI%, GridPos,    gridposY1
    IniWrite, 0, %ConfigINI%, BeastPos,   posX
    IniWrite, 0, %ConfigINI%, BeastPos,   posY
    IniWrite, 0, %ConfigINI%, DeletePos,  posX
    IniWrite, 0, %ConfigINI%, DeletePos,  posY
    IniWrite, k m|id w|cic c|id v|le m|s, f|l pla|ld h|ul, f|d bra|n, f| cy|al, f|c sp|l hy|e rhe|c ti|c l|f a|c v, %ConfigINI%, BeastStrings, GoodBeasts
    IniWrite, cic m|x ma|c fr|c san|c sav|l cru|e vu|d ab|c sh| sq|c wa|c a|rric c|c fl|c ga|c goa, %ConfigINI%, BeastStrings, BadBeast1
    IniWrite, c gol|ma h|c pi|ic ta|c u|mal d|l q|l sco|l scr|l w|ne b|ne ch|ne co|ne re|ine rho, %ConfigINI%, BeastStrings, BadBeast2
}

; ─────────────────────────────────────────────
; On load: prompt user to press F12 for help
; (now shows current F1 mode)
; ─────────────────────────────────────────────
modeText := (F1_Mode = 1) ? "Beast STORING" : "Beast DELETING"
TrayTip, Bestiary Utilities Loaded, Press F12 for help.`nF1 mode: %modeText%, 5

; ─────────────────────────────────────────────
; F12: Show help window
; ─────────────────────────────────────────────
F12::Gosub, ShowHelp
return

ShowHelp:
    Gui, Help:Destroy
    Gui, Help:New, +AlwaysOnTop +ToolWindow, Bestiary Utilities
    HelpText =
    (
Hotkeys:
  F1 : Execute current mode routine
  F3 : Cycle search (Good/Bad1/Bad2/None)
  F5 : Toggle F1 mode (Storing/Deleting)
  F9 : Edit filter strings (Good/Bad1/Bad2)
 F11 : Initial setup of Beast/Delete/Grid positions – DO NOT SKIP –
    )
    Gui, Help:Add, Text, w400, %HelpText%
    Gui, Help:Show, AutoSize Center
return


; ──────────────────────────────────────────────────────────
; F11: store positions in sequence
;   1 → Beast‑DELETE
;   2 → Beast‑PICKUP
;   3 → Top‑Left inventory corner
;   4 → Bottom‑Right inventory corner + compute 12×5 grid
; ──────────────────────────────────────────────────────────
F11::
    if (F11_State = 0) {
        TrayTip, BEAST DELETE, Mouse over the "release X" on the Top Left beast and press F11, 2
        F11_State := 1
        return
    }
    if (F11_State = 1) {
        MouseGetPos, dX, dY
        IniWrite, %dX%, %ConfigINI%, DeletePos, posX
        IniWrite, %dY%, %ConfigINI%, DeletePos, posY
        TrayTip, Saved, Now mouse over the center of the Top Left beast and press F11, 2
        F11_State := 2
        return
    }
    if (F11_State = 2) {
        MouseGetPos, bX, bY
        IniWrite, %bX%, %ConfigINI%, BeastPos, posX
        IniWrite, %bY%, %ConfigINI%, BeastPos, posY
        TrayTip, Saved, Now mouse over TOP‑LEFT inventory corner and press F11, 2
        F11_State := 3
        return
    }
    if (F11_State = 3) {
        MouseGetPos, storedX, storedY
        TrayTip, Saved, Now mouse over BOTTOM‑RIGHT inventory corner and press F11, 2
        F11_State := 4
        return
    }
    if (F11_State = 4) {
        MouseGetPos, newX, newY
        ; Normalize rectangle
        left   := Min(storedX, newX)
        right  := Max(storedX, newX)
        top    := Min(storedY, newY)
        bottom := Max(storedY, newY)

        gridCols := 12
        gridRows := 5
        cellW    := (right - left)  / gridCols
        cellH    := (bottom - top)  / gridRows

        idx := 1
        Loop, %gridCols% {
            col := A_Index - 1
            Loop, %gridRows% {
                row     := A_Index - 1
                centerX := Round(left + col * cellW + cellW/2)
                centerY := Round(top  + row * cellH + cellH/2)
                IniWrite, %centerX%, %ConfigINI%, GridPos, gridposX%idx%
                IniWrite, %centerY%, %ConfigINI%, GridPos, gridposY%idx%
                idx++
            }
        }
        TrayTip, INVENTORY Grid Saved, Setup complete (12×5 positions), 2
        F11_State := 0
        return
    }
return

; ──────────────────────────────────────────────────────────
; F9: Popup GUI to edit GoodBeasts / BadBeast1 / BadBeast2
; ──────────────────────────────────────────────────────────
F9::
    Gui, New, +AlwaysOnTop +ToolWindow, Beast Filter Strings
    Gui, Add, Text,, Good beasts:
    Gui, Add, Edit,   vGoodBeasts  w300
    Gui, Add, Text,, Bad beast 1:
    Gui, Add, Edit,   vBadBeast1   w300
    Gui, Add, Text,, Bad beasts 2:
    Gui, Add, Edit,   vBadBeast2   w300
    Gui, Add, Button, gSaveBeastStr Default, OK
    Gui, Add, Button, gCancelBeastStr, Cancel

    ; Load current values
    IniRead, tmp, %ConfigINI%, BeastStrings, GoodBeasts
    GuiControl,, GoodBeasts, %tmp%
    IniRead, tmp, %ConfigINI%, BeastStrings, BadBeast1
    GuiControl,, BadBeast1, %tmp%
    IniRead, tmp, %ConfigINI%, BeastStrings, BadBeast2
    GuiControl,, BadBeast2, %tmp%

    Gui, Show, AutoSize Center, Set Beast-Filter Strings
return

SaveBeastStr:
    Gui, Submit, NoHide
    IniWrite, %GoodBeasts%,  %ConfigINI%, BeastStrings, GoodBeasts
    IniWrite, %BadBeast1%,   %ConfigINI%, BeastStrings, BadBeast1
    IniWrite, %BadBeast2%,   %ConfigINI%, BeastStrings, BadBeast2
    Gui, Destroy
    TrayTip, Saved, Beast filter strings updated, 2
return

CancelBeastStr:
    Gui, Destroy
return

; ──────────────────────────────────────────────────────────
; F5: Toggle F1 behavior mode
; ──────────────────────────────────────────────────────────
F5::
    F1_Mode := (F1_Mode = 1) ? 2 : 1
    modeText := (F1_Mode = 1) ? "Beast STORING" : "Beast DELETING"
    TrayTip, Mode Switched, F1 now in %modeText% mode, 2
return

; ──────────────────────────────────────────────────────────
; F3: Cycle filters, copy to clipboard, paste & TrayTip
; ──────────────────────────────────────────────────────────
F3::
    TrayTip  ; clear old
    Send, ^f
    Sleep, 100
    if (SearchIndex = 1) {
        key := "GoodBeasts", msg := "Good beasts"
    } else if (SearchIndex = 2) {
        key := "BadBeast1",  msg := "Bad beasts 1"
    } else if (SearchIndex = 3) {
        key := "BadBeast2",  msg := "Bad beasts 2"
    } else {
        Send, {Delete}
        TrayTip, Filter, No filter, 2
        SearchIndex := 1
        return
    }
    IniRead, str, %ConfigINI%, BeastStrings, %key%
    Clipboard := str
    ClipWait, 1
    Send, ^v
    TrayTip, Filter, %msg%, 2
    SearchIndex := (SearchIndex = 4) ? 1 : SearchIndex + 1
return

; ──────────────────────────────────────────────────────────
; F1: Dispatch based on mode
; ──────────────────────────────────────────────────────────
F1::
    if (F1_Mode = 1) {
        ; Beast STORING
        if (!AutoRunning) {
            AutoRunning := true
            AutoIndex   := 1
            SetTimer, DoCycle, 1500
            TrayTip, Starting Beast STORING…, 2
        } else {
            SetTimer, DoCycle, Off
            AutoRunning := false
            TrayTip, Stopped Beast STORING, 2
        }
    } else {
        ; Beast DELETING
        DeleteToggle := !DeleteToggle
        if (DeleteToggle) {
            TrayTip, Starting Beast DELETING, 2
        } else {
            TrayTip, Stopped Beast DELETING, 2
        }
        While DeleteToggle {
            Random, delay, 100, 150
            IniRead, dX, %ConfigINI%, DeletePos, posX, 0
            IniRead, dY, %ConfigINI%, DeletePos, posY, 0
            if (dX && dY) {
                MouseMove, %dX%, %dY%, 10
                Sleep, 50
                Click
            }
            Sleep, %delay%
            Send, {Enter}
            Sleep, %delay%
        }
    }
return

; ──────────────────────────────────────────────────────────
; Beast STORING (break → beast → grid + clicks)
; ──────────────────────────────────────────────────────────
DoCycle:
    if (AutoIndex > 50) {
        SetTimer, DoCycle, Off
        AutoRunning := false
        AutoIndex   := 1
        TrayTip, Finished Beast STORING, 2
        return
    }
    ; 1) BREAK (56–60) + right‑click
    group    := Floor((AutoIndex-1)/10) + 1
    breakIdx := 55 + group
    IniRead, bx, %ConfigINI%, GridPos, gridposX%breakIdx%, 0
    IniRead, by, %ConfigINI%, GridPos, gridposY%breakIdx%, 0
    if (bx && by) {
        MouseMove, %bx%, %by%, 10
        Sleep, 200
        Click, Right
        Sleep, 200
    }
    ; 2) Beast pickup + left‑click
    IniRead, bX, %ConfigINI%, BeastPos, posX, 0
    IniRead, bY, %ConfigINI%, BeastPos, posY, 0
    if (bX && bY) {
        MouseMove, %bX%, %bY%, 10
        Sleep, 200
        Click, Left
        Sleep, 200
    }
    ; 3) Grid slot (1–50) + left‑click
    IniRead, gx, %ConfigINI%, GridPos, gridposX%AutoIndex%, 0
    IniRead, gy, %ConfigINI%, GridPos, gridposY%AutoIndex%, 0
    if (gx && gy) {
        MouseMove, %gx%, %gy%, 10
        Sleep, 200
        Click, Left
        Sleep, 200
    }
    AutoIndex++
return
