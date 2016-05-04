//
//  SPHNode.m
//  SPH
//
//  Created by Vasiliy Yanushevich on 11/2/12.
//  Copyright 2012 Vasiliy Yanushevich. All rights reserved.
//

#import "SPHNode.h"
#import "testLv5.h"

#include <GLUT/GLUT.h>
#include <OpenGL/glu.h>


@implementation testLv5

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	testLv5 *layer = [testLv5 node];
	
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
        shushuiPs = ccp(-10,700);
        
        [self createStaticGeometry];

        intersectQueryCallback = new QueryWorldInteractions(hashGridList, liquid);
        eulerIntersectQueryCallback = new QueryWorldPostIntersect(hashGridList, liquid);
        
        //back back1 fluid tree back2
        backgroundSprite = [CCSprite spriteWithFile:@"lv3_back.png"];//testLevel1.png testLevel3 3_1.png lv3_back.png
        backgroundSprite.anchorPoint = ccp(0,0);
        backgroundSprite.position = ccp(0,0);//(72,40);
        [self addChild:backgroundSprite z:zOrder+1];
        
//        backgroundSprite1 = [CCSprite spriteWithFile:@"lv3_back1.png"];//testLevel1.png testLevel3
//        backgroundSprite1.anchorPoint = ccp(0,0);
//        backgroundSprite1.position = ccp(0,0);
//        [self addChild:backgroundSprite1 z:zOrder+1];
        
//        tree = [CCSprite spriteWithFile:@"lv3_tree.png"];//testLevel1.png testLevel3
//        tree.anchorPoint = ccp(0,0);
//        tree.position = ccp(0,0);
//        [self addChild:tree z:zOrder+15];
        
//        backgroundSprite2 = [CCSprite spriteWithFile:@"lv3_back2.png"];//testLevel1.png testLevel3
//        backgroundSprite2.anchorPoint = ccp(0,0);
//        backgroundSprite2.position = ccp(0,0);
//        [self addChild:backgroundSprite2 z:zOrder+16];
        
        [rippleSprArr addObject:backgroundSprite];
        [backgroundSprite release];

//        [rippleSprArr addObject:backgroundSprite1];
//        [backgroundSprite1 release];
        
        [self initMenu2];
        
//        unusedSection1[0] = b2Vec2(singleVers[0].vec1.x,singleVers[0].vec1.y);
//        unusedSection1[1] = b2Vec2(singleVers[1].vec2.x,singleVers[1].vec2.y);
//        unusedSection1[2] = b2Vec2(singleVers[3].vec2.x,singleVers[3].vec2.y);
//        unusedSection1[3] = b2Vec2(singleVers[2].vec1.x,singleVers[2].vec1.y);
        
//        unusedSection1[0].Set((640.f-318.9f) / PTM_RATIO, (360+195.9f) / PTM_RATIO);
//        unusedSection1[1].Set((640.f+355.7f) / PTM_RATIO, (360+6.4f) / PTM_RATIO);
//        unusedSection1[2].Set((640.f+307.6f) / PTM_RATIO, (360-102.5f) / PTM_RATIO);
//        unusedSection1[3].Set((640.f-395.3f) / PTM_RATIO, (360+53.0f) / PTM_RATIO);
        
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
    //awakePraticles(100,b2Vec2(280,320),10,-6.f,b2Vec2(0.f,-10.f),30.f,0,true);
    
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
    initFluidPraticles(0.9f,0.015f,250.f,30.f,2000,@"fire_010.png",nil);// VbmyR.png fire2 drop2
    //added by tr 2013-08-08
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_kinematicBody;
    bodyDef.position.Set(665.f/PTM_RATIO, 280.f/PTM_RATIO);
    b2Body *body = m_world->CreateBody(&bodyDef);
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox;
    dynamicBox.SetAsBox(4.f,1.35f);
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &dynamicBox;
    fixtureDef.density = 1.f;
    fixtureDef.friction = 0.0f;
    body->CreateFixture(&fixtureDef);
    geDang = body;
    
    b2BodyDef bodyDef2;
    bodyDef2.type = b2_kinematicBody;
    bodyDef2.position.Set(770.f/PTM_RATIO, 180.f/PTM_RATIO);
    b2Body *body2 = m_world->CreateBody(&bodyDef2);
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox2;
    dynamicBox2.SetAsBox(.4f,.4f);
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef2;
    fixtureDef2.shape = &dynamicBox2;
    fixtureDef2.density = 1.f;
    fixtureDef2.friction = 0.0f;
    body2->CreateFixture(&fixtureDef2);
    body2->toolsType = 1001;
    touch1 = body2;
    
    b2BodyDef bodyDef3;
    bodyDef3.type = b2_kinematicBody;
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
    bodyDef4.type = b2_kinematicBody;
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
        //awakePraticles(100,b2Vec2(280,320),10,-6.f,b2Vec2(0.f,-10.f),30.f,0,true);
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
            //[releaseFluidBt setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"r1.png"]];
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
    if(body->toolsType == 1001)
    {
        if(geDang->GetPosition().y <= 22)
        {
            geDang->SetTransform(b2Vec2(geDang->GetPosition().x,(geDang->GetPosition().y+0.01f)), geDang->GetAngle());
        }
    }
 
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
//    for (int i = 0; i < nParticles; ++i)
//	{
//        glPointSize(1);
//        ccDrawPoint(ccp(liquid[i].mPosition.x*32,liquid[i].mPosition.y*32));
//    }

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
    vertsNum = 10;
    verts = (b2Vec2 *)malloc (vertsNum * sizeof (b2Vec2));
    
