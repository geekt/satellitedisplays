//
//  NSSocketPort_Port.h
//  ned mac
//
//  Created by thrust on 06-09-28.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <netinet/in.h>															// imports required for socket initialization


@interface NSSocketPort (Port)

-(in_port_t) port;

@end
