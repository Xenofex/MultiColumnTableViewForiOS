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


#import "EWMultiColumnTableView.h"
#import <QuartzCore/QuartzCore.h>
#import "EWHeaderHighlightLayer.h"
#import "EWMultiColumnTableViewCell.h"
#import "UIView+AddLine.h"


#define HeaderCellTag -1
#define AddHeightTo(v, h) { CGRect f = v.frame; f.size.height += h; v.frame = f; }

@interface EWMultiColumnTableView()

- (void)adjustWidth;
- (void)setupHeaderTblView;
- (void)rebuildIndexPathTable;
- (void)orientationChanged:(NSNotification *)notification;
- (void)highlightColumn:(NSInteger)col;
- (void)clearHighlightColumn;
- (void)reset;

- (void)toggleFoldOfSection:(NSInteger)section withRowNumber:(NSInteger)row rowAnimation:(UITableViewRowAnimation)animation;

- (UITableViewCell *)tblView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tblView:(UITableView *)tableView regularCellForRowAtIndexPath:(NSIndexPath *)multiColIndexPath;
- (UITableViewCell *)tblView:(UITableView *)tableView sectionHeaderCellForRowAtIndexPath:(NSIndexPath *)multiColIndexPath;
- (UITableViewCell *)headerTblView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)multiColIndexPath;

- (NSInteger)numberOfSections;
- (CGFloat)heightForCellAtIndexPath:(NSIndexPath *)indexPath column:(NSInteger)column;
- (CGFloat)widthForColumn:(NSInteger)column;
- (CGFloat)heightForHeaderCellAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)heightForTopHeaderCell;
- (CGFloat)widthForLeftHeaderCell;
- (CGFloat)heightForSectionHeaderCellAtSection:(NSInteger)section column:(NSInteger)col;
- (CGFloat)heightForHeaderCellInSectionHeaderAtSection:(NSInteger)section;


- (CGRect)highlightRectForColumn:(NSInteger)col;


- (void)columnLongPressed:(UILongPressGestureRecognizer *)recognizer;

- (NSInteger)columnOfPointInTblView:(CGPoint)point;
- (NSMutableArray *)indexPathsOfSection:(NSInteger)section headerRow:(NSInteger)row;
- (void)swapColumn:(NSInteger)col1 andColumn:(NSInteger)col2;

@end






@implementation EWMultiColumnTableView

@synthesize dataSource;
@synthesize cellHeight, cellWidth, topHeaderHeight, leftHeaderWidth, sectionHeaderHeight;
@synthesize leftHeaderBackgroundColor, sectionHeaderBackgroundColor, sectionFoldedByDefault;
@synthesize sectionHeaderEnabled;

@synthesize normalSeperatorLineColor, normalSeperatorLineWidth, boldSeperatorLineColor, boldSeperatorLineWidth;
@synthesize topHeaderBackgroundColor;


