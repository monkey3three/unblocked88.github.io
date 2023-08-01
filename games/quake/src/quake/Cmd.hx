package quake;

import quake.Protocol.CLC;

class Cmd {
    public static var text = "";
    public static var args(default,null):String;
    public static var argv(default,null) = new Array<String>();
    public static var client(default,null):Bool;

    static var functions = new Map<String,Void->Void>();
    static var alias = new Map<String, String>();
    static var wait = false;

    public static function Init() {
        AddCommand('stuffcmds', StuffCmds_f);
        AddCommand('exec', Exec_f);
        AddCommand('echo', Echo_f);
        AddCommand('alias', Alias_f);
        AddCommand('cmd', ForwardToServer);
        AddCommand('wait', Wait_f);
    }

    public static function AddCommand(name:String, command:Void->Void):Void {
        if (Cvar.vars.exists(name)) {
            Console.Print('Cmd.AddCommand: $name already defined as a var\n');
            return;
        }
        if (functions.exists(name))
            Console.Print('Cmd.AddCommand: $name already defined\n');
        else
            functions[name] = command;
    }

    public static function CompleteCommand(partial:String):String {
        if (partial.length == 0)
            return null;
        for (name in functions.keys()) {
            if (name.substring(0, partial.length) == partial)
                return name;
        }
        return null;
    }

    public static function Execute() {
        var line = '', quotes = false;
        while (text.length != 0) {
            var c = text.charCodeAt(0);
            text = text.substring(1);
            if (c == '"'.code) {
                quotes = !quotes;
                line += String.fromCharCode('"'.code);
                continue;
            }
            if ((!quotes && c == ";".code) || c == "\n".code) {
                if (line.length == 0)
                    continue;
                ExecuteString(line);
                if (wait) {
                    wait = false;
                    return;
                }
                line = '';
                continue;
            }
            line += String.fromCharCode(c);
        }
        text = '';
    }

    public static function ExecuteString(text:String, client = false):Void {
        Cmd.client = client;
        TokenizeString(text);
        if (Cmd.argv.length == 0)
            return;
        var name = Cmd.argv[0].toLowerCase();

        var f = functions[name];
        if (f != null) {
            f();
            return;
        }

        var a = alias[name];
        if (a != null) {
            Cmd.text = a + Cmd.text;
            return;
        }

        if (!Cvar.Command())
            Console.Print('Unknown command "$name"\n');
    }

    public static function ForwardToServer() {
        if (CL.cls.state != connected) {
            Console.Print('Can\'t "${argv[0]}", not connected\n');
            return;
        }
        if (CL.cls.demoplayback == true)
            return;
        var args = String.fromCharCode(CLC.stringcmd);
        if (Cmd.argv[0].toLowerCase() != 'cmd')
            args += Cmd.argv[0] + ' ';
        if (Cmd.argv.length >= 2)
            args += Cmd.args;
        else
            args += '\n';
        CL.cls.message.WriteString(args);
    }

    static function StuffCmds_f() {
        var s = false, build = '';
        for (arg in COM.argv) {
            var c = arg.charCodeAt(0);
            if (s == true) {
                if (c == 43) {
                    build += ('\n' + arg.substring(1) + ' ');
                    continue;
                }
                if (c == 45) {
                    s = false;
                    build += '\n';
                    continue;
                }
                build += (arg + ' ');
                continue;
            }
            if (c == 43) {
                s = true;
                build += (arg.substring(1) + ' ');
            }
        }
        if (build.length != 0)
            Cmd.text = build + '\n' + Cmd.text;
    }

    static function Exec_f() {
        if (argv.length != 2) {
            Console.Print('exec <filename> : execute a script file\n');
            return;
        }
        var filename = argv[1];
        var f = COM.LoadTextFile(filename);
        if (f == null) {
            Console.Print('couldn\'t exec $filename\n');
            return;
        }
        Console.Print('execing $filename\n');
        text = f + text;
    }

    static function Echo_f() {
        for (i in 1...Cmd.argv.length)
            Console.Print(Cmd.argv[i] + ' ');
        Console.Print('\n');
    }

    static function Alias_f() {
        if (Cmd.argv.length <= 1) {
            Console.Print('Current alias commands:\n');
            for (name in alias.keys())
                Console.Print(name + ' : ' + alias[name] + '\n');
        }
        var name = Cmd.argv[1], value = '';
        for (j in 2...Cmd.argv.length) {
            value += Cmd.argv[j];
            if (j != Cmd.argv.length - 1)
                value += ' ';
        }
        alias[name] = value + '\n';
    }

    static function Wait_f() {
        Cmd.wait = true;
    }

    static function TokenizeString(text:String):Void {
        argv = [];
        while (true) {
            var i = 0;
            while (i < text.length) {
                var c = text.charCodeAt(i);
                if (c > 32 || c == 10)
                    break;
                i++;
            }
            if (Cmd.argv.length == 1)
                Cmd.args = text.substring(i);
            if ((text.charCodeAt(i) == 10) || (i >= text.length))
                return;
            text = COM.Parse(text);
            if (text == null)
                return;
            argv.push(COM.token);
        }
    }
}
