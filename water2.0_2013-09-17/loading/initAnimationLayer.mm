
//
//  DefaultLoadingLayer.m
//  wf
//
//  Created by 李 智 on 13-8-31.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "DefaultLoadingLayer.h"
#import "initAnimationLayer.h"
#import "peaceLayer.h"
#import "monsterLayer.h"
#import "invadeLayer.h"
#import "nightLayer.h"
#import "magicLayer.h"


@implementation initAnimationLayer
@synthesize curAniIndex;

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	initAnimationLayer *layer = [initAnimationLayer node];
	
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
        [self peaceAni];
    }
    return self;
    
}

-(BOOL) ccMouseDown:(NSEvent *)event
{
    return NO;
    
}

-(void) tick: (ccTime) dt
{
    
    
}

-(void)peaceAni
{
    //CGSize screenSize = [CCDirector sharedDirector].winSize;
    peaceLayer *pl = [peaceLayer node];
    pl.delegateLayer = self;
    pl.position = CGPointZero;//ccp(screenSize.width/2,screenSize.height/2);
    [self addChild:pl];
    
}

-(void)monster
{
    monsterLayer *ml = [monsterLayer node];
    ml.delegateLayer = self;
    ml.position = CGPointZero;
    [self addChild:ml];
    
}

-(void)invade
{
    invadeLayer *il = [invadeLayer node];
    il.delegateLayer = self;
    il.position = CGPointZero;
    [self addChild:il];
    
}

-(void)magic
{       magicLayer *ml = [magicLayer node];
    ml.delegateLayer = self;
    ml.position = CGPointZero;
    [self addChild:ml];
}

-(void)night
{
    nightLayer *nl = [nightLayer node];
    nl.delegateLayer = self;
    nl.position = CGPointZero;
    [self addChild:nl];
}



-(void)nextAni:(int)aniIndex
{
    if(aniIndex == 0)
    {
        [self peaceAni];
    }
    else if(aniIndex == 1)
    {
        [self monster];
    }
    else if(aniIndex == 2)
    {
        [self invade];
    }
    else if(aniIndex == 3)
    {
        [self night];
    }
    else if(aniIndex == 4)
    {
        [self magic];
    }
    else
    {
        self.curAniIndex = 0 ;
        CCScene *scene = [DefaultLoadingLayer scene];
        [(CCDirectorMac*)[CCDirector sharedDirector] replaceScene:(CCScene *)[CCTransitionFade transitionWithDuration:1.f scene:scene]];
    }
    
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
