//
//  SPHNode.m
//  SPH
//
//  Created by Vasiliy Yanushevich on 11/2/12.
//  Copyright 2012 Vasiliy Yanushevich. All rights reserved.
//

#import "SPHNode.h"
#import "testLv30.h"

#include <GLUT/GLUT.h>
#include <OpenGL/glu.h>


@implementation testLv30

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	testLv30 *layer = [testLv30 node];
	
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
        shushuiPs = ccp(-50,700);
        
        fpressure = 8.0f;
        fpresnear = 8.0f;
        
        [self createStaticGeometry];

        intersectQueryCallback = new QueryWorldInteractions(hashGridList, liquid);
        eulerIntersectQueryCallback = new QueryWorldPostIntersect(hashGridList, liquid);
        
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
    
    [self createJinggai];
	
    // Particles
    initFluidPraticles(1.0f,0.002f,100.f,30.f,2000,@"fire_010.png",nil);// VbmyR.png fire2 drop2
    //added by tr 2013-08-08
    
    CCSprite *sprite = [CCSprite spriteWithFile:@"inner.png"];
    [self addChild:sprite z:zOrder+180];
    
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

-(void)createJinggai
{
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set((280.f)/PTM_RATIO, (290.f)/PTM_RATIO);
    bodyDef.angle = 0.f;
    b2Body *body = m_world->CreateBody(&bodyDef);
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox;
    dynamicBox.SetAsBox(4.f,.2f);
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &dynamicBox;
    fixtureDef.density = 100.f;
    fixtureDef.friction = 0.0f;
    fixtureDef.filter.maskBits = 1;
    body->CreateFixture(&fixtureDef);
    jinggai1 = body;
    
    b2BodyDef bodyDefX;
    bodyDefX.type = b2_dynamicBody;
    bodyDefX.position.Set((296.f+4.f*PTM_RATIO)/PTM_RATIO, (290.f)/PTM_RATIO);
    bodyDefX.angle = 0.f;
    b2Body *bodyX = m_world->CreateBody(&bodyDefX);
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBoxX;
    dynamicBoxX.SetAsBox(.5f,.2f);
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDefX;
    fixtureDefX.shape = &dynamicBoxX;
    fixtureDefX.density = 100.f;
    fixtureDefX.friction = 0.0f;
    fixtureDefX.filter.maskBits = 1;
    bodyX->CreateFixture(&fixtureDefX);
    
    b2BodyDef bodyDefX1;
    bodyDefX1.type = b2_dynamicBody;
    bodyDefX1.position.Set((264.f-4.f*PTM_RATIO)/PTM_RATIO, (290.f)/PTM_RATIO);
    bodyDefX1.angle = 0.f;
    b2Body *bodyX1 = m_world->CreateBody(&bodyDefX1);
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBoxX1;
    dynamicBoxX1.SetAsBox(.5f,.2f);
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDefX1;
    fixtureDefX1.shape = &dynamicBoxX1;
    fixtureDefX1.density = 100.f;
    fixtureDefX1.friction = 0.0f;
    fixtureDefX1.filter.maskBits = 1;
    bodyX1->CreateFixture(&fixtureDefX1);
    
    b2WeldJointDef jdX;
    jdX.frequencyHz = 0;
    jdX.dampingRatio = 0;
    jdX.Initialize(body,bodyX,body->GetPosition()+b2Vec2(3.3f,0.f));
    m_world->CreateJoint(&jdX);
    
    b2WeldJointDef jdX1;
    jdX1.frequencyHz = 0;
    jdX1.dampingRatio = 0;
    jdX1.Initialize(body,bodyX1,body->GetPosition()-b2Vec2(3.3f,0.f));
    m_world->CreateJoint(&jdX1);

    CGSize screenSize = [CCDirector sharedDirector].winSize;
    
    CCSprite *sprite = [CCSprite spriteWithFile:@"outer.png"];
    [self addChild:sprite z:zOrder+180];
    
    // +++ Add anchor body
    b2BodyDef anchorBodyDef;
    anchorBodyDef.position.Set((screenSize.width+180.f)/PTM_RATIO/2,(680.f)/PTM_RATIO); //center body on screen (screenSize.height)/PTM_RATIO
    anchorBody = m_world->CreateBody(&anchorBodyDef);
    
    b2BodyDef anchorBodyDef2;
    anchorBodyDef2.position.Set((screenSize.width-460.f)/PTM_RATIO/2,(680.f)/PTM_RATIO); //center body on screen (screenSize.height)/PTM_RATIO
    anchorBody2 = m_world->CreateBody(&anchorBodyDef2);
    
    ropeSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"rope.png" ];
    [self addChild:ropeSpriteSheet];
    
    vRopes = [[NSMutableArray alloc] init];
    vRopes2 = [[NSMutableArray alloc] init];
    
	// +++ Create box2d joint
	b2RopeJointDef jd;
	jd.bodyA=anchorBody; //define bodies
	jd.bodyB=bodyX;
	jd.localAnchorA = b2Vec2(0.0,0); //define anchors
	jd.localAnchorB = b2Vec2(0.0,0);
	jd.maxLength= (bodyX->GetPosition() - anchorBody->GetPosition()).Length(); //define max length of joint = current distance between bodies
	m_world->CreateJoint(&jd); //create joint
	// +++ Create VRope with two b2bodies and pointer to spritesheet
	VRope *newRope = [[VRope alloc] init:anchorBody body2:bodyX spriteSheet:ropeSpriteSheet];
	[vRopes addObject:newRope];
    
    // +++ Create box2d joint
	b2RopeJointDef jd2;
	jd2.bodyA=anchorBody2; //define bodies
	jd2.bodyB=bodyX1;
	jd2.localAnchorA = b2Vec2(0.0,0); //define anchors
	jd2.localAnchorB = b2Vec2(0.0,0);
	jd2.maxLength= (bodyX1->GetPosition() - anchorBody2->GetPosition()).Length(); //define max length of joint = current distance between bodies
	m_world->CreateJoint(&jd2); //create joint
	// +++ Create VRope with two b2bodies and pointer to spritesheet
	VRope *newRope2 = [[VRope alloc] init:anchorBody2 body2:bodyX1 spriteSheet:ropeSpriteSheet];
	[vRopes2 addObject:newRope2];
    
    b2BodyDef bodyDef2;
    bodyDef2.type = b2_dynamicBody;
    bodyDef2.position.Set((320.f)/PTM_RATIO, (230.f)/PTM_RATIO);
    bodyDef2.angle = 0.f;
    b2Body *body2 = m_world->CreateBody(&bodyDef);
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox2;
    dynamicBox2.SetAsBox(5.f,.2f);
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef2;
    fixtureDef2.shape = &dynamicBox2;
    fixtureDef2.density = 100.f;
    fixtureDef2.friction = 0.0f;
    fixtureDef2.filter.maskBits = 1;
    body2->CreateFixture(&fixtureDef2);
    jinggai2 = body2;
    
    b2DistanceJointDef djd;
    djd.bodyA = body;
    djd.bodyB = body2;
    djd.localAnchorA.Set(0.0f, 0.0f);
    djd.localAnchorB.Set(0.0f, 0.0f);
    b2Vec2 d = djd.bodyB->GetWorldPoint(djd.localAnchorB) - djd.bodyA->GetWorldPoint(djd.localAnchorA);
    djd.length = d.Length();
    m_world->CreateJoint(&djd);
    
