//
//  SDEWindowController.h
//  ned mac
//
//  Created by thrust on 11/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SDECustomView;


@interface SDEWindowController : NSWindowController {
	SDECustomView *renderView;
}

-(id) initWithFrame:(NSRect)aFrame;
-(id) initWithFrame:(NSRect)aFrame image:(NSImage *)anImage;
-(id) initWithFrame:(NSRect)aFrame image:(NSImage *)anImage level:(CGWindowLevel)level;
//-(id) initWithImage:(NSImage *)anImage;
-(void) setImage:(NSImage *)image;
-(void) setFrame:(NSRect)frame;

@end
