/*
 *  GCEvent.h
 *  libGlobalCache
 *
 *  Created on 7/30/09.
 *  Copyright (c) 2009-2013 by NSDex. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "GCDefines.h"

@interface GCEvent : NSObject {
	GCEvents eventType;
	
	//statechange
	int module;
	int connector;
	BOOL sensorIsClosed;
}

@property(readwrite) int module;
@property(readwrite) int connector;
@property(readwrite) BOOL sensorIsClosed;

+ (GCEvent*)checkIfEvent:(NSData*)data;

@end
