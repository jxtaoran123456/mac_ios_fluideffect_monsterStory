
//
//  DefaultLoadingLayer.m
//  wf
//
//  Created by 李 智 on 13-8-31.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//


#import "nightLayer.h"
#import "initAnimationLayer.h"

@implementation nightLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	nightLayer *layer = [nightLayer node];
	
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
    
    CCSprite *bk = [CCSprite spriteWithFile:@"initAni6_bk.png"];
    bk.position = ccp(screenSize.width/2,screenSize.height/2);
    [self addChild:bk];
    
    CCSprite *bk2 = [CCSprite spriteWithFile:@"initAni6_bk2.png"];
    bk2.position = ccp(screenSize.width/2,screenSize.height/2);
    [self addChild:bk2];
    
    CCSprite *cloud = [CCSprite spriteWithFile:@"initAni6_cloud.png"];
    cloud.position = ccp(screenSize.width/2,screenSize.height/2+280);
    [self addChild:cloud];
    id cloudAc1 = [CCMoveBy actionWithDuration:10.0 position:ccp(-400, 10)];
    id ac2 = [CCCallFunc actionWithTarget:self selector:@selector(actionOverCallFunc)];
    [cloud runAction:[CCSequence actions:cloudAc1,ac2,nil]];
    //[cloud runAction:cloudAc1];
    
    CCParticleSystem* smokeParticle = [CCParticleSystemQuad particleWithFile:@"nightSmoke1.plist"];
    smokeParticle.positionType = kCCPositionTypeFree;
    smokeParticle.position = ccp(1320,740);
    smokeParticle.scale = 1.1;
    [self addChild:smokeParticle];
    
    
    
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
