package quake;

import js.html.Uint8Array;
import quake.CL.ClientCmd;
import quake.NET.INETSocket;
import quake.PR.EType;
import quake.Protocol.SVC;
import quake.SV.MoveType;
import quake.SV.EntFlag;
import quake.Def.ClientStat;
using Tools;

@:publicFields
class HClient {
    var active:Bool;
    var spawned:Bool;
    var sendsignon:Bool;
    var dropasap:Bool;
    var message:MSG;
    var netconnection:INETSocket;
    var edict:Edict;
    var old_frags:Int;
    var num:Int;
    var colors:Int;
    var spawn_parms:Array<Float>;
    var last_message:Float;
    var cmd:ClientCmd;
    var wishdir:Vec;
    var ping_times:Array<Float>;
    var num_pings:Int;
    function new() {
        num = 0;
        message = new MSG(8000);
        message.allowoverflow = true;
        colors = 0;
        old_frags = 0;
    }
}


class Host {
    public static var initialized(default,null) = false;

    public static var client:HClient;

    public static var deathmatch(default,null):Cvar;
    public static var teamplay(default,null):Cvar;
    public static var coop(default,null):Cvar;

    public static var skill(default,null):Cvar;
    public static var current_skill:Int;

    public static var noclip_anglehack = false;

    public static var developer(default,null):Cvar;

    public static var framecount(default,null) = 0;
    public static var frametime:Float;
    public static var realtime(default,null):Float;
    static var oldrealtime:Float;
    static var timetotal = 0.0;
    static var timecount = 0;
    static var time3 = 0.0;

    static var framerate:Cvar;
    static var speeds:Cvar;
    static var ticrate:Cvar;
    static var serverprofile:Cvar;
    static var fraglimit:Cvar;
    static var timelimit:Cvar;
    static var samelevel:Cvar;
    static var noexit:Cvar;
    static var pausable:Cvar;
    static var temp1:Cvar;

    static var inerror = false;
    static var isdown = false;

    static var startdemos:Bool;

    public static function EndGame(message:String):Void {
        Console.DPrint('Host.EndGame: $message\n');
        if (CL.cls.demonum != -1)
            CL.NextDemo();
        else
            CL.Disconnect();
        throw 'Host.abortserver';
    }

    public static function Error(error:String):Void {
        if (inerror)
            Sys.Error('Host.Error: recursively entered');
        inerror = true;
        SCR.EndLoadingPlaque();
        Console.Print('Host.Error: $error\n');
        if (SV.server.active)
            ShutdownServer(false);
        CL.Disconnect();
        CL.cls.demonum = -1;
        inerror = false;
        throw new js.Error('Host.abortserver');
    }

    static function FindMaxClients():Void {
        SV.svs.maxclients = SV.svs.maxclientslimit = 1;
        CL.cls.state = disconnected;
        SV.svs.clients = [new HClient()];
        deathmatch.setValue(0);
    }

    static function InitLocal() {
        InitCommands();
        framerate = Cvar.RegisterVariable('host_framerate', '0');
        speeds = Cvar.RegisterVariable('host_speeds', '0');
        ticrate = Cvar.RegisterVariable('sys_ticrate', '0.05');
        serverprofile = Cvar.RegisterVariable('serverprofile', '0');
        fraglimit = Cvar.RegisterVariable('fraglimit', '0', false, true);
        timelimit = Cvar.RegisterVariable('timelimit', '0', false, true);
        teamplay = Cvar.RegisterVariable('teamplay', '0', false, true);
        samelevel = Cvar.RegisterVariable('samelevel', '0');
        noexit = Cvar.RegisterVariable('noexit', '0', false, true);
        skill = Cvar.RegisterVariable('skill', '1');
        developer = Cvar.RegisterVariable('developer', '0');
        deathmatch = Cvar.RegisterVariable('deathmatch', '0');
        coop = Cvar.RegisterVariable('coop', '0');
        pausable = Cvar.RegisterVariable('pausable', '1');
        temp1 = Cvar.RegisterVariable('temp1', '0');
        FindMaxClients();
    }

    static function ClientPrint(string:String):Void {
        client.message.WriteByte(SVC.print);
        client.message.WriteString(string);
    }

    public static function BroadcastPrint(string:String):Void {
        for (i in 0...SV.svs.maxclients) {
            var client = SV.svs.clients[i];
            if (!client.active || !client.spawned)
                continue;
            client.message.WriteByte(SVC.print);
            client.message.WriteString(string);
        }
    }

    public static function DropClient(crash:Bool):Void {
        var client = Host.client;
        if (!crash) {
            if (NET.CanSendMessage(client.netconnection)) {
                client.message.WriteByte(SVC.disconnect);
                NET.SendMessage(client.netconnection, client.message);
            }
            if ((client.edict != null) && (client.spawned)) {
                var saveSelf = PR.globals.self;
                PR.globals.self = client.edict.num;
                PR.ExecuteProgram(PR.globals.ClientDisconnect);
                PR.globals.self = saveSelf;
            }
            Sys.Print('Client ' + SV.GetClientName(client) + ' removed\n');
        }
        NET.Close(client.netconnection);
        client.netconnection = null;
        client.active = false;
        SV.SetClientName(client, '');
        client.old_frags = -999999;
        --NET.activeconnections;
        var num = client.num;
        for (i in 0...SV.svs.maxclients) {
            var client = SV.svs.clients[i];
            if (!client.active)
                continue;
            client.message.WriteByte(SVC.updatename);
            client.message.WriteByte(num);
            client.message.WriteByte(0);
            client.message.WriteByte(SVC.updatefrags);
            client.message.WriteByte(num);
            client.message.WriteShort(0);
            client.message.WriteByte(SVC.updatecolors);
            client.message.WriteByte(num);
            client.message.WriteByte(0);
        }
    }

