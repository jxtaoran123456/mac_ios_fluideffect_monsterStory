//
//  SPHNode.m
//  SPH
//
//  Created by Vasiliy Yanushevich on 11/2/12.
//  Copyright 2012 Vasiliy Yanushevich. All rights reserved.
//

#import "SPHNode.h"
#import "testLv19.h"

#include <GLUT/GLUT.h>
#include <OpenGL/glu.h>
#import "sphSmoke.h"


@implementation testLv19

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	testLv19 *layer = [testLv19 node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
    
}

-(id)init
{
    if (self = [super init])
    {
        fluidPraNum = 26000;
        toolsNum = 3;
        shushuiPs = ccp(120,850);
        firePs = ccp(900,280);
        particleNum = 500;
        
        collisionFactor = 10.f;
        
        [self createFire:firePs];
        
        [self createStaticGeometry];

        intersectQueryCallback = new QueryWorldInteractions(hashGridList, liquid);
        eulerIntersectQueryCallback = new QueryWorldPostIntersect(hashGridList, liquid);
        
        smintersectQueryCallback = new smQueryWorldInteractions(hashGridList, smliquid);
        smeulerIntersectQueryCallback = new smQueryWorldPostIntersect(hashGridList, smliquid);
        
        //back back1 fluid tree back2
        backgroundSprite = [CCSprite spriteWithFile:@"lv3_back.png"];//testLevel1.png testLevel3 3_1.png lv3_back.png
        backgroundSprite.anchorPoint = ccp(0,0);
        backgroundSprite.position = ccp(0,0);//(72,40);
        [self addChild:backgroundSprite z:zOrder+1];
        
        [rippleSprArr addObject:backgroundSprite];
        [backgroundSprite release];
        
        [self initMenu2];
        
        CCSprite *dangSpr = [CCSprite spriteWithFile:@"r1.png"];
        dangSpr.position = ccp(90,50);
        [self addChild:dangSpr z:zOrder+100];
        
        CCSprite *dfsSpr = [CCSprite spriteWithFile:@"r1.png"];
        dfsSpr.position = ccp(180,50);
        [self addChild:dfsSpr z:zOrder+100];
        
        CCSprite *xwSpr = [CCSprite spriteWithFile:@"r1.png"];
        xwSpr.position = ccp(270,50);
        [self addChild:xwSpr z:zOrder+100];
        
        CCSprite *szSpr = [CCSprite spriteWithFile:@"r1.png"];
        szSpr.position = ccp(360,50);
        [self addChild:szSpr z:zOrder+100];
        
        CCSprite *xtsSpr = [CCSprite spriteWithFile:@"r1.png"];
        xtsSpr.position = ccp(450,50);
        [self addChild:xtsSpr z:zOrder+100];
    
        [self scheduleUpdate];
        
    }
    return self;
    
}

-(void)initMenu
{
    CGSize s = [CCDirector sharedDirector].winSize;
    CCMenuItemImage *releaseFluid = [CCMenuItemImage itemWithNormalImage:@"r1.png" selectedImage:@"r2.png" target:self selector:@selector(releaseFluidEvent:)];
    CCMenu *fluidButton = [CCMenu menuWithItems: releaseFluid,nil];
    fluidButton.position = CGPointZero;
    fluidButton.position = ccp( s.width-50, 50);
    [self addChild:fluidButton z:100];
    
}

-(void)releaseFluidEvent:(id)sender
{
    awakePraticles(100,b2Vec2(shushuiPs.x,shushuiPs.y),10,-6.f,b2Vec2(0.f,-10.f),30.f,0,false);
    
}

-(void)initMenu2
{
    //mousePressedTick
    CGSize s = [CCDirector sharedDirector].winSize;
    releaseFluidBt = [CCSprite spriteWithFile:@"r1.png"];
    releaseFluidBt.position = CGPointZero;
    releaseFluidBt.position = ccp(s.width-50, 50);
    [self addChild:releaseFluidBt z:100];
    
    scoreLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",fluidPraNum] fontName:@"Marker Felt" fontSize:32];
    [self addChild:scoreLabel z:zOrder+100];
    [scoreLabel setColor:ccc3(255,255,255)];
    scoreLabel.position = ccp(s.width-60,s.height-40);
    
}

