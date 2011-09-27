//
//  BlinkEditorWC.m
//  Dioder Screen Colours
//
//  Created by Joachim Bengtsson on 2011-09-27.
//  Copyright (c) 2011 Daniel Kennett. All rights reserved.
//

#import "BlinkEditorWC.h"

@implementation BEBlink
@synthesize bottom, top, left, right;
@synthesize bottomActive, topActive, leftActive, rightActive;
@synthesize duration;
-(id)init;
{
    self.duration = .5;
    return self;
}
-(void)dealloc;
{
    self.bottom = nil;
    self.top = nil;
    self.left = nil;
    self.right = nil;
}
@end

@implementation BEBlinkSequence
@synthesize blinks, name;
-(id)init;
{
    self.name = @"Untitled";
    self.blinks = [NSMutableArray array];
    return self;
}
-(void)dealloc;
{
    self.blinks = nil;
    self.name = nil;
    [super dealloc];
}
@end

@implementation BlinkEditorWC
@synthesize blinkSequences, blinkSequencesC;
-(id)init;
{
    if(!(self = [super initWithWindowNibName:NSStringFromClass([self class])])) return nil;
    
    self.blinkSequences = [NSMutableArray array];
    
    return self;
}
-(void)dealloc;
{
    self.blinkSequences = nil;
    [super dealloc];
}

static NSArray *colorToArray(NSColor *color) {
    NSColor *rgb = [color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
    return [NSArray arrayWithObjects:[NSNumber numberWithFloat:[rgb redComponent]], [NSNumber numberWithFloat:[rgb greenComponent]], [NSNumber numberWithFloat:[rgb blueComponent]], nil];
}

-(IBAction)runSelection:(id)sender;
{
    NSArray *selection = [blinkSequencesC selectedObjects];
    if([selection count] != 1) {
        NSBeep(); return;
    }
    BEBlinkSequence *seq = [selection objectAtIndex:0];
    
    NSDistributedNotificationCenter *distC = [NSDistributedNotificationCenter defaultCenter];
    
    for(BEBlink *blink in seq.blinks) {
        NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSArray arrayWithObjects:
                blink.bottomActive ? colorToArray(blink.bottom) : (id)kCFBooleanFalse,
                blink.topActive ? colorToArray(blink.top) : (id)kCFBooleanFalse,
                blink.leftActive ? colorToArray(blink.left) : (id)kCFBooleanFalse,
                blink.rightActive ? colorToArray(blink.right) : (id)kCFBooleanFalse,
                nil
            ], @"colors",
            [NSNumber numberWithDouble:blink.duration], @"interval",
            nil
        ];
        [distC postNotificationName:@"DioderBlink" object:nil userInfo:args];
    }
}

@end
