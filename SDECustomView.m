//
//  SDECustomView.m
//  ned mac
//
//  Created by thrust on 11/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SDECustomView.h"


@implementation SDECustomView

//When it's time to draw, this routine is called.
//This view is inside the window, the window's opaqueness has been turned off,
//and the window's styleMask has been set to NSBorderlessWindowMask on creation,
//so what this view draws *is all the user sees of the window*.  The first two lines below
//then fill things with "clear" color, so that any images we draw are the custom shape of the window,
//for all practical purposes.  Furthermore, if the window's alphaValue is <1.0, drawing will use
//transparency.
-(void)
drawRect:(NSRect)rect {
	if (image) {
		[[NSColor clearColor] set];
		NSRectFill([self frame]);
		
		[image compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
		
		//the next line resets the CoreGraphics window shadow (calculated around our custom window shape content)
		//so it's recalculated for the new shape, etc.  The API to do this was introduced in 10.2.
		if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_1)
		{
			[[self window] setHasShadow:NO];
			[[self window] setHasShadow:YES];
		}
		else
			[[self window] invalidateShadow];
	} else {
		[[NSColor brownColor] set];
		NSRectFill([self frame]);
	}
		
}


/*! ----------------------------+---------------+-------------------------------
	@method		setImage:
	@abstract	<#brief description#>
	@discussion	when resizing, handle repositioning a little better
				if image is nil, fill with solid color placeholder
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
setImage:(NSImage *) anImage {
	if (image != anImage) {
		[image release];
		image = [anImage retain];
		
		NSWindow *window = [self window];
		if (window != nil) {
			NSRect windowFrame = [window frame];
			windowFrame.size = [image size];
			[window setFrame:windowFrame display:YES];							// display:YES does not actually mark as dirty, as I had thought
			
			[self setNeedsDisplay:YES];											// instead we have to do this
		}
	}
}

@end
