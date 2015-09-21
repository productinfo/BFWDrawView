//
//  BFWDrawView.m
//
//  Created by Tom Brodhurst-Hill on 16/10/12.
//  Copyright (c) 2012 BareFeetWare. All rights reserved.
//  Free to use at your own risk, with acknowledgement to BareFeetWare.
//

#import "BFWDrawView.h"
#import "UIImage+BFW.h"
#import "NSInvocation+BFW.h"
#import "NSString+BFW.h"
#import "NSDictionary+BFW.h"
#import "NSObject+BFWStyleKit.h" // for DLog
#import <QuartzCore/QuartzCore.h>
#import "BFWStyleKit.h"
#import "BFWStyleKitDrawing.h"

@interface BFWDrawView ()

@property (nonatomic, strong) NSInvocation *drawInvocation;
@property (nonatomic, assign) BOOL didCheckCanDraw;
@property (nonatomic, readonly) CGSize drawInFrameSize;
@property (nonatomic, strong) UIColor *retainedTintColor; // retains reference to tintColor so NSInvocation doesn't crash if the "darken colors" is enabled in System Preferences in iOS 9

@end

@implementation BFWDrawView

@synthesize styleKit = _styleKit;
@synthesize name = _name;

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        super.backgroundColor = [UIColor clearColor];
        super.contentMode = UIViewContentModeRedraw;  // forces redraw when view is resized, eg when device is rotated
    }
    return self;
}

#pragma mark - accessors

- (BFWStyleKitDrawing *)drawing
{
    if (!_drawing) {
        _drawing = [BFWStyleKit drawingForStyleKitName:_styleKit
                                           drawingName:_name];
    }
    return _drawing;
}

- (NSString *)styleKit
{
    return self.drawing.styleKit.name ?: _styleKit;
}

- (NSString *)name
{
    return self.drawing.name ?: _name;
}

- (void)setFillColor:(UIColor *)fillColor // Deprecated. Use UIView's tintColor.
{
    DLog(@"BFWDrawView called deprecated fillColor. Use tintColor instead. %@", fillColor
         );
    self.tintColor = fillColor;
    _fillColor = fillColor;
}

- (void)setTintColor:(UIColor *)tintColor
{
    if (![super.tintColor isEqual:tintColor]) {
        [super setTintColor:tintColor];
        self.drawInvocation = nil;
        [self setNeedsDisplay]; // needed?
    }
}

- (void)setStyleKit:(NSString *)styleKit
{
    if (![_styleKit isEqualToString:styleKit]) {
        _styleKit = styleKit;
        self.drawInvocation = nil;
        self.drawing = nil;
        [self setNeedsDisplay];
    }
}

- (void)setName:(NSString *)name
{
    if (![_name isEqualToString:name]) {
        _name = name;
        self.drawInvocation = nil;
        self.drawing = nil;
        [self setNeedsDisplay];
    }
}

#pragma mark - frame calculations

- (CGSize)drawnSize
{
    return self.drawInFrameSize;
}

- (CGSize)drawInFrameSize
{
    return self.drawing.hasDrawnSize ? self.drawing.drawnSize : self.frame.size;
}

- (CGSize)intrinsicContentSize
{
    CGSize size = CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
    if (self.drawing.hasDrawnSize) {
        size = self.drawing.drawnSize;
    }
    return size;
}

- (CGRect)drawFrame
{
    CGRect drawFrame = CGRectZero;
    if (self.contentMode == UIViewContentModeCenter) {
        drawFrame = CGRectMake((self.frame.size.width - self.drawInFrameSize.width) / 2,
                               (self.frame.size.height - self.drawInFrameSize.height) / 2,
                               self.drawInFrameSize.width,
                               self.drawInFrameSize.height);
    }
    else if (self.contentMode == UIViewContentModeScaleAspectFit || self.contentMode == UIViewContentModeScaleAspectFill) {
        CGFloat widthScale = self.frame.size.width / self.drawInFrameSize.width;
        CGFloat heightScale = self.frame.size.height / self.drawInFrameSize.height;
        CGFloat scale;
        if (self.contentMode == UIViewContentModeScaleAspectFit) {
            scale = widthScale > heightScale ? heightScale : widthScale;
        }
        else {
            scale = widthScale > heightScale ? widthScale : heightScale;
        }
        drawFrame.size = CGSizeMake(self.drawInFrameSize.width * scale,
                                    self.drawInFrameSize.height * scale);
        drawFrame.origin.x = (self.frame.size.width - drawFrame.size.width) / 2.0;
        drawFrame.origin.y = (self.frame.size.height - drawFrame.size.height) / 2.0;
    }
    else if (self.contentMode == UIViewContentModeScaleToFill || self.contentMode == UIViewContentModeRedraw) {
        drawFrame = self.bounds;
    }
    else {
        drawFrame = CGRectMake(0, 0, self.drawInFrameSize.width,
                               self.drawInFrameSize.height);
        if (self.contentMode == UIViewContentModeTopLeft) {
            // leave as-is
        }
        if (self.contentMode == UIViewContentModeTopRight || self.contentMode == UIViewContentModeBottomRight || self.contentMode == UIViewContentModeRight) {
            drawFrame.origin.x = self.bounds.size.width - self.drawInFrameSize.width;
        }
        if (self.contentMode == UIViewContentModeBottomLeft || self.contentMode == UIViewContentModeBottomRight || self.contentMode == UIViewContentModeBottom) {
            drawFrame.origin.y = self.bounds.size.height - self.drawInFrameSize.height;
        }
    }
    return drawFrame;
}

