/*
 *  GCDefines.h
 *  libGlobalCache
 *
 *  Created on 6/28/09.
 *  Copyright (c) 2009-2013 by NSDex. All rights reserved.
 */

#define DEBUG 1
#define GCDebugHeader "libGlobalCache"

typedef enum {
	GC_100_06,
	GC_100_12
}GCBoxModel;

//Port Defines
#define GCBoxBasePort 4998

//Command System
#define GCCommandTerminator 0x0D
extern const char GCTerminator[1];

//Timeouts
#define GCConnectionTimeout 10
#define GCCommandTimeout 5

//Notifications
NSString *const GCStateChangeEvent;

//Commands ----------------------------------------------

enum {
	GCGETDEVICES = 0,
	GCGETVERSION = 1,
	GCBLINK = 2,
	GCSENDIR = 3,
	GCSTOPIR = 4,
	GCGETSTATE = 5,
	GCSETSTATE = 6
};
typedef NSUInteger GCCommandType;
extern char *GCCommandName[7];

//Response ----------------------------------------------

//Events
enum {
	EVENT_STATECHANGE = 0
};
typedef NSUInteger GCEvents;