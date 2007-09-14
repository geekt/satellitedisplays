//
//  SDEServerReceiver.m
//  ned mac
//
//  Created by thrust on 11/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SDEServerRenderer.h"
#import "SDEConnection.h"
#import "SDECursorController.h"
#import "SDEWindowController.h"

#import "SDECommon.h"


@implementation SDEServerRenderer

-(id)
initWithClientConnections:(NSMutableArray *) connections {
	NSLog(@"SDEServerRenderer initWithClientConnections");
	self = [super init];
	if (self) {
		clients = [connections retain];
	}
	return self;
}


-(void)
dealloc {
	if (clients) {
		[clients release];
		clients = nil;
	}
	[super dealloc];
}


// observe changes to clientConnection array
-(void)
observeValueForKeyPath:(NSString *)keyPath
			  ofObject:(id)objectForKey
				change:(NSDictionary *)change
			   context:(void *)context {
    if ([keyPath isEqual:@"clientConnections"]) {
		NSLog(@"%@ received connection change with object %@", self, objectForKey);
		NSMutableDictionary *client = [change objectForKey:NSKeyValueChangeNewKey];
		
		if (client != nil) {													// insertion
			// build a cursor
			SDECursorController *cursorController = [[SDECursorController alloc] init];
			[client setValue:cursorController forKey:@"cursorController"];
			[cursorController release];
						
			// add window list
			NSMutableDictionary *windows = [[NSMutableDictionary alloc] init];
			[client setValue:windows forKey:@"windows"];
			[windows release];
			
		} else {
			// removal
		}
	}
}


#pragma mark -

-(void)
frameRequest:(SDEConnection *) aConnection {
	[aConnection write:@"frameRequest"];
}


-(void)
cursorRequest:(SDEConnection *) aConnection {
	[aConnection write:@"cursorRequest"];
}


-(void)
handleFrame:(NSDictionary *)frame withClient:(NSDictionary *)client onConnection:(SDEConnection *)aConnection {
	//NSDictionary *frame = [response objectForKey:@"frame"];
	//if ([frame count] > 0) {
//		NSLog(@"frame received: %@", frame);
	//}
	
	NSMutableDictionary *windows = [client valueForKey:@"windows"];
	
	// merge incoming frames with existing windows
	NSArray *existingWIDs = [windows allKeys];									// snapshot window state
	NSArray *currentWIDs = [frame allKeys];
	
	// remove windows that no longer exist, update existing windows
	NSEnumerator *existingWIDEnumerator = [existingWIDs objectEnumerator];
	NSNumber *WID;
	while (WID = [existingWIDEnumerator nextObject]) {
		if ([[frame objectForKey:WID] objectForKey:@"remove"]) {				// if this WID is marked, remove it
			NSLog(@"removing window %@", WID);
			[windows removeObjectForKey:WID];
		} else {
			// window exists, update it
			SDEWindowController *window = [windows objectForKey:WID];
			
			// if image data exists, update image
			NSImage *image = [[frame objectForKey:WID] objectForKey:@"image"];
			if (image) {
				//NSLog(@"updating image for wid %@", WID);
				[window setImage:image];
			}
			
			NSValue *frameValue = [[frame objectForKey:WID] objectForKey:@"frame"];
			if (frameValue) {
				[window setFrame:[frameValue rectValue]];
			}
		}
	}
	
	existingWIDs = [windows allKeys];									// snapshot window state after removal
	
	// add windows that are new.
	// invert/compress this logic
	//			if ([existingWIDs count] <= 0) {
	//				NSLog(@"initial window import");
	//				// add all windows
	//				NSEnumerator *currentWIDEnumerator = [currentWIDs objectEnumerator];
	//				while (WID = [currentWIDEnumerator nextObject]) {
	//					NSLog(@"adding WID: %@", WID);
	//					// create window, attach to window object
	//					NSImage *image = [[frame objectForKey:WID] objectForKey:@"image"];
	//					NSRect windowFrame = [[[frame objectForKey:WID] objectForKey:@"frame"] rectValue];
	//					
	//					SDEWindowController *window = [[SDEWindowController alloc] initWithFrame:windowFrame image:image];
	//					[windows setObject:window forKey:WID];
	//					[window release];
	//				}
	//			} else {
				NSEnumerator *currentWIDEnumerator = [currentWIDs objectEnumerator];
				while (WID = [currentWIDEnumerator nextObject]) {
					if (![existingWIDs containsObject:WID] || [existingWIDs count] <= 0) {
						//NSLog(@"adding WID: %@", WID);
						// create window, attach to window object
						NSImage *image = [[frame objectForKey:WID] objectForKey:@"image"];
						NSRect windowFrame = [[[frame objectForKey:WID] objectForKey:@"frame"] rectValue];
						CGWindowLevel windowLevel = [[[frame objectForKey:WID] objectForKey:@"level"] intValue];
						
						SDEWindowController *window = [[SDEWindowController alloc] initWithFrame:windowFrame
																								 image:image
																								 level:windowLevel];
						[windows setObject:window forKey:WID];
						[window release];
					}
				}
				//			}
				
				// request next frame - rate limit to ~30Hz
				[self performSelector:@selector(frameRequest:) withObject:aConnection afterDelay:kFrameRefresh];
				
				// update local window list
				
				
}


-(void)
handleCursor:(NSDictionary *)cursor withClient:(NSDictionary *)client onConnection:(SDEConnection *)aConnection {
	// cursor
	SDECursorController *cursorController = [client valueForKey:@"cursorController"];
	
	if ([cursor objectForKey:@"position"]) {
		NSValue *position = [cursor objectForKey:@"position"];
		NSPoint p = [position pointValue];
		[cursorController setCursorLocation:p];
		
		// request next cursor - rate limit
		[self performSelector:@selector(cursorRequest:)
				   withObject:aConnection
				   afterDelay:kCursorOnscreenRefresh];		
	}
	
	if ([cursor objectForKey:@"visible"]) {
		NSNumber *visible = [cursor objectForKey:@"visible"];
		if ([visible boolValue]) {
			NSLog(@"show cursor");
			[cursorController showCursor];
		} else {
			NSLog(@"hide cursor");
			[cursorController hideCursor];
		}
	}
	
}

/*! ----------------------------+---------------+-------------------------------
	@method		connection:receive:
	@abstract	<#brief description#>
	@discussion	this will have to be responsible for keeping windows in the
				right z-order
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
connection:(SDEConnection *)aConnection receive:(NSDictionary *)response {
	// look up connection in clientConnection list
	//NSMutableArray *clients = [self mutableArrayValueForKey:@"clientConnections"];
	
	NSEnumerator *enumerator = [clients objectEnumerator];
	NSMutableDictionary *client = nil;
	while (client = [enumerator nextObject]) {
		SDEConnection *connection = [client objectForKey:@"connection"];
		if ([connection isEqual:aConnection]) {
			break;
		}
	}
	if (client != nil) {
		// process response
		//NSLog(@"received response %@", response);
		
		// cursor
		if ([response objectForKey:@"cursor"]) {
			[self handleCursor:[response objectForKey:@"cursor"] withClient:client onConnection:aConnection];
		}
				
		// frames
		if ([response objectForKey:@"frame"]) {
			[self handleFrame:[response objectForKey:@"frame"] withClient:client onConnection:aConnection];
		}
	}
}

@end
