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


#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "EWMultiColumnTableViewContentBackgroundView.h"
#import "EWMultiColumnTableViewDefaults.h"
#import "EWMultiColumnTableViewBGScrollView.h"

@protocol EWMultiColumnTableViewDataSource;

typedef enum __EWMultiColumnTableViewColumnPosition {
    EWMultiColumnTableViewColumnPositionLeft,
    EWMultiColumnTableViewColumnPositionMiddle,
    EWMultiColumnTableViewColumnPositionRight
} EWMultiColumnTableViewColumnPosition;


@interface EWMultiColumnTableView : UIView<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate> {
    BOOL respondsToReuseIdAtIndexPath;
    BOOL respondsToNumberOfSections;
    
    BOOL respondsToHeightForCell;
    BOOL respondsToHeightForHeaderCell;
    BOOL respondsToLeftHeaderCell;
    BOOL respondsToWidthForHeaderCell;
    BOOL respondsToWidthForColumn;
    
    BOOL respondsToHeightForSectionHeaderCell;
    BOOL respondsToHeightForHeaderCellInSectionHeader;
    
    BOOL respondsToSetContentForHeaderCellAtRow;
    BOOL respondsToHeaderCellForColumn;
    BOOL respondsToSetContentForHeaderCellAtColumn;
    BOOL respondsToHeightForTopHeaderCell;
    
    NSInteger selectedColumn;
    
    EWMultiColumnTableViewBGScrollView *scrlView;
    UITableView *headerTblView;
    EWMultiColumnTableViewContentBackgroundView *tblView;
    
    // Keep if or not each section is folded. YES for folded, NO for expanded.
    NSMutableArray *sectionFoldingStatus;
    NSMutableArray *indexPathTable;
    
    UIView *tblViewHeader;
    
    CALayer *highlightColumnLayer;
}

@property (nonatomic, assign) id<EWMultiColumnTableViewDataSource> dataSource;

@property (nonatomic, assign) CGFloat cellHeight;
@property (nonatomic, assign) CGFloat cellWidth;
@property (nonatomic, assign) CGFloat topHeaderHeight;
@property (nonatomic, assign) CGFloat leftHeaderWidth;
@property (nonatomic, assign) CGFloat sectionHeaderHeight;
@property (nonatomic, assign) CGFloat boldSeperatorLineWidth;
@property (nonatomic, assign) CGFloat normalSeperatorLineWidth;

@property (nonatomic, retain) UIColor *boldSeperatorLineColor;
@property (nonatomic, retain) UIColor *normalSeperatorLineColor;

@property (nonatomic, retain) UIColor *leftHeaderBackgroundColor;
@property (nonatomic, retain) UIColor *sectionHeaderBackgroundColor;

@property (nonatomic, retain) UIColor *topHeaderBackgroundColor;

@property (nonatomic, assign) BOOL sectionFoldedByDefault;
@property (nonatomic, assign) BOOL sectionHeaderEnabled;

- (void)reloadData;
- (BOOL)sectionIsFolded:(NSInteger)section;

- (void)scrollToColumn:(NSInteger)col position:(EWMultiColumnTableViewColumnPosition)pos animated:(BOOL)animated;

@end



@protocol EWMultiColumnTableViewDataSource <NSObject>

- (UIView *)tableView:(EWMultiColumnTableView *)tableView cellForIndexPath:(NSIndexPath *)indexPath column:(NSInteger)col;
- (void)tableView:(EWMultiColumnTableView *)tableView setContentForCell:(UIView *)cell indexPath:(NSIndexPath *)indexPath column:(NSInteger)col;
- (NSInteger)tableView:(EWMultiColumnTableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (NSInteger)numberOfColumnsInTableView:(EWMultiColumnTableView *)tableView;


@optional

- (CGFloat)tableView:(EWMultiColumnTableView *)tableView heightForCellAtIndexPath:(NSIndexPath *)indexPath column:(NSInteger)column;

- (CGFloat)tableView:(EWMultiColumnTableView *)tableView widthForColumn:(NSInteger)column;

// If not implemented, a default cell id will be given.
- (NSString *)tableView:(EWMultiColumnTableView *)tableView reuseIdForIndexPath:(NSIndexPath *)multiColIndexPath;

#pragma mark - Header Cell
#pragma mark height and width
- (CGFloat)tableView:(EWMultiColumnTableView *)tableView heightForHeaderCellAtIndexPath:(NSIndexPath *)indexPath;
// Top header row
- (CGFloat)heightForHeaderCellOfTableView:(EWMultiColumnTableView *)tableView;
// Left header column
- (CGFloat)widthForHeaderCellOfTableView:(EWMultiColumnTableView *)tableView;

#pragma mark cell and content
// Create a new header cell in left
- (UIView *)tableView:(EWMultiColumnTableView *)tableView headerCellForIndexPath:(NSIndexPath *)indexPath;
// set content for a resuable header cell
- (void)tableView:(EWMultiColumnTableView *)tableView setContentForHeaderCell:(UIView *)cell atIndexPath:(NSIndexPath *)multiColIndexPath;

- (UIView *)tableView:(EWMultiColumnTableView *)tableView headerCellForColumn:(NSInteger)col;
- (void)tableView:(EWMultiColumnTableView *)tableView setContentForHeaderCell:(UIView *)cell atColumn:(NSInteger)col;
- (UIView *)topleftHeaderCellOfTableView:(EWMultiColumnTableView *)tableView;




#pragma mark - Action callback
- (void)tableView:(EWMultiColumnTableView *)tableView swapDataOfColumn:(NSInteger)col1 andColumn:(NSInteger)col2;




#pragma mark - Section and section header

- (NSInteger)numberOfSectionsInTableView:(EWMultiColumnTableView *)tableView;

#pragma mark section header normal cell
// new cell
- (UIView *)tableView:(EWMultiColumnTableView *)tableView sectionHeaderCellForSection:(NSInteger)section column:(NSInteger)col;
// set content
- (void)tableView:(EWMultiColumnTableView *)tableView setContentForSectionHeaderCell:(UIView *)cell section:(NSInteger)section column:(NSInteger)col;
// height
- (CGFloat)tableView:(EWMultiColumnTableView *)tableView heightForSectionHeaderCellAtSection:(NSInteger)section column:(NSInteger)col;

#pragma mark table header in section header
// new cell
- (UIView *)tableView:(EWMultiColumnTableView *)tableView headerCellInSectionHeaderForSection:(NSInteger)section;
- (void)tableView:(EWMultiColumnTableView *)tableView setContentForHeaderCellInSectionHeader:(UIView *)cell AtSection:(NSInteger)section;
// height
- (CGFloat)tableView:(EWMultiColumnTableView *)tableView heightForHeaderCellInSectionHeaderAtSection:(NSInteger)section;

@end
