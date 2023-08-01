package quake;

import js.Browser.document;
import js.Browser.getLocalStorage;
import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Uint16Array;
import js.html.Uint8Array;
import js.html.XMLHttpRequest;

@:publicFields
private class SearchPath {
	var filename:String;
	var pack:Array<Pack>;

	function new(f) {
		filename = f;
		pack = [];
	}
}

private typedef Pack = Array<File>;

@:publicFields
private class File {
	var name:String;
	var filepos:Int;
	var filelen:Int;

	function new(info:ArrayBuffer, i:Int) {
		name = Q.memstr(new Uint8Array(info, i << 6, 56)).toLowerCase();
		filepos = new DataView(info).getUint32((i << 6) + 56, true);
		filelen = new DataView(info).getUint32((i << 6) + 60, true);
	}
}


@:publicFields
class COM {
	static var cmdline:String;
	static var argv:Array<String> = [];
	static var standard_quake = true;
	static var rogue = false;
	static var hipnotic = false;
	static var modified = false;
	static var token:String;
	static var searchpaths:Array<SearchPath> = [];
	static var gamedir:Array<SearchPath>;
	static var LittleLong:Int->Int;
	static var registered:Cvar;
	static var localStorage = getLocalStorage();

	static function DefaultExtension(path:String, extension:String):String {
		var i = path.length - 1;
		while (i >= 0) {
			var src = path.charCodeAt(i);
			if (src == 47)
				break;
			if (src == 46)
				return path;
			i--;
		}
		return path + extension;
	}

	static function Parse(data:String):String {
		token = '';
		if (data.length == 0)
			return null;

		var i = 0, c = null;
		var skipwhite = true;
		while (true) {
			if (!skipwhite)
				break;
			skipwhite = false;
			while (true) {
				if (i >= data.length)
					return null;
				c = data.charCodeAt(i);
				if (c > 32)
					break;
				++i;
			}
			if (c == 47 && data.charCodeAt(i + 1) == 47) {
				while (true) {
					if (i >= data.length || data.charCodeAt(i) == 10)
						break;
					++i;
				}
				skipwhite = true;
			}
		}

		if (c == 34) {
			++i;
			while (true) {
				c = data.charCodeAt(i);
				++i;
				if (i >= data.length || c == 34)
					return data.substring(i);
				token += String.fromCharCode(c);
			}
		}

		while (true) {
			if (i >= data.length || c <= 32)
				break;
			token += String.fromCharCode(c);
			++i;
			c = data.charCodeAt(i);
		}

		return data.substring(i);
	}

	static function CheckParm(parm:String):Int {
		for (i in 1...argv.length) {
			if (argv[i] == parm)
				return i;
		}
		return null;
	}

	static function CheckRegistered():Void {
		var h = LoadFile('gfx/pop.lmp');
		if (h == null) {
			Console.Print('Playing shareware version.\n');
			if (modified)
				Sys.Error('You must have the registered version to use modified games');
			return;
		}
		var check = new Uint8Array(h);
		var pop =
		[
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x66, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x66, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x66, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x67, 0x00, 0x00,
			0x00, 0x00, 0x66, 0x65, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x65, 0x66, 0x00,
			0x00, 0x63, 0x65, 0x61, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x65, 0x63,
			0x00, 0x64, 0x65, 0x61, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x65, 0x64,
			0x00, 0x64, 0x65, 0x64, 0x00, 0x00, 0x64, 0x69, 0x69, 0x69, 0x64, 0x00, 0x00, 0x64, 0x65, 0x64,
			0x00, 0x63, 0x65, 0x68, 0x62, 0x00, 0x00, 0x64, 0x68, 0x64, 0x00, 0x00, 0x62, 0x68, 0x65, 0x63,
			0x00, 0x00, 0x65, 0x67, 0x69, 0x63, 0x00, 0x64, 0x67, 0x64, 0x00, 0x63, 0x69, 0x67, 0x65, 0x00,
			0x00, 0x00, 0x62, 0x66, 0x67, 0x69, 0x6A, 0x68, 0x67, 0x68, 0x6A, 0x69, 0x67, 0x66, 0x62, 0x00,
			0x00, 0x00, 0x00, 0x62, 0x65, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x65, 0x62, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x62, 0x63, 0x64, 0x66, 0x64, 0x63, 0x62, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x62, 0x66, 0x62, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x66, 0x61, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x65, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
		];
		for (i in 0...256) {
			if (check[i] != pop[i])
				Sys.Error('Corrupted data file.');
		}
		registered.set("1");
		Console.Print('Playing registered version.\n');
	}

