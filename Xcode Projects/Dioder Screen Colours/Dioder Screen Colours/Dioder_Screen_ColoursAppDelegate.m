//
//  Dioder_Screen_ColoursAppDelegate.m
//  Dioder Screen Colours
//
//  Created by Daniel Kennett on 14/09/2011.
//  Copyright 2011 Daniel Kennett. All rights reserved.
//

#import "Dioder_Screen_ColoursAppDelegate.h"
#import "DKSerialPort.h"
#import <QuartzCore/QuartzCore.h>
#import "BlinkEditorWC.h"

void screenDidUpdate(CGRectCount count, const CGRect *rectArray, void *userParameter);

static NSTimeInterval const kScreenshotFrequency = 0.05;
static CGFloat const kScreenColourCalculationInsetFraction = 0.25;

@interface Dioder_Screen_ColoursAppDelegate ()
@property(nonatomic,retain) NSDate *lastShotTaken;
@property(nonatomic,retain) NSDate *delayScreenUpdatesUntil;
@property(nonatomic,retain) BlinkEditorWC *blinkEditor;
-(void)doBlink:(NSDictionary*)desc;
@end

@interface NSArray (TCArrayToColor)
-(NSColor*)tc_color;
@end
@implementation NSArray (TCArrayToColor)
-(NSColor*)tc_color;
{
    return [NSColor colorWithCalibratedRed:[[self objectAtIndex:0] floatValue] green:[[self objectAtIndex:1] floatValue] blue:[[self objectAtIndex:2] floatValue] alpha:[[self count] == 4?[self objectAtIndex:3]:[NSNumber numberWithFloat:1] floatValue]];
}
@end

@implementation Dioder_Screen_ColoursAppDelegate

@synthesize window;
@synthesize commsController;
@synthesize ports;
@synthesize image;

@synthesize screenSamplingAlgorithm;
@synthesize avoidRenderingIfPossible;

@synthesize channel1Color;
@synthesize channel2Color;
@synthesize channel3Color;
@synthesize channel4Color;

@synthesize lastShotTaken;
@synthesize delayScreenUpdatesUntil;
@synthesize blinkEditor;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(portsChanged:)
                                                 name:DKSerialPortsDidChangeNotification
                                               object:nil];
    
    self.commsController = [[[ArduinoDioderCommunicationController alloc] init] autorelease];
    
    [self portsChanged:nil];
    self.lastShotTaken = nil;
    
    CGRegisterScreenRefreshCallback(screenDidUpdate, self);
    
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(addBlinkNotification:) name:@"DioderBlink" object:nil suspensionBehavior:NSNotificationSuspensionBehaviorCoalesce];
}


-(void)portsChanged:(NSNotification *)aNotification {
    self.ports = [[DKSerialPort availableSerialPorts] sortedArrayUsingComparator:^(id a, id b) {
        return [[a name] caseInsensitiveCompare:[b name]];
    }];
}

-(void)applicationWillTerminate:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DKSerialPortsDidChangeNotification object:nil];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"DioderBlink" object:nil];
    self.commsController = nil;
    CGUnregisterScreenRefreshCallback(screenDidUpdate, self);
}

#pragma mark -
#pragma mark blinking is nice

#define $notnull(thing) ((thing == [NSNull null]) ? nil : thing)
#define $castIf(klass, thing) ({ __typeof(thing) thing2 = thing; (klass*)([thing2 isKindOfClass:[klass class]]?thing2:nil); })

-(void)addBlink:(NSArray*)colors duration:(NSTimeInterval)interval;
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:colors, @"colors", [NSNumber numberWithDouble:interval], @"interval", nil];
    interval += 0.05;
    NSDate *doAt = [[self.delayScreenUpdatesUntil retain] autorelease];
    self.delayScreenUpdatesUntil = [delayScreenUpdatesUntil?:[NSDate date] dateByAddingTimeInterval:interval];
    if(!doAt)
        [self doBlink:userInfo];
    else {
        NSTimer *t = [[[NSTimer alloc] initWithFireDate:doAt interval:0 target:self selector:@selector(doDelayedBlink:) userInfo:userInfo repeats:NO] autorelease];
        [[NSRunLoop currentRunLoop] addTimer:t forMode:NSRunLoopCommonModes];
    }
}
-(void)doDelayedBlink:(NSTimer*)t; { [self doBlink:[t userInfo]]; }
-(void)doBlink:(NSDictionary*)desc;
{
    NSArray *colors = [desc objectForKey:@"colors"];
    NSTimeInterval interval = [[desc objectForKey:@"interval"] doubleValue];
    [self.commsController pushColorsToChannel1:$notnull([colors objectAtIndex:0])?:self.channel1Color
                                      channel2:$notnull([colors objectAtIndex:1])?:self.channel2Color
                                      channel3:$notnull([colors objectAtIndex:2])?:self.channel3Color
                                      channel4:$notnull([colors objectAtIndex:3])?:self.channel4Color
                                  withDuration:0];
    
    [self.commsController pushColorsToChannel1:self.channel1Color
                                      channel2:self.channel2Color
                                      channel3:self.channel3Color
                                      channel4:self.channel4Color
                                  withDuration:interval];
}

