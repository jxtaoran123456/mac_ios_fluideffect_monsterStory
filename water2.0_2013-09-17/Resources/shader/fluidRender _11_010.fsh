#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;
uniform sampler2D u_texture;

void main()
{
    vec4 normalColor = texture2D(u_texture,v_texCoord).rgba;
    float a1 = 0.3;
    vec4 alpha1 = vec4(a1,a1,a1,a1);
        
    if(normalColor.a > 0.0)
    {
        {
            gl_FragColor = vec4(0.0,1.0,0.0,normalColor.a);
        }
    }
    else
    {
        gl_FragColor = vec4(0,0,0,0);
    }

}