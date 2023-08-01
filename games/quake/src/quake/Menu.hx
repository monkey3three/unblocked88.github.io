package quake;

import js.Browser.window;
import js.html.ArrayBuffer;
import js.html.Uint8Array;
import js.html.webgl.RenderingContext;
import quake.Draw.DrawPic;
import quake.Key.KeyCode;
import quake.S.Sfx;
import quake.GL.gl;

@:enum private abstract MenuState(Int) {
	var none = 0;
	var main = 1;
	var singleplayer = 2;
	var load = 3;
	var save = 4;
	var multiplayer = 5;
	var options = 6;
	var keys = 7;
	var help = 8;
	var quit = 9;
}


@:publicFields
class Menu {

	static var state = MenuState.none;

	static var localStorage = js.Browser.getLocalStorage();
	static var save_demonum:Int;
	static var entersound = false;
	static var recursiveDraw:Bool;
	static var msgNumber:Int;
	static var wasInMenus:Bool;
	static var quit_prevstate:MenuState;

	static var sfx_menu1:Sfx;
	static var sfx_menu2:Sfx;
	static var sfx_menu3:Sfx;
	
	static var box_tl:DrawPic;
	static var box_ml:DrawPic;
	static var box_bl:DrawPic;
	static var box_tm:DrawPic;
	static var box_mm:DrawPic;
	static var box_mm2:DrawPic;
	static var box_bm:DrawPic;
	static var box_tr:DrawPic;
	static var box_mr:DrawPic;
	static var box_br:DrawPic;

	static var qplaque:DrawPic;
	static var menudot:Array<DrawPic>;

	static var ttl_main:DrawPic;
	static var mainmenu:DrawPic;
	static var ttl_sgl:DrawPic;
	static var sp_menu:DrawPic;
	static var p_load:DrawPic;
	static var p_save:DrawPic;
	static var p_multi:DrawPic;
	static var bigbox:DrawPic;
	static var menuplyr:DrawPic;

	static var p_option:DrawPic;
	static var ttl_cstm:DrawPic;

	static var help_pages:Array<DrawPic>;

	static function DrawCharacter(cx:Int, line:Int, num:Int):Void {
		Draw.Character(cx + (VID.width >> 1) - 160, line + (VID.height >> 1) - 100, num);
	}

	static function Print(cx, cy, str) {
		Draw.StringWhite(cx + (VID.width >> 1) - 160, cy + (VID.height >> 1) - 100, str);
	}

	static function PrintWhite(cx, cy, str) {
		Draw.String(cx + (VID.width >> 1) - 160, cy + (VID.height >> 1) - 100, str);
	}

	static function DrawPic(x, y, pic) {
		Draw.Pic(x + (VID.width >> 1) - 160, y + (VID.height >> 1) - 100, pic);
	}

	static function DrawPicTranslate(x, y, pic, top, bottom) {
		Draw.PicTranslate(x + (VID.width >> 1) - 160, y + (VID.height >> 1) - 100, pic, top, bottom);
	}

	static function DrawTextBox(x, y, width, lines) {
		var cx, cy;

		cy = y;
		DrawPic(x, cy, box_tl);
		for (n in 0...lines)
			DrawPic(x, cy += 8, box_ml);
		DrawPic(x, cy + 8, box_bl);

		cx = x + 8;
		var p;
		while (width > 0) {
			cy = y;
			DrawPic(cx, y, box_tm);
			p = box_mm;
			for (n in 0...lines) {
				DrawPic(cx, cy += 8, p);
				if (n == 0)
					p = box_mm2;
			}
			DrawPic(cx, cy + 8, box_bm);
			width -= 2;
			cx += 16;
		}

		cy = y;
		DrawPic(cx, cy, box_tr);
		for (n in 0...lines)
			DrawPic(cx, cy += 8, box_mr);
		DrawPic(cx, cy + 8, box_br);
	}

	static function ToggleMenu_f() {
		entersound = true;
		if (Key.dest == menu) {
			if (state != main) {
				Menu_Main_f();
				return;
			}
			Key.dest = game;
			state = none;
			return;
		}
		Menu_Main_f();
	}


	// Main menu
	static var main_cursor = 0;
	static inline var main_items = 5;

	static function Menu_Main_f() {
		if (Key.dest != menu) {
			save_demonum = CL.cls.demonum;
			CL.cls.demonum = -1;
		}
		Key.dest = menu;
		state = main;
		entersound = true;
	}