-(void)createFire:(CGPoint)pos
{
    fireParticle = [CCParticleSystemQuad particleWithFile:@"firek3.plist"];
    fireParticle.positionType = kCCPositionTypeFree;
    fireParticle.anchorPoint  = ccp(0,0);
    fireParticle.position = pos;
    fireParticle.scale = 0.3f;
    [self addChild:fireParticle z:zOrder+22];

}

-(void)createStaticGeometry
{
    b2Vec2 gravity;
	gravity.Set(0.0f, -10.0f);
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
    [self addMap1];
    [self addMap2];
	
    // Particles
    initFluidPraticles(0.9f,0.006f,90.f,30.f,1000,@"fire_010.png",nil);// VbmyR.png fire2 drop2
    sminitFluidPraticles(1.6f,1.212f,450.f,30.f,500,@"smoke32.png",nil);
    //added by tr 2013-08-08
    
    CCSprite *sprite = [CCSprite spriteWithFile:@"inner.png"];
    [self addChild:sprite z:zOrder+180];
    
    [self createSliderCrank];
    
    //ball
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set((290-0.0f) / PTM_RATIO, (390.f) / PTM_RATIO);
    bodyDef.angle = 0.f;
    b2Body *body = m_world->CreateBody(&bodyDef);
    body->SetUserData(sprite);
    body->toolsType = 1002;//铁锤
    // Define another box shape for our dynamic body.
    b2CircleShape dynamicBox;
    dynamicBox.m_radius = 1.2f;
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &dynamicBox;
    fixtureDef.density = 4.4f;
    fixtureDef.friction = 0.0f;
    fixtureDef.restitution = 0.0;
    body->CreateFixture(&fixtureDef);
    fireBall = body;

    b2BodyDef bodyDef3;
    bodyDef3.type = b2_staticBody;
    bodyDef3.position.Set((shushuiPs.x-90.f)/PTM_RATIO, (shushuiPs.y-40.f)/PTM_RATIO);
    bodyDef3.angle = -1*30.f*PI/180.f;
    b2Body *body3 = m_world->CreateBody(&bodyDef3);
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox3;
    dynamicBox3.SetAsBox(8.f,0.65f);
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef3;
    fixtureDef3.shape = &dynamicBox3;
    fixtureDef3.density = 1.f;
    fixtureDef3.friction = 0.0f;
    body3->CreateFixture(&fixtureDef3);
    
    b2BodyDef bodyDef4;
    bodyDef4.type = b2_staticBody;
    bodyDef4.position.Set((shushuiPs.x-90-160.f)/PTM_RATIO, (shushuiPs.y-40.f+320.f)/PTM_RATIO);
    bodyDef4.angle = 0;
    b2Body *body4 = m_world->CreateBody(&bodyDef4);
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox4;
    dynamicBox4.SetAsBox(0.65f,8.5f);
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef4;
    fixtureDef4.shape = &dynamicBox4;
    fixtureDef4.density = 1.f;
    fixtureDef4.friction = 0.0f;
    body4->CreateFixture(&fixtureDef4);

}

-(void)addSz
{
    b2BodyDef bodyDef;
    bodyDef.type = b2_kinematicBody;
    
    bodyDef.position.Set(640.f/PTM_RATIO, 360.f/PTM_RATIO);
    b2Body *body = m_world->CreateBody(&bodyDef);
    
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox;
    dynamicBox.SetAsBox(8.5f,0.60f);
    
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &dynamicBox;
    fixtureDef.density = 3.f;
    fixtureDef.friction = 0.0f;
    body->CreateFixture(&fixtureDef);
    
    b2BodyDef bodyDef2;
    bodyDef2.type = b2_kinematicBody;
    
    bodyDef2.position.Set(640.f/PTM_RATIO, 360.f/PTM_RATIO);
    bodyDef2.angle = 3.1415926/2.f;
    b2Body *body2 = m_world->CreateBody(&bodyDef2);
    
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox2;
    dynamicBox2.SetAsBox(8.5f,0.60f);
    
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef2;
    fixtureDef2.shape = &dynamicBox2;
    fixtureDef2.density = 1.f;
    fixtureDef2.friction = 0.00f;
    body2->CreateFixture(&fixtureDef2);
    
    float angleSpeed = -1.4f;
    
    body->SetAngularVelocity(angleSpeed*1.f);
    body2->SetAngularVelocity(angleSpeed*1.f);
    
}

