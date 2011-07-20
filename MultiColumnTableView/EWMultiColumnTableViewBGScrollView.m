/*
 * Copyright (c) 2011 Eli Wang
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */


#import "EWMultiColumnTableViewBGScrollView.h"
#import "EWMultiColumnTableView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+AddLine.h"


@implementation EWMultiColumnTableViewBGScrollView

@synthesize parent;

- (void)dealloc
{
    [lines release];
    [super dealloc];
}

- (void)redraw
{
    if (lines == nil) lines = [[NSMutableArray alloc] initWithCapacity:10];
    
    for (UIView *v in lines) {
        [v removeFromSuperview];
    }
    
    [lines removeAllObjects];
    
    UIView *v = [[[UIView alloc] initWithFrame:CGRectMake(0.0f - parent.normalSeperatorLineWidth, 0.0f,
                                                          parent.normalSeperatorLineWidth, self.frame.size.height)] autorelease];
    v.backgroundColor = parent.normalSeperatorLineColor;
    [self addSubview:v];
    [lines addObject:v];
    
    CGFloat x = 0.0f;
    for (int i = 0; i < [parent.dataSource numberOfColumnsInTableView:parent]; i++) {
        CGFloat width;
        if ([parent.dataSource respondsToSelector:@selector(tableView:widthForColumn:)])
            width = [parent.dataSource tableView:parent widthForColumn:i];
        else
            width = parent.cellWidth;
        
        x += width + parent.normalSeperatorLineWidth;
        v = [self addVerticalLineWithWidth:parent.normalSeperatorLineWidth color:parent.normalSeperatorLineColor atX:x];
        [lines addObject:v];
    }
    
}

@end
