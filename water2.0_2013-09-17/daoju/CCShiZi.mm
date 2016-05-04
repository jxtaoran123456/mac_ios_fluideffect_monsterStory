//
//  CCShiZi.m
//  WaterSprite4
//
//  Created by zte- s on 13-6-2.
//  Copyright 2013年 zte. All rights reserved.
//

#import "CCShiZi.h"


@implementation CCShiZi

-(id)initPhysical:(CGPoint)ps event:(NSEvent*)event
{
    if( (self=[super init])) 
    {
        clockDirector = 1;
        if(rStick == nil)
        {
            CCSprite *ineerS = [CCSprite spriteWithFile:@"inner.png"];
            CCSprite *outerS = [CCSprite spriteWithFile:@"outer.png"];
            rStick = [[CCRotationStick node]initWithCircle:ineerS outerCircle:outerS innerRadius:25.f outerRadius:65.f position:ps delegate:self];
            [rStick ccMouseDown:event];
            [self addChild:rStick];
        }
        
        b2BodyDef bodyDef;
        bodyDef.type = b2_kinematicBody;
        
        bodyDef.position.Set(ps.x/PTM_RATIO, ps.y/PTM_RATIO);
        b2Body *body = m_world->CreateBody(&bodyDef);
        
        // Define another box shape for our dynamic body.
        b2PolygonShape dynamicBox;
        dynamicBox.SetAsBox(2.5f,.20f);
        
        // Define the dynamic body fixture.
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &dynamicBox;	
        fixtureDef.density = 3.f;
        fixtureDef.friction = 0.0f;
        fixtureDef.filter.maskBits = 2;
        body->CreateFixture(&fixtureDef);
        
        b2BodyDef bodyDef2;
        bodyDef2.type = b2_kinematicBody;
        
        bodyDef2.position.Set(ps.x/PTM_RATIO, ps.y/PTM_RATIO);
        bodyDef2.angle = 3.1415926/2.f;
        b2Body *body2 = m_world->CreateBody(&bodyDef2);
        
        // Define another box shape for our dynamic body.
        b2PolygonShape dynamicBox2;
        dynamicBox2.SetAsBox(2.5f,.20f);
        
        // Define the dynamic body fixture.
        b2FixtureDef fixtureDef2;
        fixtureDef2.shape = &dynamicBox2;	
        fixtureDef2.density = 1.f;
        fixtureDef2.friction = 0.00f;
        fixtureDef2.filter.maskBits = 2;
        body2->CreateFixture(&fixtureDef2);
        
        ten1 = body;
        ten2 = body2;
        
        angleSpeed = -2.0f;
        
        ten1->SetAngularVelocity(angleSpeed*clockDirector);
        ten2->SetAngularVelocity(angleSpeed*clockDirector);
        
        [self scheduleUpdate];
    }
    return self;
    
}

- (BOOL) ccMouseDown:(NSEvent *)event
{
    return YES;
    
}

-(BOOL) ccMouseUp:(NSEvent*)event
{
    return YES;
    
}

-(BOOL) ccMouseDragged:(NSEvent*)event
{
    return YES;
    
}

-(BOOL) ccMouseMoved:(NSEvent*)event
{
    return YES;
    
}

-(void)rotation:(float)angle
{
    //box2d的转动方向为逆时针正向 和cocos2d的方向正好相反
    ten1->SetTransform(ten1->GetPosition(), ten1->GetAngle()-angle);
    ten2->SetTransform(ten2->GetPosition(), ten2->GetAngle()-angle);
    
    if(angle > 0)
    {
        clockDirector = 1;
    }
    else
    {
        clockDirector = -1;
    }
    ten1->SetAngularVelocity(angleSpeed*clockDirector);
    ten2->SetAngularVelocity(angleSpeed*clockDirector);
}

-(void)move:(CGPoint)offset
{
    b2Vec2 off = b2Vec2(offset.x,offset.y);
    ten1->SetTransform(ten1->GetPosition()+off/PTM_RATIO, ten1->GetAngle());
    ten2->SetTransform(ten2->GetPosition()+off/PTM_RATIO, ten2->GetAngle());
    
}

-(void)setBodyPosition:(CGPoint)position
{
    ten1->SetTransform(b2Vec2(position.x/PTM_RATIO,position.y/PTM_RATIO), ten1->GetAngle());
    ten2->SetTransform(b2Vec2(position.x/PTM_RATIO,position.y/PTM_RATIO), ten2->GetAngle());
    
}

-(void)update:(ccTime)dt
{
//    ten1->SetTransform(ten1->GetPosition(), ten1->GetAngle()-0.1f/PI);
//    ten2->SetTransform(ten2->GetPosition(), ten2->GetAngle()-0.1f/PI);
    
//    ten1->SetAngularVelocity(0.1f);
    
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
    
    [rStick removeFromParentAndCleanup:YES];
    m_world->DestroyBody(ten1);
    m_world->DestroyBody(ten2);
    if(mainSprite != nil)
    {
        [mainSprite removeFromParentAndCleanup:YES];
    }
    
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end
