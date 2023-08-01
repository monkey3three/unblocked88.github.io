package quake;

import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Uint8Array;
import js.html.XMLHttpRequest;
import quake.Entity.EntityEffect;
import quake.Mod.MModel;
import quake.Mod.ModelEffect;
import quake.NET.INETSocket;
import quake.Protocol;
import quake.S.Sfx;
import quake.Def.ClientStat;
using Tools;

@:publicFields
private class Beam {
    var entity:Int;
    var model:MModel;
    var endtime:Float;
    var start(default,null):Vec;
    var end(default,null):Vec;

    function new() {
        entity = 0;
        model = null;
        endtime = 0;
        start = new Vec();
        end = new Vec();
    }
}

@:publicFields
private class ClientStatic {
    var state:ClientActive;
    var spawnparms:String;
    var demorecording:Bool;
    var demoplayback:Bool;
    var demonum:Int;
    var demos:Array<String>;
    var demoname:String;
    var demofile:ArrayBuffer;
    var demoofs:Int;
    var demosize:Int;
    var timedemo:Bool;
    var td_startframe:Int;
    var td_lastframe:Int;
    var td_starttime:Float;
    var message(default,null):MSG;
    var netcon:INETSocket;
    var signon:Int;
    var forcetrack:Int;

    function new() {
        this.state = disconnected;
        this.spawnparms = '';
        this.demonum = 0;
        this.message = new MSG(8192);
    }
}

@:publicFields
class ClientCmd {
    var forwardmove:Float = 0.0;
    var sidemove:Float = 0.0;
    var upmove:Float = 0.0;
    function new() {}
}

@:publicFields
private class Score {
    var name = '';
    var entertime = 0.0;
    var frags = 0;
    var colors = 0;
    function new() {}
}

@:publicFields
private class ClientState {
    var mtime0:Float = 0.0;
    var mtime1:Float = 0.0;
    var time = 0.0;
    var viewangles(default,never) = new Vec();
    var mviewangles0(default,never) = new Vec();
    var mviewangles1(default,never) = new Vec();
    var mvelocity0(default,never) = new Vec();
    var mvelocity1(default,never) = new Vec();
    var velocity(default,never) = new Vec();
    var cmd(default,never) = new ClientCmd();
    var movemessages = 0;
    var stats = [
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0
    ];
    var items = 0;
    var item_gettime = [
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    ];
    var faceanimtime = 0.0;
    var cshifts = [[0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0]];
    var punchangle(default,never) = new Vec();
    var idealpitch = 0.0;
    var pitchvel = 0.0;
    var driftmove = 0.0;
    var laststop = 0.0;
    var crouch = 0.0;
    var intermission = 0;
    var completed_time = 0.0;
    var oldtime = 0.0;
    var last_received_message = 0.0;
    var viewentity = 0;
    var viewent(default,never) = new Entity();
    var cdtrack = 0;
    var looptrack = 0;
    var inwater:Bool;
    var paused:Bool;
    var onground:Bool;
    var nodrift:Bool;
    var model_precache:Array<MModel>;
    var sound_precache:Array<Sfx>;
    var maxclients:Int;
    var scores:Array<Score>;
    var gametype:Int;
    var levelname:String;
    var worldmodel:MModel;
    var viewheight:Float;

    function new() {}
}

@:enum abstract CShift(Int) to Int {
    var contents = 0;
    var damage = 1;
    var bonus = 2;
    var powerup = 3;

    public static inline var numtotal = 4;
}

@:enum abstract ClientActive(Int) {
    var disconnected = 0;
    var connecting = 1;
    var connected = 2;
}

class CL {

    public static var name(default,null):Cvar;
    public static var color(default,null):Cvar;
    static var upspeed:Cvar;
    public static var forwardspeed(default,null):Cvar;
    public static var backspeed(default,null):Cvar;
    static var sidespeed:Cvar;
    static var movespeedkey:Cvar;
    static var yawspeed:Cvar;
    static var pitchspeed:Cvar;
    static var anglespeedkey:Cvar;
    static var shownet:Cvar;
    static var nolerp:Cvar;
    public static var lookspring(default,null):Cvar;
    public static var lookstrafe(default,null):Cvar;
    public static var sensitivity(default,null):Cvar;
    public static var m_pitch(default,null):Cvar;
    public static var m_yaw(default,null):Cvar;
    public static var m_forward(default,null):Cvar;
    public static var m_side(default,null):Cvar;
    static var rcon_password:Cvar;
    static var rcon_address:Cvar;

    static var temp_entities:Array<Entity> = [];
    static var num_temp_entities:Int;

    static var sfx_wizhit:Sfx;
    static var sfx_knighthit:Sfx;
    static var sfx_tink1:Sfx;
    static var sfx_ric1:Sfx;
    static var sfx_ric2:Sfx;
    static var sfx_ric3:Sfx;
    static var sfx_r_exp3:Sfx;

    // demo

    public static function StopPlayback() {
        if (!CL.cls.demoplayback)
            return;
        CL.cls.demoplayback = false;
        CL.cls.demofile = null;
        CL.cls.state = disconnected;
        if (CL.cls.timedemo)
            CL.FinishTimeDemo();
    }

    static function WriteDemoMessage() {
        var len = CL.cls.demoofs + 16 + NET.message.cursize;
        if (CL.cls.demofile.byteLength < len) {
            var src = new Uint8Array(CL.cls.demofile, 0, CL.cls.demoofs);
            CL.cls.demofile = new ArrayBuffer(CL.cls.demofile.byteLength + 16384);
            (new Uint8Array(CL.cls.demofile)).set(src);
        }
        var f = new DataView(CL.cls.demofile, CL.cls.demoofs, 16);
        f.setInt32(0, NET.message.cursize, true);
        f.setFloat32(4, CL.state.viewangles[0], true);
        f.setFloat32(8, CL.state.viewangles[1], true);
        f.setFloat32(12, CL.state.viewangles[2], true);
        (new Uint8Array(CL.cls.demofile)).set(new Uint8Array(NET.message.data, 0, NET.message.cursize), CL.cls.demoofs + 16);
        CL.cls.demoofs = len;
    }

    static function GetMessage() {
        if (CL.cls.demoplayback) {
            if (CL.cls.signon == 4) {
                if (CL.cls.timedemo) {
                    if (Host.framecount == CL.cls.td_lastframe)
                        return 0;
                    CL.cls.td_lastframe = Host.framecount;
                    if (Host.framecount == (CL.cls.td_startframe + 1))
                        CL.cls.td_starttime = Host.realtime;
                }
                else if (CL.state.time <= CL.state.mtime0)
                    return 0;
            }
            if ((CL.cls.demoofs + 16) >= CL.cls.demosize) {
                CL.StopPlayback();
                return 0;
            }
            var view = new DataView(CL.cls.demofile);
            NET.message.cursize = view.getUint32(CL.cls.demoofs, true);
            if (NET.message.cursize > 8000)
                Sys.Error('Demo message > MAX_MSGLEN');
            CL.state.mviewangles1.setVector(CL.state.mviewangles0);
            CL.state.mviewangles0.setValues(view.getFloat32(CL.cls.demoofs + 4, true), view.getFloat32(CL.cls.demoofs + 8, true), view.getFloat32(CL.cls.demoofs + 12, true));
            CL.cls.demoofs += 16;
            if ((CL.cls.demoofs + NET.message.cursize) > CL.cls.demosize) {
                CL.StopPlayback();
                return 0;
            }
            var src = new Uint8Array(CL.cls.demofile, CL.cls.demoofs, NET.message.cursize);
            var dest = new Uint8Array(NET.message.data, 0, NET.message.cursize);
            for (i in 0...NET.message.cursize)
                dest[i] = src[i];
            CL.cls.demoofs += NET.message.cursize;
            return 1;
        };

        var r = null;
        while (true) {
            r = NET.GetMessage(CL.cls.netcon);
            if ((r != 1) && (r != 2))
                return r;
            if ((NET.message.cursize == 1) && ((new Uint8Array(NET.message.data, 0, 1))[0] == SVC.nop))
                Console.Print('<-- server to client keepalive\n');
            else
                break;
        }

        if (CL.cls.demorecording)
            CL.WriteDemoMessage();

        return r;
    }