	static function InitArgv(pargv:Array<String>):Void {
		cmdline = (pargv.join(' ') + ' ').substring(0, 256);
		argv = pargv.copy();
		if (CheckParm('-safe') != null)
			argv = argv.concat(['-nosound', '-nocdaudio', '-nomouse']);
		if (CheckParm('-rogue') != null) {
			rogue = true;
			standard_quake = false;
		} else if (CheckParm('-hipnotic') != null) {
			hipnotic = true;
			standard_quake = false;
		}
	}

	static function Init():Void {
		if (document.location.protocol != 'http:' && document.location.protocol != 'https:')
			Sys.Error('Protocol is ' + document.location.protocol + ', not http: or https:');

		var swaptest = new ArrayBuffer(2);
		var swaptestview = new Uint8Array(swaptest);
		swaptestview[0] = 1;
		swaptestview[1] = 0;
		if (new Uint16Array(swaptest)[0] == 1)
			LittleLong = (function(l) {return l;});
		else
			LittleLong = (function(l) {return (l >>> 24) + ((l & 0xff0000) >>> 8) + (((l & 0xff00) << 8) >>> 0) + ((l << 24) >>> 0);});

		registered = Cvar.RegisterVariable('registered', '0');
		Cvar.RegisterVariable('cmdline', cmdline, false, true);
		Cmd.AddCommand('path', Path_f);
		InitFilesystem();
		CheckRegistered();
	}

	static function Path_f():Void {
		Console.Print('Current search path:\n');
		var i = searchpaths.length - 1;
		while (i >= 0) {
			var s = searchpaths[i--];
			var j = s.pack.length - 1;
			while (j >= 0) {
				Console.Print(s.filename + '/' + 'pak' + j + '.pak (' + s.pack[j].length + ' files)\n');
				j--;
			}
			Console.Print(s.filename + '\n');
		}
	}

	static function WriteFile(filename:String, data:Uint8Array, len:Int):Bool {
		filename = filename.toLowerCase();
		var dest = [];
		for (i in 0...len)
			dest.push(String.fromCharCode(data[i]));
		try {
			localStorage.setItem('Quake.' + searchpaths[searchpaths.length - 1].filename + '/' + filename, dest.join(''));
		} catch (e:Any) {
			Sys.Print('COM.WriteFile: failed on ' + filename + '\n');
			return false;
		}
		Sys.Print('COM.WriteFile: ' + filename + '\n');
		return true;
	}

	static function WriteTextFile(filename:String, data:String):Bool {
		filename = filename.toLowerCase();
		try {
			localStorage.setItem('Quake.' + searchpaths[searchpaths.length - 1].filename + '/' + filename, data);
		} catch (e:Any) {
			Sys.Print('COM.WriteTextFile: failed on ' + filename + '\n');
			return false;
		}
		Sys.Print('COM.WriteTextFile: ' + filename + '\n');
		return true;
	}

