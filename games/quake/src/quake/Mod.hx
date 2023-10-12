package quake;

import js.html.DataView;
import js.html.Uint8Array;
import js.html.webgl.Buffer;
import js.html.webgl.Texture;
import quake.GL.gl;

import quake.Mod_Alias.Trivert;
import quake.Mod_Alias.Skin;
import quake.Mod_Brush.Hull;
import quake.Mod_Brush.ClipNode;
import quake.Mod_Brush.Surface;
import quake.Mod_Brush.Leaf;
import quake.Mod_Brush.Node;
import quake.Mod_Brush.Texinfo;
import quake.Mod_Brush.MTexture;

@:enum abstract ModelType(Int) {
    var brush = 0;
    var sprite = 1;
    var alias = 2;
}

@:publicFields
class MModel {
    var flags:ModelEffect;
    var oriented:Bool;
    var numframes:Int;
    var frames:Array<MFrame>;
    var boundingradius:Float;
    var player:Bool;
    var numtris:Int;
    var cmds:Buffer;
    var numskins:Int;
    var skins:Array<Skin>;
    var type:ModelType;
    var mins:Vec;
    var maxs:Vec;
    var radius:Float;
    var submodel:Bool;
    var submodels:Array<MModel>;
    var lightdata:Uint8Array;
    var chains:Array<Array<Int>>;
    var textures:Array<MTexture>;
    var waterchain:Int;
    var skychain:Int;
    var leafs:Array<Leaf>;
    var numfaces:Int;
    var faces:Array<Surface>;
    var firstface:Int;
    var marksurfaces:Array<Int>;
    var texinfo:Array<Texinfo>;
    var name:String;
    var vertexes:Array<Vec>;
    var edges:Array<Array<Int>>;
    var surfedges:Array<Int>;
    var visdata:Uint8Array;
    var random:Bool;
    var nodes:Array<Node>;
    var hulls:Array<Hull>;
    var entities:String;
    var needload:Bool;
    var scale:Vec;
    var scale_origin:Vec;
    var skinwidth:Int;
    var skinheight:Int;
    var numverts:Int;
    var width:Int;
    var height:Int;
    var planes:Array<Plane>;
    var clipnodes:Array<ClipNode>;
    var origin:Vec;

    function new(name:String) {
        this.name = name;
        this.needload = true;
    }
}


@:publicFields
class MFrame {
    var name:String;
    var group:Bool;
    var frames:Array<MFrame>;
    var interval:Float;
    var origin:Array<Int>;
    var width:Int;
    var height:Int;
    var texturenum:Texture;
    var cmdofs:Int;
    var bboxmin:Array<Int>;
    var bboxmax:Array<Int>;
    var v:Array<Trivert>;
    function new(g) {
        this.group = g;
    }
}

@:enum abstract ModelEffect(Int) to Int {
    var rocket = 1;
    var grenade = 2;
    var gib = 4;
    var rotate = 8;
    var tracer = 16;
    var zomgib = 32;
    var tracer2 = 64;
    var tracer3 = 128;
}

class Mod {
    static var known:Array<MModel> = [];

    public static function Init():Void {
        Mod_Brush.Init();
        Mod_Alias.Init();
    }

    public static function ClearAll():Void {
        for (i in 0...known.length) {
            var mod = known[i];
            if (mod.type != brush)
                continue;
            if (mod.cmds != null)
                gl.deleteBuffer(mod.cmds);
            known[i] = new MModel(mod.name);
        }
    }

    public static function FindName(name:String):MModel {
        if (name.length == 0)
            Sys.Error('Mod.FindName: NULL name');
        for (mod in known) {
            if (mod == null)
                continue;
            if (mod.name == name)
                return mod;
        }
        for (i in 0...known.length + 1) {
            if (known[i] != null)
                continue;
            return known[i] = new MModel(name);
        }
        return null;
    }

    static inline var IDPOLYHEADER = ('O'.code << 24) + ('P'.code << 16) + ('D'.code << 8) + 'I'.code; // little-endian "IDPO"
    static inline var IDSPRITEHEADER = ('P'.code << 24) + ('S'.code << 16) + ('D'.code << 8) + 'I'.code; // little-endian "IDSP"

    static function LoadModel(mod:MModel, crash:Bool):MModel {
        if (!mod.needload)
            return mod;
        var buf = COM.LoadFile(mod.name);
        if (buf == null) {
            if (crash)
                Sys.Error('Mod.LoadModel: ' + mod.name + ' not found');
            return null;
        }
        mod.needload = false;
        var view = new DataView(buf);
        switch (view.getUint32(0, true)) {
            case IDPOLYHEADER:
                Mod_Alias.LoadAliasModel(mod, view);
            case IDSPRITEHEADER:
                Mod_Sprite.LoadSpriteModel(mod, view);
            default:
                Mod_Brush.LoadBrushModel(mod, view);
        }
        return mod;
    }

    public static inline function ForName(name:String, crash:Bool):MModel {
        return LoadModel(FindName(name), crash);
    }

    public static function Print() {
        Console.Print('Cached models:\n');
        for (mod in known)
            Console.Print(mod.name + '\n');
    }
}
