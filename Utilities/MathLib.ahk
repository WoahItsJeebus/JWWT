#Requires AutoHotkey v2.0.19+
#Include TimeLib.ahk

/**
 * @class math
 * @summary Roblox/Lua-style math helpers for AutoHotkey v2.
 * @description
 * Provides constants, random helpers, trig, log/exp, rounding,
 * and a Perlin-style value noise implementation compatible with:
 *   math.noise(x), math.noise(x, y), math.noise(x, y, z).
 */
class math {
    ; ======================
    ;  CONSTANTS
    ; ======================

    /**
     * @constant
     * @type {Number}
     * @summary Mathematical constant π.
     */
    static pi   := 3.141592653589793

    /**
     * @constant
     * @type {Number}
     * @summary Large sentinel value approximating positive infinity.
     */
    static huge := 1e308  ; 'infinity'-ish for our purposes

    /**
     * @private
     * @summary PRNG state for math.random / math.randomseed.
     * @type {Integer}
     */
    __randSeed := tick()

    ; ======================
    ;  BASIC HELPERS
    ; ======================

    /**
     * @function clamp
     * @summary Clamps a number to the [minimum, maximum] range.
     * @param {Number} number - Value to clamp.
     * @param {Number} minimum - Lower bound.
     * @param {Number} maximum - Upper bound.
     * @return {Number} Clamped value.
     */
    static clamp(number, minimum, maximum) {
        return Min(Max(number, minimum), maximum)
    }

    /**
     * @function lerp
     * @summary Linearly interpolates between a and b by alpha.
     * @param {Number} a - Start value.
     * @param {Number} b - End value.
     * @param {Number} alpha - Interpolation factor [0, 1].
     * @return {Number} Interpolated value.
     */
    static lerp(a, b, alpha) {
        return a + (b - a) * alpha
    }

    /**
     * @function sign
     * @summary Returns the sign of x.
     * @description
     * Returns 1 if x > 0, -1 if x < 0, 0 if x = 0.
     * @param {Number} x
     * @return {Integer} -1, 0 or 1.
     */
    static sign(x) {
        return x > 0 ? 1 : x < 0 ? -1 : 0
    }

    /**
     * @function min
     * @summary Returns the smallest of all arguments.
     * @param {Number} x - First value.
     * @param {Number[]} rest - Remaining values.
     * @return {Number} Minimum value.
     */
    static min(x, rest*) {
        ; let the built-in handle it
        return Min(x, rest*)
    }

    /**
     * @function max
     * @summary Returns the largest of all arguments.
     * @param {Number} x - First value.
     * @param {Number[]} rest - Remaining values.
     * @return {Number} Maximum value.
     */
    static max(x, rest*) {
        return Max(x, rest*)
    }

    /**
     * @function modf
     * @summary Splits a number into integer and fractional parts.
     * @param {Number} x
     * @return {Array} [integerPart, fractionalPart].
     */
    static modf(x) {
        intPart  := Floor(x)
        fracPart := x - intPart
        return [intPart, fracPart]
    }

    ; ======================
    ;  ROUNDING / ANGLES
    ; ======================

    /**
     * @function round
     * @summary Roblox-style rounding with half-away-from-zero semantics.
     * @description
     * Supports optional decimal digits, similar to math.round in Luau.
     * @param {Number} x - Value to round.
     * @param {Integer} digits - Number of decimal places (default 0).
     * @return {Number} Rounded value.
     */
    static round(x, digits := 0) {
        scale  := 10 ** digits
        value  := x * scale
        sign   := (value < 0) ? -1 : 1
        absVal := Abs(value)
        ; half-away-from-zero
        rounded := Floor(absVal + 0.5)
        return (sign * rounded) / scale
    }

    /**
     * @function floor
     * @summary Returns the largest integer less than or equal to x.
     * @param {Number} x
     * @return {Integer}
     */
    static floor(x) {
        return Floor(x)
    }

    /**
     * @function ceil
     * @summary Returns the smallest integer greater than or equal to x.
     * @param {Number} x
     * @return {Integer}
     */
    static ceil(x) {
        return Ceil(x)
    }

    /**
     * @function abs
     * @summary Returns the absolute value of x.
     * @param {Number} x
     * @return {Number}
     */
    static abs(x) {
        return Abs(x)
    }

    /**
     * @function rad
     * @summary Converts degrees to radians.
     * @param {Number} degrees
     * @return {Number} Radians.
     */
    static rad(degrees) {
        return degrees * (this.pi / 180)
    }

