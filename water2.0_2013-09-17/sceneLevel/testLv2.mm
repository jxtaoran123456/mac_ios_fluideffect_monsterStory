//
//  SPHNode.m
//  SPH
//
//  Created by Vasiliy Yanushevich on 11/2/12.
//  Copyright 2012 Vasiliy Yanushevich. All rights reserved.
//

#import "SPHNode.h"
#import "testLv2.h"

#include <GLUT/GLUT.h>
#include <OpenGL/glu.h>



@interface a : NSObject
{
    int a1;
}
-(void)test1;
@end
@implementation a
-(void)test1
{
    a1 = 11;
    NSLog(@"this is a:%d",a1);
}
@end

@interface b : a
{
    int b1;
}
-(void)test1;
-(void)test2;
-(void)test3;
@end
@implementation b
-(void)test1
{
    b1 = 12;
    NSLog(@"this is b:%d",b1);
}
-(void)test2
{
    b1 = 13;
    NSLog(@"this is b2:%d",b1);
}
-(void)test3
{
    b1 = 10;
    NSLog(@"this is b3:%d",b1);
}
@end


@implementation testLv2

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	testLv2 *layer = [testLv2 node];
	
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
        [self createStaticGeometry];
//        [self createStaticGeometry2];

        intersectQueryCallback = new QueryWorldInteractions(hashGridList, liquid);
        eulerIntersectQueryCallback = new QueryWorldPostIntersect(hashGridList, liquid);
        
        backgroundSprite  = [CCSprite spriteWithFile:@"2.png"];//testLevel1.png testLevel3
        backgroundSprite.anchorPoint = ccp(0,0);
        backgroundSprite.position = ccp(0,0);
        [self addChild:backgroundSprite z:zOrder+1];
        
        [rippleSprArr addObject:backgroundSprite];
        [backgroundSprite release];
        
        
        test = [b alloc];
        a* testA = (a*)test;
        [testA test1];
        
        [self scheduleUpdate];
    }
    return self;
    
}

-(void)createStaticGeometry
{
    b2Vec2 gravity;
	gravity.Set(0.0f, -10.00000000000003f);
	m_world = new b2World(gravity);
	
	
	// Do we want to let bodies sleep?
	m_world->SetAllowSleeping(true);
	
	m_world->SetContinuousPhysics(true);
	
	m_debugDraw = new GLESDebugDraw( PTM_RATIO );
	m_world->SetDebugDraw(m_debugDraw);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
	//		flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	//		flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);
    
    [self addMap];
    [self addSingleMap];
	
    // Particles
    initFluidPraticles(1.6f,.002f,120.f,30.f,1000,@"VbmyR.png",nil);// VbmyR.png fire2
    //added by tr 2013-08-08
    
}

-(void)createStaticGeometry2
{
    b2Body* bod;
    
    // Static geometry
    b2PolygonShape sd;
    sd.SetAsBox(15.0f, 0.5f);
    
    b2BodyDef bd;
    bd.type = b2_staticBody;
    bd.position.Set(20.0f, 8.0f);
    b2Body* ground = m_world->CreateBody(&bd);
    
    b2FixtureDef gFix;
    gFix.shape = &sd;
    
    ground->CreateFixture(&gFix);
    sd.SetAsBox(1.0f, 0.2f,b2Vec2(0.0f,4.0f),-0.2f);
    ground->CreateFixture(&gFix);
    sd.SetAsBox(15.f, 0.2f,b2Vec2(0.2f,5.2f),-1.5f);
    ground->CreateFixture(&gFix);
    sd.SetAsBox(0.5f, 20.0f,b2Vec2(-8.0f,10.0f),0.0f);
    ground->CreateFixture(&gFix);
    
    sd.SetAsBox(0.5f,13.0f,b2Vec2(8.0f,10.0f),0.0f);
    ground->CreateFixture(&gFix);
    
    sd.SetAsBox(2.0f,0.1f,b2Vec2(16.0f,3.8f),0.1f);
    ground->CreateFixture(&gFix);
    
    // electrodruid: the stopper - uncomment this if you want to have a pool that the fluid settles in
    //  	sd.SetAsBox(0.3f,2.0f,b2Vec2(-4.5f,-2.0f),0.0f);
    //  	ground->CreateFixture(&gFix);
    
    b2CircleShape cd;
    cd.m_radius = 0.5f;
    cd.m_p = b2Vec2(-0.5f,-4.0f);
    gFix.shape = &cd;
    ground->CreateFixture(&gFix);
    
	// Particles
	float massPerParticle = totalMass / nParticles;
    
	float cx = 0.0f;
	float cy = 25.0f;
    
	// Box
    b2FixtureDef polyDef;
    //	b2PolygonDef polyDef;
    b2PolygonShape shape;
	shape.SetAsBox(0.5, 0.5);
	
	// electrodruid: Rigid body density appears to be a problem for particle vs. rigid interactions.
	// Although theoretically a low density should make a body float, it never floats without my gravity
	// fudge, and low densities mean low rotational inertia which means crazy spinning bodies
    
    //	polyDef.density = 1.0f;
	polyDef.density = 4.0f;
	b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
	bodyDef.position = b2Vec2(10.0f,25.0f);
    
	// electrodruid: As well as the above note about density, some angular damping seems to help with the
	// crazy spinning, although I'd like to not have to add it - feels like a hack.
	bodyDef.angularDamping = 0.5f;
    
	bod = m_world->CreateBody(&bodyDef);
    polyDef.shape = &shape;
	bod->CreateFixture(&polyDef);
    
}

