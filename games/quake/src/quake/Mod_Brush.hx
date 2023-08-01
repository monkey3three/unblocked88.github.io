package quake;

import js.html.DataView;
import js.html.Uint8Array;
import js.html.webgl.Texture;
import quake.Mod.MModel;

@:publicFields
class Hull {
    var clipnodes:Array<ClipNode>;
    var planes:Array<Plane>;
    var firstclipnode:Int;
    var lastclipnode:Int;
    var clip_mins:Vec;
    var clip_maxs:Vec;
    function new() {}
}

@:publicFields
class ClipNode {
    var planenum:Int;
    var child0:Int;
    var child1:Int;
    function new() {}
}

@:publicFields
class Surface {
    var extents:Array<Int>;
    var texturemins:Array<Int>;
    var light_s:Int;
    var light_t:Int;
    var dlightframe:Int;
    var dlightbits:Int;
    var plane:Plane;
    var texinfo:Int;
    var sky:Bool;
    var turbulent:Bool;
    var lightofs:Int;
    var styles:Array<Int>;
    var texture:Int;
    var verts:Array<Array<Float>>;
    var numedges:Int;
    var firstedge:Int;
    function new() {}
}

@:publicFields
class Node {
    var contents:Contents;
    var plane:Plane;
    var num:Int;
    var parent:Node;
    var child0:Node;
    var child1:Node;
    var numfaces:Int;
    var firstface:Int;
    var visframe:Int;
    var markvisframe:Int;
    var skychain:Int;
    var waterchain:Int;
    var mins:Vec;
    var maxs:Vec;
    var cmds:Array<Array<Int>>;
    var nummarksurfaces:Int;
    var firstmarksurface:Int;
    var planenum:Int;
    function new() {}
}

@:publicFields
class Leaf extends Node {
    var visofs:Int;
    var ambient_level:Array<Int>;
    function new() super();
}

@:publicFields
class Texinfo {
    var texture:Int;
    var vecs:Array<Array<Float>>;
    var flags:Int;
    function new(v,t,f) {
        vecs = v;
        texture = t;
        flags = f;
    }
}

@:publicFields
class MTexture {
    var name:String;
    var width:Int;
    var height:Int;
    var anim_base:Int;
    var anim_frame:Int;
    var anims:Array<Int>;
    var alternate_anims:Array<Int>;
    var sky:Bool;
    var turbulent:Bool;
    var texturenum:Texture;
    function new() {}
}

private class LumpOffsets {
    public static inline var entities     = (0 << 3) + 4;
    public static inline var planes       = (1 << 3) + 4;
    public static inline var textures     = (2 << 3) + 4;
    public static inline var vertexes     = (3 << 3) + 4;
    public static inline var visibility   = (4 << 3) + 4;
    public static inline var nodes        = (5 << 3) + 4;
    public static inline var texinfo      = (6 << 3) + 4;
    public static inline var faces        = (7 << 3) + 4;
    public static inline var lighting     = (8 << 3) + 4;
    public static inline var clipnodes    = (9 << 3) + 4;
    public static inline var leafs        = (10 << 3) + 4;
    public static inline var marksurfaces = (11 << 3) + 4;
    public static inline var edges        = (12 << 3) + 4;
    public static inline var surfedges    = (13 << 3) + 4;
    public static inline var models       = (14 << 3) + 4;
}

class Mod_Brush {
    static inline var VERSION = 29;

    public static var novis(default,null):Array<Int>;

    public static function Init() {
        novis = [];
        for (i in 0...1024)
            novis.push(0xff);
    }

    public static function PointInLeaf(p:Vec, model:MModel):Leaf {
        if (model == null || model.nodes == null)
            Sys.Error('Mod.PointInLeaf: bad model');
        var node = model.nodes[0];
        while (true) {
            if (node.contents < 0)
                return cast node;
            var plane = node.plane;
            if ((Vec.DotProduct(p, plane.normal) - plane.dist) > 0)
                node = node.child0;
            else
                node = node.child1;
        }
    }

    public static function LeafPVS(leaf:Leaf, model:MModel):Array<Int> {
        if (leaf == model.leafs[0])
            return novis;
        return DecompressVis(leaf.visofs, model);
    }

