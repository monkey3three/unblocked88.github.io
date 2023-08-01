package quake;

import js.html.ArrayBuffer;
import js.html.Float32Array;
import js.html.Int32Array;

@:build(quake.EdictVarsMacro.build())
class EdictVars {
    var modelindex:Float; // 0 // float
    var absmin:Vec; // 1 // vec3
    var absmax:Vec; // 4 // vec3
    var ltime:Float; // 7 // float
    var movetype:Float; // 8 // float
    var solid:Float; // 9 // float
    var origin:Vec; // 10 // vec3
    var oldorigin:Vec; // 13 // vec3
    var velocity:Vec; // 16 // vec3
    var angles:Vec; // 19 // vec3
    var avelocity:Vec; // 22 // vec3
    var punchangle:Vec; // 25 // vec3
    var classname:Int; // 28 // string
    var model:Int; // 29 // string
    var frame:Float; // 30 // float
    var skin:Float; // 31 // float
    var effects:Float; // 32 // float
    var mins:Vec; // 33 // vec3
    var maxs:Vec; // 36 // vec3
    var size:Vec; // 39 // vec3
    var touch:Int; // 42 // func
    var use:Int; // 43 // func
    var think:Int; // 44 // func
    var blocked:Int; // 45 // func
    var nextthink:Float; // 46 // float
    var groundentity:Int; // 47 // edict
    var health:Float; // 48 // float
    var frags:Float; // 49 // float
    var weapon:Float; // 50 // float
    var weaponmodel:Int; // 51 // string
    var weaponframe:Float; // 52 // float
    var currentammo:Float; // 53 // float
    var ammo_shells:Float; // 54 // float
    var ammo_nails:Float; // 55 // float
    var ammo_rockets:Float; // 56 // float
    var ammo_cells:Float; // 57 // float
    var items:Float; // 58 // float
    var takedamage:Float; // 59 // float
    var chain:Int; // 60 // edict
    var deadflag:Float; // 61 // float
    var view_ofs:Vec; // 62 // vec3
    var button0:Float; // 65 // float
    var button1:Float; // 66 // float
    var button2:Float; // 67 // float
    var impulse:Float; // 68 // float
    var fixangle:Float; // 69 // float
    var v_angle:Vec; // 70 // vec3
    var idealpitch:Float; // 73 // float
    var netname:Int; // 74 // string
    var enemy:Int; // 75 // edict
    var flags:Float; // 76 // float
    var colormap:Float; // 77 // float
    var team:Float; // 78 // float
    var max_health:Float; // 79 // float
    var teleport_time:Float; // 80 // float
    var armortype:Float; // 81 // float
    var armorvalue:Float; // 82 // float
    var waterlevel:Float; // 83 // float
    var watertype:Float; // 84 // float
    var ideal_yaw:Float; // 85 // float
    var yaw_speed:Float; // 86 // float
    var aiment:Int; // 87 // edict
    var goalentity:Int; // 88 // edict
    var spawnflags:Float; // 89 // float
    var target:Int; // 90 // string
    var targetname:Int; // 91 // string
    var dmg_take:Float; // 92 // float
    var dmg_save:Float; // 93 // float
    var dmg_inflictor:Int; // 94 // edict
    var owner:Int; // 95 // edict
    var movedir:Vec; // 96 // vec3
    var message:Int; // 99 // string
    var sounds:Float; // 100 // float
    var noise:Int; // 101 // string
    var noise1:Int; // 102 // string
    var noise2:Int; // 103 // string
    var noise3:Int; // 104 // string

    @:dyn var ammo_shells1:Float;
    @:dyn var ammo_nails1:Float;
    @:dyn var ammo_lava_nails:Float;
    @:dyn var ammo_rockets1:Float;
    @:dyn var ammo_multi_rockets:Float;
    @:dyn var ammo_cells1:Float;
    @:dyn var ammo_plasma:Float;
    @:dyn var gravity:Float;
    @:dyn var items2:Float;

    public static var ammo_shells1_ofs:Null<Int> = null;
    public static var ammo_nails1_ofs:Null<Int> = null;
    public static var ammo_lava_nails_ofs:Null<Int> = null;
    public static var ammo_rockets1_ofs:Null<Int> = null;
    public static var ammo_multi_rockets_ofs:Null<Int> = null;
    public static var ammo_cells1_ofs:Null<Int> = null;
    public static var ammo_plasma_ofs:Null<Int> = null;
    public static var gravity_ofs:Null<Int> = null;
    public static var items2_ofs:Null<Int> = null;

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
}
