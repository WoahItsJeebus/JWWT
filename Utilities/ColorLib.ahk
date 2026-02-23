#Requires AutoHotkey v2.0.19+

/**
 * @class Color3
 * @summary Roblox-style Color3 (r,g,b in [0,1]) for AutoHotkey v2.
 */
class Color3 {
    r := 0.0
    g := 0.0
    b := 0.0

    /**
     * @constructor
     * @summary Creates a Color3 from normalized components [0,1].
     * @param {Number} r
     * @param {Number} g
     * @param {Number} b
     */
    __New(r := 0, g := 0, b := 0) {
        this.r := Color3.__clamp01(r)
        this.g := Color3.__clamp01(g)
        this.b := Color3.__clamp01(b)
    }

    ; ======================
    ;  STATIC CONSTRUCTORS
    ; ======================

    /**
     * @function new
     * @summary Equivalent to Color3(r,g,b) for Lua muscle memory.
     * @param {Number} r
     * @param {Number} g
     * @param {Number} b
     * @return {Color3}
     */
    static new(r := 0, g := 0, b := 0) {
        return Color3(r, g, b)
    }

    /**
     * @function fromRGB
     * @summary Constructs from 0–255 RGB bytes.
     * @param {Integer} r - 0..255
     * @param {Integer} g - 0..255
     * @param {Integer} b - 0..255
     * @return {Color3}
     */
    static fromRGB(r, g, b) {
        return Color3(
            Color3.__clamp01(r / 255),
            Color3.__clamp01(g / 255),
            Color3.__clamp01(b / 255)
        )
    }

    /**
     * @function fromHex
     * @summary Constructs from a hex string like "#RRGGBB" or "RRGGBB".
     * @param {String} hex
     * @return {Color3}
     */
    static fromHex(hex) {
        hex := Trim(hex)
        if (SubStr(hex, 1, 1) = "#")
            hex := SubStr(hex, 2)

        if (StrLen(hex) != 6)
            throw Error("Color3.fromHex(): expected 6-digit hex, got '" hex "'")

        r := "0x" SubStr(hex, 1, 2)
        g := "0x" SubStr(hex, 3, 2)
        b := "0x" SubStr(hex, 5, 2)
        return Color3.fromRGB(r, g, b)
    }

    /**
     * @function fromHSV
     * @summary Constructs from HSV components in [0,1].
     * @param {Number} h - Hue [0,1].
     * @param {Number} s - Saturation [0,1].
     * @param {Number} v - Value [0,1].
     * @return {Color3}
     */
    static fromHSV(h, s, v) {
        h := Color3.__wrap01(h)
        s := Color3.__clamp01(s)
        v := Color3.__clamp01(v)

        if (s = 0) {
            return Color3(v, v, v)
        }

        h6 := h * 6
        i  := Floor(h6)
        f  := h6 - i

        p := v * (1 - s)
        q := v * (1 - s * f)
        t := v * (1 - s * (1 - f))

        switch Mod(i, 6) {
            case 0: r := v, g := t, b := p
            case 1: r := q, g := v, b := p
            case 2: r := p, g := v, b := t
            case 3: r := p, g := q, b := v
            case 4: r := t, g := p, b := v
            default: r := v, g := p, b := q
        }

        return Color3(r, g, b)
    }

    /**
     * @function random
     * @summary Returns a random Color3. Accepts either numbers or Color3 objects.
     * @description
     * Supported calls:
     *   - Color3.random() → full 0–255 random RGB
     *   - Color3.random(minColor:Color3, maxColor:Color3)
     *   - Color3.random(rMin,rMax,gMin,gMax,bMin,bMax)
     *   - Color3.random(globalMin, globalMax)
     *
     * @param {Any} args - flexible parameter set
     * @return {Color3}
     */
    static random(args*) {
		; --- Case 1: two Color3 objects provided ---
		if (args.Length = 2 && args[1] is Color3 && args[2] is Color3) {
			c1 := args[1], c2 := args[2]
			r := math.lerp(c1.r, c2.r, Random())
			g := math.lerp(c1.g, c2.g, Random())
			b := math.lerp(c1.b, c2.b, Random())
			return Color3(r, g, b)
		}

		; --- Case 2: numeric arguments (0–255 based) ---
		if (args.Length = 0) {
			rMin:=0, rMax:=255, gMin:=0, gMax:=255, bMin:=0, bMax:=255
		} else if (args.Length = 2) {
			rMin:=args[1], rMax:=args[2]
			gMin:=rMin, gMax:=rMax, bMin:=rMin, bMax:=rMax
		} else if (args.Length = 6) {
			rMin:=args[1], rMax:=args[2]
			gMin:=args[3], gMax:=args[4]
			bMin:=args[5], bMax:=args[6]
		} else {
			throw Error("Color3.random(): invalid argument count")
		}

		; clamp ranges 0–255
		rMin := Color3.__clampByte(rMin), rMax := Color3.__clampByte(rMax)
		gMin := Color3.__clampByte(gMin), gMax := Color3.__clampByte(gMax)
		bMin := Color3.__clampByte(bMin), bMax := Color3.__clampByte(bMax)

		; ensure min ≤ max
		if (rMax < rMin)
			tmp:=rMin, rMin:=rMax, rMax:=tmp
		if (gMax < gMin)
			tmp:=gMin, gMin:=gMax, gMax:=tmp
		if (bMax < bMin)
			tmp:=bMin, bMin:=bMax, bMax:=tmp

		; generate values
		try {
			r := math.random(rMin, rMax)
			g := math.random(gMin, gMax)
			b := math.random(bMin, bMax)
		} catch {
			r := Random(rMin, rMax)
			g := Random(gMin, gMax)
			b := Random(bMin, bMax)
		}

		return Color3.fromRGB(r, g, b)
	}

