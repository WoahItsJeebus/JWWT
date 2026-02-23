#Requires AutoHotkey v2.0.19
#Include EventListeners.ahk

;===========================================================
; Instance module for Roblox-style ValueObjects
; Usage:
;   local n := Instance.new("NumberValue")
;   local s := Instance.new("StringValue", someParent)
;
; Integration with Event system:
;   ; Option A (explicit factory):
;   Instance.SetSignalFactory(Event.CreateSignal.Bind(Event))
;
;   ; Option B (auto-detect):
;   ; If a global class `Event` with static CreateSignal()
;   ; exists, Instance will call Event.CreateSignal()
;   ; automatically when creating signals.
;
; If no Event system is available, a built-in Signal/Connection
; fallback is used.
;===========================================================

class Instance
{
    ; Factory for creating Signal objects. Must be a callable (Func/BoundFunc)
    ; that returns an object with at least:
    ;   Connect(callback)
    ;   Fire(args*)
    static SignalFactory := ""

    ;-------------------------------------------------------
    ; Public API
    ;-------------------------------------------------------
    static new(className, parent := "")
    {
        if (className = "")
            throw Error("Instance.new requires a className")

        cls := StrLower(className)

        switch cls
        {
        case "numbervalue":
            return NumberValue(parent)
        case "intvalue":
            return IntValue(parent)
        case "boolvalue":
            return BoolValue(parent)
        case "stringvalue":
            return StringValue(parent)
        case "objectvalue":
            return ObjectValue(parent)
        case "vector2value":
            return Vector2Value(parent)
        case "color3value":
            return Color3Value(parent)
        default:
            throw Error("Instance.new: Unsupported class '" className "'")
        }
    }

    ; Allow wiring in your own Signal factory (from your event module)
    static SetSignalFactory(factory)
    {
        if !IsObject(factory)
            throw Error("SetSignalFactory expects a callable object (Func/BoundFunc)")
        Instance.SignalFactory := factory
    }

    ;-------------------------------------------------------
    ; Internal: create a Signal, using:
    ;   1) Explicit SignalFactory if set
    ;   2) Global Event.CreateSignal() if available
    ;   3) Built-in fallback Signal implementation
    ;-------------------------------------------------------
    static _CreateSignal()
    {
        ; 1) Explicit factory provided by user
        if IsObject(Instance.SignalFactory)
            return Instance.SignalFactory.Call()

        ; 2) Auto-detect global Event.CreateSignal()
        ;    Safe try/catch in case Event or Event.CreateSignal
        ;    is undefined.
        try {
            if IsObject(Event.CreateSignal)
                return Event.CreateSignal.Call(Event)
        } catch {
            ; ignore and fall through to fallback
        }

        ; 3) Fallback
        return Instance.Signal()
    }

    ;=======================================================
    ; Fallback Signal implementation (RBX-like)
    ; Only used if no Event module is available AND
    ; you haven't set SignalFactory manually.
    ;=======================================================
    class Signal
    {
        __New()
        {
            this._handlers := []  ; array of Connection objects
        }

        ;-------------------------------------------
        ; Connect(callback) -> Connection
        ;-------------------------------------------
        Connect(callback)
        {
            if !IsObject(callback)
                throw Error("Signal.Connect expects a function/BoundFunc")

            conn := Instance.Connection(this, callback, false)
            this._handlers.Push(conn)
            return conn
        }

        ;-------------------------------------------
        ; Once(callback) -> Connection
        ; Fires only once, then disconnects.
        ;-------------------------------------------
        Once(callback)
        {
            if !IsObject(callback)
                throw Error("Signal.Once expects a function/BoundFunc")

            conn := Instance.Connection(this, callback, true)
            this._handlers.Push(conn)
            return conn
        }

        ;-------------------------------------------
        ; Fire(args*)
        ;-------------------------------------------
        Fire(args*)
        {
            ; Clone list to avoid issues if handlers disconnect while firing
            handlers := this._handlers.Clone()
            for conn in handlers
            {
                if conn._disconnected
                    continue

                conn._callback.Call(args*)

                if conn._once
                    conn.Disconnect()
            }
        }

        ;-------------------------------------------
        ; Wait() -> Array of args
        ; Blocks the current thread until the next fire.
        ;-------------------------------------------
        Wait()
        {
            received := false
            result := []

            temp := this.Connect((params*) => (
                received := true,
                result := params
            ))

            while !received
                Sleep 10

            temp.Disconnect()
            return result
        }

        ;-------------------------------------------
        ; DisconnectAll()
        ;-------------------------------------------
        DisconnectAll()
        {
            for conn in this._handlers
                conn._disconnected := true
            this._handlers := []
        }
    }

    class Connection
    {
        __New(signal, callback, once := false)
        {
            this._signal       := signal
            this._callback     := callback
            this._once         := once
            this._disconnected := false
        }

        Disconnect()
        {
            if this._disconnected
                return

            this._disconnected := true
            handlers := this._signal._handlers

            Loop handlers.Length
            {
                if (handlers[A_Index] == this)
                {
                    handlers.RemoveAt(A_Index)
                    break
                }
            }
        }
    }
}

;===========================================================
; Base Instance class (RBXInstance) and ValueBase
;===========================================================

class RBXInstance
{
    __New(className, parent := "")
    {
        this._ClassName := className
        this._Name      := className
        this._Parent    := ""
        this.Children   := []          ; array of child instances
        this._destroyed := false

        this._changed     := Instance._CreateSignal()
        this._destroying  := Instance._CreateSignal()
        this._propSignals := Map()     ; propName -> Signal

        if IsObject(parent)
            this.Parent := parent      ; goes through Parent property
    }

