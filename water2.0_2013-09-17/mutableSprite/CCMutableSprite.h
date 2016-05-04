//
//  CCMutableSprite.h
//  wf
//
//  Created by 李 智 on 13-9-13.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import <Availability.h>

#import "ccConfig.h"
#import "CCSpriteBatchNode.h"
#import "CCSprite.h"
#import "CCSpriteFrame.h"
#import "CCSpriteFrameCache.h"
#import "CCAnimation.h"
#import "CCAnimationCache.h"
#import "CCTextureCache.h"
#import "CGPointExtension.h"
#import "CCDrawingPrimitives.h"

#import "CCTexture2DMutable.h"

@interface CCMutableSprite : CCSprite
{
    
}

+(id)spriteWithFile:(NSString*)filename;
+(id) spriteWithTexture:(CCTexture2D*)texture;
-(id) initWithTexture:(CCTexture2DMutable*)texture;
-(id) initWithTexture:(CCTexture2DMutable*)texture;
-(id) initWithTexture:(CCTexture2DMutable*)texture rect:(CGRect)rect;
-(void) setTexture:(CCTexture2DMutable*)texture;


@end