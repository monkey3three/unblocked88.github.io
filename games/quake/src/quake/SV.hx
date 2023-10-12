package quake;

import js.html.Uint8Array;
import quake.Entity.EntityEffect;
import quake.CL.ClientCmd;
import quake.Host.HClient;
import quake.Mod;
import quake.Mod_Brush;
import quake.Protocol;
import quake.Edict;

@:publicFields
private class AreaNode {
    var axis:Int;
    var dist:Float;
    var children:Array<AreaNode>;
    var trigger_edicts:EdictLink;
    var solid_edicts:EdictLink;
    function new() {}
}

@:publicFields
private class MoveClip {
    var type:Int;
    var trace:Trace;
    var boxmins:Vec;
    var boxmaxs:Vec;
    var mins:Vec;
    var maxs:Vec;
    var mins2:Vec;
    var maxs2:Vec;
    var start:Vec;
    var end:Vec;
    var passedict:Edict;
    function new() {}
}

@:publicFields
class Trace {
    var allsolid:Bool = false;
    var startsolid:Bool = false;
    var inopen:Bool = false;
    var inwater:Bool = false;
    var plane(default,never):Plane = new Plane();
    var fraction:Float = 0.0;
    var endpos(default,never):Vec = new Vec();
    var ent:Edict;
    function new() {}
}


@:publicFields
private class ServerStatic {
    var maxclients:Int;
    var maxclientslimit:Int;
    var clients:Array<HClient>;
    var serverflags:Int;
    var changelevel_issued:Bool;
    function new() {}
}

@:publicFields
private class ServerState {
    var num_edicts = 0;
    var datagram = new MSG(1024);
    var reliable_datagram = new MSG(1024);
    var signon = new MSG(8192);
    var sound_precache:Array<String>;
    var model_precache:Array<String>;
    var edicts:Array<Edict>;
    var loadgame:Bool;
    var worldmodel:MModel;
    var models:Array<MModel>;
    var time:Float;
    var active:Bool;
    var loading:Bool;
    var paused:Bool;
    var lastcheck:Int;
    var lastchecktime:Float;
    var modelname:String;
    var lightstyles:Array<String>;

    function new() {}
}

@:enum abstract MoveType(Int) to Int {
    var none = 0;
    var anglenoclip = 1;
    var angleclip = 2;
    var walk = 3;
    var step = 4;
    var fly = 5;
    var toss = 6;
    var push = 7;
    var noclip = 8;
    var flymissile = 9;
    var bounce = 10;
}

@:enum abstract EntFlag(Int) to Int {
    var fly = 1;
    var swim = 2;
    var conveyor = 4;
    var client = 8;
    var inwater = 16;
    var monster = 32;
    var godmode = 64;
    var notarget = 128;
    var item = 256;
    var onground = 512;
    var partialground = 1024;
    var waterjump = 2048;
    var jumpreleased = 4096;

    @:op(a+b) static function _(a:EntFlag, b:EntFlag):EntFlag;
    @:op(a|b) static function _(a:EntFlag, b:EntFlag):EntFlag;
    @:op(a&b) static function _(a:EntFlag, b:EntFlag):EntFlag;
    @:op(a^b) static function _(a:EntFlag, b:EntFlag):EntFlag;
    @:op(~a) static function _(a:EntFlag):EntFlag;
}

@:enum abstract DamageType(Int) to Int {
    var no = 0;
    var yes = 1;
    var aim = 2;
}

@:enum abstract SolidType(Int) to Int {
    var not = 0;
    var trigger = 1;
    var bbox = 2;
    var slidebox = 3;
    var bsp = 4;
}

@:enum abstract ClipType(Int) to Int {
    var normal = 0;
    var nomonsters = 1;
    var missile = 2;
}

@:publicFields
class SV {
    // main

    static var server = new ServerState();
    static var svs = new ServerStatic();

    static var maxvelocity:Cvar;
    static var gravity:Cvar;
    static var friction:Cvar;
    static var edgefriction:Cvar;
    static var stopspeed:Cvar;
    static var maxspeed:Cvar;
    static var accelerate:Cvar;
    static var idealpitchscale:Cvar;
    static var aim:Cvar;
    static var nostep:Cvar;

    static var nop:MSG;
    static var reconnect:MSG;
    static var clientdatagram = new MSG(1024);

    static var areanodes:Array<AreaNode>;
    static var box_clipnodes:Array<ClipNode>;
    static var box_planes:Array<Plane>;
    static var box_hull:Hull;
    static var steptrace:Trace;
    static var player:Edict;
    static var fatpvs = [];
    static var fatbytes:Int;

    static function Init() {
        maxvelocity = Cvar.RegisterVariable('sv_maxvelocity', '2000');
        gravity = Cvar.RegisterVariable('sv_gravity', '800', false, true);
        friction = Cvar.RegisterVariable('sv_friction', '4', false, true);
        edgefriction = Cvar.RegisterVariable('edgefriction', '2');
        stopspeed = Cvar.RegisterVariable('sv_stopspeed', '100');
        maxspeed = Cvar.RegisterVariable('sv_maxspeed', '320', false, true);
        accelerate = Cvar.RegisterVariable('sv_accelerate', '10');
        idealpitchscale = Cvar.RegisterVariable('sv_idealpitchscale', '0.8');
        aim = Cvar.RegisterVariable('sv_aim', '0.93');
        nostep = Cvar.RegisterVariable('sv_nostep', '0');

        nop = new MSG(4, 1);
        new Uint8Array(nop.data)[0] = SVC.nop;

        reconnect = new MSG(128);
        reconnect.WriteByte(SVC.stufftext);
        reconnect.WriteString('reconnect\n');

        InitBoxHull();
    }

    static function StartParticle(org:Vec, dir:Vec, color:Int, count:Int):Void {
        var datagram = server.datagram;
        if (datagram.cursize >= 1009)
            return;
        datagram.WriteByte(SVC.particle);
        datagram.WriteCoord(org[0]);
        datagram.WriteCoord(org[1]);
        datagram.WriteCoord(org[2]);
        for (i in 0...3) {
            var v = Std.int(dir[i] * 16.0);
            if (v > 127)
                v = 127;
            else if (v < -128)
                v = -128;
            datagram.WriteChar(v);
        }
        datagram.WriteByte(count);
        datagram.WriteByte(color);
    }

    static function StartSound(entity:Edict, channel:Int, sample:String, volume:Int, attenuation:Float):Void {
        if (volume < 0 || volume > 255)
            Sys.Error('SV.StartSound: volume = ' + volume);
        if (attenuation < 0.0 || attenuation > 4.0)
            Sys.Error('SV.StartSound: attenuation = ' + attenuation);
        if (channel < 0 || channel > 7)
            Sys.Error('SV.StartSound: channel = ' + channel);

        var datagram = server.datagram;
        if (datagram.cursize >= 1009)
            return;

        var i = 1;
        while (i < server.sound_precache.length) {
            if (sample == server.sound_precache[i])
                break;
            i++;
        }
        if (i >= server.sound_precache.length) {
            Console.Print('SV.StartSound: ' + sample + ' not precached\n');
            return;
        }

        var field_mask = 0;
        if (volume != 255)
            field_mask += 1;
        if (attenuation != 1.0)
            field_mask += 2;

        datagram.WriteByte(SVC.sound);
        datagram.WriteByte(field_mask);
        if ((field_mask & 1) != 0)
            datagram.WriteByte(volume);
        if ((field_mask & 2) != 0)
            datagram.WriteByte(Math.floor(attenuation * 64.0));
        datagram.WriteShort((entity.num << 3) + channel);
        datagram.WriteByte(i);
        datagram.WriteCoord(entity.v.origin[0] + 0.5 * (entity.v.mins[0] + entity.v.maxs[0]));
        datagram.WriteCoord(entity.v.origin[1] + 0.5 * (entity.v.mins[1] + entity.v.maxs[1]));
        datagram.WriteCoord(entity.v.origin[2] + 0.5 * (entity.v.mins[2] + entity.v.maxs[2]));
    }

    static function SendServerinfo(client:HClient):Void {
        var message = client.message;
        message.WriteByte(SVC.print);
        message.WriteString(String.fromCharCode(2) + '\nVERSION 1.09 SERVER (' + PR.crc + ' CRC)\n');
        message.WriteByte(SVC.serverinfo);
        message.WriteLong(Protocol.version);
        message.WriteByte(svs.maxclients);
        message.WriteByte((Host.coop.value == 0 && Host.deathmatch.value != 0) ? 1 : 0);
        message.WriteString(PR.GetString(server.edicts[0].v.message));
        for (i in 1...server.model_precache.length)
            message.WriteString(server.model_precache[i]);
        message.WriteByte(0);
        for (i in 1...server.sound_precache.length)
            message.WriteString(server.sound_precache[i]);
        message.WriteByte(0);
        message.WriteByte(SVC.cdtrack);
        message.WriteByte(Std.int(server.edicts[0].v.sounds));
        message.WriteByte(Std.int(server.edicts[0].v.sounds));
        message.WriteByte(SVC.setview);
        message.WriteShort(client.edict.num);
        message.WriteByte(SVC.signonnum);
        message.WriteByte(1);
        client.sendsignon = true;
        client.spawned = false;
    }

    static function ConnectClient(clientnum:Int):Void {
        var client = svs.clients[clientnum];
        var spawn_parms = null;
        if (server.loadgame) {
            spawn_parms = [];
            if (client.spawn_parms == null) {
                client.spawn_parms = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
            }
            for (i in 0...16)
                spawn_parms[i] = client.spawn_parms[i];
        }
        Console.DPrint('Client ' + client.netconnection.address + ' connected\n');
        client.active = true;
        client.dropasap = false;
        client.last_message = 0.0;
        client.cmd = new ClientCmd();
        client.wishdir = new Vec();
        client.message.cursize = 0;
        client.edict = server.edicts[clientnum + 1];
        client.edict.v.netname = PR.netnames + (clientnum << 5);
        SetClientName(client, 'unconnected');
        client.colors = 0;
        client.ping_times = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        client.num_pings = 0;
        if (!server.loadgame) {
            client.spawn_parms = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        }
        client.old_frags = 0;
        if (server.loadgame) {
            for (i in 0...16)
                client.spawn_parms[i] = spawn_parms[i];
        } else {
            PR.ExecuteProgram(PR.globals.SetNewParms);
            client.spawn_parms = PR.globals.GetParms();
        }
        SendServerinfo(client);
    }


    static function CheckForNewClients():Void {
        while (true) {
            var ret = NET.CheckNewConnections();
            if (ret == null)
                return;
            var i = 0;
            while (i < svs.maxclients) {
                if (!svs.clients[i].active)
                    break;
                i++;
            }
            if (i == svs.maxclients)
                Sys.Error('SV.CheckForNewClients: no free clients');
            svs.clients[i].netconnection = ret;
            ConnectClient(i);
            NET.activeconnections++;
        }
    }

