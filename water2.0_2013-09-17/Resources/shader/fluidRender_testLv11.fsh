#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;
uniform sampler2D u_texture;
uniform sampler2D FluidRender1;//added by tr 2013-10-08 
uniform sampler2D FluidRender2;//added by tr 2013-10-08 
uniform sampler2D u_colorRampTexture;


#define KERNEL_SIZE 9

// Gaussian kernel
// 1 2 1
// 2 4 2
// 1 2 1
float kernel[9];

float step_w = 1.0/1280.0;
float step_h = 1.0/720.0;

vec2 offset[9];

float GaussianCoef(float x, float y)
{
	float sigma = 0.33;
	return  ( 1.0 / ( 2.0*3.14 * sigma*sigma ) ) * exp( -(x*x+y*y) / (2.0*sigma*sigma) );
}

void main()
{
    vec4 normalColor = texture2D(u_texture,v_texCoord).rgba;
//    vec4 f1 = texture2D(FluidRender1,v_texCoord).rgba;//绿 fluidRender1Color
//    vec4 f2 = texture2D(FluidRender2,v_texCoord).rgba;//红
      float a = 0.5;
//    vec4 alpha = vec4(a,a,a,a);
//    
    if(normalColor.a >= 0.68)
    {
//        float PI = 3.14159265;
//        float radiusStepLength = 1.0/1280.0;
//        float radiusSteps = 5.0;
//        float rotationSteps = 10.0;
//        
//        float weightsSum = GaussianCoef(0.0,0.0);
//        vec4 colorSum = weightsSum * texture2D(u_texture, vec2(0.0,0.0));
//        
//        
//        for (float radius=radiusStepLength; radius <= (radiusSteps+1.0)*radiusSteps/1280.0; radius+=radiusStepLength)
//        {
//            for (float rotation = 0.0; rotation < 2.0*PI; rotation+=2.0*PI/rotationSteps)
//            {
//                float x = radius * cos(rotation)/1280.0;
//                float y = radius * sin(rotation)/720.0;
//                
//                float weight = GaussianCoef(x, y);
//                weightsSum += weight;
//                
//                colorSum += weightsSum * texture2D(u_texture, vec2(x,y));
//            }
//        }
//        
//        vec4 blurredColor = colorSum / weightsSum;
//        gl_FragColor = blurredColor;
    
    
//        vec4 centreColour = normalColor;
//        vec4 result ;//= normalColor;
//        float normalization = 1.0;
//        float filterRadius = 10.0;
//        for(float i=-1.0*filterRadius;i<=filterRadius;i=i+1.0)
//        {
//            float ix = v_texCoord.x+i/1280.0;
//            float iy = v_texCoord.y+i/720.0;
//            vec4 sample = texture2D(u_texture, v_texCoord + vec2(ix,iy));
//            
//            if(ix < 0.0 || ix > 1.0 || iy < 0.0 || iy > 1.0 )continue;//|| sample.a < 0.68
//            
//            float gaussianCoeff = GaussianCoef(ix,iy);
//            
//            //depends on your implementation, this is quick
//            float closeness = distance(sample,centreColour) / length(vec4(1.0,1.0,1.0,1.0));
//            
//            float sampleWeight = closeness * gaussianCoeff;
//            
//            result += sample * sampleWeight;
//            normalization += sampleWeight;
//        }
//        vec4 bilateral = result / normalization;
//        gl_FragColor = 1.0*vec4(bilateral.r,bilateral.g,bilateral.b,1.0);
        
//        int i;
//        vec4 sum = vec4(0.0);
//        float KernelSize = 25.0;
//        
//        for (i = 0; i < KernelSize; i++)
//        {
//            vec4 tmp = texture2D(u_texture, v_texCoord.st + Offset[i]);
//            sum += tmp * KernelValue[i];
//        }
//        
//        vec4 baseColor = texture2D(BaseImage, vec2(gl_TexCoord[0]));
//        gl_FragColor = ScaleFactor * sum + baseColor;
        
        vec4 sum = vec4(0.0);
        
        // blur in y (vertical)
        // take nine samples, with the distance blurSize between them
        const float blurSize = 30.0/1280.0;
        sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y - 4.0*blurSize)) * 0.05;
        sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y - 3.0*blurSize)) * 0.09;
        sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y - 2.0*blurSize)) * 0.12;
        sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y - blurSize)) * 0.15;
        sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y)) * 0.16;
        sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y + blurSize)) * 0.15;
        sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y + 2.0*blurSize)) * 0.12;
        sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y + 3.0*blurSize)) * 0.09;
        sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y + 4.0*blurSize)) * 0.05;
        
        gl_FragColor = sum;

//        int i = 0;
//        vec4 sum = vec4(0.0);
//        
//        offset[0] = vec2(-step_w, -step_h);
//        offset[1] = vec2(0.0, -step_h);
//        offset[2] = vec2(step_w, -step_h);
//        
//        offset[3] = vec2(-step_w, 0.0);
//        offset[4] = vec2(0.0, 0.0);
//        offset[5] = vec2(step_w, 0.0);
//        
//        offset[6] = vec2(-step_w, step_h);
//        offset[7] = vec2(0.0, step_h);
//        offset[8] = vec2(step_w, step_h);
//        
//        kernel[0] = 1.0/16.0; 	kernel[1] = 2.0/16.0;	kernel[2] = 1.0/16.0;
//        kernel[3] = 2.0/16.0;	kernel[4] = 4.0/16.0;	kernel[5] = 2.0/16.0;
//        kernel[6] = 1.0/16.0;   kernel[7] = 2.0/16.0;	kernel[8] = 1.0/16.0;
//        
//        
//        if(gl_TexCoord[0].s<0.495)
//        {
//            for( i=0; i<9; i++ )
//            {
//                vec4 tmp = texture2D(u_texture, v_texCoord.st + offset[i]);
//                sum += tmp * kernel[i];
//            }
//        }
//        else if( v_texCoord.s>0.505 )
//        {
//            sum = texture2D(u_texture, v_texCoord.xy);
//        }
//        else
//        {
//            sum = vec4(1.0, 0.0, 0.0, 1.0);
//        }
//        
//        gl_FragColor = sum;
//    
    }
    else
    {
        gl_FragColor = vec4(0,0,0,0);

    }


}