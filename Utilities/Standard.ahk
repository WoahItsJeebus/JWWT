#Requires AutoHotkey v2.0.19+
#Include Notifications.ahk

/**
 * @function Print
 * @summary Logs an informational message.
 * @description
 * Equivalent to Roblox's print(); logs to debug output and shows a notification.
 */
Print(args*) {
    msg := __FormatPrintArgs(args*)
    if (msg = "")
        msg := "(nil)"

    stamp  := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    prefix := "[" stamp "] [INFO] "
    line   := prefix msg
	
	OutputDebug(line "`n")

    try Notifications.new(msg, Map(
        "Title",          "Warning",
        "Type",           "warn",
        "Duration",       4000,
        "Width",          300,
        "Height",         90,
        "HighlightColor", "929292"  ; soft yellow/orange

    ))
}

/**
 * @function Warn
 * @summary Logs a warning message.
 * @description
 * Equivalent to Roblox's warn(); logs to debug output and shows a warning notification.
 */
Warn(args*) {
    msg := __FormatPrintArgs(args*)
    if (msg = "")
        msg := "(nil)"

    stamp  := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    prefix := "[" stamp "] [WARN] "
    line   := prefix msg

    OutputDebug(line "`n")

    ; Visual warning (ties into your existing notification system)
    try Notifications.new(msg, Map(
        "Title",          "Warning",
        "Type",           "warn",
        "Duration",       4000,
        "Width",          300,
        "Height",         90,
        "HighlightColor", "ffbf00"  ; soft yellow/orange
    ))
}

/**
 * @function RaiseError
 * @summary Logs an error message and optionally throws an exception.
 * @description
 * Equivalent to Roblox's error(); logs to debug output, shows an error notification, and can throw an exception.
 * @param {number} level - The severity level of the error (0 = log only, >=1 = throw exception).
 */
RaiseError(level, args*) {
    if !IsInteger(level)
        throw Error("RaiseError(): first argument must be an integer level (0 = non-fatal, >=1 = fatal).")

    msg := __FormatPrintArgs(args*)
    if (msg = "")
        msg := "(nil)"

    stamp  := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    prefix := "[" stamp "] [ERROR L" level "] "
    line   := prefix msg

    OutputDebug(line "`n")

    ; Visual error popup
    try Notifications.new(msg, Map(
        "Title",          "Error",
        "Type",           "error",
        "Duration",       6000,
        "Width",          320,
        "Height",         100,
        "HighlightColor", "ff3040"
    ))

    ; Level 0 = soft error (log only); 1+ = fatal
    if (level >= 1)
        throw Error(line)
}

; ============================================
;  INTERNAL FORMAT HELPERS
; ============================================

__FormatPrintArgs(args*) {
    if (args.Length = 0)
        return ""

    out := ""
    for i, v in args {
        if (i > 1)
            out .= " "
        out .= __ToDebugString(v)
    }
    return out
}

__ToDebugString(val, depth := 0) {
    ; Avoid infinite recursion
    if (depth > 3)
        return "<...>"

    if IsObject(val) {
        if (val is Array) {
            buf := "["
            first := true
            for i, v in val {
                if !first
                    buf .= ", "
                buf  .= __ToDebugString(v, depth + 1)
                first := false
            }
            buf .= "]"
            return buf
        } else if (val is Map) {
            buf := "{"
            first := true
            for k, v in val {
                if !first
                    buf .= ", "
                buf  .= __ToDebugString(k, depth + 1) ": " __ToDebugString(v, depth + 1)
                first := false
            }
            buf .= "}"
            return buf
        } else {
            ; Some other object (Func, ComObject, custom class, etc.)
            ; You can extend this branch if you want richer output.
            return "<Object:" Type(val) ">"
        }
    }

    ; Primitive types – let AHK coerce them
    return val
}