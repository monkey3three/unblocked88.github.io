package quake;

import quake.Protocol.SVC;
import quake.SV.EntFlag;
import quake.SV.DamageType;
import quake.SV.SolidType;
import quake.PR.PROffset;
using Tools;

class PF {

    static var argc:Int;

    public static inline function call(argc:Int, idx:Int):Void {
        if (idx >= builtin.length)
            PR.RunError('Bad builtin call number');
        PF.argc = argc;
        builtin[idx]();
    }

    static function VarString(first:Int) {
        var out = '';
        for (i in first...argc)
            out += PR.GetString(PR.globals.ints[OFS_PARM0 + i * 3]);
        return out;
    }

    static function error() {
        Console.Print('====SERVER ERROR in ' + PR.GetString(PR.xfunction.name) + '\n' + VarString(0) + '\n');
        ED.Print(SV.server.edicts[PR.globals.self]);
        Host.Error('Program error');
    }

    static function objerror() {
        Console.Print('====OBJECT ERROR in ' + PR.GetString(PR.xfunction.name) + '\n' + VarString(0) + '\n');
        ED.Print(SV.server.edicts[PR.globals.self]);
        Host.Error('Program error');
    }

    static function makevectors():Void {
        Vec.AngleVectors(PR.globals.GetVector(OFS_PARM0), PR.globals.v_forward, PR.globals.v_right, PR.globals.v_up);
    }

    static function setorigin():Void {
        var e = SV.server.edicts[PR.globals.ints[OFS_PARM0]];
        e.v.origin.setValues(
            PR.globals.floats[OFS_PARM1],
            PR.globals.floats[OFS_PARM1 + 1],
            PR.globals.floats[OFS_PARM1 + 2]
        );
        SV.LinkEdict(e, false);
    }

    static function SetMinMaxSize(e:Edict, min:Vec, max:Vec):Void {
        if ((min[0] > max[0]) || (min[1] > max[1]) || (min[2] > max[2]))
            PR.RunError('backwards mins/maxs');
        e.v.mins.setVector(min);
        e.v.maxs.setVector(max);
        e.v.size.setValues(max[0] - min[0], max[1] - min[1], max[2] - min[2]);
        SV.LinkEdict(e, false);
    }

    static function setsize():Void {
        SetMinMaxSize(
            SV.server.edicts[PR.globals.ints[OFS_PARM0]],
            PR.globals.GetVector(OFS_PARM1),
            PR.globals.GetVector(OFS_PARM2)
        );
    }

    static function setmodel():Void {
        var e = SV.server.edicts[PR.globals.ints[OFS_PARM0]];
        var m = PR.GetString(PR.globals.ints[OFS_PARM1]);
        var i = 0;
        while (i < SV.server.model_precache.length) {
            if (SV.server.model_precache[i] == m)
                break;
            i++;
        }
        if (i == SV.server.model_precache.length)
            PR.RunError('no precache: ' + m + '\n');

        e.v.model = PR.globals.ints[OFS_PARM1];
        e.v.modelindex = i;
        var mod = SV.server.models[i];
        if (mod != null)
            SetMinMaxSize(e, mod.mins, mod.maxs);
        else
            SetMinMaxSize(e, Vec.origin, Vec.origin);
    }

    static function bprint():Void {
        Host.BroadcastPrint(VarString(0));
    }

    static function sprint():Void {
        var entnum = PR.globals.ints[OFS_PARM0];
        if (entnum <= 0 || entnum > SV.svs.maxclients) {
            Console.Print('tried to sprint to a non-client\n');
            return;
        }
        var client = SV.svs.clients[entnum - 1];
        client.message.WriteByte(SVC.print);
        client.message.WriteString(VarString(1));
    }

