package quake;

import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Uint8Array;

class W {
    static var lumps = new Map<String, ArrayBuffer>();

    public static function LoadWadFile(filename:String):Void {
        var base = COM.LoadFile(filename);
        if (base == null)
            Sys.Error('W.LoadWadFile: couldn\'t load ' + filename);
        var view = new DataView(base);
        if (view.getUint32(0, true) != 0x32444157)
            Sys.Error('Wad file ' + filename + ' doesn\'t have WAD2 id');
        var numlumps = view.getUint32(4, true);
        var infotableofs = view.getUint32(8, true);
        for (i in 0...numlumps) {
            var size = view.getUint32(infotableofs + 4, true);
            var lump = new ArrayBuffer(size);
            new Uint8Array(lump).set(new Uint8Array(base, view.getUint32(infotableofs, true), size));
            lumps[Q.memstr(new Uint8Array(base, infotableofs + 16, 16)).toUpperCase()] = lump;
            infotableofs += 32;
        }
    }

    public static function GetLumpName(name:String):ArrayBuffer {
        var lump = lumps[name];
        if (lump == null)
            Sys.Error('W.GetLumpName: ' + name + ' not found');
        return lump;
    }
}
