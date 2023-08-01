package quake;

@:enum abstract ClientStat(Int) to Int {
	var health = 0;
	var frags = 1;
	var weapon = 2;
	var ammo = 3;
	var armor = 4;
	var weaponframe = 5;
	var shells = 6;
	var nails = 7;
	var rockets = 8;
	var cells = 9;
	var activeweapon = 10;
	var totalsecrets = 11;
	var totalmonsters = 12;
	var secrets = 13;
	var monsters = 14;
}

@:publicFields
class Def {
	static macro function getVersion():haxe.macro.Expr.ExprOf<String> {
		return macro $v{haxe.macro.Context.definedValue("version")};
	}

	static inline var timedate = 'Exe: 12:39:20 Aug  7 2014\n';
	static inline var max_edicts = 2048;

	static var it = {
		shotgun: 1,
		super_shotgun: 2,
		nailgun: 4,
		super_nailgun: 8,
		grenade_launcher: 16,
		rocket_launcher: 32,
		lightning: 64,
		super_lightning: 128,
		shells: 256,
		nails: 512,
		rockets: 1024,
		cells: 2048,
		axe: 4096,
		armor1: 8192,
		armor2: 16384,
		armor3: 32768,
		superhealth: 65536,
		key1: 131072,
		key2: 262144,
		invisibility: 524288,
		invulnerability: 1048576,
		suit: 2097152,
		quad: 4194304
	};

	static var rit = {
		shells: 128,
		nails: 256,
		rockets: 512,
		cells: 1024,
		axe: 2048,
		lava_nailgun: 4096,
		lava_super_nailgun: 8192,
		multi_grenade: 16384,
		multi_rocket: 32768,
		plasma_gun: 65536,
		armor1: 8388608,
		armor2: 16777216,
		armor3: 33554432,
		lava_nails: 67108864,
		plasma_ammo: 134217728,
		multi_rockets: 268435456,
		shield: 536870912,
		antigrav: 1073741824,
		superhealth: 2147483648
	};

	static var hit = {
		proximity_gun_bit: 16,
		mjolnir_bit: 7,
		laser_cannon_bit: 23,
		proximity_gun: 65536,
		mjolnir: 128,
		laser_cannon: 8388608,
		wetsuit: 33554432,
		empathy_shields: 67108864
	};
}
