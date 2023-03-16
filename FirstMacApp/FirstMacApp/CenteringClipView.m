//
//  CenteringClipView.m
//  FirstMacApp
//
//  Created by sunmengtuo on 2021/8/30.
//

#import "CenteringClipView.h"

@implementation CenteringClipView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (NSRect)constrainBoundsRect:(NSRect)proposedBounds
{
    NSRect rect = [super constrainBoundsRect:proposedBounds];
    NSView *view = self.documentView;
    if (view) {
        if (rect.size.width > view.frame.size.width) {
            rect.origin.x = (rect.size.width - view.frame.size.width) / -2.0;
        }
        if (rect.size.height > view.frame.size.height) {
            rect.origin.y = (rect.size.height - view.frame.size.height) / -2.0;
        }
    }
    return rect;
}

@end
