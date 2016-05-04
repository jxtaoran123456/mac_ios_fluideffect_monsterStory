//
//  SPHNode.m
//  SPH
//
//  Created by Vasiliy Yanushevich on 11/2/12.
//  Copyright 2012 Vasiliy Yanushevich. All rights reserved.
//

#import "SPHNode.h"
#import "testLv20.h"

#include <GLUT/GLUT.h>
#include <OpenGL/glu.h>


@implementation testLv20

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	testLv20 *layer = [testLv20 node];
	
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
        shushuiPs = ccp(-100,750);//ccp(-60,750);
        
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
    awakePraticles(nParticles,b2Vec2(shushuiPs.x,shushuiPs.y),10,-6.f,b2Vec2(0.f,-10.f),30.f,0,false);
    
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
    [self addSingleMap];
	
    // Particles
    initFluidPraticles(0.9f,0.008f,100.f,30.f,2000,@"fire_010.png",nil);// VbmyR.png fire2 drop2
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
    dynamicBox3.SetAsBox(8.f,0.65f);//(12.f,1.65f);
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef3;
    fixtureDef3.shape = &dynamicBox3;
    fixtureDef3.density = 1.f;
    fixtureDef3.friction = 0.0f;
    body3->CreateFixture(&fixtureDef3);
    
    b2BodyDef bodyDef4;
    bodyDef4.type = b2_staticBody;
    bodyDef4.position.Set((shushuiPs.x-90-160.f)/PTM_RATIO, (shushuiPs.y-40.f+320.f)/PTM_RATIO);//((shushuiPs.x-90-280.f)/PTM_RATIO, (shushuiPs.y-40.f+420.f)/PTM_RATIO);
    bodyDef4.angle = 0;
    b2Body *body4 = m_world->CreateBody(&bodyDef4);
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox4;
    dynamicBox4.SetAsBox(0.65f,8.5f);//(1.65f,10.5f);
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef4;
    fixtureDef4.shape = &dynamicBox4;
    fixtureDef4.density = 1.f;
    fixtureDef4.friction = 0.0f;
    body4->CreateFixture(&fixtureDef4);
    
//    b2BodyDef bodyDef7;
//    bodyDef7.type = b2_staticBody;
//    bodyDef7.position.Set((shushuiPs.x+180)/PTM_RATIO, (shushuiPs.y-40.f+420.f)/PTM_RATIO);
//    bodyDef7.angle = 0;
//    b2Body *body7 = m_world->CreateBody(&bodyDef7);
//    // Define another box shape for our dynamic body.
//    b2PolygonShape dynamicBox7;
//    dynamicBox7.SetAsBox(1.65f,18.f);
//    // Define the dynamic body fixture.
//    b2FixtureDef fixtureDef7;
//    fixtureDef7.shape = &dynamicBox7;
//    fixtureDef7.density = 1.f;
//    fixtureDef7.friction = 0.0f;
//    body7->CreateFixture(&fixtureDef7);
//    mov = body7;
    
    b2BodyDef bodyDef5;
    bodyDef5.type = b2_dynamicBody;
    bodyDef5.position.Set((640.f+280.0f) / PTM_RATIO, (360.f+100.0f) / PTM_RATIO);
    bodyDef5.angle = 0;
    b2Body *body5 = m_world->CreateBody(&bodyDef5);
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox5;
    dynamicBox5.SetAsBox(0.35f,0.35f);
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef5;
    fixtureDef5.shape = &dynamicBox5;
    fixtureDef5.density = 30.f;
    fixtureDef5.friction = 0.4f;
    body5->CreateFixture(&fixtureDef5);
    body5->toolsType = 1104;
    touch = body5;
    
    b2BodyDef bodyDef6;
    bodyDef6.type = b2_staticBody;
    bodyDef6.position.Set((630.f) / PTM_RATIO, (360.f-100.f) / PTM_RATIO);
    bodyDef6.angle = 0;
    b2Body *body6 = m_world->CreateBody(&bodyDef6);
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox6;
    dynamicBox6.SetAsBox(4.35f,0.35f);
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef6;
    fixtureDef6.shape = &dynamicBox6;
    fixtureDef6.density = 30.f;
    fixtureDef6.friction = 0.4f;
    body6->CreateFixture(&fixtureDef6);
    gedang = body6;
    
