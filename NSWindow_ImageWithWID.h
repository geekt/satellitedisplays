//
//  NSWindow_ImageWithWID.h
//  ned mac
//
//  Created by thrust on 11/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CGSPrivate.h"


@interface NSWindow (ImageWithWID)

+(NSImage *) imageWithWID:(CGSWindowID)aWID;

@end
