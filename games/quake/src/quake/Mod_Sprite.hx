package quake;

import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Uint8Array;
import js.html.Uint32Array;
import js.html.webgl.RenderingContext;
import quake.Mod.MModel;
import quake.Mod.MFrame;
import quake.GL.gl;
import quake.GL.GLTexture;

class Mod_Sprite {
    static inline var VERSION = 1;

    public static function LoadSpriteModel(loadmodel:MModel, model:DataView):Void {
        var version = model.getUint32(4, true);
        if (version != VERSION)
            Sys.Error(loadmodel.name + ' has wrong version number (' + version + ' should be ' + VERSION + ')');

        loadmodel.type = sprite;
        loadmodel.oriented = model.getUint32(8, true) == 3;
        loadmodel.boundingradius = model.getFloat32(12, true);
        loadmodel.width = model.getUint32(16, true);
        loadmodel.height = model.getUint32(20, true);
        loadmodel.numframes = model.getUint32(24, true);
        if (loadmodel.numframes == 0)
            Sys.Error('model ' + loadmodel.name + ' has no frames');
        loadmodel.random = model.getUint32(32, true) == 1;
        loadmodel.mins = Vec.of(loadmodel.width * -0.5, loadmodel.width * -0.5, loadmodel.height * -0.5);
        loadmodel.maxs = Vec.of(loadmodel.width * 0.5, loadmodel.width * 0.5, loadmodel.height * 0.5);

        loadmodel.frames = [];
        var inframe = 36, frame, group, numframes;
        for (i in 0...loadmodel.numframes) {
            inframe += 4;
            if (model.getUint32(inframe - 4, true) == 0) {
                frame = new MFrame(false);
                loadmodel.frames[i] = frame;
                inframe = LoadSpriteFrame(loadmodel.name + '_' + i, model, inframe, frame);
            }
            else
            {
                group = new MFrame(true);
                group.frames = [];
                loadmodel.frames[i] = group;
                numframes = model.getUint32(inframe, true);
                inframe += 4;
                for (j in 0...numframes) {
                    var f  = new MFrame(false);
                    f.interval = model.getFloat32(inframe, true);
                    group.frames[j] = f;
                    if (group.frames[j].interval <= 0.0)
                        Sys.Error('Mod.LoadSpriteModel: interval<=0');
                    inframe += 4;
                }
                for (j in 0...numframes)
                    inframe = LoadSpriteFrame(loadmodel.name + '_' + i + '_' + j, model, inframe, group.frames[j]);
            }
        }
    }

    static function LoadSpriteFrame(identifier:String, model:DataView, inframe:Int, frame:MFrame):Int {
        frame.origin = [model.getInt32(inframe, true), -model.getInt32(inframe + 4, true)];
        frame.width = model.getUint32(inframe + 8, true);
        frame.height = model.getUint32(inframe + 12, true);
        var size = frame.width * frame.height;

        for (glt in GL.textures) {
            if (glt.identifier == identifier) {
                if ((frame.width != glt.width) || (frame.height != glt.height))
                    Sys.Error('Mod.LoadSpriteFrame: cache mismatch');
                frame.texturenum = glt.texnum;
                return inframe + 16 + frame.width * frame.height;
            }
        }

        var data = new Uint8Array(model.buffer, inframe + 16, size);
        var scaled_width = frame.width, scaled_height = frame.height;
        if (((frame.width & (frame.width - 1)) != 0) || ((frame.height & (frame.height - 1)) != 0)) {
            --scaled_width;
            scaled_width |= (scaled_width >> 1);
            scaled_width |= (scaled_width >> 2);
            scaled_width |= (scaled_width >> 4);
            scaled_width |= (scaled_width >> 8);
            scaled_width |= (scaled_width >> 16);
            ++scaled_width;
            --scaled_height;
            scaled_height |= (scaled_height >> 1);
            scaled_height |= (scaled_height >> 2);
            scaled_height |= (scaled_height >> 4);
            scaled_height |= (scaled_height >> 8);
            scaled_height |= (scaled_height >> 16);
            ++scaled_height;
        }
        if (scaled_width > GL.maxtexturesize)
            scaled_width = GL.maxtexturesize;
        if (scaled_height > GL.maxtexturesize)
            scaled_height = GL.maxtexturesize;
        if ((scaled_width != frame.width) || (scaled_height != frame.height)) {
            size = scaled_width * scaled_height;
            data = GL.ResampleTexture(data, frame.width, frame.height, scaled_width, scaled_height);
        }

        var trans = new ArrayBuffer(size << 2);
        var trans32 = new Uint32Array(trans);
        for (i in 0...size) {
            if (data[i] != 255)
                trans32[i] = COM.LittleLong(VID.d_8to24table[data[i]] + 0xff000000);
        }

        var glt = new GLTexture(identifier, frame.width, frame.height);
        GL.Bind(0, glt.texnum);
        gl.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, scaled_width, scaled_height, 0, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, new Uint8Array(trans));
        gl.generateMipmap(RenderingContext.TEXTURE_2D);
        gl.texParameterf(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, GL.filter_min);
        gl.texParameterf(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, GL.filter_max);
        GL.textures.push(glt);
        frame.texturenum = glt.texnum;
        return inframe + 16 + frame.width * frame.height;
    }
}
