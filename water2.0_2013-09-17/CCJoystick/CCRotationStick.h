//
//  CCRorationStick.h
//  WaterSprite4
//
//  Created by zte-s on 13-5-29.
//  Copyright 2013年 zte. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "sphFluid.h"
#import "sphSmoke.h"



#define PI 3.1415926535897
#define RotationSpeed 1//.f
#define AngToRadian(angle)  PI*angle*RotationSpeed/180.f


@protocol CCRotationStickDelegate <NSObject>
@optional
-(void)rotation:(float)angle;
-(void)move:(CGPoint)offset;
@end

@interface CCRotationStick : CCLayer<CCMouseEventDelegate>
{
    CCSprite *innerCircle;
    CCSprite *outerCircle;
    id mouseDelegate;
    float innerRadius;
    float outerRadius;
    CGPoint stickPosition;
    
    CGPoint prevPoint;
    
    BOOL ifmouseEventTranslateToOther ;
    int gestureType;//手势类型 1 旋转 2移动
    
    //不可放置区域
    b2Vec2 *unusedSection1;
    int unusedSection1VecNum;
    
    //回归区域和半径
    CGPoint disappearSection;
    float disappearRadius;
}

@property(assign,nonatomic)CGPoint  stickPosition;
@property(assign,nonatomic)CGPoint disappearSection;
@property(assign,nonatomic)float disappearRadius;
@property(assign,nonatomic)CCSprite *innerCircle;
@property(assign,nonatomic)CCSprite *outerCircle;
@property(assign,nonatomic)b2Vec2 *unusedSection1;
@property(assign,nonatomic)int unusedSection1VecNum;


-(void)updateNewPosition:(CGPoint)newPosition;

-(id)initWithCircle:(CCSprite *)innerS outerCircle:(CCSprite *)outerS innerRadius:(float)innerR outerRadius:(float)outerR position:(CGPoint)ps delegate:(id)mouseD;

-(float)rotationEvent:(CGPoint)previousPoint curPoint:(CGPoint)currentPoint;

+(float)acosAngle:(CGPoint)p1 cicleCenter:(CGPoint)p2 lastPoint:(CGPoint)p3;
+(float)asinAngle:(CGPoint)p1 cicleCenter:(CGPoint)p2 lastPoint:(CGPoint)p3;





@end
