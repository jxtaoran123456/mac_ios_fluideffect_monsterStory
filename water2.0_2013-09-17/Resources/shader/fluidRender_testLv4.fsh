#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;
uniform sampler2D u_texture;
uniform sampler2D FluidRender1;//added by tr 2013-10-08 
uniform sampler2D FluidRender2;//added by tr 2013-10-08 


void main()
{
    vec4 normalColor = texture2D(u_texture,v_texCoord).rgba;
    vec4 fluidRender1Color = texture2D(FluidRender1,v_texCoord).rgba;
    vec4 fluidRender2Color = texture2D(FluidRender2,v_texCoord).rgba;
        
    if(normalColor.a > 0.6)
    {
        if(normalColor.r == normalColor.a)
        {
            gl_FragColor = vec4(fluidRender1Color.r,fluidRender2Color.g,normalColor.b,0.5);
        }
        else
        {
            gl_FragColor = normalColor.a*vec4(1.0,0.0,1.0,0.5);
        }
    }
    else
    {
        gl_FragColor = vec4(0,0,0,0);
    }


}