/*
 *  LLThreadQueue.h
 *  libGlobalCache
 *
 *  Created on 6/28/09.
 *  Copyright (c) 2009-2013 by NSDex. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol LLThreadQueueProtocol

@property (nonatomic, assign) id next;

@end

@interface LLThreadQueue : NSObject {
	NSObject <LLThreadQueueProtocol> *head;
	NSObject <LLThreadQueueProtocol> *tail;
	int count;
}

@property (nonatomic, readonly) int count;

- (void)smash;
- (void)cut:(NSObject<LLThreadQueueProtocol>*)theObject;
- (void)push:(NSObject<LLThreadQueueProtocol>*)theObject;
- (NSObject*)peek;
- (NSObject*)pop;
- (BOOL)remove:(NSObject<LLThreadQueueProtocol>*)theObject;

@end

