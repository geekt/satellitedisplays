/**
 rwproto.h - header file for the remote window protocol version 1.0
 
 I'm substantially borrowing ideas from rfbproto.h here. note that our
 definition of server and client are reversed from vnc:
 
 the remote display is served to the client, but the client "serves"
 image data to the display server.
*/

#pragma mark initial handshake

#define rwProtocolVersionFormat "rw %02d.%02d\n"
#define rwProtocolMajorVersion 1
#define rwProtocolMinorVersion 0

#pragma mark authentication

// no auth supported at this time
#define rwNoAuth 0

typedef struct {
	UInt32 numberOfSecurityTypes;
	// array of types
} rwAuthMessage;

#pragma mark init

typedef struct {
	UInt32 nameLength;
	// followed by unichar namelength
} rwClientInitMsg;

typedef struct {
	//
} rwServerInitMsg;

//-----------------------------------------------------------------------------
#pragma mark server -> client message types

#define rwWindowUpdate 0

//-----------------------------------------------------------------------------
#pragma mark client -> server message types

#define rwWindowUpdateRequest 3

//-----------------------------------------------------------------------------
#pragma mark encoding types

#define rwEncodingTiff 90
#define rwEncodingMoveWindow 99

//-----------------------------------------------------------------------------
#pragma mark client -> server message definitions

/*-----------------------------------------------------------------------------
 * FramebufferUpdate - a block of rectangles to be copied to the framebuffer.
 *
 * This message consists of a header giving the number of rectangles of pixel
 * data followed by the rectangles themselves.  The header is padded so that
 * together with the type byte it is an exact multiple of 4 bytes (to help
 * with alignment of 32-bit pixels):
 */

typedef struct {
    UInt8 type;			/* always rfbFramebufferUpdate */
    UInt8 pad;
    UInt16 nRects;
    /* followed by nRects rectangles */
} rwWindowUpdateMsg;

/*
 * Each rectangle of pixel data consists of a header describing the position
 * and size of the rectangle and a type word describing the encoding of the
 * pixel data, followed finally by the pixel data.  Note that if the client has
 * not sent a SetEncodings message then it will only receive raw pixel data.
 * Also note again that this structure is a multiple of 4 bytes.
 */

typedef struct {
    rwRectangle r;
    UInt32 encoding;	/* one of the encoding types rfbEncoding... */
} rwWindowUpdateRectHeader;

//-----------------------------------------------------------------------------
#pragma mark client -> server message definitions

// since we have multiple windows, we want to request on a per-window basis. but
// at the same time, we are going to assume we're running on an os that never
// invalidates the whole window on us, since it's pretty stupid to be going over
// the network to get data that we really should be cacheing locally. the complexity
// added by sorting out invalidation rects for a stack of windows isn't worth the
// hassle over just sending a single updateAllWindowsRequest.

typedef struct {
    UInt32 type;			/* always rfbFramebufferUpdateRequest */
    UInt32 incremental;
} rwWindowUpdateRequestMsg;

/*-----------------------------------------------------------------------------
 * Structure used to specify a rectangle. This structure is a multiple of 4
 * bytes so that it can be interspersed with 32-bit pixel data without
 * affecting alignment.
 * a target wid has been added so the rect is applied to the correct window
 */
typedef struct {
    UInt16 x;
    UInt16 y;
	
    UInt16 w;
    UInt16 h;
	
	UInt32 wid;
} rwRectangle;