#pragma constructors and dealloc

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        
        self.layer.borderColor = [[UIColor colorWithWhite:EWMultiColumnTable_BorderColorGray alpha:1.0f] CGColor];
        self.layer.cornerRadius = EWMultiColumnTable_CornerRadius;
        self.layer.borderWidth = EWMultiColumnTable_BorderWidth;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        
        cellHeight = EWMultiColumnTable_DefaultCellHeight;
        cellWidth = EWMultiColumnTable_DefaultCellWidth;
        topHeaderHeight = EWMultiColumnTable_DefaultTopHeaderHeight;
        leftHeaderWidth = EWMultiColumnTable_DefaultLeftHeaderWidth;
        sectionHeaderHeight = EWMultiColumnTable_DefaultSectionHeaderHeight;
        
        boldSeperatorLineWidth = EWMultiColumnTable_BoldLineWidth;
        normalSeperatorLineWidth = EWMultiColumnTable_NormalLineWidth;
        self.boldSeperatorLineColor = [UIColor colorWithWhite:EWMultiColumnTable_LineGray alpha:1.0f];
        self.normalSeperatorLineColor = [UIColor colorWithWhite:EWMultiColumnTable_LineGray alpha:1.0f];
        
        self.leftHeaderBackgroundColor = [UIColor colorWithWhite:249.0f/255.0f alpha:1.0f];
        self.sectionHeaderBackgroundColor = [UIColor colorWithWhite:241.0f/255.0f alpha:1.0f];
        self.topHeaderBackgroundColor = [UIColor whiteColor];
        sectionFoldedByDefault = NO;
        
        
        selectedColumn = -1;
        sectionFoldingStatus = [[NSMutableArray alloc] initWithCapacity:10];
        
        scrlView = [[EWMultiColumnTableViewBGScrollView alloc] initWithFrame:self.bounds];
        scrlView.parent = self;
        scrlView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:scrlView];
        
        tblView = [[EWMultiColumnTableViewContentBackgroundView alloc] initWithFrame:scrlView.bounds];
        tblView.dataSource = self;
        tblView.delegate = self;
        tblView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tblView.backgroundColor = [UIColor clearColor];
        [scrlView addSubview:tblView];
        
        UILongPressGestureRecognizer *recognizer = [[[UILongPressGestureRecognizer alloc] 
                                                     initWithTarget:self action:@selector(columnLongPressed:)] autorelease];
        recognizer.minimumPressDuration = 1.0;
        [tblView addGestureRecognizer:recognizer];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [tblView release];
    [headerTblView release];
    [scrlView release];
    [sectionFoldingStatus release];
    [indexPathTable release];
    [highlightColumnLayer release];
    [tblViewHeader release];
    
    [leftHeaderBackgroundColor release];
    [sectionHeaderBackgroundColor release];
    [normalSeperatorLineColor release];
    [boldSeperatorLineColor release];
    [topHeaderBackgroundColor release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, boldSeperatorLineWidth);
    CGContextSetAllowsAntialiasing(context, 0);
    
    CGContextSetStrokeColorWithColor(context, [boldSeperatorLineColor CGColor]);
    
    if (respondsToLeftHeaderCell) {
        CGFloat x = [self widthForLeftHeaderCell] + boldSeperatorLineWidth / 2.0f;
        CGContextMoveToPoint(context, x, 0.0f);
        CGContextAddLineToPoint(context, x, self.frame.size.height);
    }
    CGContextStrokePath(context);
    
    
}

#pragma mark - Methods

- (void)reloadData
{
    [self reset];
    
    
    [headerTblView reloadData];
    [tblView reloadData];
    [self adjustWidth];
}

- (BOOL)sectionIsFolded:(NSInteger)section
{
    return [[sectionFoldingStatus objectAtIndex:section] boolValue];
}

- (void)scrollToColumn:(NSInteger)col position:(EWMultiColumnTableViewColumnPosition)pos animated:(BOOL)animated
{
    CGFloat x = 0.0f;
    
    for (int i = 0; i < col; i++) {
        x += [self widthForColumn:i] + normalSeperatorLineWidth;
    }
    
    switch (pos) {
        case EWMultiColumnTableViewColumnPositionMiddle:
            x -= (scrlView.bounds.size.width - (2 * normalSeperatorLineWidth + [self widthForColumn:col])) / 2;
            if (x < 0.0f) x = 0.0f;
            break;
        case EWMultiColumnTableViewColumnPositionRight:
            x -= scrlView.bounds.size.width - (2 * normalSeperatorLineWidth + [self widthForColumn:col]);
            if (x < 0.0f) x = 0.0f;
            break;
        default:
            break;
    
    }
        
    [scrlView setContentOffset:CGPointMake(x, 0) animated:animated];
}

#pragma mark - Properties

