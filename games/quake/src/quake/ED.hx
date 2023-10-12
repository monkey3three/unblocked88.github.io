package quake;

import js.html.ArrayBuffer;
import js.html.Float32Array;
import js.html.Int32Array;
import quake.PR.EType;
import quake.PR.PRDef;
import quake.SV.MoveType;

@:publicFields
class ED {
	static function Alloc():Edict {
		var i = SV.svs.maxclients + 1;
		while (i < SV.server.num_edicts) {
			var e = SV.server.edicts[i++];
			if (e.free && (e.freetime < 2.0 || (SV.server.time - e.freetime) > 0.5)) {
				e.Clear();
				return e;
			}
		}
		if (i == Def.max_edicts)
			Sys.Error('ED.Alloc: no free edicts (max_edicts is ${Def.max_edicts})');
		var e = SV.server.edicts[SV.server.num_edicts++];
		e.Clear();
		return e;
	}

	static function Free(ed:Edict):Void {
		SV.UnlinkEdict(ed);
		ed.free = true;
		ed.v.model = 0;
		ed.v.takedamage = 0.0;
		ed.v.modelindex = 0.0;
		ed.v.colormap = 0.0;
		ed.v.skin = 0.0;
		ed.v.frame = 0.0;
		ed.v.origin.setVector(Vec.origin);
		ed.v.angles.setVector(Vec.origin);
		ed.v.nextthink = -1.0;
		ed.v.solid = 0.0;
		ed.freetime = SV.server.time;
	}

	static function GlobalAtOfs(ofs:Int):PRDef {
		for (def in PR.globaldefs) {
			if (def.ofs == ofs)
				return def;
		}
		return null;
	}

	static function FieldAtOfs(ofs:Int):PRDef {
		for (def in PR.fielddefs) {
			if (def.ofs == ofs)
				return def;
		}
		return null;
	}

	static function FindField(name:String):PRDef {
		for (def in PR.fielddefs) {
			if (PR.GetString(def.name) == name)
				return def;
		}
		return null;
	}

	static function FindGlobal(name:String):PRDef {
		for (def in PR.globaldefs) {
			if (PR.GetString(def.name) == name)
				return def;
		}
		return null;
	}

	static function FindFunction(name:String):Int {
		for (i in 0...PR.functions.length) {
			if (PR.GetString(PR.functions[i].name) == name)
				return i;
		}
		return null;
	}

	static function Print(ed:Edict):Void {
		if (ed.free) {
			Console.Print('FREE\n');
			return;
		}
		Console.Print('\nEDICT ${ed.num}:\n');
		for (i in 1...PR.fielddefs.length) {
			var d = PR.fielddefs[i];
			var name = PR.GetString(d.name);
			if (name.charCodeAt(name.length - 2) == "_".code)
				continue;
			var v = d.ofs;
			if (ed.v.ints[v] == 0) {
				if ((d.type & 0x7fff) == 3) {
					if (ed.v.ints[v + 1] == 0 && ed.v.ints[v + 2] == 0)
						continue;
				} else {
					continue;
				}
			}
			while (name.length <= 14)
				name += ' ';
			Console.Print(name + PR.ValueString(d.type, ed.v.buffer, v) + '\n');
		}
	}

	static function PrintEdicts() {
		if (!SV.server.active)
			return;
		Console.Print(SV.server.num_edicts + ' entities\n');
		for (i in 0...SV.server.num_edicts)
			Print(SV.server.edicts[i]);
	}

	static function PrintEdict_f() {
		if (!SV.server.active)
			return;
		var i = Q.atoi(Cmd.argv[1]);
		if ((i >= 0) && (i < SV.server.num_edicts))
			Print(SV.server.edicts[i]);
	}

	static function Count() {
		if (!SV.server.active)
			return;
		var active = 0, models = 0, solid = 0, step = 0;
		for (i in 0...SV.server.num_edicts) {
			var ent = SV.server.edicts[i];
			if (ent.free)
				continue;
			++active;
			if (ent.v.solid != 0.0)
				++solid;
			if (ent.v.model != 0)
				++models;
			if (ent.v.movetype == MoveType.step)
				++step;
		}
		var num_edicts = SV.server.num_edicts;
		Console.Print('num_edicts:' + (num_edicts <= 9 ? '  ' : (num_edicts <= 99 ? ' ' : '')) + num_edicts + '\n');
		Console.Print('active    :' + (active <= 9 ? '  ' : (active <= 99 ? ' ' : '')) + active + '\n');
		Console.Print('view      :' + (models <= 9 ? '  ' : (models <= 99 ? ' ' : '')) + models + '\n');
		Console.Print('touch     :' + (solid <= 9 ? '  ' : (solid <= 99 ? ' ' : '')) + solid + '\n');
		Console.Print('step      :' + (step <= 9 ? '  ' : (step <= 99 ? ' ' : '')) + step + '\n');
	}