    public static function ShutdownServer(crash:Bool):Void {
        if (!SV.server.active)
            return;
        SV.server.active = false;
        if (CL.cls.state == connected)
            CL.Disconnect();
        var start = Sys.FloatTime(), count = 0;
        do
        {
            for (i in 0...SV.svs.maxclients) {
                Host.client = SV.svs.clients[i];
                if ((!Host.client.active) || (Host.client.message.cursize == 0))
                    continue;
                if (NET.CanSendMessage(Host.client.netconnection)) {
                    NET.SendMessage(Host.client.netconnection, Host.client.message);
                    Host.client.message.cursize = 0;
                    continue;
                }
                NET.GetMessage(Host.client.netconnection);
                ++count;
            }
            if ((Sys.FloatTime() - start) > 3.0)
                break;
        } while (count != 0);
        var buf = new MSG(4, 1);
        (new Uint8Array(buf.data))[0] = SVC.disconnect;
        count = NET.SendToAll(buf);
        if (count != 0)
            Console.Print('Host.ShutdownServer: NET.SendToAll failed for ' + count + ' clients\n');
        for (i in 0...SV.svs.maxclients) {
            Host.client = SV.svs.clients[i];
            if (Host.client.active)
                Host.DropClient(crash);
        }
    }

    static inline function WriteConfiguration() {
        COM.WriteTextFile('config.cfg', Key.WriteBindings() + Cvar.WriteVariables());
    }

    static function ServerFrame() {
        PR.globals.frametime = Host.frametime;
        SV.server.datagram.cursize = 0;
        SV.CheckForNewClients();
        SV.RunClients();
        if (!SV.server.paused && (SV.svs.maxclients >= 2 || Key.dest == game))
            SV.Physics();
        SV.SendClientMessages();
    }

    static function _Frame() {
        Math.random();

        Host.realtime = Sys.FloatTime();
        Host.frametime = Host.realtime - Host.oldrealtime;
        Host.oldrealtime = Host.realtime;
        if (Host.framerate.value > 0)
            Host.frametime = Host.framerate.value;
        else {
            if (Host.frametime > 0.1)
                Host.frametime = 0.1;
            else if (Host.frametime < 0.001)
                Host.frametime = 0.001;
        }

        if (CL.cls.state == connecting) {
            NET.CheckForResend();
            SCR.UpdateScreen();
            return;
        }

        var time1 = null, time2 = null, pass1, pass2, pass3, tot;

        Cmd.Execute();

        CL.SendCmd();
        if (SV.server.active)
            Host.ServerFrame();

        if (CL.cls.state == connected)
            CL.ReadFromServer();

        if (Host.speeds.value != 0)
            time1 = Sys.FloatTime();

        SCR.UpdateScreen();
        CL.RunParticles();

        if (Host.speeds.value != 0)
            time2 = Sys.FloatTime();

        if (CL.cls.signon == 4) {
            S.Update(Render.refdef.vieworg, Render.vpn, Render.vright, Render.vup);
            CL.DecayLights();
        }
        else
            S.Update(Vec.origin, Vec.origin, Vec.origin, Vec.origin);
        CDAudio.Update();

        if (Host.speeds.value != 0) {
            pass1 = (time1 - Host.time3) * 1000.0;
            Host.time3 = Sys.FloatTime();
            pass2 = (time2 - time1) * 1000.0;
            pass3 = (Host.time3 - time2) * 1000.0;
            tot = Math.floor(pass1 + pass2 + pass3);
            Console.Print((tot <= 99 ? (tot <= 9 ? '  ' : ' ') : '')
                + tot + ' tot '
                + (pass1 < 100.0 ? (pass1 < 10.0 ? '  ' : ' ') : '')
                + Math.floor(pass1) + ' server '
                + (pass2 < 100.0 ? (pass2 < 10.0 ? '  ' : ' ') : '')
                + Math.floor(pass2) + ' gfx '
                + (pass3 < 100.0 ? (pass3 < 10.0 ? '  ' : ' ') : '')
                + Math.floor(pass3) + ' snd\n');
        }

        if (Host.startdemos) {
            CL.NextDemo();
            Host.startdemos = false;
        }

        ++Host.framecount;
    }

    public static function Frame() {
        if (Host.serverprofile.value == 0) {
            Host._Frame();
            return;
        }
        var time1 = Sys.FloatTime();
        Host._Frame();
        Host.timetotal += Sys.FloatTime() - time1;
        if (++Host.timecount <= 999)
            return;
        var m = Std.int(Host.timetotal * 1000.0 / Host.timecount);
        Host.timecount = 0;
        Host.timetotal = 0.0;
        var c = 0;
        for (i in 0...SV.svs.maxclients) {
            if (SV.svs.clients[i].active)
                ++c;
        }
        Console.Print('serverprofile: ' + (c <= 9 ? ' ' : '') + c + ' clients ' + (m <= 9 ? ' ' : '') + m + ' msec\n');
    }

