//
//  CCShiZi.h
//  WaterSprite4
//
//  Created by zte- s on 13-6-2.
//  Copyright 2013年 zte. All rights reserved.
//

#import "CCTool.h"

class b2World;

extern b2World* m_world;


@interface CCXuanWo:CCTool
{
    b2Body *xw;
    int xwBodyType;
    
    b2Vec2 *mapVerts;
    int mapVertsNum;
    
    //1顺时针 －1逆时针
    int clockDirector;
}


//计算吸铁石对水滴粒子的吸力情况
-(void)comupteAttractiveForceFromXW:(int)numParticles waterParticle:(sParticle*)liquid;
+(float)acosAngle:(CGPoint)p1 cicleCenter:(CGPoint)p2 lastPoint:(CGPoint)p3;

@end