    static function centerprint():Void {
        var entnum = PR.globals.ints[OFS_PARM0];
        if (entnum <= 0 || entnum > SV.svs.maxclients) {
            Console.Print('tried to sprint to a non-client\n');
            return;
        }
        var client = SV.svs.clients[entnum - 1];
        client.message.WriteByte(SVC.centerprint);
        client.message.WriteString(VarString(1));
    }

    static function normalize():Void {
        var newvalue = PR.globals.GetVector(OFS_PARM0);
        Vec.Normalize(newvalue);
        PR.globals.SetReturnVector(newvalue);
    }

    static function vlen():Void {
        PR.globals.SetReturnFloat(Math.sqrt(PR.globals.floats[OFS_PARM0] * PR.globals.floats[OFS_PARM0] + PR.globals.floats[OFS_PARM0 + 1] * PR.globals.floats[OFS_PARM0 + 1] + PR.globals.floats[OFS_PARM0 + 2] * PR.globals.floats[OFS_PARM0 + 2]));
    }

    static function vectoyaw() {
        var value1 = PR.globals.floats[4], value2 = PR.globals.floats[5];
        if ((value1 == 0.0) && (value2 == 0.0)) {
            PR.globals.floats[OFS_RETURN] = 0.0;
            return;
        }
        var yaw = Std.int(Math.atan2(value2, value1) * 180.0 / Math.PI);
        if (yaw < 0)
            yaw += 360;
        PR.globals.floats[OFS_RETURN] = yaw;
    }

    static function vectoangles() {
        PR.globals.floats[OFS_RETURN + 2] = 0.0;
        var value1 = [PR.globals.floats[4], PR.globals.floats[5], PR.globals.floats[6]];
        if ((value1[0] == 0.0) && (value1[1] == 0.0)) {
            if (value1[2] > 0.0)
                PR.globals.floats[OFS_RETURN] = 90.0;
            else
                PR.globals.floats[OFS_RETURN] = 270.0;
            PR.globals.floats[OFS_RETURN + 1] = 0.0;
            return;
        }

        var yaw = Std.int(Math.atan2(value1[1], value1[0]) * 180.0 / Math.PI);
        if (yaw < 0)
            yaw += 360;
        var pitch = Std.int(Math.atan2(value1[2], Math.sqrt(value1[0] * value1[0] + value1[1] * value1[1])) * 180.0 / Math.PI);
        if (pitch < 0)
            pitch += 360;
        PR.globals.floats[OFS_RETURN] = pitch;
        PR.globals.floats[OFS_RETURN + 1] = yaw;
    }

    static function random() {
        PR.globals.SetReturnFloat(Math.random());
    }

    static function particle() {
        SV.StartParticle(
            PR.globals.GetVector(OFS_PARM0),
            PR.globals.GetVector(OFS_PARM1),
            Std.int(PR.globals.GetFloat(OFS_PARM2)),
            Std.int(PR.globals.GetFloat(OFS_PARM3))
        );
    }

    static function ambientsound() {
        var samp = PR.GetString(PR.globals.ints[7]);
        var i = 0;
        while (i < SV.server.sound_precache.length) {
            if (SV.server.sound_precache[i] == samp)
                break;
            i++;
        }
        if (i == SV.server.sound_precache.length) {
            Console.Print('no precache: ' + samp + '\n');
            return;
        }
        var signon = SV.server.signon;
        signon.WriteByte(SVC.spawnstaticsound);
        signon.WriteCoord(PR.globals.floats[4]);
        signon.WriteCoord(PR.globals.floats[5]);
        signon.WriteCoord(PR.globals.floats[6]);
        signon.WriteByte(i);
        signon.WriteByte(Std.int(PR.globals.floats[10] * 255));
        signon.WriteByte(Std.int(PR.globals.floats[13] * 64));
    }

    static function sound() {
        SV.StartSound(SV.server.edicts[PR.globals.ints[4]],
            Std.int(PR.globals.floats[7]),
            PR.GetString(PR.globals.ints[10]),
            Std.int(PR.globals.floats[13] * 255),
            PR.globals.floats[16]);
    }