//    verts[0].Set((640.f-637.0f) / PTM_RATIO, 0.f/ PTM_RATIO);
//    verts[1].Set((640.f-637.0f) / PTM_RATIO, (360.f+33.0f) / PTM_RATIO);
//    verts[2].Set((640.f-531.0f) / PTM_RATIO, (360.f+34.0f) / PTM_RATIO);
//    verts[3].Set((640.f-308.0f) / PTM_RATIO, (360.f+4.0f) / PTM_RATIO);
//    verts[4].Set((640.f-277.0f) / PTM_RATIO, (360.f-99.0f) / PTM_RATIO);
//    verts[5].Set((640.f-278.0f) / PTM_RATIO, (360.f-131.0f) / PTM_RATIO);
//    verts[6].Set((640.f-224.0f) / PTM_RATIO, (360.f-201.0f) / PTM_RATIO);
//    verts[7].Set((640.f-235.0f) / PTM_RATIO, (360.f-260.0f) / PTM_RATIO);
//    verts[8].Set((640.f-214.0f) / PTM_RATIO, (360.f-319.0f) / PTM_RATIO);
//    verts[9].Set((640.f+228.0f) / PTM_RATIO, (360.f-313.0f) / PTM_RATIO);
//    verts[10].Set((640.f+273.0f) / PTM_RATIO, (360.f-211.0f) / PTM_RATIO);
//    verts[11].Set((640.f+335.0f) / PTM_RATIO, (360.f-101.0f) / PTM_RATIO);
//    verts[12].Set((640.f+637.0f) / PTM_RATIO, (360.f-97.0f) / PTM_RATIO);
//    verts[13].Set((640.f+637.0f) / PTM_RATIO,0.f / PTM_RATIO);
    