	static function Main_Draw() {
		DrawPic(16, 4, qplaque);
		DrawPic(160 - (ttl_main.width >> 1), 4, ttl_main);
		DrawPic(72, 32, mainmenu);
		DrawPic(54, 32 + main_cursor * 20, menudot[Math.floor(Host.realtime * 10.0) % 6]);
	}

	static function Main_Key(k:KeyCode):Void {
		switch (k) {
			case KeyCode.escape:
				Key.dest = game;
				state = none;
				CL.cls.demonum = save_demonum;
				if (CL.cls.demonum != -1 && !CL.cls.demoplayback && CL.cls.state != connected)
					CL.NextDemo();
			case KeyCode.downarrow:
				S.LocalSound(sfx_menu1);
				if (++main_cursor >= main_items)
					main_cursor = 0;
			case KeyCode.uparrow:
				S.LocalSound(sfx_menu1);
				if (--main_cursor < 0)
					main_cursor = main_items - 1;
			case KeyCode.enter:
				entersound = true;
				switch (main_cursor) {
					case 0:
						Menu_SinglePlayer_f();
					case 1:
						Menu_MultiPlayer_f();
					case 2:
						Menu_Options_f();
					case 3:
						Menu_Help_f();
					case 4:
						Menu_Quit_f();
				}
			default:
		}
	}

	// Single player menu
	static var singleplayer_cursor = 0;
	static inline var singleplayer_items = 3;

	static function Menu_SinglePlayer_f() {
		Key.dest = menu;
		state = singleplayer;
		entersound = true;
	}

	static function SinglePlayer_Draw() {
		DrawPic(16, 4, qplaque);
		DrawPic(160 - (ttl_sgl.width >> 1), 4, ttl_sgl);
		DrawPic(72, 32, sp_menu);
		DrawPic(54, 32 + singleplayer_cursor * 20, menudot[Math.floor(Host.realtime * 10.0) % 6]);
	}

	static function SinglePlayer_Key(k) {
		switch (k) {
			case KeyCode.escape:
				Menu_Main_f();

			case KeyCode.downarrow:
				S.LocalSound(sfx_menu1);
				if (++singleplayer_cursor >= singleplayer_items)
					singleplayer_cursor = 0;

			case KeyCode.uparrow:
				S.LocalSound(sfx_menu1);
				if (--singleplayer_cursor < 0)
					singleplayer_cursor = singleplayer_items - 1;

			case KeyCode.enter:
				entersound = true;
				switch (singleplayer_cursor) {
					case 0:
						if (SV.server.active) {
							if (!window.confirm('Are you sure you want to start a new game?'))
								return;
							Cmd.text += 'disconnect\n';
						}
						Key.dest = game;
						Cmd.text += 'maxplayers 1\nmap start\n';
	
					case 1:
						Menu_Load_f();
	
					case 2:
						Menu_Save_f();
				}
			default:
		}
	}

	// Load/save menu
	static var load_cursor = 0;
	static var max_savegames = 12;
	static var filenames = [];
	static var loadable = [];
	static var removable = [];

	static function ScanSaves() {
		var searchpaths = COM.searchpaths;
		var search = 'Quake.' + COM.gamedir[0].filename + '/s';
		COM.searchpaths = COM.gamedir;
		for (i in 0...max_savegames) {
			var f = localStorage.getItem(search + i + '.sav');
			if (f != null)
				removable[i] = true;
			else
			{
				removable[i] = false;
				f = COM.LoadTextFile('s' + i + '.sav');
				if (f == null) {
					filenames[i] = '--- UNUSED SLOT ---';
					loadable[i] = false;
					continue;
				}
			}
			var version = 0;
			while (version < f.length) {
				var c = f.charCodeAt(version++);
				if (c == 10)
					break;
			}
			var name = [];
			for (j in 0...40) {
				var c = f.charCodeAt(version + j);
				if (c == 13)
					break;
				if (c == 95)
					name[j] = ' ';
				else
					name[j] = String.fromCharCode(c);
			}
			filenames[i] = name.join('');
			loadable[i] = true;
		}
		COM.searchpaths = searchpaths;
	}

	static function Menu_Load_f() {
		entersound = true;
		state = load;
		Key.dest = menu;
		ScanSaves();
	}