    public static function Init() {
        Host.oldrealtime = Sys.FloatTime();
        Cmd.Init();
        V.Init();
        Chase.Init();
        COM.Init();
        Host.InitLocal();
        W.LoadWadFile('gfx.wad');
        Key.Init();
        Console.Init();
        PR.Init();
        Mod.Init();
        NET.Init();
        SV.Init();
        Console.Print(Def.timedate);
        VID.Init();
        Draw.Init();
        SCR.Init();
        Render.Init();
        S.Init();
        Menu.Init();
        CDAudio.Init();
        Sbar.Init();
        CL.Init();
        IN.Init();
        Cmd.text = 'exec quake.rc\n' + Cmd.text;
        Host.initialized = true;
        Sys.Print('======Quake Initialized======\n');
    }

    public static function Shutdown():Void {
        if (Host.isdown) {
            Sys.Print('recursive shutdown\n');
            return;
        }
        Host.isdown = true;
        Host.WriteConfiguration();
        CDAudio.Stop();
        NET.Shutdown();
        S.StopAllSounds();
        IN.Shutdown();
    }

    // Commands

    public static function Quit_f():Void {
        if (Key.dest != console) {
            Menu.Menu_Quit_f();
            return;
        }
        Sys.Quit();
    }

    static function Status_f() {
        var print;
        if (!Cmd.client) {
            if (!SV.server.active) {
                Cmd.ForwardToServer();
                return;
            }
            print = Console.Print;
        }
        else
            print = Host.ClientPrint;
        print('host:    ' + NET.hostname.string + '\n');
        print('version: 1.09\n');
        print('map:     ' + PR.GetString(PR.globals.mapname) + '\n');
        print('players: ' + NET.activeconnections + ' active (' + SV.svs.maxclients + ' max)\n\n');
        for (i in 0...SV.svs.maxclients) {
            var client = SV.svs.clients[i];
            if (!client.active)
                continue;
            var frags = client.edict.v.frags.toFixed(0);
            if (frags.length == 1)
                frags = '  ' + frags;
            else if (frags.length == 2)
                frags = ' ' + frags;
            var seconds = Std.int(NET.time - client.netconnection.connecttime);
            var minutes = Std.int(seconds / 60);
            var hours;
            if (minutes != 0) {
                seconds -= minutes * 60;
                hours = Std.int(minutes / 60);
                if (hours != 0)
                    minutes -= hours * 60;
            }
            else
                hours = 0;
            var str = '#' + (i + 1) + ' ';
            if (i <= 8)
                str += ' ';
            str += SV.GetClientName(client);
            while (str.length <= 21)
                str += ' ';
            str += frags + '  ';
            if (hours <= 9)
                str += ' ';
            str += hours + ':';
            if (minutes <= 9)
                str += '0';
            str += minutes + ':';
            if (seconds <= 9)
                str += '0';
            print(str + seconds + '\n');
            print('   ' + client.netconnection.address + '\n');
        }
    }

    static function God_f() {
        if (!Cmd.client) {
            Cmd.ForwardToServer();
            return;
        }
        if (PR.globals.deathmatch != 0)
            return;
        SV.player.flags = SV.player.flags ^ EntFlag.godmode;
        if ((SV.player.flags & EntFlag.godmode) == 0)
            Host.ClientPrint('godmode OFF\n');
        else
            Host.ClientPrint('godmode ON\n');
    }

    static function Notarget_f() {
        if (!Cmd.client) {
            Cmd.ForwardToServer();
            return;
        }
        if (PR.globals.deathmatch != 0)
            return;
        SV.player.flags = SV.player.flags ^ EntFlag.notarget;
        if ((SV.player.flags & EntFlag.notarget) == 0)
            Host.ClientPrint('notarget OFF\n');
        else
            Host.ClientPrint('notarget ON\n');
    }

    static function Noclip_f() {
        if (!Cmd.client) {
            Cmd.ForwardToServer();
            return;
        }
        if (PR.globals.deathmatch != 0)
            return;
        if (SV.player.v.movetype != MoveType.noclip) {
            Host.noclip_anglehack = true;
            SV.player.v.movetype = MoveType.noclip;
            Host.ClientPrint('noclip ON\n');
            return;
        }
        Host.noclip_anglehack = false;
        SV.player.v.movetype = MoveType.walk;
        Host.ClientPrint('noclip OFF\n');
    }

    static function Fly_f() {
        if (!Cmd.client) {
            Cmd.ForwardToServer();
            return;
        }
        if (PR.globals.deathmatch != 0)
            return;
        if (SV.player.v.movetype != MoveType.fly) {
            SV.player.v.movetype = MoveType.fly;
            Host.ClientPrint('flymode ON\n');
            return;
        }
        SV.player.v.movetype = MoveType.walk;
        Host.ClientPrint('flymode OFF\n');
    }

    static function Ping_f() {
        if (!Cmd.client) {
            Cmd.ForwardToServer();
            return;
        }
        Host.ClientPrint('Client ping times:\n');
        for (i in 0...SV.svs.maxclients) {
            var client = SV.svs.clients[i];
            if (!client.active)
                continue;
            var total = 0.0;
            for (j in 0...16)
                total += client.ping_times[j];
            var total = (total * 62.5).toFixed(0);
            if (total.length == 1)
                total = '   ' + total;
            else if (total.length == 2)
                total = '  ' + total;
            else if (total.length == 3)
                total = ' ' + total;
            Host.ClientPrint(total + ' ' + SV.GetClientName(client) + '\n');
        }
    }

