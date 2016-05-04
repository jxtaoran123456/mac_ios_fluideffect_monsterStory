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


@interface CCDianFengShan:CCTool
{
    b2Body *dfs;
    
    b2Vec2 *mapVerts;//记住 这块赋予的连线必须形成一个合理的闭合区域
    int mapVertsNum;
    
    int windTick;

}
@property(assign,nonatomic) BOOL ifContinue;
@property(assign,nonatomic) b2Vec2 *mapVerts;
@property(assign,nonatomic) int mapVertsNum;


//计算吸铁石对水滴粒子的吸力情况
-(void)comupteAttractiveForceFromDFS:(int)numParticles waterParticle:(sParticle*)liquid;
+(float)acosAngle:(CGPoint)p1 cicleCenter:(CGPoint)p2 lastPoint:(CGPoint)p3;
+(int) pointRedressOutEdge:(b2Vec2)vertsPoint mapVerts:(b2Vec2 *)verts mapVertsNum:(int)vertsNum;

@end