	static function Menu_Save_f() {
		if ((!SV.server.active) || (CL.state.intermission != 0) || (SV.svs.maxclients != 1))
			return;
		entersound = true;
		state = save;
		Key.dest = menu;
		ScanSaves();
	}

	static function Load_Draw() {
		DrawPic(160 - (p_load.width >> 1), 4, p_load);
		for (i in 0...max_savegames)
			Print(16, 32 + (i << 3), filenames[i]);
		DrawCharacter(8, 32 + (load_cursor << 3), 12 + (Std.int(Host.realtime * 4) & 1));
	}

	static function Save_Draw() {
		DrawPic(160 - (p_save.width >> 1), 4, p_save);
		for (i in 0...max_savegames)
			Print(16, 32 + (i << 3), filenames[i]);
		DrawCharacter(8, 32 + (load_cursor << 3), 12 + (Std.int(Host.realtime * 4) & 1));
	}

	static function Load_Key(k:KeyCode) {
		switch (k) {
			case KeyCode.escape:
				Menu_SinglePlayer_f();
			case KeyCode.enter:
				S.LocalSound(sfx_menu2);
				if (!loadable[load_cursor])
					return;
				state = none;
				Key.dest = game;
				SCR.BeginLoadingPlaque();
				Cmd.text += 'load s' + load_cursor + '\n';
			case KeyCode.uparrow | KeyCode.leftarrow:
				S.LocalSound(sfx_menu1);
				if (--load_cursor < 0)
					load_cursor = max_savegames - 1;
			case KeyCode.downarrow | KeyCode.rightarrow:
				S.LocalSound(sfx_menu1);
				if (++load_cursor >= max_savegames)
					load_cursor = 0;
				return;
			case KeyCode.del:
				if (!removable[load_cursor])
					return;
				if (!window.confirm('Delete selected game?'))
					return;
				localStorage.removeItem('Quake.' + COM.gamedir[0].filename + '/s' + load_cursor + '.sav');
				ScanSaves();
			default:
		}
	}

	static function Save_Key(k:KeyCode) {
		switch (k) {
			case KeyCode.escape:
				Menu_SinglePlayer_f();
			case KeyCode.enter:
				state = none;
				Key.dest = game;
				Cmd.text += 'save s' + load_cursor + '\n';
			case KeyCode.uparrow | KeyCode.leftarrow:
				S.LocalSound(sfx_menu1);
				if (--load_cursor < 0)
					load_cursor = max_savegames - 1;
			case KeyCode.downarrow | KeyCode.rightarrow:
				S.LocalSound(sfx_menu1);
				if (++load_cursor >= max_savegames)
					load_cursor = 0;
			case KeyCode.del:
				if (!removable[load_cursor])
					return;
				if (!window.confirm('Delete selected game?'))
					return;
				localStorage.removeItem('Quake.' + COM.gamedir[0].filename + '/s' + load_cursor + '.sav');
				ScanSaves();
			default:
		}
	}

	// Multiplayer menu
	static var multiplayer_cursor = 0;
	static var multiplayer_cursor_table = [56, 72, 96, 120, 156];
	static var multiplayer_joinname = '';
	static inline var multiplayer_items = 5;

	static var multiplayer_myname:String;
	static var multiplayer_top:Int;
	static var multiplayer_oldtop:Int;
	static var multiplayer_bottom:Int;
	static var multiplayer_oldbottom:Int;

	static function Menu_MultiPlayer_f() {
		Key.dest = menu;
		state = multiplayer;
		entersound = true;
		multiplayer_myname = CL.name.string;
		multiplayer_top = multiplayer_oldtop = Std.int(CL.color.value) >> 4;
		multiplayer_bottom = multiplayer_oldbottom = Std.int(CL.color.value) & 15;
	}

