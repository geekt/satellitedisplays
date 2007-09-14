//
//  SDEWindowController.m
//  ned mac
//
//  Created by thrust on 11/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SDEWindowController.h"
#import "SDECustomView.h"


@implementation SDEWindowController

-(id)
initWithFrame:(NSRect)aFrame image:(NSImage *)anImage level:(CGWindowLevel)level {
	self = [super initWithWindowNibName:@"SDEServerRenderWindow"];
	if (self) {
		NSWindow *window = [self window];
		
//		[window setIgnoresMouseEvents:YES];										// control local interactivity
		[window setMovableByWindowBackground:YES];
		
		// regular level for these windows. how do we set a CG window level?
		// same way.
		[window setLevel:level];
		
		[window setOpaque:NO];													// make the window itself transparent
		[window setBackgroundColor:[NSColor clearColor]];
		
		renderView = [[SDECustomView alloc] init];
		[window setContentView:renderView];
		[renderView setImage:anImage];
		
		[window setFrame:aFrame display:YES];
		
		[window orderFrontRegardless];											// show window
	}
	return self;
}

-(id)
initWithFrame:(NSRect)aFrame image:(NSImage *)anImage {
	return [self initWithFrame:aFrame image:anImage level:CGWindowLevelForKey(kCGNormalWindowLevelKey)];
}

-(id)
initWithFrame:(NSRect)aFrame {
	return [self initWithFrame:aFrame image:nil level:CGWindowLevelForKey(kCGNormalWindowLevelKey)];
}


//-(id)
//initWithImage:(NSImage *)anImage {
//	
//}


-(id)
init {
	return [self initWithFrame:NSZeroRect image:nil];
}


//-(void)
//dealloc {
//	NSLog(@"%@ dealloc", self);
//	[super dealloc];
//}


-(void)
setImage:(NSImage *)image {
	[renderView setImage:image];
}


-(void)
setFrame:(NSRect)frame {
	[[self window] setFrame:frame display:YES];
}

@end