    static function DecompressVis(i:Int, model:MModel):Array<Int> {
        var decompressed = [];
        var out = 0;
        var row = (model.leafs.length + 7) >> 3;
        if (model.visdata == null) {
            while (row >= 0) {
                decompressed[out++] = 0xff;
                row--;
            }
            return decompressed;
        }
        var out = 0;
        while (out < row) {
            if (model.visdata[i] != 0) {
                decompressed[out++] = model.visdata[i++];
                continue;
            }
            var c = model.visdata[i + 1];
            while (c > 0) {
                decompressed[out++] = 0;
                c--;
            }
            i += 2;
        }
        return decompressed;
    }


    public static function LoadBrushModel(loadmodel:MModel, data:DataView):Void {
        var version = data.getUint32(0, true);
        if (version != VERSION)
            Sys.Error('Mod.LoadBrushModel: ' + loadmodel.name + ' has wrong version number (' + version + ' should be ' + VERSION + ')');

        loadmodel.type = brush;

        LoadVertexes(loadmodel, data);
        LoadEdges(loadmodel, data);
        LoadSurfedges(loadmodel, data);
        LoadTextures(loadmodel, data);
        LoadLighting(loadmodel, data);
        LoadPlanes(loadmodel, data);
        LoadTexinfo(loadmodel, data);
        LoadFaces(loadmodel, data);
        LoadMarksurfaces(loadmodel, data);
        LoadVisibility(loadmodel, data);
        LoadLeafs(loadmodel, data);
        LoadNodes(loadmodel, data);
        LoadClipnodes(loadmodel, data);
        MakeHull0(loadmodel);
        LoadEntities(loadmodel, data);
        LoadSubmodels(loadmodel, data);

        var mins = [0.0, 0.0, 0.0];
        var maxs = [0.0, 0.0, 0.0];

        for (vert in loadmodel.vertexes) {
            if (vert[0] < mins[0])
                mins[0] = vert[0];
            else if (vert[0] > maxs[0])
                maxs[0] = vert[0];

            if (vert[1] < mins[1])
                mins[1] = vert[1];
            else if (vert[1] > maxs[1])
                maxs[1] = vert[1];

            if (vert[2] < mins[2])
                mins[2] = vert[2];
            else if (vert[2] > maxs[2])
                maxs[2] = vert[2];
        }

        loadmodel.radius = Vec.Length(Vec.of(
            Math.max(Math.abs(mins[0]), Math.abs(maxs[0])),
            Math.max(Math.abs(mins[1]), Math.abs(maxs[1])),
            Math.max(Math.abs(mins[2]), Math.abs(maxs[2]))
        ));
    }