    static function Stop_f() {
        if (Cmd.client)
            return;
        if (!CL.cls.demorecording) {
            Console.Print('Not recording a demo.\n');
            return;
        }
        NET.message.cursize = 0;
        NET.message.WriteByte(SVC.disconnect);
        CL.WriteDemoMessage();
        if (!COM.WriteFile(CL.cls.demoname, new Uint8Array(CL.cls.demofile), CL.cls.demoofs))
            Console.Print('ERROR: couldn\'t open.\n');
        CL.cls.demofile = null;
        CL.cls.demorecording = false;
        Console.Print('Completed demo\n');
    }

    static function Record_f() {
        var c = Cmd.argv.length;
        if ((c <= 1) || (c >= 5)) {
            Console.Print('record <demoname> [<map> [cd track]]\n');
            return;
        }
        if (Cmd.argv[1].indexOf('..') != -1) {
            Console.Print('Relative pathnames are not allowed.\n');
            return;
        }
        if ((c == 2) && (CL.cls.state == connected)) {
            Console.Print('Can not record - already connected to server\nClient demo recording must be started before connecting\n');
            return;
        }
        if (c == 4) {
            CL.cls.forcetrack = Q.atoi(Cmd.argv[3]);
            Console.Print('Forcing CD track to ' + CL.cls.forcetrack);
        }
        else
            CL.cls.forcetrack = -1;
        CL.cls.demoname = COM.DefaultExtension(Cmd.argv[1], '.dem');
        if (c >= 3)
            Cmd.ExecuteString('map ' + Cmd.argv[2]);
        Console.Print('recording to ' + CL.cls.demoname + '.\n');
        CL.cls.demofile = new ArrayBuffer(16384);
        var track = Std.string(CL.cls.forcetrack) + '\n';
        var dest = new Uint8Array(CL.cls.demofile, 0, track.length);
        for (i in 0...track.length)
            dest[i] = track.charCodeAt(i);
        CL.cls.demoofs = track.length;
        CL.cls.demorecording = true;
    }

    static function PlayDemo_f() {
        if (Cmd.client)
            return;
        if (Cmd.argv.length != 2) {
            Console.Print('playdemo <demoname> : plays a demo\n');
            return;
        }
        CL.Disconnect();
        var name = COM.DefaultExtension(Cmd.argv[1], '.dem');
        Console.Print('Playing demo from ' + name + '.\n');
        var demofile = COM.LoadFile(name);
        if (demofile == null) {
            Console.Print('ERROR: couldn\'t open.\n');
            CL.cls.demonum = -1;
            SCR.disabled_for_loading = false;
            return;
        }
        CL.cls.demofile = demofile;
        var demofile = new Uint8Array(demofile);
        CL.cls.demosize = demofile.length;
        CL.cls.demoplayback = true;
        CL.cls.state = connected;
        CL.cls.forcetrack = 0;
        var i = 0, neg = false;
        while (i < demofile.length) {
            var c = demofile[i];
            if (c == 10)
                break;
            if (c == 45)
                neg = true;
            else
                CL.cls.forcetrack = CL.cls.forcetrack * 10 + c - 48;
            i++;
        }
        if (neg)
            CL.cls.forcetrack = -CL.cls.forcetrack;
        CL.cls.demoofs = i + 1;
    }

    static function FinishTimeDemo() {
        CL.cls.timedemo = false;
        var frames = Host.framecount - CL.cls.td_startframe - 1;
        var time = Host.realtime - CL.cls.td_starttime;
        if (time == 0.0)
            time = 1.0;
        Console.Print(frames + ' frames ' + time.toFixed(1) + ' seconds ' + (frames / time).toFixed(1) + ' fps\n');
    }

    static function TimeDemo_f() {
        if (Cmd.client)
            return;
        if (Cmd.argv.length != 2) {
            Console.Print('timedemo <demoname> : gets demo speeds\n');
            return;
        }
        CL.PlayDemo_f();
        CL.cls.timedemo = true;
        CL.cls.td_startframe = Host.framecount;
        CL.cls.td_lastframe = -1;
    }

    // input

    public static var kbutton(default,null) = {
        mlook: 0,
        klook: 1,
        left: 2,
        right: 3,
        forward: 4,
        back: 5,
        lookup: 6,
        lookdown: 7,
        moveleft: 8,
        moveright: 9,
        strafe: 10,
        speed: 11,
        use: 12,
        jump: 13,
        attack: 14,
        moveup: 15,
        movedown: 16,
        num: 17
    }
    public static var kbuttons(default,null):Array<{down:Array<Int>, state:Int}> = [];

    static function KeyDown() {
        var b:Int = Reflect.field(CL.kbutton, Cmd.argv[0].substring(1));
        if (b == null)
            return;
        var b = CL.kbuttons[b];

        var k;
        if (Cmd.argv[1] != null)
            k = Q.atoi(Cmd.argv[1]);
        else
            k = -1;

        if ((k == b.down[0]) || (k == b.down[1]))
            return;

        if (b.down[0] == 0)
            b.down[0] = k;
        else if (b.down[1] == 0)
            b.down[1] = k;
        else
        {
            Console.Print('Three keys down for a button!\n');
            return;
        }

        if ((b.state & 1) == 0)
            b.state |= 3;
    }

    static function KeyUp() {
        var b:Int = Reflect.field(CL.kbutton, Cmd.argv[0].substring(1));
        if (b == null)
            return;
        var b = CL.kbuttons[b];

        var k;
        if (Cmd.argv[1] != null)
            k = Q.atoi(Cmd.argv[1]);
        else
        {
            b.down[0] = b.down[1] = 0;
            b.state = 4;
            return;
        }

        if (b.down[0] == k)
            b.down[0] = 0;
        else if (b.down[1] == k)
            b.down[1] = 0;
        else
            return;
        if ((b.down[0] != 0) || (b.down[1] != 0))
            return;

        if ((b.state & 1) != 0)
            b.state = (b.state - 1) | 4;
    }

    static function MLookUp() {
        CL.KeyUp();
        if (((CL.kbuttons[CL.kbutton.mlook].state & 1) == 0) && (CL.lookspring.value != 0))
            V.StartPitchDrift();
    }

    static var impulse:Int;

    static function Impulse() {
        CL.impulse = Q.atoi(Cmd.argv[1]);
    }

    static function KeyState(key:Int) {
        var key = CL.kbuttons[key];
        var down = key.state & 1;
        key.state &= 1;
        if ((key.state & 2) != 0) {
            if ((key.state & 4) != 0)
                return (down != 0) ? 0.75 : 0.25;
            return (down != 0) ? 0.5 : 0.0;
        }
        if ((key.state & 4) != 0)
            return 0.0;
        return (down != 0) ? 1.0 : 0.0;
    }

