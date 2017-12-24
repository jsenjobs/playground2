/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#import "AppDelegate.h"
#import "LoginController.h"
#import "WXBase2ViewController.h"
#import "UIViewController+WXDemoNaviBar.h"
#import "WXEventModule.h"
#import "WXImgLoaderDefaultImpl.h"
#import "SimpleStore.h"
#import "WXNavigationDefault.h"
#import "DemoDefine.h"
#import "WXSyncTestModule.h"
#import "WXExtModule.h"
#import <WeexSDK/WeexSDK.h>
#import <AVFoundation/AVFoundation.h>
#import <ATSDK/ATManager.h>
#import "WXConfigCenterProtocol.h"
#import "WXConfigCenterDefaultImpl.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

#pragma mark
#pragma mark application

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self initWeexSDK];
    
    if([self checkLogin]) {
        self.window.rootViewController = [[WXRootViewController alloc] initWithRootViewController:[self loginController]];
    } else {
        self.window.rootViewController = [[WXRootViewController alloc] initWithRootViewController:[self mainController]];
    }


    [self.window makeKeyAndVisible];
    
    [self startSplashScreen];
    

    return YES;
}
- (BOOL) checkLogin {
    
    
    // NSString *userKey = [[WXUtility globalCache] objectForKey:@"userKey"];
    NSString *userKey = [self getItem:@"userKey"];
    NSString *time = [self getItem:@"time"];
    if(!userKey || !time) {
        return YES;
    }
    NSInteger days = [self getDifferenceByDate:[self dateFromLongLong:[time longLongValue]]];
    
    if(days <= 7) {
        return NO;
    }

    return YES;
    
}
- (NSString*)getItem:(NSString *)key {
    //1.获得NSUserDefaults文件
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    //3.读取文件
    NSString *value = [userDefaults objectForKey:key];
    // BOOL sex = [userDefaults boolForKey:@"sex"];
    // NSInteger age = [userDefaults integerForKey:@"age"];
    return value;
}
- (NSInteger)getDifferenceByDate:(NSDate *)oldDate {
    //获得当前时间
    NSDate *now = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    unsigned int unitFlags = NSCalendarUnitDay;
    NSDateComponents *comps = [gregorian components:unitFlags fromDate:oldDate  toDate:now  options:0];
    return [comps day];
}
-(NSDate*)dateFromLongLong:(long long)msSince1970{
    return [NSDate dateWithTimeIntervalSince1970:msSince1970 / 1000];
}

-(void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
#ifdef UITEST
#if !TARGET_IPHONE_SIMULATOR
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    setenv("GCOV_PREFIX", [documentsDirectory cStringUsingEncoding:NSUTF8StringEncoding], 1);
    setenv("GCOV_PREFIX_STRIP", "6", 1);
#endif
    extern void __gcov_flush(void);
    __gcov_flush();
#endif
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    NSString *newUrlStr = url.absoluteString;
    if([url.scheme isEqualToString:@"wxpage"]) {
        newUrlStr = [newUrlStr stringByReplacingOccurrencesOfString:@"wxpage://" withString:@"http://"];
    }
    UIViewController * viewController = [self loginController];
    ((LoginController*)viewController).url = [NSURL URLWithString:newUrlStr];
    [(WXRootViewController*)self.window.rootViewController pushViewController:viewController animated:YES];
    return YES;
}