//    singleVers[3].vec1.Set((640.f+251.0f) / PTM_RATIO, (360.f+75.7f) / PTM_RATIO);
//    singleVers[3].vec2.Set((640.0f+392.4f) / PTM_RATIO, (360.f+77.1f) / PTM_RATIO);

}

-(void)createGears
{
    b2PulleyJoint* m_joint1;
    {
		float32 y = 0.f;//16.0f;
		float32 L = 18.f;//12.0f;
		float32 a = 1.0f;
		float32 b = 2.0f;
        
		b2Body* ground = NULL;
		{
			b2BodyDef bd;
			ground = m_world->CreateBody(&bd);
            
			b2EdgeShape edge;
			edge.Set(b2Vec2(-40.0f, -20.0f), b2Vec2(40.0f, -20.0f));
			//ground->CreateFixture(&shape, 0.0f);
            
			b2CircleShape circle;
			circle.m_radius = 2.0f;
            
			circle.m_p.Set(2.0f, y + b + L);
			ground->CreateFixture(&circle, 0.0f);
            
			circle.m_p.Set(22.0f, y + b + L);
			ground->CreateFixture(&circle, 0.0f);
		}
        
		{
			b2PolygonShape shape;
			shape.SetAsBox(a, b);
            
			b2BodyDef bd;
			bd.type = b2_dynamicBody;
            
			//bd.fixedRotation = true;
			bd.position.Set(-10.0f, y);
			b2Body* body1 = m_world->CreateBody(&bd);
			body1->CreateFixture(&shape, 10.0f);
            
			bd.position.Set(23.0f, y+14.f);
			b2Body* body2 = m_world->CreateBody(&bd);
			body2->CreateFixture(&shape, 5.0f);
            
			b2PulleyJointDef pulleyDef;
			b2Vec2 anchor1(-10.0f, y + b);
			b2Vec2 anchor2(10.0f, y + b);
			b2Vec2 groundAnchor1(-10.0f, y + b + L);
			b2Vec2 groundAnchor2(10.0f, y + b + L);
			pulleyDef.Initialize(body1, body2, groundAnchor1, groundAnchor2, anchor1, anchor2, 1.5f);
            
			m_joint1 = (b2PulleyJoint*)m_world->CreateJoint(&pulleyDef);
		}
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
        awakePraticles(nParticles,b2Vec2(shushuiPs.x,shushuiPs.y),10,-10.f,b2Vec2(0.f,-10.f),30.f,0,false);
        //mov->SetTransform(b2Vec2(mov->GetPosition().x,mov->GetPosition().y+4.f), mov->GetAngle());
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

//碰撞事件处理
-(void)collisionHandle:(b2Body*)body index:(int)fluidPraticleIndex
{
    if(body->toolsType == 1104)
    {
        if(gedang->GetPosition().x*PTM_RATIO > 400.f)
        {
            gedang->SetTransform(b2Vec2(gedang->GetPosition().x-0.01f,gedang->GetPosition().y), gedang->GetAngle());
        }
    }
    
}

-(void) draw
{

    
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
    vertsNum = 14;
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
    
    verts[0].Set((640-87.0f) / PTM_RATIO, (360-102.5f) / PTM_RATIO);
    verts[1].Set((640-242.5f) / PTM_RATIO, (360-152.0f) / PTM_RATIO);
    verts[2].Set((640-153.4f) / PTM_RATIO, (360-232.6f) / PTM_RATIO);
    verts[3].Set((640-246.8f) / PTM_RATIO, (360-283.5f) / PTM_RATIO);
    verts[4].Set((640-210.0f) / PTM_RATIO, (360-350.0f) / PTM_RATIO);
    verts[5].Set((640+153.4f) / PTM_RATIO, (360-350.0f) / PTM_RATIO);
    verts[6].Set((640+116.7f) / PTM_RATIO, (360-252.4f) / PTM_RATIO);
    verts[7].Set((640+78.5f) / PTM_RATIO, (360-118.1f) / PTM_RATIO);
    verts[8].Set((640+150.6f) / PTM_RATIO, (360-101.1f) / PTM_RATIO);
    verts[9].Set((640+178.9f) / PTM_RATIO, (360-351.4f) / PTM_RATIO);
    verts[10].Set((640-251.0f) / PTM_RATIO, (360-354.3f) / PTM_RATIO);
    verts[11].Set((640-277.9f) / PTM_RATIO, (360-273.7f) / PTM_RATIO);
    verts[12].Set((640-294.9f) / PTM_RATIO, (360-156.3f) / PTM_RATIO);
    verts[13].Set((640-224.2f) / PTM_RATIO, (360-74.2f) / PTM_RATIO);

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
    
//    singleVers[0].vec1.Set((640.f-634.0f) / PTM_RATIO, (360.f+225.0f) / PTM_RATIO);
//    singleVers[0].vec2.Set((640.f-103.0f) / PTM_RATIO, (360.f+225.0f) / PTM_RATIO);
//
//    singleVers[1].vec1.Set((640.f+360.0f) / PTM_RATIO, (360.f+109.0f) / PTM_RATIO);
//    singleVers[1].vec2.Set((640.f+580.0f) / PTM_RATIO, (360.f+112.0f) / PTM_RATIO);
//    
//    singleVers[2].vec1.Set((640.f+580.0f) / PTM_RATIO, (360.f+112.0f) / PTM_RATIO);
//    singleVers[2].vec2.Set((587.0f+640.f) / PTM_RATIO, (360.f+30.0f) / PTM_RATIO);
    
    singleVers[0].vec1.Set((640.f-499.9f) / PTM_RATIO, (360.f+167.6f) / PTM_RATIO);
    singleVers[0].vec2.Set((640.f-384.0f) / PTM_RATIO, (360.f+167.6f) / PTM_RATIO);
    
    singleVers[1].vec1.Set((640.f-287.8f) / PTM_RATIO, (360.f+60.1f) / PTM_RATIO);
    singleVers[1].vec2.Set((640.f-145.0f) / PTM_RATIO, (360.f+58.7f) / PTM_RATIO);
    
//    singleVers[2].vec1.Set((640.f-21.9f) / PTM_RATIO, (360.f-105.4f) / PTM_RATIO);
//    singleVers[2].vec2.Set((587.0f+133.6f) / PTM_RATIO, (360.f-102.5f) / PTM_RATIO);
    
    singleVers[2].vec1.Set((640.f+251.0f) / PTM_RATIO, (360.f+77.1f) / PTM_RATIO);
    singleVers[2].vec2.Set((640.0f+392.4f) / PTM_RATIO, (360.f+77.1f) / PTM_RATIO);

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
            awakePraticles(nParticles,b2Vec2(shushuiPs.x,shushuiPs.y),40,60.f,b2Vec2(0.f,-10.f),0.f,0,true);
        }
    }
    CGPoint touchPs;
    if(touch != nil)
    {
        touchPs = ccp(touch->GetPosition().x*PTM_RATIO,touch->GetPosition().y*PTM_RATIO);
    }
    if((touchPs.x > 950 && touchPs.y > 440) && (touchPs.x < 1050 && touchPs.y < 460 ) && (gedang->GetPosition().x*PTM_RATIO < 780))
    {
        gedang->SetTransform(b2Vec2(gedang->GetPosition().x+0.03,gedang->GetPosition().y), 0);
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
