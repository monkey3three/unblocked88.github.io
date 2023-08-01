package quake;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

class EdictVarsMacro {
    static function build():Array<Field> {
        var fields = Context.getBuildFields();
        var offset = 0;
        var addedFields = [];
        var inits = [];
        var initField = null;

        for (field in fields) {
            if (field.name == "init") {
                initField = field;
                continue;
            }
            switch (field.kind) {
                case FVar(ct, null):
                    var fieldName = field.name;
                    var viewField = switch (ct) {
                        case TPath({name: "Float"}): "floats";
                        case TPath({name: "Int"}): "ints";
                        case TPath({name: "Vec"}):
                            field.access = [APublic];
                            field.kind = FProp("default", "null", macro : quake.Vec);
                            inits.push(macro this.$fieldName = cast new js.html.Float32Array(buffer, $v{offset * 4}, 3));
                            offset += 3;
                            continue;
                        default: continue;
                    };
                    field.kind = FProp("get", "set", ct);
                    field.access = [APublic];
                    var ofsExpr = macro $v{offset};
                    if (Lambda.exists(field.meta, function(m) return m.name == ":dyn")) {
                        var ofsName = field.name + "_ofs";
                        ofsExpr = macro quake.EdictVars.$ofsName;
                    } else {
                        offset++;
                    }
                    addedFields.push({
                        pos: field.pos,
                        name: "get_" + field.name,
                        access: [APrivate, AInline],
                        kind: FFun({
                            ret: ct,
                            args: [],
                            expr: macro return this.$viewField[$ofsExpr]
                        })
                    });
                    addedFields.push({
                        pos: field.pos,
                        name: "set_" + field.name,
                        access: [APrivate, AInline],
                        kind: FFun({
                            ret: ct,
                            args: [{name: "value", type: ct}],
                            expr: macro return this.$viewField[$ofsExpr] = value
                        })
                    });
                default:
            }
        }
        switch (initField.kind) {
            case FFun(f):
                f.expr = macro $b{inits};
            default: throw false;
        }
        return fields.concat(addedFields);
    }
}