    static function AddToFatPVS(org:Vec, node:Node):Void {
        while (true) {
            if (node.contents < 0) {
                if (node.contents != Contents.solid) {
                    var pvs = Mod_Brush.LeafPVS(cast node, server.worldmodel);
                    for (i in 0...fatbytes)
                        fatpvs[i] |= pvs[i];
                }
                return;
            }
            var normal = node.plane.normal;
            var d = org[0] * normal[0] + org[1] * normal[1] + org[2] * normal[2] - node.plane.dist;
            if (d > 8.0) {
                node = node.child0;
            } else {
                if (d >= -8.0)
                    AddToFatPVS(org, node.child0);
                node = node.child1;
            }
        }
    }

    static function FatPVS(org:Vec):Void {
        fatbytes = (server.worldmodel.leafs.length + 31) >> 3;
        for (i in 0...fatbytes)
            fatpvs[i] = 0;
        AddToFatPVS(org, server.worldmodel.nodes[0]);
    }

    static function WriteEntitiesToClient(clent:Edict, msg:MSG):Void {
        FatPVS(Vec.Add(clent.v.origin, clent.v.view_ofs));
        var pvs = fatpvs;
        for (e in 1...server.num_edicts) {
            var ent = server.edicts[e];
            if (ent != clent) {
                if (ent.v.modelindex == 0.0 || PR.strings[ent.v.model] == 0)
                    continue;
                var i = 0;
                while (i < ent.leafnums.length) {
                    if ((pvs[ent.leafnums[i] >> 3] & (1 << (ent.leafnums[i] & 7))) != 0)
                        break;
                    i++;
                }
                if (i == ent.leafnums.length)
                    continue;
            }
            if ((msg.data.byteLength - msg.cursize) < 16) {
                Console.Print('packet overflow\n');
                return;
            }

            var bits = 0;
            for (i in 0...3) {
                var miss = ent.v.origin[i] - ent.baseline.origin[i];
                if (miss < -0.1 || miss > 0.1)
                    bits += U.origin1 << i;
            }
            if (ent.v.angles[0] != ent.baseline.angles[0])
                bits += U.angle1;
            if (ent.v.angles[1] != ent.baseline.angles[1])
                bits += U.angle2;
            if (ent.v.angles[2] != ent.baseline.angles[2])
                bits += U.angle3;
            if (ent.v.movetype == MoveType.step)
                bits += U.nolerp;
            if (ent.baseline.colormap != ent.v.colormap)
                bits += U.colormap;
            if (ent.baseline.skin != ent.v.skin)
                bits += U.skin;
            if (ent.baseline.frame != ent.v.frame)
                bits += U.frame;
            if (ent.baseline.effects != ent.v.effects)
                bits += U.effects;
            if (ent.baseline.modelindex != ent.v.modelindex)
                bits += U.model;
            if (e >= 256)
                bits += U.longentity;
            if (bits >= 256)
                bits += U.morebits;

            msg.WriteByte(bits + U.signal);
            if ((bits & U.morebits) != 0)
                msg.WriteByte(bits >> 8);
            if ((bits & U.longentity) != 0)
                msg.WriteShort(e);
            else
                msg.WriteByte(e);
            if ((bits & U.model) != 0)
                msg.WriteByte(Std.int(ent.v.modelindex));
            if ((bits & U.frame) != 0)
                msg.WriteByte(Std.int(ent.v.frame));
            if ((bits & U.colormap) != 0)
                msg.WriteByte(Std.int(ent.v.colormap));
            if ((bits & U.skin) != 0)
                msg.WriteByte(Std.int(ent.v.skin));
            if ((bits & U.effects) != 0)
                msg.WriteByte(Std.int(ent.v.effects));
            if ((bits & U.origin1) != 0)
                msg.WriteCoord(ent.v.origin[0]);
            if ((bits & U.angle1) != 0)
                msg.WriteAngle(ent.v.angles[0]);
            if ((bits & U.origin2) != 0)
                msg.WriteCoord(ent.v.origin[1]);
            if ((bits & U.angle2) != 0)
                msg.WriteAngle(ent.v.angles[1]);
            if ((bits & U.origin3) != 0)
                msg.WriteCoord(ent.v.origin[2]);
            if ((bits & U.angle3) != 0)
                msg.WriteAngle(ent.v.angles[2]);
        }
    }

    static function WriteClientdataToMessage(ent:Edict, msg:MSG):Void {
        if (ent.v.dmg_take != 0.0 || ent.v.dmg_save != 0.0) {
            var other = server.edicts[ent.v.dmg_inflictor];
            msg.WriteByte(SVC.damage);
            msg.WriteByte(Std.int(ent.v.dmg_save));
            msg.WriteByte(Std.int(ent.v.dmg_take));
            msg.WriteCoord(other.v.origin[0] + 0.5 * (other.v.mins[0] + other.v.maxs[0]));
            msg.WriteCoord(other.v.origin[1] + 0.5 * (other.v.mins[1] + other.v.maxs[1]));
            msg.WriteCoord(other.v.origin[2] + 0.5 * (other.v.mins[2] + other.v.maxs[2]));
            ent.v.dmg_take = 0.0;
            ent.v.dmg_save = 0.0;
        }

        SetIdealPitch();

        if (ent.v.fixangle != 0.0) {
            msg.WriteByte(SVC.setangle);
            msg.WriteAngle(ent.v.angles[0]);
            msg.WriteAngle(ent.v.angles[1]);
            msg.WriteAngle(ent.v.angles[2]);
            ent.v.fixangle = 0.0;
        }

        var bits = SU.items + SU.weapon;
        if (ent.v.view_ofs[2] != Protocol.default_viewheight)
            bits += SU.viewheight;
        if (ent.v.idealpitch != 0.0)
            bits += SU.idealpitch;

        var val = EdictVars.items2_ofs;
        var items;
        if (val != null) {
            if (ent.v.floats[val] != 0.0)
                items = Std.int(ent.items) + (Std.int(ent.v.floats[val]) << 23);
            else
                items = Std.int(ent.items) + (Std.int(PR.globals.serverflags) << 28);
        } else {
            items = Std.int(ent.items) + (Std.int(PR.globals.serverflags) << 28);
        }

        if ((ent.flags & EntFlag.onground) != 0)
            bits += SU.onground;
        if (ent.v.waterlevel >= 2.0)
            bits += SU.inwater;

        if (ent.v.punchangle[0] != 0.0)
            bits += SU.punch1;
        if (ent.v.velocity[0] != 0.0)
            bits += SU.velocity1;
        if (ent.v.punchangle[1] != 0.0)
            bits += SU.punch2;
        if (ent.v.velocity[1] != 0.0)
            bits += SU.velocity2;
        if (ent.v.punchangle[2] != 0.0)
            bits += SU.punch3;
        if (ent.v.velocity[2] != 0.0)
            bits += SU.velocity3;

        if (ent.v.weaponframe != 0.0)
            bits += SU.weaponframe;
        if (ent.v.armorvalue != 0.0)
            bits += SU.armor;

        msg.WriteByte(SVC.clientdata);
        msg.WriteShort(bits);
        if ((bits & SU.viewheight) != 0)
            msg.WriteChar(Std.int(ent.v.view_ofs[2]));
        if ((bits & SU.idealpitch) != 0)
            msg.WriteChar(Std.int(ent.v.idealpitch));

        if ((bits & SU.punch1) != 0)
            msg.WriteChar(Std.int(ent.v.punchangle[0]));
        if ((bits & SU.velocity1) != 0)
            msg.WriteChar(Std.int(ent.v.velocity[0] * 0.0625));
        if ((bits & SU.punch2) != 0)
            msg.WriteChar(Std.int(ent.v.punchangle[1]));
        if ((bits & SU.velocity2) != 0)
            msg.WriteChar(Std.int(ent.v.velocity[1] * 0.0625));
        if ((bits & SU.punch3) != 0)
            msg.WriteChar(Std.int(ent.v.punchangle[2]));
        if ((bits & SU.velocity3) != 0)
            msg.WriteChar(Std.int(ent.v.velocity[2] * 0.0625));

        msg.WriteLong(items);
        if ((bits & SU.weaponframe) != 0)
            msg.WriteByte(Std.int(ent.v.weaponframe));
        if ((bits & SU.armor) != 0)
            msg.WriteByte(Std.int(ent.v.armorvalue));
        msg.WriteByte(ModelIndex(PR.GetString(ent.v.weaponmodel)));
        msg.WriteShort(Std.int(ent.v.health));
        msg.WriteByte(Std.int(ent.v.currentammo));
        msg.WriteByte(Std.int(ent.v.ammo_shells));
        msg.WriteByte(Std.int(ent.v.ammo_nails));
        msg.WriteByte(Std.int(ent.v.ammo_rockets));
        msg.WriteByte(Std.int(ent.v.ammo_cells));
        if (COM.standard_quake) {
            msg.WriteByte(Std.int(ent.v.weapon));
        } else {
            var weapon = Std.int(ent.v.weapon);
            for (i in 0...32) {
                if ((weapon & (1 << i)) != 0) {
                    msg.WriteByte(i);
                    break;
                }
            }
        }
    }

    static function SendClientDatagram():Bool {
        var client = Host.client;
        var msg = clientdatagram;
        msg.cursize = 0;
        msg.WriteByte(SVC.time);
        msg.WriteFloat(server.time);
        WriteClientdataToMessage(client.edict, msg);
        WriteEntitiesToClient(client.edict, msg);
        if ((msg.cursize + server.datagram.cursize) < msg.data.byteLength)
            msg.Write(new Uint8Array(server.datagram.data), server.datagram.cursize);
        if (NET.SendUnreliableMessage(client.netconnection, msg) == -1) {
            Host.DropClient(true);
            return false;
        }
        return true;
    }

    static function UpdateToReliableMessages():Void {
        for (i in 0...svs.maxclients) {
            Host.client = svs.clients[i];
            var frags = Std.int(Host.client.edict.v.frags);
            Host.client.edict.v.frags = frags;
            if (Host.client.old_frags == frags)
                continue;
            for (j in 0...svs.maxclients) {
                var client = svs.clients[j];
                if (!client.active)
                    continue;
                client.message.WriteByte(SVC.updatefrags);
                client.message.WriteByte(i);
                client.message.WriteShort(frags);
            }
            Host.client.old_frags = frags;
        }

        for (i in 0...svs.maxclients) {
            var client = svs.clients[i];
            if (client.active)
                client.message.Write(new Uint8Array(server.reliable_datagram.data), server.reliable_datagram.cursize);
        }

        server.reliable_datagram.cursize = 0;
    }

