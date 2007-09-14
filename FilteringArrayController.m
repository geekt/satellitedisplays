#import "FilteringArrayController.h"

@implementation FilteringArrayController

- (void)search:(id)sender
{
    [self setSearchString:[sender stringValue]];
    [self rearrangeObjects];    
}


//- (id)newObject
//{
//    //newObject = [super newObject];
//    //[newObject setValue:@"First" forKey:@"firstName"];
//    //[newObject setValue:@"Last" forKey:@"lastName"];
//    //return newObject;
//	return nil;
//}



-(NSArray *)
arrangeObjects:(NSArray *)objects {
	
    if ((searchString == nil) || ([searchString isEqualToString:@""])) {
		return [super arrangeObjects:objects];   
	}
	
    NSMutableArray *matchedObjects = [NSMutableArray arrayWithCapacity:[objects count]];
    // case-insensitive search
    NSString *lowerSearch = [searchString lowercaseString];
    
	NSEnumerator *oEnum = [objects objectEnumerator];
    id item;	
    while (item = [oEnum nextObject]) {
		//  Use of local autorelease pool here is probably overkill, but may be useful in a larger-scale application.
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString *lowerName = [[item valueForKeyPath:@"properties.netService.name"] lowercaseString];
		if ([lowerName rangeOfString:lowerSearch].location != NSNotFound)
		{
			[matchedObjects addObject:item];
		}
		[pool release];
    }
    return [super arrangeObjects:matchedObjects];
}


//  - dealloc:
-(void)
dealloc {
    [self setSearchString: nil];    
    [super dealloc];
}

-(NSString *)
searchString {
	NSLog(@"searchString: %@", searchString);
	return searchString;
}

// - setSearchString:
-(void)
setSearchString:(NSString *)newSearchString {
    if (searchString != newSearchString) {
		NSLog(@"setSearchString: %@", newSearchString);
        [searchString autorelease];
        searchString = [newSearchString copy];
    }
}

@end
