//
//  CCShiZi.m
//  WaterSprite4
//
//  Created by zte- s on 13-6-2.
//  Copyright 2013年 zte. All rights reserved.
//

#import "CCXuanWo.h"


@implementation CCXuanWo

-(id)initPhysical:(CGPoint)ps event:(NSEvent*)event
{
    if( (self=[super init])) 
    {
        type = 3;
        clockDirector = 1;//默认 顺时针
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
        bodyDef.angle = 0.f;
        b2Body *body = m_world->CreateBody(&bodyDef);
        xwBodyType = 1000;
        
        // Define another box shape for our dynamic body.
        b2CircleShape dynamicBox;
        dynamicBox.m_radius = 0.15f;
        
        // Define the dynamic body fixture.
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &dynamicBox;
        fixtureDef.density = 1.f;
        fixtureDef.friction = 0.8f;
        fixtureDef.filter.maskBits = 2;
        body->CreateFixture(&fixtureDef);
        
        xw = body;
        xw->SetAngularVelocity(-1.f*clockDirector*PI);
        
        [self scheduleUpdate];
    }
    return self;
    
}

- (BOOL) ccMouseDown:(NSEvent *)event
{
    ifContinue = NO;
    return NO;
}

-(BOOL) ccMouseUp:(NSEvent*)event
{
    ifContinue = YES;
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
    xw->SetTransform(xw->GetPosition(),xw->GetAngle()-angle);
    if(angle > 0)
    {
        clockDirector = 1;
    }
    else
    {
        clockDirector = -1;
    }
    xw->SetAngularVelocity(-1.f*clockDirector*PI);
}

-(void)move:(CGPoint)offset
{
    b2Vec2 off = b2Vec2(offset.x,offset.y);
    xw->SetTransform(xw->GetPosition()+off/PTM_RATIO, xw->GetAngle());
    
}

-(void)setBodyPosition:(CGPoint)position
{
    xw->SetTransform(b2Vec2(position.x/PTM_RATIO,position.y/PTM_RATIO), xw->GetAngle());
    
}

//计算吸铁石对水滴粒子的吸力情况
-(void)comupteAttractiveForceFromXW:(int)numParticles waterParticle:(sParticle*)liquid  
{
    //匀速圆周运动 产生大小不变的向心力
    int totalForceNum = 0;
    
    for (int32 i = 0; i < numParticles; ++i)
    {
        float distance = (liquid[i].mPosition-xw->GetPosition()).Length();
        if(distance <= 3.0f && distance >= 0.0f)
        {
            totalForceNum++;
        }
    }
    
    for (int32 i = 0; i < numParticles; ++i)
    {
        if(liquid[i].isAwake == false)continue;
        float distance = (liquid[i].mPosition-xw->GetPosition()).Length();
        b2Vec2 disNormalize =  (xw->GetPosition() - liquid[i].mPosition);
        disNormalize.Normalize();
        if(distance <= 3.2f && distance >= 0.0f)
        {
            b2Vec2 forceFactor;
            b2Vec2 forceFactor2;
            
            forceFactor =  disNormalize;
            float mVelocity = liquid[i].mVelocity.LengthSquared();
            forceFactor = forceFactor * mVelocity;
            forceFactor = forceFactor/distance;
            
            int tick;
            if(totalForceNum > 20)
            {
                tick = 50-totalForceNum/20;
            }
            else
            {
                tick = liquid[i].xuanwoTick;
            }
            
            float rX = xw->GetPosition().x;
            float rY = xw->GetPosition().y;
            
            //顺时针切线力
            if(liquid[i].mPosition.x <= rX && liquid[i].mPosition.y >= rY)//第1象限
            {
                //force x >0 y >0
                forceFactor2 = b2Vec2(fabs(disNormalize.y),fabs(disNormalize.x));
            }
            else if(liquid[i].mPosition.x >= rX && liquid[i].mPosition.y >= rY)//第4象限
            {
                //force x > 0 y < 0
                forceFactor2 = b2Vec2(fabs(disNormalize.y),fabs(disNormalize.x)*-1.f);
            }
            else if(liquid[i].mPosition.x >= rX && liquid[i].mPosition.y <= rY)//第3象限
            {
                //force x < 0 y < 0
                forceFactor2 = b2Vec2(fabs(disNormalize.y)*-1.f,fabs(disNormalize.x)*-1.f);
                
            }
            else if(liquid[i].mPosition.x <= rX && liquid[i].mPosition.y <= rY)//第2象限
            {
                //force x < 0 y > 0
                forceFactor2 = b2Vec2(fabs(disNormalize.y)*-1.f,fabs(disNormalize.x));
            }
            
            if(distance >= 3.0f)
            {
                liquid[i].xuanwoTick = 60 + rand()%240;
                liquid[i].xuanwoTickCount = 0;
                continue;
            }
            
            else if(distance >= 2.3f)
            {
                //if(i % 8 == 0) return;
                
                float T = 2.0f;
                float r = distance;
                float fn = r*4.f*PI*PI/(T*T);
                float v = 2 * PI * r / T;
                
                if(liquid[i].xuanwoTickCount >= tick &&
                   ((liquid[i].mPosition.x > rX && liquid[i].mPosition.y < rY && clockDirector == -1)
                   ||
                    (liquid[i].mPosition.x < rX && liquid[i].mPosition.y < rY  && clockDirector == 1)
                    )
                   )
                {
                    liquid[i].mForce += m_world->GetGravity();
                    continue;
                }
                liquid[i].mForce = 1.f*fn * disNormalize ;//- 1.f * m_world->GetGravity();
                liquid[i].mVelocity = clockDirector*v*forceFactor2;
                liquid[i].xuanwoTickCount++;
            }
            else
            {
//                float T = 2.0f;
//                float r = distance;
//                float fn = r*4.f*PI*PI/(T*T);
//                float v = 2 * PI * r / T;
//                liquid[i].mForce += -1*(fn * disNormalize - 1.f * m_world->GetGravity());
//                liquid[i].mVelocity = -1.f*clockDirector*v*forceFactor2;
//                liquid[i].xuanwoTick++;
            }
        }
    }
    
}

-(void)update:(ccTime)dt
{
    if(m_numParticles > 0 && m_liquid != NULL)
    {
        [self comupteAttractiveForceFromXW:m_numParticles waterParticle:m_liquid];
    }

}

+(float)acosAngle:(CGPoint)p1 cicleCenter:(CGPoint)p2 lastPoint:(CGPoint)p3
{
    //added by tr 2013-05-29
    //vector1
    float xV1 = p2.x - p1.x;
    float yV1 = p2.y - p1.y; 
    //vector2
    float xV2 = p2.x - p3.x;
    float yV2 = p2.y - p3.y;
    
    if ((0==xV1 && 0 ==yV1)&&(0 == xV2 && 0 == yV2))
        return 0;
    else
        return acos((xV1*xV2 + yV1*yV2) / sqrt((xV1*xV1 + yV1*yV1)*(xV2*xV2 + yV2*yV2)));//steering*
    //ended by tr 2013-05-29
    
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
    
    [rStick removeFromParentAndCleanup:YES];
    m_world->DestroyBody(xw);
    if(mainSprite != nil)
    {
        [mainSprite removeFromParentAndCleanup:YES];
    }
    
	// don't forget to call "super dealloc"
	[super dealloc];
    
}

@end