    static function SendClientMessages():Void {
        UpdateToReliableMessages();
        for (i in 0...svs.maxclients) {
            var client = Host.client = svs.clients[i];
            if (!client.active)
                continue;
            if (client.spawned) {
                if (!SendClientDatagram())
                    continue;
            } else if (!client.sendsignon) {
                if ((Host.realtime - client.last_message) > 5.0) {
                    if (NET.SendUnreliableMessage(client.netconnection, nop) == -1)
                        Host.DropClient(true);
                    client.last_message = Host.realtime;
                }
                continue;
            }
            if (client.message.overflowed) {
                Host.DropClient(true);
                client.message.overflowed = false;
                continue;
            }
            if (client.dropasap) {
                if (NET.CanSendMessage(client.netconnection))
                    Host.DropClient(false);
            } else if (client.message.cursize != 0) {
                if (!NET.CanSendMessage(client.netconnection))
                    continue;
                if (NET.SendMessage(client.netconnection, client.message) == -1)
                    Host.DropClient(true);
                client.message.cursize = 0;
                client.last_message = Host.realtime;
                client.sendsignon = false;
            }
        }

        for (i in 1...server.num_edicts)
            server.edicts[i].v.effects = Std.int(server.edicts[i].v.effects) & ~EF_MUZZLEFLASH;
    }

    static function ModelIndex(name:String):Int {
        if (name == null)
            return 0;
        if (name.length == 0)
            return 0;
        for (i in 0...server.model_precache.length) {
            if (server.model_precache[i] == name)
                return i;
        }
        Sys.Error('SV.ModelIndex: model ' + name + ' not precached');
        return 0;
    }

    static function CreateBaseline():Void {
        var player = ModelIndex('progs/player.mdl');
        var signon = server.signon;
        for (i in 0...server.num_edicts) {
            var svent = server.edicts[i];
            if (svent.free)
                continue;
            if (i > svs.maxclients && svent.v.modelindex == 0)
                continue;
            var baseline = svent.baseline;
            baseline.origin.setValues(svent.v.origin[0], svent.v.origin[1], svent.v.origin[2]);
            baseline.angles.setValues(svent.v.angles[0], svent.v.angles[1], svent.v.angles[2]);
            baseline.frame = Std.int(svent.v.frame);
            baseline.skin = Std.int(svent.v.skin);
            if (i > 0 && i <= svs.maxclients) {
                baseline.colormap = i;
                baseline.modelindex = player;
            } else {
                baseline.colormap = 0;
                baseline.modelindex = ModelIndex(PR.GetString(svent.v.model));
            }
            signon.WriteByte(SVC.spawnbaseline);
            signon.WriteShort(i);
            signon.WriteByte(baseline.modelindex);
            signon.WriteByte(baseline.frame);
            signon.WriteByte(baseline.colormap);
            signon.WriteByte(baseline.skin);
            signon.WriteCoord(baseline.origin[0]);
            signon.WriteAngle(baseline.angles[0]);
            signon.WriteCoord(baseline.origin[1]);
            signon.WriteAngle(baseline.angles[1]);
            signon.WriteCoord(baseline.origin[2]);
            signon.WriteAngle(baseline.angles[2]);
        }
    }

    static function SaveSpawnparms():Void {
        svs.serverflags = Std.int(PR.globals.serverflags);
        for (i in 0...svs.maxclients) {
            Host.client = svs.clients[i];
            if (!Host.client.active)
                continue;
            PR.globals.self = Host.client.edict.num;
            PR.ExecuteProgram(PR.globals.SetChangeParms);
            Host.client.spawn_parms = PR.globals.GetParms();
        }
    }

    static function SpawnServer(map:String):Void {
        if (NET.hostname.string.length == 0)
            NET.hostname.set('UNNAMED');

        SCR.centertime_off = 0.0;

        Console.DPrint('SpawnServer: $map\n');
        svs.changelevel_issued = false;

        if (server.active) {
            NET.SendToAll(reconnect);
            Cmd.ExecuteString('reconnect\n');
        }

        if (Host.coop.value != 0)
            Host.deathmatch.setValue(0);
        Host.current_skill = Math.floor(Host.skill.value + 0.5);
        if (Host.current_skill < 0)
            Host.current_skill = 0;
        else if (Host.current_skill > 3)
            Host.current_skill = 3;
        Host.skill.setValue(Host.current_skill);

        Console.DPrint('Clearing memory\n');
        Mod.ClearAll();

        PR.LoadProgs();

        server.edicts = [];
        for (i in 0...Def.max_edicts)
            server.edicts.push(new Edict(i));

        server.datagram.cursize = 0;
        server.reliable_datagram.cursize = 0;
        server.signon.cursize = 0;
        server.num_edicts = svs.maxclients + 1;
        for (i in 0...svs.maxclients)
            svs.clients[i].edict = server.edicts[i + 1];
        server.loading = true;
        server.paused = false;
        server.loadgame = false;
        server.time = 1.0;
        server.lastcheck = 0;
        server.lastchecktime = 0.0;
        server.modelname = 'maps/' + map + '.bsp';
        server.worldmodel = Mod.ForName(server.modelname, false);
        if (server.worldmodel == null) {
            Console.Print('Couldn\'t spawn server ' + server.modelname + '\n');
            server.active = false;
            return;
        }
        server.models = [];
        server.models[1] = server.worldmodel;

        areanodes = [];
        CreateAreaNode(0, server.worldmodel.mins, server.worldmodel.maxs);

        server.sound_precache = [''];
        server.model_precache = ['', server.modelname];
        for (i in 1...server.worldmodel.submodels.length + 1) {
            server.model_precache[i + 1] = '*' + i;
            server.models[i + 1] = Mod.ForName('*' + i, false);
        }

        server.lightstyles = [];
        for (i in 0...CL.MAX_LIGHTSTYLES)
            server.lightstyles.push('');

        var ent = server.edicts[0];
        ent.v.model = PR.NewString(server.modelname, 64);
        ent.v.modelindex = 1.0;
        ent.v.solid = SolidType.bsp;
        ent.v.movetype = MoveType.push;

        if (Host.coop.value != 0)
            PR.globals.coop = Host.coop.value;
        else
            PR.globals.deathmatch = Host.deathmatch.value;

        PR.globals.mapname = PR.NewString(map, 64);
        PR.globals.serverflags = svs.serverflags;
        ED.LoadFromFile(server.worldmodel.entities);
        server.active = true;
        server.loading = false;
        Host.frametime = 0.1;
        Physics();
        Physics();
        CreateBaseline();
        for (i in 0...svs.maxclients) {
            Host.client = svs.clients[i];
            if (!Host.client.active)
                continue;
            Host.client.edict.v.netname = PR.netnames + (i << 5);
            SendServerinfo(Host.client);
        }
        Console.DPrint('Server spawned.\n');
    }

    static inline function GetClientName(client:HClient):String {
        return PR.GetString(PR.netnames + (client.num << 5));
    }

    static function SetClientName(client:HClient, name:String):Void {
        var ofs = PR.netnames + (client.num << 5);
        var i = 0;
        while (i < name.length) {
            PR.strings[ofs + i] = name.charCodeAt(i);
            i++;
        }
        PR.strings[ofs + i] = 0;
    }

    // move

    static function CheckBottom(ent:Edict):Bool {
        var mins = [
            ent.v.origin[0] + ent.v.mins[0],
            ent.v.origin[1] + ent.v.mins[1],
            ent.v.origin[2] + ent.v.mins[2]
        ];
        var maxs = [
            ent.v.origin[0] + ent.v.maxs[0],
            ent.v.origin[1] + ent.v.maxs[1],
            ent.v.origin[2] + ent.v.maxs[2]
        ];
        while (true) {
            if (PointContents(Vec.of(mins[0], mins[1], mins[2] - 1.0)) != Contents.solid)
                break;
            if (PointContents(Vec.of(mins[0], maxs[1], mins[2] - 1.0)) != Contents.solid)
                break;
            if (PointContents(Vec.of(maxs[0], mins[1], mins[2] - 1.0)) != Contents.solid)
                break;
            if (PointContents(Vec.of(maxs[0], maxs[1], mins[2] - 1.0)) != Contents.solid)
                break;
            return true;
        }
        var start = Vec.of((mins[0] + maxs[0]) * 0.5, (mins[1] + maxs[1]) * 0.5, mins[2]);
        var stop = Vec.of(start[0], start[1], start[2] - 36.0);
        var trace = Move(start, Vec.origin, Vec.origin, stop, 1, ent);
        if (trace.fraction == 1.0)
            return false;
        var mid, bottom;
        mid = bottom = trace.endpos[2];
        for (x in 0...2) {
            for (y in 0...2) {
                start[0] = stop[0] = (x != 0) ? maxs[0] : mins[0];
                start[1] = stop[1] = (y != 0) ? maxs[1] : mins[1];
                trace = Move(start, Vec.origin, Vec.origin, stop, 1, ent);
                if (trace.fraction != 1.0 && trace.endpos[2] > bottom)
                    bottom = trace.endpos[2];
                if (trace.fraction == 1.0 || (mid - trace.endpos[2]) > 18.0)
                    return false;
            }
        }
        return true;
    }

    static function movestep(ent:Edict, move:Vec, relink:Bool):Bool {
        var oldorg = ent.v.origin;
        var neworg = new Vec();
        var mins = ent.v.mins.copy();
        var maxs = ent.v.maxs.copy();
        if ((ent.flags & (EntFlag.swim + EntFlag.fly)) != 0) {
            var enemy = ent.v.enemy;
            for (i in 0...2) {
                neworg.setValues(
                    ent.v.origin[0] + move[0],
                    ent.v.origin[1] + move[1],
                    ent.v.origin[2]
                );
                if (i == 0 && enemy != 0) {
                    var dz = ent.v.origin[2] - server.edicts[enemy].v.origin[2];
                    if (dz > 40.0)
                        neworg[2] -= 8.0;
                    else if (dz < 30.0)
                        neworg[2] += 8.0;
                }
                var trace = Move(ent.v.origin.copy(), mins, maxs, neworg, 0, ent);
                if (trace.fraction == 1.0) {
                    if ((ent.flags & EntFlag.swim) != 0 && PointContents(trace.endpos) == Contents.empty)
                        return false;
                    ent.v.origin.setVector(trace.endpos);
                    if (relink)
                        LinkEdict(ent, true);
                    return true;
                }
                if (enemy == 0)
                    return false;
            }
            return false;
        }
        neworg.setValues(ent.v.origin[0] + move[0], ent.v.origin[1] + move[1], ent.v.origin[2] + 18.0);
        var end = Vec.of(neworg[0], neworg[1], neworg[2] - 36.0);
        var trace = Move(neworg, mins, maxs, end, 0, ent);
        if (trace.allsolid)
            return false;
        if (trace.startsolid) {
            neworg[2] -= 18.0;
            trace = Move(neworg, mins, maxs, end, 0, ent);
            if (trace.allsolid || trace.startsolid)
                return false;
        }
        if (trace.fraction == 1.0) {
            if ((ent.flags & EntFlag.partialground) == 0)
                return false;
            ent.v.origin[0] += move[0];
            ent.v.origin[1] += move[1];
            if (relink)
                LinkEdict(ent, true);
            ent.flags &= ~EntFlag.onground;
            return true;
        }
        ent.v.origin.setVector(trace.endpos);
        if (!CheckBottom(ent)) {
            if ((ent.flags & EntFlag.partialground) != 0) {
                if (relink)
                    LinkEdict(ent, true);
                return true;
            }
            ent.v.origin.setVector(oldorg);
            return false;
        }
        ent.flags &= ~EntFlag.partialground;
        ent.v.groundentity = trace.ent.num;
        if (relink)
            LinkEdict(ent, true);
        return true;
    }

