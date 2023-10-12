package quake;

import quake.Draw.DrawPic;
import quake.Def.ClientStat;

class Sbar {
    public static var lines:Int;

    static var nums:Array<Array<DrawPic>>;
    static var colon:DrawPic;
    static var slash:DrawPic;
    static var weapons:Array<Array<DrawPic>>;
    static var faces:Array<Array<DrawPic>>;
    static var h_weapons:Array<Array<DrawPic>>;
    static var r_invbar:Array<DrawPic>;
    static var r_weapons:Array<DrawPic>;
    static var r_items:Array<DrawPic>;
    static var r_ammo:Array<DrawPic>;
    static var sigil:Array<DrawPic>;
    static var items:Array<DrawPic>;
    static var ammo:Array<DrawPic>;
    static var armor:Array<DrawPic>;
    static var h_items:Array<DrawPic>;
    static var ibar:DrawPic;
    static var ranking:DrawPic;
    static var complete:DrawPic;
    static var inter:DrawPic;
    static var finale:DrawPic;
    static var disc:DrawPic;
    static var sbar:DrawPic;
    static var scorebar:DrawPic;
    static var r_teambord:DrawPic;
    static var face_invis_invuln:DrawPic;
    static var face_invis:DrawPic;
    static var face_invuln:DrawPic;
    static var face_quad:DrawPic;
    static var fragsort:Array<Int> = [];
    static var hipweapons:Array<Int>;
    static var scoreboardlines:Int;
    static var showscores = false;

