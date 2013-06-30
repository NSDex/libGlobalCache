/*
 *  GlobalCacheBox.m
 *  libGlobalCache
 *
 *  Created on 6/27/09.
 *  Copyright (c) 2009-2013 by NSDex. All rights reserved.
 */

#import "GlobalCacheBox.h"



@implementation GlobalCacheBox

- (id)init {
	return nil; //Do not use init
}

 /*
  Init the object
  A model must be specified and must match the box you specify
  If address is null we will try to listen for becon packets
  If everythign is null, then we will connect to the first box we find
 */
- (id)initWithParent:(NSObject*)p withAddress:(NSString*)address withMAC:(NSString*)mac withName:(NSString*)name ofType:(GCBoxModel)model withCallback:(SEL)cb {
	if(self = [super init]) {
		parentThread = [NSThread currentThread]; parent = p;
		boxType = model;
		boxAddress = address;
		boxMAC = mac;
		boxName = name;
		ready = NO; readyLock = [[NSLock alloc] init];
		commandQueue = [[LLThreadQueue alloc] init];
		currentIRID = 0;
		boxConnectionCallback = cb;
	}
	return self;
}

- (void)dealloc {
	//LATER
	[super dealloc];
}

/*
 Start the connection process.  A seperate thread is spun off
 to work on connecting.
 */
- (void)connect {
#ifdef DEBUG
	printf("%s - %s: Starting Connection\n", GCDebugHeader, "GlobalCacheBox");
#endif
	//Spin a new thread to work on connecting to the GCBox.  Don't hang the main program.
	connectionHandler = [[NSThread alloc] initWithTarget:self selector:@selector(initConnection:) object:self];
	[connectionHandler start];
}

/*
 Returns no if no commands are executing
 */
- (BOOL)commandsAreWaiting  {
	@synchronized(activeCommand) {
		return (activeCommand != nil);
	}
	return YES;
}

/*
 Will attempt to remove the given command from the stack.
 */
- (BOOL)removeCommandFromStack:(GCCommand*)command {
	return [commandQueue remove:command];
}

#pragma mark -
#pragma mark Commands

/*
 Get all modules installed in the GC Box
*/
- (GCCommand*)getDevices:(id)sender callback:(SEL)cb context:(NSObject*)ct {
	NSMutableData *command = [NSMutableData dataWithCapacity:strlen(GCCommandName[GCGETDEVICES])+strlen(GCTerminator)];
	char *cname = GCCommandName[GCGETDEVICES];
	[command appendBytes:cname length:strlen(cname)];
	[command appendBytes:&GCTerminator length:sizeof(GCTerminator)];
	//Now make a new command container
	GCCommand *newCommand = [[GCCommand alloc] initWithCommand:GCGETDEVICES data:command sender:sender callback:cb context:ct];
	//Send it
	if(connectionHandler == nil || newCommand == nil) {
		return nil;
	}
	[self performSelector:@selector(executeCommand:) onThread:connectionHandler withObject:newCommand waitUntilDone:NO];
	return newCommand;
}

/*
 Get the version of an installed module.  The int can
 only be 1 digit.  Any more will be cut.
 Function returns false if the connection thread does not exist
 */
- (GCCommand*)getVersion:(int)module sender:(id)sender callback:(SEL)cb context:(NSObject*)ct {
	NSMutableData *command = [NSMutableData dataWithCapacity:strlen(GCCommandName[GCGETVERSION])+strlen(GCTerminator)];
	char *cname = GCCommandName[GCGETVERSION];
	char sep = ',';
	while(module > 9) { module = module % 10; }
	[command appendBytes:cname length:strlen(cname)];
	[command appendBytes:&sep length:1];
	[command appendBytes:[[[NSNumber numberWithInt:module] stringValue] cStringUsingEncoding:NSASCIIStringEncoding] length:[[[NSNumber numberWithInt:module] stringValue] length]]; //Module
	//Append the terminator
	[command appendBytes:&GCTerminator length:sizeof(GCTerminator)];
	//Now make a new command container
	GCCommand *newCommand = [[GCCommand alloc] initWithCommand:GCGETVERSION data:command sender:sender callback:cb context:ct];
	//Send it
	if(connectionHandler == nil || newCommand == nil) {
		return nil;
	}
	[self performSelector:@selector(executeCommand:) onThread:connectionHandler withObject:newCommand waitUntilDone:NO];
	return newCommand;
}

