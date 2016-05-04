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


@interface CCShiZi:CCTool
{
    b2Body * ten1;
    b2Body * ten2;
    
    //1顺时针 －1逆时针
    int clockDirector;
    float angleSpeed;
    
}


@end
