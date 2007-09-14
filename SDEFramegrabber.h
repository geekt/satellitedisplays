//
//  SDEFramegrabber.h
//  ned mac
//
//  Created by thrust on 11/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SDEConnection.h"


@interface SDEFramegrabber : NSObject {
	NSScreen					*screen;										// screen to capture in. just support one capture screen for now
	BOOL						dirty;											// if screen is dirty and needs a repaint
	int							rate;
	BOOL						moved;											// if an object moved
	
	NSColor						*cursorColor;
	NSPoint						oldPoint;
	NSCursor					*oldCursor;
	
	NSMutableDictionary			*windows;
	
	SDEConnection			*connection;
}

-(id) initWithConnection:(SDEConnection *)aConnection screen:(NSScreen *) aScreen;
-(id) initWithConnection:(SDEConnection *)aConnection;

@end
