uniform vec4 uRect;
uniform mat4 uOrtho;
attribute vec2 aPoint;
varying vec2 vTexCoord;
void main(void)
{
    gl_Position = uOrtho * vec4(uRect.x + uRect.z * aPoint.x, uRect.y + uRect.w * aPoint.y, 0.0, 1.0);
    vTexCoord = vec2(aPoint.x, 1.0 - aPoint.y);
}