	static function ParseGlobals(data:String):Void {
		while (true) {
			data = COM.Parse(data);
			if (COM.token.charCodeAt(0) == "}".code)
				return;
			if (data == null)
				Sys.Error('ED.ParseGlobals: EOF without closing brace');
			var keyname = COM.token;
			data = COM.Parse(data);
			if (data == null)
				Sys.Error('ED.ParseGlobals: EOF without closing brace');
			if (COM.token.charCodeAt(0) == "}".code)
				Sys.Error('ED.ParseGlobals: closing brace without data');
			var key = FindGlobal(keyname);
			if (key == null) {
				Console.Print('\'$keyname\' is not a global\n');
				continue;
			}
			if (!ParseEpair(PR.globals.buffer, key, COM.token))
				Host.Error('ED.ParseGlobals: parse error');
		}
	}

	static function NewString(string:String):Int {
		var newstring = new StringBuf();
		var i = 0;
		while (i < string.length) {
			var c = string.charCodeAt(i);
			if (c == "\\".code && i < (string.length - 1)) {
				++i;
				newstring.addChar(if (string.charCodeAt(i) == "n".code) "\n".code else "\\".code);
			} else {
				newstring.addChar(c);
			}
			i++;
		}
		return PR.NewString(newstring.toString(), string.length + 1);
	}

	static function ParseEpair(base:ArrayBuffer, key:PRDef, s:String):Bool {
		var d_float = new Float32Array(base);
		var d_int = new Int32Array(base);
		switch (key.type & 0x7fff : EType) {
			case ev_string:
				d_int[key.ofs] = NewString(s);
				return true;
			case ev_float:
				d_float[key.ofs] = Q.atof(s);
				return true;
			case ev_vector:
				var v = s.split(' ');
				d_float[key.ofs] = Q.atof(v[0]);
				d_float[key.ofs + 1] = Q.atof(v[1]);
				d_float[key.ofs + 2] = Q.atof(v[2]);
				return true;
			case ev_entity:
				d_int[key.ofs] = Q.atoi(s);
				return true;
			case ev_field:
				var d = FindField(s);
				if (d == null) {
					Console.Print('Can\'t find field ' + s + '\n');
					return false;
				}
				d_int[key.ofs] = d.ofs;
				return true;
			case ev_function:
				var d = FindFunction(s);
				if (d == null) {
					Console.Print('Can\'t find function ' + s + '\n');
					return false;
				}
				d_int[key.ofs] = d;
			default:
		}
		return true;
	}

	static function ParseEdict(data:String, ent:Edict):String {
		if (ent != SV.server.edicts[0]) {
			for (i in 0...PR.entityfields)
				ent.v.ints[i] = 0;
		}
		var init = false;
		while (true) {
			data = COM.Parse(data);
			if (COM.token.charCodeAt(0) == 125)
				break;
			if (data == null)
				Sys.Error('ED.ParseEdict: EOF without closing brace');
			var anglehack;
			if (COM.token == 'angle') {
				COM.token = 'angles';
				anglehack = true;
			} else {
				anglehack = false;
				if (COM.token == 'light')
					COM.token = 'light_lev';
			}
			var n = COM.token.length;
			while (n > 0) {
				if (COM.token.charCodeAt(n - 1) != 32)
					break;
				n--;
			}
			var keyname = COM.token.substring(0, n);
			data = COM.Parse(data);
			if (data == null)
				Sys.Error('ED.ParseEdict: EOF without closing brace');
			if (COM.token.charCodeAt(0) == 125)
				Sys.Error('ED.ParseEdict: closing brace without data');
			init = true;
			if (keyname.charCodeAt(0) == 95)
				continue;
			var key = FindField(keyname);
			if (key == null) {
				Console.Print('\'' + keyname + '\' is not a field\n');
				continue;
			}
			if (anglehack)
				COM.token = '0 ' + COM.token + ' 0';
			if (!ParseEpair(ent.v.buffer, key, COM.token))
				Host.Error('ED.ParseEdict: parse error');
		}
		if (!init)
			ent.free = true;
		return data;
	}

	static function LoadFromFile(data:String):Void {
		var ent = null, inhibit = 0;
		PR.globals.time = SV.server.time;

		while (true) {
			data = COM.Parse(data);
			if (data == null)
				break;
			if (COM.token.charCodeAt(0) != 123)
				Sys.Error('ED.LoadFromFile: found ' + COM.token + ' when expecting {');

			if (ent == null)
				ent = SV.server.edicts[0];
			else
				ent = Alloc();
			data = ParseEdict(data, ent);

			var spawnflags = Std.int(ent.v.spawnflags);
			if (Host.deathmatch.value != 0) {
				if ((spawnflags & 2048) != 0) {
					Free(ent);
					++inhibit;
					continue;
				}
			}
			else if (((Host.current_skill == 0) && ((spawnflags & 256) != 0))
				|| ((Host.current_skill == 1) && ((spawnflags & 512) != 0))
				|| ((Host.current_skill >= 2) && ((spawnflags & 1024) != 0))) {
				Free(ent);
				++inhibit;
				continue;
			}

			if (ent.v.classname == 0) {
				Console.Print('No classname for:\n');
				Print(ent);
				Free(ent);
				continue;
			}

			var func = FindFunction(PR.GetString(ent.v.classname));
			if (func == null) {
				Console.Print('No spawn function for:\n');
				Print(ent);
				Free(ent);
				continue;
			}

			PR.globals.self = ent.num;
			PR.ExecuteProgram(func);
		}

		Console.DPrint(inhibit + ' entities inhibited\n');
	}
}
