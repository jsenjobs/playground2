//
//  SimpleStore.m
//  WeexDemo
//
//  Created by jsen on 2017/12/24.
//  Copyright © 2017年 taobao. All rights reserved.
//

#import "SimpleStore.h"

@implementation SimpleStore

WX_EXPORT_METHOD(@selector(setItem:value:callback:))
WX_EXPORT_METHOD(@selector(getItem:callback:))
WX_EXPORT_METHOD(@selector(removeItem:callback:))

- (void)setItem:(NSString *)key value:(NSString *)value callback:(WXModuleCallback)callback
{
    
    if(! key || !value) {
        if(callback) {
            callback(@{@"result":@"failed",@"data":@"key or value must a string!"}); // forgive my english
        }
        return;
    }
    //1.获得NSUserDefaults文件
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    //2.向文件中写入内容
    [userDefaults setObject:value forKey:key];
    // [userDefaults setBool:YES forKey:@"sex"];
    // [userDefaults setInteger:21 forKey:@"age"];
    //2.1立即同步
    [userDefaults synchronize];
    if (callback) {
        callback(@{@"result":@"success"});
    }
}
- (void)getItem:(NSString *)key callback:(WXModuleCallback)callback
{
    if(!key) {
        if(callback) {
            callback(@{@"result":@"failed",@"data":@"key must a string!"}); // forgive my english
        }
        return;
    }
    //1.获得NSUserDefaults文件
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    //3.读取文件
    NSString *value = [userDefaults objectForKey:key];
    // BOOL sex = [userDefaults boolForKey:@"sex"];
    // NSInteger age = [userDefaults integerForKey:@"age"];
    
    if(callback) {
        callback(@{@"result":@"success",@"data":value});
    }
    
}
- (void)removeItem:(NSString *)key callback:(WXModuleCallback)callback {
    if(!key) {
        if(callback) {
            callback(@{@"result":@"failed",@"data":@"key must a string!"}); // forgive my english
        }
        return;
    }
    //1.获得NSUserDefaults文件
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults removeObjectForKey:key];
    
    if(callback) {
        callback(@{@"result":@"success"});
    }
    
}
@end