    /**
     * @function deg
     * @summary Converts radians to degrees.
     * @param {Number} radians
     * @return {Number} Degrees.
     */
    static deg(radians) {
        return radians * (180 / this.pi)
    }

    ; ======================
    ;  TRIG / HYPERBOLIC
    ; ======================

    /**
     * @function sin
     * @summary Sine of x (radians).
     * @param {Number} x
     * @return {Number}
     */
    static sin(x) {
        return Sin(x)
    }

    /**
     * @function cos
     * @summary Cosine of x (radians).
     * @param {Number} x
     * @return {Number}
     */
    static cos(x) {
        return Cos(x)
    }

    /**
     * @function tan
     * @summary Tangent of x (radians).
     * @param {Number} x
     * @return {Number}
     */
    static tan(x) {
        return Tan(x)
    }

    /**
     * @function asin
     * @summary Arcsine of x in radians.
     * @param {Number} x
     * @return {Number}
     */
    static asin(x) {
        return ASin(x)
    }

    /**
     * @function acos
     * @summary Arccosine of x in radians.
     * @param {Number} x
     * @return {Number}
     */
    static acos(x) {
        return ACos(x)
    }

    /**
     * @function atan
     * @summary Arctangent of x in radians.
     * @param {Number} x
     * @return {Number}
     */
    static atan(x) {
        return ATan(x)
    }

    /**
     * @function atan2
     * @summary Roblox-style two-argument arctangent.
     * @description
     * Returns the angle (in radians) whose tangent is y/x,
     * taking into account the signs of both arguments to determine
     * the correct quadrant.
     * @param {Number} y
     * @param {Number} x
     * @return {Number} Angle in radians.
     */
    static atan2(y, x) {
        if (x > 0)
            return ATan(y / x)
        else if (x < 0 && y >= 0)
            return ATan(y / x) + this.pi
        else if (x < 0 && y < 0)
            return ATan(y / x) - this.pi
        else if (x = 0 && y > 0)
            return this.pi / 2
        else if (x = 0 && y < 0)
            return -this.pi / 2
        else
            return 0  ; undefined for (0,0), just return 0
    }

    /**
     * @function sqrt
     * @summary Square root of x.
     * @param {Number} x
     * @return {Number}
     */
    static sqrt(x) {
        return Sqrt(x)
    }

    /**
     * @function sinh
     * @summary Hyperbolic sine of x.
     * @param {Number} x
     * @return {Number}
     */
    static sinh(x) {
        ex  := Exp(x)
        exn := Exp(-x)
        return (ex - exn) / 2
    }

    /**
     * @function cosh
     * @summary Hyperbolic cosine of x.
     * @param {Number} x
     * @return {Number}
     */
    static cosh(x) {
        ex  := Exp(x)
        exn := Exp(-x)
        return (ex + exn) / 2
    }

    /**
     * @function tanh
     * @summary Hyperbolic tangent of x.
     * @param {Number} x
     * @return {Number}
     */
    static tanh(x) {
        ex2 := Exp(2 * x)
        return (ex2 - 1) / (ex2 + 1)
    }

    ; ======================
    ;  LOG / EXP
    ; ======================

    /**
     * @function log
     * @summary Natural log or log with custom base (Roblox-style).
     * @description
     * math.log(x)      -> ln(x)
     * math.log(x, b)   -> ln(x) / ln(b)
     * @param {Number} x - Value.
     * @param {Number} [base] - Optional base. Defaults to e when omitted or 0.
     * @return {Number}
     */
    static log(x, base := "") {
        if (base = "" || base = 0)
            return Ln(x)
        return Ln(x) / Ln(base)
    }

    /**
     * @function log10
     * @summary Base-10 logarithm.
     * @param {Number} x
     * @return {Number}
     */
    static log10(x) {
        return Log(x)  ; AHK's Log is base-10
    }

    /**
     * @function exp
     * @summary Exponential e^x.
     * @param {Number} x
     * @return {Number}
     */
    static exp(x) {
        return Exp(x)
    }

    /**
     * @function fmod
     * @summary Lua/Roblox-style floating-point modulus.
     * @param {Number} x
     * @param {Number} y
     * @return {Number} Remainder of x / y.
     */
    static fmod(x, y) {
        return Mod(x, y)
    }

    /**
     * @function pow
     * @summary Raises x to the power y.
     * @param {Number} x
     * @param {Number} y
     * @return {Number} x^y.
     */
    static pow(x, y) {
        return x ** y
    }

    ; ======================
    ;  RANDOM
    ; ======================