/*
 Tell the box to blink it's status light.  No return value is
 sent from the box so a callback is not needed.
 */
- (GCCommand*)blink:(BOOL)shouldBlink sender:(id)sender callback:(SEL)cb context:(NSObject*)ct {
	NSMutableData *command = [NSMutableData dataWithCapacity:strlen(GCCommandName[GCBLINK])+strlen(GCTerminator)];
	char *cname = GCCommandName[GCBLINK];
	char *parameter1; if(shouldBlink) { parameter1 = "1"; } else { parameter1 = "0"; }
	char sep = ',';
	[command appendBytes:cname length:strlen(cname)];
	[command appendBytes:&sep length:1];
	[command appendBytes:&parameter1 length:1];
	//Append the terminator
	[command appendBytes:&GCTerminator length:sizeof(GCTerminator)];
	//Now make a new command container
	GCCommand *newCommand = [[GCCommand alloc] initWithCommand:GCBLINK data:command sender:sender callback:cb context:ct];
	//Send it
	if(connectionHandler == nil || newCommand == nil) {
		return nil;
	}
	[self performSelector:@selector(executeCommand:) onThread:connectionHandler withObject:newCommand waitUntilDone:NO];
	return newCommand;
}

/*
 IR sending commands
 */
- (GCCommand*)sendir:(int)module connector:(int)connector frequency:(NSUInteger)frequency count:(int)count offset:(int)offset data:(char*)data
		sender:(id)sender callback:(SEL)cb context:(NSObject*)ct 
{
	NSMutableData *command = [NSMutableData dataWithCapacity:strlen(GCCommandName[GCSENDIR])+strlen(GCTerminator)];
	char *cname = GCCommandName[GCSENDIR];
	currentIRID++; currentIRID %= 100;
	char sep = ','; char sep2 = ':';
	[command appendBytes:cname length:strlen(cname)];
	[command appendBytes:&sep length:1];
	[command appendBytes:[[[NSNumber numberWithInt:module] stringValue] cStringUsingEncoding:NSASCIIStringEncoding] length:[[[NSNumber numberWithInt:module] stringValue] length]];
	[command appendBytes:&sep2 length:1];
	[command appendBytes:[[[NSNumber numberWithInt:connector] stringValue] cStringUsingEncoding:NSASCIIStringEncoding] length:[[[NSNumber numberWithInt:connector] stringValue] length]];
	[command appendBytes:&sep length:1];
	[command appendBytes:[[[NSNumber numberWithInt:currentIRID] stringValue] cStringUsingEncoding:NSASCIIStringEncoding] length:[[[NSNumber numberWithInt:currentIRID] stringValue] length]];
	[command appendBytes:&sep length:1];
	[command appendBytes:[[[NSNumber numberWithUnsignedInt:frequency] stringValue] cStringUsingEncoding:NSASCIIStringEncoding] length:[[[NSNumber numberWithUnsignedInt:frequency] stringValue] length]];
	[command appendBytes:&sep length:1];
	[command appendBytes:[[[NSNumber numberWithInt:count] stringValue] cStringUsingEncoding:NSASCIIStringEncoding] length:[[[NSNumber numberWithInt:count] stringValue] length]];
	[command appendBytes:&sep length:1];
	[command appendBytes:[[[NSNumber numberWithInt:offset] stringValue] cStringUsingEncoding:NSASCIIStringEncoding] length:[[[NSNumber numberWithInt:offset] stringValue] length]];
	[command appendBytes:&sep length:1];
	[command appendBytes:data length:strlen(data)];
	//Append the terminator
	[command appendBytes:&GCTerminator length:sizeof(GCTerminator)];
	//Now make a new command container
	GCCommand *newCommand = [[GCCommand alloc] initWithCommand:GCSENDIR data:command sender:sender callback:cb context:ct];
	//Send it
	if(connectionHandler == nil || newCommand == nil) {
		return nil;
	}
	newCommand.irid = currentIRID;
	[self performSelector:@selector(executeCommand:) onThread:connectionHandler withObject:newCommand waitUntilDone:NO];
	return newCommand;
}