    static function AdjustAngles() {
        var speed = Host.frametime;
        if ((CL.kbuttons[CL.kbutton.speed].state & 1) != 0)
            speed *= CL.anglespeedkey.value;

        var angles = CL.state.viewangles;

        if ((CL.kbuttons[CL.kbutton.strafe].state & 1) == 0) {
            angles[1] += speed * CL.yawspeed.value * (CL.KeyState(CL.kbutton.left) - CL.KeyState(CL.kbutton.right));
            angles[1] = Vec.Anglemod(angles[1]);
        }
        if ((CL.kbuttons[CL.kbutton.klook].state & 1) != 0) {
            V.StopPitchDrift();
            angles[0] += speed * CL.pitchspeed.value * (CL.KeyState(CL.kbutton.back) - CL.KeyState(CL.kbutton.forward));
        }

        var up = CL.KeyState(CL.kbutton.lookup), down = CL.KeyState(CL.kbutton.lookdown);
        if ((up != 0.0) || (down != 0.0)) {
            angles[0] += speed * CL.pitchspeed.value * (down - up);
            V.StopPitchDrift();
        }

        if (angles[0] > 80.0)
            angles[0] = 80.0;
        else if (angles[0] < -70.0)
            angles[0] = -70.0;

        if (angles[2] > 50.0)
            angles[2] = 50.0;
        else if (angles[2] < -50.0)
            angles[2] = -50.0;
    }

    static function BaseMove() {
        if (CL.cls.signon != 4)
            return;

        CL.AdjustAngles();

        var cmd = CL.state.cmd;

        cmd.sidemove = CL.sidespeed.value * (CL.KeyState(CL.kbutton.moveright) - CL.KeyState(CL.kbutton.moveleft));
        if ((CL.kbuttons[CL.kbutton.strafe].state & 1) != 0)
            cmd.sidemove += CL.sidespeed.value * (CL.KeyState(CL.kbutton.right) - CL.KeyState(CL.kbutton.left));

        cmd.upmove = CL.upspeed.value * (CL.KeyState(CL.kbutton.moveup) - CL.KeyState(CL.kbutton.movedown));

        if ((CL.kbuttons[CL.kbutton.klook].state & 1) == 0)
            cmd.forwardmove = CL.forwardspeed.value * CL.KeyState(CL.kbutton.forward) - CL.backspeed.value * CL.KeyState(CL.kbutton.back);
        else
            cmd.forwardmove = 0.0;

        if ((CL.kbuttons[CL.kbutton.speed].state & 1) != 0) {
            cmd.forwardmove *= CL.movespeedkey.value;
            cmd.sidemove *= CL.movespeedkey.value;
            cmd.upmove *= CL.movespeedkey.value;
        }
    }

    static var sendmovebuf = new MSG(16);
    static function SendMove() {
        var buf = CL.sendmovebuf;
        buf.cursize = 0;
        buf.WriteByte(CLC.move);
        buf.WriteFloat(CL.state.mtime0);
        buf.WriteAngle(CL.state.viewangles[0]);
        buf.WriteAngle(CL.state.viewangles[1]);
        buf.WriteAngle(CL.state.viewangles[2]);
        buf.WriteShort(Std.int(CL.state.cmd.forwardmove));
        buf.WriteShort(Std.int(CL.state.cmd.sidemove));
        buf.WriteShort(Std.int(CL.state.cmd.upmove));
        var bits = 0;
        if ((CL.kbuttons[CL.kbutton.attack].state & 3) != 0)
            bits += 1;
        CL.kbuttons[CL.kbutton.attack].state &= 5;
        if ((CL.kbuttons[CL.kbutton.jump].state & 3) != 0)
            bits += 2;
        CL.kbuttons[CL.kbutton.jump].state &= 5;
        buf.WriteByte(bits);
        buf.WriteByte(CL.impulse);
        CL.impulse = 0;
        if (CL.cls.demoplayback)
            return;
        if (++CL.state.movemessages <= 2)
            return;
        if (NET.SendUnreliableMessage(CL.cls.netcon, buf) == -1) {
            Console.Print('CL.SendMove: lost server connection\n');
            CL.Disconnect();
        }
    }

    static function InitInput() {
        var commands = ['moveup', 'movedown', 'left', 'right',
            'forward', 'back', 'lookup', 'lookdown',
            'strafe', 'moveleft', 'moveright', 'speed',
            'attack', 'use', 'jump', 'klook'
        ];
        for (cmd in commands) {
            Cmd.AddCommand('+' + cmd, CL.KeyDown);
            Cmd.AddCommand('-' + cmd, CL.KeyUp);
        }
        Cmd.AddCommand('impulse', CL.Impulse);
        Cmd.AddCommand('+mlook', CL.KeyDown);
        Cmd.AddCommand('-mlook', CL.MLookUp);

        for (i in 0...CL.kbutton.num)
            CL.kbuttons[i] = {down: [0, 0], state: 0};
    }

    // main

    public static var cls(default,never) = new ClientStatic();
    public static var state(default,null):ClientState;
    public static var static_entities(default,null):Array<Entity> = [];
    public static var visedicts(default,never):Array<Entity> = [];

    static function Rcon_f() {
        if (CL.rcon_password.string.length == 0) {
            Console.Print('You must set \'rcon_password\' before\nissuing an rcon command.\n');
            return;
        }
        var to = null;
        if ((CL.cls.state == connected) && (CL.cls.netcon != null)) {
            if (NET.drivers[CL.cls.netcon.driver] == NET_WEBS)
                to = CL.cls.netcon.address.substring(5);
        }
        if (to == null) {
            if (CL.rcon_address.string.length == 0) {
                Console.Print('You must either be connected,\nor set the \'rcon_address\' cvar\nto issue rcon commands\n');
                return;
            }
            to = CL.rcon_address.string;
        }
        var pw;
        try
        {
            pw = Q.btoa(new Uint8Array(Q.strmem('quake:' + CL.rcon_password.string)));
        }
        catch (e:Any) {
            return;
        }
        var message = '', i;
        for (i in 1...Cmd.argv.length)
            message += Cmd.argv[i] + ' ';
        try
        {
            message = StringTools.urlEncode(message);
        }
        catch (e:Any) {
            return;
        }
        var xhr = new XMLHttpRequest();
        xhr.open('HEAD', 'http://' + to + '/rcon/' + message);
        xhr.setRequestHeader('Authorization', 'Basic ' + pw);
        xhr.send();
    }

    public static var entities(default,null):Array<Entity>;

    public static inline var MAX_DLIGHTS = 32;
    public static inline var MAX_LIGHTSTYLES = 64;
    static inline var MAX_BEAMS = 24;

    public static var dlights(default,null):Array<DLight>;
    public static var lightstyle(default,null):Array<String>;
    static var beams:Array<Beam>;

    static function ClearState() {
        if (!SV.server.active) {
            Console.DPrint('Clearing memory\n');
            Mod.ClearAll();
            cls.signon = 0;
        }

        state = new ClientState();
        static_entities = [];
        cls.message.cursize = 0;

        entities = [];

        dlights = [];
        for (i in 0...MAX_DLIGHTS)
            dlights.push(new DLight());

        lightstyle = [];
        for (i in 0...MAX_LIGHTSTYLES)
            lightstyle.push("");

        beams = [];
        for (i in 0...MAX_BEAMS)
            beams.push(new Beam());
    }

    public static function Disconnect() {
        S.StopAllSounds();
        if (CL.cls.demoplayback)
            CL.StopPlayback();
        else if (CL.cls.state == connected) {
            if (CL.cls.demorecording)
                CL.Stop_f();
            Console.DPrint('Sending clc_disconnect\n');
            CL.cls.message.cursize = 0;
            CL.cls.message.WriteByte(CLC.disconnect);
            NET.SendUnreliableMessage(CL.cls.netcon, CL.cls.message);
            CL.cls.message.cursize = 0;
            NET.Close(CL.cls.netcon);
            CL.cls.state = disconnected;
            if (SV.server.active)
                Host.ShutdownServer(false);
        }
        CL.cls.demoplayback = CL.cls.timedemo = false;
        CL.cls.signon = 0;
    }

    static var host:String;

