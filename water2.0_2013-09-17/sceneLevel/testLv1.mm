//
//  SPHNode.m
//  SPH
//
//  Created by Vasiliy Yanushevich on 11/2/12.
//  Copyright 2012 Vasiliy Yanushevich. All rights reserved.
//

#import "SPHNode.h"
#import "testLv1.h"

#include <GLUT/GLUT.h>
#include <OpenGL/glu.h>



@implementation testLv1

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	testLv1 *layer = [testLv1 node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
    
}

-(id)init
{
    if (self = [super init])
    {
        // enable touches
//		self.isMouseEnabled = YES;
//        
//        self.anchorPoint = ccp(0, 0);
//        self.position = ccp(0,0);

        ParticleBatch = [[CCSpriteBatchNode batchNodeWithFile:@"fire2.png" capacity:2000] retain];//VbmyR.png fire
        ParticleBatch2 = [[CCSpriteBatchNode batchNodeWithFile:@"VbmyR2.png" capacity:2000] retain];//VbmyR.png
        ParticleBuddleBatch = [[CCSpriteBatchNode batchNodeWithFile:@"blue_circle_small.png" capacity:20] retain];
        [self createStaticGeometry];
        [self addMap2];
        [self addChild:ParticleBuddleBatch z:2];
        
        intersectQueryCallback = new QueryWorldInteractions(hashGridList, liquid);
        eulerIntersectQueryCallback = new QueryWorldPostIntersect(hashGridList, liquid);
        
        backgroundSprite  = [CCSprite spriteWithFile:@"testLevel4.png"];//testLevel1.png testLevel3
        backgroundSprite.anchorPoint = ccp(0,0);
        backgroundSprite.position = ccp(0,0);
        [self addChild:backgroundSprite z:zOrder-10];
        
        [self initRippleRender];
        
        [self scheduleUpdate];
    }
    return self;
    
}

-(void)createStaticGeometry
{
    m_world = new b2World(b2Vec2(0.f, -40.f));
    
    m_debugDraw = new GLESDebugDraw( 32.f );
	m_world->SetDebugDraw(m_debugDraw);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
	//		flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	//		flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);
    
    [self addMap2];
	
    // Particles
    initFluidPraticles(.99f,.021f,150.f,30.f,1500,@"fire.png",nil);// VbmyR.png
    //added by tr 2013-08-08
    
}

- (BOOL) ccMouseDown:(NSEvent *)event
{
    awakePraticles(300);
	return YES;
    
    CCCamera *cam;
    cam = [backgroundSprite camera];
    [cam setEyeX:-200 eyeY:-200 eyeZ:1200];
}


-(void) draw
{
//    glDisable(GL_TEXTURE_2D);
//	glDisableClientState(GL_COLOR_ARRAY);
//	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
//	
//	m_world->DrawDebugData();
//	
//	// restore default GL states
//	glEnable(GL_TEXTURE_2D);
//	glEnableClientState(GL_COLOR_ARRAY);
//	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
//
//    [self drawLiquid];

    [super draw];
    
}

-(void)dealloc
{
    [super dealloc];
}

-(void)addMap2
{
    b2BodyDef bd;
    bd.type = b2_staticBody;
    b2Body* ground = m_world->CreateBody(&bd);
    vertsNum = 12;
    verts = (b2Vec2 *)malloc (vertsNum * sizeof (b2Vec2)); 
    
    verts[0].Set((512.f-483.0f) / PTM_RATIO, (1288.f+255.0f) / PTM_RATIO);
    verts[1].Set((512.f-413.0f) / PTM_RATIO, (288.f-31.0f) / PTM_RATIO);
    verts[2].Set((512.f-378.0f) / PTM_RATIO, (288.f-5.0f) / PTM_RATIO);
    verts[3].Set((512.f-218.0f) / PTM_RATIO, (288.f+2.0f) / PTM_RATIO);
    verts[4].Set((512.f-217.0f) / PTM_RATIO, (288.f-23.0f) / PTM_RATIO);
    verts[5].Set((512.f-172.0f) / PTM_RATIO, (288.f-33.0f) / PTM_RATIO);
    verts[6].Set((512.f+24.0f) / PTM_RATIO, (288.f-23.0f) / PTM_RATIO);
    verts[7].Set((512.f+147.0f) / PTM_RATIO, (288.f-53.0f) / PTM_RATIO);
    verts[8].Set((512.f+178.0f) / PTM_RATIO, (288.f-158.0f) / PTM_RATIO);
    verts[9].Set((512.f+402.0f) / PTM_RATIO, (288.f-198.0f) / PTM_RATIO);
    verts[10].Set((512.f+475.0f) / PTM_RATIO, (288.f-120.0f) / PTM_RATIO);
    verts[11].Set((512.f+475.0f) / PTM_RATIO, (1288.f+255.0f) / PTM_RATIO);
    
    b2EdgeShape shape;
    
    shape.Set(verts[0], verts[1]);
    shape.m_hasVertex3 = true;
    shape.m_vertex3 = verts[2];
    ground->CreateFixture(&shape, 0.0f);
    
    for(int i = 1; i <= vertsNum-3; i++)
    {
        shape.Set(verts[i], verts[i+1]);
        shape.m_hasVertex0 = true;
        shape.m_hasVertex3 = true;
        shape.m_vertex0 = verts[i-1];
        shape.m_vertex3 = verts[i+2];
        ground->CreateFixture(&shape, .0f);
        
    }
    shape.Set(verts[vertsNum-2], verts[vertsNum-1]);
    shape.m_hasVertex0 = true;
    shape.m_vertex0 = verts[vertsNum-3];
    ground->CreateFixture(&shape, 0.0f);
    
}

-(void)initRippleRender
{
    if(rippleRender==nil)
    {
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        rippleRender = [CCRenderTexture renderTextureWithWidth:screenSize.width
                                                         height:screenSize.height];
        rippleRender.position = ccp(screenSize.width/2,
                                     screenSize.height/2);
        [self addChild:rippleRender z:10];
    }
    
    swg = [[CCSpriteWaveGenerator alloc] initWithCCSprite:rippleRender.sprite];//rippleRender.sprite
    CCSprite *rippledSprite = swg.rippledSprite;
    [self addChild:rippledSprite z:10];
    
}

-(void)rippleEffect:(ccTime)dt
{
    [rippleRender beginWithClear:0 g:0 b:0 a:0];
    [backgroundSprite visit];
    [rippleRender end];
    
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    int static tick = 0;
    tick++;
    if(tick%3 ==0)
    {
//        if(swg != nil)
//        {
//            [swg release];
//            swg = [[CCSpriteWaveGenerator alloc] initWithCCSprite:rippleRender.sprite];
//            CCSprite *rippledSprite = swg.rippledSprite;
//            [self addChild:rippledSprite z:10];
//        }
        
        
        
//        int i = rand()%((int)screenSize.width);
//        int j = rand()%((int)screenSize.height);
//        [swg createWaveAt:CGPointMake(i,j)];
//        [swg update:dt];
    }
    
    int i = rand()%((int)screenSize.width);
    int j = rand()%((int)screenSize.height);
    [swg createWaveAt:CGPointMake(i,j)];
    [swg update:dt];
}

-(void)update:(ccTime)dt
{
	// Update positions, and hash them
    updateFluidStep(dt);
    [self rippleEffect:dt];
    
}

@end
