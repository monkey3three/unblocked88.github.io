uniform vec3 uViewOrigin;
uniform mat3 uViewAngles;
uniform mat4 uPerspective;
attribute vec3 aPoint;
void main(void)
{
    vec3 position = uViewAngles * (aPoint - uViewOrigin);
    gl_Position = uPerspective * vec4(position.xz, -position.y, 1.0);
}