    ;-------------------------
    ; Read-only ClassName
    ;-------------------------
    ClassName {
        Get {
            return this._ClassName
        }
    }

    ;-------------------------
    ; Name (fires Changed)
    ;-------------------------
    Name {
        Get {
            return this._Name
        }
        Set {
            if (this._Name == value)
                return
            this._Name := value
            this._firePropertyChanged("Name")
        }
    }

    ;-------------------------
    ; Parent (updates child lists)
    ;-------------------------
    Parent {
        Get {
            return this._Parent
        }
        Set {
            this._setParent(value)
        }
    }

    ; Expose Children as a cloned array
    GetChildren()
    {
        return this.Children.Clone()
    }

    ;-------------------------
    ; Events
    ;   - Changed: Signal(propName)
    ;   - Destroying: Signal()
    ;   - GetPropertyChangedSignal(propName): Signal(newValue)
    ;-------------------------
    Changed {
        Get {
            return this._changed
        }
    }

    Destroying {
        Get {
            return this._destroying
        }
    }

    GetPropertyChangedSignal(propName)
    {
        if !this._propSignals.Has(propName)
            this._propSignals[propName] := Instance._CreateSignal()
        return this._propSignals[propName]
    }

    ; RBX-ish helper
    IsA(className)
    {
        return (this._ClassName = className)
    }

    ;-------------------------
    ; Destruction
    ;-------------------------
    Destroy()
    {
        if this._destroyed
            return

        this._destroyed := true
        this._destroying.Fire()

        ; Destroy children first
        for child in this.Children.Clone()
            child.Destroy()

        ; Detach from parent
        this.Parent := ""  ; uses _setParent

        ; Clear lists/signals
        this.Children     := []
        this._propSignals := Map()
    }

    ;=======================================================
    ; Internal helpers
    ;=======================================================
    _setParent(newParent)
    {
        old := this._Parent
        if (old == newParent)
            return

        ; Remove from old parent
        if IsObject(old)
            old._removeChild(this)

        this._Parent := newParent

        ; Add to new parent
        if IsObject(newParent)
            newParent._addChild(this)

        ; You could add an AncestryChanged signal here later
        ; and fire it with (this, old, newParent)
    }

    _addChild(child)
    {
        this.Children.Push(child)
    }

    _removeChild(child)
    {
        Loop this.Children.Length
        {
            if (this.Children[A_Index] == child)
            {
                this.Children.RemoveAt(A_Index)
                break
            }
        }
    }

    _firePropertyChanged(propName)
    {
        ; Global Changed(propName)
        this._changed.Fire(propName)

        ; Property-specific signal, passes new value
        if this._propSignals.Has(propName)
        {
            try
                this._propSignals[propName].Fire(this.%propName%)
            catch
                this._propSignals[propName].Fire()
        }
    }
}

;===========================================================
; ValueBase - common base for ValueObjects
;===========================================================

class ValueBase extends RBXInstance
{
    __New(className, defaultValue := "", parent := "")
    {
        this._Value := defaultValue
        super.__New(className, parent)
    }

    ; Generic setter used by subclasses - they can override SetValue()
    SetValue(newValue)
    {
        if (this._Value == newValue)
            return
        this._Value := newValue
        this._firePropertyChanged("Value")
    }

    Value {
        Get {
            return this._Value
        }
        Set {
            this.SetValue(value)
        }
    }
}

;===========================================================
; Concrete ValueObject classes
;===========================================================

class NumberValue extends ValueBase
{
    __New(parent := "", defaultValue := 0.0)
    {
        super.__New("NumberValue", defaultValue, parent)
    }

    SetValue(newValue)
    {
        if !IsNumber(newValue)
            throw Error("NumberValue.Value must be numeric")
        super.SetValue(newValue)
    }
}

class IntValue extends ValueBase
{
    __New(parent := "", defaultValue := 0)
    {
        super.__New("IntValue", defaultValue, parent)
    }

    SetValue(newValue)
    {
        if !IsInteger(newValue)
            throw Error("IntValue.Value must be an integer")
        super.SetValue(newValue)
    }
}

class BoolValue extends ValueBase
{
    __New(parent := "", defaultValue := false)
    {
        super.__New("BoolValue", defaultValue, parent)
    }

    SetValue(newValue)
    {
        ; Coerce to true/false
        newValue := !!newValue
        super.SetValue(newValue)
    }
}

class StringValue extends ValueBase
{
    __New(parent := "", defaultValue := "")
    {
        super.__New("StringValue", defaultValue, parent)
    }

    SetValue(newValue)
    {
        ; Force string
        newValue := newValue ""
        super.SetValue(newValue)
    }
}

class ObjectValue extends ValueBase
{
    __New(parent := "", defaultValue := "")
    {
        super.__New("ObjectValue", defaultValue, parent)
    }

    ; No extra type checks; can hold any AHK value
}

class Vector2Value extends ValueBase
{
    ; Assume you're using a Vector2 type from your math lib.
    ; We just store whatever object you give us.
    __New(parent := "", defaultValue := "")
    {
        super.__New("Vector2Value", defaultValue, parent)
    }
}

class Color3Value extends ValueBase
{
    ; Assume you're using your Color3 lib (Color3.fromRGB, etc.).
    ; We just store the object you pass.
    __New(parent := "", defaultValue := "")
    {
        super.__New("Color3Value", defaultValue, parent)
    }
}