    /**
     * @function randomseed
     * @summary Sets the seed for math.random.
     * @description
     * Uses a simple LCG; same seed => same sequence.
     * @param {Number} seed - Seed value; 0 is remapped to 1.
     * @return {Void}
     */
    static randomseed(seed) {
        ; keep it simple & deterministic
        seed := Floor(Abs(seed))
        if (seed = 0)
            seed := 1
        this.__randSeed := seed
    }

    /**
     * @function random
     * @summary Lua/Roblox-style random function.
     * @description
     * math.random()              -> float [0, 1)
     * math.random(upper)         -> int   [1, upper]
     * math.random(lower, upper)  -> int   [lower, upper]
     * @param {Number} [lower] - Lower bound or upper when only one arg.
     * @param {Number} [upper] - Upper bound.
     * @return {Number} Random number as described above.
     */
    static random(lower := "", upper := "") {
        ; LCG: same each run for same seed
        this.__randSeed := (this.__randSeed * 1103515245 + 12345) & 0x7fffffff
        r := this.__randSeed / 0x7fffffff  ; 0..1

        ; no args -> 0..1 (float)
        if (lower = "" && upper = "")
            return r

        ; one arg -> 1..upper (int)
        if (upper = "") {
            upper := lower
            lower := 1
        }

        ; two args -> lower..upper (int)
        return Floor(lower + r * (upper - lower + 1))
    }

    ; ======================
    ;  NOISE (Perlin-style value noise)
    ; ======================

    /**
     * @function noise
     * @summary Smooth value-noise function similar to Roblox's math.noise.
     * @description
     * Signature:
     *   math.noise(x)
     *   math.noise(x, y)
     *   math.noise(x, y, z)
     * Returns a deterministic pseudo-random value in [-1, 1].
     *
     * @param {Number} x
     * @param {Number} [y=0]
     * @param {Number} [z=0]
     * @return {Number} Noise value in [-1, 1].
     */
    static noise(x, y := 0, z := 0) {
        ; coerce missing/blank args to 0
        if (y = "")
            y := 0
        if (z = "")
            z := 0

        ; integer lattice coordinates
        ix := Floor(x)
        iy := Floor(y)
        iz := Floor(z)

        ; fractional part within the cell
        fx := x - ix
        fy := y - iy
        fz := z - iz

        ; fade (smoothstep) on each axis
        u := this.__fade(fx)
        v := this.__fade(fy)
        w := this.__fade(fz)

        ; 8 corners of the cell
        n000 := this.__hash3(ix    , iy    , iz    )
        n100 := this.__hash3(ix + 1, iy    , iz    )
        n010 := this.__hash3(ix    , iy + 1, iz    )
        n110 := this.__hash3(ix + 1, iy + 1, iz    )
        n001 := this.__hash3(ix    , iy    , iz + 1)
        n101 := this.__hash3(ix + 1, iy    , iz + 1)
        n011 := this.__hash3(ix    , iy + 1, iz + 1)
        n111 := this.__hash3(ix + 1, iy + 1, iz + 1)

        ; trilinear interpolation with fade curve
        x1 := this.lerp(n000, n100, u)
        x2 := this.lerp(n010, n110, u)
        y1 := this.lerp(x1,  x2,   v)

        x3 := this.lerp(n001, n101, u)
        x4 := this.lerp(n011, n111, u)
        y2 := this.lerp(x3,  x4,   v)

        return this.lerp(y1, y2, w)  ; final value in [-1, 1]
    }

    ; ======================
    ;  INTERNAL HELPERS
    ; ======================

    /**
     * @private
     * @function __fade
     * @summary Smoothstep-like fade curve used for interpolation.
     * @description
     * Implements 6t^5 - 15t^4 + 10t^3.
     * @param {Number} t - Fractional coordinate [0, 1].
     * @return {Number} Smoothed value.
     */
    static __fade(t) {
        return t * t * t * (t * (t * 6 - 15) + 10)
    }

    /**
     * @private
     * @function __hash3
     * @summary Deterministic hash from integer coordinates to [-1, 1].
     * @param {Integer} ix
     * @param {Integer} iy
     * @param {Integer} iz
     * @return {Number} Pseudo-random value in [-1, 1].
     */
    static __hash3(ix, iy, iz) {
        ; make sure everything is integer
        n := ix * 374761393
        n += iy * 668265263
        n += iz * 2147483647

        n := n ^ (n >> 13)
        n := n * 1274126177
        n := n ^ (n >> 16)

        ; map to [-1, 1]
        n := n & 0x7fffffff
        return (n / 0x7fffffff) * 2 - 1
    }
}