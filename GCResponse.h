/*
 *  GCResponse.h
 *  libGlobalCache
 *
 *  Created on 7/29/09.
 *  Copyright (c) 2009-2013 by NSDex. All rights reserved.
 */

#import <Foundation/Foundation.h>


@interface GCResponse : NSObject {
	GCCommandType type;
	
	BOOL dataParsed;
	
	//General Response Stuff
	int module;
	int connector;
	
	//getdevices
	NSMutableArray *devices; //Array of strings
	
	//getversion
	NSString *versionString;
	
	//sendir
	int irid;
	
	//getstate
	BOOL sensorIsClosed;
}

@property(nonatomic) BOOL dataParsed;

@property(readwrite) int module;
@property(readwrite) int connector;
@property(nonatomic, retain) NSMutableArray *devices;
@property(nonatomic, retain) NSString *versionString;
@property(readwrite) int irid;
@property(readwrite) BOOL sensorIsClosed;

- (id)initWithType:(GCCommandType)t;
- (BOOL)parseData:(NSData*)data;

@end