/*
 Terminate IR signals.  This command gets first priority and will be executed right away
 */
- (GCCommand*)stopir:(int)module connector:(int)connector sender:(id)sender callback:(SEL)cb context:(NSObject*)ct {
	NSMutableData *command = [NSMutableData dataWithCapacity:strlen(GCCommandName[GCSTOPIR])+strlen(GCTerminator)];
	char *cname = GCCommandName[GCSTOPIR];
	char sep = ','; char sep2 = ':';
	[command appendBytes:cname length:strlen(cname)];
	[command appendBytes:&sep length:1];
	[command appendBytes:[[[NSNumber numberWithInt:module] stringValue] cStringUsingEncoding:NSASCIIStringEncoding] length:[[[NSNumber numberWithInt:module] stringValue] length]];
	[command appendBytes:&sep2 length:1];
	[command appendBytes:[[[NSNumber numberWithInt:connector] stringValue] cStringUsingEncoding:NSASCIIStringEncoding] length:[[[NSNumber numberWithInt:connector] stringValue] length]];
	//Append the terminator
	[command appendBytes:&GCTerminator length:sizeof(GCTerminator)];
	//Now make a new command container
	GCCommand *newCommand = [[GCCommand alloc] initWithCommand:GCSTOPIR data:command sender:sender callback:cb context:ct];
	//Send it
	if(connectionHandler == nil || newCommand == nil) {
		return nil;
	}
	[self performSelector:@selector(executeCommand:) onThread:connectionHandler withObject:newCommand waitUntilDone:NO];
	return newCommand;
}

/*
 Get the state of a sensor
 */
- (GCCommand*)getState:(int)module connector:(int)connector sender:(id)sender callback:(SEL)cb context:(NSObject*)ct {
	NSMutableData *command = [NSMutableData dataWithCapacity:strlen(GCCommandName[GCGETSTATE])+strlen(GCTerminator)];
	char *cname = GCCommandName[GCGETSTATE];
	while(connector > 9) { connector = connector % 10; }
	if(boxType == GC_100_06 && module != 2) return NO;
	else if(boxType == GC_100_12 && module < 3) return NO;
	else return NO;
	char sep = ','; char sep2 = ':';
	[command appendBytes:cname length:strlen(cname)];
	[command appendBytes:&sep length:1];
	[command appendBytes:[[[NSNumber numberWithInt:module] stringValue] cStringUsingEncoding:NSASCIIStringEncoding] length:[[[NSNumber numberWithInt:module] stringValue] length]];
	[command appendBytes:&sep2 length:1];
	[command appendBytes:[[[NSNumber numberWithInt:connector] stringValue] cStringUsingEncoding:NSASCIIStringEncoding] length:[[[NSNumber numberWithInt:connector] stringValue] length]];
	//Append the terminator
	[command appendBytes:&GCTerminator length:sizeof(GCTerminator)];
	//Now make a new command container
	GCCommand *newCommand = [[GCCommand alloc] initWithCommand:GCGETSTATE data:command sender:sender callback:cb context:ct];
	//Send it
	if(connectionHandler == nil || newCommand == nil) {
		return nil;
	}
	[self performSelector:@selector(executeCommand:) onThread:connectionHandler withObject:newCommand waitUntilDone:NO];
	return newCommand;
}

/*
 Set the state of a relay output
 */
