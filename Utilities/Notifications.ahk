#SingleInstance Force
#Include TimeLib.ahk

global intWindowColor := "2e2e2e"
global intControlColor := "3c3c3c"
global intProgressBarColor := "4a90e2"
global ControlTextColor := "ffffff"
global linkColor := "4a90e2"

class Notifications {
	static new(message, options := Map()) {
		static notificationGUIs := [] ; Store notification GUIs in a static array
		static config := Map(
			"HeaderColor", "ff9696",
			"BodyColor", "2e2e2e",
			"HighlightColor", "4a90e2",

			"HeaderFont", "Ink Free",
			"BodyFont", "Consolas",

			"HeaderFontWeight", 600,
			"BodyFontWeight", 400,

			"HeaderFontSize", 14,
			"BodyFontSize", 12,

			"ButtonFontSize", 12,
			"ButtonHeight", 25
		)

		static defaultOptions := Map(
			"Type", "info",
			"OnYes", "",
			"OnNo", "",
			"Duration", 4000,
			"Title", "Notification",
			"Width", 350,
			"Height", 150,
		)

		mergeMaps(default, override) {
			; Merge two maps, with override taking precedence
			for key, value in override {
				default[key] := value
			}
			return default
		}
		options := mergeMaps(defaultOptions, options)
		options := mergeMaps(config, options)
		
		; Colors
		global intWindowColor
		global intControlColor
		global intProgressBarColor
		global ControlTextColor
		global linkColor

		local popupWidth := options.Has("Width") ? options["Width"] : 350
		local popupHeight := options.Has("Height") ? options["Height"] : 150
		local popupMarginX := 10
		local popupMarginY := 10
		
		; Move currently existing notifications up and begin moving next notification in the queue
		if notificationGUIs.Length >= 3
			closeNotification(notificationGUIs[1])

		for i, UI_Hwnd in notificationGUIs {
			if UI_Hwnd && IsWindowVisibleToUser(UI_Hwnd) {
				WinGetPos(&x, &y, &w, &h, UI_Hwnd)
				
				if WinExist(UI_Hwnd)
					try SetTimer(SlideGUI(UI_Hwnd, x, y - (popupHeight + (popupMarginY*3)),25), 0, 1)
				; UI.Move(x, y - (popupHeight + popupMarginY), w, h)
			}
		}

		; Setup dimensions
		MonitorGetWorkArea(, &monLeft, &monTop, &monRight, &monBottom)
		screenW := monRight - monLeft
		screenH := monBottom - monTop

		; Extract options values
		local type     := options["Type"]     || "info"
		local duration := options["Duration"] || 4000
		local onYes    := options["OnYes"]    || ""
		local onNo     := options["OnNo"]     || ""
		local title    := options["Title"]    || "Notification"
		local width    := options["Width"]    || popupWidth
		local height   := options["Height"]   || popupHeight
		local headerColor  := options["HeaderColor"] || config["HeaderColor"]
		local bodyColor    := options["BodyColor"]    || config["BodyColor"]
		local highlightColor := options["HighlightColor"] || config["HighlightColor"]
		local HeaderFontWeight := options["HeaderFontWeight"] || config["HeaderFontWeight"]
		local HeaderFontSize   := options["HeaderFontSize"]   || config["HeaderFontSize"]
		local buttonHeight := options["ButtonHeight"] || config["ButtonHeight"]
		local HeaderFont := options["HeaderFont"] || config["HeaderFont"]
		local BodyFont   := options["BodyFont"]   || config["BodyFont"]
		local ButtonFontSize := options["ButtonFontSize"] || config["ButtonFontSize"]
		
		local btnOk := "", btnYes := "", btnNo := "", titleLabel := "", messageBox := ""

		; === Outer shell GUI (invisible container with rounded corners) ===
		local NotiShellGui := Gui("+AlwaysOnTop +OwnDialogs -Caption +ToolWindow +LastFound +")
		local id := NotiShellGui.Hwnd
		notificationGUIs.Push(NotiShellGui.Hwnd)
		
		; === Inner GUI (contains actual controls and styles) ===
		local NotiInnerGui := Gui("+Parent" NotiShellGui.Hwnd " -Caption +ToolWindow +LastFound +E0x20")

		NotiInnerGui.MarginX := popupMarginX
		NotiInnerGui.MarginY := popupMarginY

		NotiInnerGui.BackColor := intWindowColor
		NotiInnerGui.SetFont("s" ButtonFontSize " c" ControlTextColor)
		
		innerWidth := popupWidth - (popupMarginX * 2)
		innerHeight := popupHeight - (popupMarginY * 2)

		; Create controls
		local titleWidth := MeasureTextWidth(NotiInnerGui, title)
		titleLabel := NotiInnerGui.Add("Text", "y" popupMarginY/2 " Center vNotificationTitle w" innerWidth*0.95 " h" buttonHeight, title)
		messageBox := NotiInnerGui.Add("Text", "Center xm w" innerWidth-popupMarginX " h" popupHeight - buttonHeight - (popupMarginY*2), message)

		titleLabel.SetFont("s16 c" (options["HeaderColor"] or config.HeaderColor) " w" options["HeaderFontWeight"] or config.HeaderFontWeight, options["HeaderFont"] or config.HeaderFont)
		
		if (type = "yesno") {
			btnYes := NotiInnerGui.Add("Button", "xm h" buttonHeight " w" (innerWidth-(NotiInnerGui.MarginX*2.5))/2, "Yes")
			btnNo  := NotiInnerGui.Add("Button", "x+m h" buttonHeight " w" (innerWidth-(NotiInnerGui.MarginX*2.5))/2, "No")

			btnYes.OnEvent("Click", (*) => (
				closeNotification(),
				(onYes is Func || onYes is BoundFunc) ? onYes.Call() : ""
			))
			btnNo.OnEvent("Click", (*) => (
				closeNotification(),
				(onNo is Func || onNo is BoundFunc) ? onNo.Call() : ""
			))
		} else if (type = "ok") {
			btnOk := NotiInnerGui.Add("Button", "xm+" innerWidth*0.35 " y+" popupHeight - buttonHeight - (popupMarginX*2) " h" buttonHeight " w" innerWidth*0.25, "OK")
			btnOk.OnEvent("Click", (*) => (
				closeNotification(),
				(onYes is Func || onYes is BoundFunc) ? onYes.Call() : ""
			))
		} else {
			btnOk := NotiInnerGui.Add("Button", "Background" intWindowColor " xm+" innerWidth*0.35 " ym+" popupHeight - (popupMarginY*2) " h" buttonHeight " w" innerWidth*0.25, "OK")
			btnOk.OnEvent("Click", (*) => (
				closeNotification(),
				(onYes is Func || onYes is BoundFunc) ? onYes.Call() : ""
			))
			btnOk.SetFont("s" ButtonFontSize " c" ControlTextColor, BodyFont)
		}

		; Position centered vertically, flush right horizontally
		shellX := monRight - popupWidth - 25
		shellY := monTop + ((screenH - popupHeight) / 1.25)
		
		finalHeight := popupHeight + (btnNo || btnYes || btnOk ? buttonHeight : 0)

		; Show both GUIs
		NotiShellGui.BackColor := getActiveStatusColor(highlightColor)
		SetTimer(updateTheme, 250)
		WinSetTransparent(0, NotiShellGui.Hwnd)

		NotiShellGui.Show("NoActivate x" shellX " y" shellY " w" popupWidth " h" finalHeight)
		NotiInnerGui.Show("NoActivate w" innerWidth " h" finalHeight)
		
		NotiInnerGui.OnEvent("Escape", closeNotification)
		NotiShellGui.OnEvent("Escape", closeNotification)

		; Apply rounded corners to shell only
		SetRoundedCorners(NotiShellGui.Hwnd, 16)
		SetRoundedCorners(NotiInnerGui.Hwnd, 16)

		; Animate fade in
		AnimateFadeIn(NotiShellGui.Hwnd)

		; Fade out timer
		fadeDuration := (type = "yesno") ? 30000 : (type = "ok") ? 5000 : duration
		SetTimer(() => closeNotification(), -fadeDuration)

		getActiveStatusColor(forcedColor := false) {
			if forcedColor
				return forcedColor
			return "84e5f7"
		}

		local lastThemeUpdate := tick()
		updateTheme(*) {
			if !IsSet(activeNotification) or !NotiShellGui or !NotiInnerGui
				return SetTimer(updateTheme, 0)
			
			if NotiShellGui.BackColor != getActiveStatusColor(highlightColor)
				NotiShellGui.BackColor := getActiveStatusColor(highlightColor)
			
			if (tick() - lastThemeUpdate) < 1
				return
			lastThemeUpdate := tick()
			
			if titleLabel
				titleLabel.Redraw()
			if messageBox
				messageBox.Redraw()
			; ApplyThemeToGui(NotiInnerGui, LoadThemeFromINI(currentTheme))
		}
		
		local isRemoved := false
		closeNotification(optionalCtrl := "") {
			; Remove from notification list
			try
				if optionalCtrl
					removeFromArray(notificationGUIs, optionalCtrl)
				else
					removeFromArray(notificationGUIs, id)

			try
				if optionalCtrl
					AnimateFadeOut(optionalCtrl)
				else
					AnimateFadeOut(id)
			
			try
				SetTimer(updateTheme, 0)

			try 
				SetTimer(closeNotification, 0)

			isRemoved := true
			; NotiShellGui := unset
			; NotiInnerGui := unset
			return NotiShellGui
		}
	}
}

