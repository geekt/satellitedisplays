//
//  SDEFramegrabber.m
//  ned mac
//
//  Created by thrust on 11/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SDEFramegrabber.h"
#import "NSScreen_UserDescription.h"
#import "NSScreen_WIDs.h"
#import "CGSPrivate.h"
#import "NSWindow_FrameWithWID.h"
#import "NSWindow_ImageWithWID.h"

#import "SDECommon.h"


@interface SDEFramegrabber (forwardDecls)
void screenRefreshCallback(CGRectCount, const CGRect *, void *);
void screenMoveCallback(CGScreenUpdateMoveDelta, size_t, const CGRect *, void *);
-(void) handleFrameRequest;
@end

@implementation SDEFramegrabber

/*! ----------------------------+---------------+-------------------------------
@method		-initWithConnection:
@abstract	<#brief description#>
@discussion	get the screen named Display, and only grab on that
@param		<#name#> <#description#>
@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(id)
initWithConnection:(SDEConnection *)aConnection {
	NSArray *screens = [NSScreen screens];
	NSEnumerator *screenEnumerator = [screens objectEnumerator];
	NSScreen *aScreen = nil;
	while (aScreen = [screenEnumerator nextObject]) {
		if ([[aScreen userDescription] isEqualToString:@"Display"]) {
			NSLog(@"found iodummyfb");
			break;
		} else {
			NSLog(@"found %@", [aScreen userDescription]);
		}
	}
	
	return [self initWithConnection:aConnection screen:aScreen];
}


-(id)
initWithConnection:(SDEConnection *)aConnection screen:(NSScreen *)aScreen {
	self = [super init];
	if (self) {
		connection = [aConnection retain];
		
		screen = [aScreen retain];
		
		// set up a screen refresh callback, but we only want to callback on
		// the screens we're interested in? not so easy to do with a category, so
		// just handle it here instead
		CGRegisterScreenRefreshCallback(screenRefreshCallback, self);
		//CGScreenRegisterMoveCallback(screenMoveCallback, self);
		
		oldCursor = nil;
		oldPoint = NSMakePoint(20,20);											// start off on the main screen, guaranteed to be offscreen remote
																				// this assumes unmirrored. oh well, close enough.
		
		dirty = YES;
		moved = NO;
		
		windows = [[NSMutableDictionary alloc] init];
	}
	return self;
}



-(void)
dealloc {
	if (windows) {
		[windows release];
	}
	
	// unregister screen refresh callback
	CGUnregisterScreenRefreshCallback(screenRefreshCallback, self);
	//CGScreenUnregisterMoveCallback(screenMoveCallback, self);
	
	if (screen) {
		[screen release];
	}
	
	if (connection) {
		[connection release];
	}
	
	[super dealloc];
}


#pragma mark -
#pragma mark refresh callbacks
// break this into an nsscreen category? can we manage that with the c callback?
-(void)
screenRefreshed:(CGRectCount)count rectArray:(const CGRect *)rectArray {
	int i;
	CGRect regionCGRect;
	NSRect screenNSRect = [screen frame];
	
	float mainScreenHeight = [[NSScreen mainScreen] frame].size.height;
	
	for (i = 0; i < count; i++) {
		regionCGRect = rectArray[i];											// left-handed CGRect
		
		//CGGetDisplaysWithRect
		
		NSRect regionNSRect = NSMakeRect(regionCGRect.origin.x,					// adjust to right-handed NSRect
										 mainScreenHeight - regionCGRect.origin.y - regionCGRect.size.height,
										 regionCGRect.size.width,
										 regionCGRect.size.height);
		
		// intersect the regionRect with the screens we're interested in
		// capturing on.
		if (NSIntersectsRect(regionNSRect, screenNSRect)) {
			//			NSLog(@"region updated: %f,%f %f,%f",
			//				  regionNSRect.origin.x, regionNSRect.origin.y,
			//				  regionNSRect.size.width, regionNSRect.size.height);
			
			dirty = YES;														// mark screen as dirty
		}
	}
	
//	if (dirty) {
//		NSLog(@"screenRefreshed: %d", count);
//		[self handleFrameRequest];
//	}
}


/*! ----------------------------+---------------+-------------------------------
@method		-screenMoved: rectArray: delta:
@abstract	<#brief description#>
@discussion	we have to be careful here, this could be a scrolling event as
			well as just a plain window move. is this not being called because
			the iodummyframebuffer doesn't support block movement?
@param		<#name#> <#description#>
@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
screenMoved:(CGRectCount)count rectArray:(const CGRect *)rectArray delta:(CGScreenUpdateMoveDelta)delta {
	//NSLog(@"screenMoved");
	int i;
	CGRect regionCGRect;
	NSRect screenNSRect = [screen frame];
	
	float mainScreenHeight = [[NSScreen mainScreen] frame].size.height;
	
	for (i = 0; i < count; i++) {
		regionCGRect = rectArray[i];											// left-handed CGRect
		
		NSRect regionNSRect = NSMakeRect(regionCGRect.origin.x,					// adjust to right-handed NSRect
										 mainScreenHeight - regionCGRect.origin.y - regionCGRect.size.height,
										 regionCGRect.size.width,
										 regionCGRect.size.height);
		
		if (i == 0) {
			NSLog(@"region moved: %f,%f %f,%f",
				  regionNSRect.origin.x, regionNSRect.origin.y,
				  regionNSRect.size.width, regionNSRect.size.height);
		}
		
		// intersect the regionRect with the screens we're interested in
		// capturing on.
		if (NSIntersectsRect(regionNSRect, screenNSRect)) {
			
			moved = YES;														// mark screen as having objects moved
		}
	}
	
	if (moved) {
		NSLog(@"regionNSRect moved: %d", count);
//
//		[self handleFrameRequest];
	}
}


/*! ----------------------------+---------------+-------------------------------
@function	screenRefreshCallback
@abstract	c wrapper for screen refresh callback
@discussion	do we want to re-schedule these so we're not spending too long
			on the callback thread? the callbacks are run on our main thread,
			so how does that work?

@param		<#name#> <#description#>
@result		<#description#>
--------------------------------+---------------+---------------------------- */
void
screenRefreshCallback(CGRectCount count, 
					  const CGRect * rectArray, 
					  void * impl) {
	SDEFramegrabber *self = impl;
	[self screenRefreshed:count rectArray:rectArray];
}

