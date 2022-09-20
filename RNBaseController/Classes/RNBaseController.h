//
//  RNAresViewController.h
//  QMRNAres
//
//  Created by lylaut on 2017/11/3.
//

#import <UIKit/UIKit.h>

@interface RNBaseController : UIViewController

@property (nonatomic, assign) BOOL isSupportScanGun; // 是否支持扫码枪

@property (nonatomic, copy, readonly) NSString *uri; // 模块标记

@property (nonatomic, strong, readonly) NSDictionary *p; // 传入的属性

/// 初始化方法
/// @param uri  模块标记
/// @param url url
/// @param moduleName 模块名
/// @param properties 属性
/// @param launchOptions launchOptions
- (instancetype)initWithUri:(NSString *)uri url:(NSURL *)url moduleName:(NSString *)moduleName properties:(NSDictionary *)properties launchOptions:(NSDictionary *)launchOptions;

///  以下方法需重写实现相关功能

///  固定属性增加
/// @param properties 初始化传入的属性
- (void)setCommonPropertiesWith:(NSMutableDictionary *)properties;

/// 下载时动画视图
- (UIView *)downloadAnimationView;

/// 处理下载失败的情形
- (void)handleDownloadError;

@end