//    verts[0].Set((640.f-636.0f) / PTM_RATIO, 0.0f / PTM_RATIO);
//    verts[1].Set((640.f-636.0f) / PTM_RATIO, (360.f+69.0f) / PTM_RATIO);
//    verts[2].Set((640.f-348.0f) / PTM_RATIO, (360.f+68.0f) / PTM_RATIO);
//    verts[3].Set((640.f-302.0f) / PTM_RATIO, (360.f-334.0f) / PTM_RATIO);
//    verts[4].Set((640.f+269.0f) / PTM_RATIO, (360.f-326.0f) / PTM_RATIO);
//    verts[5].Set((640.f+304.0f) / PTM_RATIO, (360.f-104.0f) / PTM_RATIO);
//    verts[6].Set((640.f+640.0f) / PTM_RATIO, (360.f-104.0f) / PTM_RATIO);
//    verts[7].Set((640.f+640.0f) / PTM_RATIO, 0.0f / PTM_RATIO);
    
    
//    verts[0].Set((640.f+130.8f) / PTM_RATIO, (360.f-85.6f) / PTM_RATIO);
//    verts[1].Set((640.f-78.5f) / PTM_RATIO, (360.f-40.3f) / PTM_RATIO);
//    verts[2].Set((640.f-30.4f) / PTM_RATIO, (360.f+265.2f) / PTM_RATIO);
//    verts[3].Set((640.f+432.0f) / PTM_RATIO, (360.f+245.4f) / PTM_RATIO);
//    verts[4].Set((640.f+480.1f) / PTM_RATIO, (360.f-318.9f) / PTM_RATIO);
//    verts[5].Set((640.f+197.3f) / PTM_RATIO, (360.f-316.1f) / PTM_RATIO);
//    verts[6].Set((640.f+198.7f) / PTM_RATIO, (360.f-198.7f) / PTM_RATIO);
//    verts[7].Set((640.f+173.2f) / PTM_RATIO, (360.f-72.8f) / PTM_RATIO);
//    verts[8].Set((640.f+342.9f) / PTM_RATIO, (360.f-64.3f) / PTM_RATIO);
//    verts[9].Set((640.f+317.5f) / PTM_RATIO, (360.f+108.2f) / PTM_RATIO);
//    verts[10].Set((640.f+72.8f) / PTM_RATIO, (360.f+126.6f) / PTM_RATIO);
//    verts[11].Set((640.f+94.0f) / PTM_RATIO, (360.f+14.8f) / PTM_RATIO);
    
//    verts[0].Set((640.f+118.0f) / PTM_RATIO, (360.f-74.0f) / PTM_RATIO);
//    verts[1].Set((640.f+26.0f) / PTM_RATIO, (360.f-73.0f) / PTM_RATIO);
//    verts[2].Set((640.f-62.0f) / PTM_RATIO, (360.f-41.0f) / PTM_RATIO);
//    verts[3].Set((640.f-72.0f) / PTM_RATIO, (360.f+51.0f) / PTM_RATIO);
//    verts[4].Set((640.f-22.0f) / PTM_RATIO, (360.f+261.0f) / PTM_RATIO);
//    verts[5].Set((640.f+254.0f) / PTM_RATIO, (360.f+276.0f) / PTM_RATIO);
//    verts[6].Set((640.f+427.0f) / PTM_RATIO, (360.f+241.0f) / PTM_RATIO);
//    verts[7].Set((640.f+479.0f) / PTM_RATIO, (360.f-317.0f) / PTM_RATIO);
//    verts[8].Set((640.f+213.0f) / PTM_RATIO, (360.f-317.0f) / PTM_RATIO);
//    verts[9].Set((640.f+213.0f) / PTM_RATIO, (360.f-244.0f) / PTM_RATIO);
//    verts[10].Set((640.f+184.0f) / PTM_RATIO, (360.f-80.0f) / PTM_RATIO);
//    verts[11].Set((640.f+347.0f) / PTM_RATIO, (360.f-69.0f) / PTM_RATIO);
//    verts[12].Set((640.f+329.0f) / PTM_RATIO, (360.f+111.0f) / PTM_RATIO);
//    verts[13].Set((640.f+293.0f) / PTM_RATIO, (360.f+128.0f) / PTM_RATIO);
//    verts[14].Set((640.f+66.0f) / PTM_RATIO, (360.f+126.0f) / PTM_RATIO);
    
