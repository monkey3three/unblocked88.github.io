uniform vec2 uCharacter;
uniform vec2 uDest;
uniform mat4 uOrtho;
attribute vec2 aPoint;
varying vec2 vTexCoord;
void main(void)
{
    gl_Position = uOrtho * vec4(aPoint * 8.0 + uDest, 0.0, 1.0);
    vTexCoord = (aPoint + uCharacter) * 0.0625;
}
