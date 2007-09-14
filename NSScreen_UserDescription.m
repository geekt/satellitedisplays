//
//  NSScreen.m
//  ned mac
//
//  Created by thrust on 10/09/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NSScreen_UserDescription.h"
#import <IOKit/graphics/IOGraphicsLib.h>


@implementation NSScreen (UserDescription)

-(NSString *)
userDescription {
	NSString* returnedString = nil;
	NSNumber* screenNumber = [[self deviceDescription] objectForKey:@"NSScreenNumber"];
	
	if (screenNumber != nil) {
	// @"NSScreenNumber" is documented in NSScreen as being eqiuvalent to CGDirectDisplayID
	CGDirectDisplayID thisDisplayID = (CGDirectDisplayID) [screenNumber pointerValue];
	
	// From the display ID we can get an IOKit service desc
	io_service_t displayService = CGDisplayIOServicePort(thisDisplayID);
	if (displayService != 0)
	{
		// Ask IOKit for info
		NSDictionary* infoDict = (NSDictionary*) IODisplayCreateInfoDictionary(displayService, kIODisplayOnlyPreferredName);
		if (infoDict != nil)
		{
			NSDictionary* productNameDict = [infoDict objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
			
			if (productNameDict != nil) {
				// CFBundleCopyBundleLocalizations then CFBundleCopyPreferredLocalizationsFromArray to get 
				// an ordered list of the current localization order. Then compare with the contents of the returned
				// dictionary, which contains names for the display keyed by localization.
				
				// For now just return the first item
				returnedString = [[[[productNameDict allValues] objectAtIndex:0] copy] autorelease];
			}
			[infoDict release];
		}
	}
	}
	
	// If we couldn't get anything, give an ugly but unique description
	if (returnedString == nil) {
		returnedString = [NSString stringWithFormat:@"Unknown Display (%08x)", self];
	}
	
	return returnedString;
}

@end