package quake;

import js.Browser.document;
import js.Browser.window;
import js.html.webgl.RenderingContext;
import quake.Draw.DrawPic;
import quake.GL.gl;

class SCR {
    public static var fov(default,null):Cvar;
    public static var viewsize(default,null):Cvar;
    public static var devicePixelRatio(default,null):Float;
    public static var con_current(default,null) = 0;
    public static var centertime_off = 0.0;
    public static var recalc_refdef = false;
    public static var disabled_for_loading = false;

    static var centerstring:Array<String> = [];
    static var centertime_start:Float;
    static var count = 0;
    static var screenshot = false;
    static var disabled_time:Float;

    static var oldfov:Float;
    static var oldscreensize:Float;

    static var conspeed:Cvar;
    static var showturtle:Cvar;
    static var showpause:Cvar;
    static var centertime:Cvar;
    static var printspeed:Cvar;

    static var net:DrawPic;
    static var turtle:DrawPic;
    static var pause:DrawPic;

    public static function Init():Void {
        fov = Cvar.RegisterVariable('fov', '90');
        viewsize = Cvar.RegisterVariable('viewsize', '100', true);
        conspeed = Cvar.RegisterVariable('scr_conspeed', '300');
        showturtle = Cvar.RegisterVariable('showturtle', '0');
        showpause = Cvar.RegisterVariable('showpause', '1');
        centertime = Cvar.RegisterVariable('scr_centertime', '2');
        printspeed = Cvar.RegisterVariable('scr_printspeed', '8');
        Cmd.AddCommand('screenshot', ScreenShot_f);
        Cmd.AddCommand('sizeup', SizeUp_f);
        Cmd.AddCommand('sizedown', SizeDown_f);
        net = Draw.PicFromWad('NET');
        turtle = Draw.PicFromWad('TURTLE');
        pause = Draw.CachePic('pause');
    }

    public static function CenterPrint(str:String):Void {
        centerstring = [];
        var start = 0;
        var i = 0;
        while (i < str.length) {
            var next;
            if (str.charCodeAt(i) == "\n".code) {
                next = i + 1;
            } else if ((i - start) >= 40) {
                next = i;
            } else {
                i++;
                continue;
            }
            centerstring.push(str.substring(start, i));
            start = next;
            i++;
        }
        centerstring.push(str.substring(start, i));
        centertime_off = centertime.value;
        centertime_start = CL.state.time;
    }

    public static function BeginLoadingPlaque():Void {
        S.StopAllSounds();
        if (CL.cls.state != connected || CL.cls.signon != 4)
            return;
        centertime_off = 0.0;
        con_current = 0;
        disabled_for_loading = true;
        disabled_time = Host.realtime + 60.0;
    }

    public static function EndLoadingPlaque():Void {
        disabled_for_loading = false;
        Console.ClearNotify();
    }

    public static function UpdateScreen() {
        if (disabled_for_loading) {
            if (Host.realtime <= disabled_time)
                return;
            disabled_for_loading = false;
            Console.Print('load failed.\n');
        }

        var elem = document.documentElement;
        var width = (elem.clientWidth <= 320) ? 320 : elem.clientWidth;
        var height = (elem.clientHeight <= 200) ? 200 : elem.clientHeight;
        var pixelRatio = if (window.devicePixelRatio >= 1.0) window.devicePixelRatio else 1.0;

        if (VID.width != width || VID.height != height || devicePixelRatio != pixelRatio || Host.framecount == 0) {
            VID.width = width;
            VID.height = height;
            VID.mainwindow.width = Std.int(width * pixelRatio);
            VID.mainwindow.height = Std.int(height * pixelRatio);
            VID.mainwindow.style.width = width + 'px';
            VID.mainwindow.style.height = height + 'px';
            devicePixelRatio = pixelRatio;
            recalc_refdef = true;
        }

        if (oldfov != fov.value) {
            oldfov = fov.value;
            recalc_refdef = true;
        }

        if (oldscreensize != viewsize.value) {
            oldscreensize = viewsize.value;
            recalc_refdef = true;
        }

        if (recalc_refdef)
            CalcRefdef();

        SetUpToDrawConsole();
        V.RenderView();
        GL.Set2D();

        if (Render.dowarp)
            Render.WarpScreen();

        if (!Console.forcedup)
            Render.PolyBlend();

        if (CL.cls.state == connecting) {
            DrawConsole();
        } else if (CL.state.intermission == 1 && Key.dest == game) {
            Sbar.IntermissionOverlay();
        } else if (CL.state.intermission == 2 && Key.dest == game) {
            Sbar.FinaleOverlay();
            DrawCenterString();
        } else if (CL.state.intermission == 3 && Key.dest == game) {
            DrawCenterString();
        } else {
            if (V.crosshair.value != 0) {
                Draw.Character(
                    Std.int(Render.refdef.vrect.x + (Render.refdef.vrect.width >> 1) + V.crossx.value),
                    Std.int(Render.refdef.vrect.y + (Render.refdef.vrect.height >> 1) + V.crossy.value),
                    "+".code
                );
            }
            DrawNet();
            DrawTurtle();
            DrawPause();
            DrawCenterString();
            Sbar.DrawSbar();
            DrawConsole();
            Menu.DrawMenu();
        }

        gl.disable(RenderingContext.BLEND);

        if (screenshot) {
            screenshot = false;
            gl.finish();
            window.open(VID.mainwindow.toDataURL('image/jpeg'));
        }
    }

