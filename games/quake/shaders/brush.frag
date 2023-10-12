precision mediump float;
uniform float uGamma;
uniform sampler2D tTexture;
uniform sampler2D tLightmap;
uniform sampler2D tDlight;
uniform sampler2D tLightStyle;
varying vec4 vTexCoord;
varying vec4 vLightStyle;
void main(void)
{
    vec4 texture = texture2D(tTexture, vTexCoord.xy);
    gl_FragColor = vec4(texture.rgb *
        mix(1.0, dot(texture2D(tLightmap, vTexCoord.zw), vec4(
            texture2D(tLightStyle, vec2(vLightStyle.x, 0.0)).a,
            texture2D(tLightStyle, vec2(vLightStyle.y, 0.0)).a,
            texture2D(tLightStyle, vec2(vLightStyle.z, 0.0)).a,
            texture2D(tLightStyle, vec2(vLightStyle.w, 0.0)).a)
        * 43.828125) + texture2D(tDlight, vTexCoord.zw).a, texture.a), 1.0);
    gl_FragColor.r = pow(gl_FragColor.r, uGamma);
    gl_FragColor.g = pow(gl_FragColor.g, uGamma);
    gl_FragColor.b = pow(gl_FragColor.b, uGamma);
}