	static function MultiPlayer_Draw() {
		DrawPic(16, 4, qplaque);
		DrawPic(160 - (p_multi.width >> 1), 4, p_multi);

		Print(64, 40, 'Join game at:');
		DrawTextBox(72, 48, 22, 1);
		Print(80, 56, multiplayer_joinname.substring(multiplayer_joinname.length - 21));

		Print(64, 72, 'Your name');
		DrawTextBox(160, 64, 16, 1);
		Print(168, 72, multiplayer_myname);

		Print(64, 96, 'Shirt color');
		Print(64, 120, 'Pants color');

		DrawTextBox(64, 148, 14, 1);
		Print(72, 156, 'Accept Changes');

		DrawPic(160, 80, bigbox);
		DrawPicTranslate(172, 88, menuplyr,
			(multiplayer_top << 4) + (multiplayer_top >= 8 ? 4 : 11),
			(multiplayer_bottom << 4) + (multiplayer_bottom >= 8 ? 4 : 11));

		DrawCharacter(56, multiplayer_cursor_table[multiplayer_cursor], 12 + (Std.int(Host.realtime * 4) & 1));

		if (multiplayer_cursor == 0)
			DrawCharacter(multiplayer_joinname.length <= 20 ? 80 + (multiplayer_joinname.length << 3) : 248, 56, 10 + (Std.int(Host.realtime * 4) & 1));
		else if (multiplayer_cursor == 1)
			DrawCharacter(168 + (multiplayer_myname.length << 3), 72, 10 + (Std.int(Host.realtime * 4) & 1));

		if (!NET_WEBS.available)
			PrintWhite(52, 172, 'No Communications Available');
	}

	static function MultiPlayer_Key(k:KeyCode) {
		if (k == KeyCode.escape)
			Menu_Main_f();

		switch (k) {
			case KeyCode.uparrow:
				S.LocalSound(sfx_menu1);
				if (--multiplayer_cursor < 0)
					multiplayer_cursor = multiplayer_items - 1;
				return;
			case KeyCode.downarrow:
				S.LocalSound(sfx_menu1);
				if (++multiplayer_cursor >= multiplayer_items)
					multiplayer_cursor = 0;
				return;
			case KeyCode.leftarrow:
				if (multiplayer_cursor == 2) {
					if (--multiplayer_top < 0)
						multiplayer_top = 13;
					S.LocalSound(sfx_menu3);
				}
				else if (multiplayer_cursor == 3) {
					if (--multiplayer_bottom < 0)
						multiplayer_bottom = 13;
					S.LocalSound(sfx_menu3);
				}
				return;
			case KeyCode.rightarrow:
				if (multiplayer_cursor == 2)
					(multiplayer_top <= 12) ? ++multiplayer_top : multiplayer_top = 0;
				else if (multiplayer_cursor == 3)
					(multiplayer_bottom <= 12) ? ++multiplayer_bottom : multiplayer_bottom = 0;
				else
					return;
				S.LocalSound(sfx_menu3);
				return;
			case KeyCode.enter:
				switch (multiplayer_cursor) {
					case 0:
						S.LocalSound(sfx_menu2);
						if (!NET_WEBS.available)
							return;
						Key.dest = game;
						state = none;
						Cmd.text += 'connect "';
						if (multiplayer_joinname.substring(0, 5) != 'ws://')
							Cmd.text += 'ws://';
						Cmd.text += multiplayer_joinname + '"\n';
					case 2:
						S.LocalSound(sfx_menu3);
						(multiplayer_top <= 12) ? ++multiplayer_top : multiplayer_top = 0;
					case 3:
						S.LocalSound(sfx_menu3);
						(multiplayer_bottom <= 12) ? ++multiplayer_bottom : multiplayer_bottom = 0;
					case 4:
						if (CL.name.string != multiplayer_myname)
							Cmd.text += 'name "' + multiplayer_myname + '"\n';
						if ((multiplayer_top != multiplayer_oldtop) || (multiplayer_bottom != multiplayer_oldbottom)) {
							multiplayer_oldtop = multiplayer_top;
							multiplayer_oldbottom = multiplayer_bottom;
							Cmd.text += 'color ' + multiplayer_top + ' ' + multiplayer_bottom + '\n';
						}
						entersound = true;
				}
			case KeyCode.backspace:
				if (multiplayer_cursor == 0) {
					if (multiplayer_joinname.length != 0)
						multiplayer_joinname = multiplayer_joinname.substring(0, multiplayer_joinname.length - 1);
					return;
				}
				if (multiplayer_cursor == 1) {
					if (multiplayer_myname.length != 0)
						multiplayer_myname = multiplayer_myname.substring(0, multiplayer_myname.length - 1);
				}
				return;
			default:
		}

		if ((k < 32) || (k > 127))
			return;
		if (multiplayer_cursor == 0) {
			multiplayer_joinname += String.fromCharCode(k);
			return;
		}
		if (multiplayer_cursor == 1) {
			if (multiplayer_myname.length <= 14)
				multiplayer_myname += String.fromCharCode(k);
		}
	}

