#Requires AutoHotkey v2.0.19+

/**
 * @function tick
 * @summary Returns high-precision Unix epoch time (seconds as float).
 * @description
 * Combines UTC date/time (whole seconds) with the current millisecond tick count.
*/

tick(*) {
	static __tickBaseMillis := A_TickCount
	static __tickBaseTime   := DateDiff(A_NowUTC, "19700101000000", "Seconds")

    ; Seconds since the base moment, adjusted with high-res uptime
    delta := (A_TickCount - __tickBaseMillis) / 1000.0
    return __tickBaseTime + delta
}

/**
 * @function time
 * @summary Returns the amount of time, in seconds, that has elapsed since the current script instance started running.
 * @description
 * Equivalent to Roblox's os.time(); gives seconds since script start.
 */
time() {
	return os.time()
}

class os {
	
	/**
	 * @function clock
	 * @summary Returns the number of seconds since the script started.
	 * @description
	 * Equivalent to Roblox's os.clock(); gives seconds since an arbitrary baseline with sub-millisecond precision (script start for this library).
	 */
	static clock() {
		static __ClockStart := A_TickCount
		return (A_TickCount - __ClockStart) / 1000.0
	}

	/**
	 * @function time
	 * @summary Returns the current Unix timestamp.
	 * @description
	 * Equivalent to Roblox's os.time(); gives seconds since 1970-01-01 UTC.
	 */
	static time() {
		return this.clock()
	}
}

/**
 * @class DateTime
 * @summary Provides date and time related utilities.
 * @description
 * Equivalent to Roblox's DateTime class.
 */
class DateTime {
	/**
	 * @function now
	 * @summary Returns a map containing the current date and time information.
	 * @description
	 * Equivalent to Roblox's DateTime.now(); gives detailed current date and time info.
	 * @returns {Map}
	 * ("Year", "Month", "Day", "Hour", "Minute", "Second", "Unix", "TimezoneOffset", "Iso8601", "Pretty")
	 */
	static now() {
		local now := A_Now
		local yyyy := FormatTime(now, "yyyy")
		local MM := FormatTime(now, "MM")
		local dd := FormatTime(now, "dd")
		local hh := FormatTime(now, "HH")
		local mm := FormatTime(now, "mm")
		local ss := FormatTime(now, "ss")
		local tz := A_NowUTC
		local offsetSec := DateDiff(now, tz, "Seconds")
		local offsetHr := Round(offsetSec / 3600, 2)

		return Map(
			"Year", yyyy + 0,
			"Month", MM + 0,
			"Day", dd + 0,
			"Hour", hh + 0,
			"Minute", mm + 0,
			"Second", ss + 0,
			"Unix", tick(),
			"TimezoneOffset", offsetHr,
			"Iso8601", FormatTime(, "yyyy-MM-dd'T'HH:mm:ss"),
			"Pretty", FormatTime(, "yyyy-MM-dd HH:mm:ss")
		)
	}
}