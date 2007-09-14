//
//  SDEConnection.m
//  ned mac
//
//  Created by thrust on 06-10-05.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SDEConnection.h"

//#import "SDEString.h"
//#import "SDECursorRequest.h"
//#import "SDECursorUpdate.h"
//#import "SDEFrameRequest.h"

#import <Foundation/NSDebug.h>


@interface SDEConnection (ForwardDecls)
-(void) openStreams;
-(void) closeStreams;
@end


@implementation SDEConnection

/*! ----------------------------+---------------+-------------------------------
	@method		initWithFileHandle:
	@abstract	set up NSStreams around a socket referenced by file handle.
	@discussion	must retain the file handle to ensure the connection stays open
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(id)
initWithFileHandle:(NSFileHandle *) aFileHandle {
	self = [super init];
	if (self != nil) {
		fileHandle = [aFileHandle retain];										// hold on to the file handle for the duration
																				// of the connection
		
		CFReadStreamRef readStream;
		CFWriteStreamRef writeStream;
		
		NSLog(@"creating stream pair with socket %d", [aFileHandle fileDescriptor]);

		CFStreamCreatePairWithSocket(kCFAllocatorDefault,
									 [aFileHandle fileDescriptor],
									 &readStream,
									 &writeStream);
		
		inputStream = (NSInputStream *) readStream;
		outputStream = (NSOutputStream *) writeStream;
		
		[self openStreams];
	}
	return self;
}


-(id)
initWithNetService:(NSNetService *) netService {
	self = [super init];
	if (self) {
		
		NSLog(@"connecting to %@", [netService valueForKey:@"name"]);
		if ([netService getInputStream:&inputStream outputStream:&outputStream]) {
			[self openStreams];													// open streams for asynchronous comm..
			
			[self setConnected:YES];											// we're connected
		} else {
			// couldn't get streams
		}
	}
	
	return self;
}


-(void)
dealloc {
	NSLog(@"%@: dealloc", self);
	
	[self closeStreams];
	
	if (fileHandle) {
		[fileHandle closeFile];
		[fileHandle release];
		fileHandle = nil;
	}
	
	[super dealloc];
}


#pragma mark -
-(id)
delegate {
	return _delegate;
}


-(void)
setDelegate:(id)newDelegate {
	_delegate = newDelegate;
}


#pragma mark -
#pragma mark kvc/kvo compliant accessors
-(BOOL)
	connected {
	return connected;
}


-(void)
setConnected:(BOOL)flag {
	connected = flag;
	// if connected == NO, close streams?
}


#pragma mark -
- (void)
openStreams {
	NSLog(@"opening streams");
	
	fifo = [[NSMutableArray arrayWithCapacity:1024] retain];					// set up fifo to buffer the output stream
	writeCursor = 0;
	
	inputData = nil;
	//readCursor = 0;
	
    [inputStream retain];
    [outputStream retain];
	
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
	
	// are we ok to be reading/writing on the default run loop?
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	
    [inputStream open];
    [outputStream open];
}


- (void)
closeStreams {
	NSLog(@"%@: closing streams", self);
	
    [inputStream close];
    [outputStream close];
	
    [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	
    [inputStream setDelegate:nil];
    [outputStream setDelegate:nil];
	
    [inputStream release];
    [outputStream release];
	
    inputStream = nil;
    outputStream = nil;
	
	[fifo release];
	fifo = nil;
}


#pragma mark -
/*! ----------------------------+---------------+-------------------------------
	@method		flushFifo
	@abstract	serialize an NSObject to an NSOutputStream
	@discussion	convert NSObject to NSData, put data length + data on the wire
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
flushFifo {
	NSAssert(outputStream, @"outputStream == nil");
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (!outputSpaceAvailable) {
		//NSLog(@"\t%@ attempting to flush with no space available, skipping and waiting", self);
	} else if ([fifo count] <= 0) {
		//NSLog(@"\t%@ attempting to flush with no data available, skipping and waiting", self);
	} else {
		if (writeCursor == 0) {
			NSObject *object = [fifo objectAtIndex:0];							// get a new object
			
			NSData *objectData = [NSArchiver archivedDataWithRootObject:object];
			
			unsigned int length = EndianU32_NtoB([objectData length]);			// swizzle native to big
			
			outputData = [NSMutableData dataWithBytes:&length length:sizeof(length)];	// prepend object length
			[outputData appendData:objectData];
			
			[outputData retain];												// released once all data has been written
			//NSLog(@"created %d byte object to send", length);
		}		
		
		unsigned int totalRemaining = [outputData length] - writeCursor;
		
		void *marker = (void *)[outputData bytes] + writeCursor;
		
		int currentRemaining = MIN(totalRemaining, 4096);						// want to break large objects into smaller chunks
		
		//NSLog(@"\t%@ attempting to write %d bytes", self, currentRemaining);
		
		int actuallyWritten = [outputStream write:marker maxLength:currentRemaining];
		
		//NSLog(@"\t%@ actually wrote %d bytes", self, actuallyWritten);
		
		NSAssert(actuallyWritten != -1, @"stream error");
		
		totalRemaining -= actuallyWritten;
		writeCursor += actuallyWritten;
		
		if (totalRemaining <= 0) {												// successfully wrote whole object
			writeCursor = 0;
			[fifo removeObjectAtIndex:0];										// no point doing this here instead of earlier, since
																				// we have no fallback plan to deal with stream errors?
			
			[outputData release];
		}
		
		outputSpaceAvailable = NO;												// we wrote some data, so reset outputSpaceAvailable
	}
	
	[pool release];
}


/*! ----------------------------+---------------+-------------------------------
	@method		write:
	@abstract	write an object out to the stream
	@discussion	<#comprehensive description#>
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
write:(NSObject *)anObject {
	[fifo addObject:anObject];
	[self flushFifo];
}


/*! ----------------------------+---------------+-------------------------------
	@method		readFromStream
	@abstract	reassemble into full objects here, before passing up to delegate
	@discussion	<#comprehensive description#>
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
readFromStream {
	static uint8_t buf[16 * 1024];
	uint8_t *buffer = NULL;
	unsigned int len = 0;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];					// network events don't empty the pool, so
																				// we have to be careful to do it ourselves.
	
	if (![inputStream getBuffer:&buffer length:&len]) {
		int amount = [inputStream read:buf maxLength:sizeof(buf)];
		buffer = buf;
		len = amount;
		//NSLog(@"NSInputStream buffer not available, reading %d bytes into local buffer", len);
	} else {
		//NSLog(@"got %d byte NSInputStream buffer", len);
	}
	
	while (0 < len) {
		static unsigned int dataSize;
		static unsigned int remainingDataToRead;
		
		if (inputData == nil) {
			dataSize = *(unsigned int *)buffer;									// fresh object, so read off length
			dataSize = EndianU32_BtoN(dataSize);								// swizzle
			
			remainingDataToRead = dataSize;
			
			buffer += sizeof(dataSize);											// adjust buffer pointer up to account for length removal
			len -= sizeof(dataSize);
			
			//NSLog(@"creating %d byte NSData", dataSize);
			inputData = [[NSMutableData alloc] initWithCapacity:dataSize];
		}
		
		unsigned int appendLength = MIN(len, remainingDataToRead);
		
		//NSLog(@"appending %d bytes to NSData", appendLength);
		[inputData appendBytes:buffer length:appendLength];

		buffer += appendLength;													// adjust pointers
		len -= appendLength;
		remainingDataToRead -= appendLength;
		
		// if appended enough bytes
		if ([inputData length] >= dataSize) {
			if ([inputData length] > dataSize) {
				// how does this happen?
				NSLog(@"%@: got too much data on stream %@! length = %d, should be %d", self, fileHandle, [inputData length], dataSize);
			}
			
			NSObject *object = [NSUnarchiver unarchiveObjectWithData:inputData];
			
			if (object != nil) {
				if ([_delegate respondsToSelector:@selector(connection:receive:)]) {
					//NSLog(@"passing object %@ to delegate", object);
					[_delegate connection:self receive:object];
				} else {
					NSLog(@"no delegate to handle object: %@", object);
				}
				
			} else {
				NSLog(@"could not unarchive object");
			}
			
			[inputData release];
			inputData = nil;
		}
	}
	
	[pool release];
}

/*! ----------------------------+---------------+-------------------------------
	@method		stream: handleEvent:
	@abstract	<#brief description#>
	@discussion	analogous to [RFBConnection readData:]
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
stream:(NSStream *) aStream handleEvent:(NSStreamEvent)streamEvent {
	NSString *streamType;
	
	switch(streamEvent) {
		case NSStreamEventHasBytesAvailable:
			//NSLog(streamType, @"has bytes available");
			[self readFromStream];
            break;
			
        case NSStreamEventEndEncountered:
			streamType = [NSString stringWithFormat:@"\t%@ %@ %%@", self, [[aStream class] description]];
			NSLog(streamType, @"end encountered");
			[self setConnected:NO];												// parent calls closeStreams
            break;
			
        case NSStreamEventHasSpaceAvailable:
			//NSLog(streamType, @"has space available, attempting flush");
			outputSpaceAvailable = YES;
			[self flushFifo];													// try sending data if we have any
			break;
			
        case NSStreamEventErrorOccurred:
			streamType = [NSString stringWithFormat:@"\t%@ %@ %%@", self, [[aStream class] description]];
			NSLog(streamType, @"error occurred");
			
			NSError *theError = [aStream streamError];
			NSLog(@"error %i: %@", [theError code], [theError localizedDescription]);
			
			[self setConnected:NO];												// shut 'er down, parent calls closeStreams
			break;
			
        case NSStreamEventOpenCompleted:
			streamType = [NSString stringWithFormat:@"\t%@ %@ %%@", self, [[aStream class] description]];
			NSLog(streamType, @"open completed");								// now available for sending/receiving
			break;
			
        case NSStreamEventNone:
			streamType = [NSString stringWithFormat:@"\t%@ %@ %%@", self, [[aStream class] description]];
			NSLog(streamType, @"none");
			break;
			
        default:
			streamType = [NSString stringWithFormat:@"\t%@ %@ %%@", self, [[aStream class] description]];
			NSLog(streamType, @"default");
            break;
	}
}

@end
