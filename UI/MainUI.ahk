#Requires AutoHotkey v2.0

global version := "1.0.0"
global MainUI := ""
global GridControls := []
global ScrollY := 0
global MaxScroll := 0

#Include ..\Utilities\Standard.ahk

WM_MOUSEWHEEL := 0x020A
OnMessage(WM_MOUSEWHEEL, HandleMouseWheel)

CreateUI() {
    global MainUI

	if MainUI
		MainUI.Destroy()

    MainUI := Gui("+Resize", "Jeebus' Wuthering Waves Tracker")
    MainUI.MarginX := 10
    MainUI.MarginY := 10

; Menu bar
	local MBar := MenuBar()
	MainUI.MenuBar := MBar

	; Script menu
	local ScriptMenu := Menu()
	ScriptMenu.Add("Reload", reloadScript.Bind())
	ScriptMenu.Add("About", (*) => MsgBox("Jeebus' Wuthering Waves Tracker (JWWT)`nVersion " version "`n`nA simple Wuthering Waves tracker built with AutoHotkey v2.0.19.`n`n(c) 2026 WoahItsJeebus", "About", "Iconi"))
	MBar.Add("Script", ScriptMenu)

    local header := MainUI.Add("Text",, "Resonators")
    MainUI.Add("Text", "xm w" 650 - (MainUI.MarginX*2) " 0x10")

	MainUI.OnEvent("Size", (*) => redrawControls())
	MainUI.Show("w650 h600")

    return MainUI
}

HandleMouseWheel(wParam, lParam, msg, hwnd) {
    global MainUI, ScrollY, MaxScroll, GridControls

    ; Only scroll if the message is for our GUI
    if canScroll(hwnd)

    ; Extract wheel delta (high word of wParam)
    local delta := 0
	delta := (wParam >> 16) & 0xFFFF || 0

    ; Convert signed 16-bit
    if (delta & 0x8000)
        delta := -(0x10000 - delta)

    local scrollStep := delta > 0 ? -40 : 40

    ScrollY := Clamp(ScrollY + scrollStep, 0, MaxScroll)

    for item in GridControls {
        newY := item.baseY - ScrollY
        item.ctrl.Move(, newY)
		item.overlay.Move(, newY)
    }

	redrawControls()
}

PopulateGrid(items) {
    global GridControls, ScrollY, MaxScroll, MainUI

    iconSize := 96
    padding := 10
    columns := 6
    GridTopOffset := 60

    GridControls := []
    ScrollY := 0

    row := 0
    col := 0

    for item in items {
        x := col == 0 ? padding : (padding + (col * (iconSize + padding)))
        y := row * (iconSize + padding) + GridTopOffset

        pic := MainUI.Add("Picture"
            , "x" x " y" y " w" iconSize " h" iconSize
            , item.icon)

        overlay := MainUI.Add("Text"
            , "x" x " y" y " w" iconSize " h" iconSize " cBlack BackgroundBlack")

        ; overlay.Value := 100 ; fully filled = fully black

        state := {
            id: item.id,
            ctrl: pic,
            overlay: overlay,
            baseY: y,
            owned: false
        }

		overlay.Visible := state.owned ? false : true

        pic.OnEvent("Click", ToggleOwned.Bind(state))
		overlay.OnEvent("Click", ToggleOwned.Bind(state))
		
        GridControls.Push(state)

        col++
        if (col >= columns) {
            col := 0
            row++
        }
    }

    totalHeight := (row + 1) * (iconSize + padding)
    visibleHeight := 500

    MaxScroll := Max(0, totalHeight - visibleHeight)

	redrawControls()
}

ToggleOwned(state, *) {
    state.owned := !state.owned

    if (state.owned) {
        state.overlay.Visible := false
	}
    else {
        state.overlay.Visible := true
	}
}

OnMouseWheel(guiObj, ctrlObj, info) {
    global ScrollY, MaxScroll, GridControls

    delta := info.Delta > 0 ? -40 : 40
    ScrollY := Clamp(ScrollY + delta, 0, MaxScroll)

    for item in GridControls {
        newY := item.baseY - ScrollY
        item.ctrl.Move(, newY)
    }
}

Clamp(val, min, max) {
    return val < min ? min : val > max ? max : val
}

canScroll(hwnd) {
	global MainUI, GridControls
	local scrollable := false
	if (hwnd == MainUI.Hwnd)
        return true
    else {
		for item in GridControls
			if (hwnd == item.ctrl.Hwnd)
				return true
	}
	
	return false
}

redrawControls() {
	global GridControls
	for item in GridControls
		item.ctrl.Redraw()
}

reloadScript(*) {
	global MainUI
	local MainGui := MainUI ? MainUI : ""

	; Hide the GUI to avoid flicker
	if MainGui
		MainGui.Destroy()

	; Reload the script
	Reload()
}