    public static function Init():Void {
        nums = [[], []];
        for (i in 0...10) {
            nums[0][i] = Draw.PicFromWad('NUM_' + i);
            nums[1][i] = Draw.PicFromWad('ANUM_' + i);
        }
        nums[0][10] = Draw.PicFromWad('NUM_MINUS');
        nums[1][10] = Draw.PicFromWad('ANUM_MINUS');
        colon = Draw.PicFromWad('NUM_COLON');
        slash = Draw.PicFromWad('NUM_SLASH');

        weapons = [
            [
                Draw.PicFromWad('INV_SHOTGUN'),
                Draw.PicFromWad('INV_SSHOTGUN'),
                Draw.PicFromWad('INV_NAILGUN'),
                Draw.PicFromWad('INV_SNAILGUN'),
                Draw.PicFromWad('INV_RLAUNCH'),
                Draw.PicFromWad('INV_SRLAUNCH'),
                Draw.PicFromWad('INV_LIGHTNG')
            ],
            [
                Draw.PicFromWad('INV2_SHOTGUN'),
                Draw.PicFromWad('INV2_SSHOTGUN'),
                Draw.PicFromWad('INV2_NAILGUN'),
                Draw.PicFromWad('INV2_SNAILGUN'),
                Draw.PicFromWad('INV2_RLAUNCH'),
                Draw.PicFromWad('INV2_SRLAUNCH'),
                Draw.PicFromWad('INV2_LIGHTNG')
            ]
        ];
        for (i in 0...5) {
            weapons.push([
                Draw.PicFromWad('INVA' + (i + 1) + '_SHOTGUN'),
                Draw.PicFromWad('INVA' + (i + 1) + '_SSHOTGUN'),
                Draw.PicFromWad('INVA' + (i + 1) + '_NAILGUN'),
                Draw.PicFromWad('INVA' + (i + 1) + '_SNAILGUN'),
                Draw.PicFromWad('INVA' + (i + 1) + '_RLAUNCH'),
                Draw.PicFromWad('INVA' + (i + 1) + '_SRLAUNCH'),
                Draw.PicFromWad('INVA' + (i + 1) + '_LIGHTNG')
            ]);
        }

        ammo = [
            Draw.PicFromWad('SB_SHELLS'),
            Draw.PicFromWad('SB_NAILS'),
            Draw.PicFromWad('SB_ROCKET'),
            Draw.PicFromWad('SB_CELLS')
        ];

        armor = [
            Draw.PicFromWad('SB_ARMOR1'),
            Draw.PicFromWad('SB_ARMOR2'),
            Draw.PicFromWad('SB_ARMOR3')
        ];

        items = [
            Draw.PicFromWad('SB_KEY1'),
            Draw.PicFromWad('SB_KEY2'),
            Draw.PicFromWad('SB_INVIS'),
            Draw.PicFromWad('SB_INVULN'),
            Draw.PicFromWad('SB_SUIT'),
            Draw.PicFromWad('SB_QUAD')
        ];

        sigil = [
            Draw.PicFromWad('SB_SIGIL1'),
            Draw.PicFromWad('SB_SIGIL2'),
            Draw.PicFromWad('SB_SIGIL3'),
            Draw.PicFromWad('SB_SIGIL4')
        ];

        faces = [];
        for (i in 0...5) {
            faces.push([
                Draw.PicFromWad('FACE' + (5 - i)),
                Draw.PicFromWad('FACE_P' + (5 - i))
            ]);
        }
        face_invis = Draw.PicFromWad('FACE_INVIS');
        face_invuln = Draw.PicFromWad('FACE_INVUL2');
        face_invis_invuln = Draw.PicFromWad('FACE_INV2');
        face_quad = Draw.PicFromWad('FACE_QUAD');

        Cmd.AddCommand('+showscores', ShowScores);
        Cmd.AddCommand('-showscores', DontShowScores);

        sbar = Draw.PicFromWad('SBAR');
        ibar = Draw.PicFromWad('IBAR');
        scorebar = Draw.PicFromWad('SCOREBAR');

        ranking = Draw.CachePic('ranking');
        complete = Draw.CachePic('complete');
        inter = Draw.CachePic('inter');
        finale = Draw.CachePic('finale');

        disc = Draw.PicFromWad('DISC');

        if (COM.hipnotic) {
            h_weapons = [
                [
                    Draw.PicFromWad('INV_LASER'),
                    Draw.PicFromWad('INV_MJOLNIR'),
                    Draw.PicFromWad('INV_GREN_PROX'),
                    Draw.PicFromWad('INV_PROX_GREN'),
                    Draw.PicFromWad('INV_PROX')
                ],
                [
                    Draw.PicFromWad('INV2_LASER'),
                    Draw.PicFromWad('INV2_MJOLNIR'),
                    Draw.PicFromWad('INV2_GREN_PROX'),
                    Draw.PicFromWad('INV2_PROX_GREN'),
                    Draw.PicFromWad('INV2_PROX')
                ]
            ];
            for (i in 0...5)
                h_weapons.push([
                    Draw.PicFromWad('INVA' + (i + 1) + '_LASER'),
                    Draw.PicFromWad('INVA' + (i + 1) + '_MJOLNIR'),
                    Draw.PicFromWad('INVA' + (i + 1) + '_GREN_PROX'),
                    Draw.PicFromWad('INVA' + (i + 1) + '_PROX_GREN'),
                    Draw.PicFromWad('INVA' + (i + 1) + '_PROX')
                ]);
            hipweapons = [Def.hit.laser_cannon_bit, Def.hit.mjolnir_bit, 4, Def.hit.proximity_gun_bit];
            h_items = [
                Draw.PicFromWad('SB_WSUIT'),
                Draw.PicFromWad('SB_ESHLD')
            ];
        }

        if (COM.rogue) {
            r_invbar = [
                Draw.PicFromWad('R_INVBAR1'),
                Draw.PicFromWad('R_INVBAR2')
            ];
            r_weapons = [
                Draw.PicFromWad('R_LAVA'),
                Draw.PicFromWad('R_SUPERLAVA'),
                Draw.PicFromWad('R_GREN'),
                Draw.PicFromWad('R_MULTIROCK'),
                Draw.PicFromWad('R_PLASMA')
            ];
            r_items = [
                Draw.PicFromWad('R_SHIELD1'),
                Draw.PicFromWad('R_AGRAV1')
            ];
            r_teambord = Draw.PicFromWad('R_TEAMBORD');
            r_ammo = [
                Draw.PicFromWad('R_AMMOLAVA'),
                Draw.PicFromWad('R_AMMOMULTI'),
                Draw.PicFromWad('R_AMMOPLASMA')
            ];
        }
    }

    static function ShowScores():Void {
        showscores = true;
    }

    static function DontShowScores():Void {
        showscores = false;
    }

    static function DrawPic(x:Int, y:Int, pic:DrawPic):Void {
        if (CL.state.gametype == 1)
            Draw.Pic(x, y + VID.height - 24, pic);
        else
            Draw.Pic(x + (VID.width >> 1) - 160, y + VID.height - 24, pic);
    }

