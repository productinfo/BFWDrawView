//
//  NSObject+BFWStyleKit.h
//
//  Created by Tom Brodhurst-Hill on 16/10/12.
//  Copyright (c) 2015 BareFeetWare. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSObject (BFWStyleKit)

#pragma mark - Introspection for NSObject subclasses

+ (id _Nullable)returnValueForClassMethodName:(NSString * _Nonnull)methodName;

@end
