package quake;

import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Uint8Array;
import js.html.Int8Array;


@:publicFields
class MSG {
	var data:ArrayBuffer;
	var cursize:Int;
	var allowoverflow = false;
	var overflowed = false;

	function new(capacity:Int, size = 0) {
		data = new ArrayBuffer(capacity);
		cursize = size;
	}

	static var badread:Bool;
	static var readcount:Int;

	function GetSpace(length:Int):Int {
		if ((cursize + length) > data.byteLength) {
			if (!allowoverflow)
				Sys.Error('SZ.GetSpace: overflow without allowoverflow set');
			if (length > data.byteLength)
				Sys.Error('SZ.GetSpace: ' + length + ' is > full buffer size');
			overflowed = true;
			Console.Print('SZ.GetSpace: overflow\n');
			cursize = 0;
		}
		var oldsize = cursize;
		cursize += length;
		return oldsize;
	}

	function Write(a:Uint8Array, length:Int):Void {
		(new Uint8Array(data, GetSpace(length), length)).set(a.subarray(0, length));
	}

	function WriteChar(c:Int):Void {
		(new DataView(data)).setInt8(GetSpace(1), c);
	}

	function WriteByte(c:Int):Void {
		(new DataView(data)).setUint8(GetSpace(1), c);
	}

	function WriteShort(c:Int):Void {
		(new DataView(data)).setInt16(GetSpace(2), c, true);
	}

	function WriteLong(c:Int):Void {
		(new DataView(data)).setInt32(GetSpace(4), c, true);
	}

	function WriteFloat(f:Float):Void {
		(new DataView(data)).setFloat32(GetSpace(4), f, true);
	}

	function WriteString(s:String):Void {
		if (s != null)
			Write(new Uint8Array(Q.strmem(s)), s.length);
		WriteChar(0);
	}

	inline function WriteCoord(f:Float):Void {
		WriteShort(Std.int(f * 8));
	}

	inline function WriteAngle(f:Float):Void {
		WriteByte(Std.int(f * 256 / 360) & 255);
	}

	function Print(s:String):Void {
		var buf = new Uint8Array(data);
		var dest;
		if (cursize != 0) {
			if (buf[cursize - 1] == 0)
				dest = GetSpace(s.length - 1) - 1;
			else
				dest = GetSpace(s.length);
		} else {
			dest = GetSpace(s.length);
		}
		for (i in 0...s.length)
			buf[dest + i] = s.charCodeAt(i);
	}

	static function BeginReading():Void {
		readcount = 0;
		badread = false;
	}

	static function ReadChar():Int {
		if (readcount >= NET.message.cursize) {
			badread = true;
			return -1;
		}
		var c = (new Int8Array(NET.message.data, readcount, 1))[0];
		++readcount;
		return c;
	}

	static function ReadByte():Int {
		if (readcount >= NET.message.cursize) {
			badread = true;
			return -1;
		}
		var c = (new Uint8Array(NET.message.data, readcount, 1))[0];
		++readcount;
		return c;
	}

	static function ReadShort():Int {
		if ((readcount + 2) > NET.message.cursize) {
			badread = true;
			return -1;
		}
		var c = (new DataView(NET.message.data)).getInt16(readcount, true);
		readcount += 2;
		return c;
	}

	static function ReadLong():Int {
		if ((readcount + 4) > NET.message.cursize) {
			badread = true;
			return -1;
		}
		var c = (new DataView(NET.message.data)).getInt32(readcount, true);
		readcount += 4;
		return c;
	}

	static function ReadFloat():Float {
		if ((readcount + 4) > NET.message.cursize) {
			badread = true;
			return -1;
		}
		var f = (new DataView(NET.message.data)).getFloat32(readcount, true);
		readcount += 4;
		return f;
	}

	static function ReadString():String {
		var string = new StringBuf();
		for (l in 0...2048) {
			var c = ReadByte();
			if (c <= 0)
				break;
			string.addChar(c);
		}
		return string.toString();
	}

	static inline function ReadCoord():Float {
		return ReadShort() * 0.125;
	}

	static inline function ReadAngle():Float {
		return ReadChar() * 1.40625;
	}

	static inline function ReadVector():Vec {
		return Vec.of(ReadCoord(), ReadCoord(), ReadCoord());
	}
}