    static function Map_f() {
        if (Cmd.argv.length <= 1) {
            Console.Print('USAGE: map <map>\n');
            return;
        }
        if (Cmd.client)
            return;
        CL.cls.demonum = -1;
        CL.Disconnect();
        Host.ShutdownServer(false);
        Key.dest = game;
        SCR.BeginLoadingPlaque();
        SV.svs.serverflags = 0;
        SV.SpawnServer(Cmd.argv[1]);
        if (!SV.server.active)
            return;
        CL.cls.spawnparms = '';
        for (i in 2...Cmd.argv.length)
            CL.cls.spawnparms += Cmd.argv[i] + ' ';
        Cmd.ExecuteString('connect local');
    }

    static function Changelevel_f() {
        if (Cmd.argv.length != 2) {
            Console.Print('changelevel <levelname> : continue game on a new level\n');
            return;
        }
        if ((!SV.server.active) || (CL.cls.demoplayback)) {
            Console.Print('Only the server may changelevel\n');
            return;
        }
        SV.SaveSpawnparms();
        SV.SpawnServer(Cmd.argv[1]);
    }

    static function Restart_f() {
        if (!CL.cls.demoplayback && SV.server.active && !Cmd.client)
            SV.SpawnServer(PR.GetString(PR.globals.mapname));
    }

    static function Reconnect_f() {
        SCR.BeginLoadingPlaque();
        CL.cls.signon = 0;
    }

    static function Connect_f() {
        CL.cls.demonum = -1;
        if (CL.cls.demoplayback) {
            CL.StopPlayback();
            CL.Disconnect();
        }
        CL.EstablishConnection(Cmd.argv[1]);
        CL.cls.signon = 0;
    }

    static function SavegameComment() {
        var text = ~/\s/gm.replace(CL.state.levelname, "_");
        for (i in CL.state.levelname.length...22)
            text += '_';

        text += 'kills:';
        var kills = Std.string(CL.state.stats[ClientStat.monsters]);
        if (kills.length == 2)
            text += '_';
        else if (kills.length == 1)
            text += '__';
        text += kills + '/';
        kills = Std.string(CL.state.stats[ClientStat.totalmonsters]);
        if (kills.length == 2)
            text += '_';
        else if (kills.length == 1)
            text += '__';
        text += kills;

        return text + '____';
    }

    static function Savegame_f() {
        if (Cmd.client)
            return;
        if (!SV.server.active) {
            Console.Print('Not playing a local game.\n');
            return;
        }
        if (CL.state.intermission != 0) {
            Console.Print('Can\'t save in intermission.\n');
            return;
        }
        if (SV.svs.maxclients != 1) {
            Console.Print('Can\'t save multiplayer games.\n');
            return;
        }
        if (Cmd.argv.length != 2) {
            Console.Print('save <savename> : save a game\n');
            return;
        }
        if (Cmd.argv[1].indexOf('..') != -1) {
            Console.Print('Relative pathnames are not allowed.\n');
            return;
        }
        var client = SV.svs.clients[0];
        if (client.active) {
            if (client.edict.v.health <= 0.0) {
                Console.Print('Can\'t savegame with a dead player\n');
                return;
            }
        }
        var f = ['5\n' + Host.SavegameComment() + '\n'];
        for (i in 0...16)
            f.push(client.spawn_parms[i].toFixed(6) + '\n');
        f.push(Host.current_skill + '\n' + PR.GetString(PR.globals.mapname) + '\n' + SV.server.time.toFixed(6) + '\n');
        for (ls in SV.server.lightstyles) {
            if (ls.length != 0)
                f.push(ls + '\n');
            else
                f.push('m\n');
        }
        f.push('{\n');
        for (def in PR.globaldefs) {
            var type = def.type;
            if ((type & 0x8000) == 0)
                continue;
            var type:EType = type & 0x7fff;
            if ((type != ev_string) && (type != ev_float) && (type != ev_entity))
                continue;
            f.push('"' + PR.GetString(def.name) + '" "' + PR.UglyValueString(cast type, PR.globals.buffer, def.ofs) + '"\n');
        }
        f.push('}\n');
        for (i in 0...SV.server.num_edicts) {
            var ed = SV.server.edicts[i];
            if (ed.free) {
                f.push('{\n}\n');
                continue;
            }
            f.push('{\n');
            for (def in PR.fielddefs) {
                var name = PR.GetString(def.name);
                if (name.charCodeAt(name.length - 2) == 95)
                    continue;
                var type = def.type & 0x7fff;
                var v = def.ofs;
                if (ed.v.ints[v] == 0) {
                    if (type == 3) {
                        if ((ed.v.ints[v + 1] == 0) && (ed.v.ints[v + 2] == 0))
                            continue;
                    }
                    else
                        continue;
                }
                f.push('"' + name + '" "' + PR.UglyValueString(type, ed.v.buffer, def.ofs) + '"\n');
            }
            f.push('}\n');
        }
        var name = COM.DefaultExtension(Cmd.argv[1], '.sav');
        Console.Print('Saving game to ' + name + '...\n');
        if (COM.WriteTextFile(name, f.join('')))
            Console.Print('done.\n');
        else
            Console.Print('ERROR: couldn\'t open.\n');
    }

