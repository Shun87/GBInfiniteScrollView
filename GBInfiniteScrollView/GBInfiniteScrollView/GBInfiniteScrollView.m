//
//  GBInfiniteScrollView.h
//  GBInfiniteScrollView
//
//  Created by Gerardo Blanco García on 01/10/13.
//  Copyright (c) 2013 Gerardo Blanco García. All rights reserved.
//

#import "GBInfiniteScrollView.h"

static CGFloat const GBAutoScrollDefaultInterval = 3.0f;

@interface GBInfiniteScrollView ()

/**
 *  Number of pages.
 */
@property (nonatomic) NSUInteger numberOfPages;

/**
 *  The current page index.
 */
@property (nonatomic, readwrite) NSUInteger currentPageIndex;

/**
 *  Array of visible indices.
 */
@property (nonatomic, strong) NSMutableArray *visibleIndices;

/**
 *  Visible pages.
 */
@property (nonatomic, strong) NSMutableArray *visiblePages;

/**
 *  Reusable pages.
 */
@property (nonatomic, strong) NSMutableArray *reusablePages;

/**
 *  A boolean value that determines whether automatic scroll is enabled.
 */
@property (nonatomic) BOOL autoScroll;

/**
 *  Automatic scrolling timer.
 */
@property (nonatomic, strong) NSTimer *timer;

/**
 *  A boolean value that determines whether there is need to reload.
 */
@property (nonatomic) BOOL needsReloadData;

@end

@implementation GBInfiniteScrollView

#pragma mark - Initialization

- (id)init
{
    return [self initWithFrame:[UIScreen mainScreen].applicationFrame];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

#pragma mark - Lazy instantiation

- (NSMutableArray *)visibleIndices
{
    if (!_visibleIndices) {
        _visibleIndices = [[NSMutableArray alloc] init];
    }
    
    return _visibleIndices;
}

- (NSMutableArray *)visiblePages
{
    if (!_visiblePages) {
        _visiblePages = [[NSMutableArray alloc] init];
    }
    
    return _visiblePages;
}

- (NSMutableArray *)reusablePages
{
    if (!_reusablePages) {
        _reusablePages = [[NSMutableArray alloc] init];
    }
    
    return _reusablePages;
}

#pragma mark - Setup

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    self.bounces = NO;
    self.pagingEnabled = YES;
    self.showsHorizontalScrollIndicator = NO;
    self.userInteractionEnabled = YES;
    self.exclusiveTouch = YES;

    [self setupDefautValues];
}

- (void)setupDefautValues
{
    self.autoScroll = NO;
    self.shouldScrollingWrapDataSource = YES;
    self.pageIndex = [self firstPageIndex];
    self.currentPageIndex = [self firstPageIndex];
    self.direction = GBAutoScrollDirectionRightToLeft;
    self.interval = GBAutoScrollDefaultInterval;
}

- (void)setupTimer
{
    if (self.timer) {
        [self.timer invalidate];
    }
    
    if (self.autoScroll) {
        if (self.direction == GBAutoScrollDirectionLeftToRight) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:self.interval
                                                          target:self
                                                        selector:@selector(scrollToPreviousPage)
                                                        userInfo:nil
                                                         repeats:YES];
        } else {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:self.interval
                                                          target:self
                                                        selector:@selector(scrollToNextPage)
                                                        userInfo:nil
                                                         repeats:YES];
        }
    }
}

#pragma mark - Convenient methods

- (BOOL)isEmpty
{
    return ([self numberOfPages] == 0);
}

- (BOOL)isNotEmpty
{
    return (self.isEmpty ? NO : YES);
}

- (BOOL)singlePage
{
    return ([self numberOfPages] == 1);
}

- (BOOL)isScrollNecessary
{
    return (self.isScrollNotNecessary ? NO : YES);
}

- (BOOL)isScrollNotNecessary
{
    return ([self isEmpty] || [self singlePage]);
}

- (BOOL)isLastPage {
    return (self.currentPageIndex==[self lastPageIndex]?YES:NO);
}

