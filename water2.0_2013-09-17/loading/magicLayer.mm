
//
//  DefaultLoadingLayer.m
//  wf
//
//  Created by 李 智 on 13-8-31.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//


#import "magicLayer.h"
#import "initAnimationLayer.h"

@implementation magicLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	magicLayer *layer = [magicLayer node];
	
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
    
    CCSprite *bk = [CCSprite spriteWithFile:@"initAni4_bk.png"];
    bk.position = ccp(screenSize.width/2,screenSize.height/2);
    [self addChild:bk];
    
    CCSprite *magician = [CCSprite spriteWithFile:@"initAni4_moun.png"];
    magician.position = ccp(screenSize.width/2-100,screenSize.height/2-180);
    [self addChild:magician];
    id magicianAc1 = [CCMoveBy actionWithDuration:6 position:ccp(10, 20)];
    id magicianAc2 = [CCScaleTo actionWithDuration:6 scale:1.04];
    id ac1 = [CCSpawn actions:magicianAc1,magicianAc2,nil];
    id ac2 = [CCCallFunc actionWithTarget:self selector:@selector(actionOverCallFunc)];
    [magician runAction:[CCSequence actions:ac1,ac2,nil]];
    
    CCSprite *fluid = [CCSprite spriteWithFile:@"initAni4_water.png"];
    fluid.position = ccp(screenSize.width/2,screenSize.height/2+40);
    [self addChild:fluid];
    id fluidAc1 = [CCRotateTo actionWithDuration:6.0f angle:10];
    id fluidAc2 = [CCScaleTo actionWithDuration:6.0f scale:1.2];
    id fluidAc3 = [CCMoveBy actionWithDuration:4.0f position:ccp(10, 30)];
    id fluidAc4 = [CCSpawn actions:fluidAc1,fluidAc2,fluidAc3,nil];
    [fluid runAction:fluidAc4];
    
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
