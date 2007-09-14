//
//  NSWindow_ImageWithWID.m
//  ned mac
//
//  Created by thrust on 11/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NSWindow_ImageWithWID.h"


@implementation NSWindow (ImageWithWID)


/*! ----------------------------+---------------+-------------------------------
	@method		+imageWithWID:
	@abstract	<#brief description#>
	@discussion	oGL frame grab: http://lists.apple.com/archives/Quartz-dev/2006/Apr/msg00088.html
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
+(NSImage *)
imageWithWID:(CGSWindowID)wid {
	
	CGSConnectionRef cid = (CGSConnectionRef) [NSApp contextID];				// get context ID. does this ever change?

	CGRect cgrect;
	CGSGetWindowBounds(cid, wid, &cgrect);										// get window bounds in CG space
	
	NSSize imageSize = NSMakeSize(cgrect.size.width, cgrect.size.height);		// create an NSImage of appropriate size
	
	NSImage *img = [[NSImage alloc] initWithSize:imageSize];
	
	[img lockFocus];															// lock the drawing context to the image
	
	void *grafport = [[NSGraphicsContext currentContext] graphicsPort];			// get the graphport
	
	// copie du contenu de la fenêtre vers le contexte graphique mis en avant
	// copy the contents of the window. set the origin of the dstRect to 0
	cgrect.origin = CGPointZero;
	CGContextCopyWindowCaptureContentsToRect(grafport, cgrect, cid, wid, cgrect);

	[img unlockFocus];
	
	return [img autorelease];
}

@end
