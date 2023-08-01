package quake;

@:publicFields
class DLight {
    var key:Int;
    var origin(default,null):Vec;
    var radius:Float;
    var minlight:Float;
    var decay:Float;
    var die:Float;
    function new() {
        key = 0;
        origin = new Vec();
        radius = 0;
        minlight = 0;
        decay = 0;
        die = 0;
    }

    inline function alloc(k:Int) {
        key = k;
        origin.setVector(Vec.origin);
        radius = 0;
        minlight = 0;
        decay = 0;
        die = 0;
    }
}