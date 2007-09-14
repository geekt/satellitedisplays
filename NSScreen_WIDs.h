//
//  NSScreen_WIDs.h
//  ned mac
//
//  Created by thrust on 11/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSScreen (WIDs)

-(NSMutableDictionary *) windows;
-(NSMutableDictionary *) windowsWithMinimumLevel:(CGWindowLevel)minimumWindowLevel;

@end
