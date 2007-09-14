//
//  DEGTXTRecord.h
//  ned mac
//
//  Created by thrust on 19/07/06.
//  Copyright 2006 ritchie argue. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DEGTXTRecord : NSObject {
	NSMutableDictionary *properties;
}

-(void) updateProperties:(NSDictionary *)newProperties;
-(void) updatePropertiesWithData:(NSData *)newData;

@end
