#version 410 core

void main(void)
{
    const vec4 vertices[6] = vec4[6](vec4( -0.5, 0.5, 0.5, 0.5),
                                     vec4(0.5),
                                     vec4( 0.5, -0.5, 0.5, 0.5),
                                     vec4( -0.5, 0.5, 0.5, 0.5),
                                     vec4(-0.5, -0.5, 0.5, 0.5),
                                     vec4( 0.5, -0.5, 0.5, 0.5));
    gl_Position = vertices[gl_VertexID];
}