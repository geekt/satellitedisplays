/* FilteringArrayController */

#import <Cocoa/Cocoa.h>

@interface FilteringArrayController : NSArrayController {
	NSString *searchString;
}

-(void) search:(id)sender;
-(NSString *) searchString;
-(void) setSearchString:(NSString *)newSearchString;

@end
