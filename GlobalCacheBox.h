/*
 *  GlobalCacheBox.h
 *  libGlobalCache
 *
 *  Created on 6/27/09.
 *  Copyright (c) 2009-2013 by NSDex. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "LLThreadQueue.h"
#import "GCCommand.h"
#import "GCEvent.h"

@interface GlobalCacheBox : NSObject {
	NSThread *parentThread; NSObject *parent;
	SEL boxConnectionCallback;
	
	NSThread *connectionHandler;
	
	GCBoxModel boxType;
	NSString *boxAddress;
	NSString *boxMAC;
	NSString *boxName;
	
	NSInputStream *iStream;
	NSOutputStream *oStream;
	NSMutableData *current;
	LLThreadQueue *commandQueue;
	GCCommand *activeCommand; //Thread Lock
	int currentIRID;
	bool ready; NSLock *readyLock; //Thread Lock
	NSTimer *failTimer;
}

- (id)initWithParent:(NSObject*)p withAddress:(NSString*)address withMAC:(NSString*)mac withName:(NSString*)name ofType:(GCBoxModel)model withCallback:(SEL)cb;
- (void)connect;
- (BOOL)commandsAreWaiting;
- (BOOL)removeCommandFromStack:(GCCommand*)command;

//Commands
- (GCCommand*)getDevices:(id)sender callback:(SEL)cb context:(NSObject*)ct;
- (GCCommand*)getVersion:(int)module sender:(id)sender callback:(SEL)cb context:(NSObject*)ct;
- (GCCommand*)blink:(BOOL)shouldBlink sender:(id)sender callback:(SEL)cb context:(NSObject*)ct;
- (GCCommand*)sendir:(int)module connector:(int)connector frequency:(NSUInteger)frequency count:(int)count offset:(int)offset data:(char*)data
		sender:(id)sender callback:(SEL)cb context:(NSObject*)ct;
- (GCCommand*)stopir:(int)module connector:(int)connector sender:(id)sender callback:(SEL)cb context:(NSObject*)ct;
- (GCCommand*)getState:(int)module connector:(int)connector sender:(id)sender callback:(SEL)cb context:(NSObject*)ct;
- (GCCommand*)setState:(BOOL)closed module:(int)module connector:(int)connector sender:(id)sender callback:(SEL)cb context:(NSObject*)ct;

@end
