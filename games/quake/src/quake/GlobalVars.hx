package quake;

import js.html.ArrayBuffer;
import js.html.Float32Array;
import js.html.Int32Array;

import quake.PR.PROffset;

@:build(quake.GlobalVarsMacro.build())
class GlobalVars {
    var self:Int; // 28 // edict
    var other:Int; // 29 // edict
    var world:Int; // 30 // edict
    var time:Float; // 31 // float
    var frametime:Float; // 32 // float
    var force_retouch:Float; // 33 // float
    var mapname:Int; // 34 // string
    var deathmatch:Float; // 35 // float
    var coop:Float; // 36 // float
    var teamplay:Float; // 37 // float
    var serverflags:Float; // 38 // float
    var total_secrets:Float; // 39 // float
    var total_monsters:Float; // 40 // float
    var found_secrets:Float; // 41 // float
    var killed_monsters:Float; // 42 // float

    var parms:Float; // 43 // float[16]
    var parms1:Float; // 44
    var parms2:Float; // 45
    var parms3:Float; // 46
    var parms4:Float; // 47
    var parms5:Float; // 48
    var parms6:Float; // 49
    var parms7:Float; // 50
    var parms8:Float; // 51
    var parms9:Float; // 52
    var parms10:Float; // 53
    var parms11:Float; // 54
    var parms12:Float; // 55
    var parms13:Float; // 56
    var parms14:Float; // 57
    var parms15:Float; // 58

    var v_forward:Vec; // 59 // vec3
    var v_up:Vec; // 62 // vec3
    var v_right:Vec; // 65 // vec3
    var trace_allsolid:Float; // 68 // float
    var trace_startsolid:Float; // 69 // float
    var trace_fraction:Float; // 70 // float
    var trace_endpos:Vec; // 71 // vec3
    var trace_plane_normal:Vec; // 74 // vec3
    var trace_plane_dist:Float; // 77 // float
    var trace_ent:Int; // 78 // edict
    var trace_inopen:Float; // 79 // float
    var trace_inwater:Float; // 80 // float
    var msg_entity:Int; // 81 // edict
    var main:Int; // 82 // func
    var StartFrame:Int; // 83 // func
    var PlayerPreThink:Int; // 84 // func
    var PlayerPostThink:Int; // 85 // func
    var ClientKill:Int; // 86 // func
    var ClientConnect:Int; // 87 // func
    var PutClientInServer:Int; // 88 // func
    var ClientDisconnect:Int; // 89 // func
    var SetNewParms:Int; // 90 // func
    var SetChangeParms:Int; // 91 // func

    public var buffer(default,null):ArrayBuffer;
    public var floats(default,null):Float32Array;
    public var ints(default,null):Int32Array;

    public function new(buf) {
        buffer = buf;
        floats = new Float32Array(buf);
        ints = new Int32Array(buf);
        init();
    }

    inline function init():Void;

    public inline function SetReturnVector(v:Vec):Void {
        floats[OFS_RETURN] = v[0];
        floats[OFS_RETURN + 1] = v[1];
        floats[OFS_RETURN + 2] = v[2];
    }

    public inline function SetReturnFloat(f:Float):Void {
        floats[OFS_RETURN] = f;
    }

    public inline function SetReturnInt(i:Int):Void {
        ints[OFS_RETURN] = i;
    }

    public inline function GetVector(ofs:Int):Vec {
        return Vec.of(floats[ofs], floats[ofs + 1], floats[ofs + 2]);
    }

    public inline function GetFloat(ofs:Int):Float {
        return floats[ofs];
    }

    public inline function GetInt(ofs:Int):Int {
        return ints[ofs];
    }

    public inline function GetParms():Array<Float> {
        return [
            parms,
            parms1,
            parms2,
            parms3,
            parms4,
            parms5,
            parms6,
            parms7,
            parms8,
            parms9,
            parms10,
            parms11,
            parms12,
            parms13,
            parms14,
            parms15
        ];
    }

    public inline function SetParms(values:Array<Float>):Void {
        parms = values[0];
        parms1 = values[1];
        parms2 = values[2];
        parms3 = values[3];
        parms4 = values[4];
        parms5 = values[5];
        parms6 = values[6];
        parms7 = values[7];
        parms8 = values[8];
        parms9 = values[9];
        parms10 = values[10];
        parms11 = values[11];
        parms12 = values[12];
        parms13 = values[13];
        parms14 = values[14];
        parms15 = values[15];
    }
}
