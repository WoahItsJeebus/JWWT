#Requires AutoHotkey v2.0
#SingleInstance Force
#Include UI\MainUI.ahk

; --- Global scroll variables ---
global ScrollY := 0
global MaxScroll := 0
global GridControls := []

; Hook mouse wheel globally
WM_MOUSEWHEEL := 0x020A
OnMessage(WM_MOUSEWHEEL, HandleMouseWheel)

; Create UI
mainUI := CreateUI()

; Show window at fixed size
mainUI.Show("w650 h600")

; ----- Dummy Data Injection -----

items := []
index := 1

Loop 40 {
    items.Push({
        id: "test" index,
        icon: "icons\placeholder.png"
    })
    index++
}

PopulateGrid(items)