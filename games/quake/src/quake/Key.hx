package quake;

@:enum abstract KeyCode(Int) from Int to Int {
	var tab = 9;
	var enter = 13;
	var escape = 27;
	var space = 32;
	var backspace = 127;
	var uparrow = 128;
	var downarrow = 129;
	var leftarrow = 130;
	var rightarrow = 131;
	var alt = 132;
	var ctrl = 133;
	var shift = 134;
	var f1 = 135;
	var f2 = 136;
	var f3 = 137;
	var f4 = 138;
	var f5 = 139;
	var f6 = 140;
	var f7 = 141;
	var f8 = 142;
	var f9 = 143;
	var f10 = 144;
	var f11 = 145;
	var f12 = 146;
	var ins = 147;
	var del = 148;
	var pgdn = 149;
	var pgup = 150;
	var home = 151;
	var end = 152;
	var pause = 255;
	var mouse1 = 200;
	var mouse2 = 201;
	var mouse3 = 202;
	var mwheelup = 239;
	var mwheeldown = 240;

	@:op(a>b) static function _(a:KeyCode, b:KeyCode):Bool;
	@:op(a<b) static function _(a:KeyCode, b:KeyCode):Bool;
	@:op(a>=b) static function _(a:KeyCode, b:KeyCode):Bool;
	@:op(a<=b) static function _(a:KeyCode, b:KeyCode):Bool;
}

@:enum abstract KeyDest(Int) {
	var game = 0;
	var console = 1;
	var message = 2;
	var menu = 3;
}

@:publicFields
class Key {

	static var lines = [''];
	static var edit_line = '';
	static var history_line = 1;

	static var dest:KeyDest;

	static var bindings:Array<String> = [];
	static var consolekeys:Array<Bool> = [];
	static var shift:Array<Int> = [];
	static var down:Array<Bool> = [];
	static var shift_down:Bool;

	static var names = [
		{name: 'TAB', keynum: KeyCode.tab},
		{name: 'ENTER', keynum: KeyCode.enter},
		{name: 'ESCAPE', keynum: KeyCode.escape},
		{name: 'SPACE', keynum: KeyCode.space},
		{name: 'BACKSPACE', keynum: KeyCode.backspace},
		{name: 'UPARROW', keynum: KeyCode.uparrow},
		{name: 'DOWNARROW', keynum: KeyCode.downarrow},
		{name: 'LEFTARROW', keynum: KeyCode.leftarrow},
		{name: 'RIGHTARROW', keynum: KeyCode.rightarrow},
		{name: 'ALT', keynum: KeyCode.alt},
		{name: 'CTRL', keynum: KeyCode.ctrl},
		{name: 'SHIFT', keynum: KeyCode.shift},
		{name: 'F1', keynum: KeyCode.f1},
		{name: 'F2', keynum: KeyCode.f2},
		{name: 'F3', keynum: KeyCode.f3},
		{name: 'F4', keynum: KeyCode.f4},
		{name: 'F5', keynum: KeyCode.f5},
		{name: 'F6', keynum: KeyCode.f6},
		{name: 'F7', keynum: KeyCode.f7},
		{name: 'F8', keynum: KeyCode.f8},
		{name: 'F9', keynum: KeyCode.f9},
		{name: 'F10', keynum: KeyCode.f10},
		{name: 'F11', keynum: KeyCode.f11},
		{name: 'F12', keynum: KeyCode.f12},
		{name: 'INS', keynum: KeyCode.ins},
		{name: 'DEL', keynum: KeyCode.del},
		{name: 'PGDN', keynum: KeyCode.pgdn},
		{name: 'PGUP', keynum: KeyCode.pgup},
		{name: 'HOME', keynum: KeyCode.home},
		{name: 'END', keynum: KeyCode.end},
		{name: 'MOUSE1', keynum: KeyCode.mouse1},
		{name: 'MOUSE2', keynum: KeyCode.mouse2},
		{name: 'MOUSE3', keynum: KeyCode.mouse3},
		{name: 'PAUSE', keynum: KeyCode.pause},
		{name: 'MWHEELUP', keynum: KeyCode.mwheelup},
		{name: 'MWHEELDOWN', keynum: KeyCode.mwheeldown},
		{name: 'SEMICOLON', keynum: 59}
	];

	static var team_message:Bool;