- (void)setDataSource:(id<EWMultiColumnTableViewDataSource>)dataSource_
{
    if (dataSource != dataSource_) {
        dataSource = dataSource_;
        
        respondsToReuseIdAtIndexPath = [dataSource_ respondsToSelector:@selector(tableView:reuseIdForIndexPath:)];
        respondsToNumberOfSections = [dataSource_ respondsToSelector:@selector(numberOfSectionsInTableView:)];
        
        respondsToHeightForCell = [dataSource_ respondsToSelector:@selector(tableView:heightForCellAtIndexPath:column:)];
        respondsToLeftHeaderCell = [dataSource_ respondsToSelector:@selector(tableView:headerCellForIndexPath:)];
        respondsToHeightForHeaderCell = [dataSource_ respondsToSelector:@selector(tableView:heightForHeaderCellAtIndexPath:)];
        respondsToWidthForHeaderCell = [dataSource_ respondsToSelector:@selector(widthForHeaderCellOfTableView:)];
        respondsToSetContentForHeaderCellAtRow = [dataSource_ respondsToSelector:@selector(tableView:setContentForHeaderCell:atRow:)];
        respondsToHeaderCellForColumn = [dataSource_ respondsToSelector:@selector(tableView:headerCellForColumn:)];
        respondsToSetContentForHeaderCellAtColumn = [dataSource_ respondsToSelector:@selector(tableView:setContentForHeaderCell:atColumn:)];
        respondsToWidthForColumn = [dataSource_ respondsToSelector:@selector(tableView:widthForColumn:)];
        respondsToHeightForTopHeaderCell = [dataSource_ respondsToSelector:@selector(heightForHeaderCellOfTableView:)];
        respondsToHeightForSectionHeaderCell = [dataSource_ respondsToSelector:@selector(tableView:heightForSectionHeaderCellAtSection:column:)];
        respondsToHeightForHeaderCellInSectionHeader = [dataSource_ respondsToSelector:@selector(tableView:heightForHeaderCellInSectionHeaderAtSection:)];
        
        // set contentSize of the scrollView and the width of the tableView
        [self adjustWidth];
        
        // Initialize sectionFoldingStatus
        [sectionFoldingStatus release];
        sectionFoldingStatus = [[NSMutableArray alloc] initWithCapacity:[self numberOfSections]];
        for (int i = 0; i < [self numberOfSections]; i++) {
            [sectionFoldingStatus addObject:[NSNumber numberWithBool:sectionFoldedByDefault]];
        } 
        
        [self reset];
        
        if (respondsToLeftHeaderCell)
            [self setupHeaderTblView];
        
    }
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numOfRows = 0;
    NSInteger numOfSec = [self numberOfSections];
    
    
    for (int i = 0; i < numOfSec; i++) {
        if (sectionHeaderEnabled)
            numOfRows++;
        
        if (!sectionHeaderEnabled || ![[sectionFoldingStatus objectAtIndex:i] boolValue])
            numOfRows += [dataSource tableView:self numberOfRowsInSection:i];
    }
    
    return numOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == tblView) {
        return [self tblView:tableView cellForRowAtIndexPath:indexPath];
    } else {
        return [self headerTblView:tableView cellForRowAtIndexPath:indexPath];
    }
}

- (UITableViewCell *)tblView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *multiColIndexPath = [indexPathTable objectAtIndex:indexPath.row];
    
    if (sectionHeaderEnabled && [multiColIndexPath length] == 1)
        return [self tblView:tableView sectionHeaderCellForRowAtIndexPath:multiColIndexPath];
    else
        return [self tblView:tableView regularCellForRowAtIndexPath:multiColIndexPath];
}

