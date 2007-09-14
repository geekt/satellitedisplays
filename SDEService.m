//
//  SDEService.m
//  ned mac
//
//  Created by thrust on 14/07/06.
//  Copyright 2006 ritchie argue. All rights reserved.
//

#import "SDEService.h"
#import "DEGTXTRecord.h"
#import "SDEConnection.h"


@implementation SDEService

/*!
    @method     initWithNetService
    @abstract   (brief description)
    @discussion there should be one init… method that calls [super init],
				this is the designated initializer. other initializers
				should call it. non-assigned instance variables are auto-
				initialized to 0 or nil.
*/
-(id)
initWithNetService:(NSNetService *) aService {
	self = [super init];
	if (self) {
		properties = [[NSMutableDictionary alloc] init];
		
		[properties setValue:aService forKeyPath:@"netService"];
		[properties setValue:[[[DEGTXTRecord alloc] init] autorelease] forKeyPath:@"TXTRecord"];
		
		// set up some kvo flags
		[properties setValue:[NSNumber numberWithBool:NO] forKeyPath:@"resolving"];
		[properties setValue:[NSNumber numberWithBool:NO] forKeyPath:@"receivingTXT"];
		
		[aService setDelegate:self];											// set us up as the delegate for the NSNetService
	}
	return self;
}

-(void)
dealloc {
	NSLog(@"%@: dealloc", self);
	
	[properties release];
	
	[super dealloc];
}

-(id)
valueForUndefinedKey:(NSString *)key {
	NSLog(@"SDEServiceRecord: valueForUndefinedKey: %@", key);
	
	return @"undefined!";
}

#pragma mark -
#pragma mark NSNetService

-(void)
netServiceDidStop:(NSNetService *) aService {
	NSLog(@"\t%@ netServiceDidStop", [self valueForKeyPath:@"properties.name"]);
}


/*!
    @method     setReceivingTXT:
    @abstract   set a flag to indicate that we are receiving TXT data
    @discussion the controller watches this property via kvo, and updates
				the ui as necessary
*/
-(void)
setReceivingTXT:(bool) value {
	[properties setValue:[NSNumber numberWithBool:value] forKeyPath:@"receivingTXT"];
}


/*!
    @method     netService: didUpdateTXTRecordData:
    @abstract   called when there is new TXTRecordData for us
    @discussion this object is the delegate of its NSNetService
*/
- (void)
netService:(NSNetService *)sender
didUpdateTXTRecordData:(NSData *)myData {
	// animate progress indicator
	[self setReceivingTXT:YES];
	
	DEGTXTRecord *txtRecord = [self valueForKeyPath:@"properties.TXTRecord"];
	
	// do we have to notify someone that we're doing this now?
	[txtRecord updatePropertiesWithData:myData];
	
	// give the animation some time to display
	[self performSelector:@selector(setReceivingTXT:) withObject:NO afterDelay:0.2];
}


#pragma mark -
#pragma mark kvc/kvo

+(NSString *)
objectName {
	return @"Display Sharing Service";
}


+(NSString *)
objectNamePlural {
	return @"Display Sharing Services";
}

@end
