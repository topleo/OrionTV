// tvOS 27 requires scene lifecycle adoption for apps linked with the new SDK.
// Keep the Expo/RN-created root window and attach it to the UIKit scene.
@interface OrionTVSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation OrionTVSceneDelegate
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions
{
  if (![scene isKindOfClass:[UIWindowScene class]]) return;
  AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
  self.window = appDelegate.window;
  self.window.windowScene = (UIWindowScene *)scene;
  [self.window makeKeyAndVisible];
  for (UIOpenURLContext *context in connectionOptions.URLContexts) {
    [appDelegate application:UIApplication.sharedApplication openURL:context.URL options:@{}];
  }
}
- (void)sceneDidBecomeActive:(UIScene *)scene
{
  id delegate = UIApplication.sharedApplication.delegate;
  if ([delegate respondsToSelector:@selector(applicationDidBecomeActive:)]) [delegate applicationDidBecomeActive:UIApplication.sharedApplication];
}
- (void)sceneWillResignActive:(UIScene *)scene
{
  id delegate = UIApplication.sharedApplication.delegate;
  if ([delegate respondsToSelector:@selector(applicationWillResignActive:)]) [delegate applicationWillResignActive:UIApplication.sharedApplication];
}
- (void)sceneWillEnterForeground:(UIScene *)scene
{
  id delegate = UIApplication.sharedApplication.delegate;
  if ([delegate respondsToSelector:@selector(applicationWillEnterForeground:)]) [delegate applicationWillEnterForeground:UIApplication.sharedApplication];
}
- (void)sceneDidEnterBackground:(UIScene *)scene
{
  id delegate = UIApplication.sharedApplication.delegate;
  if ([delegate respondsToSelector:@selector(applicationDidEnterBackground:)]) [delegate applicationDidEnterBackground:UIApplication.sharedApplication];
}
- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts
{
  for (UIOpenURLContext *context in URLContexts) {
    [(AppDelegate *)UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication openURL:context.URL options:@{}];
  }
}
@end