    static function StepDirection(ent:Edict, yaw:Float, dist:Float):Bool {
        ent.v.ideal_yaw = yaw;
        PF.changeyaw();
        yaw *= Math.PI / 180.0;
        var oldorigin = ent.v.origin.copy();
        if (movestep(ent, Vec.of(Math.cos(yaw) * dist, Math.sin(yaw) * dist, 0), false)) {
            var delta = ent.v.angles[1] - ent.v.ideal_yaw;
            if (delta > 45.0 && delta < 315.0)
                ent.v.origin.setVector(oldorigin);
            LinkEdict(ent, true);
            return true;
        }
        LinkEdict(ent, true);
        return false;
    }

    static function NewChaseDir(actor:Edict, enemy:Edict, dist:Float):Void {
        var olddir = Vec.Anglemod(Std.int(actor.v.ideal_yaw / 45.0) * 45.0);
        var turnaround = Vec.Anglemod(olddir - 180.0);
        var deltax = enemy.v.origin[0] - actor.v.origin[0];
        var deltay = enemy.v.origin[1] - actor.v.origin[1];
        var dx, dy;
        if (deltax > 10.0)
            dx = 0.0;
        else if (deltax < -10.0)
            dx = 180.0;
        else
            dx = -1;
        if (deltay < -10.0)
            dy = 270.0;
        else if (deltay > 10.0)
            dy = 90.0;
        else
            dy = -1;
        var tdir;
        if (dx != -1 && dy != -1) {
            if (dx == 0.0)
                tdir = (dy == 90.0) ? 45.0 : 315.0;
            else
                tdir = (dy == 90.0) ? 135.0 : 215.0;
            if (tdir != turnaround && StepDirection(actor, tdir, dist))
                return;
        }
        if (Math.random() >= 0.25 || Math.abs(deltay) > Math.abs(deltax)) {
            tdir = dx;
            dx = dy;
            dy = tdir;
        }
        if (dx != -1 && dx != turnaround && StepDirection(actor, dx, dist))
            return;
        if (dy != -1 && dy != turnaround && StepDirection(actor, dy, dist))
            return;
        if (olddir != -1 && StepDirection(actor, olddir, dist))
            return;
        if (Math.random() >= 0.5) {
            tdir = 0.0;
            while (tdir <= 315.0) {
                if (tdir != turnaround && StepDirection(actor, tdir, dist))
                    return;
                tdir += 45.0;
            }
        } else {
            tdir = 315.0;
            while (tdir >= 0.0) {
                if (tdir != turnaround && StepDirection(actor, tdir, dist))
                    return;
                tdir -= 45.0;
            }
        }
        if (turnaround != -1 && StepDirection(actor, turnaround, dist))
            return;
        actor.v.ideal_yaw = olddir;
        if (!CheckBottom(actor))
            actor.flags |= EntFlag.partialground;
    }

    static function CloseEnough(ent:Edict, goal:Edict, dist:Float):Bool {
        for (i in 0...3) {
            if (goal.v.absmin[i] > (ent.v.absmax[i] + dist))
                return false;
            if (goal.v.absmax[i] < (ent.v.absmin[i] - dist))
                return false;
        }
        return true;
    }

    // phys

    static function CheckAllEnts():Void {
        for (e in 1...server.num_edicts) {
            var check = server.edicts[e];
            if (check.free)
                continue;
            switch (check.v.movetype) {
                case MoveType.push | MoveType.none | MoveType.noclip:
                    continue;
            }
            if (TestEntityPosition(check))
                Console.Print('entity in invalid position\n');
        }
    }

    static function CheckVelocity(ent:Edict):Void {
        for (i in 0...3) {
            var velocity = ent.v.velocity[i];
            if (Math.isNaN(velocity)) {
                Console.Print('Got a NaN velocity on ' + PR.GetString(ent.v.classname) + '\n');
                velocity = 0.0;
            }
            if (Math.isNaN(ent.v.origin[i])) {
                Console.Print('Got a NaN origin on ' + PR.GetString(ent.v.classname) + '\n');
                ent.v.origin[i] = 0.0;
            }
            if (velocity > maxvelocity.value)
                velocity = maxvelocity.value;
            else if (velocity < -maxvelocity.value)
                velocity = -maxvelocity.value;
            ent.v.velocity[i] = velocity;
        }
    }

    static function RunThink(ent:Edict):Bool {
        var thinktime = ent.v.nextthink;
        if (thinktime <= 0.0 || thinktime > (server.time + Host.frametime))
            return true;
        if (thinktime < server.time)
            thinktime = server.time;
        ent.v.nextthink = 0.0;
        PR.globals.time = thinktime;
        PR.globals.self = ent.num;
        PR.globals.other = 0;
        PR.ExecuteProgram(ent.v.think);
        return !ent.free;
    }

    static function Impact(e1:Edict, e2:Edict):Void {
        var old_self = PR.globals.self;
        var old_other = PR.globals.other;
        PR.globals.time = server.time;

        if (e1.v.touch != 0 && e1.v.solid != SolidType.not) {
            PR.globals.self = e1.num;
            PR.globals.other = e2.num;
            PR.ExecuteProgram(e1.v.touch);
        }
        if (e2.v.touch != 0 && e2.v.solid != SolidType.not) {
            PR.globals.self = e2.num;
            PR.globals.other = e1.num;
            PR.ExecuteProgram(e2.v.touch);
        }

        PR.globals.self = old_self;
        PR.globals.other = old_other;
    }

    static function ClipVelocity(vec:Vec, normal:Vec, out:Vec, overbounce:Float):Void {
        var backoff = (vec[0] * normal[0] + vec[1] * normal[1] + vec[2] * normal[2]) * overbounce;

        out[0] = vec[0] - normal[0] * backoff;
        if (out[0] > -0.1 && out[0] < 0.1)
            out[0] = 0.0;
        out[1] = vec[1] - normal[1] * backoff;
        if (out[1] > -0.1 && out[1] < 0.1)
            out[1] = 0.0;
        out[2] = vec[2] - normal[2] * backoff;
        if (out[2] > -0.1 && out[2] < 0.1)
            out[2] = 0.0;
    }

    static function FlyMove(ent:Edict, time:Float):Int {
        var primal_velocity = ent.v.velocity.copy();
        var original_velocity = ent.v.velocity.copy();
        var new_velocity = new Vec();
        var end = new Vec();
        var time_left = time;
        var blocked = 0;
        var planes = [];
        var numplanes = 0;
        for (bumpcount in 0...4) {
            if (ent.v.velocity[0] == 0.0 && ent.v.velocity[1] == 0.0 && ent.v.velocity[2] == 0.0)
                break;
            end[0] = ent.v.origin[0] + time_left * ent.v.velocity[0];
            end[1] = ent.v.origin[1] + time_left * ent.v.velocity[1];
            end[2] = ent.v.origin[2] + time_left * ent.v.velocity[2];
            var trace = Move(ent.v.origin.copy(), ent.v.mins.copy(), ent.v.maxs.copy(), end, 0, ent);
            if (trace.allsolid) {
                ent.v.velocity.setVector(Vec.origin);
                return 3;
            }
            if (trace.fraction > 0.0) {
                ent.v.origin.setVector(trace.endpos);
                original_velocity = ent.v.velocity.copy();
                numplanes = 0;
                if (trace.fraction == 1.0)
                    break;
            }
            if (trace.ent == null)
                Sys.Error('SV.FlyMove: !trace.ent');
            if (trace.plane.normal[2] > 0.7) {
                blocked |= 1;
                if (trace.ent.v.solid == SolidType.bsp) {
                    ent.flags |= EntFlag.onground;
                    ent.v.groundentity = trace.ent.num;
                }
            } else if (trace.plane.normal[2] == 0.0) {
                blocked |= 2;
                steptrace = trace;
            }
            Impact(ent, trace.ent);
            if (ent.free)
                break;
            time_left -= time_left * trace.fraction;
            if (numplanes >= 5) {
                ent.v.velocity.setVector(Vec.origin);
                return 3;
            }
            planes[numplanes++] = Vec.of(trace.plane.normal[0], trace.plane.normal[1], trace.plane.normal[2]);
            var i = 0;
            while (i < numplanes) {
                ClipVelocity(original_velocity, planes[i], new_velocity, 1.0);
                var j = 0;
                while (j < numplanes) {
                    if (j != i) {
                        var plane = planes[j];
                        if ((new_velocity[0] * plane[0] + new_velocity[1] * plane[1] + new_velocity[2] * plane[2]) < 0.0)
                            break;
                    }
                    j++;
                }
                if (j == numplanes)
                    break;
                i++;
            }
            if (i != numplanes) {
                ent.v.velocity.setVector(new_velocity);
            } else {
                if (numplanes != 2) {
                    ent.v.velocity.setVector(Vec.origin);
                    return 7;
                }
                var dir = Vec.CrossProduct(planes[0], planes[1]);
                var d = dir[0] * ent.v.velocity[0] + dir[1] * ent.v.velocity[1] + dir[2] * ent.v.velocity[2];
                ent.v.velocity.setValues(dir[0] * d, dir[1] * d, dir[2] * d);
            }
            if ((ent.v.velocity[0] * primal_velocity[0] + ent.v.velocity[1] * primal_velocity[1] + ent.v.velocity[2] * primal_velocity[2]) <= 0.0) {
                ent.v.velocity.setVector(Vec.origin);
                return blocked;
            }
        }
        return blocked;
    }

    static function AddGravity(ent:Edict):Void {
        var val = EdictVars.gravity_ofs;
        var ent_gravity;
        if (val != null)
            ent_gravity = (ent.v.floats[val] != 0.0) ? ent.v.floats[val] : 1.0;
        else
            ent_gravity = 1.0;
        ent.v.velocity[2] -= ent_gravity * gravity.value * Host.frametime;
    }

    static function PushEntity(ent:Edict, push:Vec):Trace {
        var end = Vec.Add(ent.v.origin, push);
        var nomonsters;
        var solid = ent.v.solid;
        if (ent.v.movetype == MoveType.flymissile)
            nomonsters = ClipType.missile;
        else if (solid == SolidType.trigger || solid == SolidType.not)
            nomonsters = ClipType.nomonsters
        else
            nomonsters = ClipType.normal;
        var trace = Move(ent.v.origin.copy(), ent.v.mins.copy(), ent.v.maxs.copy(), end, nomonsters, ent);
        ent.v.origin.setVector(trace.endpos);
        LinkEdict(ent, true);
        if (trace.ent != null)
            Impact(ent, trace.ent);
        return trace;
    }