- (BOOL) ccMouseDown:(NSEvent *)event
{
    prePoint = ccp([event locationInWindow].x,[event locationInWindow].y);
    
    //判断是否点击的道具按钮
    if(prePoint.x <= 120 && prePoint.x >= 60 && prePoint.y <= 90 && prePoint.y >= 10)//添加格挡
    {
        if(dang == nil)
        {
            [self addDangban:prePoint event:event];
        }
        return NO;
    }
    else if(prePoint.x <= 210 && prePoint.x >= 150 && prePoint.y <= 90 && prePoint.y >= 10)//添加风扇
    {
        if(dfs == nil)
        {
            [self addDXF:prePoint event:event];
        }
        return NO;
    }
    else if(prePoint.x <= 300 && prePoint.x >= 160 && prePoint.y <= 90 && prePoint.y >= 10)//添加漩涡
    {
        if(xw == nil)
        {
            [self addXW:prePoint event:event];
        }
        return NO;
    }

    return NO;
}

-(BOOL) ccMouseMoved:(NSEvent*)event
{
    ifMove = true;
    return NO;
    
}

-(BOOL) ccMouseDragged:(NSEvent*)event
{
    ifMove = true;
    return NO;
}

-(BOOL) ccMouseUp:(NSEvent*)event
{
    if(ifMove == true)
    {
        ifMove = false;
        return NO;
    }
    else
    {
        awakePraticles(500);
        return NO;
    }}


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

