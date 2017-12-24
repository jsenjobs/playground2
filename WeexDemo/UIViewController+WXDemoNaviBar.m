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

#import "UIViewController+WXDemoNaviBar.h"
#import "WXDefine.h"
#import <objc/runtime.h>

@implementation UIViewController (WXDemoNaviBar)

- (void)setupNaviBar
{
    UIScreenEdgePanGestureRecognizer *edgePanGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(edgePanGesture:)];
    edgePanGestureRecognizer.delegate = self;
    edgePanGestureRecognizer.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:edgePanGestureRecognizer];
    
    NSArray *ver = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    if ([[ver objectAtIndex:0] intValue] >= 7) {
        // iOS 7.0 or later
        self.navigationController.navigationBar.barTintColor = WEEX_COLOR;
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        self.navigationController.navigationBar.translucent = NO;
    }else {
        // iOS 6.1 or earlier
        self.navigationController.navigationBar.tintColor = WEEX_COLOR;
    }
    
    [self.navigationController.navigationBar setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                      [UIColor whiteColor], NSForegroundColorAttributeName, nil]];
    self.navigationItem.title = @"";
}

- (void)edgePanGesture:(UIScreenEdgePanGestureRecognizer*)edgePanGestureRecognizer
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark- UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.navigationController && [self.navigationController.viewControllers count] == 1) {
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark - UIBarButtonItems


- (UIBarButtonItem *)backButtonItem
{
    UIBarButtonItem *backButtonItem = objc_getAssociatedObject(self, _cmd);
    if (!backButtonItem) {
        backButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(backButtonClicked:)];
        objc_setAssociatedObject(self, _cmd, backButtonItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return backButtonItem;
}

#pragma mark -
#pragma mark - UIBarButtonItem actions

- (void)backButtonClicked:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
