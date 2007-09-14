//
//  NedClientController.h
//  ned mac
//
//  Created by thrust on 09/06/06.
//  Copyright 2006 ritchie argue. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DEGRectToStringTransformer;

@interface SDEClientController : NSObjectController {
	NSMutableArray				*nedDisplays;									// data source for tableview
	
	NSMutableDictionary			*properties;
	
	NSTimer						*timer;											// autorelease pool watchdog
	
	BOOL						searching;										// keep track of activity, these three are coalesced
	int							resolveCount;									// into animateProgressIndicator
	int							receivingTXTCount;
	
	BOOL						animateProgressIndicator;
	
@private
	NSNetServiceBrowser			*serviceBrowser;
}

#pragma mark -
#pragma mark kvc/kvo accessors
-(BOOL)animateProgressIndicator;
-(void)setAnimateProgressIndicator:(BOOL)animate;

-(NSString *) questionObjectNameForCurrentCount;								// get @"Service"/@"Services" depending on count

-(void) connect:(NSArray *) services;

@end
