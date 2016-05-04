//
//  CCShiZi.m
//  WaterSprite4
//
//  Created by zte- s on 13-6-2.
//  Copyright 2013年 zte. All rights reserved.
//

#import "CCDianFengShan.h"


@implementation CCDianFengShan
@synthesize mapVerts,mapVertsNum;

-(id)initPhysical:(CGPoint)ps event:(NSEvent*)event
{
    if( (self=[super init])) 
    {
        type = 1;
        
        mainSprite = [CCSprite spriteWithFile:@"xts.jpg"];
        mainSprite.scale = 0.15;
        mainSprite.rotation = 180;
        mainSprite.position = ps;
        [self addChild:mainSprite];
        if(rStick == nil)
        {
            CCSprite *ineerS = [CCSprite spriteWithFile:@"inner.png"];
            CCSprite *outerS = [CCSprite spriteWithFile:@"outer.png"];
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
        fixtureDef.density = 0.1f;
        fixtureDef.friction = 0.0f;
        fixtureDef.filter.maskBits = 2;
        body->CreateFixture(&fixtureDef);
        
        dfs = body;
        
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
    dfs->SetTransform(dfs->GetPosition(), dfs->GetAngle()-angle);
    if(mainSprite != nil)
    {
        mainSprite.rotation = mainSprite.rotation + angle*180/PI;
    }
    
}

-(void)move:(CGPoint)offset
{
    b2Vec2 off = b2Vec2(offset.x,offset.y);
    dfs->SetTransform(dfs->GetPosition()+off/PTM_RATIO, dfs->GetAngle());
    if(mainSprite != nil)
    {
        mainSprite.position = ccp(mainSprite.position.x+off.x,mainSprite.position.y+off.y);
    }
    
}

-(void)setBodyPosition:(CGPoint)position
{
    dfs->SetTransform(b2Vec2(position.x/PTM_RATIO,position.y/PTM_RATIO), dfs->GetAngle());
    if(mainSprite != nil)
    {
        mainSprite.position = position;
    }
    
}

//计算电风扇力情况
-(void)comupteAttractiveForceFromDFS:(int)numParticles waterParticle:(sParticle*)liquid  
{    
    //1 求点到电风扇的距离
    float distance;
    float dfsAngle = dfs->GetAngle();
//    windTick++;
//    if(windTick % 2 == 0)return;
    
    //曲面向磁力的边的宽的中心点坐标 这里 默认的由磁力的方向为左边
    b2Vec2 cilPoint = b2Vec2(dfs->GetPosition().x-1.f*cos(dfsAngle),dfs->GetPosition().y-1.f*sin(dfsAngle));
    
    //if([CCDianFengShan pointRedressOutEdge:cilPoint mapVerts:mapVerts mapVertsNum:mapVertsNum] == -1)return;//风力点在闭合区间外部  不计算风力影响
    
    //int windStrengthFactor = 2+rand()%8;
    float windStrengthFactor = windStrengthFactor + 0.5;
    if(windStrengthFactor >= 8.0)windStrengthFactor = 2.0f;
    for (int32 i = 0; i < numParticles; ++i)
    {
        if(liquid[i].isAwake == false)continue;
        distance = (liquid[i].mPosition-dfs->GetPosition()).Length();

        if(distance > 8.f)continue;
        
        b2Vec2 disNormalize = liquid[i].mPosition-dfs->GetPosition();
        disNormalize.Normalize();
        //求水滴到中心点到之间的夹角大小 如果为－30～30度 表示其受引力影响 扇形弧度为60度夹角
        float jiaAngle = [CCDianFengShan acosAngle:ccp(liquid[i].mPosition.x*PTM_RATIO,liquid[i].mPosition.y*PTM_RATIO)
                                        cicleCenter:ccp(dfs->GetPosition().x*PTM_RATIO,dfs->GetPosition().y*PTM_RATIO)
                                          lastPoint:ccp(cilPoint.x*PTM_RATIO,cilPoint.y*PTM_RATIO)
                          ];
        if((jiaAngle <= PI/8.f && fabs(jiaAngle) > eps) )//|| (jiaAngle <= -PI*5.f/6.f))
        {
            liquid[i].mForce += (disNormalize*30 - m_world->GetGravity());
        }
    }
    
    for (int32 i = 0; i < smnParticles; ++i)
    {
        if(smliquid[i].isAwake == false)continue;
        distance = (smliquid[i].mPosition-dfs->GetPosition()).Length();
        
        if(distance > 8.f)continue;
        
        b2Vec2 disNormalize = smliquid[i].mPosition-dfs->GetPosition();
        disNormalize.Normalize();
        //求水滴到中心点到之间的夹角大小 如果为－30～30度 表示其受引力影响 扇形弧度为60度夹角
        float jiaAngle = [CCDianFengShan acosAngle:ccp(smliquid[i].mPosition.x*PTM_RATIO,smliquid[i].mPosition.y*PTM_RATIO)
                                       cicleCenter:ccp(dfs->GetPosition().x*PTM_RATIO,dfs->GetPosition().y*PTM_RATIO)
                                         lastPoint:ccp(cilPoint.x*PTM_RATIO,cilPoint.y*PTM_RATIO)
                          ];
        if((jiaAngle <= PI/8.f && fabs(jiaAngle) > eps) )//|| (jiaAngle <= -PI*5.f/6.f))
        {
            smliquid[i].mForce += disNormalize*30 ;//- m_world->GetGravity());
        }
        
    }
    
}

-(void)update:(ccTime)dt
{
    if(m_numParticles > 0 && m_liquid != NULL)
    {
        [self comupteAttractiveForceFromDFS:m_numParticles waterParticle:m_liquid];
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

+(int) pointRedressOutEdge:(b2Vec2)vertsPoint mapVerts:(b2Vec2 *)verts mapVertsNum:(int)vertsNum
{
    bool result = false;
    for(int i=0; i < vertsNum; ++i)
    {
        float c1 = (verts[ i+1 ].x - vertsPoint.x)*(vertsPoint.y - verts[ i ].y);
        float c2 = (verts[ i+1 ].y - vertsPoint.y)*(vertsPoint.x - verts[ i ].x);
        
        //判断点是否在线段边上或者线段顶端 如果在的话 直接还原
        if(fabs(c1 - c2) <= eps)
        {
            return vertsNum;
        }
        
        if( (
             ( ( verts[ i + 1 ].y <= vertsPoint.y ) && ( vertsPoint.y < verts[ i ].y ) )
             || ( ( verts[ i ].y <= vertsPoint.y ) && ( vertsPoint.y < verts[ i + 1 ].y ) )
             )
           &&
           ( vertsPoint.x < ( verts[ i ].x - verts[ i + 1 ].x ) * ( vertsPoint.y - verts[ i + 1 ].y ) / ( verts[ i ].y - verts[ i + 1 ].y ) + verts[ i + 1 ].x )
           )
        {
            result = !result;
        }
        
        {
            result = !result;
        }
    }
    return (result == false)?-1:-2;//false表示在闭合区间外部 -1 外部 -2 内部 因为有可能涉及到第一条线段 0 所以不用0返回
    
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
    
    [rStick removeFromParentAndCleanup:YES];
    m_world->DestroyBody(dfs);
    if(mainSprite != nil)
    {
        [mainSprite removeFromParentAndCleanup:YES];
    }
    
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end