    public static function Connect(sock:INETSocket):Void {
        CL.cls.netcon = sock;
        Console.DPrint('CL.Connect: connected to ' + CL.host + '\n');
        CL.cls.demonum = -1;
        CL.cls.state = connected;
        CL.cls.signon = 0;
    }

    public static function EstablishConnection(host:String):Void {
        if (CL.cls.demoplayback)
            return;
        CL.Disconnect();
        CL.host = host;
        var sock = NET.Connect(host);
        if (sock == null)
            Host.Error('CL.EstablishConnection: connect failed\n');
        CL.Connect(sock);
    }

    static function SignonReply() {
        Console.DPrint('CL.SignonReply: ' + CL.cls.signon + '\n');
        switch (CL.cls.signon) {
            case 1:
                CL.cls.message.WriteByte(CLC.stringcmd);
                CL.cls.message.WriteString('prespawn');
            case 2:
                CL.cls.message.WriteByte(CLC.stringcmd);
                CL.cls.message.WriteString('name "' + CL.name.string + '"\n');
                CL.cls.message.WriteByte(CLC.stringcmd);
                var col = Std.int(CL.color.value);
                CL.cls.message.WriteString('color ' + (col >> 4) + ' ' + (col & 15) + '\n');
                CL.cls.message.WriteByte(CLC.stringcmd);
                CL.cls.message.WriteString('spawn ' + CL.cls.spawnparms);
            case 3:
                CL.cls.message.WriteByte(CLC.stringcmd);
                CL.cls.message.WriteString('begin');
            case 4:
                SCR.EndLoadingPlaque();
        }
    }

    public static function NextDemo():Void {
        if (CL.cls.demonum == -1)
            return;
        SCR.BeginLoadingPlaque();
        if (CL.cls.demonum >= CL.cls.demos.length) {
            if (CL.cls.demos.length == 0) {
                Console.Print('No demos listed with startdemos\n');
                CL.cls.demonum = -1;
                return;
            }
            CL.cls.demonum = 0;
        }
        Cmd.text = 'playdemo ' + CL.cls.demos[CL.cls.demonum++] + '\n' + Cmd.text;
    }

    static function PrintEntities_f() {
        for (i in 0...CL.entities.length) {
            var ent = CL.entities[i];
            if (i <= 9)
                Console.Print('  ' + i + ':');
            else if (i <= 99)
                Console.Print(' ' + i + ':');
            else
                Console.Print(i + ':');
            if (ent.model == null) {
                Console.Print('EMPTY\n');
                continue;
            }
            Console.Print(ent.model.name + (ent.frame <= 9 ? ': ' : ':') + ent.frame +
                '  (' + ent.origin[0].toFixed(1) + ',' + ent.origin[1].toFixed(1) + ',' + ent.origin[2].toFixed(1) +
                ') [' + ent.angles[0].toFixed(1) + ' ' + ent.angles[1].toFixed(1) + ' ' + ent.angles[2].toFixed(1) + ']\n');
        }
    }

    static function AllocDlight(key:Int) {
        var dl = null;
        if (key != 0) {
            for (light in dlights) {
                if (light.key == key) {
                    dl = light;
                    break;
                }
            }
        }
        if (dl == null) {
            for (light in dlights) {
                if (light.die < state.time) {
                    dl = light;
                    break;
                }
            }
            if (dl == null)
                dl = dlights[0];
        }
        dl.alloc(key);
        return dl;
    }

    public static function DecayLights():Void {
        var time = state.time - state.oldtime;
        for (dl in dlights) {
            if (dl.die < state.time || dl.radius == 0.0)
                continue;
            dl.radius -= time * dl.decay;
            if (dl.radius < 0.0)
                dl.radius = 0.0;
        }
    }

    static function LerpPoint() {
        var f = CL.state.mtime0 - CL.state.mtime1;
        if ((f == 0.0) || (CL.nolerp.value != 0) || (CL.cls.timedemo) || (SV.server.active)) {
            CL.state.time = CL.state.mtime0;
            return 1.0;
        }
        if (f > 0.1) {
            CL.state.mtime1 = CL.state.mtime0 - 0.1;
            f = 0.1;
        }
        var frac = (CL.state.time - CL.state.mtime1) / f;
        if (frac < 0.0) {
            if (frac < -0.01)
                CL.state.time = CL.state.mtime1;
            return 0.0;
        }
        if (frac > 1.0) {
            if (frac > 1.01)
                CL.state.time = CL.state.mtime0;
            return 1.0;
        }
        return frac;
    }

    public static var numvisedicts(default,null):Int;

    static function RelinkEntities() {
        var frac = CL.LerpPoint();

        CL.numvisedicts = 0;

        CL.state.velocity[0] = CL.state.mvelocity1[0] + frac * (CL.state.mvelocity0[0] - CL.state.mvelocity1[0]);
        CL.state.velocity[1] = CL.state.mvelocity1[1] + frac * (CL.state.mvelocity0[1] - CL.state.mvelocity1[1]);
        CL.state.velocity[2] = CL.state.mvelocity1[2] + frac * (CL.state.mvelocity0[2] - CL.state.mvelocity1[2]);

        if (CL.cls.demoplayback) {
            for (i in 0...3) {
                var d = CL.state.mviewangles0[i] - CL.state.mviewangles1[i];
                if (d > 180.0)
                    d -= 360.0;
                else if (d < -180.0)
                    d += 360.0;
                CL.state.viewangles[i] = CL.state.mviewangles1[i] + frac * d;
            }
        }

        var bobjrotate = Vec.Anglemod(100.0 * CL.state.time);
        var delta = [];
        var oldorg = new Vec();
        var dl;
        for (i in 1...CL.entities.length) {
            var ent = CL.entities[i];
            if (ent.model == null)
                continue;
            if (ent.msgtime != CL.state.mtime0) {
                ent.model = null;
                continue;
            }
            oldorg[0] = ent.origin[0];
            oldorg[1] = ent.origin[1];
            oldorg[2] = ent.origin[2];
            if (ent.forcelink) {
                ent.origin.setVector(ent.msg_origins0);
                ent.angles.setVector(ent.msg_angles0);
            }
            else
            {
                var f = frac;
                for (j in 0...3) {
                    delta[j] = ent.msg_origins0[j] - ent.msg_origins1[j];
                    if ((delta[j] > 100.0) || (delta[j] < -100.0))
                        f = 1.0;
                }
                for (j in 0...3) {
                    ent.origin[j] = ent.msg_origins1[j] + f * delta[j];
                    var d = ent.msg_angles0[j] - ent.msg_angles1[j];
                    if (d > 180.0)
                        d -= 360.0;
                    else if (d < -180.0)
                        d += 360.0;
                    ent.angles[j] = ent.msg_angles1[j] + f * d;
                }
            }

            if ((ent.model.flags & ModelEffect.rotate) != 0)
                ent.angles[1] = bobjrotate;
            if ((ent.effects & EF_BRIGHTFIELD) != 0)
                Render.EntityParticles(ent);
            if ((ent.effects & EF_MUZZLEFLASH) != 0) {
                dl = CL.AllocDlight(i);
                var fv = new Vec();
                Vec.AngleVectors(ent.angles, fv);
                dl.origin.setValues(
                    ent.origin[0] + 18.0 * fv[0],
                    ent.origin[1] + 18.0 * fv[1],
                    ent.origin[2] + 16.0 + 18.0 * fv[2]
                );
                dl.radius = 200.0 + Math.random() * 32.0;
                dl.minlight = 32.0;
                dl.die = CL.state.time + 0.1;
            }
            if ((ent.effects & EF_BRIGHTLIGHT) != 0) {
                dl = CL.AllocDlight(i);
                dl.origin.setValues(ent.origin[0], ent.origin[1], ent.origin[2] + 16.0);
                dl.radius = 400.0 + Math.random() * 32.0;
                dl.die = CL.state.time + 0.001;
            }
            if ((ent.effects & EF_DIMLIGHT) != 0) {
                dl = CL.AllocDlight(i);
                dl.origin.setValues(ent.origin[0], ent.origin[1], ent.origin[2] + 16.0);
                dl.radius = 200.0 + Math.random() * 32.0;
                dl.die = CL.state.time + 0.001;
            }
            if ((ent.model.flags & ModelEffect.gib) != 0)
                Render.RocketTrail(oldorg, ent.origin, 2);
            else if ((ent.model.flags & ModelEffect.zomgib) != 0)
                Render.RocketTrail(oldorg, ent.origin, 4);
            else if ((ent.model.flags & ModelEffect.tracer) != 0)
                Render.RocketTrail(oldorg, ent.origin, 3);
            else if ((ent.model.flags & ModelEffect.tracer2) != 0)
                Render.RocketTrail(oldorg, ent.origin, 5);
            else if ((ent.model.flags & ModelEffect.rocket) != 0) {
                Render.RocketTrail(oldorg, ent.origin, 0);
                dl = CL.AllocDlight(i);
                dl.origin.setVector(ent.origin);
                dl.radius = 200.0;
                dl.die = CL.state.time + 0.01;
            }
            else if ((ent.model.flags & ModelEffect.grenade) != 0)
                Render.RocketTrail(oldorg, ent.origin, 1);
            else if ((ent.model.flags & ModelEffect.tracer3) != 0)
                Render.RocketTrail(oldorg, ent.origin, 6);

            ent.forcelink = false;
            if ((i != CL.state.viewentity) || (Chase.active.value != 0))
                CL.visedicts[CL.numvisedicts++] = ent;
        }
    }

