//
//  RNMetroSplitBundleController.h
//  RNBaseController
//
//  Created by lylaut on 2022/11/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RNMetroSplitBundleManager : NSObject

+ (instancetype)sharedManager;

+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)init NS_UNAVAILABLE;

- (void)initalManagerWithSplitEnabled:(BOOL)enabled
                       baseBundlePath:(NSURL *)localPath;

@end


@interface RNMetroSplitBundleController : UIViewController

@property (nonatomic, assign) BOOL isSupportScanGun; // 是否支持扫码枪

@property (nonatomic, copy, readonly) NSString *uri; // 模块标记

@property (nonatomic, strong, readonly) NSDictionary *p; // 传入的属性

- (instancetype)initWithUri:(NSString *)uri url:(NSURL *)url moduleName:(NSString *)moduleName properties:(nullable NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
