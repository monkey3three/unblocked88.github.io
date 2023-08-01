package quake;

import js.Browser.document;
import js.html.ArrayBuffer;
import js.html.Float32Array;
import js.html.Uint32Array;
import js.html.Uint8Array;
import js.html.webgl.Buffer;
import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;

@:publicFields
private class GLModeSetting {
    var min:Int;
    var max:Int;
    function new(min, max) {
        this.min = min;
        this.max = max;
    }
}

@:publicFields
class GLTexture {
    var texnum:Texture;
    var identifier:String;
    var width:Int;
    var height:Int;

    function new(id, w, h) {
        this.texnum = GL.gl.createTexture();
        this.identifier = id;
        this.width = w;
        this.height = h;
    }
}

class GL {
    public static var gl(default,null):RenderingContext;
    public static var rect(default,null):Buffer;
    public static var textures(default,null):Array<GLTexture> = [];
    public static var programs(default,null):Array<GLProgram> = [];
    public static var filter_min(default,null):Int;
    public static var filter_max(default,null):Int;
    public static var maxtexturesize(default,null):Int;
    public static var ortho(default,null) = [
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.00001, 0.0,
        -1.0, 1.0, 0.0, 1.0
    ];
    public static var identity(default,null) = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0];

    static var picmip:Cvar;
    static var activetexture:Int;
    static var currenttextures = new Map<Int,Texture>();
    static var currentProgram:GLProgram;
    static var modes:Map<String,GLModeSetting>;

    public static function Bind(target:Int, texnum:Texture):Void {
        if (currenttextures[target] != texnum) {
            if (activetexture != target) {
                activetexture = target;
                gl.activeTexture(RenderingContext.TEXTURE0 + target);
            }
            currenttextures[target] = texnum;
            gl.bindTexture(RenderingContext.TEXTURE_2D, texnum);
        }
    }

    static function TextureMode_f():Void {
        if (Cmd.argv.length <= 1) {
            for (name in modes.keys()) {
                var mode = modes[name];
                if (filter_min == mode.min) {
                    Console.Print(name + '\n');
                    return;
                }
            }
            Console.Print('current filter is unknown???\n');
            return;
        }
        var name = Cmd.argv[1].toUpperCase();
        var mode = modes[name];
        if (mode == null) {
            Console.Print('bad filter name\n');
            return;
        }
        filter_min = mode.min;
        filter_max = mode.max;
        for (tex in textures) {
            Bind(0, tex.texnum);
            gl.texParameterf(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, filter_min);
            gl.texParameterf(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, filter_max);
        }
    }

    public static function Set2D():Void {
        gl.viewport(0, 0, Std.int(VID.width * SCR.devicePixelRatio), Std.int(VID.height * SCR.devicePixelRatio));
        UnbindProgram();
        for (program in programs) {
            program.use();
            program.setOrtho(ortho);
        }
        gl.disable(RenderingContext.DEPTH_TEST);
        gl.enable(RenderingContext.BLEND);
    }

    public static function ResampleTexture(data:Uint8Array, inwidth:Int, inheight:Int, outwidth:Int, outheight:Int):Uint8Array {
        var outdata = new ArrayBuffer(outwidth * outheight);
        var out = new Uint8Array(outdata);
        var xstep = inwidth / outwidth, ystep = inheight / outheight;
        var src, dest = 0, y;
        for (i in 0...outheight) {
            src = Math.floor(i * ystep) * inwidth;
            for (j in 0...outwidth)
                out[dest + j] = data[src + Math.floor(j * xstep)];
            dest += outwidth;
        }
        return out;
    }

    public static function Upload(data:Uint8Array, width:Int, height:Int):Void {
        var scaled_width = width, scaled_height = height;
        if (((width & (width - 1)) != 0) || ((height & (height - 1)) != 0)) {
            --scaled_width;
            scaled_width |= (scaled_width >> 1);
            scaled_width |= (scaled_width >> 2);
            scaled_width |= (scaled_width >> 4);
            scaled_width |= (scaled_width >> 8);
            scaled_width |= (scaled_width >> 16);
            ++scaled_width;
            --scaled_height;
            scaled_height |= (scaled_height >> 1);
            scaled_height |= (scaled_height >> 2);
            scaled_height |= (scaled_height >> 4);
            scaled_height |= (scaled_height >> 8);
            scaled_height |= (scaled_height >> 16);
            ++scaled_height;
        }
        if (scaled_width > maxtexturesize)
            scaled_width = maxtexturesize;
        if (scaled_height > maxtexturesize)
            scaled_height = maxtexturesize;
        if ((scaled_width != width) || (scaled_height != height))
            data = ResampleTexture(data, width, height, scaled_width, scaled_height);
        var trans = new ArrayBuffer((scaled_width * scaled_height) << 2);
        var trans32 = new Uint32Array(trans);
        var i = scaled_width * scaled_height - 1;
        while (i >= 0) {
            trans32[i] = COM.LittleLong(VID.d_8to24table[data[i]] + 0xff000000);
            if (data[i] >= 224)
                trans32[i] &= 0xffffff;
            i--;
        }
        gl.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, scaled_width, scaled_height, 0, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, new Uint8Array(trans));
        gl.generateMipmap(RenderingContext.TEXTURE_2D);
        gl.texParameterf(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, filter_min);
        gl.texParameterf(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, filter_max);
    }

    public static function LoadTexture(identifier:String, width:Int, height:Int, data:Uint8Array):GLTexture {
        if (identifier.length != 0) {
            for (glt in textures) {
                if (glt.identifier == identifier) {
                    if (width != glt.width || height != glt.height)
                        Sys.Error('GL.LoadTexture: cache mismatch');
                    return glt;
                }
            }
        }

        var scaled_width = width, scaled_height = height;
        if (((width & (width - 1)) != 0) || ((height & (height - 1)) != 0)) {
            --scaled_width ;
            scaled_width |= (scaled_width >> 1);
            scaled_width |= (scaled_width >> 2);
            scaled_width |= (scaled_width >> 4);
            scaled_width |= (scaled_width >> 8);
            scaled_width |= (scaled_width >> 16);
            ++scaled_width;
            --scaled_height;
            scaled_height |= (scaled_height >> 1);
            scaled_height |= (scaled_height >> 2);
            scaled_height |= (scaled_height >> 4);
            scaled_height |= (scaled_height >> 8);
            scaled_height |= (scaled_height >> 16);
            ++scaled_height;
        }
        if (scaled_width > maxtexturesize)
            scaled_width = maxtexturesize;
        if (scaled_height > maxtexturesize)
            scaled_height = maxtexturesize;
        scaled_width >>= Std.int(picmip.value);
        if (scaled_width == 0)
            scaled_width = 1;
        scaled_height >>= Std.int(picmip.value);
        if (scaled_height == 0)
            scaled_height = 1;
        if (scaled_width != width || scaled_height != height)
            data = ResampleTexture(data, width, height, scaled_width, scaled_height);

        var glt = new GLTexture(identifier, width, height);
        Bind(0, glt.texnum);
        Upload(data, scaled_width, scaled_height);
        textures.push(glt);
        return glt;
    }

    public static function LoadPicTexture(pic:quake.Draw.DrawPic):Texture {
        var data = pic.data, scaled_width = pic.width, scaled_height = pic.height;
        if (((pic.width & (pic.width - 1)) != 0) || ((pic.height & (pic.height - 1)) != 0)) {
            --scaled_width ;
            scaled_width |= (scaled_width >> 1);
            scaled_width |= (scaled_width >> 2);
            scaled_width |= (scaled_width >> 4);
            scaled_width |= (scaled_width >> 8);
            scaled_width |= (scaled_width >> 16);
            ++scaled_width;
            --scaled_height;
            scaled_height |= (scaled_height >> 1);
            scaled_height |= (scaled_height >> 2);
            scaled_height |= (scaled_height >> 4);
            scaled_height |= (scaled_height >> 8);
            scaled_height |= (scaled_height >> 16);
            ++scaled_height;
        }
        if (scaled_width > maxtexturesize)
            scaled_width = maxtexturesize;
        if (scaled_height > maxtexturesize)
            scaled_height = maxtexturesize;
        if (scaled_width != pic.width || scaled_height != pic.height)
            data = ResampleTexture(data, pic.width, pic.height, scaled_width, scaled_height);

        var texnum = gl.createTexture();
        Bind(0, texnum);
        var trans = new ArrayBuffer((scaled_width * scaled_height) << 2);
        var trans32 = new Uint32Array(trans);
        var i = scaled_width * scaled_height - 1;
        while (i >= 0) {
            if (data[i] != 255)
                trans32[i] = COM.LittleLong(VID.d_8to24table[data[i]] + 0xff000000);
            i--;
        }
        gl.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, scaled_width, scaled_height, 0, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, new Uint8Array(trans));
        gl.texParameterf(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, RenderingContext.LINEAR);
        gl.texParameterf(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, RenderingContext.LINEAR);
        return texnum;
    }

    static inline function AddProgram<T:GLProgram>(program:T):T {
        programs.push(program);
        return program;
    }

    public static function UseProgram<T:GLProgram>(program:T):T {
        if (currentProgram == program)
            return program;
        if (currentProgram != null)
            currentProgram.unbind();
        currentProgram = program;
        program.use();
        program.bind();
        return program;
    }

    public static function UnbindProgram():Void {
        if (currentProgram == null)
            return;
        currentProgram.unbind();
        currentProgram = null;
    }

    public static function RotationMatrix(pitch:Float, yaw:Float, roll:Float):Array<Float> {
        pitch *= Math.PI / -180.0;
        yaw *= Math.PI / 180.0;
        roll *= Math.PI / 180.0;
        var sp = Math.sin(pitch);
        var cp = Math.cos(pitch);
        var sy = Math.sin(yaw);
        var cy = Math.cos(yaw);
        var sr = Math.sin(roll);
        var cr = Math.cos(roll);
        return [
            cy * cp,                    sy * cp,                    -sp,
            -sy * cr + cy * sp * sr,    cy * cr + sy * sp * sr,     cp * sr,
            -sy * -sr + cy * sp * cr,   cy * -sr + sy * sp * cr,    cp * cr
        ];
    }

    public static function Init() {
        VID.mainwindow = cast document.getElementById('mainwindow');
        try {
            gl = VID.mainwindow.getContext('webgl');
            if (gl == null)
                VID.mainwindow.getContext('experimental-webgl');
        } catch (e:Any) {}
        if (gl == null)
            Sys.Error('Unable to initialize WebGL. Your browser may not support it.');

        maxtexturesize = gl.getParameter(RenderingContext.MAX_TEXTURE_SIZE);

        gl.clearColor(0.0, 0.0, 0.0, 0.0);
        gl.cullFace(RenderingContext.FRONT);
        gl.blendFuncSeparate(RenderingContext.SRC_ALPHA, RenderingContext.ONE_MINUS_SRC_ALPHA, RenderingContext.ONE, RenderingContext.ONE);

        modes = [
            'GL_NEAREST' => new GLModeSetting(RenderingContext.NEAREST, RenderingContext.NEAREST),
            'GL_LINEAR' => new GLModeSetting(RenderingContext.LINEAR, RenderingContext.LINEAR),
            'GL_NEAREST_MIPMAP_NEAREST' => new GLModeSetting(RenderingContext.NEAREST_MIPMAP_NEAREST, RenderingContext.NEAREST),
            'GL_LINEAR_MIPMAP_NEAREST' => new GLModeSetting(RenderingContext.LINEAR_MIPMAP_NEAREST, RenderingContext.LINEAR),
            'GL_NEAREST_MIPMAP_LINEAR' => new GLModeSetting(RenderingContext.NEAREST_MIPMAP_LINEAR, RenderingContext.NEAREST),
            'GL_LINEAR_MIPMAP_LINEAR' => new GLModeSetting(RenderingContext.LINEAR_MIPMAP_LINEAR, RenderingContext.LINEAR),
        ];

        var defaultMode = modes["GL_LINEAR_MIPMAP_NEAREST"];
        filter_min = defaultMode.min;
        filter_max = defaultMode.max;

        picmip = Cvar.RegisterVariable('gl_picmip', '0');
        Cmd.AddCommand('gl_texturemode', GL.TextureMode_f);

        rect = gl.createBuffer();
        gl.bindBuffer(RenderingContext.ARRAY_BUFFER, rect);
        gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32Array([0, 0, 0, 1, 1, 0, 1, 1]), RenderingContext.STATIC_DRAW);

        VID.mainwindow.style.display = 'inline-block';

        GLPrograms.init(gl);
    }
}
