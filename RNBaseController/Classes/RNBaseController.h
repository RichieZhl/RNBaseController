//
//  RNAresViewController.h
//  QMRNAres
//
//  Created by lylaut on 2017/11/3.
//

#import <UIKit/UIKit.h>

@interface RNBaseController : UIViewController

@property (nonatomic, assign) BOOL needsCache; // 本地缓存

@property (nonatomic, assign) BOOL isSupportScanGun; // 是否支持扫码枪

@property (nonatomic, copy, readonly) NSString *uri; // 模块标记

@property (nonatomic, strong, readonly) NSDictionary *p; // 传入的属性

@property (nonatomic, copy) void (^loadSourceBlock)(BOOL success); // 远程 js bundle 缓存完毕回调

/// 初始化方法
/// @param uri  模块标记
/// @param url url
/// @param moduleName 模块名
/// @param properties 属性
/// @param local 是否使用本地，差分包使用
- (instancetype)initWithUri:(NSString *)uri url:(NSURL *)url moduleName:(NSString *)moduleName properties:(NSDictionary *)properties useLocal:(BOOL)local;

/// 初始化方法  针对只运行一个RN实例的情形
/// @param url url
/// @param moduleName 模块名
/// @param properties 属性
/// @param launchOptions launchOptions
- (instancetype)initWitUrl:(NSURL *)url moduleName:(NSString *)moduleName properties:(NSDictionary *)properties launchOptions:(NSDictionary *)launchOptions;

///  以下方法需重写实现相关功能

///  固定属性增加
/// @param properties 初始化传入的属性
- (void)setCommonPropertiesWith:(NSMutableDictionary *)properties;

- (NSURL *)baseURL;

/// 本地缓存路径
/// @param url 远程URL
- (NSURL *)rnlocalPath:(NSURL *)url;

/// 本地缓存是否存在
/// @param url 远程URL
- (BOOL)rnlocalPathExsit:(NSURL *)url;

@end