    public static function ReadFromServer():Void {
        CL.state.oldtime = CL.state.time;
        CL.state.time += Host.frametime;
        while(true) {
            var ret = CL.GetMessage();
            if (ret == -1)
                Host.Error('CL.ReadFromServer: lost server connection');
            if (ret == 0)
                break;
            CL.state.last_received_message = Host.realtime;
            CL.ParseServerMessage();
            if (CL.cls.state != connected)
                break;
        }
        if (CL.shownet.value != 0)
            Console.Print('\n');
        CL.RelinkEntities();
        CL.UpdateTEnts();
    }

    public static function SendCmd():Void {
        if (CL.cls.state != connected)
            return;

        if (CL.cls.signon == 4) {
            CL.BaseMove();
            IN.Move();
            CL.SendMove();
        }

        if (CL.cls.demoplayback) {
            CL.cls.message.cursize = 0;
            return;
        }

        if (CL.cls.message.cursize == 0)
            return;

        if (!NET.CanSendMessage(CL.cls.netcon)) {
            Console.DPrint('CL.SendCmd: can\'t send\n');
            return;
        }

        if (NET.SendMessage(CL.cls.netcon, CL.cls.message) == -1)
            Host.Error('CL.SendCmd: lost server connection');

        CL.cls.message.cursize = 0;
    }

    public static function Init():Void {
        ClearState();
        InitInput();
        InitTEnts();
        name = Cvar.RegisterVariable('_cl_name', 'player', true);
        color = Cvar.RegisterVariable('_cl_color', '0', true);
        upspeed = Cvar.RegisterVariable('cl_upspeed', '200');
        forwardspeed = Cvar.RegisterVariable('cl_forwardspeed', '200', true);
        backspeed = Cvar.RegisterVariable('cl_backspeed', '200', true);
        sidespeed = Cvar.RegisterVariable('cl_sidespeed', '350');
        movespeedkey = Cvar.RegisterVariable('cl_movespeedkey', '2.0');
        yawspeed = Cvar.RegisterVariable('cl_yawspeed', '140');
        pitchspeed = Cvar.RegisterVariable('cl_pitchspeed', '150');
        anglespeedkey = Cvar.RegisterVariable('cl_anglespeedkey', '1.5');
        shownet = Cvar.RegisterVariable('cl_shownet', '0');
        nolerp = Cvar.RegisterVariable('cl_nolerp', '0');
        lookspring = Cvar.RegisterVariable('lookspring', '0', true);
        lookstrafe = Cvar.RegisterVariable('lookstrafe', '0', true);
        sensitivity = Cvar.RegisterVariable('sensitivity', '3', true);
        m_pitch = Cvar.RegisterVariable('m_pitch', '0.022', true);
        m_yaw = Cvar.RegisterVariable('m_yaw', '0.022', true);
        m_forward = Cvar.RegisterVariable('m_forward', '1', true);
        m_side = Cvar.RegisterVariable('m_side', '0.8', true);
        rcon_password = Cvar.RegisterVariable('rcon_password', '');
        rcon_address = Cvar.RegisterVariable('rcon_address', '');
        Cmd.AddCommand('entities', PrintEntities_f);
        Cmd.AddCommand('disconnect', Disconnect);
        Cmd.AddCommand('record', Record_f);
        Cmd.AddCommand('stop', Stop_f);
        Cmd.AddCommand('playdemo', PlayDemo_f);
        Cmd.AddCommand('timedemo', TimeDemo_f);
        Cmd.AddCommand('rcon', Rcon_f);
    }

    // parse

    static var svc_strings = [
        'bad',
        'nop',
        'disconnect',
        'updatestat',
        'version',
        'setview',
        'sound',
        'time',
        'print',
        'stufftext',
        'setangle',
        'serverinfo',
        'lightstyle',
        'updatename',
        'updatefrags',
        'clientdata',
        'stopsound',
        'updatecolors',
        'particle',
        'damage',
        'spawnstatic',
        'OBSOLETE spawnbinary',
        'spawnbaseline',
        'temp_entity',
        'setpause',
        'signonnum',
        'centerprint',
        'killedmonster',
        'foundsecret',
        'spawnstaticsound',
        'intermission',
        'finale',
        'cdtrack',
        'sellscreen',
        'cutscene'
    ];

    static function EntityNum(num:Int):Entity {
        if (num < CL.entities.length)
            return CL.entities[num];
        while (CL.entities.length <= num) {
            CL.entities.push(new Entity(num));
        }
        return CL.entities[num];
    }

    static function ParseStartSoundPacket() {
        var field_mask = MSG.ReadByte();
        var volume = ((field_mask & 1) != 0) ? MSG.ReadByte() : 255;
        var attenuation = ((field_mask & 2) != 0) ? MSG.ReadByte() * 0.015625 : 1.0;
        var channel = MSG.ReadShort();
        var sound_num = MSG.ReadByte();
        var ent = channel >> 3;
        channel &= 7;
        var pos = MSG.ReadVector();
        S.StartSound(ent, channel, CL.state.sound_precache[sound_num], pos, volume / 255.0, attenuation);
    }

    static var lastmsg = 0.0;
    static function KeepaliveMessage() {
        if ((SV.server.active) || (CL.cls.demoplayback))
            return;
        var oldsize = NET.message.cursize;
        var olddata = new Uint8Array(8192);
        olddata.set(new Uint8Array(NET.message.data, 0, oldsize));
        while (true) {
            var ret = CL.GetMessage();
            switch (ret) {
            case 0:
            case 1:
                Host.Error('CL.KeepaliveMessage: received a message');
            case 2:
                if (MSG.ReadByte() != SVC.nop)
                    Host.Error('CL.KeepaliveMessage: datagram wasn\'t a nop');
            default:
                Host.Error('CL.KeepaliveMessage: CL.GetMessage failed');
            }
            if (ret == 0)
                break;
        }
        NET.message.cursize = oldsize;
        (new Uint8Array(NET.message.data, 0, oldsize)).set(olddata.subarray(0, oldsize));
        var time = Sys.FloatTime();
        if ((time - CL.lastmsg) < 5.0)
            return;
        CL.lastmsg = time;
        Console.Print('--> client to server keepalive\n');
        CL.cls.message.WriteByte(CLC.nop);
        NET.SendMessage(CL.cls.netcon, CL.cls.message);
        CL.cls.message.cursize = 0;
    }