	static function ProcessConsole(key) {
		if (key == KeyCode.enter) {
			Cmd.text += Key.edit_line + '\n';
			Console.Print(']' + Key.edit_line + '\n');
			Key.lines.push(Key.edit_line);
			Key.edit_line = '';
			Key.history_line = Key.lines.length;
			return;
		}

		if (key == KeyCode.tab) {
			var cmd = Cmd.CompleteCommand(Key.edit_line);
			if (cmd == null)
				cmd = Cvar.CompleteVariable(Key.edit_line);
			if (cmd == null)
				return;
			Key.edit_line = cmd + ' ';
			return;
		}

		if ((key == KeyCode.backspace) || (key == KeyCode.leftarrow)) {
			if (Key.edit_line.length > 0)
				Key.edit_line = Key.edit_line.substring(0, Key.edit_line.length - 1);
			return;
		}

		if (key == KeyCode.uparrow) {
			if (--Key.history_line < 0)
				Key.history_line = 0;
			Key.edit_line = Key.lines[Key.history_line];
			return;
		}

		if (key == KeyCode.downarrow) {
			if (Key.history_line >= Key.lines.length)
				return;
			if (++Key.history_line >= Key.lines.length) {
				Key.history_line = Key.lines.length;
				Key.edit_line = '';
				return;
			}
			Key.edit_line = Key.lines[Key.history_line];
			return;
		}

		if (key == KeyCode.pgup) {
			Console.backscroll += 2;
			if (Console.backscroll > Console.text.length)
				Console.backscroll = Console.text.length;
			return;
		}

		if (key == KeyCode.pgdn) {
			Console.backscroll -= 2;
			if (Console.backscroll < 0)
				Console.backscroll = 0;
			return;
		}

		if (key == KeyCode.home) {
			Console.backscroll = Console.text.length - 10;
			if (Console.backscroll < 0)
				Console.backscroll = 0;
			return;
		}

		if (key == KeyCode.end) {
			Console.backscroll = 0;
			return;
		}

		if ((key < 32) || (key > 127))
			return;

		Key.edit_line += String.fromCharCode(key);
	}

	static var chat_buffer = '';

	static function Message(key) {
		if (key == KeyCode.enter) {
			if (Key.team_message)
				Cmd.text += 'say_team "' + Key.chat_buffer + '"\n';
			else
				Cmd.text += 'say "' + Key.chat_buffer + '"\n';
			Key.dest = game;
			Key.chat_buffer = '';
			return;
		}
		if (key == KeyCode.escape) {
			Key.dest = game;
			Key.chat_buffer = '';
			return;
		}
		if ((key < 32) || (key > 127))
			return;
		if (key == KeyCode.backspace) {
			if (Key.chat_buffer.length != 0)
				Key.chat_buffer = Key.chat_buffer.substring(0, Key.chat_buffer.length - 1);
			return;
		}
		if (Key.chat_buffer.length >= 31)
			return;
		Key.chat_buffer = Key.chat_buffer + String.fromCharCode(key);
	}

	static function StringToKeynum(str:String):Int {
		if (str.length == 1)
			return str.charCodeAt(0);
		str = str.toUpperCase();
		for (k in names) {
			if (k.name == str)
				return k.keynum;
		}
		return null;
	}

	static function KeynumToString(keynum:Int):String {
		if ((keynum > 32) && (keynum < 127))
			return String.fromCharCode(keynum);
		for (k in names) {
			if (k.keynum == keynum)
				return k.name;
		}
		return '<UNKNOWN KEYNUM>';
	}

	static function Unbind_f() {
		if (Cmd.argv.length != 2) {
			Console.Print('unbind <key> : remove commands from a key\n');
			return;
		}
		var b = Key.StringToKeynum(Cmd.argv[1]);
		if (b == null) {
			Console.Print('"' + Cmd.argv[1] + '" isn\'t a valid key\n');
			return;
		}
		Key.bindings[b] = null;
	}

	static function Unbindall_f():Void {
		Key.bindings = [];
	}

	static function Bind_f():Void {
		var c = Cmd.argv.length;
		if ((c != 2) && (c != 3)) {
			Console.Print('bind <key> [command] : attach a command to a key\n');
			return;
		}
		var b = Key.StringToKeynum(Cmd.argv[1]);
		if (b == null) {
			Console.Print('"' + Cmd.argv[1] + '" isn\'t a valid key\n');
			return;
		}
		if (c == 2) {
			if (Key.bindings[b] != null)
				Console.Print('"' + Cmd.argv[1] + '" = "' + Key.bindings[b] + '"\n');
			else
				Console.Print('"' + Cmd.argv[1] + '" is not bound\n');
			return;
		}

		var cmd = Cmd.argv[2];
		for (i in 3...c) {
			cmd += ' ' + Cmd.argv[i];
		}
		Key.bindings[b] = cmd;
	}

