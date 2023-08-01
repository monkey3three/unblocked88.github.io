package quake;

import quake.CL.CShift;
import quake.Def.ClientStat;

@:enum abstract ViewAngle(Int) to Int {
	var PITCH = 0;
	var YAW = 0;
	var ROLL = 0;
}

@:publicFields
class V {
	static var cshift_empty = [130.0, 80.0, 50.0, 0.0];
	static var cshift_water = [130.0, 80.0, 50.0, 128.0];
	static var cshift_slime = [0.0, 25.0, 5.0, 150.0];
	static var cshift_lava = [255.0, 80.0, 0.0, 150.0];
	static var blend = [0.0, 0.0, 0.0, 0.0];
	static var oldz = 0.0;

	static var dmg_roll:Float;
	static var dmg_pitch:Float;
	static var dmg_time = 0.0;

	static var centermove:Cvar;
	static var centerspeed:Cvar;
	static var iyaw_cycle:Cvar;
	static var iroll_cycle:Cvar;
	static var ipitch_cycle:Cvar;
	static var iyaw_level:Cvar;
	static var iroll_level:Cvar;
	static var ipitch_level:Cvar;
	static var idlescale:Cvar;
	static var crosshair:Cvar;
	static var crossx:Cvar;
	static var crossy:Cvar;
	static var cshiftpercent:Cvar;
	static var ofsx:Cvar;
	static var ofsy:Cvar;
	static var ofsz:Cvar;
	static var rollspeed:Cvar;
	static var rollangle:Cvar;
	static var bob:Cvar;
	static var bobcycle:Cvar;
	static var bobup:Cvar;
	static var kicktime:Cvar;
	static var kickroll:Cvar;
	static var kickpitch:Cvar;
	static var gamma:Cvar;

	static function CalcRoll(angles:Vec, velocity:Vec):Float {
		var right = new Vec();
		Vec.AngleVectors(angles, null, right);
		var side = Vec.DotProduct(velocity, right);
		var sign = side < 0 ? -1 : 1;
		side = Math.abs(side);
		if (side < rollspeed.value)
			return side * sign * rollangle.value / rollspeed.value;
		return rollangle.value * sign;
	}

	static function CalcBob():Float {
		if (bobcycle.value <= 0.0 || bobcycle.value >= 1.0 || bobup.value <= 0.0 || bobup.value >= 1.0 || bob.value == 0.0)
			return 0.0;

		var cycle = (CL.state.time - Std.int(CL.state.time / bobcycle.value) * bobcycle.value) / bobcycle.value;
		if (cycle < bobup.value)
			cycle = Math.PI * cycle / bobup.value;
		else
			cycle = Math.PI + Math.PI * (cycle - bobup.value) / (1.0 - bobup.value);

		var bob = Math.sqrt(CL.state.velocity[0] * CL.state.velocity[0] + CL.state.velocity[1] * CL.state.velocity[1]) * bob.value;
		bob = bob * 0.3 + bob * 0.7 * Math.sin(cycle);
		if (bob > 4.0)
			bob = 4.0;
		else if (bob < -7.0)
			bob = -7.0;
		return bob;
	}

	static function StartPitchDrift():Void {
		if (CL.state.laststop == CL.state.time)
			return;
		if (CL.state.nodrift || CL.state.pitchvel == 0.0) {
			CL.state.pitchvel = centerspeed.value;
			CL.state.nodrift = false;
			CL.state.driftmove = 0.0;
		}
	}

	static function StopPitchDrift():Void {
		CL.state.laststop = CL.state.time;
		CL.state.nodrift = true;
		CL.state.pitchvel = 0.0;
	}

	static function DriftPitch():Void {
		if (Host.noclip_anglehack || !CL.state.onground || CL.cls.demoplayback) {
			CL.state.driftmove = 0.0;
			CL.state.pitchvel = 0.0;
			return;
		}

		if (CL.state.nodrift) {
			if (Math.abs(CL.state.cmd.forwardmove) < CL.forwardspeed.value)
				CL.state.driftmove = 0.0;
			else
				CL.state.driftmove += Host.frametime;
			if (CL.state.driftmove > centermove.value)
				StartPitchDrift();
			return;
		}

		var delta = CL.state.idealpitch - CL.state.viewangles[ViewAngle.PITCH];
		if (delta == 0.0) {
			CL.state.pitchvel = 0.0;
			return;
		}

		var move = Host.frametime * CL.state.pitchvel;
		CL.state.pitchvel += Host.frametime * centerspeed.value;

		if (delta > 0) {
			if (move > delta) {
				CL.state.pitchvel = 0.0;
				move = delta;
			}
			CL.state.viewangles[ViewAngle.PITCH] += move;
		} else if (delta < 0) {
			if (move > -delta) {
				CL.state.pitchvel = 0.0;
				move = -delta;
			}
			CL.state.viewangles[ViewAngle.PITCH] -= move;
		}
	}