-(void)createSliderCrank
{
    b2RevoluteJoint* m_joint1;
	b2PrismaticJoint* m_joint2;
    
    b2Body* ground = NULL;
    {
        b2BodyDef bd;
        ground = m_world->CreateBody(&bd);
        
        b2EdgeShape shape;
        shape.Set(b2Vec2(0.0f, 0.0f), b2Vec2(1.0f, 0.0f));
        ground->CreateFixture(&shape, 0.0f);
    }
    
    b2Body* prevBody = ground;
    
    // Define crank.
    {
        b2PolygonShape shape;
        shape.SetAsBox(0.5f, 1.0f);
        
        b2BodyDef bd;
        bd.type = b2_dynamicBody;
        bd.position.Set(20.0f, 6.0f);
        b2Body* body = m_world->CreateBody(&bd);
        body->CreateFixture(&shape, 2.0f);
        
        b2RevoluteJointDef rjd;
        rjd.Initialize(prevBody, body, b2Vec2(20.0f, 5.0f));
        rjd.motorSpeed = 1.0f * b2_pi;
        rjd.maxMotorTorque = 10000.0f;
        rjd.enableMotor = true;
        m_joint1 = (b2RevoluteJoint*)m_world->CreateJoint(&rjd);
        
        prevBody = body;
    }
    
    // Define follower.
    {
        b2PolygonShape shape;
        shape.SetAsBox(0.5f, 2.0f);
        
        b2BodyDef bd;
        bd.type = b2_dynamicBody;
        bd.position.Set(20.0f, 9.0f);
        b2Body* body = m_world->CreateBody(&bd);
        body->CreateFixture(&shape, 2.0f);
        
        b2RevoluteJointDef rjd;
        rjd.Initialize(prevBody, body, b2Vec2(20.0f, 7.0f));
        rjd.enableMotor = false;
        m_world->CreateJoint(&rjd);
        
        prevBody = body;
    }
    
    // Define piston
    {
        b2PolygonShape shape;
        shape.SetAsBox(4.0f, .5f);
        
        b2BodyDef bd;
        bd.type = b2_dynamicBody;
        bd.fixedRotation = true;
        bd.position.Set(20.0f, 11.0f);
        b2Body* body = m_world->CreateBody(&bd);
        body->CreateFixture(&shape, 2.0f);
        //bianseBox = body;
        
        b2RevoluteJointDef rjd;
        rjd.Initialize(prevBody, body, b2Vec2(20.0f, 11.0f));
        m_world->CreateJoint(&rjd);
        
        b2PrismaticJointDef pjd;
        pjd.Initialize(ground, body, b2Vec2(20.0f, 11.0f), b2Vec2(0.0f, 1.0f));
        
        pjd.maxMotorForce = 1.0f;
        pjd.enableMotor = true;
        
        m_joint2 = (b2PrismaticJoint*)m_world->CreateJoint(&pjd);
    }
    
}


- (BOOL) ccMouseDown:(NSEvent *)event
{
    prePoint = ccp([event locationInWindow].x,[event locationInWindow].y);
    CGSize s = [CCDirector sharedDirector].winSize;
    
    //判断是否点击的道具按钮
    if(prePoint.x <= 120 && prePoint.x >= 60 && prePoint.y <= 90 && prePoint.y >= 10)//添加格挡
    {
        //if(dang == nil)
        {
            [self addDangban:prePoint event:event];
        }
        return NO;
    }
    else if(prePoint.x <= 210 && prePoint.x >= 150 && prePoint.y <= 90 && prePoint.y >= 10)//添加风扇
    {
        //if(dfs == nil)
        {
            [self addDXF:prePoint event:event];
        }
        return NO;
    }
    else if(prePoint.x <= 300 && prePoint.x >=240 && prePoint.y <= 90 && prePoint.y >= 10)//添加漩涡
    {
        //if(xw == nil)
        {
            [self addXW:prePoint event:event];
        }
        return NO;
    }
    else if(prePoint.x <= 390 && prePoint.x >= 330 && prePoint.y <= 90 && prePoint.y >= 10)//添加漩涡
    {
        //if(xw == nil)
        {
            [self addShiZi:prePoint event:event];
        }
        return NO;
    }
    else if(prePoint.x <= 480 && prePoint.x >= 420 && prePoint.y <= 90 && prePoint.y >= 10)//添加漩涡
    {
        //if(xw == nil)
        {
            [self addXTS:prePoint event:event];
        }
        return NO;
    }
    else if(prePoint.x <= s.width-20 && prePoint.x >= s.width-70 && prePoint.y <= 100 && prePoint.y >= 50 && releaseFluidBt != nil && result == 0)//haveAwakeParticlesNum < fluidPraNum
    {
        awakePraticles(100,b2Vec2(shushuiPs.x,shushuiPs.y),10,-10.f,b2Vec2(0.f,-10.f),30.f,0,false);
        [releaseFluidBt setTexture:[[CCTextureCache sharedTextureCache] addImage: @"r2.png"]];
        ifFluidBtPressed = YES;
    }
    return NO;
    
}

