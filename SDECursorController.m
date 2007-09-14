//
//  SDECursorController.m
//  ned mac
//
//  Created by thrust on 11/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SDECursorController.h"
#import "SDECustomView.h"


@implementation SDECursorController

-(id)
init {
	self = [super initWithWindowNibName:@"SDEServerCursorWindow"];
	if (self) {
		NSWindow *window = [self window];
		
		[window setOpaque:NO];
		[window setIgnoresMouseEvents:YES];
		[window setLevel:NSPopUpMenuWindowLevel];
		[window setBackgroundColor:[NSColor clearColor]];
		[window setMovableByWindowBackground:YES];
		
		cursorView = [[SDECustomView alloc] init];
		[window setContentView:cursorView];

		[self setCursor:[NSCursor arrowCursor]];								// set default cursor
																				// have to do this _after we add the view to the window
																				// to get it to resize
		
		// should probably figure out the cursor hot spot at some point, and
		// actually use it
	}
	return self;
}


-(void)
dealloc {
	[cursorView release];
	
	[super dealloc];
}


-(void)
setCursor:(NSCursor *) aCursor {
	[cursorView setImage:[aCursor image]];
	
	hotSpotOffset.x = [aCursor hotSpot].x;
	hotSpotOffset.y = [[aCursor image] size].height - [aCursor hotSpot].y;
}


/*! ----------------------------+---------------+-------------------------------
	@method		setCursorLocation
	@abstract	<#brief description#>
	@discussion	aPoint describes the hotspot location, we need to offset this
				into the window containing the cursor
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
setCursorLocation:(NSPoint)aPoint {
	NSPoint windowOrigin;
	windowOrigin.x = aPoint.x - hotSpotOffset.x;
	windowOrigin.y = aPoint.y - hotSpotOffset.y;
	[[self window] setFrameOrigin:windowOrigin];
}


-(void)
showCursor {
	[[self window] orderFrontRegardless];
}


-(void)
hideCursor {
	[[self window] orderOut:nil];
}

@end
