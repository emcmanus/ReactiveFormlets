//
//  RFReifiedProtocol.m
//  iOS Formlets
//
//  Created by Jon Sterling on 6/12/12.
//  Copyright (c) 2012 Jon Sterling. All rights reserved.
//

#import "RFReifiedProtocol.h"
#import "RFOrderedDictionary.h"
#import "NSInvocation+RFExtensions.h"
#import "RFObjCRuntime.h"
#import <ReactiveCocoa/RACObjCRuntime.h>
#import <ReactiveCocoa/RACTuple.h>
#import <ReactiveCocoa/RACSequence.h>

static void *const kModelAssociatedObjectKey;

@implementation RFReifiedProtocol

+ (Class)model:(Protocol *)model {
	NSString *name = [NSString stringWithFormat:@"%@_%s", self, protocol_getName(model)];

	Class class = [self rf_subclassWithName:name adopting:@[ model ]];
	[class rf_setAssociatedObject:model forKey:kModelAssociatedObjectKey policy:OBJC_ASSOCIATION_ASSIGN];

	return class;
}

+ (Protocol *)model {
	return [self rf_associatedObjectForKey:kModelAssociatedObjectKey];
}

#pragma mark - Message Forwarding

+ (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	return [RFObjCRuntime classMethodSignatureForSelector:aSelector inProtocol:self.class.model];
}

+ (void)forwardInvocation:(NSInvocation *)invocation {
	[invocation retainArguments];

	RFOrderedDictionary *arguments = invocation.rf_argumentDictionary;
	invocation.returnValue = &(__unsafe_unretained id){
		[[self alloc] initWithOrderedDictionary:arguments]
	};
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	return [RFObjCRuntime instanceMethodSignatureForSelector:aSelector inProtocol:self.class.model];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
	NSString *key = NSStringFromSelector(anInvocation.selector);
	anInvocation.returnValue = &(__unsafe_unretained id){
		[self valueForKey:key]
	};
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	return ([self.allKeys containsObject:NSStringFromSelector(aSelector)] ||
			[super respondsToSelector:aSelector]);
}

- (id)valueForUndefinedKey:(NSString *)key {
	return self[key];
}

@end
