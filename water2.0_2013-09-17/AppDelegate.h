//
//  AppDelegate.h
//  water2.0_2013-09-17
//
//  Created by 李 智 on 13-9-17.
//  Copyright 李 智 2013年. All rights reserved.
//

#import "cocos2d.h"

@interface water2_0_2013_09_17AppDelegate : NSObject <NSApplicationDelegate>
{
	NSWindow	*window_;
	CCGLView	*glView_;
}

@property (assign) IBOutlet NSWindow	*window;
@property (assign) IBOutlet CCGLView	*glView;

- (IBAction)toggleFullScreen:(id)sender;

@end
