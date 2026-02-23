#Requires AutoHotkey v2.0.19

; Global alias so you can write Enum.KeyCode, like Roblox
global RbxEnum := Enum

/**
 * @class Enum
 * @summary Roblox-style Enum implementation for AutoHotkey v2.
 * @description
 * Provides Enum types and items similar to Roblox's Enum system.
 */
class Enum {
    static Types := Map()  ; "KeyCode" -> EnumType instance

    ; -----------------------------
    ;   EnumItem
    ; -----------------------------
    class EnumItem {
        __New(enumType, name, value, extra := unset) {
            this.EnumType := enumType
            this.Name     := name
            this.Value    := value

            ; Optional extra data, e.g. Map("Key", "k")
            if IsSet(extra) && extra is Map {
                for k, v in extra
                    this.%k% := v
            }
        }

        ; String representation – keep it simple:
        ToString() {
            return this.Name
        }
    }

    ; -----------------------------
    ;   EnumType
    ; -----------------------------
    class EnumType {
        __New(name) {
            this.Name    := name
            this.Items   := []      ; array of EnumItem
            this.ByName  := Map()   ; name  -> EnumItem
            this.ByValue := Map()   ; value -> EnumItem
		}

        AddItem(name, value, extra := unset) {
            item := RbxEnum.EnumItem(this, name, value, extra)
            this.Items.Push(item)
            this.ByName[name]  := item
            this.ByValue[value] := item

            ; Allow Enum.KeyCode.K
            this.%name% := item
            return item
        }

        FromName(name) {
			local newName := this.ByName.Has(name) ? this.ByName[name] : unset
            return newName
        }

        FromValue(val) {
			local newVal := this.ByValue.Has(val) ? this.ByValue[val] : unset
            return newVal
        }

        ; Enum.KeyCode("K") or Enum.KeyCode(5)
        Call(arg, *) {
            if IsNumber(arg)
                return this.FromValue(arg)
            else
                return this.FromName(arg)
        }

        ; for item in Enum.KeyCode
        _NewEnum() {
            return this.Items._NewEnum()
        }
    }

    ; -----------------------------
    ;   Define helper
    ; -----------------------------
    ; Usage patterns:
    ;   Enum.Define("Foo")                                ; empty enum
    ;   Enum.Define("Foo", "A", "B", "C")                 ; auto values 0,1,2
    ;   Enum.Define("Foo", ["A", 10], ["B", 20])          ; explicit values
    ;   Enum.Define("Foo", ["K", Map("Key","k")])      ; auto value with extra
    ;   Enum.Define("Foo", ["Space", 32, Map("Key","{Space}")])
    static Define(name, spec*) {
        t := RbxEnum.EnumType(name)
        RbxEnum.Types[name] := t
        ; Allow Enum.KeyCode, Enum.UserInputType, etc.
        RbxEnum.%name% := t

        if (spec.Length = 0)
            return t

        nextVal := 0
        for i, entry in spec {
            itemName := ""
            val      := ""
            local extra    := ""

            if (entry is Array) {
                itemName := entry[1]

                if (entry.Length = 1) {
                    ; ["Name"]
                    val := nextVal
                } else if (entry.Length = 2) {
                    ; ["Name", valueOrExtra]
                    if (entry[2] is Map) {
                        val   := nextVal
                        extra := entry[2]
                    } else {
                        val := entry[2]
                    }
                } else {
                    ; ["Name", value, extra]
                    val   := entry[2]
                    extra := entry[3]
                }
            } else {
                ; "Name"
                itemName := entry
                val := nextVal
            }

            t.AddItem(itemName, val, extra)
            nextVal := val + 1
        }
        return t
    }

    static GetType(name) {
		local newName := RbxEnum.Types.Has(name) ? RbxEnum.Types[name] : unset
        return newName
    }
}

IsEnumItem(obj) {
    return IsObject(obj)
        && obj.HasProp("EnumType")
        && obj.HasProp("Name")
        && obj.HasProp("Value")
}

GetKeyToken(enumItem) {
    return IsEnumItem(enumItem) && enumItem.HasProp("Key")
        ? enumItem.Key
        : ""
}

; ---- UserInputType (subset, extend as needed) ----
Enum.Define(
    "UserInputType"
    , "MouseButton1"
    , "MouseButton2"
    , "MouseButton3"
    , "MouseWheel"
    , "MouseMovement"
    , "Keyboard"
    , "Touch"
    , "Gamepad1"
    , "Gamepad2"
    , "Gamepad3"
    , "Gamepad4"
)

