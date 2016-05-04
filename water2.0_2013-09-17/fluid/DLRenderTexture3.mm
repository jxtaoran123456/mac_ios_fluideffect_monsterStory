//
//  DLRenderTexture.m
//  wf
//
//  Created by 李 智 on 13-8-22.
//
//

#import "DLRenderTexture3.h"

@implementation DLRenderTexture3


- (void)draw
{
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, .9f);
    
}

@end