	// Options menu
	static var options_cursor = 0;
	static inline var options_items = 12;

	static function Menu_Options_f() {
		Key.dest = menu;
		state = options;
		entersound = true;
	}

	static function AdjustSliders(dir) {
		S.LocalSound(sfx_menu3);
		
		switch (options_cursor) {
		case 3: // screen size
			SCR.viewsize.value += dir * 10;
			if (SCR.viewsize.value < 30)
				SCR.viewsize.value = 30;
			else if (SCR.viewsize.value > 120)
				SCR.viewsize.value = 120;
			SCR.viewsize.setValue(SCR.viewsize.value);
			return;
		case 4: // gamma
			V.gamma.value -= dir * 0.05;
			if (V.gamma.value < 0.5)
				V.gamma.value = 0.5;
			else if (V.gamma.value > 1.0)
				V.gamma.value = 1.0;
			V.gamma.setValue(V.gamma.value);
			return;
		case 5: // mouse speed
			CL.sensitivity.value += dir * 0.5;
			if (CL.sensitivity.value < 1.0)
				CL.sensitivity.value = 1.0;
			else if (CL.sensitivity.value > 11.0)
				CL.sensitivity.value = 11.0;
			CL.sensitivity.setValue(CL.sensitivity.value);
			return;
		case 6: // music volume
			S.bgmvolume.value += dir * 0.1;
			if (S.bgmvolume.value < 0.0)
				S.bgmvolume.value = 0.0;
			else if (S.bgmvolume.value > 1.0)
				S.bgmvolume.value = 1.0;
			S.bgmvolume.setValue(S.bgmvolume.value);
			return;
		case 7: // sfx volume
			S.volume.value += dir * 0.1;
			if (S.volume.value < 0.0)
				S.volume.value = 0.0;
			else if (S.volume.value > 1.0)
				S.volume.value = 1.0;
			S.volume.setValue(S.volume.value);
			return;
		case 8: // allways run
			if (CL.forwardspeed.value > 200.0) {
				CL.forwardspeed.setValue(200);
				CL.backspeed.setValue(200);
				return;
			}
			CL.forwardspeed.setValue(400);
			CL.backspeed.setValue(400);
			return;
		case 9: // invert mouse
			CL.m_pitch.setValue(-CL.m_pitch.value);
			return;
		case 10: // lookspring
			CL.lookspring.setValue((CL.lookspring.value != 0) ? 0 : 1);
			return;
		case 11: // lookstrafe
			CL.lookstrafe.setValue((CL.lookstrafe.value != 0) ? 0 : 1);
		}
	}

	static function DrawSlider(x:Int, y:Int, range:Float):Void {
		if (range < 0)
			range = 0;
		else if (range > 1)
			range = 1;
		DrawCharacter(x - 8, y, 128);
		DrawCharacter(x, y, 129);
		DrawCharacter(x + 8, y, 129);
		DrawCharacter(x + 16, y, 129);
		DrawCharacter(x + 24, y, 129);
		DrawCharacter(x + 32, y, 129);
		DrawCharacter(x + 40, y, 129);
		DrawCharacter(x + 48, y, 129);
		DrawCharacter(x + 56, y, 129);
		DrawCharacter(x + 64, y, 129);
		DrawCharacter(x + 72, y, 129);
		DrawCharacter(x + 80, y, 130);
		DrawCharacter(x + Math.floor(72 * range), y, 131);
	}

	static function Options_Draw() {
		DrawPic(16, 4, qplaque);
		DrawPic(160 - (p_option.width >> 1), 4, p_option);
		
		Print(48, 32, 'Customize controls');
		Print(88, 40, 'Go to console');
		Print(56, 48, 'Reset to defaults');
		
		Print(104, 56, 'Screen size');
		DrawSlider(220, 56, (SCR.viewsize.value - 30) / 90);
		Print(112, 64, 'Brightness');
		DrawSlider(220, 64, (1.0 - V.gamma.value) * 2.0);
		Print(104, 72, 'Mouse Speed');
		DrawSlider(220, 72, (CL.sensitivity.value - 1) / 10);
		Print(72, 80, 'CD Music Volume');
		DrawSlider(220, 80, S.bgmvolume.value);
		Print(96, 88, 'Sound Volume');
		DrawSlider(220, 88, S.volume.value);
		Print(112, 96, 'Always Run');
		Print(220, 96, (CL.forwardspeed.value > 200.0) ? 'on' : 'off');
		Print(96, 104, 'Invert Mouse');
		Print(220, 104, (CL.m_pitch.value < 0.0) ? 'on' : 'off');
		Print(112, 112, 'Lookspring');
		Print(220, 112, (CL.lookspring.value != 0) ? 'on' : 'off');
		Print(112, 120, 'Lookstrafe');
		Print(220, 120, (CL.lookstrafe.value != 0) ? 'on' : 'off');
		
		DrawCharacter(200, 32 + (options_cursor << 3), 12 + (Std.int(Host.realtime * 4) & 1));
	}

