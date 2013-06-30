/*
 *  LLThreadQueue.m
 *  libGlobalCache
 *
 *  Created on 6/28/09.
 *  Copyright (c) 2009-2013 by NSDex. All rights reserved.
 */

#import "LLThreadQueue.h"

@implementation LLThreadQueue

@synthesize count;

- (id)init {
	if(self = [super init]) {
		head = nil;
		tail = nil;
		count = 0;
	}
	return self;
}

- (void)dealloc
{
	@synchronized(self) {
		NSObject<LLThreadQueueProtocol> *current;
		while(head != tail) {
			current = head;
			head = current.next;
			[current release];
		}
		[head release];
	}
	[super dealloc];
}

/*
 Destroy the stack
 */
- (void)smash {
	@synchronized(self) {
		NSObject<LLThreadQueueProtocol> *current;
		while(head != tail) {
			current = head;
			head = current.next;
			[current release];
		}
		[head release];
		head = nil;
		tail = nil;
		count = 0;
	}
}

/*
 Add the object to the back.
 */
- (void)push:(NSObject<LLThreadQueueProtocol>*)theObject {
	if(theObject == nil) return;
	@synchronized(self) {
		[theObject retain];
		if(head == nil) {
			head = theObject;
			tail = theObject;
		} else {
			tail.next = theObject;
			tail = theObject;
		}
		count++;
	}
}

/*
 Add the object to the front.
 */
- (void)cut:(NSObject<LLThreadQueueProtocol>*)theObject {
	if(theObject == nil) return;
	@synchronized(self) {
		[theObject retain];
		if(head == nil) {
			head = theObject;
			tail = theObject;
		} else {
			theObject.next = head;
			head = theObject;
		}
		count++;
	}
}

/*
 Return object at the front but don't pop it
 */
- (NSObject*)peek {
	return head;
}

/*
 Return the front most object
 */
- (NSObject*)pop {
	NSObject *temp = nil;
	@synchronized(self) {
		if(head == nil) return nil;
		temp = head;
		head = head.next;
		count--;
	}
	return [temp autorelease];
}

- (BOOL)remove:(NSObject<LLThreadQueueProtocol>*)theObject {
	NSObject<LLThreadQueueProtocol> *current = head;
	@synchronized(self) {
		if(current == theObject) { head = current.next; [current autorelease]; return YES; }
		while(current != nil || current != tail) {
			if(current.next == theObject) { [current.next autorelease]; 
				current.next = [[current next] next];
				if(current.next = tail) tail = current;
				return YES;
			}
			current = current.next;
		}
	}
	return NO;
}

@end