; ---- KeyCode (subset, extend as needed) ----
Enum.Define(
	"KeyCode"
	; Letter keys
	, ["A", Map("Key", "a")]
	, ["B", Map("Key", "b")]
	, ["C", Map("Key", "c")]
	, ["D", Map("Key", "d")]
	, ["E", Map("Key", "e")]
	, ["F", Map("Key", "f")]
	, ["G", Map("Key", "g")]
	, ["H", Map("Key", "h")]
	, ["I", Map("Key", "i")]
	, ["J", Map("Key", "j")]
	, ["K", Map("Key", "k")]
	, ["L", Map("Key", "l")]
	, ["M", Map("Key", "m")]
	, ["N", Map("Key", "n")]
	, ["O", Map("Key", "o")]
	, ["P", Map("Key", "p")]
	, ["Q", Map("Key", "q")]
	, ["R", Map("Key", "r")]
	, ["S", Map("Key", "s")]
	, ["T", Map("Key", "t")]
	, ["U", Map("Key", "u")]
	, ["V", Map("Key", "v")]
	, ["W", Map("Key", "w")]
	, ["X", Map("Key", "x")]
	, ["Y", Map("Key", "y")]
	, ["Z", Map("Key", "z")]
	
	; Number keys
	, ["0", Map("Key", "0")]
	, ["1", Map("Key", "1")]
	, ["2", Map("Key", "2")]
	, ["3", Map("Key", "3")]
	, ["4", Map("Key", "4")]
	, ["5", Map("Key", "5")]
	, ["6", Map("Key", "6")]
	, ["7", Map("Key", "7")]
	, ["8", Map("Key", "8")]
	, ["9", Map("Key", "9")]
	
	; Whitespace keys
	, ["Space", 32, Map("Key", "{Space}")]
	, ["Enter", 13, Map("Key", "{Enter}")]
	, ["LeftShift", 160, Map("Key", "+")]
	, ["RightShift", 161, Map("Key", "+")]
	, ["LeftControl", 162, Map("Key", "^")]
	, ["RightControl", 163, Map("Key", "^")]
	, ["LeftAlt", 164, Map("Key", "!")]
	, ["RightAlt", 165, Map("Key", "!")]

	; Arrow keys
	, ["Up", 38, Map("Key", "{Up}")]
	, ["Down", 40, Map("Key", "{Down}")]
	, ["Left", 37, Map("Key", "{Left}")]
	, ["Right", 39, Map("Key", "{Right}")]

	; Special keys
	, ["Escape", 27, Map("Key", "{Esc}")]
	, ["Tab", 9, Map("Key", "{Tab}")]
	, ["Backspace", 8, Map("Key", "{Backspace}")]
	, ["Delete", 46, Map("Key", "{Del}")]
	, ["Insert", 45, Map("Key", "{Insert}")]
	, ["Home", 36, Map("Key", "{Home}")]
	, ["End", 35, Map("Key", "{End}")]
	, ["PageUp", 33, Map("Key", "{PgUp}")]
	, ["PageDown", 34, Map("Key", "{PgDn}")]
	, ["CapsLock", 20, Map("Key", "{CapsLock}")]
	, ["NumLock", 144, Map("Key", "{NumLock}")]
	, ["ScrollLock", 145, Map("Key", "{ScrollLock}")]
	, ["PrintScreen", 44, Map("Key", "{PrintScreen}")]
	, ["Pause", 19, Map("Key", "{Pause}")]
	, ["Backquote", 192, Map("Key", "``")]
	, ["Minus", 189, Map("Key", "-")]
	, ["Equals", 187, Map("Key", "=")]
	, ["LeftBracket", 219, Map("Key", "[")]
	, ["RightBracket", 221, Map("Key", "]")]
	, ["Backslash", 220, Map("Key", "\")]
	, ["Semicolon", 186, Map("Key", ";")]
	, ["Apostrophe", 222, Map("Key", "'")]
	, ["Comma", 188, Map("Key", ",")]
	, ["Period", 190, Map("Key", ".")]
	, ["Slash", 191, Map("Key", "/")]
	
	; Numpad keys
	, ["Numpad0", 96, Map("Key", "{Numpad0}")]
	, ["Numpad1", 97, Map("Key", "{Numpad1}")]
	, ["Numpad2", 98, Map("Key", "{Numpad2}")]
	, ["Numpad3", 99, Map("Key", "{Numpad3}")]
	, ["Numpad4", 100, Map("Key", "{Numpad4}")]
	, ["Numpad5", 101, Map("Key", "{Numpad5}")]
	, ["Numpad6", 102, Map("Key", "{Numpad6}")]
	, ["Numpad7", 103, Map("Key", "{Numpad7}")]
	, ["Numpad8", 104, Map("Key", "{Numpad8}")]
	, ["Numpad9", 105, Map("Key", "{Numpad9}")]
	, ["NumpadMultiply", 106, Map("Key", "{NumpadMult}")]
	, ["NumpadAdd", 107, Map("Key", "{NumpadAdd}")]
	, ["NumpadSubtract", 109, Map("Key", "{NumpadSub}")]
	, ["NumpadDecimal", 110, Map("Key", "{NumpadDot}")]
	, ["NumpadDivide", 111, Map("Key", "{NumpadDiv}")]

	; Function keys
	, ["F1", 112, Map("Key", "{F1}")]
	, ["F2", 113, Map("Key", "{F2}")]
	, ["F3", 114, Map("Key", "{F3}")]
	, ["F4", 115, Map("Key", "{F4}")]
	, ["F5", 116, Map("Key", "{F5}")]
	, ["F6", 117, Map("Key", "{F6}")]
	, ["F7", 118, Map("Key", "{F7}")]
	, ["F8", 119, Map("Key", "{F8}")]
	, ["F9", 120, Map("Key", "{F9}")]
	, ["F10", 121, Map("Key", "{F10}")]
	, ["F11", 122, Map("Key", "{F11}")]
	, ["F12", 123, Map("Key", "{F12}")]
)