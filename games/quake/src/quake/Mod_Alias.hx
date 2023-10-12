package quake;

import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Uint8Array;
import js.html.Float32Array;
import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;
import quake.Mod.MModel;
import quake.Mod.MFrame;
import quake.GL.gl;
import quake.GL.GLTexture;

@:publicFields
private class STVert {
    var onseam:Bool;
    var s:Int;
    var t:Int;
    function new(onseam, s, t) {
        this.onseam = onseam;
        this.s = s;
        this.t = t;
    }
}

@:publicFields
private class Triangle {
    var facesfront:Bool;
    var vertindex:Array<Int>;
    function new(facesfront, vertindex) {
        this.facesfront = facesfront;
        this.vertindex = vertindex;
    }
}

@:publicFields
class Trivert {
    var v:Array<Int>;
    var lightnormalindex:Int;
    function new(v, lightnormalindex) {
        this.v = v;
        this.lightnormalindex = lightnormalindex;
    }
}

@:publicFields
class Skin {
    var group:Bool;
    var skins:Array<Skin>;
    var interval:Float;
    var texturenum:GLTexture;
    var playertexture:Texture;
    function new(g) {
        this.group = g;
    }
}

class Mod_Alias {
    static inline var VERSION = 6;
    static var filledcolor:Int;

    public static function Init() {
        filledcolor = 0;
        for (i in 0...256) {
            if (VID.d_8to24table[i] == 0) {
                filledcolor = i;
                break;
            }
        }
    }

