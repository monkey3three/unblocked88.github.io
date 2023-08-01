class Tools {
    public static inline function toFixed(f:Float, p:Int):String {
        #if js
        return (cast f).toFixed(p);
        #else
        #error "TODO"
        #end
    }
}
