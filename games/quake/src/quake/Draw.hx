package quake;

import js.Browser.document;
import js.html.ArrayBuffer;
import js.html.CanvasElement;
import js.html.DataView;
import js.html.ImageElement;
import js.html.Uint8Array;
import js.html.Uint32Array;
import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;
import quake.GL.gl;

@:publicFields
class DrawPic {
	var width:Int;
	var height:Int;
	var data:Uint8Array;
	var texnum:Texture;
	var translate:Texture;

	function new(buf:ArrayBuffer) {
		if (buf != null) {
			var view = new DataView(buf, 0, 8);
			width = view.getUint32(0, true);
			height = view.getUint32(4, true);
			data = new Uint8Array(buf, 8, width * height);
			texnum = GL.LoadPicTexture(this);
		}
	}
}


class Draw {
	static var chars:Uint8Array;
	static var conback:DrawPic;
	static var loading:DrawPic;
	static var char_texture:Texture;
	static var loadingElem:ImageElement;

	static function CharToConback(num:Int, dest:Int):Void {
		var source = ((num >> 4) << 10) + ((num & 15) << 3);
		for (drawline in 0...8) {
			for (x in 0...8) {
				if (chars[source + x] != 0)
					conback.data[dest + x] = 0x60 + chars[source + x];
			}
			source += 128;
			dest += 320;
		}
	}

	public static function Init():Void {
		chars = new Uint8Array(W.GetLumpName('CONCHARS'));

		var trans = new ArrayBuffer(65536);
		var trans32 = new Uint32Array(trans);
		for (i in 0...16384) {
			if (chars[i] != 0)
				trans32[i] = COM.LittleLong(VID.d_8to24table[chars[i]] + 0xff000000);
		}
		char_texture = gl.createTexture();
		GL.Bind(0, char_texture);
		gl.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, 128, 128, 0, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, new Uint8Array(trans));
		gl.texParameterf(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, RenderingContext.LINEAR);
		gl.texParameterf(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, RenderingContext.LINEAR);

		conback = new DrawPic(null);
		var cb = COM.LoadFile('gfx/conback.lmp');
		if (cb == null)
			Sys.Error('Couldn\'t load gfx/conback.lmp');
		conback.width = 320;
		conback.height = 200;
		conback.data = new Uint8Array(cb, 8, 64000);
		var ver = '(HaxeQuake ' + Def.getVersion() + ') 1.09';
		for (i in 0...ver.length)
			CharToConback(ver.charCodeAt(i), 59829 - ((ver.length - i) << 3));
		conback.texnum = GL.LoadPicTexture(conback);

		loading = CachePic('loading');
		loadingElem = cast document.getElementById('loading');
		loadingElem.src = PicToDataURL(loading);

