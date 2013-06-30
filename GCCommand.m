/*
 *  GCCommand.m
 *  libGlobalCache
 *
 *  Created on 6/28/09.
 *  Copyright (c) 2009-2013 by NSDex. All rights reserved.
 */

#import "GCCommand.h"


@implementation GCCommand

@synthesize commandType;
@synthesize doNotWait;
@synthesize commandData;
@synthesize pos;
@synthesize irid;
@synthesize senThread;
@synthesize sen;
@synthesize callback;
@synthesize context;
@synthesize response;
@synthesize next;

- (id)initWithCommand:(GCCommandType)c data:(NSData*)data sender:(id)sender callback:(SEL)cb context:(NSObject*)ct {
	if(self = [super init]) {
		commandData = data; pos = 0;
		[commandData retain];
		callback = cb;
		context = ct;
		if(ct != nil) { [context retain]; }
		commandType = c;
		if(c == GCBLINK) doNotWait = YES; else doNotWait = NO;
		response = [[GCResponse alloc] initWithType:c];
		senThread = [NSThread currentThread];
		sen = sender;
		irid = -1;
	}
	return self;
}

- (void)dealloc {
	[commandData release];
	[response release];
	if(context != nil) { [context release]; }
	[super dealloc];
}

@end