//    b2RevoluteJointDef jointDef;
//    jointDef.Initialize(body, body2,(body->GetPosition()+body2->GetPosition())/2.f);
//    jointDef.lowerAngle = -10;// -90 degrees
//    jointDef.upperAngle = 10;// 45 degrees
//    jointDef.enableLimit = true;
//    jointDef.maxMotorTorque = 10.0f;
//    jointDef.motorSpeed = 0.6f;
//    jointDef.enableMotor = false;
//    m_world->CreateJoint(&jointDef);
    
    b2PrismaticJointDef jointDef;
    b2Vec2 worldAxis(1.0f, 0.0f);
    jointDef.Initialize(body,body2, (body->GetPosition()+body2->GetPosition())/2.f, worldAxis);
    jointDef.lowerTranslation = 0.0f;
    jointDef.upperTranslation = 0.0f;
    jointDef.enableLimit = true;
    jointDef.maxMotorForce = 1.0f;
    jointDef.motorSpeed = 0.0f;
    jointDef.enableMotor = true;
    m_world->CreateJoint(&jointDef);
    
//    b2WeldJointDef jd2;
//    jd2.frequencyHz = 0;
//    jd2.dampingRatio = 0;
//    jd2.Initialize(body,body2,body->GetPosition());
//    m_world->CreateJoint(&jd2);
    