- (BOOL)isFirstPage {
    return (self.currentPageIndex==[self firstPageIndex]?YES:NO);
}

#pragma mark - Pages

- (void)updateNumberOfPages
{
    if (self.infiniteScrollViewDataSource &&
        [self.infiniteScrollViewDataSource respondsToSelector:@selector(numberOfPagesInInfiniteScrollView:)]) {
        self.numberOfPages = [self.infiniteScrollViewDataSource numberOfPagesInInfiniteScrollView:self];
    }
}

- (CGFloat)pageWidth
{
    return self.frame.size.width;
}

- (NSUInteger)firstPageIndex
{
    return 0;
}

- (NSUInteger)lastPageIndex
{
    return fmax([self firstPageIndex], [self numberOfPages] - 1);
}

- (NSUInteger)nextIndex:(NSUInteger)index
{
    return (index == [self lastPageIndex]) ? [self firstPageIndex] : (index + 1);
}

- (NSUInteger)previousIndex:(NSUInteger)index
{
    return (index == [self firstPageIndex]) ? [self lastPageIndex] : (index - 1);
}

- (void)updateCurrentPageIndex
{
    self.currentPageIndex = (self.pageIndex > [self lastPageIndex]) ? [self lastPageIndex] : fmaxf(self.pageIndex, 0.0f);
}

- (NSUInteger)nextPageIndex
{
    if (!self.shouldScrollingWrapDataSource && [self isLastPage]) return self.currentPageIndex;
    return [self nextIndex:self.currentPageIndex];
}

- (NSUInteger)previousPageIndex
{
    if (!self.shouldScrollingWrapDataSource && [self isFirstPage]) return self.currentPageIndex;
    return [self previousIndex:self.currentPageIndex];
}

- (void)next
{
    if (self.debug) {
        NSLog(@"Next: %lu", (unsigned long)[self nextPageIndex]);
    }
    
    self.currentPageIndex = [self nextPageIndex];
}

- (void)previous
{
    if (self.debug) {
        NSLog(@"Previous: %lu", (unsigned long)[self previousPageIndex]);
    }
    
    self.currentPageIndex = [self previousPageIndex];
}

- (GBInfiniteScrollViewPage *)pageAtIndex:(NSUInteger)index
{
    GBInfiniteScrollViewPage *page = nil;
    
    NSUInteger visibleIndex = [self.visibleIndices indexOfObject:[NSNumber numberWithUnsignedInteger:index]];
    
    if ((visibleIndex == NSNotFound) || (self.needsReloadData)) {
        if (self.infiniteScrollViewDataSource &&
            [self.infiniteScrollViewDataSource respondsToSelector:@selector(infiniteScrollView:pageAtIndex:)]) {
            page = [self.infiniteScrollViewDataSource infiniteScrollView:self pageAtIndex:index];
        }
        
        self.needsReloadData = NO;
    } else {
        page = [self.visiblePages objectAtIndex:visibleIndex];
    }

    return page;
}

- (GBInfiniteScrollViewPage *)nextPage
{
    return [self pageAtIndex:[self nextPageIndex]];
}

- (GBInfiniteScrollViewPage *)currentPage
{
    return [self pageAtIndex:[self currentPageIndex]];
}

- (GBInfiniteScrollViewPage *)previousPage
{
    return [self pageAtIndex:[self previousPageIndex]];
}

#pragma mark - Visible pages

- (NSUInteger)numberOfVisiblePages
{
    return self.visibleIndices.count;
}

- (NSUInteger)firstVisiblePageIndex
{
    NSNumber *firstVisibleIndex = [self.visibleIndices firstObject];
    return [firstVisibleIndex integerValue];
}

- (NSUInteger)lastVisiblePageIndex
{
    NSNumber *lastVisibleIndex = [self.visibleIndices lastObject];
    return [lastVisibleIndex integerValue];
}

- (NSUInteger)nextVisiblePageIndex
{
    return [self nextIndex:[self lastVisiblePageIndex]];
}