#pragma mark - layout

- (void)layoutSubviews
{
    // layoutSubviews is called when constraints change. Since new constraints might resize this view, we need to redraw.
    // TODO: only redraw if size actually changed
    self.drawInvocation = nil;
    [self setNeedsDisplay];
    [super layoutSubviews];
}

#pragma mark - drawing

- (void)setArgumentPointer:(NSValue *)argumentPointer
              forParameter:(NSString *)parameter
{
    NSUInteger index = [self.drawing.methodParameters indexOfObject:parameter];
    if (index != NSNotFound) {
        [self.drawInvocation setArgument:argumentPointer.pointerValue
                                 atIndex:index + 2];
    }
}

- (NSArray *)parameters {
    return self.drawing.methodParameters;
}

- (SEL)drawingSelector {
    return NSSelectorFromString(self.drawing.methodName);
}

- (NSInvocation *)drawInvocation
{
    if (!_drawInvocation) {
        NSMutableArray *argumentPointers = [[NSMutableArray alloc] init];
        // Declare local variable copies in same scope as call to NSInvocation so they are retained
        CGRect frame = self.drawFrame;
        self.retainedTintColor = self.tintColor;
        UIColor *tintColor = self.retainedTintColor;
        for (NSString *parameter in self.drawing.methodParameters) {
            NSValue *argumentPointer = nil;
            if ([parameter isEqualToString:@"frame"]) {
                argumentPointer = [NSValue valueWithPointer:&frame];
            }
            else if ([parameter isEqualToString:@"tintColor"]) {
                argumentPointer = [NSValue valueWithPointer:&tintColor];
            }
            if (argumentPointer) {
                [argumentPointers addObject:argumentPointer];
            }
            else {
                DLog(@"**** error: unexpected parameter: %@", parameter);
                argumentPointers = nil;
                break;
            }
        }
        if (argumentPointers) {
            _drawInvocation = [NSInvocation invocationForClass:self.drawing.styleKit.paintCodeClass
                                                      selector:self.drawingSelector
                                              argumentPointers:argumentPointers];
        }
    }
    return _drawInvocation;
}

- (BOOL)canDraw
{
    self.didCheckCanDraw = YES;
    return self.drawInvocation ? YES : NO;
}

- (BOOL)isDrawInvocationInstantiated
{
    return _drawInvocation != nil;
}

- (void)drawRect:(CGRect)rect
{
    [self.drawInvocation invoke];
}

#pragma mark - image rendering

+ (NSMutableDictionary *)imageCache
{
    static NSMutableDictionary *imageCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageCache = [[NSMutableDictionary alloc] init];
    });
    return imageCache;
}

- (NSString *)cacheKey
{
    NSMutableArray *components = [@[self.name, self.styleKit, NSStringFromCGSize(self.frame.size)] mutableCopy];
    NSString *colorString = self.tintColor.description;
    if (colorString) {
        [components addObject:colorString];
    }
    NSString *key = [components componentsJoinedByString:@"."];
    return key;
}

- (UIImage *)cachedImageForKey:(NSString *)key
{
    return [self class].imageCache[key];
}

- (void)setCachedImage:(UIImage *)image
                forKey:(NSString *)key
{
    [self class].imageCache[key] = image;
}

- (UIImage*)imageFromView
{
    UIImage *image = nil;
    if (self.name && self.styleKit) {
        NSString *key = [self cacheKey];
        image = [self cachedImageForKey:key];
        if (!image) {
            image = [UIImage imageOfView:self
                                    size:self.frame.size];
            if (image) {
                [self setCachedImage:image
                              forKey:key];
            }
        }
    }
    else {
        DLog(@"**** error: Missing name or styleKit");
    }
    return image;
}

- (UIImage*)image
{
    return [self imageFromView];
}

#pragma mark - image output methods

- (BOOL)writeImageAtScale:(CGFloat)scale
                   toFile:(NSString*)savePath
{
    NSString *directoryPath = [savePath stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    BOOL success = NO;
    UIImage *image = [self imageAtScale:scale];
    if (image) {
        success = [UIImagePNGRepresentation(image) writeToFile:savePath atomically:YES];
    }
    return success;
}

- (UIImage*)imageAtScale:(CGFloat)scale
{
    UIImage *image = nil;
    if (self.canDraw) {
        CGFloat savedContentsScale = self.contentScaleFactor;
        self.contentScaleFactor = scale;
        BOOL isOpaque = NO;
        UIGraphicsBeginImageContextWithOptions(self.frame.size, isOpaque, scale);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.contentScaleFactor = savedContentsScale;
    }
    return image;
}

@end
