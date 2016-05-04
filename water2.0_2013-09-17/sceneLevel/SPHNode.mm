//
//  SPHNode.m
//  SPH
//
//  Created by Vasiliy Yanushevich on 11/2/12.
//  Copyright 2012 Vasiliy Yanushevich. All rights reserved.
//

#import "SPHNode.h"
//#import "DLRenderTexture.h"
//#import "DLRenderTexture2.h"
//#import "DLRenderTexture3.h"

#include <GLUT/GLUT.h>
#include <OpenGL/glu.h>

#import "DLRenderTexture.h"
//#import "DLRenderTexture2.h"
//#import "DLRenderTexture3.h"
//#import "CCTexture2DMutable.h"


@implementation SPHNode
@synthesize usedToolsNum,dang,dfs,xw,sz,xts,colorState,ylBody1;

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	SPHNode *layer = [SPHNode node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
    
}

-(id)init
{
    if (self = [super init])
    {
        fpressure = 2.0f;
        fpresnear = 2.0f;
        collisionFactor = 1.0f;
        
        // enable touches
		self.mouseEnabled = YES;
        [self setMousePriority:mousePriority];
        
        self.anchorPoint = ccp(0,0);
        self.position = ccp(0,0);

        CGSize screenSize = [CCDirector sharedDirector].winSize;
        if(renderTexture==nil)
        {
            renderTexture = [CCRenderTexture renderTextureWithWidth:screenSize.width height:screenSize.height];
            renderTexture.position = ccp(screenSize.width/2, screenSize.height/2);
            [self addChild:renderTexture z:zOrder+10];//前面为滤镜层 后面为遮挡层
        }
        if(renderTexture2==nil)
        {
            renderTexture2 = [CCRenderTexture renderTextureWithWidth:screenSize.width height:screenSize.height];
            renderTexture2.position = ccp(screenSize.width/2, screenSize.height/2);
            [self addChild:renderTexture2 z:zOrder+10];//前面为滤镜层 后面为遮挡层
        }
        
        // 2
        const GLchar * fragmentSource = (GLchar*) [[NSString stringWithContentsOfFile:[CCFileUtils fullPathFromRelativePath:@"fluidRender.fsh"] encoding:NSUTF8StringEncoding error:nil] UTF8String];
        renderTexture.sprite.shaderProgram = [[CCGLProgram alloc] initWithVertexShaderByteArray:ccPositionTextureA8Color_vert fragmentShaderByteArray:fragmentSource];
        [renderTexture.sprite.shaderProgram addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
        [renderTexture.sprite.shaderProgram addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
        [renderTexture.sprite.shaderProgram link];
        [renderTexture.sprite.shaderProgram updateUniforms];
        [renderTexture.sprite.shaderProgram use];
        
        ParticleBatch = [[CCSpriteBatchNode batchNodeWithFile:@"fire_010.png" capacity:3000] retain];//VbmyR.png fire drop2 drop5 fire_010
        ParticleBatch2 = [[CCSpriteBatchNode batchNodeWithFile:@"fire_100.png" capacity:3000] retain];//VbmyR.png
        smokeParticleBatch = [[CCSpriteBatchNode batchNodeWithFile:@"smoke32.png" capacity:1000] retain];
        ParticleBuddleBatch = [[CCSpriteBatchNode batchNodeWithFile:@"buddle1.png" capacity:100] retain];

        gameLayer = self;
        
        rippleSprArr = [[NSMutableArray alloc]init];
        daojuArr = [[NSMutableArray alloc]init];
        
        [self addChild:ParticleBatch z:zOrder+10];
        [self addChild:ParticleBatch2 z:zOrder+10];
        [self addChild:smokeParticleBatch z:zOrder+10];
        [self addChild:ParticleBuddleBatch z:zOrder+10];
        
        [rippleSprArr addObject:ParticleBuddleBatch];
        [ParticleBuddleBatch release];
        
        [self initRippleRender];
        
        self.position = ccp(0,0);
        
    }
    return self;
    
}



-(void)initMenu
{
    
    
}

-(void)createStaticGeometry
{

    
}

- (BOOL) ccMouseDown:(NSEvent *)event
{
    return NO;
    
}

- (void)drawLiquid
{
    [renderTexture beginWithClear:0 g:0 b:0 a:0];
    
    if(ParticleBatch != nil)
    {
        ParticleBatch.visible = YES;
        [ParticleBatch visit];
        ParticleBatch.visible = NO;
    }

    if(ParticleBatch2 != nil)
    {
        ParticleBatch2.visible = YES;
        [ParticleBatch2 visit];
        ParticleBatch2.visible = NO;
    }
    
    [renderTexture end];
    
}

-(void) draw
{    
    [self drawLiquid];
    [super draw];
    
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
	kmGLPushMatrix();
	
	m_world->DrawDebugData();
	
	kmGLPopMatrix();
    
}

-(void)update:(ccTime)dt
{
    if(result == 0)
    {
        deltaTime += dt;
        if(haveAwakeParticlesNum >= fluidPraNum)
        {
            result = -1;
        }
    }
    
	// Update positions, and hash them 在子类中的update函数调用覆盖该函数
    [self updatePhysicalWorld:dt];
    updateFluidStep(dt);
    [self rippleEffect:dt];
    [self updateUI];
    [self winJudge];
    
}

-(void)addDangban:(CGPoint)ps event:(NSEvent*)event
{
    
}

-(void)addDXF:(CGPoint)ps event:(NSEvent*)event
{
    
}

-(void)addXW:(CGPoint)ps event:(NSEvent*)event
{
    
}

-(void)addShiZi:(CGPoint)ps event:(NSEvent*)event
{
    
}

-(void)addXTS:(CGPoint)ps event:(NSEvent*)event
{
    
}

-(void)toolsForce
{
    
}

-(void)updatePhysicalWorld:(float)dt
{
    int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	m_world->Step(dt, velocityIterations, positionIterations);
    
    //Iterate over the bodies in the physics world
	for (b2Body* b = m_world->GetBodyList(); b; b = b->GetNext())
	{
		if (b->GetUserData() != NULL)
		{
			//Synchronize the AtlasSprites position and rotation with the corresponding body
			CCSprite *myActor = (CCSprite*)b->GetUserData();
			myActor.position = CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
			myActor.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
		}
	}
    
}

//水波滤镜效果
-(void)initRippleRender
{
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    rippleRender = [CCRenderTexture renderTextureWithWidth:screenSize.width height:screenSize.height];
    rippleRender.position = ccp(screenSize.width/2,screenSize.height/2);
    [self addChild:rippleRender z:zOrder+3];
    
    [rippleRender beginWithClear:0 g:0 b:0 a:0];
    [backgroundSprite visit];
    [rippleRender end];
    
    swg = [[CCSpriteWaveGenerator alloc]initWithCCSprite:rippleRender.sprite];//rippleSpr
    swg.rippledSprite.position = ccp(screenSize.width/2,screenSize.height/2);
    swg.rippledSprite.flipY = YES;
    [self addChild:swg.rippledSprite z:zOrder+3];//swg.rippledSprite

}

-(void)rippleEffect:(ccTime)dt
{
    
    int static tick = 0;
    tick++;
    if(tick == 10000)tick = 0;
    if(tick%4 == 0)
    {
        [rippleRender beginWithClear:0 g:0 b:0 a:0];
        
        for(int i = 0; i < [rippleSprArr count];i++)
        {
            CCNode *rippleSpr = (CCNode *)[rippleSprArr objectAtIndex:i];
            [rippleSpr visit];
        }
        [rippleRender end];
        
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        
        int i = rand()%((int)screenSize.width);
        int j = rand()%((int)screenSize.height);
        [swg createWaveAt:CGPointMake(i,j)];
        [swg update:dt];

    }
    
}
 
-(void)setColorState:(int)fluidPraticleIndex color:(ccColor3B)color
{
    if(liquid[fluidPraticleIndex].sp != nil && liquid[fluidPraticleIndex].type == 0 && ParticleBatch2 != nil)
    {
        [liquid[fluidPraticleIndex].sp removeFromParentAndCleanup:YES];
        liquid[fluidPraticleIndex].sp = [CCSprite spriteWithTexture:[ParticleBatch2 texture]];//[CCSprite spriteWithFile:batchNodeSprite2Str];
        liquid[fluidPraticleIndex].sp.position = ccp(liquid[fluidPraticleIndex].mPosition.x*PTM_RATIO,liquid[fluidPraticleIndex].mPosition.y*PTM_RATIO);
        [ParticleBatch2 addChild:liquid[fluidPraticleIndex].sp];
        liquid[fluidPraticleIndex].type = 1;
    }
    else if(liquid[fluidPraticleIndex].sp == nil && liquid[fluidPraticleIndex].type == 0 && ParticleBatch2 != nil)
    {
        liquid[fluidPraticleIndex].sp = [CCSprite spriteWithTexture:[ParticleBatch2 texture]];//[CCSprite spriteWithFile:batchNodeSprite2Str];
        liquid[fluidPraticleIndex].sp.position = ccp(liquid[fluidPraticleIndex].mPosition.x*PTM_RATIO,liquid[fluidPraticleIndex].mPosition.y*PTM_RATIO);
        [ParticleBatch2 addChild:liquid[fluidPraticleIndex].sp];
        liquid[fluidPraticleIndex].type = 1;
    }
    else if(liquid[fluidPraticleIndex].sp != nil && liquid[fluidPraticleIndex].type == 1)
    {
        
    }
    
}

-(void)reductionColorState:(int)fluidPraticleIndex
{
    liquid[fluidPraticleIndex].type  = 0;
    if(liquid[fluidPraticleIndex].sp != nil)
    {
        [liquid[fluidPraticleIndex].sp removeFromParentAndCleanup:YES];
        liquid[fluidPraticleIndex].sp = [CCSprite spriteWithTexture:[ParticleBatch texture]];
        liquid[fluidPraticleIndex].sp.position = ccp(liquid[fluidPraticleIndex].mPosition.x*PTM_RATIO,liquid[fluidPraticleIndex].mPosition.y*PTM_RATIO);
        [ParticleBatch addChild:liquid[fluidPraticleIndex].sp];
        
    }
    
}

//碰撞事件处理
-(void)collisionHandle:(b2Body*)body index:(int)fluidPraticleIndex
{
    if(body->toolsType == 1001)
    {
        
    }
    
}

//共定义了三套无连接地图边界检测和一套线段边界检测 这个在子类中实现
-(void)addMap
{
    
}
-(void)addMap1
{
    
}
-(void)addMap2
{
    
}
-(void)addSingleMap
{
    
    
}

-(int)winJudge
{
    return 0;
}

-(void)updateUI
{
    
}

-(int)computeScore
{
    return 0;
    
}

-(void)dealloc
{
    clearMemory();
	clearHashGrid();
    delete m_world;
    m_world = NULL;
    delete intersectQueryCallback;
    intersectQueryCallback = NULL;
    delete eulerIntersectQueryCallback;
    eulerIntersectQueryCallback = NULL;
    
    vertsNum = 0;
    if(verts != NULL){delete verts;verts = NULL;}
    
    vertsNum1 = 0;
    if(verts1 != NULL){delete verts1;verts1 = NULL;}
    
    vertsNum2 = 0;
    if(verts2 != NULL){delete verts2;verts2 = NULL;}
    
    singleVerNum = 0;
    if(singleVers != NULL){delete singleVers;singleVers = NULL;}
    if(swg != nil){[swg release];}
    
    if(rippleSprArr){[rippleSprArr release];rippleSprArr = nil;}
    if(daojuArr){[daojuArr release];daojuArr = nil;}
    
    [super dealloc];
    
}



@end
