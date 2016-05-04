//
//  DefaultLoadingLayer.h
//  wf
//
//  Created by 李 智 on 13-8-31.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface initAnimationLayer : CCLayer
{
    //ani shunxu 3 2 1 6 5
    int curAniIndex;
}
@property (assign,nonatomic) int curAniIndex;;

+(CCScene *) scene;

-(void)peaceAni;
-(void)monster;
-(void)invade;
-(void)magic;
-(void)night;

-(void)nextAni:(int)aniIndex;

@end