    public static function LoadAliasModel(loadmodel:MModel, model:DataView):Void {
        var version = model.getUint32(4, true);
        if (version != VERSION)
            Sys.Error(loadmodel.name + ' has wrong version number (' + version + ' should be ' + VERSION + ')');

        loadmodel.type = alias;
        loadmodel.player = loadmodel.name == 'progs/player.mdl';
        loadmodel.scale = Vec.of(model.getFloat32(8, true), model.getFloat32(12, true), model.getFloat32(16, true));
        loadmodel.scale_origin = Vec.of(model.getFloat32(20, true), model.getFloat32(24, true), model.getFloat32(28, true));
        loadmodel.boundingradius = model.getFloat32(32, true);
        loadmodel.numskins = model.getUint32(48, true);
        if (loadmodel.numskins == 0)
            Sys.Error('model ' + loadmodel.name + ' has no skins');
        loadmodel.skinwidth = model.getUint32(52, true);
        loadmodel.skinheight = model.getUint32(56, true);
        loadmodel.numverts = model.getUint32(60, true);
        if (loadmodel.numverts == 0)
            Sys.Error('model ' + loadmodel.name + ' has no vertices');
        loadmodel.numtris = model.getUint32(64, true);
        if (loadmodel.numtris == 0)
            Sys.Error('model ' + loadmodel.name + ' has no triangles');
        loadmodel.numframes = model.getUint32(68, true);
        if (loadmodel.numframes == 0)
            Sys.Error('model ' + loadmodel.name + ' has no frames');
        loadmodel.random = model.getUint32(72, true) == 1;
        loadmodel.flags = cast model.getUint32(76, true);
        loadmodel.mins = Vec.of(-16.0, -16.0, -16.0);
        loadmodel.maxs = Vec.of(16.0, 16.0, 16.0);

        var inmodel = LoadAllSkins(loadmodel, model, 84);

        var stverts = [];
        for (i in 0...loadmodel.numverts) {
            stverts.push(new STVert(
                model.getUint32(inmodel, true) != 0,
                model.getUint32(inmodel + 4, true),
                model.getUint32(inmodel + 8, true)
            ));
            inmodel += 12;
        }

        var triangles = [];
        for (i in 0...loadmodel.numtris) {
            triangles.push(new Triangle(
                model.getUint32(inmodel, true) != 0,
                [
                    model.getUint32(inmodel + 4, true),
                    model.getUint32(inmodel + 8, true),
                    model.getUint32(inmodel + 12, true)
                ]
            ));
            inmodel += 16;
        }

        LoadAllFrames(loadmodel, model, inmodel);

        var cmds = [];

        for (i in 0...loadmodel.numtris) {
            var triangle = triangles[i];
            if (triangle.facesfront) {
                var vert = stverts[triangle.vertindex[0]];
                cmds.push((vert.s + 0.5) / loadmodel.skinwidth);
                cmds.push((vert.t + 0.5) / loadmodel.skinheight);
                vert = stverts[triangle.vertindex[1]];
                cmds.push((vert.s + 0.5) / loadmodel.skinwidth);
                cmds.push((vert.t + 0.5) / loadmodel.skinheight);
                vert = stverts[triangle.vertindex[2]];
                cmds.push((vert.s + 0.5) / loadmodel.skinwidth);
                cmds.push((vert.t + 0.5) / loadmodel.skinheight);
                continue;
            }
            for (j in 0...3) {
                var vert = stverts[triangle.vertindex[j]];
                if (vert.onseam)
                    cmds.push((vert.s + loadmodel.skinwidth / 2 + 0.5) / loadmodel.skinwidth);
                else
                    cmds.push((vert.s + 0.5) / loadmodel.skinwidth);
                cmds.push((vert.t + 0.5) / loadmodel.skinheight);
            }
        }

        var group, frame;
        for (i in 0...loadmodel.numframes) {
            group = loadmodel.frames[i];
            if (group.group) {
                for (j in 0...group.frames.length) {
                    frame = group.frames[j];
                    frame.cmdofs = cmds.length << 2;
                    for (k in 0...loadmodel.numtris) {
                        var triangle = triangles[k];
                        for (l in 0...3) {
                            var vert = frame.v[triangle.vertindex[l]];
                            if (vert.lightnormalindex >= 162)
                                Sys.Error('lightnormalindex >= NUMVERTEXNORMALS');
                            cmds.push(vert.v[0] * loadmodel.scale[0] + loadmodel.scale_origin[0]);
                            cmds.push(vert.v[1] * loadmodel.scale[1] + loadmodel.scale_origin[1]);
                            cmds.push(vert.v[2] * loadmodel.scale[2] + loadmodel.scale_origin[2]);
                            cmds.push(Render.avertexnormals[vert.lightnormalindex * 3]);
                            cmds.push(Render.avertexnormals[vert.lightnormalindex * 3 + 1]);
                            cmds.push(Render.avertexnormals[vert.lightnormalindex * 3 + 2]);
                        }
                    }
                }
                continue;
            }
            frame = group;
            frame.cmdofs = cmds.length << 2;
            for (j in 0...loadmodel.numtris) {
                var triangle = triangles[j];
                for (k in 0...3) {
                    var vert = frame.v[triangle.vertindex[k]];
                    if (vert.lightnormalindex >= 162)
                        Sys.Error('lightnormalindex >= NUMVERTEXNORMALS');
                    cmds.push(vert.v[0] * loadmodel.scale[0] + loadmodel.scale_origin[0]);
                    cmds.push(vert.v[1] * loadmodel.scale[1] + loadmodel.scale_origin[1]);
                    cmds.push(vert.v[2] * loadmodel.scale[2] + loadmodel.scale_origin[2]);
                    cmds.push(Render.avertexnormals[vert.lightnormalindex * 3]);
                    cmds.push(Render.avertexnormals[vert.lightnormalindex * 3 + 1]);
                    cmds.push(Render.avertexnormals[vert.lightnormalindex * 3 + 2]);
                }
            }
        }

        loadmodel.cmds = gl.createBuffer();
        gl.bindBuffer(RenderingContext.ARRAY_BUFFER, loadmodel.cmds);
        gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32Array(cmds), RenderingContext.STATIC_DRAW);
    }


    static function LoadAllSkins(loadmodel:MModel, model:DataView, inmodel:Int):Int {
        loadmodel.skins = [];
        var skinsize = loadmodel.skinwidth * loadmodel.skinheight;
        for (i in 0...loadmodel.numskins) {
            inmodel += 4;
            if (model.getUint32(inmodel - 4, true) == 0) {
                var skin = new Uint8Array(model.buffer, inmodel, skinsize);
                FloodFillSkin(loadmodel, skin);
                var g = new Skin(false);
                g.texturenum = GL.LoadTexture(loadmodel.name + '_' + i,
                        loadmodel.skinwidth,
                        loadmodel.skinheight,
                        skin);
                loadmodel.skins[i] = g;
                if (loadmodel.player)
                    TranslatePlayerSkin(loadmodel, new Uint8Array(model.buffer, inmodel, skinsize), loadmodel.skins[i]);
                inmodel += skinsize;
            }
            else
            {
                var group = new Skin(true);
                var numskins = model.getUint32(inmodel, true);
                inmodel += 4;
                for (j in 0...numskins) {
                    var s = new Skin(false);
                    s.interval = model.getFloat32(inmodel, true);
                    if (s.interval <= 0.0)
                        Sys.Error('Mod.LoadAllSkins: interval<=0');
                    group.skins[j] = s;
                    inmodel += 4;
                }
                for (j in 0...numskins) {
                    var skin = new Uint8Array(model.buffer, inmodel, skinsize);
                    FloodFillSkin(loadmodel, skin);
                    group.skins[j].texturenum = GL.LoadTexture(loadmodel.name + '_' + i + '_' + j,
                        loadmodel.skinwidth,
                        loadmodel.skinheight,
                        skin);
                    if (loadmodel.player)
                        TranslatePlayerSkin(loadmodel, new Uint8Array(model.buffer, inmodel, skinsize), group.skins[j]);
                    inmodel += skinsize;
                }
                loadmodel.skins[i] = group;
            }
        }
        return inmodel;
    }

    static function LoadAllFrames(loadmodel:MModel, model:DataView, inmodel:Int):Void {
        loadmodel.frames = [];
        for (i in 0...loadmodel.numframes) {
            inmodel += 4;
            if (model.getUint32(inmodel - 4, true) == 0) {
                var frame = new MFrame(false);
                frame.group = false;
                frame.bboxmin = [model.getUint8(inmodel), model.getUint8(inmodel + 1), model.getUint8(inmodel + 2)];
                frame.bboxmax = [model.getUint8(inmodel + 4), model.getUint8(inmodel + 5), model.getUint8(inmodel + 6)];
                frame.name = Q.memstr(new Uint8Array(model.buffer, inmodel + 8, 16));
                frame.v = [];
                inmodel += 24;
                for (j in 0...loadmodel.numverts) {
                    frame.v[j] = new Trivert(
                        [model.getUint8(inmodel), model.getUint8(inmodel + 1), model.getUint8(inmodel + 2)],
                        model.getUint8(inmodel + 3)
                    );
                    inmodel += 4;
                }
                loadmodel.frames[i] = frame;
            }
            else
            {
                var group = new MFrame(true);
                group.bboxmin = [model.getUint8(inmodel + 4), model.getUint8(inmodel + 5), model.getUint8(inmodel + 6)];
                group.bboxmax = [model.getUint8(inmodel + 8), model.getUint8(inmodel + 9), model.getUint8(inmodel + 10)];
                group.frames = [];
                var numframes = model.getUint32(inmodel, true);
                inmodel += 12;
                for (j in 0...numframes) {
                    var f = new MFrame(false);
                    f.interval = model.getFloat32(inmodel, true);
                    group.frames[j] = f;
                    if (group.frames[j].interval <= 0.0)
                        Sys.Error('Mod.LoadAllFrames: interval<=0');
                    inmodel += 4;
                }
                for (j in 0...numframes) {
                    var frame = group.frames[j];
                    frame.bboxmin = [model.getUint8(inmodel), model.getUint8(inmodel + 1), model.getUint8(inmodel + 2)];
                    frame.bboxmax = [model.getUint8(inmodel + 4), model.getUint8(inmodel + 5), model.getUint8(inmodel + 6)];
                    frame.name = Q.memstr(new Uint8Array(model.buffer, inmodel + 8, 16));
                    frame.v = [];
                    inmodel += 24;
                    for (k in 0...loadmodel.numverts) {
                        frame.v[k] = new Trivert(
                            [model.getUint8(inmodel), model.getUint8(inmodel + 1), model.getUint8(inmodel + 2)],
                            model.getUint8(inmodel + 3)
                        );
                        inmodel += 4;
                    }
                }
                loadmodel.frames[i] = group;
            }
        }
    }

    static function FloodFillSkin(loadmodel:MModel, skin:Uint8Array) {
        var fillcolor = skin[0];
        if (fillcolor == filledcolor)
            return;

        var width = loadmodel.skinwidth;
        var height = loadmodel.skinheight;

        var lifo = [[0, 0]];
        var sp = 1;
        while (sp > 0) {
            var cur = lifo[--sp];
            var x = cur[0];
            var y = cur[1];
            skin[y * width + x] = filledcolor;
            if (x > 0) {
                if (skin[y * width + x - 1] == fillcolor)
                    lifo[sp++] = [x - 1, y];
            }
            if (x < (width - 1)) {
                if (skin[y * width + x + 1] == fillcolor)
                    lifo[sp++] = [x + 1, y];
            }
            if (y > 0) {
                if (skin[(y - 1) * width + x] == fillcolor)
                    lifo[sp++] = [x, y - 1];
            }
            if (y < (height - 1)) {
                if (skin[(y + 1) * width + x] == fillcolor)
                    lifo[sp++] = [x, y + 1];
            }
        }
    }

    static function TranslatePlayerSkin(loadmodel:MModel, data:Uint8Array, skin:Skin):Void {
        if (loadmodel.skinwidth != 512 || loadmodel.skinheight != 256)
            data = GL.ResampleTexture(data, loadmodel.skinwidth, loadmodel.skinheight, 512, 256);
        var out = new Uint8Array(new ArrayBuffer(512 * 256 * 4));
        for (i in 0...(512 * 256)) {
            var original = data[i];
            if ((original >> 4) == 1) {
                out[i << 2] = (original & 15) * 17;
                out[(i << 2) + 1] = 255;
            } else if ((original >> 4) == 6) {
                out[(i << 2) + 2] = (original & 15) * 17;
                out[(i << 2) + 3] = 255;
            }
        }
        skin.playertexture = gl.createTexture();
        GL.Bind(0, skin.playertexture);
        gl.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, 512, 256, 0, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, out);
        gl.generateMipmap(RenderingContext.TEXTURE_2D);
        gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, GL.filter_min);
        gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, GL.filter_max);
    }
}