- (GCCommand*)setState:(BOOL)closed module:(int)module connector:(int)connector sender:(id)sender callback:(SEL)cb context:(NSObject*)ct {
	NSMutableData *command = [NSMutableData dataWithCapacity:strlen(GCCommandName[GCSETSTATE])+strlen(GCTerminator)];
	char *cname = GCCommandName[GCSETSTATE];
	while(connector > 9) { connector = connector % 10; }
	if(boxType == GC_100_06) return NO;
	else if(boxType == GC_100_12 && module != 3) return NO;
	else return NO;
	char sep = ','; char sep2 = ':';
	char on; if(closed) on = '1'; else on = '0';
	[command appendBytes:cname length:strlen(cname)];
	[command appendBytes:&sep length:1];
	[command appendBytes:[[[NSNumber numberWithInt:module] stringValue] cStringUsingEncoding:NSASCIIStringEncoding] length:[[[NSNumber numberWithInt:module] stringValue] length]];
	[command appendBytes:&sep2 length:1];
	[command appendBytes:[[[NSNumber numberWithInt:connector] stringValue] cStringUsingEncoding:NSASCIIStringEncoding] length:[[[NSNumber numberWithInt:connector] stringValue] length]];
	[command appendBytes:&sep length:1];
	[command appendBytes:&on length:1];
	//Append the terminator
	[command appendBytes:&GCTerminator length:sizeof(GCTerminator)];
	//Now make a new command container
	GCCommand *newCommand = [[GCCommand alloc] initWithCommand:GCSETSTATE data:command sender:sender callback:cb context:ct];
	//Send it
	if(connectionHandler == nil || newCommand == nil) {
		return nil;
	}
	[self performSelector:@selector(executeCommand:) onThread:connectionHandler withObject:newCommand waitUntilDone:NO];
	return newCommand;
}

#pragma mark -
#pragma mark Reponse System

/*
 Notifications need to be posted in the main thread.  So we setup a method to run in
 main thread space that will post the notifications.
 */
- (void)postNotification:(id)notification {
	[[NSNotificationCenter defaultCenter] postNotification:notification];
	[notification release];
}

- (void)handleCompleteCommandResponse:(NSData*)data {
#ifdef DEBUG
	printf("%s - %s: Calling to parse command data on main thread.\n", GCDebugHeader, "GlobalCacheBox");
#endif
	@synchronized(activeCommand) {
		if([activeCommand.response parseData:data]) {
			[self performSelector:@selector(readyNextCommand:) onThread:connectionHandler withObject:nil waitUntilDone:NO];
		} else {
#ifdef DEBUG
			printf("%s - %s: Response was invalid\n", GCDebugHeader, "GlobalCacheBox");
#endif
		}
		[data release];
	}
	return;
}

#pragma mark -
#pragma mark Hidden Thread Methods

/*
 Attempt to take care of any problems
 */
- (void)handleErrors:(id)context {
	if([context isKindOfClass:[NSTimer class]]) {
		NSTimer *s = (NSTimer*)context; if(s != failTimer) return;
		if(!activeCommand) return; //Who cares if a timer expired when no command is running
#ifdef DEBUG
		printf("%s - %s: A timer expired\n", GCDebugHeader, "GlobalCacheBox");
#endif
	}
#ifdef DEBUG
	printf("%s - %s: Preparing to restart.\n", GCDebugHeader, "GlobalCacheBox");
#endif
	[iStream close];
	[oStream close];
	[current release];
	ready = NO;
	@synchronized(activeCommand) {
		if(activeCommand != nil) { [commandQueue cut:activeCommand]; [activeCommand autorelease]; activeCommand = nil; }
	}
#ifdef DEBUG
	printf("%s - %s: Restarting.\n", GCDebugHeader, "GlobalCacheBox");
#endif
	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(initConnection:) userInfo:nil repeats:NO];
}

/*
 Runs the next command when called if a command is not
 already running.  Otherwise just queue it.
 */
