//
//  CCMutableSprite.m
//  wf
//
//  Created by 李 智 on 13-9-13.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "CCMutableSprite.h"


@implementation CCMutableSprite

+(id)spriteWithFile:(NSString*)filename
{
    return [[[self alloc] initWithFile:filename] autorelease];
    
}

-(id) initWithFile:(NSString*)filename
{
	NSAssert(filename!=nil, @"Invalid filename for sprite");
    
	CCTexture2DMutable *texture = [[CCTextureCache sharedTextureCache] addImage: filename];
	if( texture ) {
		CGRect rect = CGRectZero;
		rect.size = texture.contentSize;
		return [self initWithTexture:texture rect:rect];
	}
    
	[self release];
	return nil;
}

+(id)spriteWithTexture:(CCTexture2DMutable*)texture
{
	return [[[self alloc] initWithTexture:texture] autorelease];
}

-(id) initWithTexture:(CCTexture2DMutable*)texture
{
	NSAssert(texture!=nil, @"Invalid texture for sprite");
    
	CGRect rect = CGRectZero;
	rect.size = texture.contentSize;
	return [self initWithTexture:texture rect:rect];
}

-(id) initWithTexture:(CCTexture2DMutable*)texture rect:(CGRect)rect
{
    NSAssert(texture!=nil, @"Invalid texture for sprite");
	// IMPORTANT: [self init] and not [super init];
	if( (self = [self init]) )
	{
		[self setTexture:texture];
		[self setTextureRect:rect];
	}
	return self;
}

-(void) setTexture:(CCTexture2DMutable*)texture
{
	NSAssert( ! usesBatchNode_, @"CCSprite: setTexture doesn't work when the sprite is rendered using a CCSpriteBatchNode");
	
	// accept texture==nil as argument
	NSAssert( !texture || [texture isKindOfClass:[CCTexture2D class]], @"setTexture expects a CCTexture2D. Invalid argument");
    
	[texture_ release];
	texture_ = [texture retain];
	
	[self updateBlendFunc];
}

-(void) updateBlendFunc
{
	NSAssert( ! usesBatchNode_, @"CCSprite: updateBlendFunc doesn't work when the sprite is rendered using a CCSpriteBatchNode");
    
	// it's possible to have an untextured sprite
	if( !texture_ || ! [texture_ hasPremultipliedAlpha] ) {
		blendFunc_.src = GL_SRC_ALPHA;
		blendFunc_.dst = GL_ONE_MINUS_SRC_ALPHA;
		[self setOpacityModifyRGB:NO];
	} else {
		blendFunc_.src = CC_BLEND_SRC;
		blendFunc_.dst = CC_BLEND_DST;
		[self setOpacityModifyRGB:YES];
	}
    
}

@end
