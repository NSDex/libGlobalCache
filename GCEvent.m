/*
 *  GCEvent.m
 *  libGlobalCache
 *
 *  Created on 7/30/09.
 *  Copyright (c) 2009-2013 by NSDex. All rights reserved.
 */

#import "GCEvent.h"


@implementation GCEvent

@synthesize module;
@synthesize connector;
@synthesize sensorIsClosed;

+ (GCEvent*)checkIfEvent:(NSData*)data {
	char *bytes = (char *)[data bytes];
	int pos = 0;
	if(!strncmp(bytes, "statechange", 11)) { //They are equal
#ifdef DEBUG
		printf("%s - %s: Event of type statechange received\n", GCDebugHeader, "GCEvent");
#endif
		GCEvent *newEvent = [[GCEvent alloc] init];
		pos = 11;
		if(bytes[pos] != ',') { [newEvent release]; return nil; }
		pos++;
		char buf[2];
		buf[0] = bytes[pos]; buf[1] = '\0';
		newEvent.module = atoi(buf);
		pos++;
		if(bytes[pos] != ':') { [newEvent release]; return nil; }
		pos++;
		buf[0] = bytes[pos]; buf[1] = '\0';
		newEvent.connector = atoi(buf);
		pos++;
		if(bytes[pos] != ',') { [newEvent release]; return nil; }
		pos++;
		if(bytes[pos] == '1') newEvent.sensorIsClosed = YES;
		else if(bytes[pos] == '0') newEvent.sensorIsClosed = NO;
		else { [newEvent release]; return nil; }
		
		return [newEvent autorelease];
	}
	return nil;
}

@end