- (NSUInteger)previousVisiblePageIndex
{
    return [self previousIndex:[self firstVisiblePageIndex]];
}

- (GBInfiniteScrollViewPage *)lastVisiblePage
{
    return [self pageAtIndex:[self lastVisiblePageIndex]];
}

- (GBInfiniteScrollViewPage *)firstVisiblePage
{
    return [self pageAtIndex:[self firstVisiblePageIndex]];
}

- (void)addNextVisiblePage:(GBInfiniteScrollViewPage *)page
{
    if (self.debug) {
        NSLog(@"Adding next visible page: %lu", (unsigned long)[self nextVisiblePageIndex]);
    }
    
    [self addLastVisiblePage:page atIndex:[self nextVisiblePageIndex]];
}

- (void)addPreviousVisiblePage:(GBInfiniteScrollViewPage *)page
{
    if (self.debug) {
        NSLog(@"Adding previous visible page: %lu", (unsigned long)[self previousVisiblePageIndex]);
    }
    
    [self addFirstVisiblePage:page atIndex:[self previousVisiblePageIndex]];
}

- (void)addLastVisiblePage:(GBInfiniteScrollViewPage *)page atIndex:(NSUInteger)index
{
    NSUInteger visibleIndex = [self.visibleIndices indexOfObject:[NSNumber numberWithUnsignedInteger:index]];
    
    if (visibleIndex == NSNotFound && page) {
        [self.visibleIndices addObject:[NSNumber numberWithUnsignedInteger:index]];
        [self.visiblePages addObject:page];
        
        if (self.debug) {
            NSLog(@"Visible indices: %@", [self visibleIndicesDescription]);
        }
    }
}

- (void)addFirstVisiblePage:(GBInfiniteScrollViewPage *)page atIndex:(NSUInteger)index
{
    NSUInteger visibleIndex = [self.visibleIndices indexOfObject:[NSNumber numberWithUnsignedInteger:index]];
    
    if (visibleIndex == NSNotFound && page) {
        [self.visibleIndices insertObject:[NSNumber numberWithUnsignedInteger:index] atIndex:0];
        [self.visiblePages insertObject:page atIndex:0.0f];
        
        if (self.debug) {
            NSLog(@"Visible indices: %@", [self visibleIndicesDescription]);
        }
    }
}

- (void)removeFirstVisiblePage
{
    if (self.debug) {
        NSLog(@"Removing first visible page.");
    }
    
    GBInfiniteScrollViewPage *firstVisiblePage = [self firstVisiblePage];
    [firstVisiblePage removeFromSuperview];
    [self.reusablePages addObject:firstVisiblePage];
    [self.visibleIndices removeObjectAtIndex:0];
    [self.visiblePages removeObjectAtIndex:0];
    
    if (self.debug) {
        NSLog(@"Visible indices: %@", [self visibleIndicesDescription]);
    }
}

- (void)removeLastVisiblePage
{
    if (self.debug) {
        NSLog(@"Removing last visible page.");
    }
    
    GBInfiniteScrollViewPage *lastVisiblePage = [self lastVisiblePage];
    [[self lastVisiblePage] removeFromSuperview];
    [self.reusablePages addObject:lastVisiblePage];
    [self.visibleIndices removeLastObject];
    [self.visiblePages removeLastObject];
    
    if (self.debug) {
        NSLog(@"Visible indices: %@", [self visibleIndicesDescription]);
    }
}

- (NSString *)visibleIndicesDescription
{
    NSString *description = @"";
    
    description = [description stringByAppendingString:[self.visibleIndices componentsJoinedByString:@", "]];
    
    return description;
}


#pragma mark - Reusable pages

- (GBInfiniteScrollViewPage *)dequeueReusablePage
{
    GBInfiniteScrollViewPage *page = nil;
    
    page = [self.reusablePages lastObject];
    
    if (page) {
        [self.reusablePages removeLastObject];
        [page prepareForReuse];
    }
    
    return page;
}

#pragma mark - Content offset

- (CGFloat)minContentOffsetX
{
    return [self centerContentOffsetX] - [self distanceFromCenterOffsetX];
}