    static function breakstatement() {
        Console.Print('break statement\n');
    }

    static function traceline() {
        var trace = SV.Move(Vec.of(PR.globals.floats[4], PR.globals.floats[5], PR.globals.floats[6]),
            Vec.origin, Vec.origin, Vec.of(PR.globals.floats[7], PR.globals.floats[8], PR.globals.floats[9]),
            Std.int(PR.globals.floats[10]), SV.server.edicts[PR.globals.ints[13]]);
        PR.globals.trace_allsolid = (trace.allsolid) ? 1.0 : 0.0;
        PR.globals.trace_startsolid = (trace.startsolid) ? 1.0 : 0.0;
        PR.globals.trace_fraction = trace.fraction;
        PR.globals.trace_inwater = (trace.inwater) ? 1.0 : 0.0;
        PR.globals.trace_inopen = (trace.inopen) ? 1.0 : 0.0;
        PR.globals.trace_endpos.setVector(trace.endpos);
        var plane = trace.plane;
        PR.globals.trace_plane_normal.setVector(plane.normal);
        PR.globals.trace_plane_dist = plane.dist;
        PR.globals.trace_ent = (trace.ent != null) ? trace.ent.num : 0;
    }

    static function newcheckclient(check:Int):Int {
        if (check <= 0)
            check = 1;
        else if (check > SV.svs.maxclients)
            check = SV.svs.maxclients;
        var i = 1;
        if (check != SV.svs.maxclients)
            i += check;
        var ent = null;
        while (true) {
            if (i == SV.svs.maxclients + 1)
                i = 1;
            ent = SV.server.edicts[i];
            if (i == check)
                break;
            if (ent.free) {
                i++;
                continue;
            }
            if ((ent.v.health <= 0.0) || ((ent.flags & EntFlag.notarget) != 0)) {
                i++;
                continue;
            }
            break;
        }
        checkpvs = Mod_Brush.LeafPVS(Mod_Brush.PointInLeaf(Vec.Add(ent.v.origin, ent.v.view_ofs), SV.server.worldmodel), SV.server.worldmodel);
        return i;
    }

    static var checkpvs:Array<Int>;

    static function checkclient() {
        if ((SV.server.time - SV.server.lastchecktime) >= 0.1) {
            SV.server.lastcheck = newcheckclient(SV.server.lastcheck);
            SV.server.lastchecktime = SV.server.time;
        }
        var ent = SV.server.edicts[SV.server.lastcheck];
        if ((ent.free) || (ent.v.health <= 0.0)) {
            PR.globals.ints[OFS_RETURN] = 0;
            return;
        }
        var self = SV.server.edicts[PR.globals.self];
        var l = Mod_Brush.PointInLeaf(Vec.Add(self.v.origin, self.v.view_ofs), SV.server.worldmodel).num - 1;
        if ((l < 0) || ((checkpvs[l >> 3] & (1 << (l & 7))) == 0)) {
            PR.globals.ints[OFS_RETURN] = 0;
            return;
        }
        PR.globals.ints[OFS_RETURN] = ent.num;
    }

    static function stuffcmd() {
        var entnum = PR.globals.ints[4];
        if ((entnum <= 0) || (entnum > SV.svs.maxclients))
            PR.RunError('Parm 0 not a client');
        var client = SV.svs.clients[entnum - 1];
        client.message.WriteByte(SVC.stufftext);
        client.message.WriteString(PR.GetString(PR.globals.ints[7]));
    }

    static function localcmd() {
        Cmd.text += PR.GetString(PR.globals.ints[4]);
    }

    static function cvar() {
        var v = Cvar.FindVar(PR.GetString(PR.globals.ints[4]));
        PR.globals.floats[OFS_RETURN] = v != null ? v.value : 0.0;
    }

    static function cvar_set() {
        Cvar.Set(PR.GetString(PR.globals.ints[4]), PR.GetString(PR.globals.ints[7]));
    }