    static function DrawCenterString():Void {
        centertime_off -= Host.frametime;
        if ((centertime_off <= 0.0 && CL.state.intermission == 0) || Key.dest != game)
            return;

        var y = if (centerstring.length <= 4) Math.floor(VID.height * 0.35) else 48;

        if (CL.state.intermission != 0) {
            var remaining = Math.floor(printspeed.value * (CL.state.time - centertime_start));
            for (str in centerstring) {
                var x = (VID.width - (str.length << 3)) >> 1;
                for (j in 0...str.length) {
                    Draw.Character(x, y, str.charCodeAt(j));
                    if ((remaining--) == 0)
                        return;
                    x += 8;
                }
                y += 8;
            }
            return;
        }

        for (s in centerstring) {
            Draw.String((VID.width - (s.length << 3)) >> 1, y, s);
            y += 8;
        }
    }

    static function CalcRefdef():Void {
        recalc_refdef = false;

        if (viewsize.value < 30)
            viewsize.set("30");
        else if (viewsize.value > 120)
            viewsize.set("120");

        var size, full = false;
        if (CL.state.intermission != 0) {
            full = true;
            size = 1.0;
            Sbar.lines = 0;
        } else {
            size = viewsize.value;
            if (size >= 120.0)
                Sbar.lines = 0;
            else if (size >= 110.0)
                Sbar.lines = 24;
            else
                Sbar.lines = 48;
            if (size >= 100.0) {
                full = true;
                size = 100.0;
            }
            size *= 0.01;
        }

        var vrect = Render.refdef.vrect;
        vrect.width = Math.floor(VID.width * size);
        if (vrect.width < 96) {
            size = 96.0 / vrect.width;
            vrect.width = 96;
        }
        vrect.height = Math.floor(VID.height * size);
        if (vrect.height > (VID.height - Sbar.lines))
            vrect.height = VID.height - Sbar.lines;
        vrect.x = (VID.width - vrect.width) >> 1;
        if (full)
            vrect.y = 0;
        else
            vrect.y = (VID.height - Sbar.lines - vrect.height) >> 1;

        if (fov.value < 10)
            fov.set("10");
        else if (fov.value > 170)
            fov.set("170");

        if ((vrect.width * 0.75) <= vrect.height) {
            Render.refdef.fov_x = fov.value;
            Render.refdef.fov_y = Math.atan(vrect.height / (vrect.width / Math.tan(fov.value * Math.PI / 360.0))) * 360.0 / Math.PI;
        } else {
            Render.refdef.fov_x = Math.atan(vrect.width / (vrect.height / Math.tan(fov.value * 0.82 * Math.PI / 360.0))) * 360.0 / Math.PI;
            Render.refdef.fov_y = fov.value * 0.82;
        }

        var ymax = 4.0 * Math.tan(Render.refdef.fov_y * Math.PI / 360.0);
        Render.perspective[0] = 4.0 / (ymax * Render.refdef.vrect.width / Render.refdef.vrect.height);
        Render.perspective[5] = 4.0 / ymax;
        GL.ortho[0] = 2.0 / VID.width;
        GL.ortho[5] = -2.0 / VID.height;

        Render.warpwidth = Std.int(vrect.width * devicePixelRatio);
        Render.warpheight = Std.int(vrect.height * devicePixelRatio);
        if (Render.warpwidth > 2048)
            Render.warpwidth = 2048;
        if (Render.warpheight > 2048)
            Render.warpheight = 2048;
        if (Render.oldwarpwidth != Render.warpwidth || Render.oldwarpheight != Render.warpheight) {
            Render.oldwarpwidth = Render.warpwidth;
            Render.oldwarpheight = Render.warpheight;
            GL.Bind(0, Render.warptexture);
            gl.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, Render.warpwidth, Render.warpheight, 0, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, null);
            gl.bindRenderbuffer(RenderingContext.RENDERBUFFER, Render.warprenderbuffer);
            gl.renderbufferStorage(RenderingContext.RENDERBUFFER, RenderingContext.DEPTH_COMPONENT16, Render.warpwidth, Render.warpheight);
            gl.bindRenderbuffer(RenderingContext.RENDERBUFFER, null);
        }
    }

    static function SizeUp_f():Void {
        viewsize.setValue(viewsize.value + 10);
        recalc_refdef = true;
    }

    static function SizeDown_f():Void {
        viewsize.setValue(viewsize.value - 10);
        recalc_refdef = true;
    }

    static function DrawTurtle():Void {
        if (showturtle.value == 0)
            return;
        if (Host.frametime < 0.1) {
            count = 0;
            return;
        }
        if (++count >= 3)
            Draw.Pic(Render.refdef.vrect.x, Render.refdef.vrect.y, turtle);
    }

    static function DrawNet():Void {
        if ((Host.realtime - CL.state.last_received_message) >= 0.3 && !CL.cls.demoplayback)
            Draw.Pic(Render.refdef.vrect.x, Render.refdef.vrect.y, net);
    }

    static function DrawPause():Void {
        if (showpause.value != 0 && CL.state.paused)
            Draw.Pic((VID.width - pause.width) >> 1, (VID.height - 48 - pause.height) >> 1, pause);
    }

    static function SetUpToDrawConsole():Void {
        Console.forcedup = (CL.state.worldmodel == null || CL.cls.signon != 4);

        if (Console.forcedup) {
            con_current = 200;
            return;
        }

        var conlines = if (Key.dest == console) 100 else 0;
        if (conlines < con_current) {
            con_current -= Std.int(conspeed.value * Host.frametime);
            if (conlines > con_current)
                con_current = conlines;
        } else if (conlines > con_current) {
            con_current += Std.int(conspeed.value * Host.frametime);
            if (conlines < con_current)
                con_current = conlines;
        }
    }

    static function DrawConsole():Void {
        if (con_current > 0) {
            Console.DrawConsole(con_current);
            return;
        }
        if (Key.dest == game || Key.dest == message)
            Console.DrawNotify();
    }

    static function ScreenShot_f():Void {
        screenshot = true;
    }
}
