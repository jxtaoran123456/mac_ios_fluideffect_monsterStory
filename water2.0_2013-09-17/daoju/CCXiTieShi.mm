//
//  CCShiZi.m
//  WaterSprite4
//
//  Created by zte- s on 13-6-2.
//  Copyright 2013年 zte. All rights reserved.
//

#import "CCXiTieShi.h"


@implementation CCXiTieShi

-(id)initPhysical:(CGPoint)ps event:(NSEvent*)event
{
    if( (self=[super init])) 
    {
        type = 2;
        
        mainSprite = [CCSprite spriteWithFile:@"xts.jpg"];
        mainSprite.scale = 0.15;
        mainSprite.rotation = 180;
        mainSprite.position = ps;
        [self addChild:mainSprite];
        
        if(rStick == nil)
        {
            CCSprite *ineerS = [CCSprite spriteWithFile:@"inner.png"];
            CCSprite *outerS = [CCSprite spriteWithFile:@"outer.png"];//
            rStick = [[CCRotationStick node]initWithCircle:ineerS outerCircle:outerS innerRadius:25.f outerRadius:65.f position:ps delegate:self];
            [rStick ccMouseDown:event];
            [self addChild:rStick];
        }
        
        b2BodyDef bodyDef;
        bodyDef.type = b2_staticBody;
        
        bodyDef.position.Set(ps.x/PTM_RATIO, ps.y/PTM_RATIO);
        bodyDef.angle = 0.f;
        b2Body *body = m_world->CreateBody(&bodyDef);
        
        // Define another box shape for our dynamic body.
        b2PolygonShape dynamicBox;
        dynamicBox.SetAsBox(1.f,1.f);
        
        // Define the dynamic body fixture.
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &dynamicBox;
        fixtureDef.density = 1.f;
        fixtureDef.friction = 0.0f;
        fixtureDef.filter.maskBits = 2;
        body->CreateFixture(&fixtureDef);
        
        xts = body;
        
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
    xts->SetTransform(xts->GetPosition(), xts->GetAngle()-angle);
    if(mainSprite != nil)
    {
        mainSprite.rotation = mainSprite.rotation + angle*180/PI;
    }
    
}

-(void)move:(CGPoint)offset
{
    b2Vec2 off = b2Vec2(offset.x,offset.y);
    xts->SetTransform(xts->GetPosition()+off/PTM_RATIO, xts->GetAngle());
    if(mainSprite != nil)
    {
        mainSprite.position = ccp(mainSprite.position.x+off.x,mainSprite.position.y+off.y);
    }
    
}

-(void)setBodyPosition:(CGPoint)position
{
    xts->SetTransform(b2Vec2(position.x/PTM_RATIO,position.y/PTM_RATIO), xts->GetAngle());
    if(mainSprite != nil)
    {
        mainSprite.position = position;
    }
    
}

//计算吸铁石对水滴粒子的吸力情况
-(void)comupteAttractiveForceFromXTS:(int)numParticles waterParticle:(sParticle*)liquid
{    
    //1 求点到吸铁石的距离
    float distance;
    float xtsAngle = xts->GetAngle();
    for (int32 i = 0; i < numParticles; ++i)
    {
        if(liquid[i].isAwake == false)continue;
        distance = (liquid[i].mPosition-xts->GetPosition()).Length();
        if(distance > 8.f) continue;
        //曲面向磁力的边的宽的中心点坐标 这里 默认的由磁力的方向为左边
        b2Vec2 cilPoint = b2Vec2(xts->GetPosition().x-1.f*cos(xtsAngle),xts->GetPosition().y-1.f*sin(xtsAngle));

        //求水滴到中心点到之间的夹角大小 如果为－30～30度 表示其受引力影响 扇形弧度为60度夹角
        float jiaAngle = [CCXiTieShi acosAngle:ccp(liquid[i].mPosition.x*PTM_RATIO,liquid[i].mPosition.y*PTM_RATIO)
                                        cicleCenter:ccp(xts->GetPosition().x*PTM_RATIO,xts->GetPosition().y*PTM_RATIO)
                                          lastPoint:ccp(cilPoint.x*PTM_RATIO,cilPoint.y*PTM_RATIO)
                          ];
        
        if((jiaAngle <= PI/6.f ) && fabs(jiaAngle) > eps )// || (jiaAngle <= -PI*5.f/6.f))
        {
            //水滴受力
            b2Vec2 force;
            float forceFactor = 6.f - distance;
            b2Vec2 disNorlize = b2Vec2((xts->GetPosition().x - liquid[i].mPosition.x),(xts->GetPosition().y - liquid[i].mPosition.y));
            disNorlize.Normalize();
            //越近 给的力越大 极限距离为 2.f 取反向偏差
            if(forceFactor > 4.f )//&& fabs(jiaAngle) < PI/10.f)
            {
                //float totalForce = forceFactor*2;//暂时给这么大的总受力
                //force = -5*b2Vec2((xts->GetPosition().x - liquid[i].mPosition.x)/distance*totalForce,(xts->GetPosition().y - liquid[i].mPosition.y)/distance*totalForce);
                
                force = -10.f*forceFactor*forceFactor*disNorlize;
            }
            else
            {
                //float totalForce = forceFactor*4;//暂时给这么大的总受力
                //force = b2Vec2((xts->GetPosition().x - liquid[i].mPosition.x)/distance*totalForce,(xts->GetPosition().y - liquid[i].mPosition.y)/distance*totalForce);
                
                force = 1.5f*(distance*distance/2.f)*disNorlize;
            }
            liquid[i].mForce += (force - m_world->GetGravity());
            
        }
    }
    
}

-(void)update:(ccTime)dt
{
    if(m_numParticles > 0 && m_liquid != NULL)
    {
        [self comupteAttractiveForceFromXTS:m_numParticles waterParticle:m_liquid];
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
    m_world->DestroyBody(xts);
    if(mainSprite != nil)
    {
        [mainSprite removeFromParentAndCleanup:YES];
    }
    
	// don't forget to call "super dealloc"
	[super dealloc];
    
}

@end
