//
//  CCShiZi.m
//  WaterSprite4
//
//  Created by zte- s on 13-6-2.
//  Copyright 2013年 zte. All rights reserved.
//

#import "CCDangBan.h"


@implementation CCDangBan


-(id)initPhysical:(CGPoint)ps event:(NSEvent*)event
{
    if( (self=[super init])) 
    {
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
        bodyDef.angle = -1.f*3.1415926/6.f;
        b2Body *body = m_world->CreateBody(&bodyDef);
        
        // Define another box shape for our dynamic body.
        b2PolygonShape dynamicBox;
        dynamicBox.SetAsBox(2.5f,.25f);
        
        // Define the dynamic body fixture.
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &dynamicBox;	
        fixtureDef.density = 1.f;
        fixtureDef.friction = 0.0f;
        fixtureDef.filter.maskBits = 2;
        body->CreateFixture(&fixtureDef);
        
        dang = body;
        
        //dang->SetAngularVelocity(0.5f);
    }
    return self;
    
}

- (BOOL) ccMouseDown:(NSEvent *)event
{
    
    return NO;
}

-(BOOL) ccMouseUp:(NSEvent*)event
{
    
    return NO;
}

-(BOOL) ccMouseDragged:(NSEvent*)event
{
    
    return NO;
}

-(BOOL) ccMouseMoved:(NSEvent*)event
{
    return NO;
    
}

-(void)rotation:(float)angle
{
    //box2d的转动方向为逆时针正向 和cocos2d的方向正好相反
    dang->SetTransform(dang->GetPosition(), dang->GetAngle()-angle);
    
}

-(void)move:(CGPoint)offset
{
    b2Vec2 off = b2Vec2(offset.x,offset.y);
    dang->SetTransform(dang->GetPosition()+off/PTM_RATIO, dang->GetAngle());

}

-(void)setBodyPosition:(CGPoint)position
{
    dang->SetTransform(b2Vec2(position.x/PTM_RATIO,position.y/PTM_RATIO), dang->GetAngle());
    
}

//-(void)removeFromParentAndCleanup:(BOOL)cleanup
//{
//    // don't forget to call "super dealloc"
//
//    
//	// in case you have something to dealloc, do it in this method
//    if(rStick != nil)
//    {
//        [rStick removeFromParentAndCleanup:YES];
//        rStick = nil;
//    }
//    m_world->DestroyBody(dang);
//    if(mainSprite != nil)
//    {
//        [mainSprite removeFromParentAndCleanup:YES];
//        mainSprite = nil;
//    }
//    
//    [super removeFromParentAndCleanup:cleanup];
//    
//}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
    [rStick removeFromParentAndCleanup:YES];
    m_world->DestroyBody(dang);
    if(mainSprite != nil)
    {
        [mainSprite removeFromParentAndCleanup:YES];
    }
    // don't forget to call "super dealloc"
	[super dealloc];

    
}

@end
