package quake;

class PRMacro {
    public static macro function SetEntVarField(field:String) {
        var ofsName = field + "_ofs";
        return macro {
            var def = ED.FindField($v{field});
            if (def != null) EdictVars.$ofsName = cast def.ofs;
        };
    }
}