#pragma mark weex
- (void)initWeexSDK
{
    [WXAppConfiguration setAppGroup:@"AliApp"];
    [WXAppConfiguration setAppName:@"WeexDemo"];
    [WXAppConfiguration setExternalUserAgent:@"ExternalUA"];
    
    [WXSDKEngine initSDKEnvironment];
    
    [WXSDKEngine registerHandler:[WXImgLoaderDefaultImpl new] withProtocol:@protocol(WXImgLoaderProtocol)];
        [WXSDKEngine registerHandler:[WXNavigationDefault new] withProtocol:@protocol(WXNavigationProtocol)];
    // [WXSDKEngine registerHandler:[WXEventModule new] withProtocol:@protocol(WXEventModuleProtocol)];
    // [WXSDKEngine registerHandler:[WXConfigCenterDefaultImpl new] withProtocol:@protocol(WXConfigCenterProtocol)];

    
    [WXSDKEngine registerComponent:@"select" withClass:NSClassFromString(@"WXSelectComponent")];
    [WXSDKEngine registerModule:@"event" withClass:[WXEventModule class]];
    [WXSDKEngine registerModule:@"syncTest" withClass:[WXSyncTestModule class]];
    [WXSDKEngine registerModule:@"simpleStore" withClass:[SimpleStore class]];
    // [WXSDKEngine registerExtendCallNative:@"test" withClass:NSClassFromString(@"WXExtendCallNativeTest")];
    [WXSDKEngine registerModule:@"ext" withClass:[WXExtModule class]];

}

- (UIViewController *)loginController
{
    UIViewController *demo = [[LoginController alloc] init];

#if DEBUG
    //If you are debugging in device , please change the host to current IP of your computer.
    ((LoginController *)demo).url = [NSURL URLWithString:HOME_URL];
#else
    ((LoginController *)demo).url = [NSURL URLWithString:BUNDLE_URL];
#endif
    return demo;
}
- (UIViewController *)mainController
{
    
#if DEBUG
    //If you are debugging in device , please change the host to current IP of your computer.
    NSLog(@"KKKK%@", HOME_URL_MAIN);
    return [[WXBase2ViewController alloc]initWithSourceURL:[NSURL URLWithString:HOME_URL_MAIN]];
#else
    return [[WXBase2ViewController alloc]initWithSourceURL:[NSURL URLWithString:BUNDLE_URL_MAIN]];
#endif
}

#pragma mark 
#pragma mark animation when startup

- (void)startSplashScreen
{
    UIView* splashView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    splashView.backgroundColor = WEEX_COLOR;
    
    UIImageView *iconImageView = [UIImageView new];
    UIImage *icon = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"weex-icon" ofType:@"png"]];
    if ([icon respondsToSelector:@selector(imageWithRenderingMode:)]) {
        iconImageView.image = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        iconImageView.tintColor = [UIColor whiteColor];
    } else {
        iconImageView.image = icon;
    }
    iconImageView.frame = CGRectMake(0, 0, 320, 320);
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    iconImageView.center = splashView.center;
    [splashView addSubview:iconImageView];
    
    [self.window addSubview:splashView];
    
    float animationDuration = 1.4;
    CGFloat shrinkDuration = animationDuration * 0.3;
    CGFloat growDuration = animationDuration * 0.7;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        [UIView animateWithDuration:shrinkDuration delay:1.0 usingSpringWithDamping:0.7f initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGAffineTransform scaleTransform = CGAffineTransformMakeScale(0.75, 0.75);
            iconImageView.transform = scaleTransform;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:growDuration animations:^{
                CGAffineTransform scaleTransform = CGAffineTransformMakeScale(20, 20);
                iconImageView.transform = scaleTransform;
                splashView.alpha = 0;
            } completion:^(BOOL finished) {
                [splashView removeFromSuperview];
            }];
        }];
    } else {
        [UIView animateWithDuration:shrinkDuration delay:1.0 options:0 animations:^{
            CGAffineTransform scaleTransform = CGAffineTransformMakeScale(0.75, 0.75);
            iconImageView.transform = scaleTransform;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:growDuration animations:^{
                CGAffineTransform scaleTransform = CGAffineTransformMakeScale(20, 20);
                iconImageView.transform = scaleTransform;
                splashView.alpha = 0;
            } completion:^(BOOL finished) {
                [splashView removeFromSuperview];
            }];
        }];
    }
}
@end