    static function findradius() {
        var chain = 0;
        var org = [PR.globals.floats[4], PR.globals.floats[5], PR.globals.floats[6]], eorg = [];
        var rad = PR.globals.floats[7];
        for (i in 1...SV.server.num_edicts) {
            var ent = SV.server.edicts[i];
            if (ent.free)
                continue;
            if (ent.v.solid == SolidType.not)
                continue;
            eorg[0] = org[0] - (ent.v.origin[0] + (ent.v.mins[0] + ent.v.maxs[0]) * 0.5);
            eorg[1] = org[1] - (ent.v.origin[1] + (ent.v.mins[1] + ent.v.maxs[1]) * 0.5);
            eorg[2] = org[2] - (ent.v.origin[2] + (ent.v.mins[2] + ent.v.maxs[2]) * 0.5);
            if (Math.sqrt(eorg[0] * eorg[0] + eorg[1] * eorg[1] + eorg[2] * eorg[2]) > rad)
                continue;
            ent.v.chain = chain;
            chain = i;
        }
        PR.globals.ints[OFS_RETURN] = chain;
    }

    static function dprint() {
        Console.DPrint(VarString(0));
    }

    static function ftos() {
        var v = PR.globals.floats[4];
        if (v == Math.floor(v))
            PR.TempString(Std.string(v));
        else
            PR.TempString(v.toFixed(1));
        PR.globals.ints[OFS_RETURN] = PR.string_temp;
    }

    static function fabs() {
        PR.globals.SetReturnFloat(Math.abs(PR.globals.floats[4]));
    }

    static function vtos() {
        PR.TempString(PR.globals.floats[4].toFixed(1)
            + ' ' + PR.globals.floats[5].toFixed(1)
            + ' ' + PR.globals.floats[6].toFixed(1));
        PR.globals.ints[OFS_RETURN] = PR.string_temp;
    }

    static function Spawn() {
        PR.globals.SetReturnInt(ED.Alloc().num);
    }

    static function Remove() {
        ED.Free(SV.server.edicts[PR.globals.ints[4]]);
    }

    static function Find() {
        var e = PR.globals.ints[4];
        var f = PR.globals.ints[7];
        var s = PR.GetString(PR.globals.ints[10]);
        for (e in (e + 1)...SV.server.num_edicts) {
            var ed = SV.server.edicts[e];
            if (ed.free)
                continue;
            if (PR.GetString(ed.v.ints[f]) == s) {
                PR.globals.ints[OFS_RETURN] = ed.num;
                return;
            }
        }
        PR.globals.ints[OFS_RETURN] = 0;
    }

    static function MoveToGoal() {
        var ent = SV.server.edicts[PR.globals.self];
        if ((ent.flags & (EntFlag.onground + EntFlag.fly + EntFlag.swim)) == 0) {
            PR.globals.floats[OFS_RETURN] = 0.0;
            return;
        }
        var goal = SV.server.edicts[ent.v.goalentity];
        var dist = PR.globals.floats[4];
        if ((ent.v.enemy != 0) && (SV.CloseEnough(ent, goal, dist)))
            return;
        if ((Math.random() >= 0.75) || !SV.StepDirection(ent, ent.v.ideal_yaw, dist))
            SV.NewChaseDir(ent, goal, dist);
    }

    static function precache_file() {
        PR.globals.ints[OFS_RETURN] = PR.globals.ints[4];
    }

    static function precache_sound() {
        var s = PR.GetString(PR.globals.ints[4]);
        PR.globals.ints[OFS_RETURN] = PR.globals.ints[4];
        PR.CheckEmptyString(s);
        var i = 0;
        while (i < SV.server.sound_precache.length) {
            if (SV.server.sound_precache[i] == s)
                return;
            i++;
        }
        SV.server.sound_precache[i] = s;
    }