//    verts[0].Set((640.f-638.0f) / PTM_RATIO, (360.f+171.0f) / PTM_RATIO);
//    verts[1].Set((640.f-638.0f) / PTM_RATIO, (360.f+356.0f) / PTM_RATIO);
//    verts[2].Set((640.f-305.0f) / PTM_RATIO, (360.f+356.0f) / PTM_RATIO);
//    verts[3].Set((640.f-306.0f) / PTM_RATIO, (360.f+31.0f) / PTM_RATIO);
//    verts[4].Set((640.f-269.0f) / PTM_RATIO, (360.f-20.0f) / PTM_RATIO);
//    verts[5].Set((640.f-202.0f) / PTM_RATIO, (360.f-18.0f) / PTM_RATIO);
//    verts[6].Set((640.f-181.0f) / PTM_RATIO, (360.f+29.0f) / PTM_RATIO);
//    verts[7].Set((640.f-164.0f) / PTM_RATIO, (360.f+357.0f) / PTM_RATIO);
//    verts[8].Set((640.f+635.0f) / PTM_RATIO, (360.f+354.0f) / PTM_RATIO);
//    verts[9].Set((640.f+634.0f) / PTM_RATIO, (360.f+85.0f) / PTM_RATIO);
//    verts[10].Set((640.f+297.0f) / PTM_RATIO, (360.f+100.0f) / PTM_RATIO);
//    verts[11].Set((640.f+255.0f) / PTM_RATIO, (360.f+256.0f) / PTM_RATIO);
//    verts[12].Set((640.f+198.0f) / PTM_RATIO, (360.f+287.0f) / PTM_RATIO);
//    verts[13].Set((640.f+70.0f) / PTM_RATIO, (360.f+291.0f) / PTM_RATIO);
//    verts[14].Set((640.f+97.0f) / PTM_RATIO, (360.f-130.0f) / PTM_RATIO);
//    verts[15].Set((640.f+612.0f) / PTM_RATIO, (360.f-154.0f) / PTM_RATIO);
//    verts[16].Set((640.f+633.0f) / PTM_RATIO, (360.f-331.0f) / PTM_RATIO);
//    verts[17].Set((640.f-630.0f) / PTM_RATIO, (360.f-325.0f) / PTM_RATIO);
//    verts[18].Set((640.f-539.0f) / PTM_RATIO, (360.f+178.0f) / PTM_RATIO);
    
//    verts[0].Set(-300.f / PTM_RATIO, (360.f+187.0f) / PTM_RATIO);
//    verts[1].Set(-300.f / PTM_RATIO, (1360.f+356.0f) / PTM_RATIO);
//    verts[2].Set((640.f-337.0f) / PTM_RATIO, (1360.f+360.0f) / PTM_RATIO);
//    verts[3].Set((640.f-260.0f) / PTM_RATIO, (360.f-134.0f) / PTM_RATIO);
//    verts[4].Set((640.f-168.0f) / PTM_RATIO, (360.f-186.0f) / PTM_RATIO);
//    verts[5].Set((640.f-76.0f) / PTM_RATIO, (360.f-182.0f) / PTM_RATIO);
//    verts[6].Set((640.f-21.0f) / PTM_RATIO, (360.f-142.0f) / PTM_RATIO);
//    verts[7].Set((640.f+20.0f) / PTM_RATIO, (1360.f+354.0f) / PTM_RATIO);
//    verts[8].Set((640.f+630.0f) / PTM_RATIO, (1360.f+349.0f) / PTM_RATIO);
//    verts[9].Set((640.f+634.0f) / PTM_RATIO, (360.f-22.0f) / PTM_RATIO);
//    verts[10].Set((640.f+382.0f) / PTM_RATIO, (360.f+3.0f) / PTM_RATIO);
//    verts[11].Set((640.f+317.0f) / PTM_RATIO, (360.f+178.0f) / PTM_RATIO);
//    verts[12].Set((640.f+225.0f) / PTM_RATIO, (360.f+265.0f) / PTM_RATIO);
//    verts[13].Set((640.f+130.0f) / PTM_RATIO, (360.f+254.0f) / PTM_RATIO);
//    verts[14].Set((640.f+134.0f) / PTM_RATIO, (360.f-201.0f) / PTM_RATIO);
//    verts[15].Set((640.f+637.0f) / PTM_RATIO, (360.f-241.0f) / PTM_RATIO);
//    verts[16].Set((640.f+630.0f) / PTM_RATIO, (360.f-346.0f) / PTM_RATIO);
//    verts[17].Set((640.f-490.0f) / PTM_RATIO, (360.f-331.0f) / PTM_RATIO);
//    verts[18].Set((640.f-527.0f) / PTM_RATIO, (360.f+181.0f) / PTM_RATIO);
    

    verts[0].Set((640.f-31.0f) / PTM_RATIO, (360.f-354.0f) / PTM_RATIO);
    verts[1].Set((640.f-16.0f) / PTM_RATIO, (360.f-215.0f) / PTM_RATIO);
    verts[2].Set((640.f+140.0f) / PTM_RATIO, (360.f-207.0f) / PTM_RATIO);
    verts[3].Set((640.f+157.0f) / PTM_RATIO, (360.f+159.0f) / PTM_RATIO);
    verts[4].Set((640.f+310.0f) / PTM_RATIO, (360.f+158.0f) / PTM_RATIO);
    verts[5].Set((640.f+320.0f) / PTM_RATIO, (360.f-58.0f) / PTM_RATIO);
    
    
    
    verts[6].Set((640.f+584.0f) / PTM_RATIO, (360.f-62.0f) / PTM_RATIO);
    verts[7].Set((640.f+584.0f) / PTM_RATIO, (360.f+360.0f) / PTM_RATIO);
    verts[8].Set((640.f+634.0f) / PTM_RATIO, (360.f+360.0f) / PTM_RATIO);
    
    
    
    
    //verts[6].Set((640.f+634.0f) / PTM_RATIO, (360.f-62.0f) / PTM_RATIO);
    verts[9].Set((640.f+636.0f) / PTM_RATIO, (360.f-353.0f) / PTM_RATIO);
    
    
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
    singleVerNum = 5;
    singleVers = (singleVec *)malloc (singleVerNum * sizeof (singleVec));
    
