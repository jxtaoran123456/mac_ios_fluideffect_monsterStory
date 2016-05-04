//
//  AppDelegate.mm
//  water2.0_2013-09-17
//
//  Created by 李 智 on 13-9-17.
//  Copyright 李 智 2013年. All rights reserved.
//


#import "AppDelegate.h"
#import "HelloWorldLayer.h"
#import "HelloWorldLayer.h"
#import "DefaultLoadingLayer.h"
#import "initAnimationLayer.h"
#import "SPHNode.h"

@implementation water2_0_2013_09_17AppDelegate
@synthesize window=window_, glView=glView_;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	CCDirectorMac *director = (CCDirectorMac*) [CCDirector sharedDirector];
	
        [director setAnimationInterval:1.f/40.f];
    
	// enable FPS and SPF
	[director setDisplayStats:YES];
	
	// connect the OpenGL view with the director
	[director setView:glView_];
    
    

	// EXPERIMENTAL stuff.
	// 'Effects' don't work correctly when autoscale is turned on.
	// Use kCCDirectorResize_NoScale if you don't want auto-scaling.
	[director setResizeMode:kCCDirectorResize_AutoScale];
	
	// Enable "moving" mouse event. Default no.
	[window_ setAcceptsMouseMovedEvents:NO];
	
	// Center main window
	[window_ center];

//	CCScene *scene = [CCScene node];
//	[scene addChild:[HelloWorldLayer node]];
//  [director runWithScene:scene];
    [director runWithScene:[initAnimationLayer scene]];//DefaultLoadingLayer initAnimationLayer
	
	
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication
{
	return YES;
}

- (void)dealloc
{
	[[CCDirector sharedDirector] end];
	[window_ release];
	[super dealloc];
}

#pragma mark AppDelegate - IBActions

- (IBAction)toggleFullScreen: (id)sender
{
	CCDirectorMac *director = (CCDirectorMac*) [CCDirector sharedDirector];
	[director setFullScreen: ! [director isFullScreen] ];
}

@end
