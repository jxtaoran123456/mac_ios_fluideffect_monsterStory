//
//  DefaultLoadingLayer.h
//  wf
//
//  Created by 李 智 on 13-8-31.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class initAnimationLayer;

@interface aniLayer : CCLayer
{
    initAnimationLayer *delegateLayer;
    int state;//0 静止 1进行 2完结
}
@property (assign,nonatomic) CCLayer *delegateLayer;

+(CCScene *) scene;

-(void)addAnimation;
-(void)actionOverCallFunc;


@end
