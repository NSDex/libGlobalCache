/*
 *  GCResponse.m
 *  libGlobalCache
 *
 *  Created on 7/29/09.
 *  Copyright (c) 2009-2013 by NSDex. All rights reserved.
 */

#import "GCResponse.h"


@implementation GCResponse

@synthesize dataParsed;
@synthesize module;
@synthesize connector;
@synthesize devices;
@synthesize versionString;
@synthesize irid;
@synthesize sensorIsClosed;

- (id)init {
	return nil;
}

- (id)initWithType:(GCCommandType)t {
	if(self = [super init]) {
		type = t;
		dataParsed = NO;
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}

- (BOOL)parseData:(NSData*)data {
#ifdef DEBUG
	printf("%s - %s: Parse data called for Command\n", GCDebugHeader, "GCResponse");
#endif
	char *bytes = (char *)[data bytes];
	int pos = 0;
	
	//Find the response type
	if(!strncmp(bytes, "device", 6) && type == GCGETDEVICES) { 
		if(self.devices == nil) self.devices = [NSMutableArray arrayWithCapacity:0];
		pos = 6;
		if(bytes[pos] != ',') { return NO; }
		pos++;
		char buffer[256]; int i; for(i=0; i<sizeof(buffer); i++) { buffer[i] = bytes[pos+i]; if(buffer[i] == GCCommandTerminator) break; } buffer[i] = '\0';
		[self.devices addObject:[NSString stringWithCString:buffer encoding:NSASCIIStringEncoding]];
	}
	else if(!strncmp(bytes, "endlistdevices", 14) && type == GCGETDEVICES) {
		if(self.devices == nil) self.devices = [NSMutableArray arrayWithCapacity:0];
		pos = 14;
		dataParsed = YES;
		return YES;
	}
	else if(!strncmp(bytes, "version", 7) && type == GCGETVERSION) {
		pos = 7;
		if(bytes[pos] != ',') { return NO; }
		pos++;
		char buf[2];
		buf[0] = bytes[pos]; buf[1] = '\0';
		module = atoi(buf);
		pos++;
		if(bytes[pos] != ',') { return NO; }
		pos++;
		char buffer[256]; int i; for(i=0; i<sizeof(buffer); i++) { buffer[i] = bytes[pos+i]; if(buffer[i] == GCCommandTerminator) break; } buffer[i] = '\0';
		self.versionString = [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
		dataParsed = YES;
		return YES;
	}
	else if(!strncmp(bytes, "completeir", 10) && type == GCSENDIR) {
		pos = 10;
		if(bytes[pos] != ',') { return NO; }
		pos++;
		char buf[2];
		buf[0] = bytes[pos]; buf[1] = '\0';
		module = atoi(buf);
		pos++;
		if(bytes[pos] != ':') { return NO; }
		pos++;
		buf[0] = bytes[pos]; buf[1] = '\0';
		connector = atoi(buf);
		pos++;
		if(bytes[pos] != ',') { return NO; }
		pos++;
		char buffer[256]; int i; for(i=0; i<sizeof(buffer); i++) { buffer[i] = bytes[pos+i]; if(buffer[i] == GCCommandTerminator) break; } buffer[i] = '\0';
		irid = atoi(buffer);
		dataParsed = YES;
		return YES;
	}
	else if(!strncmp(bytes, "state", 5) && (type == GCGETSTATE || type == GCSETSTATE)) {
		pos = 5;
		if(bytes[pos] != ',') { return NO; }
		pos++;
		char buf[2];
		buf[0] = bytes[pos]; buf[1] = '\0';
		module = atoi(buf);
		pos++;
		if(bytes[pos] != ':') { return NO; }
		pos++;
		buf[0] = bytes[pos]; buf[1] = '\0';
		connector = atoi(buf);
		pos++;
		if(bytes[pos] != ',') { return NO; }
		pos++;
		if(bytes[pos] == '1') sensorIsClosed = YES; else if(bytes[pos] == '0') sensorIsClosed = NO; else return NO; 
		dataParsed = YES;
		return YES;
	}
	
	return YES;
}

@end