	static function Options_Key(k) {
		switch (k) {
		case KeyCode.escape:
			Menu_Main_f();
			return;
		case KeyCode.enter:
			entersound = true;
			switch (options_cursor) {
			case 0:
				Menu_Keys_f();
				return;
			case 1:
				state = none;
				Console.ToggleConsole_f();
				return;
			case 2:
				Cmd.text += 'exec default.cfg\n';
				return;
			default:
				AdjustSliders(1);
			}
			return;
		case KeyCode.uparrow:
			S.LocalSound(sfx_menu1);
			if (--options_cursor < 0)
				options_cursor = options_items - 1;
			return;
		case KeyCode.downarrow:
			S.LocalSound(sfx_menu1);
			if (++options_cursor >= options_items)
				options_cursor = 0;
			return;
		case KeyCode.leftarrow:
			AdjustSliders(-1);
			return;
		case KeyCode.rightarrow:
			AdjustSliders(1);
		default:
		}
	}

	// Keys menu
	static var bindnames = [
		["+attack", "attack"],
		["impulse 10", "change weapon"],
		["+jump", "jump / swim up"],
		["+forward", "walk forward"],
		["+back", "backpedal"],
		["+left", "turn left"],
		["+right", "turn right"],
		["+speed", "run"],
		["+moveleft", "step left"],
		["+moveright", "step right"],
		["+strafe", "sidestep"],
		["+lookup", "look up"],
		["+lookdown", "look down"],
		["centerview", "center view"],
		["+mlook", "mouse look"],
		["+klook", "keyboard look"],
		["+moveup", "swim up"],
		["+movedown", "swim down"]
	];

	static var keys_cursor = 0;

	static function Menu_Keys_f() {
		Key.dest = menu;
		state = keys;
		entersound = true;
	}

	static function FindKeysForCommand(command:String):Array<Int> {
		var twokeys = [];
		for (i in 0...Key.bindings.length) {
			if (Key.bindings[i] == command) {
				twokeys.push(i);
				if (twokeys.length == 2)
					return twokeys;
			}
		}
		return twokeys;
	}

	static function UnbindCommand(command) {
		for (i in 0...Key.bindings.length) {
			if (Key.bindings[i] == command)
				Key.bindings[i] = null;
		}
	}

	static var bind_grab:Bool;

	static function Keys_Draw() {
		DrawPic(160 - (ttl_cstm.width >> 1), 4, ttl_cstm);

		if (bind_grab) {
			Print(12, 32, 'Press a key or button for this action');
			DrawCharacter(130, 48 + (keys_cursor << 3), 61);
		}
		else
		{
			Print(18, 32, 'Enter to change, backspace to clear');
			DrawCharacter(130, 48 + (keys_cursor << 3), 12 + (Std.int(Host.realtime * 4) & 1));
		}

		var y = 48;
		for (i in 0...bindnames.length) {
			Print(16, y, bindnames[i][1]);
			var keys = FindKeysForCommand(bindnames[i][0]);
			if (keys[0] == null)
				Print(140, y, '???');
			else
			{
				var name = Key.KeynumToString(keys[0]);
				if (keys[1] != null)
					name += ' or ' + Key.KeynumToString(keys[1]);
				Print(140, y, name);
			}
			y += 8;
		}
	}

