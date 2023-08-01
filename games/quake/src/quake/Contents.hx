package quake;

@:enum abstract Contents(Int) from Int to Int {
    var empty = -1;
    var solid = -2;
    var water = -3;
    var slime = -4;
    var lava = -5;
    var sky = -6;
    var origin = -7;
    var clip = -8;
    var current_0 = -9;
    var current_90 = -10;
    var current_180 = -11;
    var current_270 = -12;
    var current_up = -13;
    var current_down = -14;

    @:op(a<b) static function _(a:Contents, b:Contents):Bool;
    @:op(a>b) static function _(a:Contents, b:Contents):Bool;
    @:op(a<=b) static function _(a:Contents, b:Contents):Bool;
    @:op(a>=b) static function _(a:Contents, b:Contents):Bool;
}