    static function PushMove(pusher:Edict, movetime:Float):Void {
        if (pusher.v.velocity[0] == 0.0 && pusher.v.velocity[1] == 0.0 && pusher.v.velocity[2] == 0.0) {
            pusher.v.ltime += movetime;
            return;
        }
        var move = Vec.of(
            pusher.v.velocity[0] * movetime,
            pusher.v.velocity[1] * movetime,
            pusher.v.velocity[2] * movetime
        );
        var mins = [
            pusher.v.absmin[0] + move[0],
            pusher.v.absmin[1] + move[1],
            pusher.v.absmin[2] + move[2]
        ];
        var maxs = [
            pusher.v.absmax[0] + move[0],
            pusher.v.absmax[1] + move[1],
            pusher.v.absmax[2] + move[2]
        ];
        var pushorig = pusher.v.origin.copy();
        pusher.v.origin[0] += move[0];
        pusher.v.origin[1] += move[1];
        pusher.v.origin[2] += move[2];
        pusher.v.ltime += movetime;
        LinkEdict(pusher, false);
        var moved:Array<Array<Any>> = [];
        for (e in 1...server.num_edicts) {
            var check = server.edicts[e];
            if (check.free)
                continue;
            var movetype = check.v.movetype;
            if (movetype == MoveType.push || movetype == MoveType.none || movetype == MoveType.noclip)
                continue;
            if ((check.flags & EntFlag.onground) == 0 || check.v.groundentity != pusher.num) {
                if (check.v.absmin[0] >= maxs[0] || check.v.absmin[1] >= maxs[1] || check.v.absmin[2] >= maxs[2] ||
                    check.v.absmax[0] <= mins[0] || check.v.absmax[1] <= mins[1] || check.v.absmax[2] <= mins[2])
                    continue;
                if (!TestEntityPosition(check))
                    continue;
            }
            if (movetype != MoveType.walk)
                check.flags &= ~EntFlag.onground;
            var entorig = check.v.origin.copy();
            moved.push([entorig[0], entorig[1], entorig[2], check]);
            pusher.v.solid = SolidType.not;
            PushEntity(check, move);
            pusher.v.solid = SolidType.bsp;
            if (TestEntityPosition(check)) {
                if (check.v.mins == check.v.maxs)
                    continue;
                if (check.v.solid == SolidType.not || check.v.solid == SolidType.trigger) {
                    check.v.mins[0] = check.v.maxs[0] = 0.0;
                    check.v.mins[1] = check.v.maxs[1] = 0.0;
                    check.v.maxs[2] = check.v.mins[2];
                    continue;
                }
                check.v.origin.setVector(entorig);
                LinkEdict(check, true);
                pusher.v.origin.setVector(pushorig);
                LinkEdict(pusher, false);
                pusher.v.ltime -= movetime;
                if (pusher.v.blocked != 0) {
                    PR.globals.self = pusher.num;
                    PR.globals.other = check.num;
                    PR.ExecuteProgram(pusher.v.blocked);
                }
                for (moved_edict in moved) {
                    var ed:Edict = moved_edict[3];
                    ed.v.origin.setValues(moved_edict[0], moved_edict[1], moved_edict[2]);
                    LinkEdict(ed, false);
                }
                return;
            }
        }
    }

    static function Physics_Pusher(ent:Edict) {
        var oldltime = ent.v.ltime;
        var thinktime = ent.v.nextthink;
        var movetime;
        if (thinktime < (oldltime + Host.frametime)) {
            movetime = thinktime - oldltime;
            if (movetime < 0.0)
                movetime = 0.0;
        } else {
            movetime = Host.frametime;
        }
        if (movetime != 0.0)
            PushMove(ent, movetime);
        if (thinktime <= oldltime || thinktime > ent.v.ltime)
            return;
        ent.v.nextthink = 0.0;
        PR.globals.time = server.time;
        PR.globals.self = ent.num;
        PR.globals.other = 0;
        PR.ExecuteProgram(ent.v.think);
    }

    static function CheckStuck(ent:Edict):Void {
        if (!TestEntityPosition(ent)) {
            ent.v.oldorigin.setVector(ent.v.origin);
            return;
        }
        var org = ent.v.origin.copy();
        ent.v.origin.setVector(ent.v.oldorigin);
        if (!TestEntityPosition(ent)) {
            Console.DPrint('Unstuck.\n');
            LinkEdict(ent, true);
            return;
        }
        for (z in 0...18) {
            for (i in -1...2) {
                for (j in -1...2) {
                    ent.v.origin.setValues(org[0] + i, org[1] + j, org[2] + z);
                    if (!TestEntityPosition(ent)) {
                        Console.DPrint('Unstuck.\n');
                        LinkEdict(ent, true);
                        return;
                    }
                }
            }
        }
        ent.v.origin.setVector(org);
        Console.DPrint('player is stuck.\n');
    }

    static function CheckWater(ent:Edict):Bool {
        var point = Vec.of(ent.v.origin[0], ent.v.origin[1], ent.v.origin[2] + ent.v.mins[2] + 1.0);
        ent.v.waterlevel = 0.0;
        ent.v.watertype = Contents.empty;
        var cont = PointContents(point);
        if (cont > Contents.water)
            return false;
        ent.v.watertype = cont;
        ent.v.waterlevel = 1.0;
        point[2] = ent.v.origin[2] + (ent.v.mins[2] + ent.v.maxs[2]) * 0.5;
        cont = PointContents(point);
        if (cont <= Contents.water) {
            ent.v.waterlevel = 2.0;
            point[2] = ent.v.origin[2] + ent.v.view_ofs[2];
            cont = PointContents(point);
            if (cont <= Contents.water)
                ent.v.waterlevel = 3.0;
        }
        return ent.v.waterlevel > 1.0;
    }

    static function WallFriction(ent:Edict, tr:Trace):Void {
        var forward = new Vec();
        Vec.AngleVectors(ent.v.v_angle.copy(), forward);
        var normal = tr.plane.normal;
        var d = normal[0] * forward[0] + normal[1] * forward[1] + normal[2] * forward[2] + 0.5;
        if (d >= 0.0)
            return;
        d += 1.0;
        var i = normal[0] * ent.v.velocity[0] + normal[1] * ent.v.velocity[1] + normal[2] * ent.v.velocity[2];
        ent.v.velocity[0] = (ent.v.velocity[0] - normal[0] * i) * d;
        ent.v.velocity[1] = (ent.v.velocity[1] - normal[1] * i) * d;
    }

    static function TryUnstick(ent:Edict, oldvel:Vec):Int {
        var oldorg = ent.v.origin.copy();
        var dir = Vec.of(2.0, 0.0, 0.0);
        for (i in 0...8) {
            switch (i) {
                case 1:
                    dir[0] = 0.0;
                    dir[1] = 2.0;
                case 2:
                    dir[0] = -2.0;
                    dir[1] = 0.0;
                case 3:
                    dir[0] = 0.0;
                    dir[1] = -2.0;
                case 4:
                    dir[0] = 2.0;
                    dir[1] = 2.0;
                case 5:
                    dir[0] = -2.0;
                    dir[1] = 2.0;
                case 6:
                    dir[0] = 2.0;
                    dir[1] = -2.0;
                case 7:
                    dir[0] = -2.0;
                    dir[1] = -2.0;
            }
            PushEntity(ent, dir);
            ent.v.velocity.setValues(oldvel[0], oldvel[1], 0.0);
            var clip = FlyMove(ent, 0.1);
            if (Math.abs(oldorg[1] - ent.v.origin[1]) > 4.0 || Math.abs(oldorg[0] - ent.v.origin[0]) > 4.0)
                return clip;
            ent.v.origin.setVector(oldorg);
        }
        ent.v.velocity.setVector(Vec.origin);
        return 7;
    }

    static function WalkMove(ent:Edict) {
        var oldonground = ent.flags & EntFlag.onground;
        ent.flags ^= oldonground;
        var oldorg = ent.v.origin.copy();
        var oldvel = ent.v.velocity.copy();
        var clip = FlyMove(ent, Host.frametime);
        if ((clip & 2) == 0)
            return;
        if (oldonground == 0 && ent.v.waterlevel == 0.0)
            return;
        if (ent.v.movetype != MoveType.walk)
            return;
        if (nostep.value != 0)
            return;
        if ((player.flags & EntFlag.waterjump) != 0)
            return;
        var nosteporg = ent.v.origin.copy();
        var nostepvel = ent.v.velocity.copy();
        ent.v.origin.setVector(oldorg);
        PushEntity(ent, Vec.of(0.0, 0.0, 18.0));
        ent.v.velocity[0] = oldvel[0];
        ent.v.velocity[1] = oldvel[1];
        ent.v.velocity[2] = 0.0;
        clip = FlyMove(ent, Host.frametime);
        if (clip != 0) {
            if (Math.abs(oldorg[1] - ent.v.origin[1]) < 0.03125 && Math.abs(oldorg[0] - ent.v.origin[0]) < 0.03125)
                clip = TryUnstick(ent, oldvel);
            if ((clip & 2) != 0)
                WallFriction(ent, steptrace);
        }
        var downtrace = PushEntity(ent, Vec.of(0.0, 0.0, oldvel[2] * Host.frametime - 18.0));
        if (downtrace.plane.normal[2] > 0.7) {
            if (ent.v.solid == SolidType.bsp) {
                ent.flags |= EntFlag.onground;
                ent.v.groundentity = downtrace.ent.num;
            }
            return;
        }
        ent.v.origin.setVector(nosteporg);
        ent.v.velocity.setVector(nostepvel);
    }

    static function Physics_Client(ent:Edict):Void {
        if (!svs.clients[ent.num - 1].active)
            return;
        PR.globals.time = server.time;
        PR.globals.self = ent.num;
        PR.ExecuteProgram(PR.globals.PlayerPreThink);
        CheckVelocity(ent);
        var movetype = Std.int(ent.v.movetype);
        if (movetype == MoveType.toss || movetype == MoveType.bounce) {
            Physics_Toss(ent);
        } else {
            if (!RunThink(ent))
                return;
            switch (movetype) {
                case MoveType.none:
                case MoveType.walk:
                    if (!CheckWater(ent) && (ent.flags & EntFlag.waterjump) == 0)
                        AddGravity(ent);
                    CheckStuck(ent);
                    WalkMove(ent);
                case MoveType.fly:
                    FlyMove(ent, Host.frametime);
                case MoveType.noclip:
                    ent.v.origin[0] += Host.frametime * ent.v.velocity[0];
                    ent.v.origin[1] += Host.frametime * ent.v.velocity[1];
                    ent.v.origin[2] += Host.frametime * ent.v.velocity[2];
                default:
                    Sys.Error('SV.Physics_Client: bad movetype ' + movetype);
            }
        }
        LinkEdict(ent, true);
        PR.globals.time = server.time;
        PR.globals.self = ent.num;
        PR.ExecuteProgram(PR.globals.PlayerPostThink);
    }

