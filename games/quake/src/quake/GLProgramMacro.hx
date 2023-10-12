package quake;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

class GLProgramMacro {
    static var shadersDir = Context.resolvePath("shaders");

    static function build() {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();
        var shaderMeta = cls.meta.extract(":shader");
        var shaderName = switch (shaderMeta) {
            case [{name: ":shader", params: [{expr: EConst(CString(s))}]}]: s;
            default: throw new Error("No @:shader(\"name\") meta or it's invalid", cls.pos);
        }

        var path = shadersDir + "/" + shaderName;
        var vert = sys.io.File.getContent(path + ".vert");
        var frag = sys.io.File.getContent(path + ".frag");

        var ctorExprs = [macro super(gl, $v{vert}, $v{frag})];
        var bindExprs = [];
        var unbindExprs = [];
        var texNum = 0;

        var pos = Context.currentPos();

        for (field in fields) {
            switch (field.kind) {
                case FVar(ct, _):
                    switch (ct.toType()) {
                        case TType(_.get() => dt, _):
                            var name = field.name;
                            switch (dt.name) {
                                case "GLUni":
                                    ctorExprs.push(macro this.$name = this.gl.getUniformLocation(this.program, $v{name}));

                                    switch (name) {
                                        case "uOrtho":
                                            fields.push({
                                                pos: pos,
                                                name: "setOrtho",
                                                access: [AOverride],
                                                kind: FFun({
                                                    ret: null,
                                                    args: [{name: "ortho", type: macro : Array<Float>}],
                                                    expr: macro this.gl.uniformMatrix4fv(this.uOrtho, false, ortho)
                                                })
                                            });
                                        case "uGamma":
                                            fields.push({
                                                pos: pos,
                                                name: "setGamma",
                                                access: [AOverride],
                                                kind: FFun({
                                                    ret: null,
                                                    args: [{name: "gamma", type: macro : Float}],
                                                    expr: macro this.gl.uniform1f(this.uGamma, gamma)
                                                })
                                            });
                                        case "uViewOrigin":
                                            fields.push({
                                                pos: pos,
                                                name: "setViewOrigin",
                                                access: [AOverride],
                                                kind: FFun({
                                                    ret: null,
                                                    args: [{name: "v", type: macro : quake.Vec}],
                                                    expr: macro this.gl.uniform3fv(this.uViewOrigin, v)
                                                })
                                            });
                                        case "uViewAngles":
                                            fields.push({
                                                pos: pos,
                                                name: "setViewAngles",
                                                access: [AOverride],
                                                kind: FFun({
                                                    ret: null,
                                                    args: [{name: "v", type: macro : Array<Float>}],
                                                    expr: macro this.gl.uniformMatrix3fv(this.uViewAngles, false, v)
                                                })
                                            });
                                        case "uPerspective":
                                            fields.push({
                                                pos: pos,
                                                name: "setPerspective",
                                                access: [AOverride],
                                                kind: FFun({
                                                    ret: null,
                                                    args: [{name: "v", type: macro : Array<Float>}],
                                                    expr: macro this.gl.uniformMatrix4fv(this.uPerspective, false, v)
                                                })
                                            });
                                    }

                                case "GLAtt":
                                    ctorExprs.push(macro this.$name = this.gl.getAttribLocation(this.program, $v{name}));
                                    bindExprs.push(macro this.gl.enableVertexAttribArray(this.$name));
                                    unbindExprs.push(macro this.gl.disableVertexAttribArray(this.$name));
                                case "GLTex":
                                    var id = texNum++;
                                    ctorExprs.push(macro this.$name = $v{id});
                                    ctorExprs.push(macro this.gl.uniform1i(this.gl.getUniformLocation(this.program, $v{name}), $v{id}));
                                default:
                                    continue;
                            }
                            field.kind = FProp("default", "null", ct);
                            field.access.push(APublic);
                        default:
                    }
                default:
            }
        }

        fields.push({
            pos: pos,
            name: "new",
            access: [APublic],
            kind: FFun({
                ret: null,
                args: [{name: "gl", type: null}],
                expr: macro $b{ctorExprs}
            })
        });
        if (bindExprs.length > 0) {
            fields.push({
                pos: pos,
                name: "bind",
                access: [AOverride],
                kind: FFun({
                    ret: null,
                    args: [],
                    expr: macro $b{bindExprs}
                })
            });
            fields.push({
                pos: pos,
                name: "unbind",
                access: [AOverride],
                kind: FFun({
                    ret: null,
                    args: [],
                    expr: macro $b{unbindExprs}
                })
            });
        }

        return fields;
    }
}
#end