    static function Loadgame_f() {
        if (Cmd.client)
            return;
        if (Cmd.argv.length != 2) {
            Console.Print('load <savename> : load a game\n');
            return;
        }
        CL.cls.demonum = -1;
        var name = COM.DefaultExtension(Cmd.argv[1], '.sav');
        Console.Print('Loading game from ' + name + '...\n');
        var f = COM.LoadTextFile(name);
        if (f == null) {
            Console.Print('ERROR: couldn\'t open.\n');
            return;
        }
        var f = f.split('\n');

        var tfloat = Std.parseFloat(f[0]);
        if (tfloat != 5) {
            Console.Print('Savegame is version ' + tfloat + ', not 5\n');
            return;
        }

        var spawn_parms = [];
        for (i in 0...16)
            spawn_parms[i] = Std.parseFloat(f[2 + i]);

        Host.current_skill = Std.int(Std.parseFloat(f[18]) + 0.1);
        Host.skill.setValue(Host.current_skill);

        var time = Std.parseFloat(f[20]);
        CL.Disconnect();
        SV.SpawnServer(f[19]);
        if (!SV.server.active) {
            Console.Print('Couldn\'t load map\n');
            return;
        }
        SV.server.paused = true;
        SV.server.loadgame = true;

        for (i in 0...CL.MAX_LIGHTSTYLES)
            SV.server.lightstyles[i] = f[21 + i];

        if (f[85] != '{')
            Sys.Error('First token isn\'t a brace');
        var i = 86;
        while (i < f.length) {
            if (f[i] == '}') {
                ++i;
                break;
            }
            var token = f[i].split('"');
            var keyname = token[1];
            var key = ED.FindGlobal(keyname);
            i++;
            if (key == null) {
                Console.Print('\'' + keyname + '\' is not a global\n');
                continue;
            }
            if (!ED.ParseEpair(PR.globals.buffer, key, token[3]))
                Host.Error('Host.Loadgame_f: parse error');
        }

        f.push('');
        var entnum = 0;
        var data = f.slice(i).join('\n');
        while(true) {
            data = COM.Parse(data);
            if (data == null)
                break;
            if (COM.token.charCodeAt(0) != 123)
                Sys.Error('Host.Loadgame_f: found ' + COM.token + ' when expecting {');
            var ent = SV.server.edicts[entnum++];
            for (j in 0...PR.entityfields)
                ent.v.ints[j] = 0;
            ent.free = false;
            data = ED.ParseEdict(data, ent);
            if (!ent.free)
                SV.LinkEdict(ent, false);
        }
        SV.server.num_edicts = entnum;

        SV.server.time = time;
        var client = SV.svs.clients[0];
        client.spawn_parms = [];
        for (i in 0...16)
            client.spawn_parms[i] = spawn_parms[i];
        CL.EstablishConnection('local');
        Host.Reconnect_f();
    }

    static function Name_f() {
        if (Cmd.argv.length <= 1) {
            Console.Print('"name" is "' + CL.name.string + '"\n');
            return;
        }

        var newName;
        if (Cmd.argv.length == 2)
            newName = Cmd.argv[1].substring(0, 15);
        else
            newName = Cmd.args.substring(0, 15);

        if (!Cmd.client) {
            CL.name.set(newName);
            if (CL.cls.state == connected)
                Cmd.ForwardToServer();
            return;
        }

        var name = SV.GetClientName(Host.client);
        if ((name.length != 0) && (name != 'unconnected') && (name != newName))
            Console.Print(name + ' renamed to ' + newName + '\n');
        SV.SetClientName(Host.client, newName);
        var msg = SV.server.reliable_datagram;
        msg.WriteByte(SVC.updatename);
        msg.WriteByte(Host.client.num);
        msg.WriteString(newName);
    }

    static function Version_f() {
        Console.Print('Version 1.09\n');
        Console.Print(Def.timedate);
    }

    static function Say(teamonly) {
        if (!Cmd.client) {
            Cmd.ForwardToServer();
            return;
        }
        if (Cmd.argv.length <= 1)
            return;
        var save = Host.client;
        var p = Cmd.args;
        if (p.charCodeAt(0) == 34)
            p = p.substring(1, p.length - 1);
        var text = String.fromCharCode(1)+ SV.GetClientName(save) + ': ';
        var i = 62 - text.length;
        if (p.length > i)
            p = p.substring(0, i);
        text += p + '\n';
        for (i in 0...SV.svs.maxclients) {
            var client = SV.svs.clients[i];
            if ((!client.active) || (!client.spawned))
                continue;
            if ((Host.teamplay.value != 0) && (teamonly) && (client.edict.v.team != save.edict.v.team))
                continue;
            Host.client = client;
            Host.ClientPrint(text);
        }
        Host.client = save;
        Sys.Print(text.substring(1));
    }

    static function Say_Team_f() {
        Host.Say(true);
    }

    static function Tell_f() {
        if (!Cmd.client) {
            Cmd.ForwardToServer();
            return;
        }
        if (Cmd.argv.length <= 2)
            return;
        var text = SV.GetClientName(Host.client) + ': ';
        var p = Cmd.args;
        if (p.charCodeAt(0) == 34)
            p = p.substring(1, p.length - 1);
        var i = 62 - text.length;
        if (p.length > i)
             p = p.substring(0, i);
        text += p + '\n';
        var save = Host.client;
        for (i in 0...SV.svs.maxclients) {
            var client = SV.svs.clients[i];
            if ((!client.active) || (!client.spawned))
                continue;
            if (SV.GetClientName(client).toLowerCase() != Cmd.argv[1].toLowerCase())
                continue;
            Host.client = client;
            Host.ClientPrint(text);
            break;
        }
        Host.client = save;
    }