-(BOOL) ccMouseMoved:(NSEvent*)event
{
    ifMove = true;
    return NO;
    
}

-(BOOL) ccMouseDragged:(NSEvent*)event//移动事件
{
    if(ifFluidBtPressed == YES)
    {
        CGPoint curPoint = ccp([event locationInWindow].x,[event locationInWindow].y);
        CGSize s = [CCDirector sharedDirector].winSize;
        if(curPoint.x <= s.width-20 && curPoint.x >= s.width-70  && curPoint.y <= 100 && curPoint.y >= 50 && releaseFluidBt != nil)
        {
            
        }
        else
        {
            [releaseFluidBt setTexture:[[CCTextureCache sharedTextureCache] addImage: @"r1.png"]];
            ifFluidBtPressed = NO;
        }
    }
    ifMove = true;
    return NO;
}

-(BOOL) ccMouseUp:(NSEvent*)event
{
    if(ifMove == true && ifFluidBtPressed == NO)
    {
        ifMove = false;
    }
    else if(ifMove == false && ifFluidBtPressed == NO)
    {
    }
    else if(ifMove == true && ifFluidBtPressed == YES)
    {
        ifFluidBtPressed = NO;
        [releaseFluidBt setTexture:[[CCTextureCache sharedTextureCache] addImage: @"r1.png"]];
    }
    else if(ifMove == false && ifFluidBtPressed == YES)
    {
        ifFluidBtPressed = NO;
        [releaseFluidBt setTexture:[[CCTextureCache sharedTextureCache] addImage: @"r1.png"]];
    }
    
    return NO;

}

-(void)collisionHandle:(b2Body*)body
{
 
}

-(void) draw
{

    
    [super draw];

}

-(void)dealloc
{
    [super dealloc];
    
    smclearMemory();
	smclearHashGrid();
    delete smintersectQueryCallback;
    smintersectQueryCallback = NULL;
    delete smeulerIntersectQueryCallback;
    smeulerIntersectQueryCallback = NULL;
    
}

