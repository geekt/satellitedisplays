//
//  SDECursorController.h
//  ned mac
//
//  Created by thrust on 11/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SDECustomView;


@interface SDECursorController : NSWindowController {
	SDECustomView *cursorView;
	NSPoint hotSpot;
	NSPoint hotSpotOffset;
	//NSColor *cursorColor;
}

-(void) setCursor:(NSCursor *)aCursor;
-(void) setCursorLocation:(NSPoint)aPoint;
-(void) showCursor;
-(void) hideCursor;

@end
