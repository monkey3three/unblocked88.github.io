uniform vec4 uRect;
uniform mat4 uOrtho;
attribute vec2 aPoint;
varying vec2 vTexCoord;
void main(void)
{
    gl_Position = uOrtho * vec4(uRect.xy + uRect.zw * aPoint.xy, 0.0, 1.0);
    vTexCoord = aPoint;
}