    static function DrawCharacter(x:Int, y:Int, num:Int):Void {
        if (CL.state.gametype == 1)
            Draw.Character(x + 4, y + VID.height - 24, num);
        else
            Draw.Character(x + (VID.width >> 1) - 156, y + VID.height - 24, num);
    }

    static function DrawString(x:Int, y:Int, str:String):Void {
        if (CL.state.gametype == 1)
            Draw.String(x, y + VID.height - 24, str);
        else
            Draw.String(x + (VID.width >> 1) - 160, y + VID.height - 24, str);
    }

    static function DrawNum(x:Int, y:Int, num:Int, digits:Int, color:Int):Void {
        var str = Std.string(num);
        if (str.length > digits)
            str = str.substring(str.length - digits, str.length);
        else if (str.length < digits)
            x += (digits - str.length) * 24;
        for (i in 0...str.length) {
            var frame = str.charCodeAt(i);
            DrawPic(x, y, nums[color][frame == 45 ? 10 : frame - 48]);
            x += 24;
        }
    }

    static function SortFrags():Void {
        scoreboardlines = 0;
        for (i in 0...CL.state.maxclients) {
            if (CL.state.scores[i].name.length != 0)
                fragsort[scoreboardlines++] = i;
        }
        for (i in 0...scoreboardlines) {
            for (j in 0...(scoreboardlines - 1 - i)) {
                if (CL.state.scores[fragsort[j]].frags < CL.state.scores[fragsort[j + 1]].frags) {
                    var k = fragsort[j];
                    fragsort[j] = fragsort[j + 1];
                    fragsort[j + 1] = k;
                }
            }
        }
    }

    static function SoloScoreboard():Void {
        var str;

        Sbar.DrawString(8, 4, 'Monsters:    /');
        str = Std.string(CL.state.stats[ClientStat.monsters]);
        Sbar.DrawString(104 - (str.length << 3), 4, str);
        str = Std.string(CL.state.stats[ClientStat.totalmonsters]);
        Sbar.DrawString(144 - (str.length << 3), 4, str);

        Sbar.DrawString(8, 12, 'Secrets :    /');
        str = Std.string(CL.state.stats[ClientStat.secrets]);
        Sbar.DrawString(104 - (str.length << 3), 12, str);
        str = Std.string(CL.state.stats[ClientStat.totalsecrets]);
        Sbar.DrawString(144 - (str.length << 3), 12, str);

        var minutes = Math.floor(CL.state.time / 60.0);
        var seconds = Math.floor(CL.state.time - 60 * minutes);
        var tens = Math.floor(seconds / 10.0);
        str = Std.string((seconds - 10 * tens));
        Sbar.DrawString(184, 4, 'Time :   :' + tens + str);
        str = Std.string(minutes);
        Sbar.DrawString(256 - (str.length << 3), 4, str);

        Sbar.DrawString(232 - (CL.state.levelname.length << 2), 12, CL.state.levelname);
    }