    static function Physics_Noclip(ent:Edict) {
        if (!RunThink(ent))
            return;
        ent.v.angles[0] += Host.frametime * ent.v.avelocity[0];
        ent.v.angles[1] += Host.frametime * ent.v.avelocity[1];
        ent.v.angles[2] += Host.frametime * ent.v.avelocity[2];
        ent.v.origin[0] += Host.frametime * ent.v.velocity[0];
        ent.v.origin[1] += Host.frametime * ent.v.velocity[1];
        ent.v.origin[2] += Host.frametime * ent.v.velocity[2];
        LinkEdict(ent, false);
    }

    static function CheckWaterTransition(ent:Edict):Void {
        var cont = PointContents(ent.v.origin.copy());
        if (ent.v.watertype == 0.0) {
            ent.v.watertype = cont;
            ent.v.waterlevel = 1.0;
            return;
        }
        if (cont <= Contents.water) {
            if (ent.v.watertype == Contents.empty)
                StartSound(ent, 0, 'misc/h2ohit1.wav', 255, 1.0);
            ent.v.watertype = cont;
            ent.v.waterlevel = 1.0;
            return;
        }
        if (ent.v.watertype != Contents.empty)
            StartSound(ent, 0, 'misc/h2ohit1.wav', 255, 1.0);
        ent.v.watertype = Contents.empty;
        ent.v.waterlevel = cont;
    }

    static function Physics_Toss(ent:Edict):Void {
        if (!RunThink(ent))
            return;
        if ((ent.flags & EntFlag.onground) != 0)
            return;
        CheckVelocity(ent);
        var movetype = ent.v.movetype;
        if (movetype != MoveType.fly && movetype != MoveType.flymissile)
            AddGravity(ent);
        ent.v.angles[0] += Host.frametime * ent.v.avelocity[0];
        ent.v.angles[1] += Host.frametime * ent.v.avelocity[1];
        ent.v.angles[2] += Host.frametime * ent.v.avelocity[2];
        var trace = PushEntity(ent, Vec.of(ent.v.velocity[0] * Host.frametime, ent.v.velocity[1] * Host.frametime, ent.v.velocity[2] * Host.frametime));
        if (trace.fraction == 1.0 || ent.free)
            return;
        var velocity = new Vec();
        ClipVelocity(ent.v.velocity.copy(), trace.plane.normal, velocity, (movetype == MoveType.bounce) ? 1.5 : 1.0);
        ent.v.velocity.setVector(velocity);
        if (trace.plane.normal[2] > 0.7) {
            if (ent.v.velocity[2] < 60.0 || movetype != MoveType.bounce) {
                ent.flags |= EntFlag.onground;
                ent.v.groundentity = trace.ent.num;
                ent.v.velocity.setVector(Vec.origin);
                ent.v.avelocity.setVector(Vec.origin);
            }
        }
        CheckWaterTransition(ent);
    }

    static function Physics_Step(ent:Edict):Void {
        if ((ent.flags & (EntFlag.onground + EntFlag.fly + EntFlag.swim)) == 0) {
            var hitsound = (ent.v.velocity[2] < (gravity.value * -0.1));
            AddGravity(ent);
            CheckVelocity(ent);
            FlyMove(ent, Host.frametime);
            LinkEdict(ent, true);
            if (hitsound && (ent.flags & EntFlag.onground) != 0)
                StartSound(ent, 0, 'demon/dland2.wav', 255, 1.0);
        }
        RunThink(ent);
        CheckWaterTransition(ent);
    }

    static function Physics():Void {
        PR.globals.self = 0;
        PR.globals.other = 0;
        PR.globals.time = server.time;
        PR.ExecuteProgram(PR.globals.StartFrame);
        for (i in 0...server.num_edicts) {
            var ent = server.edicts[i];
            if (ent.free)
                continue;
            if (PR.globals.force_retouch != 0.0)
                LinkEdict(ent, true);
            if (i > 0 && i <= svs.maxclients) {
                Physics_Client(ent);
                continue;
            }
            switch (ent.v.movetype) {
                case MoveType.push:
                    Physics_Pusher(ent);
                case MoveType.none:
                    RunThink(ent);
                case MoveType.noclip:
                    Physics_Noclip(ent);
                case MoveType.step:
                    Physics_Step(ent);
                case MoveType.toss | MoveType.bounce | MoveType.fly | MoveType.flymissile:
                    Physics_Toss(ent);
                default:
                    Sys.Error('SV.Physics: bad movetype ' + Std.int(ent.v.movetype));
            }
        }
        if (PR.globals.force_retouch != 0.0)
            PR.globals.force_retouch -= 1;
        server.time += Host.frametime;
    }

    // user

    static function SetIdealPitch():Void {
        var ent = player;
        if ((ent.flags & EntFlag.onground) == 0)
            return;
        var angleval = ent.v.angles[1] * (Math.PI / 180.0);
        var sinval = Math.sin(angleval);
        var cosval = Math.cos(angleval);
        var top = Vec.of(0.0, 0.0, ent.v.origin[2] + ent.v.view_ofs[2]);
        var bottom = Vec.of(0.0, 0.0, top[2] - 160.0);
        var z = [];
        for (i in 0...6) {
            top[0] = bottom[0] = ent.v.origin[0] + cosval * (i + 3) * 12.0;
            top[1] = bottom[1] = ent.v.origin[1] + sinval * (i + 3) * 12.0;
            var tr = Move(top, Vec.origin, Vec.origin, bottom, 1, ent);
            if (tr.allsolid || tr.fraction == 1.0)
                return;
            z[i] = top[2] - tr.fraction * 160.0;
        }
        var dir = 0.0, steps = 0;
        for (i in 1...6) {
            var step = z[i] - z[i - 1];
            if (step > -0.1 && step < 0.1)
                continue;
            if (dir != 0.0 && ((step - dir) > 0.1 || (step - dir) < -0.1))
                return;
            steps++;
            dir = step;
        }
        if (dir == 0.0) {
            ent.v.idealpitch = 0.0;
            return;
        }
        if (steps >= 2)
            ent.v.idealpitch = -dir * idealpitchscale.value;
    }

    static function UserFriction():Void {
        var ent = player;
        var vel0 = ent.v.velocity[0];
        var vel1 = ent.v.velocity[1];
        var speed = Math.sqrt(vel0 * vel0 + vel1 * vel1);
        if (speed == 0.0)
            return;
        var start = Vec.of(ent.v.origin[0] + vel0 / speed * 16.0, ent.v.origin[1] + vel1 / speed * 16.0, ent.v.origin[2] + ent.v.mins[2]);
        var friction = friction.value;
        if (Move(start, Vec.origin, Vec.origin, Vec.of(start[0], start[1], start[2] - 34.0), 1, ent).fraction == 1.0)
            friction *= edgefriction.value;
        var newspeed = speed - Host.frametime * (speed < stopspeed.value ? stopspeed.value : speed) * friction;
        if (newspeed < 0.0)
            newspeed = 0.0;
        newspeed /= speed;
        ent.v.velocity[0] *= newspeed;
        ent.v.velocity[1] *= newspeed;
        ent.v.velocity[2] *= newspeed;
    }

    static function Accelerate(wishvel:Vec, air:Bool):Void {
        var ent = player;
        var wishdir = wishvel.copy();
        var wishspeed = Vec.Normalize(wishdir);
        if (air && wishspeed > 30.0)
            wishspeed = 30.0;
        var addspeed = wishspeed - (ent.v.velocity[0] * wishdir[0] + ent.v.velocity[1] * wishdir[1] + ent.v.velocity[2] * wishdir[2]);
        if (addspeed <= 0.0)
            return;
        var accelspeed = accelerate.value * Host.frametime * wishspeed;
        if (accelspeed > addspeed)
            accelspeed = addspeed;
        ent.v.velocity[0] += accelspeed * wishdir[0];
        ent.v.velocity[1] += accelspeed * wishdir[1];
        ent.v.velocity[2] += accelspeed * wishdir[2];
    }

    static function WaterMove():Void {
        var ent = player;
        var cmd = Host.client.cmd;
        var forward = new Vec();
        var right = new Vec();
        Vec.AngleVectors(ent.v.v_angle.copy(), forward, right);
        var wishvel = [
            forward[0] * cmd.forwardmove + right[0] * cmd.sidemove,
            forward[1] * cmd.forwardmove + right[1] * cmd.sidemove,
            forward[2] * cmd.forwardmove + right[2] * cmd.sidemove
        ];
        if (cmd.forwardmove == 0.0 && cmd.sidemove == 0.0 && cmd.upmove == 0.0)
            wishvel[2] -= 60.0;
        else
            wishvel[2] += cmd.upmove;
        var wishspeed = Math.sqrt(wishvel[0] * wishvel[0] + wishvel[1] * wishvel[1] + wishvel[2] * wishvel[2]);
        if (wishspeed > maxspeed.value) {
            var scale = maxspeed.value / wishspeed;
            wishvel[0] *= scale;
            wishvel[1] *= scale;
            wishvel[2] *= scale;
            wishspeed = maxspeed.value;
        }
        wishspeed *= 0.7;
        var speed = Vec.Length(ent.v.velocity);
        var newspeed;
        if (speed != 0.0) {
            newspeed = speed - Host.frametime * speed * friction.value;
            if (newspeed < 0.0)
                newspeed = 0.0;
            var scale = newspeed / speed;
            ent.v.velocity[0] *= scale;
            ent.v.velocity[1] *= scale;
            ent.v.velocity[2] *= scale;
        } else {
            newspeed = 0.0;
        }
        if (wishspeed == 0.0)
            return;
        var addspeed = wishspeed - newspeed;
        if (addspeed <= 0.0)
            return;
        var accelspeed = accelerate.value * wishspeed * Host.frametime;
        if (accelspeed > addspeed)
            accelspeed = addspeed;
        ent.v.velocity[0] += accelspeed * (wishvel[0] / wishspeed);
        ent.v.velocity[1] += accelspeed * (wishvel[1] / wishspeed);
        ent.v.velocity[2] += accelspeed * (wishvel[2] / wishspeed);
    }

    static function WaterJump():Void {
        var ent = player;
        if (server.time > ent.v.teleport_time || ent.v.waterlevel == 0.0) {
            ent.flags &= ~EntFlag.waterjump;
            ent.v.teleport_time = 0.0;
        }
        ent.v.velocity[0] = ent.v.movedir[0];
        ent.v.velocity[1] = ent.v.movedir[1];
    }