    static function Color_f() {
        if (Cmd.argv.length <= 1) {
            var col = Std.int(CL.color.value);
            Console.Print('"color" is "' + (col >> 4) + ' ' + (col & 15) + '"\ncolor <0-13> [0-13]\n');
            return;
        }

        var top, bottom;
        if (Cmd.argv.length == 2)
            top = bottom = (Q.atoi(Cmd.argv[1]) & 15) >>> 0;
        else {
            top = (Q.atoi(Cmd.argv[1]) & 15) >>> 0;
            bottom = (Q.atoi(Cmd.argv[2]) & 15) >>> 0;
        }
        if (top >= 14)
            top = 13;
        if (bottom >= 14)
            bottom = 13;
        var playercolor = (top << 4) + bottom;

        if (!Cmd.client) {
            CL.color.setValue(playercolor);
            if (CL.cls.state == connected)
                Cmd.ForwardToServer();
            return;
        }

        Host.client.colors = playercolor;
        Host.client.edict.v.team = bottom + 1;
        var msg = SV.server.reliable_datagram;
        msg.WriteByte(SVC.updatecolors);
        msg.WriteByte(Host.client.num);
        msg.WriteByte(playercolor);
    }

    static function Kill_f() {
        if (!Cmd.client) {
            Cmd.ForwardToServer();
            return;
        }
        if (SV.player.v.health <= 0.0) {
            Host.ClientPrint('Can\'t suicide -- already dead!\n');
            return;
        }
        PR.globals.time = SV.server.time;
        PR.globals.self = SV.player.num;
        PR.ExecuteProgram(PR.globals.ClientKill);
    }

    static function Pause_f() {
        if (!Cmd.client) {
            Cmd.ForwardToServer();
            return;
        }
        if (Host.pausable.value == 0) {
            Host.ClientPrint('Pause not allowed.\n');
            return;
        }
        SV.server.paused = !SV.server.paused;
        Host.BroadcastPrint(SV.GetClientName(Host.client) + (SV.server.paused ? ' paused the game\n' : ' unpaused the game\n'));
        SV.server.reliable_datagram.WriteByte(SVC.setpause);
        SV.server.reliable_datagram.WriteByte(SV.server.paused ? 1 : 0);
    }

    static function PreSpawn_f() {
        if (!Cmd.client) {
            Console.Print('prespawn is not valid from the console\n');
            return;
        }
        var client = Host.client;
        if (client.spawned) {
            Console.Print('prespawn not valid -- already spawned\n');
            return;
        }
        client.message.Write(new Uint8Array(SV.server.signon.data), SV.server.signon.cursize);
        client.message.WriteByte(SVC.signonnum);
        client.message.WriteByte(2);
        client.sendsignon = true;
    }

    static function Spawn_f() {
        if (!Cmd.client) {
            Console.Print('spawn is not valid from the console\n');
            return;
        }
        var client = Host.client;
        if (client.spawned) {
            Console.Print('Spawn not valid -- already spawned\n');
            return;
        }

        var ent = client.edict;
        if (SV.server.loadgame)
            SV.server.paused = false;
        else {
            for (i in 0...PR.entityfields)
                ent.v.ints[i] = 0;
            ent.v.colormap = ent.num;
            ent.v.team = (client.colors & 15) + 1;
            ent.v.netname = PR.netnames + (client.num << 5);
            PR.globals.SetParms(client.spawn_parms);
            PR.globals.time = SV.server.time;
            PR.globals.self = ent.num;
            PR.ExecuteProgram(PR.globals.ClientConnect);
            if ((Sys.FloatTime() - client.netconnection.connecttime) <= SV.server.time)
                Sys.Print(SV.GetClientName(client) + ' entered the game\n');
            PR.ExecuteProgram(PR.globals.PutClientInServer);
        }

        var message = client.message;
        message.cursize = 0;
        message.WriteByte(SVC.time);
        message.WriteFloat(SV.server.time);
        for (i in 0...SV.svs.maxclients) {
            client = SV.svs.clients[i];
            message.WriteByte(SVC.updatename);
            message.WriteByte(i);
            message.WriteString(SV.GetClientName(client));
            message.WriteByte(SVC.updatefrags);
            message.WriteByte(i);
            message.WriteShort(client.old_frags);
            message.WriteByte(SVC.updatecolors);
            message.WriteByte(i);
            message.WriteByte(client.colors);
        }
        for (i in 0...CL.MAX_LIGHTSTYLES) {
            message.WriteByte(SVC.lightstyle);
            message.WriteByte(i);
            message.WriteString(SV.server.lightstyles[i]);
        }
        message.WriteByte(SVC.updatestat);
        message.WriteByte(ClientStat.totalsecrets);
        message.WriteLong(Std.int(PR.globals.total_secrets));
        message.WriteByte(SVC.updatestat);
        message.WriteByte(ClientStat.totalmonsters);
        message.WriteLong(Std.int(PR.globals.total_monsters));
        message.WriteByte(SVC.updatestat);
        message.WriteByte(ClientStat.secrets);
        message.WriteLong(Std.int(PR.globals.found_secrets));
        message.WriteByte(SVC.updatestat);
        message.WriteByte(ClientStat.monsters);
        message.WriteLong(Std.int(PR.globals.killed_monsters));
        message.WriteByte(SVC.setangle);
        message.WriteAngle(ent.v.angles[0]);
        message.WriteAngle(ent.v.angles[1]);
        message.WriteAngle(0.0);
        SV.WriteClientdataToMessage(ent, message);
        message.WriteByte(SVC.signonnum);
        message.WriteByte(3);
        Host.client.sendsignon = true;
    }