- (void)executeCommand:(GCCommand*)nextCommand {
	if(nextCommand != nil && [nextCommand isKindOfClass:[GCCommand class]]) {
#ifdef DEBUG
		printf("%s - %s: Asked to send Command of type %s\n", GCDebugHeader, "GlobalCacheBox", GCCommandName[nextCommand.commandType]);
#endif
		if(nextCommand.commandType == GCSTOPIR) { [commandQueue cut:nextCommand]; } else { [commandQueue push:nextCommand]; }
		[nextCommand release];
	}
	@synchronized(readyLock) {
		if(!ready) { return; } //Just queue the command for later
	}
	BOOL shouldSend = NO;
	@synchronized(activeCommand) {
		GCCommand *peek = (GCCommand*)[commandQueue peek];
		if(peek.commandType == GCSTOPIR && !activeCommand.response.dataParsed) { 
			[activeCommand.sen performSelector:activeCommand.callback onThread:activeCommand.senThread withObject:activeCommand waitUntilDone:NO];
			[activeCommand autorelease]; activeCommand = nil;
		}
		else if(activeCommand != nil) { 
#ifdef DEBUG
			printf("%s - %s: Command will be queued\n", GCDebugHeader, "GlobalCacheBox");
#endif
			return; //Just queue the command for later
		}
		else { activeCommand = (GCCommand*)[commandQueue pop]; 
			if(activeCommand != nil) { [activeCommand retain]; shouldSend = YES; }
		}
	}
	if(shouldSend) {
		//Make a timer so our program does not just hang during this next part
		@synchronized(activeCommand) { 
			failTimer = nil;
		}
		//Wait until there is space to write
		while([failTimer isValid] && ![oStream hasSpaceAvailable]) { } //Hang
		//Send
		if([failTimer isValid]) {
#ifdef DEBUG
			@synchronized(activeCommand) {
				char *buffer[[activeCommand.commandData length]+1]; [activeCommand.commandData getBytes:&buffer]; buffer[[activeCommand.commandData length]] = '\0';
				printf("%s - %s: Sending Command\n%s-END\nLENGTH=%i\n", GCDebugHeader, "GlobalCacheBox", &buffer, [activeCommand.commandData length]);
			}
#endif
			//Setup a loop to keep feeding the data
			//Normally this could be a problem since the program could hang
			//But since we have our own thread we can do this
			int value = 0;
			@synchronized(activeCommand) {
				while ([failTimer isValid]) { 
					value = [oStream write:[activeCommand.commandData bytes]+activeCommand.pos maxLength:[activeCommand.commandData length]-activeCommand.pos];
					if(value < 0) { [self handleErrors:oStream]; return; }
					activeCommand.pos += value;
					if(activeCommand.pos >= [activeCommand.commandData length]-1) return;
				}
				if(activeCommand.doNotWait) { 
					[activeCommand.sen performSelector:activeCommand.callback onThread:activeCommand.senThread withObject:activeCommand waitUntilDone:NO];
					[activeCommand autorelease];
					activeCommand = nil; [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(executeCommand:) userInfo:nil repeats:NO];  
				}
			}
		}
	}
}

/*
 Called after all processing on reponse(s) from last Command is done.
 */
- (void)readyNextCommand:(id)unused {
#ifdef DEBUG
	printf("%s - %s: Ready for next command\n", GCDebugHeader, "GlobalCacheBox");
#endif
	failTimer = nil;
	@synchronized(activeCommand) {
		[activeCommand.sen performSelector:activeCommand.callback onThread:activeCommand.senThread withObject:activeCommand waitUntilDone:NO];
		[activeCommand autorelease]; activeCommand = nil;
	}
	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(executeCommand:) userInfo:nil repeats:NO]; //Next Command go
}

- (BOOL)checkIfEventAndPost:(NSData*)data {
	GCEvent *e = [GCEvent checkIfEvent:[data copy]];
	if(e == nil) return NO;
	[self performSelector:@selector(postNotification:) onThread:parentThread withObject:[[NSNotification notificationWithName:GCStateChangeEvent object:[e retain]] retain] waitUntilDone:NO];
	return YES;
}

/*
 Handle a complete response
 */
- (void)handleCompleteResponse:(NSMutableData*)data {
#ifdef DEBUG
	char *buffer[[data length]+1]; [data getBytes:&buffer]; buffer[[data length]] = '\0';
	printf("%s - %s: Data length = %i Address = %x Response =\n%sEND\n", GCDebugHeader, "GlobalCacheBox", [data length], data, &buffer);
#endif

	//Check if the response is an event
	if([self checkIfEventAndPost:[data copy]]) { failTimer = nil; return; } //It was an event
	if(activeCommand == nil) return;  //This is bogus data
	/*
	Offload processing of data to caller thread.  Secondary thread CAN NOT be held up at all.
	*/
	failTimer = nil;
	@synchronized(activeCommand) { 
		failTimer = [NSTimer scheduledTimerWithTimeInterval:GCCommandTimeout target:self selector:@selector(handleErrors:) userInfo:activeCommand repeats:NO];
		[self performSelector:@selector(handleCompleteCommandResponse:) onThread:activeCommand.senThread withObject:[data copy] waitUntilDone:NO]; 
	}
}

