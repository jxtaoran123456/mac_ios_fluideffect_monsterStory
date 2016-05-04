//
//  CCTool.h
//  water2.0_2013-09-17
//
//  Created by 李 智 on 13-10-5.
//  Copyright 2013年 李 智. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "CCRotationStick.h"

#define PTM_RATIO 32.f
#define eps 1e-8

@interface CCTool : CCLayer<CCMouseEventDelegate,CCRotationStickDelegate> 
{
    CCRotationStick *rStick;
    CCSprite *mainSprite;
    
    BOOL ifContinue;
    int type;//1电风扇 2吸铁石 3漩涡
    
    int m_numParticles;
    sParticle* m_liquid;
    
    
}

@property(assign,nonatomic) CCSprite *mainSprite;
@property(assign,nonatomic) BOOL ifContinue;
@property(assign,nonatomic) CCRotationStick *rStick;
@property(assign,nonatomic) int type;
@property(assign,nonatomic) int m_numParticles;
@property(assign,nonatomic) sParticle* m_liquid;

-(id)initPhysical:(CGPoint)ps event:(NSEvent*)event;
-(void)rotation:(float)angle;
-(void)move:(CGPoint)offset;
-(void)setBodyPosition:(CGPoint)position;

@end