IsWindowVisibleToUser(hWnd) {
	; Ensure it's a number and not null
	if !IsInteger(hWnd) || hWnd = 0
		return false

	; Ensure the HWND exists and is a real window
	if !DllCall("IsWindow", "ptr", hWnd)
		return false

	; Check visibility
	return DllCall("IsWindowVisible", "ptr", hWnd, "int")
}

MeasureTextWidth(ctrl, text) {
	static SIZE := Buffer(8, 0)  ; holds width (int32) and height (int32)
	local L_hwnd := ctrl.Hwnd
	hdc := DllCall("GetDC", "ptr", L_hwnd, "ptr")
	
	hFont := SendMessage(0x31, 0, 0, ctrl) ; WM_GETFONT
	if hFont
		DllCall("SelectObject", "ptr", hdc, "ptr", hFont)

	DllCall("GetTextExtentPoint32", "ptr", hdc, "str", text, "int", StrLen(text), "ptr", SIZE)
	DllCall("ReleaseDC", "ptr", L_hwnd, "ptr", hdc)

	width := NumGet(SIZE, 0, "int")
	return width
}

AnimateFadeIn(hwnd, duration := 75) {
    steps := 30
    interval := duration // steps
    stepAmount := 255 // steps

    loop steps {
        opacity := Round(A_Index * (255 / steps))
        WinSetTransparent(opacity, hwnd)
        Sleep(interval)
    }

    ; Final adjustment to max opacity
    WinSetTransparent(255, hwnd)
}

