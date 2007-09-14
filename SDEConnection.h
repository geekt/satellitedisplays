//
//  SDEConnection.h
//  ned mac
//
//  Created by thrust on 06-10-05.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SDEConnection : NSObject {
	NSInputStream *inputStream;
	NSOutputStream *outputStream;
	BOOL connected;
	
	// write
	BOOL outputSpaceAvailable;
	NSMutableArray *fifo;
	NSMutableData *outputData;
	unsigned int writeCursor;
	
	// read
	id _delegate;
	NSFileHandle *fileHandle;
	NSMutableData *inputData;
}

-(id) initWithFileHandle:(NSFileHandle *) aFileHandle;
-(id) initWithNetService:(NSNetService *) netService;

-(void) write:(NSObject *) object;												// write

-(id) delegate;																	// read
-(void) setDelegate:(id)newDelegate;

-(BOOL) connected;																// connection management
-(void) setConnected:(BOOL)connected;

@end

@interface NSObject (SDEConnectionDelegate)

-(void) connection:(SDEConnection *)aConnection receive:(NSObject *)anObject;

@end