    static function DrawInventory():Void {
        if (COM.rogue)
            Sbar.DrawPic(0, -24, Sbar.r_invbar[CL.state.stats[ClientStat.activeweapon] >= Def.rit.lava_nailgun ? 0 : 1]);
        else
            Sbar.DrawPic(0, -24, Sbar.ibar);

        var flashon;
        for (i in 0...7) {
            if ((CL.state.items & (Def.it.shotgun << i)) == 0)
                continue;
            flashon = Math.floor((CL.state.time - CL.state.item_gettime[i]) * 10.0);
            if (flashon >= 10)
                flashon = CL.state.stats[ClientStat.activeweapon] == (Def.it.shotgun << i) ? 1 : 0;
            else
                flashon = (flashon % 5) + 2;
            Sbar.DrawPic(i * 24, -16, Sbar.weapons[flashon][i]);
        }
        if (COM.hipnotic) {
            var grenadeflashing = false;
            for (i in 0...4) {
                if ((CL.state.items & (1 << Sbar.hipweapons[i])) != 0) {
                    flashon = Math.floor((CL.state.time - CL.state.item_gettime[i]) * 10.0);
                    if (flashon >= 10)
                        flashon = CL.state.stats[ClientStat.activeweapon] == (1 << Sbar.hipweapons[i]) ? 1 : 0;
                    else
                        flashon = (flashon % 5) + 2;

                    if (i == 2) {
                        if (((CL.state.items & Def.hit.proximity_gun) != 0) && (flashon != 0)) {
                            grenadeflashing = true;
                            Sbar.DrawPic(96, -16, Sbar.h_weapons[flashon][2]);
                        }
                    }
                    else if (i == 3) {
                        if ((CL.state.items & Def.it.grenade_launcher) != 0) {
                            if (!grenadeflashing)
                                Sbar.DrawPic(96, -16, Sbar.h_weapons[flashon][3]);
                        }
                        else
                            Sbar.DrawPic(96, -16, Sbar.h_weapons[flashon][4]);
                    }
                    else
                        Sbar.DrawPic(176 + i * 24, -16, Sbar.h_weapons[flashon][i]);
                }
            }
        }
        else if (COM.rogue) {
            if (CL.state.stats[ClientStat.activeweapon] >= Def.rit.lava_nailgun) {
                for (i in 0...5) {
                    if (CL.state.stats[ClientStat.activeweapon] == (Def.rit.lava_nailgun << i))
                        Sbar.DrawPic((i + 2) * 24, -16, Sbar.r_weapons[i]);
                }
            }
        }

        for (i in 0...4) {
            var num = Std.string(CL.state.stats[ClientStat.shells + i]);
            switch (num.length) {
            case 1:
                Sbar.DrawCharacter(((6 * i + 3) << 3) - 2, -24, num.charCodeAt(0) - 30);
                continue;
            case 2:
                Sbar.DrawCharacter(((6 * i + 2) << 3) - 2, -24, num.charCodeAt(0) - 30);
                Sbar.DrawCharacter(((6 * i + 3) << 3) - 2, -24, num.charCodeAt(1) - 30);
                continue;
            case 3:
                Sbar.DrawCharacter(((6 * i + 1) << 3) - 2, -24, num.charCodeAt(0) - 30);
                Sbar.DrawCharacter(((6 * i + 2) << 3) - 2, -24, num.charCodeAt(1) - 30);
                Sbar.DrawCharacter(((6 * i + 3) << 3) - 2, -24, num.charCodeAt(2) - 30);
            }
        }

        if (COM.hipnotic) {
            for (i in 2...6) {
                if ((CL.state.items & (1 << (17 + i))) != 0)
                    Sbar.DrawPic(192 + (i << 4), -16, Sbar.items[i]);
            }
            if ((CL.state.items & 16777216) != 0)
                Sbar.DrawPic(288, -16, Sbar.h_items[0]);
            if ((CL.state.items & 33554432) != 0)
                Sbar.DrawPic(304, -16, Sbar.h_items[1]);
        }
        else
        {
            for (i in 0...6) {
                if ((CL.state.items & (1 << (17 + i))) != 0)
                    Sbar.DrawPic(192 + (i << 4), -16, Sbar.items[i]);
            }
            if (COM.rogue) {
                if ((CL.state.items & 536870912) != 0)
                    Sbar.DrawPic(288, -16, Sbar.r_items[0]);
                if ((CL.state.items & 1073741824) != 0)
                    Sbar.DrawPic(304, -16, Sbar.r_items[1]);
            }
            else
            {
                for (i in 0...4) {
                    if (((CL.state.items >>> (28 + i)) & 1) != 0)
                        Sbar.DrawPic(288 + (i << 3), -16, Sbar.sigil[i]);
                }
            }
        }
    }

    static function DrawFrags():Void {
        Sbar.SortFrags();
        var l = Sbar.scoreboardlines <= 4 ? Sbar.scoreboardlines : 4;
        var x = 23;
        var xofs = CL.state.gametype == 1 ? 10 : (VID.width >> 1) - 150;
        var y = VID.height - 47;
        for (i in 0...l) {
            var k = Sbar.fragsort[i];
            var s = CL.state.scores[k];
            if (s.name.length == 0)
                continue;
            Draw.Fill(xofs + (x << 3), y, 28, 4, (s.colors & 0xf0) + 8);
            Draw.Fill(xofs + (x << 3), y + 4, 28, 3, ((s.colors & 0xf) << 4) + 8);
            var num = Std.string(s.frags);
            Sbar.DrawString(((x - num.length) << 3) + 36, -24, num);
            if (k == (CL.state.viewentity - 1)) {
                Sbar.DrawCharacter((x << 3) + 2, -24, 16);
                Sbar.DrawCharacter((x << 3) + 28, -24, 17);
            }
            x += 4;
        }
    }

