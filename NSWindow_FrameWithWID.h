//
//  NSWindow_FrameWithWID.h
//  ned mac
//
//  Created by thrust on 11/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CGSPrivate.h"


@interface NSWindow (FrameWithWID)

+(NSRect) frameWithWID:(CGSWindowID)aWID;

@end
