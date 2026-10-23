#if TARGET_OS_TV
#import <React/RCTViewManager.h>
#import <React/RCTTVView.h>
#import <React/UIView+React.h>

// UIKit owns the focus appearance, accessibility and selection of the tab items.
@interface OrionTVTabBarView : RCTTVView <UITabBarDelegate>
@property(nonatomic, strong) UITabBar *bar;
@property(nonatomic) NSInteger selectedIndex;
@property(nonatomic, copy) RCTDirectEventBlock onTabSelect;
@property(nonatomic, copy) RCTDirectEventBlock onControlFocus;
@end
@implementation OrionTVTabBarView
- (instancetype)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    self.isTVSelectable = NO;
    _bar = [UITabBar new];
    _bar.delegate = self;
    NSArray *titles = @[@"现在观看", @"资料库", @"搜索", @"直播", @"设置"];
    NSMutableArray *items = [NSMutableArray new];
    for (NSInteger i = 0; i < titles.count; i++) {
      UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:titles[i] image:nil tag:i];
      item.accessibilityLabel = titles[i];
      [items addObject:item];
    }
    _bar.items = items;
    _bar.selectedItem = items.firstObject;
    [self addSubview:_bar];
    [self setFocusDestinations:@[_bar]];
  }
  return self;
}
- (void)layoutSubviews { [super layoutSubviews]; self.bar.frame = self.bounds; }
- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments { return @[self.bar]; }
- (void)setSelectedIndex:(NSInteger)index {
  _selectedIndex = MAX(0, MIN(index, (NSInteger)self.bar.items.count - 1));
  self.bar.selectedItem = self.bar.items[_selectedIndex];
}
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
  _selectedIndex = item.tag;
  if (self.onTabSelect) self.onTabSelect(@{@"index": @(item.tag)});
}
- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
  [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
  if ([context.nextFocusedView isDescendantOfView:self] && self.onControlFocus) self.onControlFocus(@{});
}
@end
@interface OrionTVTabBarManager : RCTViewManager @end
@implementation OrionTVTabBarManager
RCT_EXPORT_MODULE(OrionTVTabBar)
- (UIView *)view { return [OrionTVTabBarView new]; }
RCT_EXPORT_VIEW_PROPERTY(selectedIndex, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(onTabSelect, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onControlFocus, RCTDirectEventBlock)
@end

// A single-level system menu replaces persistent rows of category/filter tabs.
@interface OrionTVMenuView : RCTTVView
@property(nonatomic, strong) UIButton *button;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSArray<NSString *> *options;
@property(nonatomic) NSInteger selectedIndex;
@property(nonatomic, copy) RCTDirectEventBlock onSelect;
@property(nonatomic, copy) RCTDirectEventBlock onControlFocus;
@end
@implementation OrionTVMenuView
- (instancetype)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    self.isTVSelectable = NO;
    _button = [UIButton buttonWithType:UIButtonTypeSystem];
    [_button addTarget:self action:@selector(showLegacyMenu) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self addSubview:_button];
    [self setFocusDestinations:@[_button]];
  }
  return self;
}
- (void)layoutSubviews { [super layoutSubviews]; self.button.frame = self.bounds; }
- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments { return @[self.button]; }
- (void)setTitle:(NSString *)title { _title = [title copy]; [self rebuildMenu]; }
- (void)setOptions:(NSArray<NSString *> *)options { _options = [options copy]; [self rebuildMenu]; }
- (void)setSelectedIndex:(NSInteger)index { _selectedIndex = index; [self rebuildMenu]; }
- (void)choose:(NSInteger)index {
  if (index >= 0 && index < self.options.count && self.onSelect) self.onSelect(@{@"index": @(index)});
}
- (void)rebuildMenu {
  [self.button setTitle:[NSString stringWithFormat:@"%@ ▾", self.title ?: @""] forState:UIControlStateNormal];
  self.button.accessibilityLabel = self.title;
  if (@available(tvOS 17.0, *)) {
    __weak OrionTVMenuView *weakSelf = self;
    NSMutableArray<UIMenuElement *> *actions = [NSMutableArray new];
    [self.options enumerateObjectsUsingBlock:^(NSString *option, NSUInteger index, BOOL *stop) {
      UIAction *action = [UIAction actionWithTitle:option image:nil identifier:nil handler:^(__kindof UIAction *action) { [weakSelf choose:index]; }];
      action.state = (index == self.selectedIndex) ? UIMenuElementStateOn : UIMenuElementStateOff;
      [actions addObject:action];
    }];
    self.button.menu = [UIMenu menuWithTitle:@"" children:actions];
    self.button.showsMenuAsPrimaryAction = YES;
  }
}
- (void)showLegacyMenu {
  if (@available(tvOS 17.0, *)) return;
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
  __weak OrionTVMenuView *weakSelf = self;
  [self.options enumerateObjectsUsingBlock:^(NSString *option, NSUInteger index, BOOL *stop) {
    [alert addAction:[UIAlertAction actionWithTitle:option style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [weakSelf choose:index]; }]];
  }];
  [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
  [self.reactViewController presentViewController:alert animated:YES completion:nil];
}
- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
  [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
  if ([context.nextFocusedView isDescendantOfView:self] && self.onControlFocus) self.onControlFocus(@{});
}
@end
@interface OrionTVMenuManager : RCTViewManager @end
@implementation OrionTVMenuManager
RCT_EXPORT_MODULE(OrionTVMenu)
- (UIView *)view { return [OrionTVMenuView new]; }
RCT_EXPORT_VIEW_PROPERTY(title, NSString)
RCT_EXPORT_VIEW_PROPERTY(options, NSArray)
RCT_EXPORT_VIEW_PROPERTY(selectedIndex, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(onSelect, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onControlFocus, RCTDirectEventBlock)
@end
#endif
