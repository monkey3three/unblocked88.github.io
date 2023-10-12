package quake;

import quake.Mod.MModel;

@:publicFields
class Entity {
    var leafs:Array<Int> = [];
    var model:MModel;
    var angles(default,never) = new Vec();
    var msg_angles0(default,never) = new Vec();
    var msg_angles1(default,never) = new Vec();
    var origin(default,never) = new Vec();
    var msg_origins0(default,never) = new Vec();
    var msg_origins1(default,never) = new Vec();
    var frame = 0;
    var syncbase = 0.0;
    var colormap:Int;
    var num:Int;
    var skinnum = 0;
    var msgtime = 0.0;
    var forcelink:Bool;
    var effects = EF_NONE;
    var update_type = 0;
    var visframe = 0;
    var dlightframe = 0;
    var dlightbits = 0;
    var baseline(default,never) = new EntityState();
    function new(n = -1) {
        num = n;
    }
}

@:publicFields
class EntityState {
    var origin(default,never) = new Vec();
    var angles(default,never) = new Vec();
    var modelindex = 0;
    var frame = 0;
    var colormap = 0;
    var skin = 0;
    var effects = EF_NONE;
    function new() {}
}

@:enum abstract EntityEffect(Int) to Int {
    var EF_NONE = 0;
    var EF_BRIGHTFIELD = 1;
    var EF_MUZZLEFLASH = 2;
    var EF_BRIGHTLIGHT = 4;
    var EF_DIMLIGHT = 8;
}
