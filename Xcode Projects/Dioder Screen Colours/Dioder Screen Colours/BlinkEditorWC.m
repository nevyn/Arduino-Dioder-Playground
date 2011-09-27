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
-(id)initWithCoder:(NSKeyedUnarchiver*)decoder;
{
    self.bottom = [decoder decodeObjectForKey:@"bottom"];
    self.top = [decoder decodeObjectForKey:@"top"];
    self.left = [decoder decodeObjectForKey:@"left"];
    self.right = [decoder decodeObjectForKey:@"right"];
    self.bottomActive = [decoder decodeBoolForKey:@"bottomActive"];
    self.topActive = [decoder decodeBoolForKey:@"topActive"];
    self.leftActive = [decoder decodeBoolForKey:@"leftActive"];
    self.rightActive = [decoder decodeBoolForKey:@"rightActive"];
    self.duration = [decoder decodeDoubleForKey:@"duration"];
    return self;
}
-(void)encodeWithCoder:(NSKeyedArchiver*)coder;
{
    [coder encodeObject:self.bottom forKey:@"bottom"];
    [coder encodeObject:self.top forKey:@"top"];
    [coder encodeObject:self.left forKey:@"left"];
    [coder encodeObject:self.right forKey:@"right"];
    [coder encodeBool:self.bottomActive forKey:@"bottomActive"];
    [coder encodeBool:self.topActive forKey:@"topActive"];
    [coder encodeBool:self.leftActive forKey:@"leftActive"];
    [coder encodeBool:self.rightActive forKey:@"rightActive"];
    [coder encodeDouble:self.duration forKey:@"duration"];
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
-(id)initWithCoder:(NSKeyedUnarchiver*)decoder;
{
    self.blinks = [decoder decodeObjectForKey:@"blinks"];
    self.name = [decoder decodeObjectForKey:@"name"];
    return self;
}
-(void)encodeWithCoder:(NSKeyedArchiver *)coder;
{
    [coder encodeObject:self.blinks forKey:@"blinks"];
    [coder encodeObject:self.name forKey:@"name"];
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
+(NSString*)blinksPath;
{
    return [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSAllDomainsMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"blinks"];
}
-(id)init;
{
    if(!(self = [super initWithWindowNibName:NSStringFromClass([self class])])) return nil;
    
    self.blinkSequences = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self class] blinksPath]] ?: [NSMutableArray array];
    
    [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(save) userInfo:nil repeats:YES];
    
    return self;
}
-(void)dealloc;
{
    self.blinkSequences = nil;
    [super dealloc];
}

-(void)save;
{
    [NSKeyedArchiver archiveRootObject:self.blinkSequences toFile:[[self class] blinksPath]];
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
