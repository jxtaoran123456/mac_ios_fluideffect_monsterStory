
//
//  DefaultLoadingLayer.m
//  wf
//
//  Created by 李 智 on 13-8-31.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//


#import "invadeLayer.h"
#import "initAnimationLayer.h"

@implementation invadeLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	invadeLayer *layer = [invadeLayer node];
	
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
    
    CCSprite *bk = [CCSprite spriteWithFile:@"initAni1_bk1.png"];
    bk.position = ccp(screenSize.width/2,screenSize.height/2);
    [self addChild:bk];
    
    CCParticleSystem* smokeParticle = [CCParticleSystemQuad particleWithFile:@"smoke2.plist"];
    smokeParticle.positionType = kCCPositionTypeFree;
    smokeParticle.position = ccp(370,420);
    smokeParticle.scale = 0.8;
    [self addChild:smokeParticle];
    
    CCParticleSystem* fireParticle = [CCParticleSystemQuad particleWithFile:@"fire4.plist"];
    fireParticle.positionType = kCCPositionTypeFree;
    fireParticle.position = ccp(370,400);
    fireParticle.scale = 0.2;
    [self addChild:fireParticle];

    CCSprite *cow = [CCSprite spriteWithFile:@"initAni1_cow.png"];
    cow.position = ccp(screenSize.width/2-100,screenSize.height/2);
    [self addChild:cow];
    id cowAc1 = [CCMoveBy actionWithDuration:4.0 position:ccp(10, 10)];
    [cow runAction:cowAc1];
    
    CCSprite *monster = [CCSprite spriteWithFile:@"initAni1_monster.png"];
    monster.position = ccp(screenSize.width/2-60,screenSize.height/2-30);
    [self addChild:monster];
    id monsterAc1 = [CCMoveBy actionWithDuration:6.0 position:ccp(0, 10)];
    id monsterAc2 = [CCScaleTo actionWithDuration:6.0 scale:1.06];
    id ac1 = [CCSpawn actions:monsterAc1, monsterAc2,nil];
    id ac2 = [CCCallFunc actionWithTarget:self selector:@selector(actionOverCallFunc)];
    [monster runAction:[CCSequence actions:ac1,ac2,nil]];
    //[monster runAction:ac1];
    
    CCSprite *horse = [CCSprite spriteWithFile:@"initAni1_horse.png"];
    horse.position = ccp(screenSize.width/2+300,screenSize.height/2-100);
    [self addChild:horse];
    id horseAc1 = [CCMoveBy actionWithDuration:4.0 position:ccp(-25, 0)];
    [horse runAction:horseAc1];
    
    CCSprite *chc = [CCSprite spriteWithFile:@"initAni1_chc.png"];
    chc.position = ccp(screenSize.width/2-320,screenSize.height/2-180);
    [self addChild:chc];
    id chcAc1 = [CCMoveBy actionWithDuration:4.5 position:ccp(15, -20)];
    id chcAc2 = [CCScaleTo actionWithDuration:4.5 scale:0.95];
    id chcAc3 = [CCSpawn actions:chcAc1, chcAc2,nil];
    [chc runAction:chcAc3];
    
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