    static function precache_model() {
        if (!SV.server.loading)
            PR.RunError('Precache_*: Precache can only be done in spawn functions');
        var s = PR.GetString(PR.globals.ints[4]);
        PR.globals.ints[OFS_RETURN] = PR.globals.ints[4];
        PR.CheckEmptyString(s);
        var i = 0;
        while (i < SV.server.model_precache.length) {
            if (SV.server.model_precache[i] == s)
                return;
            i++;
        }
        SV.server.model_precache[i] = s;
        SV.server.models[i] = Mod.ForName(s, true);
    }

    static function coredump() {
        ED.PrintEdicts();
    }

    static function traceon() {
        PR.trace = true;
    }

    static function traceoff() {
        PR.trace = false;
    }

    static function eprint() {
        ED.Print(SV.server.edicts[Std.int(PR.globals.floats[4])]);
    }

    static function walkmove() {
        var ent = SV.server.edicts[PR.globals.self];
        if ((ent.flags & (EntFlag.onground + EntFlag.fly + EntFlag.swim)) == 0) {
            PR.globals.floats[OFS_RETURN] = 0.0;
            return;
        }
        var yaw = PR.globals.floats[4] * Math.PI / 180.0;
        var dist = PR.globals.floats[7];
        var oldf = PR.xfunction;
        var moved = SV.movestep(ent, Vec.of(Math.cos(yaw) * dist, Math.sin(yaw) * dist, 0), true);
        PR.globals.floats[OFS_RETURN] = if (moved) 1 else 0;
        PR.xfunction = oldf;
        PR.globals.self = ent.num;
    }

    static function droptofloor() {
        var ent = SV.server.edicts[PR.globals.self];
        var trace = SV.Move(ent.v.origin.copy(), ent.v.mins.copy(), ent.v.maxs.copy(),
            Vec.of(ent.v.origin[0], ent.v.origin[1], ent.v.origin[2] - 256.0), 0, ent);
        if ((trace.fraction == 1.0) || (trace.allsolid)) {
            PR.globals.floats[OFS_RETURN] = 0.0;
            return;
        }
        ent.v.origin.setVector(trace.endpos);
        SV.LinkEdict(ent, false);
        ent.flags = ent.flags | EntFlag.onground;
        ent.v.groundentity = trace.ent.num;
        PR.globals.floats[OFS_RETURN] = 1.0;
    }

    static function lightstyle() {
        var style = Std.int(PR.globals.floats[4]);
        var val = PR.GetString(PR.globals.ints[7]);
        SV.server.lightstyles[style] = val;
        if (SV.server.loading)
            return;
        for (i in 0...SV.svs.maxclients) {
            var client = SV.svs.clients[i];
            if (!client.active && !client.spawned)
                continue;
            client.message.WriteByte(SVC.lightstyle);
            client.message.WriteByte(style);
            client.message.WriteString(val);
        }
    }

    static function rint() {
        var f = PR.globals.floats[4];
        PR.globals.floats[OFS_RETURN] = Std.int(f >= 0.0 ? f + 0.5 : f - 0.5);
    }

    static function floor() {
        PR.globals.floats[OFS_RETURN] = Math.floor(PR.globals.floats[4]);
    }

    static function ceil() {
        PR.globals.floats[OFS_RETURN] = Math.ceil(PR.globals.floats[4]);
    }

    static function checkbottom() {
        var res = SV.CheckBottom(SV.server.edicts[PR.globals.ints[4]]);
        PR.globals.floats[OFS_RETURN] = if (res) 1 else 0;
    }

    static function pointcontents() {
        PR.globals.floats[OFS_RETURN] = SV.PointContents(Vec.of(PR.globals.floats[4], PR.globals.floats[5], PR.globals.floats[6]));
    }