- (UITableViewCell *)tblView:(UITableView *)tableView regularCellForRowAtIndexPath:(NSIndexPath *)multiColIndexPath
{
    NSInteger numOfCols = [dataSource numberOfColumnsInTableView:self];
    
    static NSString *CellID;
    
    if (respondsToReuseIdAtIndexPath)
        CellID = [dataSource tableView:self reuseIdForIndexPath:multiColIndexPath] ?: @"MultiColumnCell";
    else
        CellID = @"MultiColumnCell";
    
    EWMultiColumnTableViewCell *cell = (EWMultiColumnTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellID];
    
    if (cell == nil) {
        cell = [[[EWMultiColumnTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellID] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell addBottomLineWithWidth:normalSeperatorLineWidth color:normalSeperatorLineColor];
    }
    
    NSInteger columnsDiff = numOfCols - [[cell columnCells] count];
    
    if (columnsDiff > 0) {
        // Add the grid cells - call the delegate method to init the grid cells
        CGFloat x = 0.0f;
        UIView *lastCol = [[cell columnCells] lastObject];
        if (lastCol) x = lastCol.frame.origin.x + lastCol.frame.size.width;
        
        for (int i = 0; i < columnsDiff; i++) {
            UIView *gridCell = [dataSource tableView:self cellForIndexPath:multiColIndexPath column:i];
            CGRect f = gridCell.frame;
            f.origin.x += x;
            gridCell.frame = f;
            [cell.contentView addSubview:gridCell];
            
            CGFloat colWidth = [self widthForColumn:i];
            
            x += colWidth + normalSeperatorLineWidth;
            [[cell columnCells] addObject:gridCell];
        }
    } else if (columnsDiff < 0) {
        columnsDiff = -columnsDiff;
        for (int i = 0; i < columnsDiff; i++) {
            [[[cell columnCells] lastObject] removeFromSuperview];
            [[cell columnCells] removeLastObject];
        }
    }
    
    
    // call delegate method to set the cells of the other columns
    
    for (int i = 0; i < numOfCols; i++) {
        [dataSource tableView:self setContentForCell:[[cell columnCells] objectAtIndex:i] 
                    indexPath:multiColIndexPath column:i];
    }
    
    AddHeightTo(cell, normalSeperatorLineWidth);
    
    return cell;
}

- (UITableViewCell *)tblView:(UITableView *)tableView sectionHeaderCellForRowAtIndexPath:(NSIndexPath *)multiColIndexPath
{
    NSInteger numOfCols = [dataSource numberOfColumnsInTableView:self];
    NSInteger section = [multiColIndexPath indexAtPosition:0];
    
    static NSString *CellID = @"SectionHeaderCell";
    
    EWMultiColumnTableViewCell *cell = (EWMultiColumnTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellID];
    
    if (cell == nil) {
        cell = [[[EWMultiColumnTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellID] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.contentView.backgroundColor = sectionHeaderBackgroundColor;
        [cell addBottomLineWithWidth:normalSeperatorLineWidth color:normalSeperatorLineColor];
    }
    
    NSInteger columnsDiff = numOfCols - [[cell columnCells] count];
    
    if (columnsDiff > 0) {
        // Add the grid cells - call the delegate method to init the grid cells
        CGFloat x = 0.0f;
        UIView *lastCol = [[cell columnCells] lastObject];
        if (lastCol) x = lastCol.frame.origin.x + lastCol.frame.size.width;
        
        for (int i = 0; i < columnsDiff; i++) {
            UIView *gridCell = [dataSource tableView:self sectionHeaderCellForSection:section column:i];
            
            CGRect f = gridCell.frame;
            f.origin.x += x;
            gridCell.frame = f;
            [cell.contentView addSubview:gridCell];
            
            CGFloat colWidth = [self widthForColumn:i];
            
            x += colWidth + normalSeperatorLineWidth;
            [[cell columnCells] addObject:gridCell];
        }
    } else if (columnsDiff < 0) {
        columnsDiff = -columnsDiff;
        for (int i = 0; i < columnsDiff; i++) {
            [[[cell columnCells] lastObject] removeFromSuperview];
            [[cell columnCells] removeLastObject];
        }
    }
    
    
    // call delegate method to set the cells of the other columns
    
    for (int i = 0; i < numOfCols; i++) {
        [dataSource tableView:self setContentForSectionHeaderCell:[[cell columnCells] objectAtIndex:i] 
                      section:section column:i];
    }
    
    AddHeightTo(cell, normalSeperatorLineWidth);
    
    return cell;
}

- (UITableViewCell *)headerTblView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *multiColIndexPath = [indexPathTable objectAtIndex:indexPath.row];
    static NSString *CellID;
    if (sectionHeaderEnabled && [multiColIndexPath length] == 1)
        CellID = @"HeaderCellInSectionHeader";
    else
        CellID = @"HeaderCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellID] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIView *headerCellView;
        
        if (sectionHeaderEnabled && [multiColIndexPath length] == 1) {
            headerCellView = [dataSource tableView:self headerCellInSectionHeaderForSection:[multiColIndexPath indexAtPosition:0]];
            cell.contentView.backgroundColor = sectionHeaderBackgroundColor;
        } else {       
            headerCellView = [dataSource tableView:self headerCellForIndexPath:indexPath];
        }
        
        headerCellView.tag = HeaderCellTag;
        [cell.contentView addSubview:headerCellView];
        [cell addBottomLineWithWidth:normalSeperatorLineWidth color:normalSeperatorLineColor];
    }
    
    if (sectionHeaderEnabled && [multiColIndexPath length] == 1) 
        [dataSource tableView:self setContentForHeaderCellInSectionHeader:[cell viewWithTag:HeaderCellTag] 
                    AtSection:[multiColIndexPath indexAtPosition:0]];
    else
        [dataSource tableView:self setContentForHeaderCell:[cell viewWithTag:HeaderCellTag] 
                  atIndexPath:multiColIndexPath];
    
    AddHeightTo(cell, normalSeperatorLineWidth);
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *multiColIndexPath = [indexPathTable objectAtIndex:indexPath.row];
    
    if (sectionHeaderEnabled && [multiColIndexPath length] == 1) {
        // Calculate section header
        
        NSInteger section = [multiColIndexPath indexAtPosition:0];
        CGFloat height = [self heightForHeaderCellInSectionHeaderAtSection:section];
        
        // calculate the height of the cells in this row
        NSInteger numOfCols = [dataSource numberOfColumnsInTableView:self];
        for (int i = 0; i < numOfCols; i++) {
            //      call delegate method to calculate the individual cell
            CGFloat h = [self heightForSectionHeaderCellAtSection:section column:i];
            
            if (h > height) height = h;
        }
        
        // return the Maximum of them.
        return height + normalSeperatorLineWidth;
        
    } else {
        // Calculate normal row
        
        CGFloat height = [self heightForHeaderCellAtIndexPath:multiColIndexPath];
        
        // calculate the height of the cells in this row
        NSInteger numOfCols = [dataSource numberOfColumnsInTableView:self];
        for (int i = 0; i < numOfCols; i++) {
            //      call delegate method to calculate the individual cell
            CGFloat h = [self heightForCellAtIndexPath:multiColIndexPath column:i];
            
            if (h > height) height = h;
        }
        
        // return the Maximum of them.
        return height + normalSeperatorLineWidth;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == tblView) {
        [tblViewHeader release];
        tblViewHeader = [[UIView alloc] initWithFrame:CGRectZero];
        tblViewHeader.clipsToBounds = YES;
        tblViewHeader.backgroundColor = [UIColor clearColor];
        
        NSInteger cols = [dataSource numberOfColumnsInTableView:self];
        CGFloat x = 0.0f, height = 0.0f;
        
        for (int i = 0; i < cols; i++) {
            UIView *headerCell = [dataSource tableView:self headerCellForColumn:i];
            CGRect f = headerCell.frame;
            f.origin.x = x;
            headerCell.frame = f;
            [tblViewHeader addSubview:headerCell];
            height = MAX(height, f.size.height);
            
            x += [self widthForColumn:i] + normalSeperatorLineWidth;
        }
        
        CGRect f = tblViewHeader.frame;
        CGFloat width = MAX(x - normalSeperatorLineWidth, tblView.frame.size.width);
        f.size = CGSizeMake(width, height);
        tblViewHeader.frame = f;
        tblViewHeader.backgroundColor = self.topHeaderBackgroundColor;
        
        [tblViewHeader addBottomLineWithWidth:boldSeperatorLineWidth color:boldSeperatorLineColor];
        
        return tblViewHeader;
    } else {
        if ([dataSource respondsToSelector:@selector(topleftHeaderCellOfTableView:)]) {
            UIView *header = [dataSource topleftHeaderCellOfTableView:self];
            
            UIView *container = [[[UIView alloc] initWithFrame:header.frame] autorelease];
            CGRect f = container.frame;
            f.size.height = [self heightForTopHeaderCell];
            container.frame = f;
            
            [container addSubview:header];
            [container addBottomLineWithWidth:boldSeperatorLineWidth color:boldSeperatorLineColor];
            
            return container;
        } else {
            return [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self heightForTopHeaderCell] + boldSeperatorLineWidth;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == headerTblView) {
        NSIndexPath *multiColIndexPath = [indexPathTable objectAtIndex:indexPath.row];
        if (sectionHeaderEnabled && [multiColIndexPath length] == 1) {
            [self toggleFoldOfSection:[multiColIndexPath indexAtPosition:0] 
                        withRowNumber:indexPath.row rowAnimation:UITableViewRowAnimationTop];
        }
        
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    UIScrollView *target;
    if (scrollView == tblView)
        target = headerTblView;
    else
        target = tblView;
    
    target.contentOffset = scrollView.contentOffset;
}



#pragma mark - Private Methods

#pragma mark Procedures

- (void)reset 
{
    NSInteger numOfSec = [self numberOfSections];
    if (sectionHeaderEnabled && [sectionFoldingStatus count] == 0) {
        for (int i = 0; i < numOfSec; i++) {
            [sectionFoldingStatus addObject:[NSNumber numberWithBool:sectionFoldedByDefault]];
        } 
    }
    
    [indexPathTable release];
    indexPathTable = [[NSMutableArray alloc] initWithCapacity:numOfSec * 5];
    [self rebuildIndexPathTable];
    [scrlView redraw];
    
}

- (void)adjustWidth
{
    CGFloat width = 0.0f;
    NSInteger cols = [dataSource numberOfColumnsInTableView:self];
    for (int i = 0; i < cols; i++) {
        width += [self widthForColumn:i] + normalSeperatorLineWidth;
    }
    
    width -= normalSeperatorLineWidth;
    scrlView.contentSize = CGSizeMake(width, 0.0f);
    
    CGRect f = tblView.frame;
    f.size.width = MAX(self.frame.size.width - [self widthForLeftHeaderCell], width);
    tblView.frame = f;
}

- (void)setupHeaderTblView
{
    CGFloat headerCellWidth = [self widthForLeftHeaderCell];
    
    [headerTblView removeFromSuperview];
    [headerTblView release];
    headerTblView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, headerCellWidth, self.frame.size.height)];
    headerTblView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    headerTblView.delegate = self;
    headerTblView.dataSource = self;
    headerTblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    headerTblView.showsVerticalScrollIndicator = NO;
    headerTblView.backgroundColor = leftHeaderBackgroundColor;
    [self addSubview:headerTblView];
    
    scrlView.frame = CGRectMake(headerCellWidth + boldSeperatorLineWidth, 0.0f, 
                                self.frame.size.width - headerCellWidth - boldSeperatorLineWidth, self.frame.size.height);
}

- (void)rebuildIndexPathTable
{
    [indexPathTable removeAllObjects];
    
    NSInteger numOfSec = [self numberOfSections];
    for (int i = 0; i < numOfSec; i++) {
        if (sectionHeaderEnabled)
            [indexPathTable addObject:[NSIndexPath indexPathWithIndex:i]];
        
        if (!sectionHeaderEnabled || ![[sectionFoldingStatus objectAtIndex:i] boolValue]) {
            NSInteger numOfRows = [dataSource tableView:self numberOfRowsInSection:i];
            for (int j = 0; j < numOfRows; j++) {
                [indexPathTable addObject:[NSIndexPath indexPathForRow:j inSection:i]];
            }
        }
    }
    
}

- (void)swapColumn:(NSInteger)col1 andColumn:(NSInteger)col2
{
    [dataSource tableView:self swapDataOfColumn:col1 andColumn:col2];
    [tblView reloadData];
    [scrlView redraw];
}

- (void)toggleFoldOfSection:(NSInteger)section withRowNumber:(NSInteger)row rowAnimation:(UITableViewRowAnimation)animation
{
    @synchronized(self) {
        BOOL folded = [[sectionFoldingStatus objectAtIndex:section] boolValue];
        [sectionFoldingStatus replaceObjectAtIndex:section withObject:[NSNumber numberWithBool:!folded]];
        
        NSMutableArray *indexPaths = [self indexPathsOfSection: section headerRow:row];
        [self rebuildIndexPathTable];
        
        [tblView beginUpdates];
        [headerTblView beginUpdates];
        if (folded) {
            [tblView insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
            [headerTblView insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
        } else {
            [tblView deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
            [headerTblView deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
        }
        [tblView endUpdates];
        [headerTblView endUpdates];
    }
    
}

- (void)highlightColumn:(NSInteger)col
{
    if (highlightColumnLayer == nil) {
        highlightColumnLayer = [[CALayer alloc] init];
        highlightColumnLayer.borderColor = [[UIColor colorWithRed:232.0f/255.0f green:142.0f/255.0f blue:20.0f/255.0f alpha:1.0f] CGColor];
        highlightColumnLayer.borderWidth = ColumnHighlightWidth;
        highlightColumnLayer.shadowRadius = 5.0f;
        highlightColumnLayer.shadowOpacity = 0.5f;
        [self.layer addSublayer:highlightColumnLayer];
    }
    
    
    [CATransaction begin]; 
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    highlightColumnLayer.frame = [self highlightRectForColumn:selectedColumn];
    [CATransaction commit];
    
    
}

- (void)clearHighlightColumn
{
    [highlightColumnLayer removeFromSuperlayer];
    [highlightColumnLayer release];
    highlightColumnLayer = nil;
}

#pragma mark Computations


- (CGFloat)heightForCellAtIndexPath:(NSIndexPath *)indexPath column:(NSInteger)column
{
    if (respondsToHeightForCell)
        return [dataSource tableView:self heightForCellAtIndexPath:indexPath column:column];
    else
        return cellHeight;
}

- (CGFloat)widthForColumn:(NSInteger)column
{
    if (respondsToWidthForColumn)
        return [dataSource tableView:self widthForColumn:column];
    else
        return cellWidth;
}

- (CGFloat)heightForHeaderCellAtIndexPath:(NSIndexPath *)indexPath;
{
    if (respondsToHeightForHeaderCell)
        return [dataSource tableView:self heightForHeaderCellAtIndexPath:indexPath];
    else
        return sectionHeaderHeight;
}

- (CGFloat)heightForTopHeaderCell
{
    if (respondsToHeightForTopHeaderCell)
        return [dataSource heightForHeaderCellOfTableView:self];
    else
        return topHeaderHeight;
}

- (CGFloat)widthForLeftHeaderCell
{
    if (respondsToLeftHeaderCell) {
        if (respondsToWidthForHeaderCell)
            return [dataSource widthForHeaderCellOfTableView:self];
        else
            return leftHeaderWidth;
    } else {
        return 0.0f;
    }
}

- (CGFloat)heightForSectionHeaderCellAtSection:(NSInteger)section column:(NSInteger)col
{
    if (respondsToHeightForSectionHeaderCell)
        return [dataSource tableView:self heightForSectionHeaderCellAtSection:section column:col];
    else
        return sectionHeaderHeight;
}

- (CGFloat)heightForHeaderCellInSectionHeaderAtSection:(NSInteger)section
{
    if (respondsToHeightForHeaderCellInSectionHeader)
        return [dataSource tableView:self heightForHeaderCellInSectionHeaderAtSection:section];
    else
        return cellHeight;
}


- (NSInteger)numberOfSections
{
    if (respondsToNumberOfSections)
        return [dataSource numberOfSectionsInTableView:self];
    else
        return 1;
}

- (NSInteger)columnOfPointInTblView:(CGPoint)point
{
    CGFloat x = point.x, w = 0.0f;
    NSInteger cols = [dataSource numberOfColumnsInTableView:self];
    
    for (int i = 0; i < cols; i++) {
        w += [self widthForColumn:i];
        if (x < w)
            return i;
    }
    
    return -1;
}

- (NSMutableArray *)indexPathsOfSection:(NSInteger)section headerRow:(NSInteger)row
{
    NSInteger numberOfRows = [dataSource tableView:self numberOfRowsInSection:section];
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:10];
    for (int i = 1; i <= numberOfRows; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:row + i inSection:0]];
    }
    return indexPaths;
}

- (CGRect)highlightRectForColumn:(NSInteger)col
{
    CGFloat x = headerTblView.frame.size.width - scrlView.contentOffset.x + boldSeperatorLineWidth;
    for (int i = 0; i < col; i++) {
        x += [self widthForColumn:i] + normalSeperatorLineWidth;
    }
    
    CGFloat w = [self widthForColumn:col];
    
    return CGRectMake(x, EWMultiColumnTable_BorderWidth, w, self.frame.size.height - EWMultiColumnTable_BorderWidth * 2);
}

#pragma mark Event Handelers

- (void)orientationChanged:(NSNotification *)notification
{
    [self adjustWidth];
}

- (void)columnLongPressed:(UILongPressGestureRecognizer *)recognizer
{
    if ([dataSource respondsToSelector:@selector(tableView:swapDataOfColumn:andColumn:)]) {
        switch (recognizer.state) {
            case UIGestureRecognizerStateBegan: {
                // create the drag overlay layer
                CGPoint point = [recognizer locationInView:scrlView];
                selectedColumn = [self columnOfPointInTblView:point];
                
                // Highlight the column
                [self highlightColumn:selectedColumn];
                break;
            } case UIGestureRecognizerStateChanged: {
                // move the dragging layer to the destination.
                CGPoint point = [recognizer locationInView:scrlView];
                NSInteger currentCol = [self columnOfPointInTblView:point];
                
                if (currentCol >= 0 && currentCol != selectedColumn) {
                    [self swapColumn:selectedColumn andColumn:currentCol];
                    selectedColumn = currentCol;
                    [self highlightColumn:selectedColumn];
                }
                
                break;
            }
            case UIGestureRecognizerStateEnded: 
            case UIGestureRecognizerStateCancelled: {
                [self clearHighlightColumn];
                selectedColumn = -1;
                // swap the column
                break;
            } 
            default:
                NSLog(@"recognizer.state: %d", recognizer.state);
                break;
        }
    }
    
}

@end
