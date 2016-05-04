#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;
uniform sampler2D u_texture;
uniform sampler2D u_colorRampTexture;



float weightDepth(vec2 texcoord,sampler2D depthSampler,float filterRadius,float blurDir,float blurScale,float blurDepthFalloff)
{
    float depth = texture2D(depthSampler, texcoord).a;
    float sum = 0.0;
    float wsum = 0.0;
    for(float x=-filterRadius; x<=filterRadius; x+=1.0)
     {
        float sample = texture2D(depthSampler, texcoord + x*blurDir).a;
        // spatial domain
        float r = x * blurScale;
        float w = exp(-r*r);
        // range domain
        float r2 = (sample - depth) * blurDepthFalloff; 
        float g = exp(-r2*r2);
        sum += sample * w * g; 
        wsum += w * g;
    }
    if (wsum > 0.0) 
    {
        sum /= wsum;
    } 
    return sum;

}

void main()
{
    vec4 normalColor = texture2D(u_texture,v_texCoord).rgba;
    
    
//    vec4 normalColor = texture2D(u_texture, v_texCoord).rgba;
//    float rampedR = texture2D(u_colorRampTexture, vec2(normalColor.r, 0)).r;
//    float rampedG = texture2D(u_colorRampTexture, vec2(normalColor.g, 0)).g;
//    float rampedB = texture2D(u_colorRampTexture, vec2(normalColor.b, 0)).b;
//    float rampedA = texture2D(u_colorRampTexture, vec2(normalColor.b, 0)).a;
    
//    if(normalColor.a <= 0.9)
//    {
//        gl_FragColor = vec4(0,0,0,0);
//    }
//    else if(normalColor.a > 0.9)
//    {
//        gl_FragColor = vec4(1,0,0,.1);
//    }
//    else if(normalColor.a > 0.95 && normalColor.a <= 1）
//    {
//        gl_FragColor = vec4(0,0,1,.1);
//    }
    
//    if(normalColor.a > 0.6 )//红蓝
//    {
//        gl_FragColor = vec4(0.01,0.01,0.81,.2);
//    }
//    else if(normalColor.a > 0.3 && normalColor.a <= 0.6)
//    {
//        gl_FragColor = vec4(0.81,0.01,0.01,.06);
//    }
//    else
//    {
//        gl_FragColor = vec4(0,0,0,0);
//    }
    
//    if(normalColor.a > 0.3 && normalColor.a < 0.4)//清色水
//    {
//        gl_FragColor = vec4(0.01,0.01,0.01,.2);
//    }
    
//    float a1 = .775;
//    vec4 alpha1 = vec4(a1,a1,a1,a1);
//    float a2 = .3;
//    vec4 alpha2 = vec4(a2,a2,a2,a2);
//    if(normalColor.a > 0.58 && normalColor.a < 0.68)//清色水
//    {
//        //gl_FragColor = alpha*vec4(1,0.9803,0.972549,0);
//        //gl_FragColor = alpha1*vec4(0.301,0.91,1.,1);
//        //gl_FragColor = alpha1*vec4(0.0,0.0,1.0,1);
//        //gl_FragColor = alpha1*vec4(0.2,0.8,0.8,1);
//        gl_FragColor = alpha1*vec4(0.1,0.7,0.68,1);
//
//    }
//    else if(normalColor.a >= 0.68 && normalColor.a <= 1.0)
//    {
//        //gl_FragColor = alpha*vec4(0.2862,1.0,0.968627,1);
//        //gl_FragColor = alpha2*vec4(0.01,0.01,0.01,1);
//        //gl_FragColor = alpha2*vec4(0.0,0.0,1.0,1);
//        //gl_FragColor = alpha1*vec4(0.2,0.8,0.8,1);
//        gl_FragColor = alpha2*vec4(0.1,0.7,0.68,1);
//    }
//    else
//    {
//        gl_FragColor = vec4(0,0,0,0);
//    }


//    if(normalColor.a > 0.2)
//    {
//        gl_FragColor = vec4(1.0,0.01,0.01,.2);
//    }
//    else
//    {
//        gl_FragColor = vec4(0,0,0,0);
//    }
    
//    vec2 N;
//    N = v_texCoord*2.0-1.0;
//    float r2 = dot(N,N);
//    if(r2>1.0)discard;

//    float wd = weightDepth(v_texCoord,u_texture,.0025,100.01,1.0,0.001);
    float a1 = 0.22;//normalColor.a/5.0;
    float a2 = 0.66;//normalColor.a/5.0;
 //   if(a1 <= wd ){discard;return;}
    vec4 alpha1 = vec4(a1,a1,a1,a1);
    vec4 alpha2 = vec4(a2,a2,a2,a2);

//    if(normalColor.a > 0.60 && normalColor.a <= 0.70)
//    {
//        gl_FragColor = alpha2*vec4(1.1,0.7,.68,1);
//    }
//    else if(normalColor.a > 0.70 )//清色水 && normalColor.a <= 1.0
//    {
//        gl_FragColor = alpha1*vec4(1.1,0.7,.68,1);
//    }
//    else
//    {
//        gl_FragColor = vec4(0,0,0,0);
//    }
    
    
    if(normalColor.a > 0.55)
    {
//        if(normalColor.r == normalColor.a)
//        {
//            gl_FragColor = vec4(normalColor.r,normalColor.g,normalColor.b,alpha1);
//            //gl_FragColor = alpha1*vec4(normalColor.r,normalColor.g,normalColor.b,0.6);
//            //gl_FragColor = alpha1*vec4(0.1,0.1,0.1,0.4);
//        }

        if(normalColor.a > 0.68)
        {
             //gl_FragColor = alpha2*vec4(0.7,0.2,0.4,1.0);
             gl_FragColor = alpha1*vec4(0.25,0.45,0.35,1.0);
        }
        else
        {
            gl_FragColor = alpha2*vec4(0.25,0.49,0.35,1.0);
        }

    }
    else
    {
        gl_FragColor = vec4(0,0,0,0);
    }

}