//    singleVers[0].vec1.Set((640.f-329.0f) / PTM_RATIO, (360.f+242.0f) / PTM_RATIO);
//    singleVers[0].vec2.Set((640.f-38.0f) / PTM_RATIO, (360.f+163.0f) / PTM_RATIO);
//    
//    singleVers[1].vec1.Set((640.f+110.0f) / PTM_RATIO, (360.f+128.0f) / PTM_RATIO);
//    singleVers[1].vec2.Set((640.f+336.0f) / PTM_RATIO, (360.f+77.0f) / PTM_RATIO);
//    
//    singleVers[2].vec1.Set((640.f-358.0f) / PTM_RATIO, (360.f+30.0f) / PTM_RATIO);
//    singleVers[2].vec2.Set((640.f-285.0f) / PTM_RATIO, (360.f+46.0f) / PTM_RATIO);
//    
//    singleVers[3].vec1.Set((640.f-157.0f) / PTM_RATIO, (360.f+33.0f) / PTM_RATIO);
//    singleVers[3].vec2.Set((640.f+300.0f) / PTM_RATIO, (360.f-53.0f) / PTM_RATIO);
    
//    singleVers[0].vec1.Set((640.f-368.0f) / PTM_RATIO, (360.f+162.0f) / PTM_RATIO);
//    singleVers[0].vec2.Set((640.f-79.0f) / PTM_RATIO, (360.f+104.0f) / PTM_RATIO);
//    
//    singleVers[1].vec1.Set((640.f+79.0f) / PTM_RATIO, (360.f+71.0f) / PTM_RATIO);
//    singleVers[1].vec2.Set((640.f+349.0f) / PTM_RATIO, (360.f+2.0f) / PTM_RATIO);
    
    
//    
//    singleVers[2].vec1.Set((640.f-162.0f) / PTM_RATIO, (360.f+20.0f) / PTM_RATIO);
//    singleVers[2].vec2.Set((640.f+324.0f) / PTM_RATIO, (360.f-75.0f) / PTM_RATIO);
    
//    singleVers[0].vec1.Set((640.f-349.0f ) / PTM_RATIO, (360.f+204.0f) / PTM_RATIO);
//    singleVers[0].vec2.Set((640.f-66.0f) / PTM_RATIO, (360.f+129.0f) / PTM_RATIO);
//
//    singleVers[1].vec1.Set((640.f+48.0f) / PTM_RATIO, (360.f+93.0f) / PTM_RATIO);
//    singleVers[1].vec2.Set((640.f+360.0f) / PTM_RATIO, (360.f+7.0f) / PTM_RATIO);
//    
//    singleVers[2].vec1.Set((640.f-348.0f) / PTM_RATIO, (360.f+68.0f) / PTM_RATIO);
//    singleVers[2].vec2.Set((640.f-277.0f) / PTM_RATIO, (360.f+53.0f) / PTM_RATIO);
//    
//    singleVers[3].vec1.Set((640.f-162.0f) / PTM_RATIO, (360.f+31.0f) / PTM_RATIO);
//    singleVers[3].vec2.Set((640.f+308.0f) / PTM_RATIO, (360.f-104.0f) / PTM_RATIO);
    
    
    
