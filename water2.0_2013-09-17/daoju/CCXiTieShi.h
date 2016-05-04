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


@interface CCXiTieShi:CCTool
{
    b2Body *xts;
    
}



//计算吸铁石对水滴粒子的吸力情况
-(void)comupteAttractiveForceFromXTS:(int)numParticles waterParticle:(sParticle*)liquid;
+(float)acosAngle:(CGPoint)p1 cicleCenter:(CGPoint)p2 lastPoint:(CGPoint)p3;

@end
