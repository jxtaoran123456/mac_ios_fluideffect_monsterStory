#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;
uniform sampler2D u_texture;
uniform sampler2D FluidRender1;//added by tr 2013-10-08 
uniform sampler2D FluidRender2;//added by tr 2013-10-08 
uniform sampler2D u_colorRampTexture;












void main()
{
    vec4 normalColor = texture2D(u_texture,v_texCoord).rgba;
    vec4 f1 = texture2D(FluidRender1,v_texCoord).rgba;//绿 fluidRender1Color
    vec4 f2 = texture2D(FluidRender2,v_texCoord).rgba;//红
    float a = 0.5;
    vec4 alpha = vec4(a,a,a,a);
    
    
    if(normalColor.a >= 0.68)
    {
//        if(normalColor.r == 0.0)
//        {
//            gl_FragColor = alpha*vec4(0,1,0,1);
//        }
//        else if(normalColor.g == 0.0)
//        {
//            gl_FragColor = alpha*vec4(1,0,0,1);
//        }
//        else
//        {
//            vec4 finalColor = vec4(0.0,0.0,0.0,0.0);
//            for(float i = 1.0; i <= 10.0 ; i++)
//            {
//                if(i <= 5.0)//左下
//                {
//                    if(v_texCoord.y-i/720.0 >= 0.0) finalColor = finalColor + texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y-1.0/720.0));
//                    if(v_texCoord.x-i/1280.0 >= 0.0) finalColor = finalColor + texture2D(u_texture,vec2(v_texCoord.x-1.0/1280.0,v_texCoord.y));
//                }
//                else
//                {
//                    if(v_texCoord.y+i/720.0 <= 1.0) finalColor = finalColor + texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y+1.0/720.0));
//                    if(v_texCoord.x-i/1280.0 <= 1.0) finalColor = finalColor + texture2D(u_texture,vec2(v_texCoord.x+1.0/1280.0,v_texCoord.y));
//                }
//            }
//            finalColor = finalColor/vec4(200.0,200.0,200.0,200.0);
//            gl_FragColor = vec4(finalColor.r,finalColor.g,finalColor.b,1);
//        }


//            vec4 finalColor = vec4(0.0,0.0,0.0,0.0);
//            float loopNum;
//            for(float i = 0.0; i <= 8.0 ; i++)
//            {
//                if(i <= 4.0)//左下
//                {
//                    if(v_texCoord.y-i/720.0 >= 0.0 && texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y-i/720.0)).a >= 0.68)
//                    {
//                        finalColor = finalColor + texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y-i/720.0));
//                        loopNum++;
//                    }
//                    if(v_texCoord.x-i/1280.0 >= 0.0 && texture2D(u_texture,vec2(v_texCoord.x-i/1280.0,v_texCoord.y)).a >= 0.68) 
//                    {
//                        finalColor = finalColor + texture2D(u_texture,vec2(v_texCoord.x-i/1280.0,v_texCoord.y));
//                        loopNum++;
//                    }
//                }
//                else
//                {
//                    if(v_texCoord.y+i/720.0 <= 1.0 && texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y+i/720.0)).a >= 0.68) 
//                    {
//                        finalColor = finalColor + texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y+i/720.0));
//                        loopNum++;
//                    }
//                    if(v_texCoord.x+i/1280.0 <= 1.0 && texture2D(u_texture,vec2(v_texCoord.x+i/1280.0,v_texCoord.y)).a >= 0.68) 
//                    {
//                        finalColor = finalColor + texture2D(u_texture,vec2(v_texCoord.x+i/1280.0,v_texCoord.y));
//                        loopNum++;
//                    }
//                }
//            }
//            finalColor = finalColor/loopNum;
//            gl_FragColor = vec4(finalColor.r,finalColor.g,finalColor.b,1);

            
            
//        if(normalColor.r == 0.0)
//        {
//            gl_FragColor = alpha*vec4(0,1,0,1);
//        }
//        else if(normalColor.g == 0.0)
//        {
//            gl_FragColor = alpha*vec4(1,0,0,1);
//        }
//        else
//        {
            vec4 finalColor = normalColor;
            float loopNum = 1.0;
        
            float weight;
        
            vec4 up = texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y+30.0/720.0));
            vec4 down = texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y-30.0/720.0));
            vec4 left = texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y-30.0/1280.0));
            vec4 right = texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y+30.0/1280.0));
        
            vec4 ramp = (up+down+left+right - normalColor)/4.0;
            weight = (ramp.r + ramp.g + ramp.b + ramp.a)/4.0;//差距越大 原来颜色所占比例越小 越融合到其他颜色 差距越小  原来颜色融合融合越多
            weight = (1.0-weight)/30.0;
        
            for(float i = 0.0; i <= 80.0 ; i++)
            {
                if(i < 40.0)//左下
                {
                    if(v_texCoord.y-i/720.0 >= 0.0 && texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y-i/720.0)).a >= 0.68)
                    {
                        finalColor = finalColor + texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y-i/720.0));
                        loopNum = loopNum+1.0;
                    }
                    if(v_texCoord.x-i/1280.0 >= 0.0 && texture2D(u_texture,vec2(v_texCoord.x-i/1280.0,v_texCoord.y)).a >= 0.68) 
                    {
                        finalColor = finalColor + texture2D(u_texture,vec2(v_texCoord.x-i/1280.0,v_texCoord.y));
                        loopNum = loopNum+1.0;
                    }
                }
                else
                {
                    float xi = i-40.0;
                    if(v_texCoord.y+xi/720.0 <= 1.0 && texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y+xi/720.0)).a >= 0.68)
                    {
                        finalColor = finalColor + texture2D(u_texture,vec2(v_texCoord.x,v_texCoord.y+xi/720.0));
                        loopNum = loopNum+1.0;
                    }
                    if(v_texCoord.x+xi/1280.0 <= 1.0 && texture2D(u_texture,vec2(v_texCoord.x+xi/1280.0,v_texCoord.y)).a >= 0.68) 
                    {
                        finalColor = finalColor + texture2D(u_texture,vec2(v_texCoord.x+xi/1280.0,v_texCoord.y));
                        loopNum = loopNum+1.0;
                    }
                }
            }
            finalColor = finalColor/loopNum;
            gl_FragColor = alpha*vec4(finalColor.r,finalColor.g,finalColor.b,1);
    

    }
    else
    {
        gl_FragColor = vec4(0,0,0,0);

    }


}