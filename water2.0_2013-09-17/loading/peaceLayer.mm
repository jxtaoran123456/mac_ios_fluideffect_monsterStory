
//
//  DefaultLoadingLayer.m
//  wf
//
//  Created by 李 智 on 13-8-31.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//


#import "peaceLayer.h"
#import "initAnimationLayer.h"

@implementation peaceLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	peaceLayer *layer = [peaceLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
    
}

-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init]))
    {
        self.scale = 4.f;
        self.anchorPoint = ccp(0.4,0.8);
        self.position = ccp(512,576);
        [self addAnimation];
    }
    return self;
    
}

-(void) tick: (ccTime) dt
{
    
    
}

-(void)addAnimation
{
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    
    CCSprite *bk = [CCSprite spriteWithFile:@"initAni3_bk.png"];
    bk.position = ccp(screenSize.width/2,screenSize.height/2);
    [self addChild:bk];
    
    CCSprite *zhong = [CCSprite spriteWithFile:@"initAni3_zhong.png"];
    //zhong.anchorPoint = ccp(.5f,.5f);
    zhong.anchorPoint = ccp(.5f,1.f);
    zhong.position = ccp(564.f,452.f);
    [self addChild:zhong];
    state = 1;
    id zhongAc1 = [CCRotateTo actionWithDuration:1.0f angle:20];
    id zhongAc2 = [CCRotateTo actionWithDuration:1.0f angle:-20];
    id zhongAc3 = [CCSequence actions:zhongAc1, zhongAc2, nil];
    id ac1 = [CCRepeat actionWithAction:zhongAc3 times:6];
    id ac2 = [CCCallFunc actionWithTarget:self selector:@selector(actionOverCallFunc)];
    [zhong runAction:[CCRepeat actionWithAction:[CCSequence actions:ac1,ac2,nil] times:4]];
    
    CCSprite *person1 = [CCSprite spriteWithFile:@"initAni3_person1.png"];
    person1.position = ccp(screenSize.width/2-160,screenSize.height/2-180);
    [self addChild:person1 z:2];
    
    CCSprite *person2 = [CCSprite spriteWithFile:@"initAni3_person2.png"];
    person2.position = ccp(screenSize.width/2+60,screenSize.height/2-180);
    [self addChild:person2 z:1];
    
    CCSprite *person3 = [CCSprite spriteWithFile:@"initAni3_person3.png"];
    person3.position = ccp(screenSize.width/2+500,screenSize.height/2-100);
    [self addChild:person3];
    
    id scaleAni =  [CCScaleTo actionWithDuration:5 scale:1];
    [self runAction:scaleAni];
    
}




// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}


@end