	static function LoadFile(filename:String):ArrayBuffer {
		filename = filename.toLowerCase();
		var xhr = new XMLHttpRequest();
		xhr.overrideMimeType('text/plain; charset=x-user-defined');
		Draw.BeginDisc();
		var i = searchpaths.length - 1;
		while (i >= 0) {
			var search = searchpaths[i--];
			var netpath = search.filename + '/' + filename;
			var data = localStorage.getItem('Quake.' + netpath);
			if (data != null) {
				Sys.Print('FindFile: ' + netpath + '\n');
				Draw.EndDisc();
				return Q.strmem(data);
			}
			var j = search.pack.length - 1;
			while (j >= 0) {
				var pak = search.pack[j];
				for (file in pak) {
					if (file.name != filename)
						continue;
					if (file.filelen == 0) {
						Draw.EndDisc();
						return new ArrayBuffer(0);
					}
					xhr.open('GET', search.filename + '/pak' + j + '.pak', false);
					xhr.setRequestHeader('Range', 'bytes=' + file.filepos + '-' + (file.filepos + file.filelen - 1));
					xhr.send();
					if ((xhr.status >= 200) && (xhr.status <= 299) && (xhr.responseText.length == file.filelen)) {
						Sys.Print('PackFile: ' + search.filename + '/pak' + j + '.pak : ' + filename + '\n');
						Draw.EndDisc();
						return Q.strmem(xhr.responseText);
					}
					break;
				}
				j--;
			}
			xhr.open('GET', netpath, false);
			xhr.send();
			if ((xhr.status >= 200) && (xhr.status <= 299)) {
				Sys.Print('FindFile: ' + netpath + '\n');
				Draw.EndDisc();
				return Q.strmem(xhr.responseText);
			}
		}
		Sys.Print('FindFile: can\'t find ' + filename + '\n');
		Draw.EndDisc();
		return null;
	}

	static function LoadTextFile(filename:String):String {
		var buf = LoadFile(filename);
		if (buf == null)
			return null;
		var bufview = new Uint8Array(buf);
		var f = new StringBuf();
		for (i in 0...bufview.length) {
			if (bufview[i] != 13)
				f.addChar(bufview[i]);
		}
		return f.toString();
	}

	static function LoadPackFile(packfile:String):Pack {
		var xhr = new XMLHttpRequest();
		xhr.overrideMimeType('text/plain; charset=x-user-defined');
		xhr.open('GET', packfile, false);
		xhr.setRequestHeader('Range', 'bytes=0-11');
		xhr.send();
		if ((xhr.status <= 199) || (xhr.status >= 300) || (xhr.responseText.length != 12))
			return null;
		var header = new DataView(Q.strmem(xhr.responseText));
		if (header.getUint32(0, true) != 0x4b434150)
			Sys.Error(packfile + ' is not a packfile');
		var dirofs = header.getUint32(4, true);
		var dirlen = header.getUint32(8, true);
		var numpackfiles = dirlen >> 6;
		if (numpackfiles != 339)
			modified = true;
		var pack:Pack = [];
		if (numpackfiles != 0) {
			xhr.open('GET', packfile, false);
			xhr.setRequestHeader('Range', 'bytes=' + dirofs + '-' + (dirofs + dirlen - 1));
			xhr.send();
			if ((xhr.status <= 199) || (xhr.status >= 300) || (xhr.responseText.length != dirlen))
				return null;
			var info = Q.strmem(xhr.responseText);
			if (CRC.Block(new Uint8Array(info)) != 32981)
				modified = true;
			for (i in 0...numpackfiles) {
				pack.push(new File(info, i));
			}
		}
		Console.Print('Added packfile ' + packfile + ' (' + numpackfiles + ' files)\n');
		return pack;
	}

	static function AddGameDirectory(dir:String):Void {
		var search = new SearchPath(dir);
		var i = 0;
		while (true) {
			var pak = LoadPackFile(dir + '/' + 'pak' + i + '.pak');
			if (pak == null)
				break;
			search.pack.push(pak);
			++i;
		}
		searchpaths.push(search);
	}

	static function InitFilesystem() {
		var i = CheckParm('-basedir'), search = null;
		if (i != null)
			search = argv[i + 1];
		if (search != null)
			AddGameDirectory(search);
		else
			AddGameDirectory('id1');

		if (rogue)
			AddGameDirectory('rogue');
		else if (hipnotic)
			AddGameDirectory('hipnotic');

		i = CheckParm('-game');
		if (i != null) {
			search = argv[i + 1];
			if (search != null) {
				modified = true;
				AddGameDirectory(search);
			}
		}

		gamedir = [searchpaths[searchpaths.length - 1]];
	}
}