    static function DrawFace():Void {
        if (COM.rogue && CL.state.maxclients != 1 && Host.teamplay.value >= 4 && Host.teamplay.value <= 6) {
            var s = CL.state.scores[CL.state.viewentity - 1];
            var top = (s.colors & 0xf0) + 8;
            var xofs = CL.state.gametype == 1 ? 113 : (VID.width >> 1) - 47;

            DrawPic(112, 0, r_teambord);
            Draw.Fill(xofs, VID.height - 21, 22, 9, top);
            Draw.Fill(xofs, VID.height - 12, 22, 9, ((s.colors & 0xf) << 4) + 8);

            var num = (top == 8 ? '>>>' : '   ') + s.frags;
            if (num.length > 3)
                num = num.substring(num.length - 3);
            if (top == 8) {
                DrawCharacter(109, 3, num.charCodeAt(0) - 30);
                DrawCharacter(116, 3, num.charCodeAt(1) - 30);
                DrawCharacter(123, 3, num.charCodeAt(2) - 30);
            } else {
                DrawCharacter(109, 3, num.charCodeAt(0));
                DrawCharacter(116, 3, num.charCodeAt(1));
                DrawCharacter(123, 3, num.charCodeAt(2));
            }
            return;
        }

        if ((CL.state.items & (Def.it.invisibility | Def.it.invulnerability)) == (Def.it.invisibility | Def.it.invulnerability)) {
            DrawPic(112, 0, face_invis_invuln);
            return;
        }
        if ((CL.state.items & Def.it.quad) != 0) {
            DrawPic(112, 0, face_quad);
            return;
        }
        if ((CL.state.items & Def.it.invisibility) != 0) {
            DrawPic(112, 0, face_invis);
            return;
        }
        if ((CL.state.items & Def.it.invulnerability) != 0) {
            DrawPic(112, 0, face_invuln);
            return;
        }

        var f = if (CL.state.stats[ClientStat.health] >= 100) 4 else Std.int(CL.state.stats[ClientStat.health] / 20);
        var anim = if (CL.state.time <= CL.state.faceanimtime) 1 else 0;
        DrawPic(112, 0, faces[f][anim]);
    }

    public static function DrawSbar():Void {
        if (SCR.con_current >= 200)
            return;

        if (lines > 24) {
            DrawInventory();
            if (CL.state.maxclients != 1)
                DrawFrags();
        }

        if (showscores || CL.state.stats[ClientStat.health] <= 0) {
            DrawPic(0, 0, scorebar);
            SoloScoreboard();
            if (CL.state.gametype == 1)
                DeathmatchOverlay();
            return;
        }

        if (lines == 0)
            return;

        DrawPic(0, 0, sbar);

        // keys (hipnotic only)
        if (COM.hipnotic) {
            if ((CL.state.items & Def.it.key1) != 0)
                DrawPic(209, 3, items[0]);
            if ((CL.state.items & Def.it.key2) != 0)
                DrawPic(209, 12, items[1]);
        }

        var it = if (COM.rogue) cast Def.rit else Def.it;

        // armor
        if ((CL.state.items & Def.it.invulnerability) != 0) {
            DrawNum(24, 0, 666, 3, 1);
            DrawPic(0, 0, disc);
        } else {
            DrawNum(24, 0, CL.state.stats[ClientStat.armor], 3, CL.state.stats[ClientStat.armor] <= 25 ? 1 : 0);
            if ((CL.state.items & it.armor3) != 0)
                DrawPic(0, 0, armor[2]);
            else if ((CL.state.items & it.armor2) != 0)
                DrawPic(0, 0, armor[1]);
            else if ((CL.state.items & it.armor1) != 0)
                DrawPic(0, 0, armor[0]);
        }

        // face
        DrawFace();

        // health
        DrawNum(136, 0, CL.state.stats[ClientStat.health], 3, CL.state.stats[ClientStat.health] <= 25 ? 1 : 0);

        // ammo icon
        if ((CL.state.items & it.shells) != 0)
            DrawPic(224, 0, ammo[0]);
        else if ((CL.state.items & it.nails) != 0)
            DrawPic(224, 0, ammo[1]);
        else if ((CL.state.items & it.rockets) != 0)
            DrawPic(224, 0, ammo[2]);
        else if ((CL.state.items & it.cells) != 0)
            DrawPic(224, 0, ammo[3]);
        else if (COM.rogue) {
            if ((CL.state.items & Def.rit.lava_nails) != 0)
                DrawPic(224, 0, r_ammo[0]);
            else if ((CL.state.items & Def.rit.plasma_ammo) != 0)
                DrawPic(224, 0, r_ammo[1]);
            else if ((CL.state.items & Def.rit.multi_rockets) != 0)
                DrawPic(224, 0, r_ammo[2]);
        }

        DrawNum(248, 0, CL.state.stats[ClientStat.ammo], 3, CL.state.stats[ClientStat.ammo] <= 10 ? 1 : 0);

        if (VID.width >= 512 && CL.state.gametype == 1)
            MiniDeathmatchOverlay();
    }