- (CGFloat)centerContentOffsetX
{
    return [self pageWidth];
}

- (CGFloat)maxContentOffsetX
{
    return [self centerContentOffsetX] + [self distanceFromCenterOffsetX];
}

- (CGFloat)distanceFromCenterOffsetX
{
    return [self pageWidth];
}

- (CGFloat)contentSizeWidth
{
    return [self pageWidth] * 3.0f;
}

#pragma mark - Layout

- (void)reloadData
{
    [self updateCurrentPageIndex];
    [self updateData];
}

- (void)updateData
{
    self.needsReloadData = YES;
    
    [self updateNumberOfPages];
    
    [self.visibleIndices enumerateObjectsUsingBlock:^(GBInfiniteScrollViewPage *visiblePage, NSUInteger idx, BOOL *stop) {
        [self.reusablePages addObject:visiblePage];
        [visiblePage removeFromSuperview];
    }];
    
    [self.visibleIndices removeAllObjects];
    [self.visiblePages removeAllObjects];
    
    [self layoutCurrentView];
}

- (void)resetReusablePages
{
    [self.reusablePages removeAllObjects];
}

- (void)resetVisiblePages
{
    NSUInteger currentPageIndex = [self currentPageIndex];
    GBInfiniteScrollViewPage *currentpage =  [self currentPage];
    
    if (currentpage) {
        if (self.debug) {
            NSLog(@"Reseting visible pages: %@", [self visibleIndicesDescription]);
        }
        
        [self.visibleIndices enumerateObjectsUsingBlock:^(NSNumber *visibleIndex, NSUInteger idx, BOOL *stop) {
            if (self.visiblePages.count>=idx) {
                GBInfiniteScrollViewPage *visiblePage = [self.visiblePages objectAtIndex:idx];
                
                if ([self currentPageIndex] != visibleIndex.integerValue) {
                    [self.reusablePages addObject:visiblePage];
                    [visiblePage removeFromSuperview];
                }
            }
        }];
        
        [self.visibleIndices removeAllObjects];
        [self.visibleIndices addObject:[NSNumber numberWithUnsignedInteger:currentPageIndex]];
        
        [self.visiblePages removeAllObjects];
        [self.visiblePages addObject:currentpage];
        
        if (self.debug) {
            NSLog(@"Visible pages reseted: %@", [self visibleIndicesDescription]);
        }
    }
}

- (void)layoutCurrentView
{
    [self resetContentSize];
    [self centerContentOffset];
    
    GBInfiniteScrollViewPage *page = [self currentPage];
    
    [self placePage:page atPoint:[self centerContentOffsetX]];
    [self addFirstVisiblePage:page atIndex:self.currentPageIndex];
}

- (void)resetContentSize
{
    self.contentSize = CGSizeMake([self contentSizeWidth], self.frame.size.height);
}

- (void)centerContentOffset
{
    self.contentOffset = CGPointMake([self centerContentOffsetX], self.contentOffset.y);
}

- (void)recenterCurrentView
{
    [self centerContentOffset];
    [self movePage:[self currentPage] toPositionX:[self centerContentOffsetX]];
}

- (void)movePage:(GBInfiniteScrollViewPage *)page toPositionX:(CGFloat)positionX
{
    CGRect frame = page.frame;
    frame.origin.x =  positionX;
    page.frame = frame;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if ([self isScrollNecessary]) {
        [self recenterContent];
        
        CGRect visibleBounds = [self bounds];
        CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds);
        CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
        
        // Tile content in visible bounds.
        [self tileViewsFromMinX:minimumVisibleX toMaxX:maximumVisibleX];
    } else {
        [self recenterCurrentView];
        [self updateNumberOfPages];
    }
}