	static function ParseDamage():Void {
		var armor = MSG.ReadByte();
		var blood = MSG.ReadByte();
		var ent = CL.entities[CL.state.viewentity];
		var from = Vec.of(MSG.ReadCoord() - ent.origin[0], MSG.ReadCoord() - ent.origin[1], MSG.ReadCoord() - ent.origin[2]);
		Vec.Normalize(from);
		var count = (blood + armor) * 0.5;
		if (count < 10.0)
			count = 10.0;
		CL.state.faceanimtime = CL.state.time + 0.2;

		var cshift = CL.state.cshifts[CShift.damage];
		cshift[3] += 3.0 * count;
		if (cshift[3] < 0.0)
			cshift[3] = 0.0;
		else if (cshift[3] > 150.0)
			cshift[3] = 150.0;

		if (armor > blood) {
			cshift[0] = 200.0;
			cshift[1] = cshift[2] = 100.0;
		}
		else if (armor != 0) {
			cshift[0] = 220.0;
			cshift[1] = cshift[2] = 50.0;
		}
		else
		{
			cshift[0] = 255.0;
			cshift[1] = cshift[2] = 0.0;
		}

		var forward = new Vec(), right = new Vec();
		Vec.AngleVectors(ent.angles, forward, right);
		V.dmg_roll = count * (from[0] * right[0] + from[1] * right[1] + from[2] * right[2]) * V.kickroll.value;
		V.dmg_pitch = count * (from[0] * forward[0] + from[1] * forward[1] + from[2] * forward[2]) * V.kickpitch.value;
		V.dmg_time = V.kicktime.value;
	}

	static function cshift_f():Void {
		var cshift = V.cshift_empty;
		cshift[0] = Q.atoi(Cmd.argv[1]);
		cshift[1] = Q.atoi(Cmd.argv[2]);
		cshift[2] = Q.atoi(Cmd.argv[3]);
		cshift[3] = Q.atoi(Cmd.argv[4]);
	}

	static function BonusFlash_f():Void {
		var cshift = CL.state.cshifts[CShift.bonus];
		cshift[0] = 215.0;
		cshift[1] = 186.0;
		cshift[2] = 69.0;
		cshift[3] = 50.0;
	}

	static function SetContentsColor(contents:Contents):Void {
		switch (contents) {
			case empty | solid:
				CL.state.cshifts[CShift.contents] = V.cshift_empty;
			case lava:
				CL.state.cshifts[CShift.contents] = V.cshift_lava;
			case slime:
				CL.state.cshifts[CShift.contents] = V.cshift_slime;
			default:
				CL.state.cshifts[CShift.contents] = V.cshift_water;
		}
	}

	static function CalcBlend():Void {
		var cshift = CL.state.cshifts[CShift.powerup];
		if ((CL.state.items & Def.it.quad) != 0) {
			cshift[0] = 0.0;
			cshift[1] = 0.0;
			cshift[2] = 255.0;
			cshift[3] = 30.0;
		}
		else if ((CL.state.items & Def.it.suit) != 0) {
			cshift[0] = 0.0;
			cshift[1] = 255.0;
			cshift[2] = 0.0;
			cshift[3] = 20.0;
		}
		else if ((CL.state.items & Def.it.invisibility) != 0) {
			cshift[0] = 100.0;
			cshift[1] = 100.0;
			cshift[2] = 100.0;
			cshift[3] = 100.0;
		}
		else if ((CL.state.items & Def.it.invulnerability) != 0) {
			cshift[0] = 255.0;
			cshift[1] = 255.0;
			cshift[2] = 0.0;
			cshift[3] = 30.0;
		}
		else
			cshift[3] = 0.0;

		CL.state.cshifts[CShift.damage][3] -= Host.frametime * 150.0;
		if (CL.state.cshifts[CShift.damage][3] < 0.0)
			CL.state.cshifts[CShift.damage][3] = 0.0;
		CL.state.cshifts[CShift.bonus][3] -= Host.frametime * 100.0;
		if (CL.state.cshifts[CShift.bonus][3] < 0.0)
			CL.state.cshifts[CShift.bonus][3] = 0.0;

		if (V.cshiftpercent.value == 0) {
			V.blend[0] = V.blend[1] = V.blend[2] = V.blend[3] = 0.0;
			return;
		}

		var r = 0.0, g = 0.0, b = 0.0, a = 0.0;
		for (i in 0...CShift.numtotal) {
			var cshift = CL.state.cshifts[i];
			var a2 = cshift[3] * V.cshiftpercent.value / 25500.0;
			if (a2 == 0.0)
				continue;
			a = a + a2 * (1.0 - a);
			a2 = a2 / a;
			r = r * (1.0 - a2) + cshift[0] * a2;
			g = g * (1.0 - a2) + cshift[1] * a2;
			b = b * (1.0 - a2) + cshift[2] * a2;
		}
		if (a > 1.0)
			a = 1.0;
		else if (a < 0.0)
			a = 0.0;
		V.blend[0] = r;
		V.blend[1] = g;
		V.blend[2] = b;
		V.blend[3] = a;
		if (V.blend[3] > 1.0)
			V.blend[3] = 1.0;
		else if (V.blend[3] < 0.0)
			V.blend[3] = 0.0;
	}

