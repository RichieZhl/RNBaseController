//
//  RNAres.m
//  rn70
//
//  Created by lylaut on 2022/9/9.
//

#import "RNAres.h"

// 处理原生成功时返回给RN的数据封装
///
/// - Parameter data: 要处理的数据
/// - Returns: RN结构的数据
NSArray *convertSuccessResponseData(id data) {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
    [array addObject:[NSNull null]];
    [array addObject:data];
    return [array copy];
}

NSDictionary *convertPromiseSuccessResponseData(id data) {
    NSMutableDictionary *res = [NSMutableDictionary dictionaryWithObjectsAndKeys:@1, @"status", @"success", @"message", nil];
    if (data) {
        res[@"data"] = data;
    }
    return [res copy];
}

@interface RNAres ()

@end

@implementation RNAres

RCT_EXPORT_MODULE(extra)

/// 关闭当前RN控制器
RCT_EXPORT_METHOD(close) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    });
}

RCT_EXPORT_METHOD(test: (NSDictionary *)dics resolver:(RCTPromiseResolveBlock)resolve
rejecter:(RCTPromiseRejectBlock)reject) {
    NSDictionary *data = [RCTConvert NSDictionary:dics];
    NSLog(@"%@", data);
    resolve(convertPromiseSuccessResponseData(@{@"granted": @(YES)}));
}

@end