    static function ParseServerInfo() {
        Console.DPrint('Serverinfo packet received.\n');
        CL.ClearState();
        var i = MSG.ReadLong();
        if (i != Protocol.version) {
            Console.Print('Server returned version ' + i + ', not ' + Protocol.version + '\n');
            return;
        }
        CL.state.maxclients = MSG.ReadByte();
        if ((CL.state.maxclients <= 0) || (CL.state.maxclients > 16)) {
            Console.Print('Bad maxclients (' + CL.state.maxclients + ') from server\n');
            return;
        }
        CL.state.scores = [];
        for (i in 0...CL.state.maxclients) {
            CL.state.scores[i] = new Score();
        }
        CL.state.gametype = MSG.ReadByte();
        CL.state.levelname = MSG.ReadString();
        Console.Print('\n\n\x1d\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1e\x1f\n\n');
        Console.Print(String.fromCharCode(2) + CL.state.levelname + '\n');

        var str;
        var nummodels = 1, model_precache = [];
        while(true) {
            str = MSG.ReadString();
            if (str.length == 0)
                break;
            model_precache[nummodels++] = str;
        }
        var numsounds = 1, sound_precache = [];
        while (true) {
            str = MSG.ReadString();
            if (str.length == 0)
                break;
            sound_precache[numsounds++] = str;
        }

        CL.state.model_precache = [];
        for (i in 1...nummodels) {
            CL.state.model_precache[i] = Mod.ForName(model_precache[i], false);
            if (CL.state.model_precache[i] == null) {
                Console.Print('Model ' + model_precache[i] + ' not found\n');
                return;
            }
            CL.KeepaliveMessage();
        }
        CL.state.sound_precache = [];
        for (i in 1...numsounds) {
            CL.state.sound_precache[i] = S.PrecacheSound(sound_precache[i]);
            CL.KeepaliveMessage();
        }

        CL.state.worldmodel = CL.state.model_precache[1];
        CL.EntityNum(0).model = CL.state.worldmodel;
        Render.NewMap();
        Host.noclip_anglehack = false;
    }

    static function ParseUpdate(bits) {
        if (CL.cls.signon == 3) {
            CL.cls.signon = 4;
            CL.SignonReply();
        }

        if ((bits & U.morebits) != 0)
            bits += (MSG.ReadByte() << 8);

        var ent = CL.EntityNum(((bits & U.longentity) != 0) ? MSG.ReadShort() : MSG.ReadByte());

        var forcelink = ent.msgtime != CL.state.mtime1;
        ent.msgtime = CL.state.mtime0;

        var model = CL.state.model_precache[((bits & U.model) != 0) ? MSG.ReadByte() : ent.baseline.modelindex];
        if (model != ent.model) {
            ent.model = model;
            if (model != null)
                ent.syncbase = (model.random) ? Math.random() : 0.0;
            else
                forcelink = true;
        }

        ent.frame = ((bits & U.frame) != 0) ? MSG.ReadByte() : ent.baseline.frame;
        ent.colormap = ((bits & U.colormap) != 0) ? MSG.ReadByte() : ent.baseline.colormap;
        if (ent.colormap > CL.state.maxclients)
            Sys.Error('i >= cl.maxclients');
        ent.skinnum = ((bits & U.skin) != 0) ? MSG.ReadByte() : ent.baseline.skin;
        ent.effects = ((bits & U.effects) != 0) ? cast MSG.ReadByte() : ent.baseline.effects;

        ent.msg_origins1.setVector(ent.msg_origins0);
        ent.msg_angles1.setVector(ent.msg_angles0);
        ent.msg_origins0[0] = ((bits & U.origin1) != 0) ? MSG.ReadCoord() : ent.baseline.origin[0];
        ent.msg_angles0[0] = ((bits & U.angle1) != 0) ? MSG.ReadAngle() : ent.baseline.angles[0];
        ent.msg_origins0[1] = ((bits & U.origin2) != 0) ? MSG.ReadCoord() : ent.baseline.origin[1];
        ent.msg_angles0[1] = ((bits & U.angle2) != 0) ? MSG.ReadAngle() : ent.baseline.angles[1];
        ent.msg_origins0[2] = ((bits & U.origin3) != 0) ? MSG.ReadCoord() : ent.baseline.origin[2];
        ent.msg_angles0[2] = ((bits & U.angle3) != 0) ? MSG.ReadAngle() : ent.baseline.angles[2];

        if ((bits & U.nolerp) != 0)
            ent.forcelink = true;

        if (forcelink) {
            ent.origin.setVector(ent.msg_origins0);
            ent.msg_origins1.setVector(ent.origin);
            ent.angles.setVector(ent.msg_angles0);
            ent.msg_angles1.setVector(ent.angles);
            ent.forcelink = true;
        }
    }

    static function ParseBaseline(ent:Entity):Void {
        ent.baseline.modelindex = MSG.ReadByte();
        ent.baseline.frame = MSG.ReadByte();
        ent.baseline.colormap = MSG.ReadByte();
        ent.baseline.skin = MSG.ReadByte();
        ent.baseline.origin[0] = MSG.ReadCoord();
        ent.baseline.angles[0] = MSG.ReadAngle();
        ent.baseline.origin[1] = MSG.ReadCoord();
        ent.baseline.angles[1] = MSG.ReadAngle();
        ent.baseline.origin[2] = MSG.ReadCoord();
        ent.baseline.angles[2] = MSG.ReadAngle();
    }

    static function ParseClientdata(bits) {
        CL.state.viewheight = ((bits & SU.viewheight) != 0) ? MSG.ReadChar() : Protocol.default_viewheight;
        CL.state.idealpitch = ((bits & SU.idealpitch) != 0) ? MSG.ReadChar() : 0.0;

        CL.state.mvelocity1.setVector(CL.state.mvelocity0);
        for (i in 0...3) {
            if ((bits & (SU.punch1 << i)) != 0)
                CL.state.punchangle[i] = MSG.ReadChar();
            else
                CL.state.punchangle[i] = 0.0;
            if ((bits & (SU.velocity1 << i)) != 0)
                CL.state.mvelocity0[i] = MSG.ReadChar() * 16.0;
            else
                CL.state.mvelocity0[i] = 0.0;
        }

        var i = MSG.ReadLong();
        if (CL.state.items != i) {
            for (j in 0...32) {
                if ((((i >>> j) & 1) != 0) && (((CL.state.items >>> j) & 1) == 0))
                    CL.state.item_gettime[j] = CL.state.time;
            }
            CL.state.items = i;
        }

        CL.state.onground = (bits & SU.onground) != 0;
        CL.state.inwater = (bits & SU.inwater) != 0;

        CL.state.stats[ClientStat.weaponframe] = ((bits & SU.weaponframe) != 0) ? MSG.ReadByte() : 0;
        CL.state.stats[ClientStat.armor] = ((bits & SU.armor) != 0) ? MSG.ReadByte() : 0;
        CL.state.stats[ClientStat.weapon] = ((bits & SU.weapon) != 0) ? MSG.ReadByte() : 0;
        CL.state.stats[ClientStat.health] = MSG.ReadShort();
        CL.state.stats[ClientStat.ammo] = MSG.ReadByte();
        CL.state.stats[ClientStat.shells] = MSG.ReadByte();
        CL.state.stats[ClientStat.nails] = MSG.ReadByte();
        CL.state.stats[ClientStat.rockets] = MSG.ReadByte();
        CL.state.stats[ClientStat.cells] = MSG.ReadByte();
        if (COM.standard_quake)
            CL.state.stats[ClientStat.activeweapon] = MSG.ReadByte();
        else
            CL.state.stats[ClientStat.activeweapon] = 1 << MSG.ReadByte();
    }

