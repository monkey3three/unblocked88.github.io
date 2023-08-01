package quake;

import js.html.ArrayBuffer;
import js.html.Uint8Array;


@:publicFields
class Q {
    static function memstr(src:Uint8Array):String {
        var dest = [];
        for (i in 0...src.length) {
            if (src[i] == 0)
                break;
            dest.push(String.fromCharCode(src[i]));
        }
        return dest.join('');
    }

    static function strmem(src:String):ArrayBuffer {
        var buf = new ArrayBuffer(src.length);
        var dest = new Uint8Array(buf);
        for (i in 0...src.length)
            dest[i] = src.charCodeAt(i) & 255;
        return buf;
    }

    static function atoi(str:String):Int {
        if (str == null)
            return 0;

        var ptr, sign;
        if (str.charCodeAt(0) == "-".code) {
            sign = -1;
            ptr = 1;
        } else {
            sign = 1;
            ptr = 0;
        }

        var c = str.charCodeAt(ptr);
        var c2 = str.charCodeAt(ptr + 1);
        var val = 0;
        if (c == "0".code && (c2 == "x".code || c2 == "X".code)) {
            ptr += 2;
            while (true) {
                c = str.charCodeAt(ptr++);
                if (c >= "0".code && c <= "9".code)
                    val = (val << 4) + c - 48;
                else if (c >= "a".code && c <= "f".code)
                    val = (val << 4) + c - 87;
                else if (c >= "A".code && c <= "F".code)
                    val = (val << 4) + c - 55;
                else
                    return val * sign;
            }
        }
        if (c == "'".code) {
            if (c2 == null)
                return 0;
            return sign * c2;
        }
        while (true) {
            c = str.charCodeAt(ptr++);
            if (c == null || c <= "/".code || c >= ":".code)
                return val * sign;
            val = val * 10 + c - 48;
        }
    }

    static function atof(str:String):Float {
        if (str == null)
            return 0.0;
        var ptr, sign;
        if (str.charCodeAt(0) == "-".code) {
            sign = -1;
            ptr = 1;
        } else {
            sign = 1;
            ptr = 0;
        }
        var c = str.charCodeAt(ptr);
        var c2 = str.charCodeAt(ptr + 1);
        var val;
        if (c == "0".code && (c2 == "x".code || c2 == "X".code)) {
            ptr += 2;
            val = 0.0;
            while (true) {
                c = str.charCodeAt(ptr++);
                if (c >= "0".code && c <= "9".code)
                    val = (val * 16) + c - "0".code;
                else if (c >= "a".code && c <= "f".code)
                    val = (val * 16) + c - "W".code;
                else if (c >= "A".code && c <= "F".code)
                    val = (val * 16) + c - "7".code;
                else
                    return val * sign;
            }
        }
        if (c == "'".code) {
            if (Math.isNaN(c2))
                return 0;
            return sign * c2;
        }
        val = Std.parseFloat(str);
        if (Math.isNaN(val))
            return 0;
        return val;
    }

    static function btoa(src:Uint8Array):String {
        var str = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        var val = [];
        var len = src.length - (src.length % 3);
        var i = 0;
        while (i < len) {
            var c = (src[i] << 16) + (src[i + 1] << 8) + src[i + 2];
            val.push(str.charAt(c >> 18) + str.charAt((c >> 12) & 63) + str.charAt((c >> 6) & 63) + str.charAt(c & 63));
            i += 3;
        }
        if ((src.length - len) == 1) {
            var c = src[len];
            val.push(str.charAt(c >> 2) + str.charAt((c & 3) << 4) + '==');
        }
        else if ((src.length - len) == 2) {
            var c = (src[len] << 8) + src[len + 1];
            val.push(str.charAt(c >> 10) + str.charAt((c >> 4) & 63) + str.charAt((c & 15) << 2) + '=');
        }
        return val.join('');
    }
}
