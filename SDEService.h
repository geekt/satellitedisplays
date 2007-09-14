//
//  SDEService.h
//  ned mac
//
//  Created by thrust on 14/07/06.
//  Copyright 2006 ritchie argue. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SDEConnection.h"
#import "SDEFramegrabber.h"


@interface SDEService : NSObject {
	NSMutableDictionary *properties;											// for kvo/bindings
}

#pragma mark -
-(id) initWithNetService:(NSNetService *) service;

#pragma mark -
#pragma mark kvc/kvo compliance
-(id) valueForUndefinedKey:(NSString *)key;

#pragma mark -
+(NSString *) objectName;
+(NSString *) objectNamePlural;

@end
