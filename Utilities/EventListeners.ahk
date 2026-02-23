#Requires AutoHotkey v2.0.19

;===========================================================
; Events.ahk
; Roblox-style event system for AHK v2
;
; Usage:
;   ; Create a standalone signal:
;   mySignal := Event.CreateSignal()
;
;   ; Connect:
;   conn := mySignal.Connect((args*) => MsgBox("Fired: " args.Length))
;
;   ; Fire:
;   mySignal.Fire("hello", 123)
;
;   ; Once:
;   mySignal.Once((args*) => MsgBox("This runs only once"))
;
;   ; Wait:
;   args := mySignal.Wait()  ; returns an array of args
;
; Integration with Instance ValueObjects module:
;   ; After including both Events.ahk and your Instance.ahk:
;   Instance.SetSignalFactory(Event.CreateSignal.Bind(Event))
;
; Then RBXInstance.Changed / GetPropertyChangedSignal() will use
; this Event.Signal implementation under the hood.
;===========================================================

/*
 * @class Event
 * @summary Roblox-style event system for AutoHotkey v2.
 * @description
 * Provides Signal and Connection classes to mimic Roblox's event handling.
 */
class Event
{
    ;-------------------------------------------------------
    ; Factory used by other modules (like Instance)
    ; `owner` is optional and will be pre-bound when you call:
    ;   Instance.SetSignalFactory(Event.CreateSignal.Bind(Event))
    ;
    ; We explicitly tolerate `owner == Event` and just ignore it.
    ;-------------------------------------------------------
    static CreateSignal(owner := "", name := "")
    {
        if IsObject(owner) && (owner == Event)
            owner := ""   ; ignore the bound Event class
        return Event.Signal(owner, name)
    }

    ;=======================================================
    ; Signal
    ;=======================================================
    class Signal
    {
        __New(owner := "", name := "")
        {
            this._owner    := owner   ; optional, for debugging
            this._name     := name    ; optional, for debugging
            this._handlers := []      ; array of Connection objects
        }

        /*
		 * @datatype ScriptConnection
		 * @summary Represents a connection to a signal.
		 * @description
		 * Returned by Signal.Connect() and Signal.Once(); allows disconnection.
		 */
        Connect(callback)
        {
            if !IsObject(callback)
                throw Error("Signal.Connect expects a function or BoundFunc")

            conn := Event.Connection(this, callback, false)
            this._handlers.Push(conn)
            return conn
        }

        ;-----------------------------------------------
        ; Once(callback) -> Connection
        ; Like Roblox: fires once, then auto-disconnects
        ;-----------------------------------------------
        Once(callback)
        {
            if !IsObject(callback)
                throw Error("Signal.Once expects a function or BoundFunc")

            conn := Event.Connection(this, callback, true)
            this._handlers.Push(conn)
            return conn
        }

        ;-----------------------------------------------
        ; Fire(args*)
        ;-----------------------------------------------
        Fire(args*)
        {
            ; Clone the handler list so handlers can safely
            ; disconnect themselves during the callback.
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

        ;-----------------------------------------------
        ; Wait() -> Array of args
        ; Blocks the current thread until the next fire.
        ;-----------------------------------------------
        Wait()
		{
            received := false
            result   := []

            temp := this.Connect((params*) => (
                received := true,
                result   := params
            ))

            ; crude but simple wait loop; you can tune Sleep if needed
            while !received
                Sleep 10

            temp.Disconnect()
            return result
        }

        ;-----------------------------------------------
        ; DisconnectAll()
        ;-----------------------------------------------
        DisconnectAll()
        {
            for conn in this._handlers
                conn._disconnected := true
            this._handlers := []
        }
    }

    ;=======================================================
    ; Connection
    ;=======================================================
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