-(void)addMap
{
    b2BodyDef bd;
    bd.type = b2_staticBody;
    b2Body* ground = m_world->CreateBody(&bd);
    vertsNum = 7;
    verts = (b2Vec2 *)malloc (vertsNum * sizeof (b2Vec2));

//    verts[0].Set((640-615.0f) / PTM_RATIO, (360+356.0f) / PTM_RATIO);
//    verts[1].Set((640-612.0f) / PTM_RATIO, (360+7.0f) / PTM_RATIO);
//    verts[2].Set((640-106.0f) / PTM_RATIO, (360+23.0f) / PTM_RATIO);
//    verts[3].Set((640-68.0f) / PTM_RATIO, (360+14.0f) / PTM_RATIO);
//    verts[4].Set((640-82.0f) / PTM_RATIO, (360-138.0f) / PTM_RATIO);
//    verts[5].Set((640+5.0f) / PTM_RATIO, (360-294.0f) / PTM_RATIO);
//    verts[6].Set((640+532.0f) / PTM_RATIO, (360-294.0f) / PTM_RATIO);
//    verts[7].Set((640+542.0f) / PTM_RATIO, (360+49.0f) / PTM_RATIO);
//    verts[8].Set((640+587.0f) / PTM_RATIO, (360+50.0f) / PTM_RATIO);
//    verts[9].Set((640+613.0f) / PTM_RATIO, (360-357.0f) / PTM_RATIO);
//    verts[10].Set((640-630.0f) / PTM_RATIO, (360-355.0f) / PTM_RATIO);
    
    verts[0].Set((640-638.0f) / PTM_RATIO, (360+238.0f) / PTM_RATIO);
    verts[1].Set((640-582.0f) / PTM_RATIO, (360+2.0f) / PTM_RATIO);
    verts[2].Set((640-475.0f) / PTM_RATIO, (360-13.0f) / PTM_RATIO);
    verts[3].Set((640-367.0f) / PTM_RATIO, (360-16.0f) / PTM_RATIO);
    verts[4].Set((640-265.0f) / PTM_RATIO, (360-15.0f) / PTM_RATIO);
    verts[5].Set((640-291.0f) / PTM_RATIO, (360-359.0f) / PTM_RATIO);
    verts[6].Set((640-636.0f) / PTM_RATIO, (360-355.0f) / PTM_RATIO);

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
    
    shape.Set(verts[vertsNum-1], verts[0]);
    shape.m_hasVertex0 = true;
    shape.m_vertex0 = verts[vertsNum-2];
    ground->CreateFixture(&shape, 0.0f);
    
}

-(void)addMap1
{
    b2BodyDef bd;
    bd.type = b2_staticBody;
    b2Body* ground = m_world->CreateBody(&bd);
    vertsNum1 = 8;
    verts1 = (b2Vec2 *)malloc (vertsNum1 * sizeof (b2Vec2));
    
    verts1[0].Set((640.f+165.0f) / PTM_RATIO, (360.f-357.0f) / PTM_RATIO);
    verts1[1].Set((640.f+175.0f) / PTM_RATIO, (360.f-217.0f) / PTM_RATIO);
    verts1[2].Set((640.f+196.0f) / PTM_RATIO, (360.f-121.0f) / PTM_RATIO);
    verts1[3].Set((640.f+315.0f) / PTM_RATIO, (360.f-117.0f) / PTM_RATIO);
    verts1[4].Set((640.f+395.0f) / PTM_RATIO, (360.f-145.0f) / PTM_RATIO);
    verts1[5].Set((640.f+391.0f) / PTM_RATIO, (360.f-284.0f) / PTM_RATIO);
    verts1[6].Set((640.f+613.0f) / PTM_RATIO, (360.f-297.0f) / PTM_RATIO);
    verts1[7].Set((640.f+635.0f) / PTM_RATIO, (360.f-354.0f) / PTM_RATIO);
    
    b2EdgeShape shape;
    
    shape.Set(verts1[0], verts1[1]);
    shape.m_hasVertex3 = true;
    shape.m_vertex3 = verts1[2];
    ground->CreateFixture(&shape, 10.0f);
    
    for(int i = 1; i <= vertsNum1-3; i++)
    {
        shape.Set(verts1[i], verts1[i+1]);
        shape.m_hasVertex0 = true;
        shape.m_hasVertex3 = true;
        shape.m_vertex0 = verts1[i-1];
        shape.m_vertex3 = verts1[i+2];
        ground->CreateFixture(&shape, 10.0f);
        
    }
    shape.Set(verts1[vertsNum1-2], verts1[vertsNum1-1]);
    shape.m_hasVertex0 = true;
    shape.m_vertex0 = verts1[vertsNum1-3];
    ground->CreateFixture(&shape, 10.0f);
    
    shape.Set(verts1[vertsNum1-1], verts1[0]);
    shape.m_hasVertex0 = true;
    shape.m_vertex0 = verts1[vertsNum1-2];
    ground->CreateFixture(&shape, 10.0f);
    
    
}