    static function nextent() {
        for (i in (PR.globals.ints[OFS_PARM0] + 1)...SV.server.num_edicts) {
            if (!SV.server.edicts[i].free) {
                PR.globals.ints[OFS_RETURN] = i;
                return;
            }
        }
        PR.globals.ints[OFS_RETURN] = 0;
    }

    static function aim() {
        var ent = SV.server.edicts[PR.globals.ints[OFS_PARM0]];
        var start = Vec.of(ent.v.origin[0], ent.v.origin[1], ent.v.origin[2] + 20.0);
        var dir = PR.globals.v_forward.copy();
        var end = Vec.of(start[0] + 2048.0 * dir[0], start[1] + 2048.0 * dir[1], start[2] + 2048.0 * dir[2]);
        var tr = SV.Move(start, Vec.origin, Vec.origin, end, 0, ent);
        if (tr.ent != null) {
            if ((tr.ent.v.takedamage == DamageType.aim) &&
                ((Host.teamplay.value == 0) || (ent.v.team <= 0) ||
                (ent.v.team != tr.ent.v.team))) {
                PR.globals.SetReturnVector(dir);
                return;
            }
        }
        var bestdir = dir.copy();
        var bestdist = SV.aim.value;
        var bestent = null, end = new Vec();
        for (i in 1...SV.server.num_edicts) {
            var check = SV.server.edicts[i];
            if (check.v.takedamage != DamageType.aim)
                continue;
            if (check == ent)
                continue;
            if ((Host.teamplay.value != 0) && (ent.v.team > 0) && (ent.v.team == check.v.team))
                continue;
            end[0] = check.v.origin[0] + 0.5 * (check.v.mins[0] + check.v.maxs[0]);
            end[1] = check.v.origin[1] + 0.5 * (check.v.mins[1] + check.v.maxs[1]);
            end[2] = check.v.origin[2] + 0.5 * (check.v.mins[2] + check.v.maxs[2]);
            dir[0] = end[0] - start[0];
            dir[1] = end[1] - start[1];
            dir[2] = end[2] - start[2];
            Vec.Normalize(dir);
            var dist = dir[0] * bestdir[0] + dir[1] * bestdir[1] + dir[2] * bestdir[2];
            if (dist < bestdist)
                continue;
            tr = SV.Move(start, Vec.origin, Vec.origin, end, 0, ent);
            if (tr.ent == check) {
                bestdist = dist;
                bestent = check;
            }
        }
        if (bestent != null) {
            dir[0] = bestent.v.origin[0] - ent.v.origin[0];
            dir[1] = bestent.v.origin[1] - ent.v.origin[1];
            dir[2] = bestent.v.origin[2] - ent.v.origin[2];
            var dist = dir[0] * bestdir[0] + dir[1] * bestdir[1] + dir[2] * bestdir[2];
            end[0] = bestdir[0] * dist;
            end[1] = bestdir[1] * dist;
            end[2] = dir[2];
            Vec.Normalize(end);
            PR.globals.SetReturnVector(end);
            return;
        }
        PR.globals.SetReturnVector(bestdir);
    }

    public static function changeyaw() {
        var ent = SV.server.edicts[PR.globals.self];
        var current = Vec.Anglemod(ent.v.angles[1]);
        var ideal = ent.v.ideal_yaw;
        if (current == ideal)
            return;
        var move = ideal - current;
        if (ideal > current) {
            if (move >= 180.0)
                move -= 360.0;
        }
        else if (move <= -180.0)
            move += 360.0;
        var speed = ent.v.yaw_speed;
        if (move > 0.0) {
            if (move > speed)
                move = speed;
        }
        else if (move < -speed)
            move = -speed;
        ent.v.angles[1] = Vec.Anglemod(current + move);
    }