    static function Begin_f() {
        if (!Cmd.client) {
            Console.Print('begin is not valid from the console\n');
            return;
        }
        Host.client.spawned = true;
    }

    static function Kick_f() {
        if (!Cmd.client) {
            if (!SV.server.active) {
                Cmd.ForwardToServer();
                return;
            }
        } else if (PR.globals.deathmatch != 0.0) {
            return;
        }
        if (Cmd.argv.length <= 1)
            return;
        var save = Host.client;
        var s = Cmd.argv[1].toLowerCase();
        var i, byNumber = null;
        if ((Cmd.argv.length >= 3) && (s == '#')) {
            i = Q.atoi(Cmd.argv[2]) - 1;
            if ((i < 0) || (i >= SV.svs.maxclients))
                return;
            if (!SV.svs.clients[i].active)
                return;
            Host.client = SV.svs.clients[i];
            byNumber = true;
        } else {
            i = 0;
            while (i < SV.svs.maxclients) {
                Host.client = SV.svs.clients[i];
                if (!Host.client.active) {
                    i++;
                    continue;
                }
                if (SV.GetClientName(Host.client).toLowerCase() == s)
                    break;
                i++;
            }
        }
        if (i >= SV.svs.maxclients) {
            Host.client = save;
            return;
        }
        if (Host.client == save)
            return;
        var who;
        if (!Cmd.client)
            who = CL.name.string;
        else {
            if (Host.client == save)
                return;
            who = SV.GetClientName(save);
        }
        var message = null;
        if (Cmd.argv.length >= 3)
            message = COM.Parse(Cmd.args);
        if (message != null) {
            var p = 0;
            if (byNumber) {
                ++p;
                while (p < message.length) {
                    if (message.charCodeAt(p) != 32)
                        break;
                    p++;
                }
                p += Cmd.argv[2].length;
            }
            while (p < message.length) {
                if (message.charCodeAt(p) != 32)
                    break;
                p++;
            }
            Host.ClientPrint('Kicked by ' + who + ': ' + message.substring(p) + '\n');
        }
        else
            Host.ClientPrint('Kicked by ' + who + '\n');
        Host.DropClient(false);
        Host.client = save;
    }

    static function Give_f() {
        if (!Cmd.client) {
            Cmd.ForwardToServer();
            return;
        }
        if (PR.globals.deathmatch != 0)
            return;
        if (Cmd.argv.length <= 1)
            return;
        var t = Cmd.argv[1].charCodeAt(0);
        var ent = SV.player;

        if (t >= "0".code && t <= "9".code) {
            if (!COM.hipnotic) {
                if (t >= "2".code)
                    ent.items |= Def.it.shotgun << (t - "2".code);
                return;
            }
            if (t == "6".code) {
                if (Cmd.argv[1].charCodeAt(1) == "a".code)
                    ent.items |= Def.hit.proximity_gun;
                else
                    ent.items |= Def.it.grenade_launcher;
                return;
            }
            if (t == "9".code)
                ent.items |= Def.hit.laser_cannon;
            else if (t == "0".code)
                ent.items |= Def.hit.mjolnir;
            else if (t >= "2".code)
                ent.items |= Def.it.shotgun << (t - "2".code);
            return;
        }
        var v = Q.atoi(Cmd.argv[2]);
        if (t == "h".code) {
            ent.v.health = v;
            return;
        }
        if (!COM.rogue) {
            switch (t) {
                case "s".code:
                    ent.v.ammo_shells = v;
                case "n".code:
                    ent.v.ammo_nails = v;
                case "r".code:
                    ent.v.ammo_rockets = v;
                case "c".code:
                    ent.v.ammo_cells = v;
            }
            return;
        }
        switch (t) {
            case "s".code:
                if (EdictVars.ammo_shells1_ofs != null)
                    ent.v.ammo_shells1 = v;
                ent.v.ammo_shells = v;
            case "n".code:
                if (EdictVars.ammo_nails1_ofs != null) {
                    ent.v.ammo_nails1 = v;
                    if (ent.v.weapon <= Def.it.lightning)
                        ent.v.ammo_nails = v;
                }
            case "l".code:
                if (EdictVars.ammo_lava_nails_ofs != null) {
                    ent.v.ammo_lava_nails = v;
                    if (ent.v.weapon > Def.it.lightning)
                        ent.v.ammo_nails = v;
                }
            case "r".code:
                if (EdictVars.ammo_rockets1_ofs != null) {
                    ent.v.ammo_rockets1 = v;
                    if (ent.v.weapon <= Def.it.lightning)
                        ent.v.ammo_rockets = v;
                }
            case "m".code:
                if (EdictVars.ammo_multi_rockets_ofs != null) {
                    ent.v.ammo_multi_rockets = v;
                    if (ent.v.weapon > Def.it.lightning)
                        ent.v.ammo_rockets = v;
                }
            case "c".code:
                if (EdictVars.ammo_cells1_ofs != null) {
                    ent.v.ammo_cells1 = v;
                    if (ent.v.weapon <= Def.it.lightning)
                        ent.v.ammo_cells = v;
                }
            case "p".code:
                if (EdictVars.ammo_plasma_ofs != null) {
                    ent.v.ammo_plasma = v;
                    if (ent.v.weapon > Def.it.lightning)
                        ent.v.ammo_cells = v;
                }
        }
    }

