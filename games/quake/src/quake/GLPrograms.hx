package quake;

import quake.GLProgram;

@:shader("character")
class PCharacter extends GLProgram {
    var uCharacter:GLUni;
    var uDest:GLUni;
    var uOrtho:GLUni;
    var aPoint:GLAtt;
    var tTexture:GLTex;
}

@:shader("fill")
class PFill extends GLProgram {
    var uRect:GLUni;
    var uOrtho:GLUni;
    var uColor:GLUni;
    var aPoint:GLAtt;
}

@:shader("pic")
class PPic extends GLProgram {
    var uRect:GLUni;
    var uOrtho:GLUni;
    var aPoint:GLAtt;
    var tTexture:GLTex;
}

@:shader("picTranslate")
class PPicTranslate extends GLProgram {
    var uRect:GLUni;
    var uOrtho:GLUni;
    var uTop:GLUni;
    var uBottom:GLUni;
    var aPoint:GLAtt;
    var tTexture:GLTex;
    var tTrans:GLTex;
}

@:shader("particle")
class PParticle extends GLProgram {
    var uOrigin:GLUni;
    var uViewOrigin:GLUni;
    var uViewAngles:GLUni;
    var uPerspective:GLUni;
    var uScale:GLUni;
    var uGamma:GLUni;
    var uColor:GLUni;
    var aPoint:GLAtt;
}

interface IPAlias {
    var uOrigin(default,null):GLUni;
    var uAngles(default,null):GLUni;
    var uViewOrigin(default,null):GLUni;
    var uViewAngles(default,null):GLUni;
    var uPerspective(default,null):GLUni;
    var uLightVec(default,null):GLUni;
    var uGamma(default,null):GLUni;
    var uAmbientLight(default,null):GLUni;
    var uShadeLight(default,null):GLUni;
    var aPoint(default,null):GLAtt;
    var aLightNormal(default,null):GLAtt;
    var aTexCoord(default,null):GLAtt;
    var tTexture(default,null):GLTex;
}

@:shader("alias")
class PAlias extends GLProgram implements IPAlias {
    var uOrigin:GLUni;
    var uAngles:GLUni;
    var uViewOrigin:GLUni;
    var uViewAngles:GLUni;
    var uPerspective:GLUni;
    var uLightVec:GLUni;
    var uGamma:GLUni;
    var uAmbientLight:GLUni;
    var uShadeLight:GLUni;
    var aPoint:GLAtt;
    var aLightNormal:GLAtt;
    var aTexCoord:GLAtt;
    var tTexture:GLTex;
}

@:shader("brush")
class PBrush extends GLProgram {
    var uOrigin:GLUni;
    var uAngles:GLUni;
    var uViewOrigin:GLUni;
    var uViewAngles:GLUni;
    var uPerspective:GLUni;
    var uGamma:GLUni;
    var aPoint:GLAtt;
    var aTexCoord:GLAtt;
    var aLightStyle:GLAtt;
    var tTexture:GLTex;
    var tLightmap:GLTex;
    var tDlight:GLTex;
    var tLightStyle:GLTex;
}

@:shader("dlight")
class PDlight extends GLProgram {
    var uOrigin:GLUni;
    var uViewOrigin:GLUni;
    var uViewAngles:GLUni;
    var uPerspective:GLUni;
    var uRadius:GLUni;
    var uGamma:GLUni;
    var aPoint:GLAtt;
}

@:shader("player")
class PPlayer extends GLProgram implements IPAlias {
    var uOrigin:GLUni;
    var uAngles:GLUni;
    var uViewOrigin:GLUni;
    var uViewAngles:GLUni;
    var uPerspective:GLUni;
    var uLightVec:GLUni;
    var uGamma:GLUni;
    var uAmbientLight:GLUni;
    var uShadeLight:GLUni;
    var uTop:GLUni;
    var uBottom:GLUni;
    var aPoint:GLAtt;
    var aLightNormal:GLAtt;
    var aTexCoord:GLAtt;
    var tTexture:GLTex;
    var tPlayer:GLTex;
}