    static function AirMove():Void {
        var ent = player;
        var cmd = Host.client.cmd;
        var forward = new Vec();
        var right = new Vec();
        Vec.AngleVectors(ent.v.angles.copy(), forward, right);
        var fmove = cmd.forwardmove;
        var smove = cmd.sidemove;
        if (server.time < ent.v.teleport_time && fmove < 0.0)
            fmove = 0.0;
        var wishvel = Vec.of(
            forward[0] * fmove + right[0] * smove,
            forward[1] * fmove + right[1] * smove,
            (Std.int(ent.v.movetype) != MoveType.walk) ? cmd.upmove : 0.0
        );
        var wishdir = wishvel.copy();
        if (Vec.Normalize(wishdir) > maxspeed.value) {
            wishvel[0] = wishdir[0] * maxspeed.value;
            wishvel[1] = wishdir[1] * maxspeed.value;
            wishvel[2] = wishdir[2] * maxspeed.value;
        }
        if (ent.v.movetype == MoveType.noclip) {
            ent.v.velocity.setVector(wishvel);
        } else if ((ent.flags & EntFlag.onground) != 0) {
            UserFriction();
            Accelerate(wishvel, false);
        } else {
            Accelerate(wishvel, true);
        }
    }

    static function ClientThink():Void {
        var ent = player;

        if (ent.v.movetype == MoveType.none)
            return;

        var punchangle = ent.v.punchangle.copy();
        var len = Vec.Normalize(punchangle) - 10.0 * Host.frametime;
        if (len < 0.0)
            len = 0.0;
        ent.v.punchangle[0] = punchangle[0] * len;
        ent.v.punchangle[1] = punchangle[1] * len;
        ent.v.punchangle[2] = punchangle[2] * len;

        if (ent.v.health <= 0.0)
            return;

        ent.v.angles[2] = V.CalcRoll(ent.v.angles.copy(), ent.v.velocity.copy()) * 4.0;
        if (ent.v.fixangle == 0.0) {
            ent.v.angles[0] = (ent.v.v_angle[0] + ent.v.punchangle[0]) / -3.0;
            ent.v.angles[1] = ent.v.v_angle[1] + ent.v.punchangle[1];
        }

        if ((ent.flags & EntFlag.waterjump) != 0)
            WaterJump();
        else if (ent.v.waterlevel >= 2.0 && ent.v.movetype != MoveType.noclip)
            WaterMove();
        else
            AirMove();
    }

    static function ReadClientMove():Void {
        var client = Host.client;
        client.ping_times[client.num_pings++ & 15] = server.time - MSG.ReadFloat();
        client.edict.v.v_angle[0] = MSG.ReadAngle();
        client.edict.v.v_angle[1] = MSG.ReadAngle();
        client.edict.v.v_angle[2] = MSG.ReadAngle();
        client.cmd.forwardmove = MSG.ReadShort();
        client.cmd.sidemove = MSG.ReadShort();
        client.cmd.upmove = MSG.ReadShort();
        var i = MSG.ReadByte();
        client.edict.v.button0 = i & 1;
        client.edict.v.button2 = (i & 2) >> 1;
        i = MSG.ReadByte();
        if (i != 0)
            client.edict.v.impulse = i;
    }

    static var readClientCmds = [
        'status',
        'god',
        'notarget',
        'fly',
        'name',
        'noclip',
        'say',
        'say_team',
        'tell',
        'color',
        'kill',
        'pause',
        'spawn',
        'begin',
        'prespawn',
        'kick',
        'ping',
        'give',
        'ban'
    ];

    static function ReadClientMessage():Bool {
        var ret;
        do
        {
            ret = NET.GetMessage(Host.client.netconnection);
            if (ret == -1) {
                Sys.Print('SV.ReadClientMessage: NET.GetMessage failed\n');
                return false;
            }
            if (ret == 0)
                return true;
            MSG.BeginReading();
            while (true) {
                if (!Host.client.active)
                    return false;
                if (MSG.badread) {
                    Sys.Print('SV.ReadClientMessage: badread\n');
                    return false;
                }
                var cmd = MSG.ReadChar();
                if (cmd == -1) {
                    ret = 1;
                    break;
                }
                if (cmd == CLC.nop)
                    continue;
                if (cmd == CLC.stringcmd) {
                    var s = MSG.ReadString();
                    var i = 0;
                    while (i < readClientCmds.length) {
                        if (s.substring(0, readClientCmds[i].length).toLowerCase() != readClientCmds[i]) {
                            i++;
                            continue;
                        }
                        Cmd.ExecuteString(s, true);
                        break;
                    }
                    if (i == readClientCmds.length)
                        Console.DPrint(GetClientName(Host.client) + ' tried to ' + s);
                } else if (cmd == CLC.disconnect) {
                    return false;
                } else if (cmd == CLC.move) {
                    ReadClientMove();
                } else {
                    Sys.Print('SV.ReadClientMessage: unknown command char\n');
                    return false;
                }
            }
        } while (ret == 1);
        return false;
    }

    static function RunClients():Void {
        for (i in 0...svs.maxclients) {
            Host.client = svs.clients[i];
            if (!Host.client.active)
                continue;
            player = Host.client.edict;
            if (!ReadClientMessage()) {
                Host.DropClient(false);
                continue;
            }
            if (!Host.client.spawned) {
                Host.client.cmd.forwardmove = 0.0;
                Host.client.cmd.sidemove = 0.0;
                Host.client.cmd.upmove = 0.0;
                continue;
            }
            ClientThink();
        }
    }

    // world

    static function InitBoxHull():Void {
        box_clipnodes = [];
        box_planes = [];
        box_hull = new Hull();

        box_hull.clipnodes = box_clipnodes;
        box_hull.planes = box_planes;
        box_hull.firstclipnode = 0;
        box_hull.lastclipnode = 5;

        for (i in 0...6) {
            var side = i & 1;

            var node = new ClipNode();
            node.planenum = i;

            if (side == 0)
                node.child0 = Contents.empty;
            else
                node.child1 = Contents.empty;

            if (i != 5) {
                if (side == 0)
                    node.child1 = i + 1;
                else
                    node.child0 = i + 1;
            } else {
                if (side == 0)
                    node.child1 = Contents.solid;
                else
                    node.child0 = Contents.solid;
            }
            box_clipnodes.push(node);

            var plane = new Plane();
            plane.type = i >> 1;
            plane.normal[i >> 1] = 1.0;
            plane.dist = 0.0;
            box_planes.push(plane);
        }
    }

    static function HullForEntity(ent:Edict, mins:Vec, maxs:Vec, offset:Vec):Hull {
        if (ent.v.solid != SolidType.bsp) {
            box_planes[0].dist = ent.v.maxs[0] - mins[0];
            box_planes[1].dist = ent.v.mins[0] - maxs[0];
            box_planes[2].dist = ent.v.maxs[1] - mins[1];
            box_planes[3].dist = ent.v.mins[1] - maxs[1];
            box_planes[4].dist = ent.v.maxs[2] - mins[2];
            box_planes[5].dist = ent.v.mins[2] - maxs[2];
            offset.setVector(ent.v.origin);
            return box_hull;
        }
        if (ent.v.movetype != MoveType.push)
            Sys.Error('SOLID_BSP without MOVETYPE_PUSH');
        var model = server.models[Std.int(ent.v.modelindex)];
        if (model == null)
            Sys.Error('MOVETYPE_PUSH with a non bsp model');
        if (model.type != brush)
            Sys.Error('MOVETYPE_PUSH with a non bsp model');
        var size = maxs[0] - mins[0];
        var hull;
        if (size < 3.0)
            hull = model.hulls[0];
        else if (size <= 32.0)
            hull = model.hulls[1];
        else
            hull = model.hulls[2];
        offset.setValues(
            hull.clip_mins[0] - mins[0] + ent.v.origin[0],
            hull.clip_mins[1] - mins[1] + ent.v.origin[1],
            hull.clip_mins[2] - mins[2] + ent.v.origin[2]
        );
        return hull;
    }

    static function CreateAreaNode(depth:Int, mins:Vec, maxs:Vec):AreaNode {
        var anode = new AreaNode();
        areanodes.push(anode);

        anode.trigger_edicts = new EdictLink();
        anode.trigger_edicts.prev = anode.trigger_edicts.next = anode.trigger_edicts;
        anode.solid_edicts = new EdictLink();
        anode.solid_edicts.prev = anode.solid_edicts.next = anode.solid_edicts;

        if (depth == 4) {
            anode.axis = -1;
            anode.children = [];
            return anode;
        }

        anode.axis = (maxs[0] - mins[0]) > (maxs[1] - mins[1]) ? 0 : 1;
        anode.dist = 0.5 * (maxs[anode.axis] + mins[anode.axis]);

        var maxs1 = maxs.copy();
        var mins2 = mins.copy();
        maxs1[anode.axis] = mins2[anode.axis] = anode.dist;
        anode.children = [CreateAreaNode(depth + 1, mins2, maxs), CreateAreaNode(depth + 1, mins, maxs1)];
        return anode;
    }

    static function UnlinkEdict(ent:Edict) {
        if (ent.area.prev != null)
            ent.area.prev.next = ent.area.next;
        if (ent.area.next != null)
            ent.area.next.prev = ent.area.prev;
        ent.area.prev = ent.area.next = null;
    }

    static function TouchLinks(ent:Edict, node:AreaNode):Void {
        var l = node.trigger_edicts.next;
        while (l != node.trigger_edicts) {
            var touch = l.ent;
            l = l.next;
            if (touch == ent)
                continue;
            if (touch.v.touch == 0 || touch.v.solid != SolidType.trigger)
                continue;
            if (ent.v.absmin[0] > touch.v.absmax[0] || ent.v.absmin[1] > touch.v.absmax[1] || ent.v.absmin[2] > touch.v.absmax[2] ||
                ent.v.absmax[0] < touch.v.absmin[0] || ent.v.absmax[1] < touch.v.absmin[1] || ent.v.absmax[2] < touch.v.absmin[2])
                continue;
            var old_self = PR.globals.self;
            var old_other = PR.globals.other;
            PR.globals.self = touch.num;
            PR.globals.other = ent.num;
            PR.globals.time = server.time;
            PR.ExecuteProgram(touch.v.touch);
            PR.globals.self = old_self;
            PR.globals.other = old_other;
        }
        if (node.axis == -1)
            return;
        if (ent.v.absmax[node.axis] > node.dist)
            TouchLinks(ent, node.children[0]);
        if (ent.v.absmin[node.axis] < node.dist)
            TouchLinks(ent, node.children[1]);
    }

