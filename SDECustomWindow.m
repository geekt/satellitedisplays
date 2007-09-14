//
//  SDECustomWindow.m
//  ned mac
//
//  Created by thrust on 11/13/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SDECustomWindow.h"


@implementation SDECustomWindow

/*! ----------------------------+---------------+-------------------------------
@discussion
based on CustomWindow.m from the RoundTransparentWindow sample code.
this lets us draw any shaped contents as though it is the entire window.
*/
- (id)
initWithContentRect: (NSRect) contentRect
		  styleMask: (unsigned int) aStyle
			backing: (NSBackingStoreType) bufferingType
			  defer: (BOOL) flag
{
    if (self = [super initWithContentRect: contentRect
                                styleMask: NSBorderlessWindowMask
                                  backing: bufferingType
                                    defer: flag]) {
		// other initialization
		//[self setBackgroundColor: [NSColor clearColor]];
		
		// can make this window draggable here, or we can
		// write it ourself as below. this seems easier, and it clips to the correct
		// region, instead of letting us drag up under the menu bar.
		//[self setMovableByWindowBackground:YES];
		
		//[self setLevel: NSStatusWindowLevel];
		
		//[self setAlphaValue: 1.0f];
		
		// not opaque means that the window itself has no opacity, but contents
		// will. by correctly masking contents, any shaped window can be drawn.
		// this, coupled with the animation, is causing problems with clicking
		// through the window. how can we solve that?
		//[self setOpaque: NO];
		
		//[self setHasShadow: YES];
    }
    
    return self;
}

// Custom windows that use the NSBorderlessWindowMask can't become key by default.  Therefore, controls in such windows
// won't ever be enabled by default.  Thus, we override this method to change that.
// don't really care about controls, so can this for now.
//- (BOOL)
//	canBecomeKeyWindow {
//    return YES;
//}

/*! ----------------------------+---------------+-------------------------------
@discussion
so here we let the user move the window. when this gets going for reals,
do we want to let the user on the target computer move the windows, or
only the user on the source (i.e. based on where the window is coming from?)

I think on the target, the user should be able to grab in the regular window
move places (titlebar), but in the content rect should switch the cursor
to a not allowed symbol.
*/
//Once the user starts dragging the mouse, we move the window with it. We do this because the window has no title
//bar for the user to drag (so we have to implement dragging ourselves)
//- (void)
//mouseDragged:(NSEvent *)theEvent {
//   NSPoint currentLocation;
//   NSPoint newOrigin;
//   NSRect  screenFrame = [[NSScreen mainScreen] frame];
//   NSRect  windowFrame = [self frame];
//   
//   //grab the current global mouse location; we could just as easily get the mouse location 
//   //in the same way as we do in -mouseDown:
//    currentLocation = [self convertBaseToScreen:[self mouseLocationOutsideOfEventStream]];
//    newOrigin.x = currentLocation.x - initialLocn.x;
//    newOrigin.y = currentLocation.y - initialLocn.y;
//    
//    // Don't let window get dragged up under the menu bar
//    if( (newOrigin.y+windowFrame.size.height) > (screenFrame.origin.y+screenFrame.size.height) ){
//		newOrigin.y=screenFrame.origin.y + (screenFrame.size.height-windowFrame.size.height);
//    }
//    
//    //go ahead and move the window to the new location
//    [self setFrameOrigin:newOrigin];
//}

//We start tracking the a drag operation here when the user first clicks the mouse,
//to establish the initial location.
//- (void)
//mouseDown:(NSEvent *)theEvent {    
//    NSRect  windowFrame = [self frame];
//
//    //grab the mouse location in global coordinates
//   initialLocn = [self convertBaseToScreen:[theEvent locationInWindow]];
//   initialLocn.x -= windowFrame.origin.x;
//   initialLocn.y -= windowFrame.origin.y;
//}

@end
