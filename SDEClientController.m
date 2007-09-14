//
//  NedClientController.m
//  ned mac
//
//  Created by thrust on 09/06/06.
//  Copyright 2006 ritchie argue. All rights reserved.
//

#import "SDEClientController.h"

#import "SDEService.h"
#import "DEGTXTRecord.h"
#import "SDECommon.h"
#import "SDEFramegrabber.h"


@interface SDEClientController (forwardDecls)
-(void)setupServiceBrowser;
-(BOOL)searching;
-(void)setSearching:(BOOL)search;
@end


@implementation SDEClientController

/*! ----------------------------+---------------+-------------------------------
	@method		+initialize
	@abstract	<#brief description#>
	@discussion	set up initial values for defaults. my goodness this is easy.
	@param		
	@result		
--------------------------------+---------------+---------------------------- */
+(void)
initialize {
	NSLog(@"+initialize");
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];			
	
	NSData *archivedColor = [NSArchiver archivedDataWithRootObject:[NSColor blueColor]];
	[dictionary setObject:archivedColor forKey:@"CursorColor"];
	
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:dictionary];
}


-(id)
init {
	NSLog(@"-init");
	
	self = [super init];
	if (self) {
		properties = [[NSMutableDictionary alloc] init];
		
		nedDisplays = [[NSMutableArray alloc] init];
		
		[properties setValue:[NSNumber numberWithBool:NO] forKeyPath:@"searching"];
		[properties setValue:[NSNumber numberWithInt:0] forKeyPath:@"resolveCount"];
		[properties setValue:[NSNumber numberWithInt:0] forKeyPath:@"receivingTXTCount"];
		[properties setValue:[NSNumber numberWithBool:NO] forKeyPath:@"animateProgressIndicator"];
	}
	return self;
}


/*! ----------------------------+---------------+-------------------------------
	@method		dealloc
	@abstract	clean up after ourselves
	@discussion	this isn't getting called by anything. why is that? I would
				expect that whatever called -init would also call -dealloc.
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
dealloc {
	NSLog(@"%@ dealloc", self);
	
	[nedDisplays release];
	
	[properties release];
	
	[super dealloc];
}


-(void)
awakeFromNib {
	NSLog(@"-awakeFromNib");

	[[NSApplication sharedApplication] setDelegate: self];						// register to receive -applicationShouldTerminate:
	
	serviceBrowser = [[NSNetServiceBrowser alloc] init];
	[serviceBrowser setDelegate:self];
	
	// Passing in "" for the domain causes us to browse in the default browse domain,
    // which currently will always be "local".  The service type should be registered
    // with IANA, and it should be listed at <http://www.iana.org/assignments/port-numbers>.
    // At minimum, the service type should be registered at <http://www.dns-sd.org/ServiceTypes.html>
    [serviceBrowser searchForServicesOfType:kDisplayServiceString inDomain:@""];
	
}


/*! ----------------------------+---------------+-------------------------------
	@method		-applicationShouldTerminate:
	@abstract	<#brief description#>
	@discussion	clean up existing connections, eventually disable dummy
				framebuffer(s)
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(NSApplicationTerminateReply)
applicationShouldTerminate:(NSApplication *)sender {
	NSLog(@"%@ applicationShouldTerminate", self);
	
	[serviceBrowser release];
	
	return NSTerminateNow;
}


#pragma mark -
#pragma mark zeroconf


/*! ----------------------------+---------------+-------------------------------
	@abstract
		Found service, add it to the list
		start watching for TXTRecord updates
		
	@discussion
		This object is the delegate of its NSNetServiceBrowser object. We're
		only interested in services-related methods, so that's what we'll call.
*/
- (void)
netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser
   didFindService:(NSNetService *)aNetService 
	   moreComing:(BOOL)moreComing {
	   
	NSLog(@"found service: %@", [aNetService name]);
	
	// build a 'nedService' here:
	SDEService *nedService = [[SDEService alloc] initWithNetService:aNetService];
	
	// start listening for TXTRecords
	[aNetService startMonitoring];
	
	// observe changes to the receivingTXT property, to update
	// the progress indicator
	[nedService addObserver:self
		forKeyPath:@"properties.receivingTXT"
		options:NSKeyValueObservingOptionNew
		context:NULL];
	
	[nedService addObserver:self
		forKeyPath:@"properties.resolving"
		options:NSKeyValueObservingOptionNew
		context:NULL];
	
	
	NSMutableDictionary *nedDisplay = [NSMutableDictionary dictionaryWithObjectsAndKeys:nedService, @"nedService",
		[NSNumber numberWithInt:0], @"display",
		nil];
	
	// My collection controller isn’t displaying the current data…
	// This is typically due to your application modifying the collection
	// content in a manner that is not key-value-observing compliant.
	// Modifying an array using addObject: or removeObject: is not sufficient.	
	NSMutableArray *displays = [self mutableArrayValueForKey:@"nedDisplays"];
	[displays addObject:nedDisplay];
	
	
	// where does this get started?
    if(!moreComing) {
		[self setSearching:NO];
	}
}

