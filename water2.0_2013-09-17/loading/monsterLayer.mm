
//
//  DefaultLoadingLayer.m
//  wf
//
//  Created by 李 智 on 13-8-31.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//


#import "monsterLayer.h"
#import "initAnimationLayer.h"

@implementation monsterLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	monsterLayer *layer = [monsterLayer node];
	
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
    
    CCSprite *bk = [CCSprite spriteWithFile:@"initAni2_bk1.png"];
    bk.position = ccp(screenSize.width/2,screenSize.height/2);
    [self addChild:bk];
    
    CCSprite *monster1 = [CCSprite spriteWithFile:@"initAni2_monsterSha.png"];
    monster1.position = ccp(screenSize.width/2,screenSize.height/2-150);
    [self addChild:monster1];
    id monster1Ac1 = [CCScaleTo actionWithDuration:5.0 scale:1.1];
    //id monster1Ac2 = [CCScaleTo actionWithDuration:1.0 scale:1.];
    id monster1Ac3 = [CCSequence actions:monster1Ac1,nil];
    id monster1Ac4 = [CCRepeatForever actionWithAction:monster1Ac3];
    [monster1 runAction:monster1Ac4];
    
    CCSprite *monster2 = [CCSprite spriteWithFile:@"initAni2_gbl.png"];
    monster2.position = ccp(screenSize.width/2,screenSize.height/2-220);
    [self addChild:monster2];
    monster2.scale = 0.9;
    id monster2Ac1 = [CCScaleTo actionWithDuration:5.0 scale:1.0];
    [monster2 runAction:monster2Ac1];
    
    CCSprite *lady = [CCSprite spriteWithFile:@"initAni2_lady.png"];
    lady.position = ccp(screenSize.width/2+100,screenSize.height/2-80);
    [self addChild:lady];
    id ladyAc1 = [CCMoveBy actionWithDuration:5 position:ccp(190, 120)];
    id ladyAc2 = [CCScaleTo actionWithDuration:5 scale:1.1];
    id ac1 = [CCSpawn actions:ladyAc1,ladyAc2,nil];
    id ac2 = [CCCallFunc actionWithTarget:self selector:@selector(actionOverCallFunc)];
    [lady runAction:[CCSequence actions:ac1,ac2,nil]];
    
    CCSprite *boy = [CCSprite spriteWithFile:@"initAni2_rightBoy.png"];
    boy.position = ccp(screenSize.width/2-120,screenSize.height/2);
    [self addChild:boy];
    id boyAc1 = [CCMoveBy actionWithDuration:4.5 position:ccp(-30, -90)];
    id boyAc2 = [CCRotateTo actionWithDuration:4.5 angle:-10];
    //id boyAc2 = [CCScaleTo actionWithDuration:3.5 scale:0.9];
    [boy runAction:[CCSpawn actions:boyAc1,boyAc2,nil]];
    
    CCSprite *box1 = [CCSprite spriteWithFile:@"initAni2_box1.png"];
    box1.position = ccp(screenSize.width/2-420,screenSize.height/2-200);
    [self addChild:box1];
    id box1Ac1 = [CCMoveBy actionWithDuration:4.5 position:ccp(-5, 0)];
    id box1Ac2 = [CCRotateTo actionWithDuration:4.5 angle:-2];
    [box1 runAction:[CCSpawn actions:box1Ac1,box1Ac2,nil]];
    
    CCSprite *box2 = [CCSprite spriteWithFile:@"initAni2_box2.png"];
    box2.position = ccp(screenSize.width/2-240,screenSize.height/2-140);
    [self addChild:box2];
    id box2Ac1 = [CCMoveBy actionWithDuration:4.5 position:ccp(-8, 0)];
    id box2Ac2 = [CCRotateTo actionWithDuration:4.5 angle:-2];
    [box2 runAction:[CCSpawn actions:box2Ac1,box2Ac2,nil]];
    
    CCSprite *tong1 = [CCSprite spriteWithFile:@"initAni2_tong2.png"];
    tong1.position = ccp(screenSize.width/2-280,screenSize.height/2+60);
    [self addChild:tong1];
    id tong1Ac1 = [CCMoveBy actionWithDuration:4.5 position:ccp(-52, 5)];
    id tong1Ac2 = [CCRotateTo actionWithDuration:4.5 angle:-12];
    [tong1 runAction:[CCSpawn actions:tong1Ac1,tong1Ac2,nil]];
    
    CCSprite *tong2 = [CCSprite spriteWithFile:@"initAni2_tong.png"];
    tong2.position = ccp(screenSize.width/2-380,screenSize.height/2-80);
    [self addChild:tong2];
    id tong2Ac1 = [CCMoveBy actionWithDuration:4.5 position:ccp(-15, -16)];
    id tong2Ac2 = [CCRotateTo actionWithDuration:4.5 angle:-15];
    [tong2 runAction:[CCSpawn actions:tong2Ac1,tong2Ac2,nil]];
    
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
