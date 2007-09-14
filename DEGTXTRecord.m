//
//  DEGTXTRecord.m
//  ned mac
//
//  Created by thrust on 19/07/06.
//  Copyright 2006 ritchie argue. All rights reserved.
//

#import "DEGTXTRecord.h"

@implementation DEGTXTRecord

-(id)
init {
	self = [super init];
	if (self) {
		properties = [[NSMutableDictionary alloc] init];
		// create a disp array, and stick it in properties?
	}
	return self;
}

-(void)
dealloc {
	[properties release];														// releasing a collection releases all it's contents as well
	[super dealloc];
}

#pragma mark -

/*!
    @method     updateProperties:
    @abstract   update the properties dictionary with new data.
    @discussion	is it necessary to update rather than set? it's
				likely a little more processing, but does that
				really matter?
*/
-(void)
updateProperties:(NSDictionary *) newProperties {
	// locate changed fields
	
	NSLog(@"updating to %@", newProperties);
	
	if (properties != newProperties) {
		// first delete k/v pairs that don't exist in the new dict
		NSEnumerator *enumerator = [properties keyEnumerator];
		NSString *currentKey;
		while (currentKey = [enumerator nextObject]) {
			// look up currentKey in new dict
			id newObject;
			if (newObject = [newProperties objectForKey:currentKey]) {
				// we found it, so compare, and if new then update
				id oldObject = [properties objectForKey:currentKey];
				if (![newObject isEqual:oldObject]) {
					// new so replace
					[properties setObject:newObject forKey:currentKey];
				}
			} else {
				// not found, so delete old k/v pair
				[properties removeObjectForKey:currentKey];
			}
		}
		
		// now add new k/v pairs that didn't exist in the old dict
		enumerator = [newProperties keyEnumerator];
		while (currentKey = [enumerator nextObject]) {
			if (![properties objectForKey:currentKey]) {
				id newObject = [newProperties objectForKey:currentKey];
				[properties setObject:newObject forKey:currentKey];
			}
		}
	}
}

/*!
    @method     updatePropertiesWithData
    @abstract   update properties dictionary with TXTRecord data
    @discussion (comprehensive description)
*/
-(void)
updatePropertiesWithData:(NSData *) data {
	// convert txtRecord data to a dict
	
	NSDictionary *dataDict = [[NSNetService dictionaryFromTXTRecordData:data] mutableCopy];
	if ([dataDict count] <= 0)
		return;
	
	NSLog(@"dataDict: %@", dataDict);
	
	// create display array, initialize size to number of displays
	NSMutableArray *dispArray = [[NSMutableArray alloc] init];
	
	NSEnumerator *listEnumerator = [dataDict keyEnumerator];
	NSString *key;
	while ((key = [listEnumerator nextObject]) != nil) {
		if (![key isEqualToString:@"txtvers"]) {
			NSString *displayFrameString = [[NSString alloc] initWithData:[dataDict objectForKey:key] encoding:NSUTF8StringEncoding];
			NSRect displayFrame = NSRectFromString(displayFrameString);
			[displayFrameString release];
			displayFrameString = [NSString stringWithFormat:@"%d*%d @ %d,%d", 
															(int)displayFrame.size.width,
															(int)displayFrame.size.height,
															(int)displayFrame.origin.x,
															(int)displayFrame.origin.y, nil];
															
			[dispArray addObject:[NSString stringWithFormat:@"%@: %@", key, displayFrameString]];
		}
	}
	[dispArray sortUsingSelector:@selector(compare:)];
	
	// and update the properties
	[self updateProperties:[NSDictionary dictionaryWithObject:dispArray forKey:@"displays"]];
}

@end
