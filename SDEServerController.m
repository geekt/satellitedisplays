//
//  SDEServerController.m
//  ned mac
//
//  Created by thrust on 08/06/06.
//  Copyright 2006 ritchie argue. All rights reserved.
//

#import "SDEServerController.h"
#import "NSScreen_UserDescription.h"
#import "NSSocketPort_Port.h"
#import "SDECommon.h"
#import "SDEConnection.h"

#import <Carbon/Carbon.h>

@interface SDEServerController (forwardDecls)
-(void) startSharing;
-(void) stopSharing;
@end

@implementation SDEServerController

/*! ----------------------------+---------------+-------------------------------
	@method		+initialize
	@abstract	<#brief description#>
	@discussion	set up initial values for defaults. my goodness this is easy
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
+(void)
initialize {
	NSLog(@"+initialize");
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];			
	
	NSNumber *number = [NSNumber numberWithBool:NO];
	[dictionary setObject:number forKey:@"coalesceDisplays"];
	
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:dictionary];
}


-(void)
awakeFromNib {
    [[NSApplication sharedApplication] setDelegate: self];						// receive -applicationShouldTerminate:
	
	clientConnections = [[NSMutableArray alloc] init];							// list of current connections
	
	renderer = [[SDEServerRenderer alloc] initWithClientConnections:clientConnections];	// one renderer for all connections
	
	[self addObserver:renderer													// tell the renderer to watch for connection changes
		   forKeyPath:@"clientConnections"
			  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
			  context:NULL];
	
	[self startSharing];
	
	NSLog(@"hiding menubar");
	
	// hide menubar
	SetSystemUIMode(kUIModeAllHidden,
					kUIOptionDisableProcessSwitch |
					kUIOptionDisableSessionTerminate);
}


-(NSApplicationTerminateReply)
applicationShouldTerminate:(NSApplication *)sender {
	
	// show menubar
	SetSystemUIMode(kUIModeNormal, 0);
	
	[self stopSharing];
	
	[self removeObserver:renderer
			  forKeyPath:@"clientConnections"];
	
	[renderer release];
	// unregister kv observers before releasing clientConnections
	[clientConnections release];
	
	return NSTerminateNow;
}


/*! ----------------------------+---------------+-------------------------------
	@method		-enumerateDisplays
	@abstract	<#brief description#>
	@discussion	test for display coalescing here
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(NSDictionary *)
enumerateDisplays {
	NSMutableDictionary *displayDict = [NSMutableDictionary dictionary];
	
	NSArray *displays = [NSScreen screens];
	
	NSEnumerator *displayEnumerator = [displays objectEnumerator];				// array enumerators return objects in order
	NSScreen *display;
	
	//BOOL coalesceDisplays = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"coalesceDisplays"] boolValue];
	
	int index = 0;
	while ((display = [displayEnumerator nextObject]) != nil) {
		// make displays with the same name unique 
		NSString *displayName = [NSString stringWithFormat:@"%d %@", index++, [display userDescription]];
		NSString *displayFrame = NSStringFromRect([display frame]);
		
		[displayDict setObject:displayFrame forKey:displayName];
		
		// todo: test size of TXTDict, if it goes too big remove an item and try again
	}
	
	NSLog(@"sharing screen configuration %@", displayDict);
	
	return displayDict;
}

#pragma mark -

/*! ----------------------------+---------------+-------------------------------
	@method		updateTXT
	@abstract	<#brief description#>
	@discussion	refactor this
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
updateTXT {
	NSMutableDictionary *TXTDict = [NSMutableDictionary dictionaryWithObject:@"1.0" forKey:@"txtvers"];
//	
//	NSArray *displays = [NSScreen screens];
//	
//	NSEnumerator *displayEnumerator = [displays objectEnumerator];				// array enumerators return objects in order
//	NSScreen *display;
//	
//	int index = 0;
//	while ((display = [displayEnumerator nextObject]) != nil) {
//		// make displays with the same name unique 
//		NSString *displayName = [NSString stringWithFormat:@"%d %@", index++, [display userDescription]];
//		NSString *displayFrame = NSStringFromRect([display frame]);
//		
//		[TXTDict setObject:displayFrame forKey:displayName];
//		
//		// todo: test size of TXTDict, if it goes too big remove an item and try again
//	}
//		
//	NSLog(@"sharing screen configuration %@", TXTDict);
	
	[TXTDict addEntriesFromDictionary:[self enumerateDisplays]];
	
	// convert to data
	NSData *TXTData = [NSNetService dataFromTXTRecordDictionary:TXTDict];
	
	BOOL success;
	if (TXTData != nil)
		success = [netService setTXTRecordData:TXTData];
	
	if (!success)
		NSLog(@"error creating TXTRecord");
}


/*! ----------------------------+---------------+-------------------------------
	@method		startSharing
	@abstract	listen for new connections, advertise listening port via zeroconf
	@discussion	<#comprehensive description#>
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
startSharing {
	
	listeningSocketPort = [[NSSocketPort alloc] init];							// listen on random port
	listeningFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:[listeningSocketPort socket]];
	
	NSLog(@"start sharing port %d", [listeningSocketPort port]);
	
	netService = [[NSNetService alloc] initWithDomain:@""						// use default domain
												 type:kDisplayServiceString
												 name:@""						// use computer name
												 port:[listeningSocketPort port]];
	
	[netService setDelegate:self];

    if(netService && listeningFileHandle) {
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(connectionReceived:)
													 name:NSFileHandleConnectionAcceptedNotification 
												   object:listeningFileHandle];
		
		[listeningFileHandle acceptConnectionInBackgroundAndNotify];
		
		[netService publish];
		
		[self updateTXT];
	}
}


-(void)
stopSharing {
	[netService stop];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSFileHandleConnectionAcceptedNotification 
												  object:listeningFileHandle];
	
	[listeningFileHandle release];												// There is at present no way to get an NSFileHandle to -stop-
																				// listening for events, so we'll just have to tear it down and
																				// recreate it the next time we need it.
	
	[listeningSocketPort release];
}


#pragma mark -


#pragma mark -
#pragma mark netService delegate methods
/*! ----------------------------+---------------+-------------------------------
	@method		netServiceWillPublish
	@abstract	<#brief description#>
	@discussion	Called to notify the delegate object that the publishing was
				able to start successfully. The delegate will not receive this
				message if the underlying network layer was not ready to begin
				a publication.
	@param		<#name#> <#description#>
	@result		<#description#>
*/
-(void)
netServiceWillPublish:(NSNetService *)sender {
	NSLog(@"");
}