-(void)addBlinkNotification:(NSNotification*)notif;
{
    NSDictionary *ui = [notif userInfo];
    NSArray *colors = $castIf(NSArray, [ui objectForKey:@"colors"]);
    if([colors count] != 4) {
        NSLog(@"Must have userinfo 'colors' with 4 items");
        return;
    }
    NSMutableArray *colors2 = [NSMutableArray array];
    for(id thing in colors)
        if([thing isKindOfClass:[NSArray class]]) [colors2 addObject:[thing tc_color]];
        else [colors2 addObject:[NSNull null]];
    NSNumber *duration = $castIf(NSNumber, [ui objectForKey:@"interval"])?:[NSNumber numberWithDouble:.5];
    
    [self addBlink:colors2 duration:[duration doubleValue]];
}
-(IBAction)blinkRed:(id)sender;
{
    [self addBlink:[NSArray arrayWithObjects:[NSColor greenColor], [NSColor greenColor], [NSColor redColor], [NSColor redColor], nil] duration:.5];
    [self addBlink:[NSArray arrayWithObjects:[NSColor redColor], [NSColor redColor], [NSColor greenColor], [NSColor greenColor], nil] duration:.5];
}

-(IBAction)showBlinkEditor:(id)sender;
{
    if(!blinkEditor)
        self.blinkEditor = [[[BlinkEditorWC alloc] init] autorelease];
    [self.blinkEditor.window makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark Screen Monitoring

void screenDidUpdate(CGRectCount count, const CGRect *rectArray, void *userParameter) {
    
    Dioder_Screen_ColoursAppDelegate *self = userParameter;
    
    // Always assume main screen
    NSScreen *mainScreen = [[NSScreen screens] objectAtIndex:0];
    
    CGRect topBar = CGRectMake(0.0, 0.0, mainScreen.frame.size.width, mainScreen.frame.size.height * kScreenColourCalculationInsetFraction);
    CGRect bottomBar = CGRectMake(0.0, mainScreen.frame.size.height - topBar.size.height, topBar.size.width, topBar.size.height);
    CGRect leftBar = CGRectMake(0.0, 0.0, mainScreen.frame.size.width * kScreenColourCalculationInsetFraction, mainScreen.frame.size.height);
    CGRect rightBar = CGRectMake(mainScreen.frame.size.width - leftBar.size.width, 0.0, leftBar.size.width, leftBar.size.height);
    
    for (NSUInteger currentChangedFrame = 0; currentChangedFrame < count; currentChangedFrame++) {
        
        CGRect changedRect = rectArray[currentChangedFrame];
        
        if (CGRectIntersectsRect(changedRect, topBar) ||
            CGRectIntersectsRect(changedRect, bottomBar) ||
            CGRectIntersectsRect(changedRect, leftBar) ||
            CGRectIntersectsRect(changedRect, rightBar)) {
            [self updateScreenColoursIfAppropriate];
            return;
        }
    }
    //NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), @"screenDidUpdate", @"Change occurred but we don't care!");
}

-(void)updateScreenColoursIfAppropriate {
    if (self.lastShotTaken == nil)
        lastShotTaken = [NSDate new];
        
    if ([delayScreenUpdatesUntil compare:[NSDate date]] == NSOrderedDescending)
        return;
    else if (delayScreenUpdatesUntil)
        self.delayScreenUpdatesUntil = nil;
    
    if ([[NSDate date] timeIntervalSinceDate:lastShotTaken] < kScreenshotFrequency)
        return;
    
    CGImageRef screenShot = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault);
    self.lastShotTaken = [NSDate date];
    
    [self calculateColoursOfImage:screenShot];
    CGImageRelease(screenShot);
}

#pragma mark -
#pragma mark Image Calculations

-(void)calculateColoursOfImage:(CGImageRef)imageRef {
    
    switch (self.screenSamplingAlgorithm) {
        case kScreenSamplingPickAPixel:
            [self calculateColoursOfImageWithPickAPixel:imageRef];
            break;
        case kScreenSamplingAverageRGB:
            [self calculateColoursOfImageWithAverageRGB:imageRef];
            break;
        case kScreenSamplingAverageHue:
            [self calculateColoursOfImageWithAverageHue:imageRef];
            break;
        default:
            break;
    }
}

-(void)calculateColoursOfImageWithPickAPixel:(CGImageRef)imageRef {
    
    NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithCGImage:imageRef] autorelease];
    NSUInteger pixelInset = 128;
        
    self.channel1Color = [rep colorAtX:rep.pixelsWide / 2
                                     y:rep.pixelsHigh - pixelInset];
    
    self.channel2Color = [rep colorAtX:rep.pixelsWide / 2
                                     y:pixelInset];
    
    self.channel3Color = [rep colorAtX:pixelInset
                                     y:rep.pixelsHigh / 2];
    
    self.channel4Color = [rep colorAtX:rep.pixelsWide - pixelInset
                                     y:rep.pixelsHigh / 2];
    
    [self sendColours];
    [self setPreviewImageWithBitmapImageRep:rep];
}

