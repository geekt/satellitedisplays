//
//  SDEServerController.h
//  ned mac
//
//  Created by thrust on 08/06/06.
//  Copyright 2006 ritchie argue. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SDEServerRenderer.h"


@interface SDEServerController : NSObject {	
	NSSocketPort *listeningSocketPort;
	NSFileHandle *listeningFileHandle;
	NSNetService *netService;
	
	NSMutableArray *clientConnections;
	
	SDEServerRenderer *renderer;
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

@end