	static function CalcIntermissionRefdef():Void {
		var ent = CL.entities[CL.state.viewentity];
		Render.refdef.vieworg[0] = ent.origin[0];
		Render.refdef.vieworg[1] = ent.origin[1];
		Render.refdef.vieworg[2] = ent.origin[2];
		Render.refdef.viewangles[0] = ent.angles[0] + Math.sin(CL.state.time * V.ipitch_cycle.value) * V.ipitch_level.value;
		Render.refdef.viewangles[1] = ent.angles[1] + Math.sin(CL.state.time * V.iyaw_cycle.value) * V.iyaw_level.value;
		Render.refdef.viewangles[2] = ent.angles[2] + Math.sin(CL.state.time * V.iroll_cycle.value) * V.iroll_level.value;
		CL.state.viewent.model = null;
	}

	static function CalcRefdef():Void {
		DriftPitch();

		var ent = CL.entities[CL.state.viewentity];
		ent.angles[1] = CL.state.viewangles[1];
		ent.angles[0] = -CL.state.viewangles[0];
		var bob = CalcBob();

		Render.refdef.vieworg[0] = ent.origin[0] + 0.03125;
		Render.refdef.vieworg[1] = ent.origin[1] + 0.03125;
		Render.refdef.vieworg[2] = ent.origin[2] + CL.state.viewheight + bob + 0.03125;

		Render.refdef.viewangles[0] = CL.state.viewangles[0];
		Render.refdef.viewangles[1] = CL.state.viewangles[1];
		Render.refdef.viewangles[2] = CL.state.viewangles[2] + CalcRoll(CL.entities[CL.state.viewentity].angles, CL.state.velocity);

		if (V.dmg_time > 0.0) {
			if (V.kicktime.value != 0.0) {
				Render.refdef.viewangles[2] += (V.dmg_time / V.kicktime.value) * V.dmg_roll;
				Render.refdef.viewangles[0] -= (V.dmg_time / V.kicktime.value) * V.dmg_pitch;
			}
			V.dmg_time -= Host.frametime;
		}
		if (CL.state.stats[ClientStat.health] <= 0)
			Render.refdef.viewangles[2] = 80.0;

		var ipitch = V.idlescale.value * Math.sin(CL.state.time * V.ipitch_cycle.value) * V.ipitch_level.value;
		var iyaw = V.idlescale.value * Math.sin(CL.state.time * V.iyaw_cycle.value) * V.iyaw_level.value;
		var iroll = V.idlescale.value * Math.sin(CL.state.time * V.iroll_cycle.value) * V.iroll_level.value;
		Render.refdef.viewangles[0] += ipitch;
		Render.refdef.viewangles[1] += iyaw;
		Render.refdef.viewangles[2] += iroll;

		var forward = new Vec(), right = new Vec(), up = new Vec();
		Vec.AngleVectors(Vec.of(-ent.angles[0], ent.angles[1], ent.angles[2]), forward, right, up);
		Render.refdef.vieworg[0] += V.ofsx.value * forward[0] + V.ofsy.value * right[0] + V.ofsz.value * up[0];
		Render.refdef.vieworg[1] += V.ofsx.value * forward[1] + V.ofsy.value * right[1] + V.ofsz.value * up[1];
		Render.refdef.vieworg[2] += V.ofsx.value * forward[2] + V.ofsy.value * right[2] + V.ofsz.value * up[2];

		if (Render.refdef.vieworg[0] < (ent.origin[0] - 14.0))
			Render.refdef.vieworg[0] = ent.origin[0] - 14.0;
		else if (Render.refdef.vieworg[0] > (ent.origin[0] + 14.0))
			Render.refdef.vieworg[0] = ent.origin[0] + 14.0;
		if (Render.refdef.vieworg[1] < (ent.origin[1] - 14.0))
			Render.refdef.vieworg[1] = ent.origin[1] - 14.0;
		else if (Render.refdef.vieworg[1] > (ent.origin[1] + 14.0))
			Render.refdef.vieworg[1] = ent.origin[1] + 14.0;
		if (Render.refdef.vieworg[2] < (ent.origin[2] - 22.0))
			Render.refdef.vieworg[2] = ent.origin[2] - 22.0;
		else if (Render.refdef.vieworg[2] > (ent.origin[2] + 30.0))
			Render.refdef.vieworg[2] = ent.origin[2] + 30.0;

		var view = CL.state.viewent;
		view.angles[0] = -Render.refdef.viewangles[0] - ipitch;
		view.angles[1] = Render.refdef.viewangles[1] - iyaw;
		view.angles[2] = CL.state.viewangles[2] - iroll;
		view.origin[0] = ent.origin[0] + forward[0] * bob * 0.4;
		view.origin[1] = ent.origin[1] + forward[1] * bob * 0.4;
		view.origin[2] = ent.origin[2] + CL.state.viewheight + forward[2] * bob * 0.4 + bob;
		switch (SCR.viewsize.value) {
			case 110 | 90:
				view.origin[2] += 1.0;
			case 100:
				view.origin[2] += 2.0;
			case 80:
				view.origin[2] += 0.5;
		}
		view.model = CL.state.model_precache[CL.state.stats[ClientStat.weapon]];
		view.frame = CL.state.stats[ClientStat.weaponframe];

		Render.refdef.viewangles[0] += CL.state.punchangle[0];
		Render.refdef.viewangles[1] += CL.state.punchangle[1];
		Render.refdef.viewangles[2] += CL.state.punchangle[2];

		if ((CL.state.onground) && ((ent.origin[2] - V.oldz) > 0.0)) {
			var steptime:Float = CL.state.time - CL.state.oldtime;
			if (steptime < 0.0)
				steptime = 0.0;
			V.oldz += steptime * 80.0;
			if (V.oldz > ent.origin[2])
				V.oldz = ent.origin[2];
			else if ((ent.origin[2] - V.oldz) > 12.0)
				V.oldz = ent.origin[2] - 12.0;
			Render.refdef.vieworg[2] += V.oldz - ent.origin[2];
			view.origin[2] += V.oldz - ent.origin[2];
		}
		else
			V.oldz = ent.origin[2];
		if (Chase.active.value != 0)
			Chase.Update();
	}