//    b2RevoluteJointDef jointDef3;
//    jointDef3.bodyA = body;
//    jointDef3.bodyB = body2;
//    jointDef3.localAnchorA.Set(0,0);
//    jointDef3.localAnchorB.Set(0,0);
//    m_world->CreateJoint(&jointDef3);
    
    //another revolute joint to connect the chain to the circle
    b2RevoluteJointDef revoluteJointDef;
    revoluteJointDef.bodyA = body;//the last added link of the chain
    revoluteJointDef.bodyB = body2;
    revoluteJointDef.localAnchorA = body->GetPosition();//the regular position for chain link joints, as above
    revoluteJointDef.localAnchorB= b2Vec2(body->GetPosition().x,body->GetPosition().y+4.2f);//a little in from the edge of the circle
    
    revoluteJointDef.collideConnected = false;
    revoluteJointDef.enableMotor = false;
    revoluteJointDef.maxMotorTorque = 0;
    revoluteJointDef.motorSpeed =  0.f * PI/180.f;//90 degrees per second
    revoluteJointDef.referenceAngle = 0;
    
    revoluteJointDef.enableLimit = false;
    revoluteJointDef.lowerAngle = 0.f * PI/180.f;// * PI/180.f;
    revoluteJointDef.upperAngle = 0.f * PI/180.f;// * PI/180.f;
    
    m_world->CreateJoint(&revoluteJointDef);
    
    
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
    // +++ Update rope sprites
	for(uint i=0;i<[vRopes count];i++)
    {
		[[vRopes objectAtIndex:i] updateSprites];
	}
    
    for(uint i=0;i<[vRopes2 count];i++)
    {
		[[vRopes2 objectAtIndex:i] updateSprites];
	}
    
    [super draw];

}

-(void)dealloc
{
    [self removeRopes];
    if(vRopes != nil)
    {
        [vRopes release];
        vRopes = nil;
    }
    if(anchorBody != NULL)
    {
        m_world -> DestroyBody(anchorBody);
        anchorBody = NULL;
    }
    
    [super dealloc];
    
}