interface IPSprite {
    var uRect(default,null):GLUni;
    var uOrigin(default,null):GLUni;
    var uViewOrigin(default,null):GLUni;
    var uViewAngles(default,null):GLUni;
    var uPerspective(default,null):GLUni;
    var uGamma(default,null):GLUni;
    var aPoint(default,null):GLAtt;
    var tTexture(default,null):GLTex;
}

@:shader("sprite")
class PSprite extends GLProgram implements IPSprite {
    var uRect:GLUni;
    var uOrigin:GLUni;
    var uViewOrigin:GLUni;
    var uViewAngles:GLUni;
    var uPerspective:GLUni;
    var uGamma:GLUni;
    var aPoint:GLAtt;
    var tTexture:GLTex;
}

@:shader("spriteOriented")
class PSpriteOriented extends GLProgram  implements IPSprite {
    var uRect:GLUni;
    var uOrigin:GLUni;
    var uAngles:GLUni;
    var uViewOrigin:GLUni;
    var uViewAngles:GLUni;
    var uPerspective:GLUni;
    var uGamma:GLUni;
    var aPoint:GLAtt;
    var tTexture:GLTex;
}

@:shader("turbulent")
class PTurbulent extends GLProgram {
    var uOrigin:GLUni;
    var uAngles:GLUni;
    var uViewOrigin:GLUni;
    var uViewAngles:GLUni;
    var uPerspective:GLUni;
    var uGamma:GLUni;
    var uTime:GLUni;
    var aPoint:GLAtt;
    var aTexCoord:GLAtt;
    var tTexture:GLTex;
}

@:shader("warp")
class PWarp extends GLProgram {
    var uRect:GLUni;
    var uOrtho:GLUni;
    var uTime:GLUni;
    var aPoint:GLAtt;
    var tTexture:GLTex;
}

@:shader("sky")
class PSky extends GLProgram {
    var uViewAngles:GLUni;
    var uPerspective:GLUni;
    var uScale:GLUni;
    var uGamma:GLUni;
    var uTime:GLUni;
    var aPoint:GLAtt;
    var tSolid:GLTex;
    var tAlpha:GLTex;
}

@:shader("skyChain")
class PSkyChain extends GLProgram {
    var uViewOrigin:GLUni;
    var uViewAngles:GLUni;
    var uPerspective:GLUni;
    var aPoint:GLAtt;
}


class GLPrograms {
    public static var character(default,null):PCharacter;
    public static var fill(default,null):PFill;
    public static var pic(default,null):PPic;
    public static var picTranslate(default,null):PPicTranslate;
    public static var particle(default,null):PParticle;
    public static var alias(default,null):PAlias;
    public static var brush(default,null):PBrush;
    public static var dlight(default,null):PDlight;
    public static var player(default,null):PPlayer;
    public static var sprite(default,null):PSprite;
    public static var spriteOriented(default,null):PSpriteOriented;
    public static var turbulent(default,null):PTurbulent;
    public static var warp(default,null):PWarp;
    public static var sky(default,null):PSky;
    public static var skyChain(default,null):PSkyChain;

    @:access(quake.GL.AddProgram)
    inline static function add<T:GLProgram>(p:T):T return GL.AddProgram(p);

    public static function init(gl) {
        character = add(new PCharacter(gl));
        fill = add(new PFill(gl));
        pic = add(new PPic(gl));
        picTranslate = add(new PPicTranslate(gl));
        particle = add(new PParticle(gl));
        alias = add(new PAlias(gl));
        brush = add(new PBrush(gl));
        dlight = add(new PDlight(gl));
        player = add(new PPlayer(gl));
        sprite = add(new PSprite(gl));
        spriteOriented = add(new PSpriteOriented(gl));
        turbulent = add(new PTurbulent(gl));
        warp = add(new PWarp(gl));
        sky = add(new PSky(gl));
        skyChain = add(new PSkyChain(gl));
    }
}
