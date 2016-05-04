#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;
uniform sampler2D u_texture;
uniform sampler2D u_colorRampTexture;


void main()
{
    vec4 normalColor = texture2D(u_texture,v_texCoord).rgba;
    float alpha = 3.9;
    float disappFact = v_texCoord.y;
    if(normalColor.a > 0.38)
    {
        gl_FragColor = (normalColor.a - v_texCoord.y/1.5) * vec4(0.99,0.99,0.99,0.5);//-  v_texCoord.y) (normalColor.a - v_texCoord.y/1.1) *
    }
    else
    {
        gl_FragColor = vec4(0,0,0,0);
    }

}