- (void)recenterContent
{
    CGPoint currentContentOffset = [self contentOffset];
    CGFloat distanceFromCenterOffsetX = fabs(currentContentOffset.x - [self centerContentOffsetX]);
    
    if (distanceFromCenterOffsetX == [self distanceFromCenterOffsetX]) {
        if (currentContentOffset.x == [self minContentOffsetX]) {
            [self previous];
            [self didScrollToPreviousPage];
        } else if (currentContentOffset.x == [self maxContentOffsetX]) {
            [self next];
            [self didScrollToNextPage];
        }
        
        [self updateNumberOfPages];
        [self resetVisiblePages];
        [self recenterCurrentView];
        [self setupTimer];
    }
}

#pragma mark - Pages tiling

- (void)placePage:(GBInfiniteScrollViewPage *)page atPoint:(CGFloat)point
{
    CGRect frame = [page frame];
    frame.origin.x = point;
    page.frame = frame;
    
    [self addSubview:page];
}

- (CGFloat)placePage:(GBInfiniteScrollViewPage *)page onRight:(CGFloat)rightEdge
{
    CGRect frame = [page frame];
    frame.origin.x = rightEdge;
    page.frame = frame;
    
    [self addSubview:page];
    [self addNextVisiblePage:page];
    
    return CGRectGetMaxX(frame);
}

- (CGFloat)placePage:(GBInfiniteScrollViewPage *)page onLeft:(CGFloat)leftEdge
{
    CGRect frame = [page frame];
    frame.origin.x = leftEdge - [self pageWidth];
    page.frame = frame;
    
    [self addSubview:page];
    [self addPreviousVisiblePage:page];
    
    return CGRectGetMinX(frame);
}

- (void)tileViewsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX
{
    CGFloat rightEdge = CGRectGetMaxX([self lastVisiblePage].frame);

    // Add views that are missing on right side.
    if (rightEdge < maximumVisibleX) {
        if ([self firstVisiblePageIndex] != [self currentPageIndex]) {
            [self removeFirstVisiblePage];
        }

        if (![self isLastPage] || _shouldScrollingWrapDataSource) [self placePage:[self nextPage] onRight:rightEdge];
    }
    
    CGFloat leftEdge = CGRectGetMinX([self firstVisiblePage].frame);
        
    // Add views that are missing on left side.
    if (leftEdge > minimumVisibleX) {
        if ([self currentPageIndex] != [self lastVisiblePageIndex]) {
            [self removeLastVisiblePage];
        }

        if (![self isFirstPage] || _shouldScrollingWrapDataSource) [self placePage:[self previousPage] onLeft:leftEdge];
    }
}

#pragma mark - Scroll

- (void)stopAutoScroll
{
    self.autoScroll = NO;
    
    if (self.timer) {
        [self.timer invalidate];
    }
}

- (void)startAutoScroll
{
    self.autoScroll = YES;
    
    [self setupTimer];
}

- (void)scrollToNextPage
{
    if ([self isScrollNecessary]) {
        CGRect frame = [self currentPage].frame;
        CGFloat x = CGRectGetMaxX(frame);
        CGFloat y = frame.origin.y;
        CGPoint point = CGPointMake(x, y);
        [self setContentOffset:point animated:YES];
    }
}

- (void)scrollToPreviousPage
{
    if ([self isScrollNecessary]) {
        CGRect frame = [self currentPage].frame;
        CGFloat x = CGRectGetMinX(frame) - [self pageWidth];
        CGFloat y = frame.origin.y;
        CGPoint point = CGPointMake(x, y);
        [self setContentOffset:point animated:YES];
    }
}

- (void)didScrollToNextPage
{
    if (self.infiniteScrollViewDelegate &&
        [self.infiniteScrollViewDelegate respondsToSelector:@selector(infiniteScrollViewDidScrollNextPage:)]) {
        [self.infiniteScrollViewDelegate infiniteScrollViewDidScrollNextPage:self];
    }
}

- (void)didScrollToPreviousPage
{
    if (self.infiniteScrollViewDelegate &&
        [self.infiniteScrollViewDelegate respondsToSelector:@selector(infiniteScrollViewDidScrollPreviousPage:)]) {
        [self.infiniteScrollViewDelegate infiniteScrollViewDidScrollPreviousPage:self];
    }
}

@end