-(void)addMap
{
    b2BodyDef bd;
    bd.type = b2_staticBody;
    b2Body* ground = m_world->CreateBody(&bd);
    vertsNum = 11;
    verts = (b2Vec2 *)malloc (vertsNum * sizeof (b2Vec2));
    
//    verts[0].Set((640.f-635.0f) / PTM_RATIO, (360.f+69.0f) / PTM_RATIO);
//    verts[1].Set((640.f-401.0f) / PTM_RATIO, (360.f+58.0f) / PTM_RATIO);
//    verts[2].Set((640.f-366.0f) / PTM_RATIO, (360.f+37.0f) / PTM_RATIO);
//    verts[3].Set((640.f-346.0f) / PTM_RATIO, (360.f+28.0f) / PTM_RATIO);
//    verts[4].Set((640.f-294.0f) / PTM_RATIO, (360.f+42.0f) / PTM_RATIO);
//    verts[5].Set((640.f-292.0f) / PTM_RATIO, (360.f-124.0f) / PTM_RATIO);
//    verts[6].Set((640.f-279.0f) / PTM_RATIO, (360.f-137.0f) / PTM_RATIO);
//    verts[7].Set((640.f-263.0f) / PTM_RATIO, (360.f-242.0f) / PTM_RATIO);
//    verts[8].Set((640.f-47.0f) / PTM_RATIO, (360.f-268.0f) / PTM_RATIO);
//    verts[9].Set((640.f+102.0f) / PTM_RATIO, (360.f-265.0f) / PTM_RATIO);
//    verts[10].Set((640.f+253.0f) / PTM_RATIO, (360.f-254.0f) / PTM_RATIO);
//    verts[11].Set((640.f+272.0f) / PTM_RATIO, (360.f-199.0f) / PTM_RATIO);
//    verts[12].Set((640.f+267.0f) / PTM_RATIO, (360.f-115.0f) / PTM_RATIO);
//    verts[13].Set((640.f+259.0f) / PTM_RATIO, (360.f-57.0f) / PTM_RATIO);
//    verts[14].Set((640.f+307.0f) / PTM_RATIO, (360.f-56.0f) / PTM_RATIO);
//    verts[15].Set((640.f+-154.0f) / PTM_RATIO, (360.f+30.0f) / PTM_RATIO);
    
//    verts[0].Set((640.f-631.4f) / PTM_RATIO, (360.f+64.3f) / PTM_RATIO);
//    verts[1].Set((640.f-342.9f) / PTM_RATIO, (360.f+29.0f) / PTM_RATIO);
//    verts[2].Set((640.f-268.0f) / PTM_RATIO, (360.f-245.4f) / PTM_RATIO);
//    verts[3].Set((640.f-40.3f) / PTM_RATIO, (360.f-275.1f) / PTM_RATIO);
//    verts[4].Set((640.f+253.9f) / PTM_RATIO, (360.f-255.3f) / PTM_RATIO);
//    verts[5].Set((640.f+303.3f) / PTM_RATIO, (360.f-54.4f) / PTM_RATIO);
//    verts[6].Set((640.f+632.9f) / PTM_RATIO, (360.f-75.7f) / PTM_RATIO);
    
    
//    verts[0].Set((512.f-483.0f) / PTM_RATIO, (1288.f+255.0f) / PTM_RATIO);
//    verts[1].Set((512.f-413.0f) / PTM_RATIO, (288.f-31.0f) / PTM_RATIO);
//    verts[2].Set((512.f-378.0f) / PTM_RATIO, (288.f-5.0f) / PTM_RATIO);
//    verts[3].Set((512.f-218.0f) / PTM_RATIO, (288.f+2.0f) / PTM_RATIO);
//    verts[4].Set((512.f-217.0f) / PTM_RATIO, (288.f-23.0f) / PTM_RATIO);
//    verts[5].Set((512.f-172.0f) / PTM_RATIO, (288.f-33.0f) / PTM_RATIO);
//    verts[6].Set((512.f+24.0f) / PTM_RATIO, (288.f-23.0f) / PTM_RATIO);
//    verts[7].Set((512.f+147.0f) / PTM_RATIO, (288.f-53.0f) / PTM_RATIO);
//    verts[8].Set((512.f+178.0f) / PTM_RATIO, (288.f-158.0f) / PTM_RATIO);
//    verts[9].Set((512.f+402.0f) / PTM_RATIO, (288.f-198.0f) / PTM_RATIO);
//    verts[10].Set((512.f+475.0f) / PTM_RATIO, (288.f-120.0f) / PTM_RATIO);
//    verts[11].Set((512.f+475.0f) / PTM_RATIO, (1288.f+255.0f) / PTM_RATIO);
    
    verts[0].Set((640.f-632.9f) / PTM_RATIO, (360.f-307.6f) / PTM_RATIO);
    verts[1].Set((640.f-617.3f) / PTM_RATIO, (360.f+44.5f) / PTM_RATIO);
    verts[2].Set((640.f-350.0f) / PTM_RATIO, (360.f+33.2f) / PTM_RATIO);
    verts[3].Set((640.f-306.2f) / PTM_RATIO, (360.f+29.0f) / PTM_RATIO);
    verts[4].Set((640.f-273.7f) / PTM_RATIO, (360.f-259.5f) / PTM_RATIO);
    verts[5].Set((640.f-10.6f) / PTM_RATIO, (360.f-275.1f) / PTM_RATIO);
    verts[6].Set((640.f+260.9f) / PTM_RATIO, (360.f-256.7f) / PTM_RATIO);
    verts[7].Set((640.f+290.6f) / PTM_RATIO, (360.f-58.7f) / PTM_RATIO);
    verts[8].Set((640.f+365.6f) / PTM_RATIO, (360.f-21.9f) / PTM_RATIO);
    verts[9].Set((640.f+631.4f) / PTM_RATIO, (360.f-51.6f) / PTM_RATIO);
    verts[10].Set((640.f+632.9f) / PTM_RATIO, (360.f-309.0f) / PTM_RATIO);

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

-(void)addMap1
{
    b2BodyDef bd;
    bd.type = b2_staticBody;
    b2Body* ground = m_world->CreateBody(&bd);
    vertsNum1 = 5;
    verts1 = (b2Vec2 *)malloc (vertsNum1 * sizeof (b2Vec2));
    verts1[0].Set((640.f-636.0f) / PTM_RATIO, (360.f+73.0f) / PTM_RATIO);
    verts1[1].Set((640.f-403.0f) / PTM_RATIO, (360.f+67.0f) / PTM_RATIO);
    verts1[2].Set((640.f-354.0f) / PTM_RATIO, (360.f+231.0f) / PTM_RATIO);
    verts1[3].Set((640.f-322.0f) / PTM_RATIO, (360.f+243.0f) / PTM_RATIO);
    verts1[4].Set((640.f-51.0f) / PTM_RATIO, (360.f+188.0f) / PTM_RATIO);
    
    b2EdgeShape shape;
    
    shape.Set(verts1[0], verts1[1]);
    shape.m_hasVertex3 = true;
    shape.m_vertex3 = verts1[2];
    ground->CreateFixture(&shape, 0.0f);
    
    for(int i = 1; i <= vertsNum1-3; i++)
    {
        shape.Set(verts1[i], verts1[i+1]);
        shape.m_hasVertex0 = true;
        shape.m_hasVertex3 = true;
        shape.m_vertex0 = verts1[i-1];
        shape.m_vertex3 = verts1[i+2];
        ground->CreateFixture(&shape, .0f);
        
    }
    shape.Set(verts1[vertsNum1-2], verts1[vertsNum1-1]);
    shape.m_hasVertex0 = true;
    shape.m_vertex0 = verts1[vertsNum1-3];
    ground->CreateFixture(&shape, 0.0f);
    
}

-(void)addMap2
{
    b2BodyDef bd;
    bd.type = b2_staticBody;
    b2Body* ground = m_world->CreateBody(&bd);
    vertsNum2 = 4;
    verts2 = (b2Vec2 *)malloc (vertsNum2 * sizeof (b2Vec2));
    
    verts2[0].Set(89.0f / PTM_RATIO, 134.0f / PTM_RATIO);
    verts2[1].Set(366.0f / PTM_RATIO, 65.0f / PTM_RATIO);
    verts2[2].Set(361.0f / PTM_RATIO, -18.0f / PTM_RATIO);
    verts2[3].Set(574.0f / PTM_RATIO, -39.0f / PTM_RATIO);
    
    
    b2EdgeShape shape;
    
    shape.Set(verts2[0], verts2[1]);
    shape.m_hasVertex3 = true;
    shape.m_vertex3 = verts2[2];
    ground->CreateFixture(&shape, 0.0f);
    
    for(int i = 1; i <= vertsNum2-3; i++)
    {
        shape.Set(verts2[i], verts2[i+1]);
        shape.m_hasVertex0 = true;
        shape.m_hasVertex3 = true;
        shape.m_vertex0 = verts2[i-1];
        shape.m_vertex3 = verts2[i+2];
        ground->CreateFixture(&shape, .0f);
        
    }
    shape.Set(verts2[vertsNum2-2], verts2[vertsNum2-1]);
    shape.m_hasVertex0 = true;
    shape.m_vertex0 = verts2[vertsNum2-3];
    ground->CreateFixture(&shape, 0.0f);
    
}

-(void)addSingleMap
{
    singleVerNum = 4;
    singleVers = (singleVec *)malloc (singleVerNum * sizeof (singleVec));
    
    singleVers[0].vec1.Set((640.f-329.0f) / PTM_RATIO, (360.f+242.0f) / PTM_RATIO);
    singleVers[0].vec2.Set((640.f-38.0f) / PTM_RATIO, (360.f+163.0f) / PTM_RATIO);
    
    singleVers[1].vec1.Set((640.f+110.0f) / PTM_RATIO, (360.f+128.0f) / PTM_RATIO);
    singleVers[1].vec2.Set((640.f+336.0f) / PTM_RATIO, (360.f+77.0f) / PTM_RATIO);
    
    singleVers[2].vec1.Set((640.f-358.0f) / PTM_RATIO, (360.f+30.0f) / PTM_RATIO);
    singleVers[2].vec2.Set((640.f-285.0f) / PTM_RATIO, (360.f+46.0f) / PTM_RATIO);
    
    singleVers[3].vec1.Set((640.f-157.0f) / PTM_RATIO, (360.f+33.0f) / PTM_RATIO);
    singleVers[3].vec2.Set((640.f+300.0f) / PTM_RATIO, (360.f-53.0f) / PTM_RATIO);
    
    
    b2BodyDef bd;
    bd.type = b2_staticBody;
    b2Body* ground = m_world->CreateBody(&bd);
    b2EdgeShape shape;
    
    shape.Set(singleVers[0].vec1, singleVers[0].vec2);
    shape.m_hasVertex3 = false;
    ground->CreateFixture(&shape, 0.0f);
    
    shape.Set(singleVers[1].vec1, singleVers[1].vec2);
    shape.m_hasVertex3 = false;
    ground->CreateFixture(&shape, 0.0f);
    
    shape.Set(singleVers[2].vec1, singleVers[2].vec2);
    shape.m_hasVertex3 = false;
    ground->CreateFixture(&shape, 0.0f);
    
    shape.Set(singleVers[3].vec1, singleVers[3].vec2);
    shape.m_hasVertex3 = false;
    ground->CreateFixture(&shape, 0.0f);
    
}

-(void)addMapX
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

-(void)update:(ccTime)dt
{
	// Update positions, and hash them
    [super update:dt];
    
}


-(void)addDangban:(CGPoint)ps event:(NSEvent*)event
{
    {
        dang = [CCDangBan node];
        [dang initPhysical:ps event:event];
        dang.anchorPoint = ccp(0,0);
        dang.position = ccp(0,0);
        [self addChild:dang z:100];
    }
}

-(void)addDXF:(CGPoint)ps event:(NSEvent*)event
{
    
}

-(void)addXW:(CGPoint)ps event:(NSEvent*)event
{
    
}

@end
