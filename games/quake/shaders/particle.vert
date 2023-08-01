uniform vec3 uOrigin;
uniform vec3 uViewOrigin;
uniform mat3 uViewAngles;
uniform mat4 uPerspective;
uniform float uScale;
attribute vec2 aPoint;
varying vec2 vCoord;
void main(void)
{
    vec2 point = (aPoint - 0.5) * uScale;
    vec3 position = vec3(point.x, 0.0, point.y) + uViewAngles * (uOrigin - uViewOrigin);
    gl_Position = uPerspective * vec4(position.xz, -position.y, 1.0);
    vCoord = vec2(aPoint.x - 0.5, 0.5 - aPoint.y) * 2.0;
}