//void
//screenMoveCallback(CGScreenUpdateMoveDelta delta,
//				   size_t count,
//				   const CGRect * rectArray,
//				   void * userParameter) {
//	SDEFramegrabber *self = userParameter;
//	[self screenMoved:count rectArray:rectArray delta:delta];
//}


#pragma mark -

/*! ----------------------------+---------------+-------------------------------
	@method		handleCursorRequest:
	@abstract	<#brief description#>
	@discussion	doesn't seem possible to determine which cursor is currently in
				use system-wide, so we can't forward the correct cursor image to
				the remote system. damn.
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
handleCursorRequest {
	//NSLog(@"handleCursorRequest");
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self						// if there is a pending performSelector, cancel it
											 selector:@selector(handleCursorRequest)
											   object:nil];
	
	NSPoint point = [NSEvent mouseLocation];
	
	if (NSEqualPoints(point, oldPoint)) {
		// if cursor didn't move, wait 1/60s and check again
		[self performSelector:@selector(handleCursorRequest)
				   withObject:nil
				   afterDelay:kCursorOnscreenRefresh];
		
	} else {
		NSRect screenRect = [screen frame];
		
		// this didn't seem to work correctly near the top edge of the screen,
		// the hotspot can apparently go outside the screen rect by one pixel
		// (i.e. screen is 1024px tall, thus height range = 0..1023, but cursor
		// can go to 1024.
		// maybe expand the rect by a couple of pixels, so we still show the
		// cursor on the remote screen until it's moved up by the height of the
		// cursor? same with moving to the right or left, when should the cursor
		// disappear? need to experiment some with a proper multi-head, as I
		// think there is some popping present in the stock system.
		screenRect.size.height += 10;
		
		NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
		
		// if this is a transitional move by the cursor, notify the display
		if (NSPointInRect(point, screenRect) && !NSPointInRect(oldPoint, screenRect)) {
//			NSLog(@"show cursor @ position %f,%f, rect:%f,%f,%f,%f",
//				  point.x, point.y,
//				  screenRect.origin.x, screenRect.origin.y,
//				  screenRect.size.width, screenRect.size.height);
			
			[response setValue:[NSNumber numberWithBool:YES]
											 forKeyPath:@"visible"];
		}
		if (!NSPointInRect(point, screenRect) && NSPointInRect(oldPoint, screenRect)) {
//			NSLog(@"hide cursor @ position %f,%f, rect:%f,%f,%f,%f",
//				  point.x, point.y,
//				  screenRect.origin.x, screenRect.origin.y,
//				  screenRect.size.width, screenRect.size.height);
			
			[response setValue:[NSNumber numberWithBool:NO]
											 forKeyPath:@"visible"];
		}
		
		if (NSPointInRect(point, screenRect)) {									// if point on capture display, offset and send
			NSPoint offsetPoint;
			offsetPoint.x = point.x - screenRect.origin.x;
			offsetPoint.y = point.y - screenRect.origin.y;
			
			NSValue *position = [NSValue valueWithPoint:offsetPoint];
			[response setValue:position forKeyPath:@"position"];
			
		} else {																// cursor moved, but point not on display so requeue request
			[self performSelector:@selector(handleCursorRequest)
					   withObject:nil
					   afterDelay:kCursorOffscreenRefresh];
		}
		
		// if there is anything to report, do so
		if ([response count]) {
			[connection write:[NSDictionary dictionaryWithObject:response forKey:@"cursor"]];
		}
		[response release];
		
		oldPoint = NSMakePoint(point.x, point.y);
	}
}


/*! ----------------------------+---------------+-------------------------------
	@method		handleFrameRequest
	@abstract	<#brief description#>
	@discussion	break this in two: one for contents, and one for position.
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
handleFrameRequest {

	if (!dirty) {
		// no change, check again in a moment. yes polling is bad, but we also
		// want to rate-limit instead of just updating whenever the callback
		// says there has been a change, as this could be too fast for our
		// receiver. but the receiver will rate-limit itself, so we should get
		// rid of the polling here. need a way to coalesce refresh calls
		[self performSelector:@selector(handleFrameRequest)
				   withObject:nil
				   afterDelay:kFrameRefresh];
		
	} else {
		NSMutableDictionary *currentWindows =
			[screen windowsWithMinimumLevel:CGWindowLevelForKey(kCGDesktopIconWindowLevelKey)];
		
		NSArray *currentWIDs = [currentWindows allKeys];
		
		// windows in previous frame. take snapshot with allKeys rather than
		// using keyEnumerator, as we will be modifying the dictionary
		NSArray *existingWIDs = [windows allKeys];
		
		// remove windows that no longer exist in new frame
		NSEnumerator *existingWIDEnumerator = [existingWIDs objectEnumerator];
		NSNumber *WID;
		while (WID = [existingWIDEnumerator nextObject]) {			
			if (![currentWIDs containsObject:WID]) {
				NSLog(@"marking window %@ as deleted", WID);
				[windows setObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
															   forKey:@"remove"]
							forKey:WID];
			}
		}
		
		// add windows that are new
		if ([existingWIDs count] <= 0) {
			// add all windows
			NSEnumerator *currentWIDEnumerator = [currentWIDs objectEnumerator];
			while (WID = [currentWIDEnumerator nextObject]) {
				NSLog(@"initial window(s) import %@", WID);
				[windows setObject:[currentWindows objectForKey:WID]
							forKey:WID];
			}
		} else {
			NSEnumerator *currentWIDEnumerator = [currentWIDs objectEnumerator];
			while (WID = [currentWIDEnumerator nextObject]) {
				if (![existingWIDs containsObject:WID]) {
					
					NSLog(@"adding new window %@", WID);
					[windows setObject:[currentWindows objectForKey:WID]			// not in old list, add
								forKey:WID];
				}
			}
		}
		
		// adjust changed windows, build dictionary to send
		NSMutableDictionary *frame = [NSMutableDictionary dictionaryWithCapacity:[windows count]];
		
		existingWIDs = [windows allKeys];
		existingWIDEnumerator = [existingWIDs objectEnumerator];
		while (WID = [existingWIDEnumerator nextObject]) {
			//NSLog(@"adjusting changed window");
			
			NSDictionary *newWindow = [currentWindows objectForKey:WID];
			NSMutableDictionary *oldWindow = [windows objectForKey:WID];
			NSMutableDictionary *sendWindow = [NSMutableDictionary dictionaryWithCapacity:3];
			
			if ([oldWindow objectForKey:@"remove"]) {
				NSLog(@"sending remove message");
				[sendWindow setObject:[oldWindow objectForKey:@"remove"] forKey:@"remove"];
				// remove the window
				[windows removeObjectForKey:WID];
					
			} else {
				// compare & update level
				NSNumber *newLevel = [newWindow objectForKey:@"level"];
				NSNumber *oldLevel = [oldWindow objectForKey:@"level"];
				if (![newLevel isEqualToNumber:oldLevel]) {
					[oldWindow setObject:newLevel forKey:@"level"];
					[sendWindow setObject:newLevel forKey:@"level"];
				}
				
				// compare & update frame
//				if (moved) {
					NSValue *newFrame = [newWindow objectForKey:@"frame"];
					NSValue *oldFrame = [oldWindow objectForKey:@"frame"];
					if (![newFrame isEqualToValue:oldFrame]) {
						[oldWindow setObject:newFrame forKey:@"frame"];
						[sendWindow setObject:newFrame forKey:@"frame"];
					}
//				}
				
				// every six frames, update the image?
//				rate++;
//				if ((rate % 6) == 0) {
					// compare & update image
					NSImage *newImage = [NSWindow imageWithWID:[WID intValue]];
					NSImage *oldImage = [oldWindow objectForKey:@"image"];
					
					NSData *newData = [newImage TIFFRepresentation];
					NSData *oldData = [oldImage TIFFRepresentation];
					
					if (![newData isEqualToData:oldData]) {
						//NSLog(@"updating image for wid %@, image %@", WID, newImage);
						[oldWindow setObject:newImage forKey:@"image"];
						[sendWindow setObject:newImage forKey:@"image"];
					}
//				}
			}
			if ([sendWindow count]) {
				[frame setObject:sendWindow forKey:WID];
			}
		}
		
		// send the frame. if this is the first frame and it's empty, we need
		// to send it anyway to get another request from the display, otherwise
		// any windows that are on the screen before the app starts won't get
		// sent until the first change. seems like this is true anyway
		[connection write:[NSDictionary dictionaryWithObject:frame
													  forKey:@"frame"]];

		
		dirty = NO;
	}
}


/*! ----------------------------+---------------+-------------------------------
@method		connection:receive:
@abstract	<#brief description#>
@discussion	receive a request from the display, process as necessary. we need to
			cache the connection object, as the handleFrameRequest may be called
			from a callback with no access to it.
@param		<#name#> <#description#>
@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
connection:(SDEConnection *)aConnection receive:(NSString *)clientMessage {
	if (connection != aConnection) {
		NSLog(@"connection mismatch");
		return;
	}
	
	if ([clientMessage isEqualToString:@"cursorRequest"]) {
		[self handleCursorRequest];
	
	} else if ([clientMessage isEqualToString:@"frameRequest"]) {
		[self handleFrameRequest];
		
	} else {
		NSLog(@"received object: %@ on connection %@", clientMessage, aConnection);
	}
}

@end