-(void)
netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
	int error = [[errorDict objectForKey:NSNetServicesErrorCode] intValue];
    if(error == NSNetServicesCollisionError) {
		NSLog(@"a name collision occurred");
    } else {
		NSLog(@"publishing error: %d", error);
    }
	
    [listeningFileHandle release];
    listeningFileHandle = nil;
    [netService release];
    netService = nil;
	
	// alert and shut down?
}

/*! ----------------------------+---------------+-------------------------------
	@method		netServiceDidStop:
	@abstract	<#brief description#>
	@discussion	We'll need to release the NSNetService sending this, since we
				want to recreate it in sync with the socket at the other end.
				Since there's only the one NSNetService in this application, we
				can just release it.
	@param		sender <#description#>
	@result		
--------------------------------+---------------+---------------------------- */
- (void)
netServiceDidStop:(NSNetService *)sender {	
	[netService release];
    netService = nil;
}


#pragma mark -

/*! ----------------------------+---------------+-------------------------------
	@method		connectionReceived:
	@abstract	<#brief description#>
	@discussion	This object is also listening for notifications from its
				NSFileHandle. When an incoming connection is seen by the
				listeningFileHandle object, we get the NSFileHandle representing
				the near end of the connection. we use this fileHandle to open
				NSStreams in SDEConnection
	@param		aNotification <#description#>
	@result		
--------------------------------+---------------+---------------------------- */
- (void)
connectionReceived:(NSNotification *)aNotification {
	// get a handle to the endpoint
	NSFileHandle *incomingFileHandle = [[aNotification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
	
	NSLog(@"connection received %@", incomingFileHandle);
	
	SDEConnection *incomingConnection = [[SDEConnection alloc] initWithFileHandle:incomingFileHandle];
	
	[incomingConnection addObserver:self										// listen for disconnect notifications
						 forKeyPath:@"connected"
							options:NSKeyValueObservingOptionNew
							context:NULL];
	
	[incomingConnection setDelegate:self];										// handle first object received - client name

	NSMutableDictionary *nedClient = [NSMutableDictionary dictionaryWithObjectsAndKeys:incomingConnection, @"connection", nil];

	// My collection controller isn’t displaying the current data…
	// This is typically due to your application modifying the collection
	// content in a manner that is not key-value-observing compliant.
	// Modifying an array using addObject: or removeObject: is not sufficient.		
	NSMutableArray *clients = [self mutableArrayValueForKey:@"clientConnections"];
	[clients addObject:nedClient];
	
	[incomingConnection release];
	
	[listeningFileHandle acceptConnectionInBackgroundAndNotify];				// listen for new incoming connection
}



#pragma mark -
#pragma mark kvo

-(void)
observeValueForKeyPath:(NSString *)keyPath
			  ofObject:(id)object
				change:(NSDictionary *)change
			   context:(void *)context
{
    if ([keyPath isEqual:@"connected"]) {
		BOOL connected = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if (!connected) {
			[object removeObserver:self forKeyPath:@"connected"];				// unregister
			
			NSMutableArray *clients = [self mutableArrayValueForKey:@"clientConnections"];
			NSEnumerator *enumerator = [clients objectEnumerator];
			NSMutableDictionary *client = nil;
			while (client = [enumerator nextObject]) {
				SDEConnection *connection = [client objectForKey:@"connection"];
				if ([connection isEqual:object]) {
					break;
				}
			}

			if (client != nil) {
				NSLog(@"connection found, removing %@", [client objectForKey:@"name"]);
				[clients removeObject:client];
			}
			
			//[clientConnections removeObject:object];
		}
    }
}

#pragma mark -
#pragma mark delegate

-(void)
connection:(SDEConnection *)aConnection receive:(NSString *)clientName {
	NSLog(@"received client name: %@ on connection %@", clientName, aConnection);
	
	NSMutableArray *clients = [self mutableArrayValueForKey:@"clientConnections"];
	NSEnumerator *enumerator = [clients objectEnumerator];
	NSMutableDictionary *client;
	while (client = [enumerator nextObject]) {
		SDEConnection *connection = [client objectForKey:@"connection"];
		if ([connection isEqual:aConnection]) {
			NSLog(@"connection found in client array, adding %@", clientName);
			[client setValue:clientName forKey:@"name"];
			break;
		}
	}
	
	[aConnection setDelegate:renderer];											// pump incoming data at renderer
	// set up cursor for this incoming connection?
									
//	NSLog(@"requesting first frame");
//	SDEFrameRequest *frameRequest = [[SDEFrameRequest alloc] init];
//	[aConnection write:frameRequest];											// request first frame
//	[frameRequest release];
	[aConnection write:@"frameRequest"];
	
//	NSLog(@"requesting first cursor");
//	SDECursorRequest *cursorRequest = [[SDECursorRequest alloc] init];
//	[aConnection write:cursorRequest];											// request first cursor
//	[cursorRequest release];
	[aConnection write:@"cursorRequest"];
}

@end