    static function ParseStatic() {
        var ent = new Entity();
        CL.static_entities.push(ent);
        CL.ParseBaseline(ent);
        ent.model = CL.state.model_precache[ent.baseline.modelindex];
        ent.frame = ent.baseline.frame;
        ent.skinnum = ent.baseline.skin;
        ent.effects = ent.baseline.effects;
        ent.origin.setVector(ent.baseline.origin);
        ent.angles.setVector(ent.baseline.angles);
        Render.currententity = ent;
        Render.SplitEntityOnNode(Vec.Add(ent.origin, ent.model.mins), Vec.Add(ent.origin, ent.model.maxs), CL.state.worldmodel.nodes[0]);
    }

    static function ParseStaticSound() {
        var org = MSG.ReadVector();
        var sound_num = MSG.ReadByte();
        var vol = MSG.ReadByte();
        var atten = MSG.ReadByte();
        S.StaticSound(CL.state.sound_precache[sound_num], org, vol / 255.0, atten);
    }

    static function Shownet(x) {
        if (CL.shownet.value == 2) {
            Console.Print((MSG.readcount <= 99 ? (MSG.readcount <= 9 ? '  ' : ' ') : '')
                + (MSG.readcount - 1) + ':' + x + '\n');
        }
    }

    static function ParseServerMessage() {
        if (CL.shownet.value == 1)
            Console.Print(NET.message.cursize + ' ');
        else if (CL.shownet.value == 2)
            Console.Print('------------------\n');

        CL.state.onground = false;

        MSG.BeginReading();

        while(true) {
            if (MSG.badread)
                Host.Error('CL.ParseServerMessage: Bad server message');

            var cmd = MSG.ReadByte();

            if (cmd == -1) {
                CL.Shownet('END OF MESSAGE');
                return;
            }

            if ((cmd & 128) != 0) {
                CL.Shownet('fast update');
                CL.ParseUpdate(cmd & 127);
                continue;
            }

            CL.Shownet('svc_' + CL.svc_strings[cmd]);
            switch (cast cmd : Protocol.SVC) {
            case SVC.nop:
                continue;
            case SVC.time:
                CL.state.mtime1 = CL.state.mtime0;
                CL.state.mtime0 = MSG.ReadFloat();
                continue;
            case SVC.clientdata:
                CL.ParseClientdata(MSG.ReadShort());
                continue;
            case SVC.version:
                var i = MSG.ReadLong();
                if (i != Protocol.version)
                    Host.Error('CL.ParseServerMessage: Server is protocol ' + i + ' instead of ' + Protocol.version + '\n');
                continue;
            case SVC.disconnect:
                Host.EndGame('Server disconnected\n');
            case SVC.print:
                Console.Print(MSG.ReadString());
                continue;
            case SVC.centerprint:
                SCR.CenterPrint(MSG.ReadString());
                continue;
            case SVC.stufftext:
                Cmd.text += MSG.ReadString();
                continue;
            case SVC.damage:
                V.ParseDamage();
                continue;
            case SVC.serverinfo:
                CL.ParseServerInfo();
                SCR.recalc_refdef = true;
                continue;
            case SVC.setangle:
                CL.state.viewangles[0] = MSG.ReadAngle();
                CL.state.viewangles[1] = MSG.ReadAngle();
                CL.state.viewangles[2] = MSG.ReadAngle();
                continue;
            case SVC.setview:
                CL.state.viewentity = MSG.ReadShort();
                continue;
            case SVC.lightstyle:
                var i = MSG.ReadByte();
                if (i >= MAX_LIGHTSTYLES)
                    Sys.Error('svc_lightstyle > MAX_LIGHTSTYLES');
                CL.lightstyle[i] = MSG.ReadString();
                continue;
            case SVC.sound:
                CL.ParseStartSoundPacket();
                continue;
            case SVC.stopsound:
                var i = MSG.ReadShort();
                S.StopSound(i >> 3, i & 7);
                continue;
            case SVC.updatename:
                var i = MSG.ReadByte();
                if (i >= CL.state.maxclients)
                    Host.Error('CL.ParseServerMessage: svc_updatename > MAX_SCOREBOARD');
                CL.state.scores[i].name = MSG.ReadString();
                continue;
            case SVC.updatefrags:
                var i = MSG.ReadByte();
                if (i >= CL.state.maxclients)
                    Host.Error('CL.ParseServerMessage: svc_updatefrags > MAX_SCOREBOARD');
                CL.state.scores[i].frags = MSG.ReadShort();
                continue;
            case SVC.updatecolors:
                var i = MSG.ReadByte();
                if (i >= CL.state.maxclients)
                    Host.Error('CL.ParseServerMessage: svc_updatecolors > MAX_SCOREBOARD');
                CL.state.scores[i].colors = MSG.ReadByte();
                continue;
            case SVC.particle:
                Render.ParseParticleEffect();
                continue;
            case SVC.spawnbaseline:
                CL.ParseBaseline(CL.EntityNum(MSG.ReadShort()));
                continue;
            case SVC.spawnstatic:
                CL.ParseStatic();
                continue;
            case SVC.temp_entity:
                CL.ParseTEnt();
                continue;
            case SVC.setpause:
                CL.state.paused = MSG.ReadByte() != 0;
                if (CL.state.paused)
                    CDAudio.Pause();
                else
                    CDAudio.Resume();
                continue;
            case SVC.signonnum:
                var i = MSG.ReadByte();
                if (i <= CL.cls.signon)
                    Host.Error('Received signon ' + i + ' when at ' + CL.cls.signon);
                CL.cls.signon = i;
                CL.SignonReply();
                continue;
            case SVC.killedmonster:
                ++CL.state.stats[ClientStat.monsters];
                continue;
            case SVC.foundsecret:
                ++CL.state.stats[ClientStat.secrets];
                continue;
            case SVC.updatestat:
                var i = MSG.ReadByte();
                if (i >= 32)
                    Sys.Error('svc_updatestat: ' + i + ' is invalid');
                CL.state.stats[i] = MSG.ReadLong();
                continue;
            case SVC.spawnstaticsound:
                CL.ParseStaticSound();
                continue;
            case SVC.cdtrack:
                CL.state.cdtrack = MSG.ReadByte();
                MSG.ReadByte();
                if (((CL.cls.demoplayback) || (CL.cls.demorecording)) && (CL.cls.forcetrack != -1))
                    CDAudio.Play(CL.cls.forcetrack, true);
                else
                    CDAudio.Play(CL.state.cdtrack, true);
                continue;
            case SVC.intermission:
                CL.state.intermission = 1;
                CL.state.completed_time = CL.state.time;
                SCR.recalc_refdef = true;
                continue;
            case SVC.finale:
                CL.state.intermission = 2;
                CL.state.completed_time = CL.state.time;
                SCR.recalc_refdef = true;
                SCR.CenterPrint(MSG.ReadString());
                continue;
            case SVC.cutscene:
                CL.state.intermission = 3;
                CL.state.completed_time = CL.state.time;
                SCR.recalc_refdef = true;
                SCR.CenterPrint(MSG.ReadString());
                continue;
            case SVC.sellscreen:
                Cmd.ExecuteString('help');
                continue;
            }
            Host.Error('CL.ParseServerMessage: Illegible server message\n');
        }
    }

    // tent