-(void)addMap2
{
    b2BodyDef bd;
    bd.type = b2_staticBody;
    b2Body* ground = m_world->CreateBody(&bd);
    vertsNum2 = 9;
    verts2 = (b2Vec2 *)malloc (vertsNum2 * sizeof (b2Vec2));
    
//    verts2[0].Set((640.f-301.0f) / PTM_RATIO, (360.f+302.0f) / PTM_RATIO);
//    verts2[1].Set((640.f-303.0f) / PTM_RATIO, (360.f+217.0f) / PTM_RATIO);
//    verts2[2].Set((640.f-247.0f) / PTM_RATIO, (360.f+145.0f) / PTM_RATIO);
//    verts2[3].Set((640.f-195.0f) / PTM_RATIO, (360.f+78.0f) / PTM_RATIO);
//    verts2[4].Set((640.f-86.0f) / PTM_RATIO, (360.f+147.0f) / PTM_RATIO);
//    verts2[5].Set((640.f-77.0f) / PTM_RATIO, (360.f+104.0f) / PTM_RATIO);
//    verts2[6].Set((640.f-22.0f) / PTM_RATIO, (360.f+90.0f) / PTM_RATIO);
//    verts2[7].Set((640.f+35.0f) / PTM_RATIO, (360.f+187.0f) / PTM_RATIO);
//    verts2[8].Set((640.f+23.0f) / PTM_RATIO, (360.f+232.0f) / PTM_RATIO);
//    verts2[9].Set((640.f+86.0f) / PTM_RATIO, (360.f+251.0f) / PTM_RATIO);
//    verts2[10].Set((640.f+30.0f) / PTM_RATIO, (360.f+288.0f) / PTM_RATIO);
//    verts2[11].Set((640.f-92.0f) / PTM_RATIO, (360.f+312.0f) / PTM_RATIO);
    
    verts2[0].Set((640.f-201.0f) / PTM_RATIO, (360.f+321.0f) / PTM_RATIO);
    verts2[1].Set((640.f+107.0f) / PTM_RATIO, (360.f+318.0f) / PTM_RATIO);
    verts2[2].Set((640.f+201.0f) / PTM_RATIO, (360.f+292.0f) / PTM_RATIO);
    verts2[3].Set((640.f+152.0f) / PTM_RATIO, (360.f+197.0f) / PTM_RATIO);
    verts2[4].Set((640.f+151.0f) / PTM_RATIO, (360.f+106.0f) / PTM_RATIO);
    verts2[5].Set((640.f-34.0f) / PTM_RATIO, (360.f+98.0f) / PTM_RATIO);
    verts2[6].Set((640.f-138.0f) / PTM_RATIO, (360.f+71.0f) / PTM_RATIO);
    verts2[7].Set((640.f-210.0f) / PTM_RATIO, (360.f+186.0f) / PTM_RATIO);
    verts2[8].Set((640.f-198.0f) / PTM_RATIO, (360.f+280.0f) / PTM_RATIO);


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
    
    shape.Set(verts2[vertsNum2-1], verts2[0]);
    shape.m_hasVertex0 = true;
    shape.m_vertex0 = verts2[vertsNum1-2];
    ground->CreateFixture(&shape, 10.0f);
    
}

-(void)addSingleMap
{
    singleVerNum = 3;
    singleVers = (singleVec *)malloc (singleVerNum * sizeof (singleVec));
    
    singleVers[0].vec1.Set((640.f-634.0f) / PTM_RATIO, (360.f+225.0f) / PTM_RATIO);
    singleVers[0].vec2.Set((640.f-103.0f) / PTM_RATIO, (360.f+225.0f) / PTM_RATIO);
    
    singleVers[1].vec1.Set((640.f+360.0f) / PTM_RATIO, (360.f+109.0f) / PTM_RATIO);
    singleVers[1].vec2.Set((640.f+580.0f) / PTM_RATIO, (360.f+112.0f) / PTM_RATIO);
    
    singleVers[2].vec1.Set((640.f+580.0f) / PTM_RATIO, (360.f+112.0f) / PTM_RATIO);
    singleVers[2].vec2.Set((587.0f+640.f) / PTM_RATIO, (360.f+30.0f) / PTM_RATIO);
    
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
    
}

-(void)toolsForce
{
    if(dfs != nil)
    {
        [dfs comupteAttractiveForceFromDFS:3000 waterParticle:liquid];
    }
    if(xw != nil)
    {
        [xw comupteAttractiveForceFromXW:3000 waterParticle:liquid];
    }
    if(xts != nil)
    {
        [xts comupteAttractiveForceFromXTS:3000 waterParticle:liquid];
    }
    
}