    static function LoadVertexes(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.vertexes, true);
        var filelen = view.getUint32(LumpOffsets.vertexes + 4, true);
        if ((filelen % 12) != 0)
            Sys.Error('Mod.LoadVisibility: funny lump size in ' + loadmodel.name);
        var count = Std.int(filelen / 12);
        loadmodel.vertexes = [];
        for (i in 0...count) {
            loadmodel.vertexes[i] = Vec.of(view.getFloat32(fileofs, true), view.getFloat32(fileofs + 4, true), view.getFloat32(fileofs + 8, true));
            fileofs += 12;
        }
    }

    static function LoadEdges(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.edges, true);
        var filelen = view.getUint32(LumpOffsets.edges + 4, true);
        if ((filelen & 3) != 0)
            Sys.Error('Mod.LoadEdges: funny lump size in ' + loadmodel.name);
        var count = filelen >> 2;
        loadmodel.edges = [];
        for (i in 0...count) {
            loadmodel.edges[i] = [view.getUint16(fileofs, true), view.getUint16(fileofs + 2, true)];
            fileofs += 4;
        }
    }

    static function LoadSurfedges(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.surfedges, true);
        var filelen = view.getUint32(LumpOffsets.surfedges + 4, true);
        var count = filelen >> 2;
        loadmodel.surfedges = [];
        for (i in 0...count)
            loadmodel.surfedges[i] = view.getInt32(fileofs + (i << 2), true);
    }

    static function LoadTextures(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.textures, true);
        loadmodel.textures = [];
        var nummiptex = view.getUint32(fileofs, true);
        var dataofs = fileofs + 4;
        for (i in 0...nummiptex) {
            var miptexofs = view.getInt32(dataofs, true);
            dataofs += 4;
            if (miptexofs == -1) {
                loadmodel.textures[i] = Render.notexture_mip;
                continue;
            }
            miptexofs += fileofs;
            var tx = new MTexture();
            {
                tx.name = Q.memstr(new Uint8Array(view.buffer, miptexofs, 16));
                tx.width = view.getUint32(miptexofs + 16, true);
                tx.height = view.getUint32(miptexofs + 20, true);
            }
            if (tx.name.substring(0, 3).toLowerCase() == 'sky') {
                Render.InitSky(new Uint8Array(view.buffer, miptexofs + view.getUint32(miptexofs + 24, true), 32768));
                tx.texturenum = Render.solidskytexture;
                Render.skytexturenum = i;
                tx.sky = true;
            }
            else
            {
                var glt = GL.LoadTexture(tx.name, tx.width, tx.height, new Uint8Array(view.buffer, miptexofs + view.getUint32(miptexofs + 24, true), tx.width * tx.height));
                tx.texturenum = glt.texnum;
                if (tx.name.charCodeAt(0) == 42)
                    tx.turbulent = true;
            }
            loadmodel.textures[i] = tx;
        }

        for (i in 0...nummiptex) {
            var tx = loadmodel.textures[i];
            if (tx.name.charCodeAt(0) != 43)
                continue;
            if (tx.name.charCodeAt(1) != 48)
                continue;
            var name = tx.name.substring(2);
            tx.anims = [i];
            tx.alternate_anims = [];
            for (j in 0...nummiptex) {
                var tx2 = loadmodel.textures[j];
                if (tx2.name.charCodeAt(0) != 43)
                    continue;
                if (tx2.name.substring(2) != name)
                    continue;
                var num = tx2.name.charCodeAt(1);
                if (num == 48)
                    continue;
                if ((num >= 49) && (num <= 57)) {
                    tx.anims[num - 48] = j;
                    tx2.anim_base = i;
                    tx2.anim_frame = num - 48;
                    continue;
                }
                if (num >= 97)
                    num -= 32;
                if ((num >= 65) && (num <= 74)) {
                    tx.alternate_anims[num - 65] = j;
                    tx2.anim_base = i;
                    tx2.anim_frame = num - 65;
                    continue;
                }
                Sys.Error('Bad animating texture ' + tx.name);
            }
            for (j in 0...tx.anims.length) {
                if (tx.anims[j] == null)
                    Sys.Error('Missing frame ' + j + ' of ' + tx.name);
            }
            for (j in 0...tx.alternate_anims.length) {
                if (tx.alternate_anims[j] == null)
                    Sys.Error('Missing frame ' + j + ' of ' + tx.name);
            }
            loadmodel.textures[i] = tx;
        }

        loadmodel.textures.push(Render.notexture_mip);
    }

    static function LoadLighting(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.lighting, true);
        var filelen = view.getUint32(LumpOffsets.lighting + 4, true);
        if (filelen == 0)
            return;
        loadmodel.lightdata = new Uint8Array(view.buffer.slice(fileofs, fileofs + filelen));
    }

    static function LoadPlanes(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.planes, true);
        var filelen = view.getUint32(LumpOffsets.planes + 4, true);
        if ((filelen % 20) != 0)
            Sys.Error('Mod.LoadPlanes: funny lump size in ' + loadmodel.name);
        var count = Std.int(filelen / 20);
        loadmodel.planes = [];
        for (i in 0...count) {
            var out = new Plane();
            out.normal.setValues(view.getFloat32(fileofs, true), view.getFloat32(fileofs + 4, true), view.getFloat32(fileofs + 8, true));
            out.dist = view.getFloat32(fileofs + 12, true);
            out.type = view.getUint32(fileofs + 16, true);
            out.signbits = 0;
            if (out.normal[0] < 0)
                ++out.signbits;
            if (out.normal[1] < 0)
                out.signbits += 2;
            if (out.normal[2] < 0)
                out.signbits += 4;
            loadmodel.planes[i] = out;
            fileofs += 20;
        }
    }

    static function LoadTexinfo(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.texinfo, true);
        var filelen = view.getUint32(LumpOffsets.texinfo + 4, true);
        if ((filelen % 40) != 0)
            Sys.Error('Mod.LoadTexinfo: funny lump size in ' + loadmodel.name);
        var count = Std.int(filelen / 40);
        loadmodel.texinfo = [];
        for (i in 0...count) {
            var out = new Texinfo(
                [
                    [view.getFloat32(fileofs, true), view.getFloat32(fileofs + 4, true), view.getFloat32(fileofs + 8, true), view.getFloat32(fileofs + 12, true)],
                    [view.getFloat32(fileofs + 16, true), view.getFloat32(fileofs + 20, true), view.getFloat32(fileofs + 24, true), view.getFloat32(fileofs + 28, true)]
                ],
                view.getUint32(fileofs + 32, true),
                view.getUint32(fileofs + 36, true)
            );
            if (out.texture >= loadmodel.textures.length) {
                out.texture = loadmodel.textures.length - 1;
                out.flags = 0;
            }
            loadmodel.texinfo[i] = out;
            fileofs += 40;
        }
    }

    static function LoadFaces(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.faces, true);
        var filelen = view.getUint32(LumpOffsets.faces + 4, true);
        if ((filelen % 20) != 0)
            Sys.Error('Mod.LoadFaces: funny lump size in ' + loadmodel.name);
        var count = Std.int(filelen / 20);
        loadmodel.firstface = 0;
        loadmodel.numfaces = count;
        loadmodel.faces = [];
        for (i in 0...count) {
            var styles = new Uint8Array(view.buffer, fileofs + 12, 4);
            var out = new Surface();
            out.plane = loadmodel.planes[view.getUint16(fileofs, true)];
            out.firstedge = view.getUint16(fileofs + 4, true);
            out.numedges = view.getUint16(fileofs + 8, true);
            out.texinfo = view.getUint16(fileofs + 10, true);
            out.styles = [];
            out.lightofs = view.getInt32(fileofs + 16, true);
            if (styles[0] != 255)
                out.styles[0] = styles[0];
            if (styles[1] != 255)
                out.styles[1] = styles[1];
            if (styles[2] != 255)
                out.styles[2] = styles[2];
            if (styles[3] != 255)
                out.styles[3] = styles[3];

            var mins = [999999.0, 999999.0];
            var maxs = [-99999.0, -99999.0];
            var tex = loadmodel.texinfo[out.texinfo];
            out.texture = tex.texture;
            for (j in 0...out.numedges) {
                var e = loadmodel.surfedges[out.firstedge + j];
                var v;
                if (e >= 0)
                    v = loadmodel.vertexes[loadmodel.edges[e][0]];
                else
                    v = loadmodel.vertexes[loadmodel.edges[-e][1]];

                var val = Vec.DotProduct(v, Vec.ofArray(tex.vecs[0])) + tex.vecs[0][3];
                if (val < mins[0])
                    mins[0] = val;
                if (val > maxs[0])
                    maxs[0] = val;
                val = Vec.DotProduct(v, Vec.ofArray(tex.vecs[1])) + tex.vecs[1][3];
                if (val < mins[1])
                    mins[1] = val;
                if (val > maxs[1])
                    maxs[1] = val;
            }
            out.texturemins = [Math.floor(mins[0] / 16) * 16, Math.floor(mins[1] / 16) * 16];
            out.extents = [Math.ceil(maxs[0] / 16) * 16 - out.texturemins[0], Math.ceil(maxs[1] / 16) * 16 - out.texturemins[1]];

            if (loadmodel.textures[tex.texture].turbulent)
                out.turbulent = true;
            else if (loadmodel.textures[tex.texture].sky)
                out.sky = true;

            loadmodel.faces[i] = out;
            fileofs += 20;
        }
    }

    static function LoadMarksurfaces(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.marksurfaces, true);
        var filelen = view.getUint32(LumpOffsets.marksurfaces + 4, true);
        var count = filelen >> 1;
        loadmodel.marksurfaces = [];
        for (i in 0...count) {
            var j = view.getUint16(fileofs + (i << 1), true);
            if (j > loadmodel.faces.length)
                Sys.Error('Mod.LoadMarksurfaces: bad surface number');
            loadmodel.marksurfaces[i] = j;
        }
    }

    static function LoadVisibility(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.visibility, true);
        var filelen = view.getUint32(LumpOffsets.visibility + 4, true);
        if (filelen == 0)
            return;
        loadmodel.visdata = new Uint8Array(view.buffer.slice(fileofs, fileofs + filelen));
    }

    static function LoadLeafs(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.leafs, true);
        var filelen = view.getUint32(LumpOffsets.leafs + 4, true);
        if ((filelen % 28) != 0)
            Sys.Error('Mod.LoadLeafs: funny lump size in ' + loadmodel.name);
        var count = Std.int(filelen / 28);
        loadmodel.leafs = [];
        for (i in 0...count) {
            var out = new Leaf();
            out.num = i;
            out.contents = view.getInt32(fileofs, true);
            out.visofs = view.getInt32(fileofs + 4, true);
            out.mins = Vec.of(view.getInt16(fileofs + 8, true), view.getInt16(fileofs + 10, true), view.getInt16(fileofs + 12, true));
            out.maxs = Vec.of(view.getInt16(fileofs + 14, true), view.getInt16(fileofs + 16, true), view.getInt16(fileofs + 18, true));
            out.firstmarksurface = view.getUint16(fileofs + 20, true);
            out.nummarksurfaces = view.getUint16(fileofs + 22, true);
            out.ambient_level = [view.getUint8(fileofs + 24), view.getUint8(fileofs + 25), view.getUint8(fileofs + 26), view.getUint8(fileofs + 27)];
            out.cmds = [];
            out.skychain = 0;
            out.waterchain = 0;
            loadmodel.leafs.push(out);
            fileofs += 28;
        };
    }

    static function LoadNodes(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.nodes, true);
        var filelen = view.getUint32(LumpOffsets.nodes + 4, true);
        if ((filelen == 0) || ((filelen % 24) != 0))
            Sys.Error('Mod.LoadNodes: funny lump size in ' + loadmodel.name);
        var count = Std.int(filelen / 24);
        loadmodel.nodes = [];
        var children = new haxe.ds.Vector(count);
        for (i in 0...count) {
            var n = loadmodel.nodes[i] = new Node();
            n.num = i;
            n.contents = 0;
            n.planenum = view.getUint32(fileofs, true);
            children[i] = [view.getInt16(fileofs + 4, true), view.getInt16(fileofs + 6, true)];
            n.mins = Vec.of(view.getInt16(fileofs + 8, true), view.getInt16(fileofs + 10, true), view.getInt16(fileofs + 12, true));
            n.maxs = Vec.of(view.getInt16(fileofs + 14, true), view.getInt16(fileofs + 16, true), view.getInt16(fileofs + 18, true));
            n.firstface = view.getUint16(fileofs + 20, true);
            n.numfaces = view.getUint16(fileofs + 22, true);
            n.cmds = [];
            fileofs += 24;
        }
        for (i in 0...count) {
            var out = loadmodel.nodes[i];
            out.plane = loadmodel.planes[out.planenum];
            var children = children[i];
            if (children[0] >= 0)
                out.child0 = loadmodel.nodes[children[0]];
            else
                out.child0 = loadmodel.leafs[-1 - children[0]];
            if (children[1] >= 0)
                out.child1 = loadmodel.nodes[children[1]];
            else
                out.child1 = loadmodel.leafs[-1 - children[1]];
        }
        SetParent(loadmodel.nodes[0], null);
    }

    static function SetParent(node:Node, parent:Node):Void {
        node.parent = parent;
        if (node.contents < 0)
            return;
        SetParent(node.child0, node);
        SetParent(node.child1, node);
    }

    static function LoadClipnodes(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.clipnodes, true);
        var filelen = view.getUint32(LumpOffsets.clipnodes + 4, true);
        var count = filelen >> 3;
        loadmodel.clipnodes = [];

        loadmodel.hulls = [];
        loadmodel.hulls[1] = {
            var h = new Hull();
            h.clipnodes = loadmodel.clipnodes;
            h.firstclipnode = 0;
            h.lastclipnode = count - 1;
            h.planes = loadmodel.planes;
            h.clip_mins = Vec.of(-16.0, -16.0, -24.0);
            h.clip_maxs = Vec.of(16.0, 16.0, 32.0);
            h;
        };
        loadmodel.hulls[2] = {
            var h = new Hull();
            h.clipnodes = loadmodel.clipnodes;
            h.firstclipnode = 0;
            h.lastclipnode = count - 1;
            h.planes = loadmodel.planes;
            h.clip_mins = Vec.of(-32.0, -32.0, -24.0);
            h.clip_maxs = Vec.of(32.0, 32.0, 64.0);
            h;
        };
        for (i in 0...count) {
            var n = new ClipNode();
            n.planenum = view.getUint32(fileofs, true);
            n.child0 = view.getInt16(fileofs + 4, true);
            n.child1 = view.getInt16(fileofs + 6, true);
            loadmodel.clipnodes.push(n);
            fileofs += 8;
        }
    }

    static function MakeHull0(loadmodel:MModel) {
        var clipnodes = [];
        var hull = {
            var h = new Hull();
            h.clipnodes = clipnodes;
            h.lastclipnode = loadmodel.nodes.length - 1;
            h.planes = loadmodel.planes;
            h.clip_mins = new Vec();
            h.clip_maxs = new Vec();
            h;
        };
        for (i in 0...loadmodel.nodes.length) {
            var node = loadmodel.nodes[i];
            var out = new ClipNode();
            out.planenum = node.planenum;

            var child = node.child0;
            out.child0 = child.contents < 0 ? child.contents : child.num;
            child = node.child1;
            out.child1 = child.contents < 0 ? child.contents : child.num;

            clipnodes[i] = out;
        }
        loadmodel.hulls[0] = hull;
    }

    static function LoadEntities(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.entities, true);
        var filelen = view.getUint32(LumpOffsets.entities + 4, true);
        loadmodel.entities = Q.memstr(new Uint8Array(view.buffer, fileofs, filelen));
    }

    static function LoadSubmodels(loadmodel:MModel, view:DataView):Void {
        var fileofs = view.getUint32(LumpOffsets.models, true);
        var filelen = view.getUint32(LumpOffsets.models + 4, true);
        var count = filelen >> 6;
        if (count == 0)
            Sys.Error('Mod.LoadSubmodels: funny lump size in ' + loadmodel.name);
        loadmodel.submodels = [];

        loadmodel.mins = Vec.of(view.getFloat32(fileofs, true) - 1.0,
            view.getFloat32(fileofs + 4, true) - 1.0,
            view.getFloat32(fileofs + 8, true) - 1.0);
        loadmodel.maxs = Vec.of(view.getFloat32(fileofs + 12, true) + 1.0,
            view.getFloat32(fileofs + 16, true) + 1.0,
            view.getFloat32(fileofs + 20, true) + 1.0);
        loadmodel.hulls[0].firstclipnode = view.getUint32(fileofs + 36, true);
        loadmodel.hulls[1].firstclipnode = view.getUint32(fileofs + 40, true);
        loadmodel.hulls[2].firstclipnode = view.getUint32(fileofs + 44, true);
        fileofs += 64;

        var clipnodes = loadmodel.hulls[0].clipnodes;
        for (i in 1...count) {
            var out = Mod.FindName('*' + i);
            out.needload = false;
            out.type = brush;
            out.submodel = true;
            out.mins = Vec.of(view.getFloat32(fileofs, true) - 1.0,
                view.getFloat32(fileofs + 4, true) - 1.0,
                view.getFloat32(fileofs + 8, true) - 1.0);
            out.maxs = Vec.of(view.getFloat32(fileofs + 12, true) + 1.0,
                view.getFloat32(fileofs + 16, true) + 1.0,
                view.getFloat32(fileofs + 20, true) + 1.0);
            out.origin = Vec.of(view.getFloat32(fileofs + 24, true), view.getFloat32(fileofs + 28, true), view.getFloat32(fileofs + 32, true));
            out.hulls = [
                {
                    var h = new Hull();
                    h.clipnodes = clipnodes;
                    h.firstclipnode = view.getUint32(fileofs + 36, true);
                    h.lastclipnode = loadmodel.nodes.length - 1;
                    h.planes = loadmodel.planes;
                    h.clip_mins = new Vec();
                    h.clip_maxs = new Vec();
                    h;
                },
                {
                    var h = new Hull();
                    h.clipnodes = loadmodel.clipnodes;
                    h.firstclipnode = view.getUint32(fileofs + 40, true);
                    h.lastclipnode = loadmodel.clipnodes.length - 1;
                    h.planes = loadmodel.planes;
                    h.clip_mins = Vec.of(-16.0, -16.0, -24.0);
                    h.clip_maxs = Vec.of(16.0, 16.0, 32.0);
                    h;
                },
                {
                    var h = new Hull();
                    h.clipnodes = loadmodel.clipnodes;
                    h.firstclipnode = view.getUint32(fileofs + 44, true);
                    h.lastclipnode = loadmodel.clipnodes.length - 1;
                    h.planes = loadmodel.planes;
                    h.clip_mins = Vec.of(-32.0, -32.0, -24.0);
                    h.clip_maxs = Vec.of(32.0, 32.0, 64.0);
                    h;
                }
            ];
            out.textures = loadmodel.textures;
            out.lightdata = loadmodel.lightdata;
            out.faces = loadmodel.faces;
            out.firstface = view.getUint32(fileofs + 56, true);
            out.numfaces = view.getUint32(fileofs + 60, true);
            loadmodel.submodels[i - 1] = out;
            fileofs += 64;
        }
    }
}