	; ======================
    ;  STATIC CONVERTERS
    ; ======================

    /**
     * @function toRGB
     * @summary Static helper: converts a Color3 to [r,g,b] bytes.
     * @param {Color3} color
     * @return {Array} [r,g,b] as integers 0–255.
     */
    static toRGB(color) {
        if !(color is Color3)
            throw Error("Color3.toRGB(): expected Color3, got " Type(color))
        return color.ToRGB()
    }

    /**
     * @function toHex
     * @summary Static helper: converts a Color3 to "#RRGGBB" (or "RRGGBB").
     * @param {Color3} color
     * @param {Boolean} [includeHash=true] - Whether to prefix '#'.
     * @return {String}
     */
    static toHex(color, includeHash := true) {
        if !(color is Color3)
            throw Error("Color3.toHex(): expected Color3, got " Type(color))
        return color.ToHex(includeHash)
    }

    /**
     * @function toHSV
     * @summary Static helper: converts a Color3 to [h,s,v] (0–1).
     * @param {Color3} color
     * @return {Array} [h,s,v]
     */
    static toHSV(color) {
        if !(color is Color3)
            throw Error("Color3.toHSV(): expected Color3, got " Type(color))
        return color.ToHSV()
    }


    ; ======================
    ;  INSTANCE METHODS
    ; ======================

    /**
     * @function ToRGB
     * @summary Returns 0–255 byte RGB array.
     * @return {Array} [r,g,b] as integers.
     */
    ToRGB() {
        return [
            Color3.__clampByte(Round(this.r * 255)),
            Color3.__clampByte(Round(this.g * 255)),
            Color3.__clampByte(Round(this.b * 255))
        ]
    }

    /**
     * @function ToHex
     * @summary Returns a hex string for this color.
     * @param {Boolean} [includeHash=true] - Whether to prefix '#'.
     * @return {String} "#RRGGBB" or "RRGGBB".
     */
    ToHex(includeHash := true) {
        rgb := this.ToRGB()
        hex := Format("{1:02X}{2:02X}{3:02X}", rgb[1], rgb[2], rgb[3])
        return includeHash ? hex : hex
    }

    /**
     * @function ToHSV
     * @summary Converts this Color3 to HSV components in [0,1].
     * @return {Array} [h,s,v]
     */
    ToHSV() {
        r := this.r, g := this.g, b := this.b
        local max := Max(r, g, b)
        local min := Min(r, g, b)
        delta := max - min

        v := max
        s := (max = 0) ? 0 : (delta / max)

        if (delta = 0) {
            h := 0
        } else if (max = r) {
            h := ((g - b) / delta) / 6
        } else if (max = g) {
            h := ((b - r) / delta) / 6 + 1/3
        } else {
            h := ((r - g) / delta) / 6 + 2/3
        }

        h := Color3.__wrap01(h)
        return [h, s, v]
    }

    ToString() {
        return Format("Color3({:.3f}, {:.3f}, {:.3f})", this.r, this.g, this.b)
    }

    ; ======================
    ;  INTERNAL HELPERS
    ; ======================

    /**
     * @private
     */
    static __clamp01(x) {
        return x < 0 ? 0 : x > 1 ? 1 : x
    }

    /**
     * @private
     */
    static __wrap01(x) {
        x := Mod(x, 1.0)
        return x < 0 ? x + 1.0 : x
    }

    /**
     * @private
     * @summary Clamp to 0..255 and coerce to integer.
     */
    static __clampByte(x) {
        x := Round(x)
        if (x < 0)
            return 0
        if (x > 255)
            return 255
        return x
    }
}

#Include MathLib.ahk