precision mediump float;
uniform vec4 uColor;
void main(void)
{
    gl_FragColor = vec4(uColor.rgb * (1.0 / 255.0), uColor.a);
}
