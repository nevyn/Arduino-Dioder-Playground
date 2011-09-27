//
//  BlinkEditorWC.h
//  Dioder Screen Colours
//
//  Created by Joachim Bengtsson on 2011-09-27.
//  Copyright (c) 2011 Daniel Kennett. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BEBlink : NSObject <NSCoding>
@property(nonatomic,retain) NSColor *bottom;
@property(nonatomic,retain) NSColor *top;
@property(nonatomic,retain) NSColor *left;
@property(nonatomic,retain) NSColor *right;
@property(nonatomic,assign) BOOL bottomActive;
@property(nonatomic,assign) BOOL topActive;
@property(nonatomic,assign) BOOL leftActive;
@property(nonatomic,assign) BOOL rightActive;
@property(nonatomic,assign) NSTimeInterval duration;
@end

@interface BEBlinkSequence : NSObject <NSCoding>
@property(nonatomic,retain) NSMutableArray *blinks;
@property(nonatomic,retain) NSString *name;
@end

@interface BlinkEditorWC : NSWindowController
@property(nonatomic,retain) NSMutableArray *blinkSequences;
@property(nonatomic,assign) IBOutlet NSArrayController *blinkSequencesC;
-(id)init;
-(IBAction)runSelection:(id)sender;
-(void)save;
@end