    static function InitTEnts() {
        sfx_wizhit = S.PrecacheSound('wizard/hit.wav');
        sfx_knighthit = S.PrecacheSound('hknight/hit.wav');
        sfx_tink1 = S.PrecacheSound('weapons/tink1.wav');
        sfx_ric1 = S.PrecacheSound('weapons/ric1.wav');
        sfx_ric2 = S.PrecacheSound('weapons/ric2.wav');
        sfx_ric3 = S.PrecacheSound('weapons/ric3.wav');
        sfx_r_exp3 = S.PrecacheSound('weapons/r_exp3.wav');
    }

    static function ParseBeam(m:MModel):Void {
        var ent = MSG.ReadShort();

        // these arrays will be inlined by haxe so no allocation is happening
        var start = [MSG.ReadCoord(), MSG.ReadCoord(), MSG.ReadCoord()];
        var end = [MSG.ReadCoord(), MSG.ReadCoord(), MSG.ReadCoord()];

        inline function useBeam(b:Beam) {
            b.model = m;
            b.endtime = state.time + 0.2;
            b.start.setValues(start[0], start[1], start[2]);
            b.end.setValues(end[0], end[1], end[2]);
        }

        // override any beam with the same entity
        for (b in beams) {
            if (b.entity == ent) {
                useBeam(b);
                return;
            }
        }

        // find a free beam
        for (b in beams) {
            if (b.model == null || b.endtime >= state.time) {
                b.entity = ent;
                useBeam(b);
                return;
            }
        }

        Console.Print('beam list overflow!\n');
    }

    static function ParseTEnt() {
        var type:TEType = cast MSG.ReadByte();

        switch (type) {
            case lightning1:
                ParseBeam(Mod.ForName('progs/bolt.mdl', true));
                return;
            case lightning2:
                ParseBeam(Mod.ForName('progs/bolt2.mdl', true));
                return;
            case lightning3:
                ParseBeam(Mod.ForName('progs/bolt3.mdl', true));
                return;
            case beam:
                ParseBeam(Mod.ForName('progs/beam.mdl', true));
                return;
            default:
        }

        var pos = MSG.ReadVector();
        switch (type) {
            case wizspike:
                Render.RunParticleEffect(pos, Vec.origin, 20, 20);
                S.StartSound(-1, 0, CL.sfx_wizhit, pos, 1.0, 1.0);
            case knightspike:
                Render.RunParticleEffect(pos, Vec.origin, 226, 20);
                S.StartSound(-1, 0, CL.sfx_knighthit, pos, 1.0, 1.0);
            case spike:
                Render.RunParticleEffect(pos, Vec.origin, 0, 10);
            case superspike:
                Render.RunParticleEffect(pos, Vec.origin, 0, 20);
            case gunshot:
                Render.RunParticleEffect(pos, Vec.origin, 0, 20);
            case explosion:
                Render.ParticleExplosion(pos);
                var dl = CL.AllocDlight(0);
                dl.origin.setVector(pos);
                dl.radius = 350.0;
                dl.die = CL.state.time + 0.5;
                dl.decay = 300.0;
                S.StartSound(-1, 0, CL.sfx_r_exp3, pos, 1.0, 1.0);
            case tarexplosion:
                Render.BlobExplosion(pos);
                S.StartSound(-1, 0, CL.sfx_r_exp3, pos, 1.0, 1.0);
            case lavasplash:
                Render.LavaSplash(pos);
            case teleport:
                Render.TeleportSplash(pos);
            case explosion2:
                var colorStart = MSG.ReadByte();
                var colorLength = MSG.ReadByte();
                Render.ParticleExplosion2(pos, colorStart, colorLength);
                var dl = CL.AllocDlight(0);
                dl.origin.setVector(pos);
                dl.radius = 350.0;
                dl.die = CL.state.time + 0.5;
                dl.decay = 300.0;
                S.StartSound(-1, 0, CL.sfx_r_exp3, pos, 1.0, 1.0);
            default:
                Sys.Error('CL.ParseTEnt: bad type');
        }
    }

    static function NewTempEntity():Entity {
        var ent = new Entity();
        temp_entities[num_temp_entities++] = ent;
        visedicts[numvisedicts++] = ent;
        return ent;
    }

    static function UpdateTEnts():Void {
        num_temp_entities = 0;

        var dist = [0.0, 0.0, 0.0];
        var org = [0.0, 0.0, 0.0];

        for (b in beams) {
            if (b.model == null || b.endtime < state.time)
                continue;
            if (b.entity == state.viewentity)
                b.start.setVector(entities[state.viewentity].origin);
            dist[0] = b.end[0] - b.start[0];
            dist[1] = b.end[1] - b.start[1];
            dist[2] = b.end[2] - b.start[2];
            var yaw, pitch;
            if (dist[0] == 0.0 && dist[1] == 0.0) {
                yaw = 0;
                pitch = dist[2] > 0.0 ? 90 : 270;
            } else {
                yaw = Std.int(Math.atan2(dist[1], dist[0]) * 180.0 / Math.PI);
                if (yaw < 0)
                    yaw += 360;
                pitch = Std.int(Math.atan2(dist[2], Math.sqrt(dist[0] * dist[0] + dist[1] * dist[1])) * 180.0 / Math.PI);
                if (pitch < 0)
                    pitch += 360;
            }
            org[0] = b.start[0];
            org[1] = b.start[1];
            org[2] = b.start[2];
            var d = Math.sqrt(dist[0] * dist[0] + dist[1] * dist[1] + dist[2] * dist[2]);
            if (d != 0.0) {
                dist[0] /= d;
                dist[1] /= d;
                dist[2] /= d;
            }
            while (d > 0.0) {
                var ent = NewTempEntity();
                ent.origin.setValues(org[0], org[1], org[2]);
                ent.model = b.model;
                ent.angles.setValues(pitch, yaw, Math.random() * 360.0);
                org[0] += dist[0] * 30.0;
                org[1] += dist[1] * 30.0;
                org[2] += dist[2] * 30.0;
                d -= 30.0;
            }
        }
    }

    public static function RunParticles():Void {
        var frametime = state.time - state.oldtime;
        var grav = frametime * SV.gravity.value * 0.05;
        var dvel = frametime * 4.0;

        for (p in Render.particles) {
            if (p.die < state.time)
                continue;

            p.org[0] += p.vel[0] * frametime;
            p.org[1] += p.vel[1] * frametime;
            p.org[2] += p.vel[2] * frametime;

            switch (p.type) {
                case fire:
                    p.ramp += frametime * 5.0;
                    if (p.ramp >= 6.0)
                        p.die = -1.0;
                    else
                        p.color = Render.ramp3[Math.floor(p.ramp)];
                    p.vel[2] += grav;
                case explode:
                    p.ramp += frametime * 10.0;
                    if (p.ramp >= 8.0)
                        p.die = -1.0;
                    else
                        p.color = Render.ramp1[Math.floor(p.ramp)];
                    p.vel[0] += p.vel[0] * dvel;
                    p.vel[1] += p.vel[1] * dvel;
                    p.vel[2] += p.vel[2] * dvel - grav;
                case explode2:
                    p.ramp += frametime * 15.0;
                    if (p.ramp >= 8.0)
                        p.die = -1.0;
                    else
                        p.color = Render.ramp2[Math.floor(p.ramp)];
                    p.vel[0] -= p.vel[0] * frametime;
                    p.vel[1] -= p.vel[1] * frametime;
                    p.vel[2] -= p.vel[2] * frametime + grav;
                case blob:
                    p.vel[0] += p.vel[0] * dvel;
                    p.vel[1] += p.vel[1] * dvel;
                    p.vel[2] += p.vel[2] * dvel - grav;
                case blob2:
                    p.vel[0] += p.vel[0] * dvel;
                    p.vel[1] += p.vel[1] * dvel;
                    p.vel[2] -= grav;
                case grav | slowgrav:
                    p.vel[2] -= grav;
                default:
            }
        }
    }
}