package quake;

import js.html.webgl.Program;
import js.html.webgl.UniformLocation;
import js.html.webgl.RenderingContext;

typedef GLTex = Int;
typedef GLUni = UniformLocation;
typedef GLAtt = Int;

@:autoBuild(quake.GLProgramMacro.build())
class GLProgram {
    var gl:RenderingContext;
    var program:Program;

    function new(gl, srcVert, srcFrag) {
        this.gl = gl;
        program = gl.createProgram();
        var vsh = gl.createShader(RenderingContext.VERTEX_SHADER);
        gl.shaderSource(vsh, srcVert);
        gl.compileShader(vsh);
        if (!gl.getShaderParameter(vsh, RenderingContext.COMPILE_STATUS))
            Sys.Error('Error compiling shader: ' + gl.getShaderInfoLog(vsh));

        var fsh = gl.createShader(RenderingContext.FRAGMENT_SHADER);
        gl.shaderSource(fsh, srcFrag);
        gl.compileShader(fsh);
        if (!gl.getShaderParameter(fsh, RenderingContext.COMPILE_STATUS))
            Sys.Error('Error compiling shader: ' + gl.getShaderInfoLog(fsh));

        gl.attachShader(program, vsh);
        gl.attachShader(program, fsh);

        gl.linkProgram(program);
        if (!gl.getProgramParameter(program, RenderingContext.LINK_STATUS))
            Sys.Error('Error linking program: ' + gl.getProgramInfoLog(program));
        gl.useProgram(program);
    }

    public inline function use():Void {
        gl.useProgram(program);
    }

    @:allow(quake.GL)
    function bind():Void {}

    @:allow(quake.GL)
    function unbind():Void {}

    public function setOrtho(ortho:Array<Float>):Void {}
    public function setGamma(gamma:Float):Void {}
    public function setViewOrigin(v:Vec):Void {}
    public function setViewAngles(v:Array<Float>):Void {}
    public function setPerspective(v:Array<Float>):Void {}
}
