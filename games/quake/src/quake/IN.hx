package quake;

import js.Browser.document;
import js.html.MouseEvent;

@:access(quake.IN)
private class StdMouseHandler  {
    public static function attach():Void->Void {
        if ((cast VID.mainwindow).requestPointerLock != null) {
            VID.mainwindow.onclick = onclick;
            document.onmousemove = onmousemove;
            document.onpointerlockchange = onpointerlockchange;
            return detach;
        }
        return null;
    }

    static function detach():Void {
        VID.mainwindow.onclick = null;
        document.onmousemove = null;
        document.onpointerlockchange = null;
    }

    static function onclick():Void {
        if (document.pointerLockElement != VID.mainwindow)
            VID.mainwindow.requestPointerLock();
    }

    static function onmousemove(e:MouseEvent):Void {
        if (document.pointerLockElement != VID.mainwindow)
            return;
        IN.applyMouseMovement(e.movementX, e.movementY);
    }

    static function onpointerlockchange():Void {
        if (document.pointerLockElement == VID.mainwindow)
            return;
        IN.exitPointerLock();
    }
}

@:access(quake.IN)
private class MozMouseHandler {
    public static function attach():Void->Void {
        if ((cast VID.mainwindow).mozRequestPointerLock != null) {
            VID.mainwindow.onclick = onclick;
            document.onmousemove = onmousemove;
            (cast document).onmozpointerlockchange = onmozpointerlockchange;
            return detach;
        }
        return null;
    }

    static function detach():Void {
        VID.mainwindow.onclick = null;
        document.onmousemove = null;
        (cast document).onmozpointerlockchange = null;
    }

    static function onclick():Void {
        if ((cast document).mozPointerLockElement != VID.mainwindow)
            (cast VID.mainwindow).mozRequestPointerLock();
    }

    static function onmousemove(e:MouseEvent):Void {
        if ((cast document).mozPointerLockElement != VID.mainwindow)
            return;
        IN.applyMouseMovement((cast e).mozMovementX, (cast e).mozMovementY);
    }

    static function onmozpointerlockchange():Void {
        if ((cast document).mozPointerLockElement == VID.mainwindow)
            return;
        IN.exitPointerLock();
    }
}

@:access(quake.IN)
private class WebkitMouseHandler {
    public static function attach():Void->Void {
        if ((cast VID.mainwindow).webkitRequestPointerLock != null) {
            VID.mainwindow.onclick = onclick;
            document.onmousemove = onmousemove;
            (cast document).onwebkitpointerlockchange = onwebkitpointerlockchange;
            return detach;
        }
        return null;
    }

    static function detach():Void {
        VID.mainwindow.onclick = null;
        document.onmousemove = null;
        (cast document).onwebkitpointerlockchange = null;
    }

    static function onclick():Void {
        if ((cast document).webkitPointerLockElement != VID.mainwindow)
            (cast VID.mainwindow).webkitRequestPointerLock();
    }

    static function onmousemove(e:MouseEvent):Void {
        if ((cast document).webkitPointerLockElement != VID.mainwindow)
            return;
        IN.applyMouseMovement((cast e).webkitMovementX, (cast e).webkitMovementY);
    }

    static function onwebkitpointerlockchange():Void {
        if ((cast document).webkitPointerLockElement == VID.mainwindow)
            return;
        IN.exitPointerLock();
    }
}

class IN {

    static var mouse_x = 0.0;
    static var mouse_y = 0.0;
    static var old_mouse_x = 0.0;
    static var old_mouse_y = 0.0;
    static var mouse_avail = false;
    static var m_filter:Cvar;
    static var detachMouseHandler:Void->Void;

    public static function Init():Void {
        m_filter = Cvar.RegisterVariable('m_filter', '1');
        if (COM.CheckParm('-nomouse') != null)
            return;
        detachMouseHandler = attachMouseHandler();
        if (detachMouseHandler != null)
            mouse_avail = true;
    }

    public static function attachMouseHandler():Void->Void {
        var detach = StdMouseHandler.attach();
        if (detach == null)
            detach = MozMouseHandler.attach();
        if (detach == null)
            detach = WebkitMouseHandler.attach();
        return detach;
    }

    public static function Shutdown():Void {
        if (detachMouseHandler != null)
            detachMouseHandler();
    }

    public static function Move():Void {
        if (!mouse_avail)
            return;

        var mouse_x, mouse_y;
        if (m_filter.value != 0) {
            mouse_x = (IN.mouse_x + old_mouse_x) * 0.5;
            mouse_y = (IN.mouse_y + old_mouse_y) * 0.5;
        } else {
            mouse_x = IN.mouse_x;
            mouse_y = IN.mouse_y;
        }
        old_mouse_x = IN.mouse_x;
        old_mouse_y = IN.mouse_y;
        mouse_x *= CL.sensitivity.value;
        mouse_y *= CL.sensitivity.value;

        var strafe = CL.kbuttons[CL.kbutton.strafe].state & 1;
        var mlook = CL.kbuttons[CL.kbutton.mlook].state & 1;
        var angles = CL.state.viewangles;

        if (strafe != 0 || (CL.lookstrafe.value != 0 && mlook != 0))
            CL.state.cmd.sidemove += CL.m_side.value * mouse_x;
        else
            angles[1] -= CL.m_yaw.value * mouse_x;

        if (mlook != 0)
            V.StopPitchDrift();

        if (mlook != 0 && strafe == 0) {
            angles[0] += CL.m_pitch.value * mouse_y;
            if (angles[0] > 80.0)
                angles[0] = 80.0;
            else if (angles[0] < -70.0)
                angles[0] = -70.0;
        } else {
            if (strafe != 0 && Host.noclip_anglehack)
                CL.state.cmd.upmove -= CL.m_forward.value * mouse_y;
            else
                CL.state.cmd.forwardmove -= CL.m_forward.value * mouse_y;
        }

        IN.mouse_x = IN.mouse_y = 0;
    }

    static inline function applyMouseMovement(x:Int, y:Int):Void {
        IN.mouse_x += x;
        IN.mouse_y += y;
    }

    static inline function exitPointerLock():Void {
        Key.Event(escape, true);
        Key.Event(escape, false);
    }
}
