uniform vec4 uRect;
uniform vec3 uOrigin;
uniform vec3 uViewOrigin;
uniform mat3 uViewAngles;
uniform mat4 uPerspective;
attribute vec2 aPoint;
varying vec2 vTexCoord;
void main(void)
{
    vec2 point = uRect.xy + uRect.zw * aPoint;
    vec3 position = vec3(point.x, 0.0, point.y) + uViewAngles * (uOrigin - uViewOrigin);
    gl_Position = uPerspective * vec4(position.xz, -position.y, 1.0);
    vTexCoord = vec2(aPoint.x, -aPoint.y);
}