-(void)addMap
{
    b2BodyDef bd;
    bd.type = b2_staticBody;
    b2Body* ground = m_world->CreateBody(&bd);
    vertsNum = 12;
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
    
//    verts[0].Set((640-616.0f) / PTM_RATIO, (360+10.0f) / PTM_RATIO);
//    verts[1].Set((640-384.0f) / PTM_RATIO, (360+11.0f) / PTM_RATIO);
//    verts[2].Set((640-386.0f) / PTM_RATIO, (360-44.0f) / PTM_RATIO);
//    verts[3].Set((640-423.0f) / PTM_RATIO, (360-40.0f) / PTM_RATIO);
//    verts[4].Set((640-403.0f) / PTM_RATIO, (360-290.0f) / PTM_RATIO);
//    verts[5].Set((640+13.0f) / PTM_RATIO, (360-289.0f) / PTM_RATIO);
//    verts[6].Set((640-12.0f) / PTM_RATIO, (360-50.0f) / PTM_RATIO);
//    verts[7].Set((640-162.0f) / PTM_RATIO, (360-46.0f) / PTM_RATIO);
//    verts[8].Set((640-173.0f) / PTM_RATIO, (360+24.0f) / PTM_RATIO);
//    verts[9].Set((640+621.0f) / PTM_RATIO, (360+14.0f) / PTM_RATIO);
//    verts[10].Set((640+620.0f) / PTM_RATIO, (360-353.0f) / PTM_RATIO);
//    verts[11].Set((640-627.0f) / PTM_RATIO, (360-354.0f) / PTM_RATIO);
    
//    verts[0].Set((640+135.0f+50.f) / PTM_RATIO, (360-141.0f) / PTM_RATIO);
//    verts[1].Set((640+164.0f+50.f) / PTM_RATIO, (360-238.0f) / PTM_RATIO);
//    verts[2].Set((640+132.0f+50.f) / PTM_RATIO, (360-327.0f) / PTM_RATIO);
//    verts[3].Set((640+386.0f+50.f) / PTM_RATIO, (360-328.0f) / PTM_RATIO);
//    verts[4].Set((640+333.0f+50.f) / PTM_RATIO, (360-243.0f) / PTM_RATIO);
//    verts[5].Set((640+348.0f+50.f) / PTM_RATIO, (360-128.0f) / PTM_RATIO);
//    verts[6].Set((640+628.0f+50.f) / PTM_RATIO, (360-126.0f) / PTM_RATIO);
//    verts[7].Set((640+631.0f+50.f) / PTM_RATIO, (360-357.0f) / PTM_RATIO);
//    verts[8].Set((640+100.0f+50.f) / PTM_RATIO, (360-353.0f) / PTM_RATIO);
//    verts[9].Set((640+111.0f+50.f) / PTM_RATIO, (360-213.0f) / PTM_RATIO);
//    verts[10].Set((640+97.0f+50.f) / PTM_RATIO, (360-69.0f) / PTM_RATIO);
//    verts[11].Set((640+96.0f+50.f) / PTM_RATIO, (360+19.0f) / PTM_RATIO);
//    verts[12].Set((640+139.0f+50.f) / PTM_RATIO, (360-42.0f) / PTM_RATIO);
    
    verts[0].Set((640+332.0f) / PTM_RATIO, (360-76.0f) / PTM_RATIO);
    verts[1].Set((640+295.0f) / PTM_RATIO, (360-189.0f) / PTM_RATIO);
    verts[2].Set((640+378.0f) / PTM_RATIO, (360-271.0f) / PTM_RATIO);
    verts[3].Set((640+499.0f) / PTM_RATIO, (360-251.0f) / PTM_RATIO);
    verts[4].Set((640+536.0f) / PTM_RATIO, (360-258.0f) / PTM_RATIO);
    verts[5].Set((640+564.0f) / PTM_RATIO, (360-165.0f) / PTM_RATIO);
    verts[6].Set((640+558.0f) / PTM_RATIO, (360-58.0f) / PTM_RATIO);
    verts[7].Set((640+632.0f) / PTM_RATIO, (360-88.0f) / PTM_RATIO);
    verts[8].Set((640+622.0f) / PTM_RATIO, (360-337.0f) / PTM_RATIO);
    verts[9].Set((640+308.0f) / PTM_RATIO, (360-334.0f) / PTM_RATIO);
    verts[10].Set((640+260.0f) / PTM_RATIO, (360-163.0f) / PTM_RATIO);
    verts[11].Set((640+295.0f) / PTM_RATIO, (360-77.0f) / PTM_RATIO);


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
    vertsNum1 = 4;
    verts1 = (b2Vec2 *)malloc (vertsNum1 * sizeof (b2Vec2));
    
    verts1[0].Set((640.f-579.0f) / PTM_RATIO, (360.f+189.0f) / PTM_RATIO);
    verts1[1].Set((640.f+337.0f) / PTM_RATIO, (360.f+189.0f) / PTM_RATIO);
    verts1[2].Set((640.f+376.0f) / PTM_RATIO, (360.f+24.0f) / PTM_RATIO);
    verts1[3].Set((640.f-563.0f) / PTM_RATIO, (360.f+42.0f) / PTM_RATIO);
    
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
    
    shape.Set(verts1[vertsNum1-1], verts1[0]);
    shape.m_hasVertex0 = true;
    shape.m_vertex0 = verts1[vertsNum1-2];
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
    
    // +++ Update rope physics
	for(uint i=0;i<[vRopes count];i++)
    {
		[(VRope *)[vRopes objectAtIndex:i] update:dt];
	}
    for(uint i=0;i<[vRopes2 count];i++)
    {
		[(VRope *)[vRopes2 objectAtIndex:i] update:dt];
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
