/*
 *  GCDefines.m
 *  libGlobalCache
 *
 *  Created on 7/29/09.
 *  Copyright (c) 2009-2013 by NSDex. All rights reserved.
 */

#import "GCDefines.h"

//Command System
const char GCTerminator[1] = {0x0D};

//Notifications
NSString *const GCStateChangeEvent = @"GCStateChange";

//Commands ----------------------------------------------
char *GCCommandName[7] = {"getdevices", "getversion", "blink", "sendir", "stopir", "getstate", "setstate"};