AnimateFadeOut(hwnd, duration := 75) {
    steps := 30
    interval := duration // steps
    stepAmount := 255 // steps
	
    loop steps {
        opacity := Round(255 - (A_Index * (255 / steps)))
        WinSetTransparent(opacity, hwnd)
        Sleep(interval)
    }

    ; Ensure completely invisible, then close
    WinSetTransparent(0, hwnd)
    WinClose(hwnd)
}

SetRoundedCorners(hwnd, radius := 12) {
    ; Handle GUI object
	WinGetPos(&x,&y, &w, &h, hwnd)
	hRgn := DllCall("CreateRoundRectRgn"
		, "int", 0, "int", 0
		, "int", w, "int", h
		, "int", radius, "int", radius
		, "ptr")
	
	DllCall("SetWindowRgn"
		, "ptr", hwnd
		, "ptr", hRgn
		, "int", true)
}

removeFromArray(array, item) {
	for i, value in array {
		if (value == item) {
			array.RemoveAt(i)
			break
		}
	}
	return array
}

SlideGUI(GUIHwnd, x, y, duration := 200) {
	local startX, startY, endX, endY
	local GUIObj := GuiFromHwnd(GUIHwnd)
	GUIObj.GetPos(&startX, &startY, &w, &h)
	
	endX := x
	endY := y

	; Calculate the distance to move
	deltaX := endX - startX
	deltaY := endY - startY

	; Calculate the number of steps based on the duration and speed
	steps := 20
	stepDuration := duration / steps

	; Move the GUI in small increments
	Loop steps {
		startX += deltaX / steps
		startY += deltaY / steps
		GUIObj.Move(startX, startY)
		Sleep stepDuration
	}
}