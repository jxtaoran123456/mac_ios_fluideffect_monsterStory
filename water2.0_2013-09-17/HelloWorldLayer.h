//
//  HelloWorldLayer.h
//  water2.0_2013-09-17
//
//  Created by 李 智 on 13-9-17.
//  Copyright 李 智 2013年. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer
{
	CCTexture2D *spriteTexture_;	// weak ref
	b2World* world;					// strong ref
	GLESDebugDraw *m_debugDraw;		// strong ref
}
@end


@interface PhysicsSprite : CCSprite
{
	b2Body *body_;	// strong ref
}
-(void) setPhysicsBody:(b2Body*)body;
@end