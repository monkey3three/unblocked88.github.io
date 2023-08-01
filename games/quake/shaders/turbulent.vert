uniform vec3 uOrigin;
uniform mat3 uAngles;
uniform vec3 uViewOrigin;
uniform mat3 uViewAngles;
uniform mat4 uPerspective;
attribute vec3 aPoint;
attribute vec2 aTexCoord;
varying vec2 vTexCoord;
void main(void)
{
    vec3 position = uViewAngles * (uAngles * aPoint + uOrigin - uViewOrigin);
    gl_Position = uPerspective * vec4(position.xz, -position.y, 1.0);
    vTexCoord = aTexCoord;
}