-(void)calculateColoursOfImageWithAverageRGB:(CGImageRef)imageRef {
    
    size_t imageWidth = CGImageGetWidth(imageRef);
    size_t imageHeight = CGImageGetHeight(imageRef);
    
    CIImage *ciImage = [CIImage imageWithCGImage:imageRef];
    CIFilter *averageFilter = [CIFilter filterWithName:@"CIAreaAverage"];
    [averageFilter setValue:ciImage forKey:@"inputImage"];

    CIVector *topExtent = [CIVector vectorWithX:0.0 Y:0.0 Z:imageWidth W:imageHeight * kScreenColourCalculationInsetFraction];
    CIVector *leftExtent = [CIVector vectorWithX:0.0 Y:0.0 Z:imageWidth * kScreenColourCalculationInsetFraction W:imageHeight];
    CIVector *bottomExtent = [CIVector vectorWithX:0.0 Y:imageHeight - (imageHeight * kScreenColourCalculationInsetFraction) Z:imageWidth W:imageHeight * kScreenColourCalculationInsetFraction];
    CIVector *rightExtent = [CIVector vectorWithX:imageWidth - (imageWidth * kScreenColourCalculationInsetFraction) Y:0.0 Z:imageWidth * kScreenColourCalculationInsetFraction W:imageHeight];
    
    // Bottom
    [averageFilter setValue:bottomExtent forKey:@"inputExtent"];
    self.channel1Color = [self colorFromFirstPixelOfCIImage:[averageFilter valueForKey:@"outputImage"]];
    
    // Top
    [averageFilter setValue:topExtent forKey:@"inputExtent"];
    self.channel2Color = [self colorFromFirstPixelOfCIImage:[averageFilter valueForKey:@"outputImage"]];
    
    // Left
    [averageFilter setValue:leftExtent forKey:@"inputExtent"];
    self.channel3Color = [self colorFromFirstPixelOfCIImage:[averageFilter valueForKey:@"outputImage"]];

    //Right
    [averageFilter setValue:rightExtent forKey:@"inputExtent"];
    self.channel4Color = [self colorFromFirstPixelOfCIImage:[averageFilter valueForKey:@"outputImage"]];
    
    [self sendColours];
    
    if (!self.avoidRenderingIfPossible)
        [self setPreviewImageWithBitmapImageRep:[[[NSBitmapImageRep alloc] initWithCIImage:ciImage] autorelease]];
}

-(void)calculateColoursOfImageWithAverageHue:(CGImageRef)imageRef {
    
    self.channel1Color = [NSColor whiteColor];
    self.channel2Color = [NSColor whiteColor];
    self.channel3Color = [NSColor whiteColor];
    self.channel4Color = [NSColor whiteColor];

    [self sendColours];
    
    if (!self.avoidRenderingIfPossible)
        [self setPreviewImageWithBitmapImageRep:[[[NSBitmapImageRep alloc] initWithCGImage:imageRef] autorelease]];
}

-(void)sendColours {
    [self.commsController pushColorsToChannel1:self.channel1Color
                                      channel2:self.channel2Color
                                      channel3:self.channel3Color
                                      channel4:self.channel4Color
                                  withDuration:0.0 /*kScreenshotFrequency * .9*/];
}

#pragma mark -
#pragma mark Image Rendering

-(NSColor *)colorFromFirstPixelOfCIImage:(CIImage *)ciImage {
    NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithCIImage:ciImage] autorelease];
    return [rep colorAtX:0 y:0];
}

-(void)setPreviewImageWithBitmapImageRep:(NSBitmapImageRep *)rep {
    
    NSImage *previewImage = [[NSImage alloc] initWithSize:NSMakeSize([rep pixelsWide], [rep pixelsHigh])];
    [previewImage addRepresentation:rep];
    [self setImage:previewImage];
    [previewImage release];
}

@end