-(int)winJudge
{
    int innerWinCount = 0;
    b2Vec2 poly[4];
    
    poly[0].Set((640.f+309.0f) / PTM_RATIO, (360.f+169.0f) / PTM_RATIO);
    poly[1].Set((640.f+323.0f) / PTM_RATIO, (360.f-48.0f) / PTM_RATIO);
    poly[2].Set((640.f+583.0f) / PTM_RATIO, (360.f-53.0f) / PTM_RATIO);
    poly[3].Set((640.f+583.0f) / PTM_RATIO, (360.f+246.0f) / PTM_RATIO);
    
    
    for(int i = 0; i < nParticles; ++i)
	{
        if(PtInPolygon(liquid[i].mPosition,poly,4) > 0)
        {
            innerWinCount++;
        }
    }
    if(innerWinCount >= 600 && result != 1)
    {
        [self computeScore];
        result = 1;
        return 1;
    }
    else return 0;
    
}

-(int)computeScore
{
    int toolsScore = (toolsNum - usedToolsNum) *1000;
    int fluidScore = fluidPraNum - haveAwakeParticlesNum;
    int timeScore = 72000/deltaTime;
    score = toolsScore + fluidScore + timeScore;
    NSLog(@"totalScore:%d toolsScore:%d\t fluidScore:%d\t timeScore:%d\t",score,toolsScore,fluidScore,timeScore);
    
    return score;
}

-(void)updateUI
{
    [scoreLabel setString:[NSString stringWithFormat:@"%d",fluidPraNum-haveAwakeParticlesNum]];
    
}

-(void)update:(ccTime)dt
{
	// Update positions, and hash them
    if(ifFluidBtPressed == YES)
    {
        mousePressedTick++;
        if(mousePressedTick % 15 == 0 && mousePressedTick != 0 && result == 0)//&& isWaitForSmoothFlow == false) haveAwakeParticlesNum < fluidPraNum
        {
            mousePressedTick = 0;
            awakePraticles(60,b2Vec2(shushuiPs.x,shushuiPs.y),40,60.f,b2Vec2(0.f,-10.f),0.f,0,true);
        }
    }
    
    //added by tr 2013-10-21
    for(int i = 0; i < nParticles;i++)
    {

        if(fireParticle != nil && (liquid[i].mPosition*PTM_RATIO - b2Vec2(fireParticle.position.x,fireParticle.position.y)).Length() <= 30.f)
        {
            for(int j = 0; j < smnParticles;j++)
            {
                if(smliquid[j].isAwake == false)
                {
                    smliquid[j].isAwake = true;
                    smliquid[j].mPosition = liquid[i].mPosition;
                    smliquid[j].mVelocity = b2Vec2(0,rand()%3-1);
                    break;
                }
                
            }
            liquid[i].mPosition = b2Vec2(-10,-10);
//            particleNum -= 5;
//            fireParticle.scale = fireParticle.scale - particleNum/500;
//            if(particleNum < 30)
//            {
//                [fireParticle removeFromParentAndCleanup:YES];
//                fireParticle = nil;
//            }
        }
        
        if(ifBecBall == NO && fireParticle != nil && ((b2Vec2)(fireBall->GetPosition())*PTM_RATIO - b2Vec2(fireParticle.position.x,fireParticle.position.y)).Length() <= 40.f)
        {
            ifBecBall = YES;
            fireParticle2 = [CCParticleSystemQuad particleWithFile:@"firek4.plist"];
            fireParticle2.positionType = kCCPositionTypeFree;
            fireParticle2.anchorPoint  = ccp(0.5,0.5);
            fireParticle2.scale = 0.3f;
            [self addChild:fireParticle2 z:zOrder+22];
            
        }
        
        if(ifBecBall == YES && fireParticle2 != nil)
        {
            fireParticle2.position = ccp((fireBall->GetPosition()).x*PTM_RATIO,(fireBall->GetPosition()).y*PTM_RATIO);
            //fireParticle2.rotation = -1.f * 57.29577951f *(fireBall->GetAngle());
            
        }
        
        
    }
    
    smupdateFluidStep(dt);
    //ended by tr 2013-10-21
    
    if((fireBall->GetPosition()).y < -3.f)
    {
        fireBall->SetAngularVelocity(0.f);
        fireBall->SetLinearVelocity(b2Vec2(0,0));
        fireBall->SetTransform(b2Vec2((290-0.0f) / PTM_RATIO, (390.f) / PTM_RATIO), 0);
        if(fireParticle2 != nil)
        {
            [fireParticle2 removeFromParentAndCleanup:YES];
            fireParticle2 = nil;
        }
        ifBecBall = YES;
        resetAllFluid();
    }

    [super update:dt];
    
}

