//
//  DefaultLoadingLayer.h
//  wf
//
//  Created by 李 智 on 13-8-31.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface DefaultLoadingLayer : CCLayer
{
    CCSprite *defaultSpr;
    CCSprite *defaultSpr2;
    
    int tickCount;
}

+(CCScene *) scene;

@end
