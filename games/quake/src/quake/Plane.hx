package quake;

@:publicFields
class Plane {
    var type:Int = 0;
    var normal(default,never):Vec = new Vec();
    var dist:Float = 0;
    var signbits:Int = 0;

    function new() {}
}