    static function IntermissionNumber(x:Int, y:Int, num:Int):Void {
        var str = Std.string(num);
        if (str.length > 3)
            str = str.substring(str.length - 3, str.length);
        else if (str.length < 3)
            x += (3 - str.length) * 24;
        for (i in 0...str.length) {
            var frame = str.charCodeAt(i);
            Draw.Pic(x, y, nums[0][frame == 45 ? 10 : frame - 48]);
            x += 24;
        }
    }

    static function DeathmatchOverlay():Void {
        Draw.Pic((VID.width - ranking.width) >> 1, 8, ranking);
        SortFrags();

        var x = (VID.width >> 1) - 80, y = 40;
        for (i in 0...scoreboardlines) {
            var s = CL.state.scores[fragsort[i]];
            if (s.name.length == 0)
                continue;
            Draw.Fill(x, y, 40, 4, (s.colors & 0xf0) + 8);
            Draw.Fill(x, y + 4, 40, 4, ((s.colors & 0xf) << 4) + 8);
            var f = Std.string(s.frags);
            Draw.String(x + 32 - (f.length << 3), y, f);
            if (fragsort[i] == (CL.state.viewentity - 1))
                Draw.Character(x - 8, y, 12);
            Draw.String(x + 64, y, s.name);
            y += 10;
        }
    }

    static function MiniDeathmatchOverlay():Void {
        SortFrags();
        var l = scoreboardlines;
        var y = VID.height - lines;
        var numlines = lines >> 3;

        var i = 0;
        while (i < l) {
            if (fragsort[i] == (CL.state.viewentity - 1))
                break;
            i++;
        }

        i = (i == l) ? 0 : i - (numlines >> 1);
        if (i > (l - numlines))
            i = l - numlines;
        if (i < 0)
            i = 0;

        while (i < l && y < (VID.height - 8)) {
            var k = fragsort[i++];
            var s = CL.state.scores[k];
            if (s.name.length == 0)
                continue;
            Draw.Fill(324, y + 1, 40, 3, (s.colors & 0xf0) + 8);
            Draw.Fill(324, y + 4, 40, 4, ((s.colors & 0xf) << 4) + 8);
            var num = Std.string(s.frags);
            Draw.String(356 - (num.length << 3), y, num);
            if (k == (CL.state.viewentity - 1)) {
                Draw.Character(324, y, 16);
                Draw.Character(356, y, 17);
            }
            Draw.String(372, y, s.name);
            y += 8;
        }
    }

    public static function IntermissionOverlay():Void {
        if (CL.state.gametype == 1) {
            DeathmatchOverlay();
            return;
        }
        Draw.Pic(64, 24, complete);
        Draw.Pic(0, 56, inter);

        var dig = Math.floor(CL.state.completed_time / 60.0);
        IntermissionNumber(160, 64, dig);
        var num = Math.floor(CL.state.completed_time - dig * 60);
        Draw.Pic(234, 64, colon);
        Draw.Pic(246, 64, nums[0][Math.floor(num / 10)]);
        Draw.Pic(266, 64, nums[0][Math.floor(num % 10)]);

        IntermissionNumber(160, 104, CL.state.stats[ClientStat.secrets]);
        Draw.Pic(232, 104, slash);
        IntermissionNumber(240, 104, CL.state.stats[ClientStat.totalsecrets]);

        IntermissionNumber(160, 144, CL.state.stats[ClientStat.monsters]);
        Draw.Pic(232, 144, slash);
        IntermissionNumber(240, 144, CL.state.stats[ClientStat.totalmonsters]);
    }

    public static inline function FinaleOverlay():Void {
        Draw.Pic((VID.width - finale.width) >> 1, 16, finale);
    }
}
