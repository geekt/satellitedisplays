//
//  NSScreen_WIDs.m
//  ned mac
//
//  Created by thrust on 11/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NSScreen_WIDs.h"
#import "CGSPrivate.h"
#import "NSWindow_FrameWithWID.h"


@implementation NSScreen (WIDs)

-(NSMutableDictionary *)
windows {
	return [self windowsWithMinimumLevel:CGWindowLevelForKey(kCGBaseWindowLevelKey)];	// get 'em all.
}

// return NSDictionary of frames keyed on WIDs, since we need to use that
// shit again later anyway
-(NSMutableDictionary *)
windowsWithMinimumLevel:(CGWindowLevel) minimumWindowLevel {
	int count;
	NSCountWindows(&count);
	int WIDs[count];
	NSWindowList(count, WIDs);													// WIDs is in front-to-back order
	
	CGSConnectionRef cid = (CGSConnectionRef) [NSApp contextID];
	
	NSMutableDictionary *windows = [NSMutableDictionary dictionaryWithCapacity:count];
	
	int i;
	for (i = 0; i < count; i++) {
		NSRect windowFrame = [NSWindow frameWithWID:WIDs[i]];
		
		if (NSIntersectsRect(windowFrame, [self frame])) {
			CGWindowLevel windowLevel;
			CGSGetWindowLevel(cid, WIDs[i], &windowLevel);
			if (windowLevel >= minimumWindowLevel) {
				NSNumber *level = [NSNumber numberWithInt:windowLevel];
				
				//frame = [NSWindow frameWithWID:WID];
				NSRect offsetFrame = NSOffsetRect(windowFrame, -[self frame].origin.x, -[self frame].origin.y);
				NSValue *offsetFrameValue = [NSValue valueWithRect:offsetFrame];
				
				NSMutableDictionary *window = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					level, @"level",
					offsetFrameValue, @"frame",
					nil];

				NSNumber *WID = [NSNumber numberWithInt:WIDs[i]];
				[windows setObject:window forKey:WID];
			} else {
				//NSLog(@"skipping wid %d at level %d", WIDs[i], windowLevel);
			}
		} 
	}
	
	return windows;
}

@end