    static function WriteDest() {
        switch (Std.int(PR.globals.floats[4])) {
            case 0: // broadcast
                return SV.server.datagram;
            case 1: // one
                var entnum = PR.globals.msg_entity;
                if ((entnum <= 0) || (entnum > SV.svs.maxclients))
                    PR.RunError('WriteDest: not a client');
                return SV.svs.clients[entnum - 1].message;
            case 2: // all
                return SV.server.reliable_datagram;
            case 3: // init
                return SV.server.signon;
            default:
                PR.RunError('WriteDest: bad destination');
                return null;
        }
    }

    static function WriteByte() WriteDest().WriteByte(Std.int(PR.globals.floats[7]));
    static function WriteChar() WriteDest().WriteChar(Std.int(PR.globals.floats[7]));
    static function WriteShort() WriteDest().WriteShort(Std.int(PR.globals.floats[7]));
    static function WriteLong() WriteDest().WriteLong(Std.int(PR.globals.floats[7]));
    static function WriteAngle() WriteDest().WriteAngle(PR.globals.floats[7]);
    static function WriteCoord() WriteDest().WriteCoord(PR.globals.floats[7]);
    static function WriteString() WriteDest().WriteString(PR.GetString(PR.globals.ints[7]));
    static function WriteEntity() WriteDest().WriteShort(PR.globals.ints[7]);

    static function makestatic() {
        var ent = SV.server.edicts[PR.globals.ints[4]];
        var message = SV.server.signon;
        message.WriteByte(SVC.spawnstatic);
        message.WriteByte(SV.ModelIndex(PR.GetString(ent.v.model)));
        message.WriteByte(Std.int(ent.v.frame));
        message.WriteByte(Std.int(ent.v.colormap));
        message.WriteByte(Std.int(ent.v.skin));
        message.WriteCoord(ent.v.origin[0]);
        message.WriteAngle(ent.v.angles[0]);
        message.WriteCoord(ent.v.origin[1]);
        message.WriteAngle(ent.v.angles[1]);
        message.WriteCoord(ent.v.origin[2]);
        message.WriteAngle(ent.v.angles[2]);
        ED.Free(ent);
    }

    static function setspawnparms() {
        var i = PR.globals.ints[4];
        if ((i <= 0) || (i > SV.svs.maxclients))
            PR.RunError('Entity is not a client');
        PR.globals.SetParms(SV.svs.clients[i - 1].spawn_parms);
    }

    static function changelevel() {
        if (SV.svs.changelevel_issued)
            return;
        SV.svs.changelevel_issued = true;
        Cmd.text += 'changelevel ' + PR.GetString(PR.globals.ints[4]) + '\n';
    }

    static function Fixme() {
        PR.RunError('unimplemented builtin');
    }

    static var builtin:Array<Void->Void> = [
        Fixme,
        makevectors,
        setorigin,
        setmodel,
        setsize,
        Fixme,
        breakstatement,
        random,
        sound,
        normalize,
        error,
        objerror,
        vlen,
        vectoyaw,
        Spawn,
        Remove,
        traceline,
        checkclient,
        Find,
        precache_sound,
        precache_model,
        stuffcmd,
        findradius,
        bprint,
        sprint,
        dprint,
        ftos,
        vtos,
        coredump,
        traceon,
        traceoff,
        eprint,
        walkmove,
        Fixme,
        droptofloor,
        lightstyle,
        rint,
        floor,
        ceil,
        Fixme,
        checkbottom,
        pointcontents,
        Fixme,
        fabs,
        aim,
        cvar,
        localcmd,
        nextent,
        particle,
        changeyaw,
        Fixme,
        vectoangles,
        WriteByte,
        WriteChar,
        WriteShort,
        WriteLong,
        WriteCoord,
        WriteAngle,
        WriteString,
        WriteEntity,
        Fixme,
        Fixme,
        Fixme,
        Fixme,
        Fixme,
        Fixme,
        Fixme,
        MoveToGoal,
        precache_file,
        makestatic,
        changelevel,
        Fixme,
        cvar_set,
        centerprint,
        ambientsound,
        precache_model,
        precache_sound,
        precache_file,
        setspawnparms
    ];

}