//    verts[0].Set((640.f+118.0f) / PTM_RATIO, (360.f-74.0f) / PTM_RATIO);
//    verts[14].Set((640.f+66.0f) / PTM_RATIO, (360.f+126.0f) / PTM_RATIO);
    
    
//    singleVers[0].vec1.Set((400.f+118.0f) / PTM_RATIO, (460.f-74.0f) / PTM_RATIO);
//    singleVers[0].vec2.Set((400.f+66.0f) / PTM_RATIO, (460.f+126.0f) / PTM_RATIO);
    
    
//    verts[0].Set((640.f-288.0f) / PTM_RATIO, (360.f+360.0f) / PTM_RATIO);
//    verts[1].Set((640.f-208.0f) / PTM_RATIO, (360.f-62.0f) / PTM_RATIO);
//    verts[2].Set((640.f-153.0f) / PTM_RATIO, (360.f-110.0f) / PTM_RATIO);
//    verts[3].Set((640.f-90.0f) / PTM_RATIO, (360.f-105.0f) / PTM_RATIO);
//    verts[4].Set((640.f-79.0f) / PTM_RATIO, (360.f+358.0f) / PTM_RATIO);
    
    
    singleVers[0].vec1.Set((640.f-288.0f) / PTM_RATIO, (360.f+360.0f) / PTM_RATIO);
    singleVers[0].vec2.Set((640.f-208.0f) / PTM_RATIO, (360.f-62.0f) / PTM_RATIO);
    
    singleVers[1].vec1.Set((640.f-208.0f) / PTM_RATIO, (360.f-62.0f) / PTM_RATIO);
    singleVers[1].vec2.Set((640.f-153.0f) / PTM_RATIO, (360.f-110.0f) / PTM_RATIO);
    
    singleVers[2].vec1.Set((640.f-153.0f) / PTM_RATIO, (360.f-110.0f) / PTM_RATIO);
    singleVers[2].vec2.Set((640.f-90.0f) / PTM_RATIO, (360.f-105.0f) / PTM_RATIO);
    
    singleVers[3].vec1.Set((640.f-90.0f) / PTM_RATIO, (360.f-105.0f) / PTM_RATIO);
    singleVers[3].vec2.Set((640.f-79.0f) / PTM_RATIO, (360.f+358.0f) / PTM_RATIO);
    
    singleVers[4].vec1.Set((640.f-288.0f) / PTM_RATIO, (360.f+360.0f) / PTM_RATIO);
    singleVers[4].vec2.Set((640.f-79.0f) / PTM_RATIO, (360.f+358.0f) / PTM_RATIO);
    

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
//    poly[0] = b2Vec2((640.f+630.0f) / PTM_RATIO, (1360.f+349.0f) / PTM_RATIO);
//    poly[1] = b2Vec2((640.f+634.0f) / PTM_RATIO, (360.f-22.0f) / PTM_RATIO);
//    poly[2] = b2Vec2((640.f+382.0f) / PTM_RATIO, (360.f+3.0f) / PTM_RATIO);
//    poly[3] = b2Vec2((640.f+317.0f) / PTM_RATIO, (360.f+178.0f) / PTM_RATIO);
    
    poly[0].Set((640.f+309.0f) / PTM_RATIO, (360.f+169.0f) / PTM_RATIO);
    poly[1].Set((640.f+323.0f) / PTM_RATIO, (360.f-48.0f) / PTM_RATIO);
    poly[2].Set((640.f+583.0f) / PTM_RATIO, (360.f-53.0f) / PTM_RATIO);
    poly[3].Set((640.f+583.0f) / PTM_RATIO, (360.f+246.0f) / PTM_RATIO);
    
//    verts[8].Set((640.f+630.0f) / PTM_RATIO, (1360.f+349.0f) / PTM_RATIO);
//    verts[9].Set((640.f+634.0f) / PTM_RATIO, (360.f-22.0f) / PTM_RATIO);
//    verts[10].Set((640.f+382.0f) / PTM_RATIO, (360.f+3.0f) / PTM_RATIO);
//    verts[11].Set((640.f+317.0f) / PTM_RATIO, (360.f+178.0f) / PTM_RATIO);
    
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
            awakePraticles(30,b2Vec2(shushuiPs.x,shushuiPs.y),20,-24.f,b2Vec2(0.f,-10.f),30.f,0,true);
            //awakePraticles(100,b2Vec2(280,320),10,-6.f,b2Vec2(0.f,-10.f),30.f,0,true);
        }
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