		document.body.style.backgroundImage = 'url("' + PicToDataURL(PicFromWad('BACKTILE')) + '")';
	}

	public static function Character(x:Int, y:Int, num:Int):Void {
		var program = GL.UseProgram(GLPrograms.character);
		GL.Bind(program.tTexture, char_texture);
		gl.bindBuffer(RenderingContext.ARRAY_BUFFER, GL.rect);
		gl.vertexAttribPointer(program.aPoint, 2, RenderingContext.FLOAT, false, 0, 0);
		gl.uniform2f(program.uCharacter, num & 15, num >> 4);
		gl.uniform2f(program.uDest, x, y);
		gl.drawArrays(RenderingContext.TRIANGLE_STRIP, 0, 4);
	}

	public static function String(x:Int, y:Int, str:String):Void {
		var program = GL.UseProgram(GLPrograms.character);
		GL.Bind(program.tTexture, char_texture);
		gl.bindBuffer(RenderingContext.ARRAY_BUFFER, GL.rect);
		gl.vertexAttribPointer(program.aPoint, 2, RenderingContext.FLOAT, false, 0, 0);
		for (i in 0...str.length) {
			var num = str.charCodeAt(i);
			gl.uniform2f(program.uCharacter, num & 15, num >> 4);
			gl.uniform2f(program.uDest, x, y);
			gl.drawArrays(RenderingContext.TRIANGLE_STRIP, 0, 4);
			x += 8;
		}
	}

	public static function StringWhite(x:Int, y:Int, str:String):Void {
		var program = GL.UseProgram(GLPrograms.character);
		GL.Bind(program.tTexture, char_texture);
		gl.bindBuffer(RenderingContext.ARRAY_BUFFER, GL.rect);
		gl.vertexAttribPointer(program.aPoint, 2, RenderingContext.FLOAT, false, 0, 0);
		for (i in 0...str.length) {
			var num = str.charCodeAt(i) + 128;
			gl.uniform2f(program.uCharacter, num & 15, num >> 4);
			gl.uniform2f(program.uDest, x, y);
			gl.drawArrays(RenderingContext.TRIANGLE_STRIP, 0, 4);
			x += 8;
		}
	}

	public static inline function PicFromWad(name:String):DrawPic {
		return new DrawPic(W.GetLumpName(name));
	}

	public static function CachePic(path:String):DrawPic {
		path = 'gfx/' + path + '.lmp';
		var buf = COM.LoadFile(path);
		if (buf == null)
			Sys.Error('CachePic: failed to load ' + path);
		return new DrawPic(buf);
	}

	public static function Pic(x:Int, y:Int, pic:DrawPic):Void {
		var program = GL.UseProgram(GLPrograms.pic);
		GL.Bind(program.tTexture, pic.texnum);
		gl.bindBuffer(RenderingContext.ARRAY_BUFFER, GL.rect);
		gl.vertexAttribPointer(program.aPoint, 2, RenderingContext.FLOAT, false, 0, 0);
		gl.uniform4f(program.uRect, x, y, pic.width, pic.height);
		gl.drawArrays(RenderingContext.TRIANGLE_STRIP, 0, 4);
	}

	public static function PicTranslate(x:Int, y:Int, pic:DrawPic, top:Int, bottom:Int):Void {
		var program = GL.UseProgram(GLPrograms.picTranslate);
		GL.Bind(program.tTexture, pic.texnum);
		GL.Bind(program.tTrans, pic.translate);
		gl.bindBuffer(RenderingContext.ARRAY_BUFFER, GL.rect);
		gl.vertexAttribPointer(program.aPoint, 2, RenderingContext.FLOAT, false, 0, 0);
		gl.uniform4f(program.uRect, x, y, pic.width, pic.height);
		var p = VID.d_8to24table[top];
		gl.uniform3f(program.uTop, p & 0xff, (p >> 8) & 0xff, p >> 16);
		p = VID.d_8to24table[bottom];
		gl.uniform3f(program.uBottom, p & 0xff, (p >> 8) & 0xff, p >> 16);
		gl.drawArrays(RenderingContext.TRIANGLE_STRIP, 0, 4);
	}

	public static function ConsoleBackground(lines:Int):Void {
		var program = GL.UseProgram(GLPrograms.pic);
		GL.Bind(program.tTexture, conback.texnum);
		gl.bindBuffer(RenderingContext.ARRAY_BUFFER, GL.rect);
		gl.vertexAttribPointer(program.aPoint, 2, RenderingContext.FLOAT, false, 0, 0);
		gl.uniform4f(program.uRect, 0, lines - VID.height, VID.width, VID.height);
		gl.drawArrays(RenderingContext.TRIANGLE_STRIP, 0, 4);
	}

	public static function Fill(x:Int, y:Int, w:Int, h:Int, c:Int):Void {
		var program = GL.UseProgram(GLPrograms.fill);
		gl.bindBuffer(RenderingContext.ARRAY_BUFFER, GL.rect);
		gl.vertexAttribPointer(program.aPoint, 2, RenderingContext.FLOAT, false, 0, 0);
		gl.uniform4f(program.uRect, x, y, w, h);
		var color = VID.d_8to24table[c];
		gl.uniform4f(program.uColor, color & 0xff, (color >> 8) & 0xff, color >> 16, 1.0);
		gl.drawArrays(RenderingContext.TRIANGLE_STRIP, 0, 4);
	}

	public static function FadeScreen():Void {
		var program = GL.UseProgram(GLPrograms.fill);
		gl.bindBuffer(RenderingContext.ARRAY_BUFFER, GL.rect);
		gl.vertexAttribPointer(program.aPoint, 2, RenderingContext.FLOAT, false, 0, 0);
		gl.uniform4f(program.uRect, 0, 0, VID.width, VID.height);
		gl.uniform4f(program.uColor, 0.0, 0.0, 0.0, 0.8);
		gl.drawArrays(RenderingContext.TRIANGLE_STRIP, 0, 4);
	}

	public static function BeginDisc():Void {
		if (loadingElem == null)
			return;
		loadingElem.style.left = ((VID.width - loading.width) >> 1) + 'px';
		loadingElem.style.top = ((VID.height - loading.height) >> 1) + 'px';
		loadingElem.style.display = 'inline-block';
	}

	public static function EndDisc():Void {
		if (loadingElem != null)
			loadingElem.style.display = 'none';
	}

	static function PicToDataURL(pic:DrawPic):String {
		var canvas:CanvasElement = cast document.createElement('canvas');
		canvas.width = pic.width;
		canvas.height = pic.height;
		var ctx = canvas.getContext('2d');
		var data = ctx.createImageData(pic.width, pic.height);
		var trans = new ArrayBuffer(data.data.length);
		var trans32 = new Uint32Array(trans);
		for (i in 0...pic.data.length)
			trans32[i] = COM.LittleLong(VID.d_8to24table[pic.data[i]] + 0xff000000);
		data.data.set(new Uint8Array(trans));
		ctx.putImageData(data, 0, 0);
		return canvas.toDataURL();
	}
}
