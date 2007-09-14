//
//  NSSocketPort_Port.m
//  ned mac
//
//  Created by thrust on 06-09-28.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NSSocketPort_Port.h"


@implementation NSSocketPort (Port)

/*!
    @method     port
    @abstract   why isn't there just a -port method on NSSocketPort? jeez
    @discussion <#comprehensive description#>
*/
-(in_port_t)
port {
	struct sockaddr_in name;
	socklen_t namelen = sizeof(name);
	getsockname([self socket], (struct sockaddr *) &name, &namelen);
	
	return name.sin_port;
}

@end
