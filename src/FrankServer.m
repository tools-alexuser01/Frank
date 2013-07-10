//
//  FrankServer.m
//  Frank
//
//  Created by phodgson on 5/24/10.
//  Copyright 2010 ThoughtWorks. See NOTICE file for details.
//

#import "FrankServer.h"

#import "HTTPServer.h"
#import "RoutingHTTPConnection.h"
#import "StaticResources.h"
#import "DumpCommandRoute.h"
#import "ImageCaptureRoute.h"
#import "FrankCommandRoute.h"
#import "ExitCommand.h"
#import "AppCommand.h"
#import "AccessibilityCheckCommand.h"
#import "EnginesCommand.h"
#import "SuccessCommand.h"
#import "MapOperationCommand.h"
#import "ResolutionCommand.h"

#import "DeviceRoute.h"
#import "VersionRoute.h"
#import "OrientationRoute.h"

#if TARGET_OS_IPHONE
#import "LocationCommand.h"
#import "IOSKeyboardCommand.h"
#else
#import "OSXKeyboardCommand.h"
#endif

#ifndef FRANK_PRODUCT_VERSION
#define FRANK_PRODUCT_VERSION UNKNOWN
#endif

#define xstr(s) str(s)
#define str(s) #s
#define VERSIONED_NAME "Frank iOS Server " xstr(FRANK_PRODUCT_VERSION)
const unsigned char frank_what_string[] = "@(#)" VERSIONED_NAME "\n";

static NSUInteger __defaultPort = FRANK_SERVER_PORT;
@implementation FrankServer

+ (void)setDefaultHttpPort:(NSUInteger)port
{
    __defaultPort = port;
}
- (id) initWithDefaultBundle {
	return [self initWithStaticFrankBundleNamed: @"frank_static_resources"];
}

- (id) initWithStaticFrankBundleNamed:(NSString *)bundleName
{    
	self = [super init];
	if (self != nil) {
		if( ![bundleName hasSuffix:@".bundle"] )
			bundleName = [bundleName stringByAppendingString:@".bundle"];
        
        FrankCommandRoute *frankCommandRoute = [FrankCommandRoute singleton];

        StaticResources *staticResources = [[[StaticResources alloc] initWithStaticResourceSubDir:bundleName] autorelease];
        [[RequestRouter singleton]registerRoutingEntry:staticResources];
        
        [self handleGetAt:@"/device"
                     with:^{
                         return [[[DeviceRoute alloc] init] autorelease];
                     }];

        [self handleGetAt:@"/version"
                     with:^{
                         return [[[VersionRoute alloc] initWithVersion:[NSString stringWithFormat:@"%s",xstr(FRANK_PRODUCT_VERSION)]]autorelease];
                     }];
        
#if TARGET_OS_IPHONE
        [self handleGetOrPostAt:@"/orientation"
                           with:^{
                               return [[[OrientationRoute alloc] init] autorelease];
                           }];
#else
        [frankCommandRoute registerCommand:[[[SuccessCommand alloc]init]autorelease] withName:@"orientation"];
#endif
        
		
        [frankCommandRoute registerCommand:[[[ResolutionCommand alloc] init] autorelease] withName:@"resolution"];
		[frankCommandRoute registerCommand:[[[AccessibilityCheckCommand alloc] init]autorelease] withName:@"accessibility_check"];
		[frankCommandRoute registerCommand:[[[AppCommand alloc] init]autorelease] withName:@"app_exec"];
        [frankCommandRoute registerCommand:[[[EnginesCommand alloc] init]autorelease] withName:@"engines"];
        [frankCommandRoute registerCommand:[[[ExitCommand alloc] init] autorelease] withName:@"exit"];
        [frankCommandRoute registerCommand:[[[MapOperationCommand alloc]init]autorelease] withName:@"map"];
        
#if TARGET_OS_IPHONE
        [frankCommandRoute registerCommand:[[[LocationCommand alloc]init]autorelease] withName:@"location"];
        [frankCommandRoute registerCommand:[[[IOSKeyboardCommand alloc] init]autorelease] withName:@"type_into_keyboard"];
#else
        [frankCommandRoute registerCommand:[[[SuccessCommand alloc]init]autorelease] withName:@"orientation"];
        [frankCommandRoute registerCommand:[[[SuccessCommand alloc]init]autorelease] withName:@"location"];
        [frankCommandRoute registerCommand:[[[OSXKeyboardCommand alloc] init]autorelease] withName:@"type_into_keyboard"];
#endif
        
		[[RequestRouter singleton] registerRoute:frankCommandRoute];
        
        
        DumpCommandRoute *dumpCaptureCommand = [[[DumpCommandRoute alloc] init] autorelease];
		[[RequestRouter singleton] registerRoute:dumpCaptureCommand];        
        
        ImageCaptureRoute *imageCaptureCommand = [[[ImageCaptureRoute alloc] init] autorelease];
		[[RequestRouter singleton] registerRoute:imageCaptureCommand];
		
		_httpServer = [[[HTTPServer alloc]init] retain];
		
		[_httpServer setName:@"Frank UISpec server"];
		[_httpServer setType:@"_http._tcp."];
		[_httpServer setConnectionClass:[RoutingHTTPConnection class]];
		[_httpServer setPort:__defaultPort];
		NSLog( @"Creating the server: %@", _httpServer );
	}
	return self;
}

- (BOOL) startServer{
    NSLog( @"Starting server %s", VERSIONED_NAME );
	NSError *error;
	if( ![_httpServer start:&error] ) {
		NSLog(@"Error starting HTTP Server:");// %@", error);
		return NO;
	}
	return YES;
}

- (void) dealloc
{
	[_httpServer release];
	[super dealloc];
}

- (void) handleGetAt:(NSString*)path with:(HandlerCreator)handlerCreator{
    
    [[RequestRouter singleton] registerRouteForPath:path
                                  supportingMethods:@[@"GET"]
                                          createdBy:handlerCreator];
}

- (void) handleGetOrPostAt:(NSString*)path with:(HandlerCreator)handlerCreator{
    
    [[RequestRouter singleton] registerRouteForPath:path
                                  supportingMethods:@[@"GET",@"POST"]
                                          createdBy:handlerCreator];
}


@end