/*!
    @method     netServiceBrowser: didRemoveService: moreComing:
    @abstract   service removal
    @discussion make sure we use kvc/kvo-compliant access to the array
*/
- (void)
netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser
 didRemoveService:(NSNetService *)aNetService
	   moreComing:(BOOL)moreComing {
	
	NSMutableArray *displays = [self mutableArrayValueForKey:@"nedDisplays"];
	NSEnumerator *enumerator = [displays objectEnumerator];
	NSMutableDictionary *display = nil;
	//SDEService *currentNedService;

	while (display = [enumerator nextObject]) {
		SDEService *nedService = [display valueForKeyPath:@"nedService"];
		if ([[nedService valueForKeyPath:@"properties.netService"] isEqual:aNetService]) {
			
			// remove observers
			[nedService removeObserver:self
							forKeyPath:@"properties.receivingTXT"];
			[nedService removeObserver:self
							forKeyPath:@"properties.resolving"];
				
			[displays removeObject:display];									// remove from list
			break;
		}
	}
	
	[aNetService stopMonitoring];
}


// Sent when browsing begins
- (void)
netServiceBrowserWillSearch:(NSNetServiceBrowser *)serviceBrowser {
	NSLog(@"browsing started");
	[self setSearching:YES];
}


// Sent when browsing stops
- (void)
netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)serviceBrowser {
	NSLog(@"browsing stopped");
	[self setSearching:NO];
}


// Error handling code
- (void)
handleError:(NSNumber *)error {
    NSLog(@"An error occurred. Error code = %d", [error intValue]);
    // Handle error here
}


// Sent if browsing fails
- (void)
netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser
	 didNotSearch:(NSDictionary *)errorDict {
	[self setSearching:NO];
	
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode]];
}


#pragma mark -
#pragma mark kvo

-(void)
observeValueForKeyPath:(NSString *)keyPath
			  ofObject:(id)object
				change:(NSDictionary *)change
			   context:(void *)context {
	
	if ([keyPath isEqual:@"properties.receivingTXT"]) {
		// how'm I going to hook this up? like a giant ref count I guess.
		// each time a YES comes in, incr. the count, and each time a NO
		// comes in, decr. when count > 0, then animate
		BOOL receiving = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if (receiving) {
			receivingTXTCount++;
		} else {
			receivingTXTCount--;
		}
		
		// trigger kvo out to ui
		[self setAnimateProgressIndicator:receiving];
	}
	
	if ([keyPath isEqual:@"properties.resolving"]) {
		BOOL resolving = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if (resolving) resolveCount++;
		else resolveCount--;
		
		// trigger kvo out to ui
		[self setAnimateProgressIndicator:resolving];
	}
	
	
	if ([keyPath isEqual:@"connected"]) {
		BOOL connected = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if (!connected) {
			NSLog(@"%@: removing connection", self);
			[object removeObserver:self forKeyPath:@"connected"];
			NSMutableDictionary *display = context;								// context is display this connection is associated with
			[display removeObjectForKey:@"connection"];
			[display removeObjectForKey:@"framegrabber"];						// this should release the framegrabber
		}
    }
}


#pragma mark -
#pragma mark kvc/kvo compliant accessors
-(BOOL)
animateProgressIndicator {
	return animateProgressIndicator;
}


-(void)
setAnimateProgressIndicator:(BOOL)animate {
	// coalesce progress items
	animateProgressIndicator = [self searching] || (receivingTXTCount > 0) || (resolveCount > 0);
}


-(BOOL)
searching {
	return searching;
}


-(void)
setSearching:(BOOL)search {
	searching = search;
	// trigger kvo
	[self setAnimateProgressIndicator:searching];
}


// display the correctly pluralized helper string
-(NSString *)
questionObjectNameForCurrentCount {
	return (([nedDisplays count] == 1) ? [SDEService objectName] : [SDEService objectNamePlural]);
}


#pragma mark -
/*!
    @method     connect:
    @abstract   connect to displays
    @discussion called by target/argument binding: table double-click or button-press
*/
-(void)
connect:(NSArray *) selectedDisplays {
	NSLog(@"connect button pressed for services: %@", selectedDisplays);
	
	NSEnumerator *enumerator = [selectedDisplays objectEnumerator];
	NSMutableDictionary *display;

	while (display = [enumerator nextObject]) {
		SDEService *currentNedService = [display valueForKey:@"nedService"];
		NSLog(@"currentNedService: %@", currentNedService);
	
		NSNetService *netService = [currentNedService valueForKeyPath:@"properties.netService"];
		
		SDEConnection *connection = [[SDEConnection alloc] initWithNetService:netService];
		
		if (connection) {
			[display setValue:connection forKey:@"connection"];					// add new connection to nedDisplays
			[connection release];
			
			[connection addObserver:self										// listen for disconnect notifications
						 forKeyPath:@"connected"
							options:NSKeyValueObservingOptionNew
							context:display];									// pass display as context for easier removal
			
			// create iodummyframebuffer
			
			// create frame grabber. one framegrabber per connection?
			SDEFramegrabber *framegrabber = [[SDEFramegrabber alloc] initWithConnection:connection];
			[display setValue:framegrabber forKey:@"framegrabber"];
			[framegrabber release];
			// set connection delegate to frame grabber
			[connection setDelegate:framegrabber];
			
			// send compy name for the connection list on the display
			NSString *compyName = (NSString *) SCDynamicStoreCopyComputerName(NULL, NULL);
			[connection write:compyName];
			
		} else {
			// failed
			return;
		}
	}
}


/*! ----------------------------+---------------+-------------------------------
	@method		disconnect
	@abstract	<#brief description#>
	@discussion	disconnect from some services, disconnect from all services at
				quit?
	@param		<#name#> <#description#>
	@result		<#description#>
--------------------------------+---------------+---------------------------- */
-(void)
disconnect {
	NSLog(@"%@: disconnect", self);
	
//	if (connection) {
//		[connection release];
//	}
	
}

@end
