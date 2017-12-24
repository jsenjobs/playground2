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

#import "WXBase2ViewController.h"
#import "UIViewController+WXDemoNaviBar.h"

@interface WXBase2ViewController ()

@property (nonatomic, strong) WXSDKInstance *instance;
@property (nonatomic, strong) UIView *weexView;
@property (nonatomic, strong) NSURL *sourceURL;
@property (nonatomic, assign) CGFloat weexHeight;

@end

@implementation WXBase2ViewController

- (void)dealloc
{
    [_instance destroyInstance];
    [self _removeObservers];
}

- (instancetype)initWithSourceURL:(NSURL *)sourceURL
{
    if ((self = [super init])) {
        self.sourceURL = sourceURL;
        self.hidesBottomBarWhenPushed = YES;
        
        [self _addObservers];
    }
    return self;
}

//TODO get height
- (void)viewDidLayoutSubviews
{
    _weexHeight = self.view.frame.size.height;
    UIEdgeInsets safeArea = UIEdgeInsetsZero;
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        safeArea = self.view.safeAreaInsets;
    } else {
        // Fallback on earlier versions
    }
#endif
    _instance.frame = CGRectMake(safeArea.left, safeArea.top, self.view.frame.size.width-safeArea.left-safeArea.right, _weexHeight-safeArea.bottom);
}


/**
 *  We assume that the initial state of viewController's navigtionBar is hidden.  By setting the attribute of
 *  'dataRole' equal to 'navbar', the navigationBar hidden will be NO.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupNaviBar];

    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self _renderWithURL:_sourceURL];
    if ([self.navigationController isKindOfClass:[WXRootViewController class]]) {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self _updateInstanceState:WeexInstanceAppear];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self _updateInstanceState:WeexInstanceDisappear];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self _updateInstanceState:WeexInstanceMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshWeex
{
    [self _renderWithURL:_sourceURL];
}


- (void)addEdgePop
{
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)_renderWithURL:(NSURL *)sourceURL
{
    if (!sourceURL) {
        return;
    }
    
    [_instance destroyInstance];
    if([WXPrerenderManager isTaskReady:[self.sourceURL absoluteString]]){
        _instance = [WXPrerenderManager instanceFromUrl:self.sourceURL.absoluteString];
    }
    
    _instance = [[WXSDKInstance alloc] init];
    // _instance.frame = CGRectMake(0.0f, 0.0f, self.view.bounds.size.width,
    //                              self.view.bounds.size.height);
    
    
    CGFloat width = self.view.frame.size.width;
    UIEdgeInsets safeArea = UIEdgeInsetsZero;
    
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        safeArea = self.view.safeAreaInsets;
    } else {
        // Fallback on earlier versions
    }
#endif
    _instance.frame = CGRectMake(self.view.frame.size.width-width, 0, width, _weexHeight-safeArea.bottom);

    _instance.pageObject = self;
    _instance.pageName = sourceURL.absoluteString;
    _instance.viewController = self;
    
    NSString *newURL = nil;
    
    if ([sourceURL.absoluteString rangeOfString:@"?"].location != NSNotFound) {
        newURL = [NSString stringWithFormat:@"%@&random=%d", sourceURL.absoluteString, arc4random()];
    } else {
        newURL = [NSString stringWithFormat:@"%@?random=%d", sourceURL.absoluteString, arc4random()];
    }
    [_instance renderWithURL:[NSURL URLWithString:newURL] options:@{@"bundleUrl":sourceURL.absoluteString} data:nil];
    
    __weak typeof(self) weakSelf = self;
    _instance.onCreate = ^(UIView *view) {
        [weakSelf.weexView removeFromSuperview];
        weakSelf.weexView = view;
        [weakSelf.view addSubview:weakSelf.weexView];
    };
    
    _instance.onFailed = ^(NSError *error) {
        
    };
    
    _instance.renderFinish = ^(UIView *view) {
        [weakSelf _updateInstanceState:WeexInstanceAppear];
    };
    
    if([WXPrerenderManager isTaskReady:[self.sourceURL absoluteString]]){
        WX_MONITOR_INSTANCE_PERF_START(WXPTJSDownload, _instance);
        WX_MONITOR_INSTANCE_PERF_END(WXPTJSDownload, _instance);
        WX_MONITOR_INSTANCE_PERF_START(WXPTFirstScreenRender, _instance);
        WX_MONITOR_INSTANCE_PERF_START(WXPTAllRender, _instance);
        [WXPrerenderManager renderFromCache:[self.sourceURL absoluteString]];
        return;
    }
}

- (void)_updateInstanceState:(WXState)state
{
    if (_instance && _instance.state != state) {
        _instance.state = state;
        
        if (state == WeexInstanceAppear) {
            [[WXSDKManager bridgeMgr] fireEvent:_instance.instanceId ref:WX_SDK_ROOT_REF type:@"viewappear" params:nil domChanges:nil];
        } else if (state == WeexInstanceDisappear) {
            [[WXSDKManager bridgeMgr] fireEvent:_instance.instanceId ref:WX_SDK_ROOT_REF type:@"viewdisappear" params:nil domChanges:nil];
        }
    }
}

- (void)_appStateDidChange:(NSNotification *)notify
{
    if ([notify.name isEqualToString:@"UIApplicationDidBecomeActiveNotification"]) {
        [self _updateInstanceState:WeexInstanceForeground];
    } else if([notify.name isEqualToString:@"UIApplicationDidEnterBackgroundNotification"]) {
        [self _updateInstanceState:WeexInstanceBackground]; ;
    }
}

- (void)_addObservers
{
    for (NSString *name in @[UIApplicationDidBecomeActiveNotification,
                             UIApplicationDidEnterBackgroundNotification]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_appStateDidChange:)
                                                     name:name
                                                   object:nil];
    }
}

- (void)_removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