    static function FindTouchedLeafs(ent:Edict, node:Node):Void {
        if (node.contents == Contents.solid)
            return;

        if (node.contents < 0) {
            if (ent.leafnums.length == 16)
                return;
            ent.leafnums.push(node.num - 1);
            return;
        }

        var sides = Vec.BoxOnPlaneSide(ent.v.absmin, ent.v.absmax, node.plane);
        if ((sides & 1) != 0)
            FindTouchedLeafs(ent, node.child0);
        if ((sides & 2) != 0)
            FindTouchedLeafs(ent, node.child1);
    }

    static function LinkEdict(ent:Edict, touch_triggers:Bool):Void {
        if (ent.free || ent == server.edicts[0])
            return;

        UnlinkEdict(ent);

        ent.v.absmin.setValues(
            ent.v.origin[0] + ent.v.mins[0] - 1.0,
            ent.v.origin[1] + ent.v.mins[1] - 1.0,
            ent.v.origin[2] + ent.v.mins[2]
        );
        ent.v.absmax.setValues(
            ent.v.origin[0] + ent.v.maxs[0] + 1.0,
            ent.v.origin[1] + ent.v.maxs[1] + 1.0,
            ent.v.origin[2] + ent.v.maxs[2]
        );

        if ((ent.flags & EntFlag.item) != 0) {
            ent.v.absmin[0] -= 14.0;
            ent.v.absmin[1] -= 14.0;
            ent.v.absmax[0] += 14.0;
            ent.v.absmax[1] += 14.0;
        } else {
            ent.v.absmin[2] -= 1.0;
            ent.v.absmax[2] += 1.0;
        }

        ent.leafnums = [];
        if (ent.v.modelindex != 0)
            FindTouchedLeafs(ent, server.worldmodel.nodes[0]);

        if (ent.v.solid == SolidType.not)
            return;

        var node = areanodes[0];
        while (true) {
            if (node.axis == -1)
                break;
            if (ent.v.absmin[node.axis] > node.dist)
                node = node.children[0];
            else if (ent.v.absmax[node.axis] < node.dist)
                node = node.children[1];
            else
                break;
        }

        var before = (ent.v.solid == SolidType.trigger) ? node.trigger_edicts : node.solid_edicts;
        ent.area.next = before;
        ent.area.prev = before.prev;
        ent.area.prev.next = ent.area;
        ent.area.next.prev = ent.area;
        ent.area.ent = ent;

        if (touch_triggers)
            TouchLinks(ent, areanodes[0]);
    }

    static function HullPointContents(hull:Hull, num:Int, p:Vec):Contents {
        while (num >= 0) {
            if (num < hull.firstclipnode || num > hull.lastclipnode)
                Sys.Error('SV.HullPointContents: bad node number');
            var node = hull.clipnodes[num];
            var plane = hull.planes[node.planenum];
            var d;
            if (plane.type <= 2)
                d = p[plane.type] - plane.dist;
            else
                d = plane.normal[0] * p[0] + plane.normal[1] * p[1] + plane.normal[2] * p[2] - plane.dist;
            if (d >= 0.0)
                num = node.child0;
            else
                num = node.child1;
        }
        return num;
    }

    static function PointContents(p:Vec):Contents {
        var cont = HullPointContents(server.worldmodel.hulls[0], 0, p);
        if (cont <= Contents.current_0 && cont >= Contents.current_down)
            return Contents.water;
        return cont;
    }

    static function TestEntityPosition(ent:Edict):Bool {
        var origin = ent.v.origin.copy();
        return Move(origin, ent.v.mins.copy(), ent.v.maxs.copy(), origin, 0, ent).startsolid;
    }

    static function RecursiveHullCheck(hull:Hull, num:Int, p1f:Float, p2f:Float, p1:Vec, p2:Vec, trace:Trace):Bool {
        if (num < 0) {
            if (num != Contents.solid) {
                trace.allsolid = false;
                if (num == Contents.empty)
                    trace.inopen = true;
                else
                    trace.inwater = true;
            } else {
                trace.startsolid = true;
            }
            return true;
        }

        if (num < hull.firstclipnode || num > hull.lastclipnode)
            Sys.Error('SV.RecursiveHullCheck: bad node number');

        var node = hull.clipnodes[num];
        var plane = hull.planes[node.planenum];
        var t1, t2;

        if (plane.type <= 2) {
            t1 = p1[plane.type] - plane.dist;
            t2 = p2[plane.type] - plane.dist;
        } else {
            t1 = plane.normal[0] * p1[0] + plane.normal[1] * p1[1] + plane.normal[2] * p1[2] - plane.dist;
            t2 = plane.normal[0] * p2[0] + plane.normal[1] * p2[1] + plane.normal[2] * p2[2] - plane.dist;
        }

        if (t1 >= 0.0 && t2 >= 0.0)
            return RecursiveHullCheck(hull, node.child0, p1f, p2f, p1, p2, trace);
        if (t1 < 0.0 && t2 < 0.0)
            return RecursiveHullCheck(hull, node.child1, p1f, p2f, p1, p2, trace);

        var frac = (t1 + (t1 < 0.0 ? 0.03125 : -0.03125)) / (t1 - t2);
        if (frac < 0.0)
            frac = 0.0;
        else if (frac > 1.0)
            frac = 1.0;

        var midf = p1f + (p2f - p1f) * frac;
        var mid = Vec.of(
            p1[0] + frac * (p2[0] - p1[0]),
            p1[1] + frac * (p2[1] - p1[1]),
            p1[2] + frac * (p2[2] - p1[2])
        );
        var side = t1 < 0.0;

        if (!RecursiveHullCheck(hull, side ? node.child1 : node.child0, p1f, midf, p1, mid, trace))
            return false;

        if (HullPointContents(hull, side ? node.child0 : node.child1, mid) != Contents.solid)
            return RecursiveHullCheck(hull, side ? node.child0 : node.child1, midf, p2f, mid, p2, trace);

        if (trace.allsolid)
            return false;

        if (!side) {
            trace.plane.normal.setVector(plane.normal);
            trace.plane.dist = plane.dist;
        } else {
            trace.plane.normal.setValues(-plane.normal[0], -plane.normal[1], -plane.normal[2]);
            trace.plane.dist = -plane.dist;
        }

        while (HullPointContents(hull, hull.firstclipnode, mid) == Contents.solid) {
            frac -= 0.1;
            if (frac < 0.0) {
                trace.fraction = midf;
                trace.endpos.setVector(mid);
                Console.DPrint('backup past 0\n');
                return false;
            }
            midf = p1f + (p2f - p1f) * frac;
            mid[0] = p1[0] + frac * (p2[0] - p1[0]);
            mid[1] = p1[1] + frac * (p2[1] - p1[1]);
            mid[2] = p1[2] + frac * (p2[2] - p1[2]);
        }

        trace.fraction = midf;
        trace.endpos.setVector(mid);
        return false;
    }

    static function ClipMoveToEntity(ent:Edict, start:Vec, mins:Vec, maxs:Vec, end:Vec):Trace {
        var trace = new Trace();
        trace.fraction = 1.0;
        trace.allsolid = true;
        trace.endpos.setVector(end);

        var offset = new Vec();
        var hull = HullForEntity(ent, mins, maxs, offset);
        RecursiveHullCheck(hull, hull.firstclipnode, 0.0, 1.0,
                           Vec.of(start[0] - offset[0], start[1] - offset[1], start[2] - offset[2]),
                           Vec.of(end[0] - offset[0], end[1] - offset[1], end[2] - offset[2]),
                           trace);
        if (trace.fraction != 1.0) {
            trace.endpos[0] += offset[0];
            trace.endpos[1] += offset[1];
            trace.endpos[2] += offset[2];
        }
        if (trace.fraction < 1.0 || trace.startsolid)
            trace.ent = ent;
        return trace;
    }

    static function ClipToLinks(node:AreaNode, clip:MoveClip):Void {
        var l = node.solid_edicts.next;
        while (l != node.solid_edicts) {
            var touch = l.ent;
            l = l.next;
            var solid = touch.v.solid;
            if (solid == SolidType.not || touch == clip.passedict)
                continue;
            if (solid == SolidType.trigger)
                Sys.Error('Trigger in clipping list');
            if (clip.type == ClipType.nomonsters && solid != SolidType.bsp)
                continue;
            if (clip.boxmins[0] > touch.v.absmax[0] || clip.boxmins[1] > touch.v.absmax[1] || clip.boxmins[2] > touch.v.absmax[2] ||
                clip.boxmaxs[0] < touch.v.absmin[0] || clip.boxmaxs[1] < touch.v.absmin[1] || clip.boxmaxs[2] < touch.v.absmin[2])
                continue;
            if (clip.passedict != null) {
                if (clip.passedict.v.size[0] != 0.0 && touch.v.size[0] == 0.0)
                    continue;
            }
            if (clip.trace.allsolid)
                return;
            if (clip.passedict != null) {
                if (server.edicts[touch.v.owner] == clip.passedict)
                    continue;
                if (server.edicts[clip.passedict.v.owner] == touch)
                    continue;
            }
            var trace;
            if ((touch.flags & EntFlag.monster) != 0)
                trace = ClipMoveToEntity(touch, clip.start, clip.mins2, clip.maxs2, clip.end);
            else
                trace = ClipMoveToEntity(touch, clip.start, clip.mins, clip.maxs, clip.end);
            if (trace.allsolid || trace.startsolid || trace.fraction < clip.trace.fraction) {
                trace.ent = touch;
                clip.trace = trace;
                if (trace.startsolid)
                    clip.trace.startsolid = true;
            }
        }
        if (node.axis == -1)
            return;
        if (clip.boxmaxs[node.axis] > node.dist)
            ClipToLinks(node.children[0], clip);
        if (clip.boxmins[node.axis] < node.dist)
            ClipToLinks(node.children[1], clip);
    }

    static function Move(start:Vec, mins:Vec, maxs:Vec, end:Vec, type:Int, passedict:Edict):Trace {
        var clip = new MoveClip();
        clip.trace = ClipMoveToEntity(server.edicts[0], start, mins, maxs, end);
        clip.start = start;
        clip.end = end;
        clip.mins = mins;
        clip.maxs = maxs;
        clip.type = type;
        clip.passedict = passedict;
        clip.boxmins = new Vec();
        clip.boxmaxs = new Vec();
        if (type == ClipType.missile) {
            clip.mins2 = Vec.of(-15.0, -15.0, -15.0);
            clip.maxs2 = Vec.of(15.0, 15.0, 15.0);
        } else {
            clip.mins2 = mins.copy();
            clip.maxs2 = maxs.copy();
        }
        for (i in 0...3) {
            if (end[i] > start[i]) {
                clip.boxmins[i] = start[i] + clip.mins2[i] - 1.0;
                clip.boxmaxs[i] = end[i] + clip.maxs2[i] + 1.0;
                continue;
            }
            clip.boxmins[i] = end[i] + clip.mins2[i] - 1.0;
            clip.boxmaxs[i] = start[i] + clip.maxs2[i] + 1.0;
        }
        ClipToLinks(areanodes[0], clip);
        return clip.trace;
    }
}
