/*
 *  GCCommand.h
 *  libGlobalCache
 *
 *  Created on 6/28/09.
 *  Copyright (c) 2009-2013 by NSDex. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "LLThreadQueue.h"
#import "GCResponse.h"

@interface GCCommand : NSObject <LLThreadQueueProtocol> {
	GCCommandType commandType; BOOL doNotWait;
	NSData *commandData; int pos;
	int irid; //Used for the sendir command
	
	id sen; NSThread *senThread;
	SEL callback;
	NSObject *context;
	
	GCResponse *response;
	
	id next;
}

@property (nonatomic, readonly) GCCommandType commandType;
@property (readonly) BOOL doNotWait;
@property (nonatomic, retain) NSData *commandData;
@property (nonatomic, assign) int pos;
@property (readwrite) int irid;
@property (nonatomic, readonly) SEL callback;
@property (nonatomic, readonly) NSObject *context;
@property (nonatomic, readonly) NSThread *senThread;
@property (nonatomic, readonly) id sen;
@property (nonatomic, readonly) GCResponse *response;
@property (nonatomic, assign) id next;

- (id)initWithCommand:(GCCommandType)c data:(NSData*)data sender:(id)sender callback:(SEL)cb context:(NSObject*)ct;

@end
