//
//  SDEServerRenderer.h
//  ned mac
//
//  Created by thrust on 11/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SDECursorController.h"


@interface SDEServerRenderer : NSObject {
	NSMutableArray *clients;
}

-(id) initWithClientConnections:(NSMutableArray *) connections;

@end
