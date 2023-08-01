package quake;

import js.Browser.window;
import js.Browser.document;
import js.Error;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.html.WheelEvent;
import quake.Key.KeyCode;

class Sys {
    static var oldtime:Float;
    static var frame:Int;
    static var scantokey:Map<Int,KeyCode>;

    static function clearEvents() {
        window.onbeforeunload = null;
        window.oncontextmenu = null;
        window.onfocus = null;
        window.onkeydown = null;
        window.onkeyup = null;
        window.onmousedown = null;
        window.onmouseup = null;
        window.onunload = null;
        window.onwheel = null;
    }

    public static function Quit():Void {
        if (frame != null)
            window.clearInterval(frame);

        clearEvents();

        Host.Shutdown();
        document.body.style.cursor = 'auto';
        VID.mainwindow.style.display = 'none';
        if (COM.registered.value != 0)
            document.getElementById('end2').style.display = 'inline';
        else
            document.getElementById('end1').style.display = 'inline';
        throw new Error();
    }

    public static inline function Print(text:String):Void {
        trace(text);
    }

    public static function Error(text:String):Void {
        if (frame != null)
            window.clearInterval(frame);

        clearEvents();

        if (Host.initialized)
            Host.Shutdown();
        document.body.style.cursor = 'auto';
        var i = Console.text.length - 25;
        if (i < 0)
            i = 0;
        if (window.console != null) {
            while (i < Console.text.length)
                window.console.log(Console.text[i++].text);
        }
        window.alert(text);
        throw new Error(text);
    }

    public static inline function FloatTime():Float {
        return Date.now().getTime() * 0.001 - oldtime;
    }

    static inline function urlDecode(s:String):String
        return (untyped decodeURIComponent)(s);

    static function main():Void {
        window.onload = function() {
            var cmdline = urlDecode(document.location.search);
            var location = document.location;
            var argv = [location.href.substring(0, location.href.length - location.search.length)];
            if (cmdline.charCodeAt(0) == 63)
            {
                var text = '';
                var quotes = false;
                for (i in 1...cmdline.length)
                {
                    var c = cmdline.charCodeAt(i);
                    if ((c < 32) || (c > 127))
                        continue;
                    if (c == 34)
                    {
                        quotes = !quotes;
                        continue;
                    }
                    if ((quotes == false) && (c == 32))
                    {
                        if (text.length == 0)
                            continue;
                        argv.push(text);
                        text = '';
                        continue;
                    }
                    text += cmdline.charAt(i);
                }
                if (text.length != 0)
                    argv.push(text);
            }
            COM.InitArgv(argv);

            var elem = document.documentElement;
            VID.width = (elem.clientWidth <= 320) ? 320 : elem.clientWidth;
            VID.height = (elem.clientHeight <= 200) ? 200 : elem.clientHeight;

            Sys.scantokey = new Map();
            Sys.scantokey[8] = KeyCode.backspace;
            Sys.scantokey[9] = KeyCode.tab;
            Sys.scantokey[13] = KeyCode.enter;
            Sys.scantokey[16] = KeyCode.shift;
            Sys.scantokey[17] = KeyCode.ctrl;
            Sys.scantokey[18] = KeyCode.alt;
            Sys.scantokey[19] = KeyCode.pause;
            Sys.scantokey[27] = KeyCode.escape;
            Sys.scantokey[32] = KeyCode.space;
            Sys.scantokey[33] = Sys.scantokey[105] = KeyCode.pgup;
            Sys.scantokey[34] = Sys.scantokey[99] = KeyCode.pgdn;
            Sys.scantokey[35] = Sys.scantokey[97] = KeyCode.end;
            Sys.scantokey[36] = Sys.scantokey[103] = KeyCode.home;
            Sys.scantokey[37] = Sys.scantokey[100] = KeyCode.leftarrow;
            Sys.scantokey[38] = Sys.scantokey[104] = KeyCode.uparrow;
            Sys.scantokey[39] = Sys.scantokey[102] = KeyCode.rightarrow;
            Sys.scantokey[40] = Sys.scantokey[98] = KeyCode.downarrow;
            Sys.scantokey[45] = Sys.scantokey[96] = KeyCode.ins;
            Sys.scantokey[46] = Sys.scantokey[110] = KeyCode.del;
            for (i in 48...58)
                Sys.scantokey[i] = i; // 0-9
            Sys.scantokey[59] = Sys.scantokey[186] = 59; // ;
            Sys.scantokey[61] = Sys.scantokey[187] = 61; // =
            for (i in 65...91)
                Sys.scantokey[i] = i + 32; // a-z
            Sys.scantokey[106] = 42; // *
            Sys.scantokey[107] = 43; // +
            Sys.scantokey[109] = Sys.scantokey[173] = Sys.scantokey[189] = 45; // -
            Sys.scantokey[111] = Sys.scantokey[191] = 47; // /
            for (i in 112...124)
                Sys.scantokey[i] = i - 112 + KeyCode.f1; // f1-f12
            Sys.scantokey[188] = 44; // ,
            Sys.scantokey[190] = 46; // .
            Sys.scantokey[192] = 96; // `
            Sys.scantokey[219] = 91; // [
            Sys.scantokey[220] = 92; // backslash
            Sys.scantokey[221] = 93; // ]
            Sys.scantokey[222] = 39; // '

            Sys.oldtime = Date.now().getTime() * 0.001;

            Sys.Print('Host.Init\n');
            Host.Init();

            window.onbeforeunload = onbeforeunload;
            window.oncontextmenu = oncontextmenu;
            window.onfocus = onfocus;
            window.onkeydown = onkeydown;
            window.onkeyup = onkeyup;
            window.onmousedown = onmousedown;
            window.onmouseup = onmouseup;
            window.onunload = onunload;
            window.onwheel = onwheel;

            frame = window.setInterval(Host.Frame, Std.int(1000.0 / 60.0));
        }
    }

    static function onbeforeunload(_):String {
        return 'Are you sure you want to quit?';
    }

    static function oncontextmenu(e:MouseEvent):Void {
        e.preventDefault();
    }

    static function onfocus():Void {
        for (i in 0...256) {
            Key.Event(i, false);
            Key.down[i] = false;
        }
    }

    static function onkeydown(e:KeyboardEvent):Void {
        var key = scantokey[e.keyCode];
        if (key == null)
            return;
        Key.Event(key, true);
        e.preventDefault();
    }

    static function onkeyup(e:KeyboardEvent):Void
    {
        var key = scantokey[e.keyCode];
        if (key == null)
            return;
        Key.Event(key, false);
        e.preventDefault();
    }

    static function onmousedown(e:MouseEvent):Void {
        var key = switch (e.which) {
            case 1:
                KeyCode.mouse1;
            case 2:
                KeyCode.mouse3;
            case 3:
                KeyCode.mouse2;
            default:
                return;
        };
        Key.Event(key, true);
        e.preventDefault();
    }

    static function onmouseup(e:MouseEvent):Void
    {
        var key = switch (e.which) {
            case 1:
                KeyCode.mouse1;
            case 2:
                KeyCode.mouse3;
            case 3:
                KeyCode.mouse2;
            default:
                return;
        };
        Key.Event(key, false);
        e.preventDefault();
    }

    static function onunload() {
        Host.Shutdown();
    }

    static function onwheel(e:WheelEvent):Void {
        var key = e.deltaY < 0 ? KeyCode.mwheelup : KeyCode.mwheeldown;
        Key.Event(key, true);
        Key.Event(key, false);
        e.preventDefault();
    }
}