    static function FindViewthing():Edict {
        if (SV.server.active) {
            for (i in 0...SV.server.num_edicts) {
                var e = SV.server.edicts[i];
                if (PR.GetString(e.v.classname) == 'viewthing')
                    return e;
            }
        }
        Console.Print('No viewthing on map\n');
        return null;
    }

    static function Viewmodel_f() {
        if (Cmd.argv.length != 2)
            return;
        var ent = Host.FindViewthing();
        if (ent == null)
            return;
        var m = Mod.ForName(Cmd.argv[1], false);
        if (m == null) {
            Console.Print('Can\'t load ' + Cmd.argv[1] + '\n');
            return;
        }
        ent.v.frame = 0.0;
        CL.state.model_precache[Std.int(ent.v.modelindex)] = m;
    }

    static function Viewframe_f() {
        var ent = Host.FindViewthing();
        if (ent == null)
            return;
        var m = CL.state.model_precache[Std.int(ent.v.modelindex)];
        var f = Q.atoi(Cmd.argv[1]);
        if (f >= m.frames.length)
            f = m.frames.length - 1;
        ent.v.frame = f;
    }

    static function Viewnext_f() {
        var ent = Host.FindViewthing();
        if (ent == null)
            return;
        var m = CL.state.model_precache[Std.int(ent.v.modelindex)];
        var f = Std.int(ent.v.frame) + 1;
        if (f >= m.frames.length)
            f = m.frames.length - 1;
        ent.v.frame = f;
        Console.Print('frame ' + f + ': ' + m.frames[f].name + '\n');
    }

    static function Viewprev_f() {
        var ent = Host.FindViewthing();
        if (ent == null)
            return;
        var m = CL.state.model_precache[Std.int(ent.v.modelindex)];
        var f = Std.int(ent.v.frame) - 1;
        if (f < 0)
            f = 0;
        ent.v.frame = f;
        Console.Print('frame ' + f + ': ' + m.frames[f].name + '\n');
    }

    static function Startdemos_f() {
        Console.Print((Cmd.argv.length - 1) + ' demo(s) in loop\n');
        CL.cls.demos = [];
        for (i in 1...Cmd.argv.length)
            CL.cls.demos[i - 1] = Cmd.argv[i];
        if (CL.cls.demonum != -1 && !CL.cls.demoplayback) {
            CL.cls.demonum = 0;
            if (Host.framecount != 0)
                CL.NextDemo();
            else
                Host.startdemos = true;
        }
        else
            CL.cls.demonum = -1;
    }

    static function Demos_f() {
        if (CL.cls.demonum == -1)
            CL.cls.demonum = 1;
        CL.Disconnect();
        CL.NextDemo();
    }

    static function Stopdemo_f() {
        if (!CL.cls.demoplayback)
            return;
        CL.StopPlayback();
        CL.Disconnect();
    }

    static function InitCommands() {
        Cmd.AddCommand('status', Host.Status_f);
        Cmd.AddCommand('quit', Host.Quit_f);
        Cmd.AddCommand('god', Host.God_f);
        Cmd.AddCommand('notarget', Host.Notarget_f);
        Cmd.AddCommand('fly', Host.Fly_f);
        Cmd.AddCommand('map', Host.Map_f);
        Cmd.AddCommand('restart', Host.Restart_f);
        Cmd.AddCommand('changelevel', Host.Changelevel_f);
        Cmd.AddCommand('connect', Host.Connect_f);
        Cmd.AddCommand('reconnect', Host.Reconnect_f);
        Cmd.AddCommand('name', Host.Name_f);
        Cmd.AddCommand('noclip', Host.Noclip_f);
        Cmd.AddCommand('version', Host.Version_f);
        Cmd.AddCommand('say', Host.Say.bind(false));
        Cmd.AddCommand('say_team', Host.Say_Team_f);
        Cmd.AddCommand('tell', Host.Tell_f);
        Cmd.AddCommand('color', Host.Color_f);
        Cmd.AddCommand('kill', Host.Kill_f);
        Cmd.AddCommand('pause', Host.Pause_f);
        Cmd.AddCommand('spawn', Host.Spawn_f);
        Cmd.AddCommand('begin', Host.Begin_f);
        Cmd.AddCommand('prespawn', Host.PreSpawn_f);
        Cmd.AddCommand('kick', Host.Kick_f);
        Cmd.AddCommand('ping', Host.Ping_f);
        Cmd.AddCommand('load', Host.Loadgame_f);
        Cmd.AddCommand('save', Host.Savegame_f);
        Cmd.AddCommand('give', Host.Give_f);
        Cmd.AddCommand('startdemos', Host.Startdemos_f);
        Cmd.AddCommand('demos', Host.Demos_f);
        Cmd.AddCommand('stopdemo', Host.Stopdemo_f);
        Cmd.AddCommand('viewmodel', Host.Viewmodel_f);
        Cmd.AddCommand('viewframe', Host.Viewframe_f);
        Cmd.AddCommand('viewnext', Host.Viewnext_f);
        Cmd.AddCommand('viewprev', Host.Viewprev_f);
        Cmd.AddCommand('mcache', Mod.Print);
    }

}
