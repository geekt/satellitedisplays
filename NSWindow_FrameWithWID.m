//
//  NSWindow_FrameWithWID.m
//  ned mac
//
//  Created by thrust on 11/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NSWindow_FrameWithWID.h"


@implementation NSWindow (FrameWithWID)

+(NSRect)
frameWithWID:(CGSWindowID)aWID {
	CGSConnectionRef cid = (CGSConnectionRef) [NSApp contextID];
	
	float mainScreenHeight = [[NSScreen mainScreen] frame].size.height;
	
	CGRect windowCGRect;													
	CGSGetScreenRectForWindow(cid, aWID, &windowCGRect);						// returns left-handed CGRect
	
	NSRect windowRect = NSMakeRect(windowCGRect.origin.x,						// adjust to right-handed NSRect
								   mainScreenHeight - windowCGRect.origin.y - windowCGRect.size.height,
								   //windowCGRect.origin.y,
								   windowCGRect.size.width,
								   windowCGRect.size.height);
	
	return windowRect;
}

@end
