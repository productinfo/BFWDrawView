//
//  BFWStyleKitDrawing.m
//  BFWDrawView
//
//  Created by Tom Brodhurst-Hill on 19/07/2015.
//  Copyright (c) 2015 BareFeetWare. All rights reserved.
//

#import "BFWStyleKitDrawing.h"
#import "BFWStyleKit.h"
#import "NSDictionary+BFW.h"

@interface BFWStyleKitDrawing ()

@property (nonatomic, assign, readwrite) CGSize drawnSize;

@end

static NSString * const sizesKey = @"sizes";
static NSString * const sizesByPrefixKey = @"sizesByPrefix";
static NSString * const styleKitByPrefixKey = @"styleKitByPrefix";

@implementation BFWStyleKitDrawing

- (CGSize)drawnSize
{
    if (CGSizeEqualToSize(_drawnSize, CGSizeZero)) {
        NSDictionary *parameterDict = self.styleKit.parameterDict;
        NSString *sizeString = [parameterDict[sizesKey] objectForWordsKey:self.name];
        if (!sizeString) {
            sizeString = [parameterDict[sizesByPrefixKey] objectForLongestPrefixKeyMatchingWordsInString:self.name];
        }
        _drawnSize = sizeString ? CGSizeFromString(sizeString) : CGSizeZero;
    }
    return _drawnSize;
}

@end