	static function WriteBindings():String {
		var f = new StringBuf();
		for (i in 0...bindings.length) {
			var b = bindings[i];
			if (b != null)
				f.add('bind "' + KeynumToString(i) + '" "' + b + '"\n');
		}
		return f.toString();
	}

	static function Init():Void {
		for (i in 32...128)
			Key.consolekeys[i] = true;
		Key.consolekeys[KeyCode.enter] = true;
		Key.consolekeys[KeyCode.tab] = true;
		Key.consolekeys[KeyCode.leftarrow] = true;
		Key.consolekeys[KeyCode.rightarrow] = true;
		Key.consolekeys[KeyCode.uparrow] = true;
		Key.consolekeys[KeyCode.downarrow] = true;
		Key.consolekeys[KeyCode.backspace] = true;
		Key.consolekeys[KeyCode.home] = true;
		Key.consolekeys[KeyCode.end] = true;
		Key.consolekeys[KeyCode.pgup] = true;
		Key.consolekeys[KeyCode.pgdn] = true;
		Key.consolekeys[KeyCode.shift] = true;
		Key.consolekeys[96] = false;
		Key.consolekeys[126] = false;

		for (i in 0...256)
			Key.shift[i] = i;
		for (i in 97...123)
			Key.shift[i] = i - 32;
		Key.shift[49] = 33;
		Key.shift[50] = 64;
		Key.shift[51] = 35;
		Key.shift[52] = 36;
		Key.shift[53] = 37;
		Key.shift[54] = 94;
		Key.shift[55] = 38;
		Key.shift[56] = 42;
		Key.shift[57] = 40;
		Key.shift[48] = 41;
		Key.shift[45] = 95;
		Key.shift[61] = 43;
		Key.shift[43] = 60;
		Key.shift[46] = 62;
		Key.shift[47] = 63;
		Key.shift[59] = 58;
		Key.shift[39] = 34;
		Key.shift[91] = 123;
		Key.shift[93] = 125;
		Key.shift[96] = 126;
		Key.shift[92] = 124;

		Cmd.AddCommand('bind', Key.Bind_f);
		Cmd.AddCommand('unbind', Key.Unbind_f);
		Cmd.AddCommand('unbindall', Key.Unbindall_f);
	}

	static function Event(key:KeyCode, down:Bool):Void {
		if (CL.cls.state == connecting)
			return;
		if (down) {
			if ((key != KeyCode.backspace) && (key != KeyCode.pause) && (Key.down[key]))
				return;
			if ((key >= 200) && (Key.bindings[key] == null))
				Console.Print(Key.KeynumToString(key) + ' is unbound, hit F4 to set.\n');
		}
		Key.down[key] = down;

		if (key == KeyCode.shift)
			Key.shift_down = down;

		if (key == KeyCode.escape) {
			if (!down)
				return;
			if (Key.dest == message)
				Key.Message(key);
			else if (Key.dest == menu)
				Menu.Keydown(key);
			else
				Menu.ToggleMenu_f();
			return;
		}

		var kb;

		if (!down) {
			kb = Key.bindings[key];
			if (kb != null) {
				if (kb.charCodeAt(0) == 43)
					Cmd.text += '-' + kb.substring(1) + ' ' + key + '\n';
			}
			if (Key.shift[key] != key) {
				kb = Key.bindings[Key.shift[key]];
				if (kb != null) {
					if (kb.charCodeAt(0) == 43)
						Cmd.text += '-' + kb.substring(1) + ' ' + key + '\n';
				}
			}
			return;
		}

		if ((CL.cls.demoplayback) && (Key.consolekeys[key]) && (Key.dest == game)) {
			Menu.ToggleMenu_f();
			return;
		}

		if (((Key.dest == menu) && ((key == KeyCode.escape) || ((key >= KeyCode.f1) && (key <= KeyCode.f12))))
			|| ((Key.dest == console) && !Key.consolekeys[key])
			|| ((Key.dest == game) && (!Console.forcedup || !Key.consolekeys[key]))) {
			kb = Key.bindings[key];
			if (kb != null) {
				if (kb.charCodeAt(0) == 43)
					Cmd.text += kb + ' ' + key + '\n';
				else
					Cmd.text += kb + '\n';
			}
			return;
		}

		if (Key.shift_down)
			key = Key.shift[key];

		if (Key.dest == message)
			Key.Message(key);
		else if (Key.dest == menu)
			Menu.Keydown(key);
		else
			Key.ProcessConsole(key);
	}

}