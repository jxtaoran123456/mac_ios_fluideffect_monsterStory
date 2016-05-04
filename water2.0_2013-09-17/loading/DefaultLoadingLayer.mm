
//
//  DefaultLoadingLayer.m
//  wf
//
//  Created by 李 智 on 13-8-31.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "DefaultLoadingLayer.h"
#import "SPHNode.h"
#import "testLv1.h"
#import "testLv2.h"
#import "testLv3.h"
#import "testLv4.h"
#import "testLv5.h"
#import "testLv6.h"
#import "testLv7.h"
#import "testLv8.h"
#import "testLv9.h"
#import "testLv10.h"
#import "testLv11.h"
#import "testLv12.h"
#import "testLv13.h"
#import "testLv14.h"
#import "testLv15.h"
#import "testLv16.h"
#import "testLv17.h"
#import "testLv18.h"
#import "testLv19.h"
#import "testLv20.h"
#import "testLv21.h"
#import "testLv22.h"
#import "testLv23.h"
#import "testLv24.h"
#import "testLv25.h"
#import "testLv26.h"
#import "testLv27.h"
#import "testLv28.h"
#import "testLv29.h"
#import "testLv30.h"
#import "testLv31.h"
#import "testLv32.h"
#import "testLv33.h"

@implementation DefaultLoadingLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	DefaultLoadingLayer *layer = [DefaultLoadingLayer node];
	
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
        self.mouseEnabled = YES;
        defaultSpr = [CCSprite spriteWithFile:@"defaultLoading.png"];
        defaultSpr.anchorPoint = ccp(0,0);
        defaultSpr.position = ccp(0,0);
        [self addChild:defaultSpr z:1];
        
        [self schedule: @selector(tick:)];
        tickCount = 0;
    }
    return self;
    
}

- (BOOL) ccMouseDown:(NSEvent *)event
{
    return NO;
    
}

-(void) tick: (ccTime) dt
{
    tickCount++;
    if(tickCount == 210)
    {
        CCScene *scene = [testLv32 scene];
        [(CCDirectorMac*)[CCDirector sharedDirector] replaceScene:(CCScene *)[CCTransitionFade transitionWithDuration:1.f scene:scene]];
    }
    
}

//
//-(void) draw
//{
// 
//    [self drawRefractive2];
//}
//
//
//-(void)drawRefractive2
//{
//    
//    //if(renderTexture == nil ) return;
//    CGPoint segmentPos[ 6 ];
//	CGPoint texturePos[ 6 ];
//    
//    segmentPos[ 0 ] = ccp(640.f,400.f);
//    segmentPos[ 1 ] = ccp(0.f,0.f);
//    segmentPos[ 2 ] = ccp(1280.f,0.f);
//    segmentPos[ 3 ] = ccp(1280.f,800.f);
//    segmentPos[ 4 ] = ccp(0.f,800.f);
//    segmentPos[ 5 ] = ccp(0.f,0.f);
//    
//    //    texturePos[0] = ccp(.5f,.5f);
//    //    texturePos[1] = ccp(0.f,1.f);
//    //    texturePos[2] = ccp(1.f,1.f);
//    //    texturePos[3] = ccp(1.f,0.f);
//    //    texturePos[4] = ccp(0.f,0.f);
//    //    texturePos[5] = ccp(0.f,1.f);
//    
//    texturePos[0] = ccp(.5f*.625f,.5f*.78125f);
//    texturePos[1] = ccp(0.f*.625f,0.f);
//    texturePos[2] = ccp(1.f*.625f,0.f);
//    texturePos[3] = ccp(1.f*.625f,1.f*.78125f);
//    texturePos[4] = ccp(0.f*.625f,1.f*.78125f);
//    texturePos[5] = ccp(0.f*.625f,0.f);
//    
//    glColor4ub( 255, 0, 0, 255);
//    
//    glEnable( GL_TEXTURE_2D );
//    glBindTexture( GL_TEXTURE_2D, [defaultSpr.texture name]);//levelBK2
//    glEnable(GL_POINT_SPRITE);
//    glTexEnvi( GL_POINT_SPRITE, GL_COORD_REPLACE, GL_TRUE );
//    
//	glDisableClientState(GL_COLOR_ARRAY);
//    //	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
//    
//    //   glDisableClientState( GL_COLOR_ARRAY );
//    
//    glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
//    
//    glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
//    
//    glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
//    
//    glDisable(GL_POINT_SPRITE);
//    
//}

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