-(void)addDangban:(CGPoint)ps event:(NSEvent*)event
{
    if(usedToolsNum >= toolsNum)return;

    {
        dang = [CCDangBan node];
        [dang initPhysical:ps event:event];
        dang.anchorPoint = ccp(0,0);
        dang.position = ccp(0,0);
        dang.rStick.unusedSection1 = unusedSection1;
        dang.rStick.unusedSection1VecNum = 0;
        dang.rStick.disappearSection = ccp(90,50);
        dang.rStick.disappearRadius = 30;
        [dang.rStick setMousePriority:mousePriority--];
        [self addChild:dang z:zOrder+100];
        usedToolsNum++;
    }
    
}

-(void)addDXF:(CGPoint)ps event:(NSEvent*)event
{
    //if(dfs == nil)
    {
        dfs = [CCDianFengShan node];
        [dfs initPhysical:ps event:event];
        dfs.m_numParticles = nParticles;
        dfs.m_liquid = liquid;
        dfs.anchorPoint = ccp(0,0);
        dfs.position = ccp(0,0);
        dfs.rStick.unusedSection1 = unusedSection1;
        dfs.rStick.unusedSection1VecNum = 4;
        dfs.rStick.disappearSection = ccp(180,50);
        dfs.rStick.disappearRadius = 30;
        [dfs.rStick setMousePriority:mousePriority--];
        [self addChild:dfs z:zOrder+100];
    }
    
}

-(void)addXW:(CGPoint)ps event:(NSEvent*)event
{
    //if(xw == nil)
    {
        //xw = [[CCXuanWo node]initPhysical:ps];
        xw = [CCXuanWo node];
        [xw initPhysical:ps event:event];
        xw.m_numParticles = nParticles;
        xw.m_liquid = liquid;
        xw.anchorPoint = ccp(0,0);
        xw.position = ccp(0,0);
        xw.rStick.unusedSection1 = unusedSection1;
        xw.rStick.unusedSection1VecNum = 4;
        xw.rStick.disappearSection = ccp(270,50);
        xw.rStick.disappearRadius = 30;
        [xw.rStick setMousePriority:mousePriority--];
        [self addChild:xw z:zOrder+100];
    }
    
}

-(void)addShiZi:(CGPoint)ps event:(NSEvent*)event
{
    //if(sz == nil)
    {
        sz = [CCShiZi node];
        [sz initPhysical:ps event:event];
        sz.m_numParticles = nParticles;
        sz.m_liquid = liquid;
        sz.anchorPoint = ccp(0,0);
        sz.position = ccp(0,0);
        sz.rStick.unusedSection1 = unusedSection1;
        sz.rStick.unusedSection1VecNum = 4;
        sz.rStick.disappearSection = ccp(360,50);
        sz.rStick.disappearRadius = 30;
        [sz.rStick setMousePriority:mousePriority--];
        [self addChild:sz z:zOrder+100];
    }
    
}

-(void)addXTS:(CGPoint)ps event:(NSEvent*)event
{
    //if(xts == nil)
    {
        xts = [CCXiTieShi node];
        [xts initPhysical:ps event:event];
        xts.m_numParticles = nParticles;
        xts.m_liquid = liquid;
        xts.anchorPoint = ccp(0,0);
        xts.position = ccp(0,0);
        xts.rStick.unusedSection1 = unusedSection1;
        xts.rStick.unusedSection1VecNum = 4;
        xts.rStick.disappearSection = ccp(450,50);
        xts.rStick.disappearRadius = 30;
        [xts.rStick setMousePriority:mousePriority--];
        [self addChild:xts z:zOrder+100];
    }
    
}

@end