/*
 Handle all stream events
 */
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
	if(stream != iStream) { return; } //Yeah, that should not happen.  Just ignore it if it does.
	switch (eventCode) {
		case NSStreamEventNone: //Exciting
			break;
		case NSStreamEventOpenCompleted: //The idea is that we get to this point if all the open stuff worked
			if(boxConnectionCallback != NULL)
				[parent performSelector:boxConnectionCallback onThread:parentThread withObject:self waitUntilDone:NO];
			break;
		case NSStreamEventHasBytesAvailable:
			if(current == nil) { break; }
			//Read in data until a CRLF pair is hit
			unsigned char buffer;
			while([(NSInputStream*)stream hasBytesAvailable]) {
				int read = [(NSInputStream*)stream read:&buffer maxLength:1];
				if(read < 1) break;
				[current appendBytes:&buffer length:1];
				if(buffer == GCCommandTerminator) {
#ifdef DEBUG
					printf("%s - %s: A complete response has been read on stream.\n", GCDebugHeader, "GlobalCacheBox");
#endif
					[self handleCompleteResponse:current];
					[current setLength:0]; //Flush data
					return;  //Apparently it takes one run loop cycle to flush the stream of all the data I just read
				}
			}
			break;
		case NSStreamEventHasSpaceAvailable:
			break;
		case NSStreamEventErrorOccurred:
#ifdef DEBUG
			printf("%s - %s: A stream error occured\n", GCDebugHeader, "GlobalCacheBox");
#endif
			[self handleErrors:stream];
			break;
		case NSStreamEventEndEncountered: //This should never happen
#ifdef DEBUG
			printf("%s - %s: A stream end was reached\n", GCDebugHeader, "GlobalCacheBox");
#endif
			[self handleErrors:stream];
			break;
		default:
			break;
	}
	return;
}

 /*
  This is the real start point.  This routine begins the connection thread.
 */
- (void)initConnection:(id)sender {
	NSAutoreleasePool * pool; NSRunLoop * rl;
	if(sender == self) {
		pool = [[NSAutoreleasePool alloc] init];
		rl = [NSRunLoop currentRunLoop]; }
	
	if(boxAddress != nil) { //We have an address.  Connect directly
		if(iStream != nil) [iStream release];
		if(oStream != nil) [oStream release];
		if(current != nil) [current release];
		CFReadStreamRef     rStream;
		CFWriteStreamRef    wStream;
		NSAssert( (GCBoxBasePort > 0) && (GCBoxBasePort < 65534), @"Invalid Port for GCBox"); //You never know
		CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)boxAddress, GCBoxBasePort, &rStream, &wStream);
		if(rStream == NULL || wStream == NULL) { //Failure
			//Altert the main thread
			//[later]
			return;
		}
		iStream  = [NSMakeCollectable(rStream) autorelease];
		[iStream retain];
		[iStream setDelegate:self];
		[iStream scheduleInRunLoop:rl forMode:NSDefaultRunLoopMode];
		oStream  = [NSMakeCollectable(wStream) autorelease];
		[oStream retain];
		[oStream setDelegate:self];
		[oStream scheduleInRunLoop:rl	forMode:NSDefaultRunLoopMode];
		[oStream open];
		[iStream open];
		//So the connection is good.  Now we have to
		//do some administrative work
		current = [[NSMutableData dataWithCapacity:5] retain];
		@synchronized(activeCommand) {
			activeCommand = nil;
		}
		[commandQueue smash];
		@synchronized(readyLock) {
			ready = YES;
		}
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(executeCommand:) userInfo:nil repeats:NO];
	} else { //We have to scan
			//Later
	}
	
	if(sender == self) {
		[rl run];
		[pool release]; }
}

@end