	static function Keys_Key(k:KeyCode):Void {
		if (bind_grab) {
			S.LocalSound(sfx_menu1);
			if (k != KeyCode.escape && k != 96)
				Cmd.text = 'bind "' + Key.KeynumToString(k) + '" "' + bindnames[keys_cursor][0] + '"\n' + Cmd.text;
			bind_grab = false;
			return;
		}

		switch (k) {
			case KeyCode.escape:
				Menu_Options_f();
			case KeyCode.leftarrow | KeyCode.uparrow:
				S.LocalSound(sfx_menu1);
				if (--keys_cursor < 0)
					keys_cursor = bindnames.length - 1;
			case KeyCode.downarrow | KeyCode.rightarrow:
				S.LocalSound(sfx_menu1);
				if (++keys_cursor >= bindnames.length)
					keys_cursor = 0;
			case KeyCode.enter:
				S.LocalSound(sfx_menu2);
				if (FindKeysForCommand(bindnames[keys_cursor][0])[1] != null)
					UnbindCommand(bindnames[keys_cursor][0]);
				bind_grab = true;
			case KeyCode.backspace | KeyCode.del:
				S.LocalSound(sfx_menu2);
				UnbindCommand(bindnames[keys_cursor][0]);
			default:
		}
	}

	// Help menu
	static inline var num_help_pages = 6;
	static var help_page:Int;

	static function Menu_Help_f() {
		Key.dest = menu;
		state = help;
		entersound = true;
		help_page = 0;
	}

	static function Help_Draw() {
		DrawPic(0, 0, help_pages[help_page]);
	}

	static function Help_Key(k) {
		switch (k) {
		case KeyCode.escape:
			Menu_Main_f();
			return;
		case KeyCode.uparrow:
		case KeyCode.rightarrow:
			entersound = true;
			if (++help_page >= num_help_pages)
				help_page = 0;
			return;
		case KeyCode.downarrow:
		case KeyCode.leftarrow:
			entersound = true;
			if (--help_page < 0)
				help_page = num_help_pages - 1;
		default:
		}
	}

	// Quit menu
	static var quitMessage = [
		['  Are you gonna quit', '  this game just like', '   everything else?', ''],
		[' Milord, methinks that', '   thou art a lowly', ' quitter. Is this true?', ''],
		[' Do I need to bust your', '  face open for trying', '        to quit?', ''],
		[' Man, I oughta smack you', '   for trying to quit!', '     Press Y to get', '      smacked out.'],
		[' Press Y to quit like a', '   big loser in life.', '  Press N to stay proud', '    and successful!'],
		['   If you press Y to', '  quit, I will summon', '  Satan all over your', '      hard drive!'],
		['  Um, Asmodeus dislikes', ' his children trying to', ' quit. Press Y to return', '   to your Tinkertoys.'],
		['  If you quit now, I\'ll', '  throw a blanket-party', '   for you next time!', '']
	];

	static function Menu_Quit_f() {
		if (state == quit)
			return;
		wasInMenus = (Key.dest == menu);
		Key.dest = menu;
		quit_prevstate = state;
		state = quit;
		entersound = true;
		msgNumber = Math.floor(Math.random() * quitMessage.length);
	}

	static function Quit_Draw():Void {
		if (wasInMenus) {
			state = quit_prevstate;
			recursiveDraw = true;
			DrawMenu();
			state = quit;
		}
		DrawTextBox(56, 76, 24, 4);
		Print(64, 84, quitMessage[msgNumber][0]);
		Print(64, 92, quitMessage[msgNumber][1]);
		Print(64, 100, quitMessage[msgNumber][2]);
		Print(64, 108, quitMessage[msgNumber][3]);
	}

	static function Quit_Key(k:KeyCode):Void {
		switch (k) {
			case KeyCode.escape | 110:
				if (wasInMenus) {
					state = quit_prevstate;
					entersound = true;
				} else {
					Key.dest = game;
					state = none;
				}
			case 121:
				Key.dest = console;
				Host.Quit_f();
			default:
		}
	}


