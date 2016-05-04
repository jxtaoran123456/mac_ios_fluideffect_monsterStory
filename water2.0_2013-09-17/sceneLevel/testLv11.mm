//
//  SPHNode.m
//  SPH
//
//  Created by Vasiliy Yanushevich on 11/2/12.
//  Copyright 2012 Vasiliy Yanushevich. All rights reserved.
//

#import "SPHNode.h"
#import "testLv11.h"

#include <GLUT/GLUT.h>
#include <OpenGL/glu.h>
#import "CCPhysicsSprite.h"


@implementation testLv11

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	testLv11 *layer = [testLv11 node];
	
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
        toolsNum = 6;
        shushuiPs = ccp(-120,720);
        
        [self createStaticGeometry];

        intersectQueryCallback = new QueryWorldInteractions(hashGridList, liquid);
        eulerIntersectQueryCallback = new QueryWorldPostIntersect(hashGridList, liquid);
        
        //back back1 fluid tree back2
//        backgroundSprite = [CCSprite spriteWithFile:@"lv3_back.png"];//testLevel1.png testLevel3 3_1.png lv3_back.png
//        backgroundSprite.anchorPoint = ccp(0,0);
//        backgroundSprite.position = ccp(0,0);//(72,40);
//        [self addChild:backgroundSprite z:zOrder+1];
//        
//        [rippleSprArr addObject:backgroundSprite];
//        [backgroundSprite release];
        
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
        
        
        //RENDER SHADER
        
        
        const GLchar * fragmentSource1 = (GLchar*) [[NSString stringWithContentsOfFile:[CCFileUtils fullPathFromRelativePath:@"fluidRender _11_010.fsh"] encoding:NSUTF8StringEncoding error:nil] UTF8String];
        
        const GLchar * fragmentSource2 = (GLchar*) [[NSString stringWithContentsOfFile:[CCFileUtils fullPathFromRelativePath:@"fluidRender _11_100.fsh"] encoding:NSUTF8StringEncoding error:nil] UTF8String];
        renderTexture.sprite.shaderProgram = [[CCGLProgram alloc] initWithVertexShaderByteArray:ccPositionTextureA8Color_vert fragmentShaderByteArray:fragmentSource1];
        [renderTexture.sprite.shaderProgram addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
        [renderTexture.sprite.shaderProgram addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
        [renderTexture.sprite.shaderProgram link];
        [renderTexture.sprite.shaderProgram updateUniforms];
        [renderTexture.sprite.shaderProgram use];
        
        renderTexture2.sprite.shaderProgram = [[CCGLProgram alloc] initWithVertexShaderByteArray:ccPositionTextureA8Color_vert fragmentShaderByteArray:fragmentSource2];
        [renderTexture2.sprite.shaderProgram addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
        [renderTexture2.sprite.shaderProgram addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
        [renderTexture2.sprite.shaderProgram link];
        [renderTexture2.sprite.shaderProgram updateUniforms];
        [renderTexture2.sprite.shaderProgram use];

        //added new shader for this scene
        if(fluidRender==nil)
        {
            CGSize screenSize = [CCDirector sharedDirector].winSize;
            fluidRender = [CCRenderTexture renderTextureWithWidth:screenSize.width height:screenSize.height];
            fluidRender.position = ccp(screenSize.width/2, screenSize.height/2);
            [self addChild:fluidRender z:zOrder+10];//前面为滤镜层 后面为遮挡层
        }
        fluidRender.sprite.shaderProgram = [CCGLProgram programWithVertexShaderFilename:@"fluidRender_testLv11.vsh" fragmentShaderFilename:@"fluidRender_testLv11.fsh"];
        [fluidRender.sprite.shaderProgram addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
        [fluidRender.sprite.shaderProgram addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
        [fluidRender.sprite.shaderProgram addAttribute:kCCAttributeNameColor index:kCCVertexAttrib_Color];
        [fluidRender.sprite.shaderProgram link];
        [fluidRender.sprite.shaderProgram updateUniforms];
        [fluidRender.sprite.shaderProgram use];
        
        // 3
        colorRampUniformLocation = glGetUniformLocation(fluidRender.sprite.shaderProgram->_program, "u_colorRampTexture");
        glUniform1i(colorRampUniformLocation, 1);
        
        // 4
        colorRampTexture = [[CCTextureCache sharedTextureCache] addImage:@"colorRamp.png"];
        [colorRampTexture setAliasTexParameters];
    
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
    
    [self addSingleMap];
	
    // Particles
    initFluidPraticles(0.8f,0.005f,50.f,30.f,2000,@"fire_010.png",nil);// VbmyR.png fire2 drop2 fire_010
    //added by tr 2013-08-08
    
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
    
    //[self createSliderCrank];

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
        shape.Set(b2Vec2(-40.0f, 0.0f), b2Vec2(40.0f, 0.0f));
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
        shape.SetAsBox(0.5f, 1.0f);
        
        b2BodyDef bd;
        bd.type = b2_dynamicBody;
        bd.fixedRotation = true;
        bd.position.Set(20.0f, 11.0f);
        b2Body* body = m_world->CreateBody(&bd);
        body->CreateFixture(&shape, 2.0f);
        bianseBox = body;
        
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

- (void)drawLiquid
{
//    renderTexture.visible = YES;
//    renderTexture2.visible = YES;
//    
//    
//    [renderTexture2 beginWithClear:0 g:0 b:0 a:0];
//    if(ParticleBatch2 != nil)
//    {
//        ParticleBatch2.visible = YES;
//        [ParticleBatch2 visit];
//        ParticleBatch2.visible = NO;
//    }
//    [renderTexture2 end];
//    
//    [renderTexture beginWithClear:0 g:0 b:0 a:0];
//    if(ParticleBatch != nil)
//    {
//        ParticleBatch.visible = YES;
//        [ParticleBatch visit];
//        ParticleBatch.visible = NO;
//    }
//    [renderTexture end];
//    
//
//    [fluidRender beginWithClear:0 g:0 b:0 a:0];
//    [renderTexture visit];
//    [renderTexture2 visit];
//    
//    [fluidRender.sprite.shaderProgram use];
//    GLuint Program = fluidRender.sprite.shaderProgram->_program;
//    GLuint fluidRen1Loc = glGetUniformLocation(Program, "FluidRender1");
//    GLuint fluidRen2Loc = glGetUniformLocation(Program, "FluidRender2");
//    colorRampUniformLocation = glGetUniformLocation(Program, "u_colorRampTexture");
//    
//    
//    glUniform1i(fluidRen1Loc,1);
//    glUniform1i(fluidRen2Loc,2);
//    glUniform1i(colorRampUniformLocation, 3);
//    
//    glActiveTexture(GL_TEXTURE1);
//    glBindTexture(GL_TEXTURE_2D,renderTexture.sprite.texture.name);
//    glActiveTexture(GL_TEXTURE0);
//    
//    glActiveTexture(GL_TEXTURE2);
//    glBindTexture(GL_TEXTURE_2D,renderTexture2.sprite.texture.name);
//    glActiveTexture(GL_TEXTURE1);
//    
//    glActiveTexture(GL_TEXTURE3);
//    glBindTexture(GL_TEXTURE_2D,[colorRampTexture name]);
//    glActiveTexture(GL_TEXTURE2);
//
//    
//    [fluidRender end];
//    
//    renderTexture.visible = NO;
//    renderTexture2.visible = NO;

    
    
//    [fluidRender beginWithClear:0 g:0 b:0 a:0];
    
//    [renderTexture visit];
//    [renderTexture2 visit];
//
//    [fluidRender.sprite.shaderProgram use];
//    GLuint Program = fluidRender.sprite.shaderProgram->_program;
//    GLuint fluidRen1Loc = glGetUniformLocation(Program, "FluidRender1");
//    GLuint fluidRen2Loc = glGetUniformLocation(Program, "FluidRender2");
//    glUniform1i(fluidRen1Loc,1);
//    glUniform1i(fluidRen2Loc,2);
//    
//    glActiveTexture(GL_TEXTURE1);
//    glBindTexture(GL_TEXTURE_2D,renderTexture.sprite.texture.name);
//    glActiveTexture(GL_TEXTURE0);
//    
//    glActiveTexture(GL_TEXTURE2);
//    glBindTexture(GL_TEXTURE_2D,renderTexture2.sprite.texture.name);
//    glActiveTexture(GL_TEXTURE1);
//
//    [fluidRender end];
//    
//    renderTexture.visible = NO;
//    renderTexture2.visible = NO;
    
    [fluidRender beginWithClear:0 g:0 b:0 a:0];
    
    ParticleBatch.visible = YES;
    ParticleBatch2.visible = YES;
    [ParticleBatch visit];
    [ParticleBatch2 visit];
    ParticleBatch.visible = NO;
    ParticleBatch2.visible = NO;
    
    
    [fluidRender end];
    
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

    
    verts[0].Set((640-615.0f) / PTM_RATIO, (360+356.0f) / PTM_RATIO);
    verts[1].Set((640-612.0f) / PTM_RATIO, (360+7.0f) / PTM_RATIO);
    verts[2].Set((640-106.0f) / PTM_RATIO, (360+23.0f) / PTM_RATIO);
    verts[3].Set((640-68.0f) / PTM_RATIO, (360+14.0f) / PTM_RATIO);
    verts[4].Set((640-82.0f) / PTM_RATIO, (360-138.0f) / PTM_RATIO);
    verts[5].Set((640+5.0f) / PTM_RATIO, (360-294.0f) / PTM_RATIO);
    verts[6].Set((640+532.0f) / PTM_RATIO, (360-294.0f) / PTM_RATIO);
    verts[7].Set((640+542.0f) / PTM_RATIO, (360+49.0f) / PTM_RATIO);
    verts[8].Set((640+587.0f) / PTM_RATIO, (360+50.0f) / PTM_RATIO);
    verts[9].Set((640+613.0f) / PTM_RATIO, (360-357.0f) / PTM_RATIO);
    verts[10].Set((640-630.0f) / PTM_RATIO, (360-355.0f) / PTM_RATIO);


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
    singleVerNum = 14;
    singleVers = (singleVec *)malloc (singleVerNum * sizeof (singleVec));
    
    singleVers[0].vec1.Set((640.f-350.0f) / PTM_RATIO, (360.f+125.0f) / PTM_RATIO);
    singleVers[0].vec2.Set((640.f-320.0f) / PTM_RATIO, (360.f+168.0f) / PTM_RATIO);
    
    singleVers[1].vec1.Set((640.f-320.0f) / PTM_RATIO, (360.f+168.0f) / PTM_RATIO);
    singleVers[1].vec2.Set((640.f-242.0f) / PTM_RATIO, (360.f+131.0f) / PTM_RATIO);
    
    singleVers[2].vec1.Set((640.f-242.0f) / PTM_RATIO, (360.f+131.0f) / PTM_RATIO);
    singleVers[2].vec2.Set((640.f-267.0f) / PTM_RATIO, (360.f+102.0f) / PTM_RATIO);
    
    singleVers[3].vec1.Set((640.f-267.0f) / PTM_RATIO, (360.f+102.0f) / PTM_RATIO);
    singleVers[3].vec2.Set((640.f-152.0f) / PTM_RATIO, (360.f+44.0f) / PTM_RATIO);
    
    singleVers[4].vec1.Set((640.f-174.0f) / PTM_RATIO, (360.f-0.0f) / PTM_RATIO);
    singleVers[4].vec2.Set((640.f-366.0f) / PTM_RATIO, (360.f+93.0f) / PTM_RATIO);
    
    
    singleVers[5].vec1.Set((640.f+9.0f) / PTM_RATIO, (360.f+191.0f) / PTM_RATIO);
    singleVers[5].vec2.Set((640.f+27.0f) / PTM_RATIO, (360.f+138.0f) / PTM_RATIO);
    
    singleVers[6].vec1.Set((640.f+27.0f) / PTM_RATIO, (360.f+138.0f) / PTM_RATIO);
    singleVers[6].vec2.Set((640.f+50.0f) / PTM_RATIO, (360.f+53.0f) / PTM_RATIO);
    
    singleVers[7].vec1.Set((640.f+50.0f) / PTM_RATIO, (360.f+53.0f) / PTM_RATIO);
    singleVers[7].vec2.Set((640.F+93.0f) / PTM_RATIO, (360.f-2.0f) / PTM_RATIO);
    
    singleVers[8].vec1.Set((640.F+93.0f) / PTM_RATIO, (360.f-2.0f) / PTM_RATIO);
    singleVers[8].vec2.Set((640.f+160.0f) / PTM_RATIO, (360.f-34.0f) / PTM_RATIO);
    
    singleVers[9].vec1.Set((640.f+160.0f) / PTM_RATIO, (360.f-34.0f) / PTM_RATIO);
    singleVers[9].vec2.Set((640.f+224.0f) / PTM_RATIO, (360.f-32.0f) / PTM_RATIO);
    
    singleVers[10].vec1.Set((640.f+224.0f) / PTM_RATIO, (360.f-32.0f) / PTM_RATIO);
    singleVers[10].vec2.Set((640.f+270.0f) / PTM_RATIO, (360.f+21.0f) / PTM_RATIO);
    
    singleVers[11].vec1.Set((640.f+270.0f) / PTM_RATIO, (360.f+21.0f) / PTM_RATIO);
    singleVers[11].vec2.Set((640.f+282.0f) / PTM_RATIO, (360.f+81.0f) / PTM_RATIO);
    
    singleVers[12].vec1.Set((640.f+282.0f) / PTM_RATIO, (360.f+81.0f) / PTM_RATIO);
    singleVers[12].vec2.Set((640.f+284.0f) / PTM_RATIO, (360.f+144.0f) / PTM_RATIO);
    
    singleVers[13].vec1.Set((640.f+284.0f) / PTM_RATIO, (360.f+144.0f) / PTM_RATIO);
    singleVers[13].vec2.Set((640.f+286.0f) / PTM_RATIO, (360.f+184.0f) / PTM_RATIO);
    
    
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
    
    shape.Set(singleVers[4].vec1, singleVers[4].vec2);
    shape.m_hasVertex3 = false;
    ground->CreateFixture(&shape, 0.0f);
    
    
    
    shape.Set(singleVers[5].vec1, singleVers[5].vec2);
    shape.m_hasVertex3 = false;
    ground->CreateFixture(&shape, 0.0f);
    
    shape.Set(singleVers[6].vec1, singleVers[6].vec2);
    shape.m_hasVertex3 = false;
    ground->CreateFixture(&shape, 0.0f);
    
    shape.Set(singleVers[7].vec1, singleVers[7].vec2);
    shape.m_hasVertex3 = false;
    ground->CreateFixture(&shape, 0.0f);
    
    shape.Set(singleVers[8].vec1, singleVers[8].vec2);
    shape.m_hasVertex3 = false;
    ground->CreateFixture(&shape, 0.0f);
    
    shape.Set(singleVers[9].vec1, singleVers[9].vec2);
    shape.m_hasVertex3 = false;
    ground->CreateFixture(&shape, 0.0f);
    
    shape.Set(singleVers[10].vec1, singleVers[10].vec2);
    shape.m_hasVertex3 = false;
    ground->CreateFixture(&shape, 0.0f);
    
    shape.Set(singleVers[11].vec1, singleVers[11].vec2);
    shape.m_hasVertex3 = false;
    ground->CreateFixture(&shape, 0.0f);
    
    shape.Set(singleVers[12].vec1, singleVers[12].vec2);
    shape.m_hasVertex3 = false;
    ground->CreateFixture(&shape, 0.0f);
    
    shape.Set(singleVers[13].vec1, singleVers[13].vec2);
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
        if(PtInPolygon(liquid[i].mPosition,poly,4) == true)
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
        }
    }
    
    singleVers[0].vec1.Set((640.f-350.0f) / PTM_RATIO, (360.f+125.0f) / PTM_RATIO);
    singleVers[0].vec2.Set((640.f-320.0f) / PTM_RATIO, (360.f+168.0f) / PTM_RATIO);
    
    singleVers[1].vec1.Set((640.f-320.0f) / PTM_RATIO, (360.f+168.0f) / PTM_RATIO);
    singleVers[1].vec2.Set((640.f-242.0f) / PTM_RATIO, (360.f+131.0f) / PTM_RATIO);
    
    singleVers[2].vec1.Set((640.f-242.0f) / PTM_RATIO, (360.f+131.0f) / PTM_RATIO);
    singleVers[2].vec2.Set((640.f-267.0f) / PTM_RATIO, (360.f+102.0f) / PTM_RATIO);
    
    singleVers[3].vec1.Set((640.f-267.0f) / PTM_RATIO, (360.f+102.0f) / PTM_RATIO);
    singleVers[3].vec2.Set((640.f-152.0f) / PTM_RATIO, (360.f+44.0f) / PTM_RATIO);
    
    singleVers[4].vec1.Set((640.f-174.0f) / PTM_RATIO, (360.f-0.0f) / PTM_RATIO);
    singleVers[4].vec2.Set((640.f-366.0f) / PTM_RATIO, (360.f+93.0f) / PTM_RATIO);
    
    b2Vec2 poly[7];
    poly[0] = b2Vec2((640.f-350.0f) / PTM_RATIO, (360.f+125.0f) / PTM_RATIO);
    poly[1] = b2Vec2((640.f-320.0f) / PTM_RATIO, (360.f+168.0f) / PTM_RATIO);
    poly[2] = b2Vec2((640.f-242.0f) / PTM_RATIO, (360.f+131.0f) / PTM_RATIO);
    poly[3] = b2Vec2((640.f-267.0f) / PTM_RATIO, (360.f+102.0f) / PTM_RATIO);
    poly[4] = b2Vec2((640.f-152.0f) / PTM_RATIO, (360.f+44.0f) / PTM_RATIO);
    poly[5] = b2Vec2((640.f-174.0f) / PTM_RATIO, (360.f-0.0f) / PTM_RATIO);
    poly[6] = b2Vec2((640.f-366.0f) / PTM_RATIO, (360.f+93.0f) / PTM_RATIO);

    for(int i = 0; i < nParticles; ++i)
	{
        if(PtInPolygon(liquid[i].mPosition,poly,7) == true)
        {
            ccColor3B color;
            color.r = 0;
            color.g = 255;
            color.b = 0;
            [self setColorState:i color:color];
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