	static function RenderView():Void {
		if (Console.forcedup)
			return;
		if (CL.state.maxclients >= 2) {
			ofsx.set("0");
			ofsy.set("0");
			ofsz.set("0");
		}
		if (CL.state.intermission != 0)
			CalcIntermissionRefdef();
		else if (!CL.state.paused)
			CalcRefdef();
		Render.PushDlights();
		Render.RenderView();
	}

	static function Init():Void {
		Cmd.AddCommand('v_cshift', cshift_f);
		Cmd.AddCommand('bf', BonusFlash_f);
		Cmd.AddCommand('centerview', StartPitchDrift);
		centermove = Cvar.RegisterVariable('v_centermove', '0.15');
		centerspeed = Cvar.RegisterVariable('v_centerspeed', '500');
		iyaw_cycle = Cvar.RegisterVariable('v_iyaw_cycle', '2');
		iroll_cycle = Cvar.RegisterVariable('v_iroll_cycle', '0.5');
		ipitch_cycle = Cvar.RegisterVariable('v_ipitch_cycle', '1');
		iyaw_level = Cvar.RegisterVariable('v_iyaw_level', '0.3');
		iroll_level = Cvar.RegisterVariable('v_iroll_level', '0.1');
		ipitch_level = Cvar.RegisterVariable('v_ipitch_level', '0.3');
		idlescale = Cvar.RegisterVariable('v_idlescale', '0');
		crosshair = Cvar.RegisterVariable('crosshair', '0', true);
		crossx = Cvar.RegisterVariable('cl_crossx', '0');
		crossy = Cvar.RegisterVariable('cl_crossy', '0');
		cshiftpercent = Cvar.RegisterVariable('gl_cshiftpercent', '100');
		ofsx = Cvar.RegisterVariable('scr_ofsx', '0');
		ofsy = Cvar.RegisterVariable('scr_ofsy', '0');
		ofsz = Cvar.RegisterVariable('scr_ofsz', '0');
		rollspeed = Cvar.RegisterVariable('cl_rollspeed', '200');
		rollangle = Cvar.RegisterVariable('cl_rollangle', '2.0');
		bob = Cvar.RegisterVariable('cl_bob', '0.02');
		bobcycle = Cvar.RegisterVariable('cl_bobcycle', '0.6');
		bobup = Cvar.RegisterVariable('cl_bobup', '0.5');
		kicktime = Cvar.RegisterVariable('v_kicktime', '0.5');
		kickroll = Cvar.RegisterVariable('v_kickroll', '0.6');
		kickpitch = Cvar.RegisterVariable('v_kickpitch', '0.6');
		gamma = Cvar.RegisterVariable('gamma', '1', true);
	}
}