	// Menu Subsystem
	static function Init():Void {
		Cmd.AddCommand('togglemenu', ToggleMenu_f);
		Cmd.AddCommand('menu_main', Menu_Main_f);
		Cmd.AddCommand('menu_singleplayer', Menu_SinglePlayer_f);
		Cmd.AddCommand('menu_load', Menu_Load_f);
		Cmd.AddCommand('menu_save', Menu_Save_f);
		Cmd.AddCommand('menu_multiplayer', Menu_MultiPlayer_f);
		Cmd.AddCommand('menu_setup', Menu_MultiPlayer_f);
		Cmd.AddCommand('menu_options', Menu_Options_f);
		Cmd.AddCommand('menu_keys', Menu_Keys_f);
		Cmd.AddCommand('help', Menu_Help_f);
		Cmd.AddCommand('menu_quit', Menu_Quit_f);

		sfx_menu1 = S.PrecacheSound('misc/menu1.wav');
		sfx_menu2 = S.PrecacheSound('misc/menu2.wav');
		sfx_menu3 = S.PrecacheSound('misc/menu3.wav');

		box_tl = Draw.CachePic('box_tl');
		box_ml = Draw.CachePic('box_ml');
		box_bl = Draw.CachePic('box_bl');
		box_tm = Draw.CachePic('box_tm');
		box_mm = Draw.CachePic('box_mm');
		box_mm2 = Draw.CachePic('box_mm2');
		box_bm = Draw.CachePic('box_bm');
		box_tr = Draw.CachePic('box_tr');
		box_mr = Draw.CachePic('box_mr');
		box_br = Draw.CachePic('box_br');

		qplaque = Draw.CachePic('qplaque');

		menudot = [
			Draw.CachePic('menudot1'),
			Draw.CachePic('menudot2'),
			Draw.CachePic('menudot3'),
			Draw.CachePic('menudot4'),
			Draw.CachePic('menudot5'),
			Draw.CachePic('menudot6')
		];

		ttl_main = Draw.CachePic('ttl_main');
		mainmenu = Draw.CachePic('mainmenu');

		ttl_sgl = Draw.CachePic('ttl_sgl');
		sp_menu = Draw.CachePic('sp_menu');
		p_load = Draw.CachePic('p_load');
		p_save = Draw.CachePic('p_save');

		p_multi = Draw.CachePic('p_multi');
		bigbox = Draw.CachePic('bigbox');
		menuplyr = Draw.CachePic('menuplyr');
		var buf = COM.LoadFile('gfx/menuplyr.lmp');
		var data = GL.ResampleTexture(menuplyr.data, menuplyr.width, menuplyr.height, 64, 64);
		var trans = new Uint8Array(new ArrayBuffer(16384));
		for (i in 0...4096) {
			var p = data[i];
			if ((p >> 4) == 1) {
				trans[i << 2] = (p & 15) * 17;
				trans[(i << 2) + 1] = 255;
			}
			else if ((p >> 4) == 6) {
				trans[(i << 2) + 2] = (p & 15) * 17;
				trans[(i << 2) + 3] = 255;
			}
		}
		menuplyr.translate = gl.createTexture();
		GL.Bind(0, menuplyr.translate);
		gl.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, 64, 64, 0, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, trans);
		gl.texParameterf(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, RenderingContext.LINEAR);
		gl.texParameterf(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, RenderingContext.LINEAR);

		p_option = Draw.CachePic('p_option');
		ttl_cstm = Draw.CachePic('ttl_cstm');

		help_pages = [
			Draw.CachePic('help0'),
			Draw.CachePic('help1'),
			Draw.CachePic('help2'),
			Draw.CachePic('help3'),
			Draw.CachePic('help4'),
			Draw.CachePic('help5')
		];
	}

	static function DrawMenu() {
		if (state == none || Key.dest != menu)
			return;

		if (!recursiveDraw) {
			if (SCR.con_current != 0)
				Draw.ConsoleBackground(VID.height);
			else
				Draw.FadeScreen();
		} else {
			recursiveDraw = false;
		}
		
		switch (state) {
			case main:
				Main_Draw();
			case singleplayer:
				SinglePlayer_Draw();
			case load:
				Load_Draw();
			case save:
				Save_Draw();
			case multiplayer:
				MultiPlayer_Draw();
			case options:
				Options_Draw();
			case keys:
				Keys_Draw();
			case help:
				Help_Draw();
			case quit:
				Quit_Draw();
			case none:
		}

		if (entersound) {
			S.LocalSound(sfx_menu2);
			entersound = false;
		}
	}

	static function Keydown(key:KeyCode):Void {
		switch (state) {
			case main:
				Main_Key(key);
			case singleplayer:
				SinglePlayer_Key(key);
			case load:
				Load_Key(key);
			case save:
				Save_Key(key);
			case multiplayer:
				MultiPlayer_Key(key);
			case options:
				Options_Key(key);
			case keys:
				Keys_Key(key);
			case help:
				Help_Key(key);
			case quit:
				Quit_Key(key);
			case none:
		}
	}
}
