//
//  RNMetroSplitBundleController.m
//  RNBaseController
//
//  Created by lylaut on 2022/11/11.
//

#import "RNMetroSplitBundleController.h"
#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <React/RCTConvert.h>

#import <React/RCTAppSetupUtils.h>

#import <React/CoreModulesPlugins.h>
#import "RCTCxxBridgeDelegate.h"
#import <React/RCTFabricSurfaceHostingProxyRootView.h>
#import <React/RCTSurfacePresenter.h>
#import <React/RCTSurfacePresenterBridgeAdapter.h>
#import <ReactCommon/RCTTurboModuleManager.h>

#import <react/config/ReactNativeConfig.h>

static NSString *const kRNConcurrentRoot = @"concurrentRoot";

static BOOL _RNMetroSplitBundleManager_enable_split = NO;

@interface RNMetroSplitBundleManager() <RCTCxxBridgeDelegate, RCTTurboModuleManagerDelegate> {
    RCTTurboModuleManager *_turboModuleManager;
    RCTSurfacePresenterBridgeAdapter *_bridgeAdapter;
    std::shared_ptr<const facebook::react::ReactNativeConfig> _reactNativeConfig;
    facebook::react::ContextContainer::Shared _contextContainer;
}

@property (nonatomic, strong) NSURL *baseLocalPath;

@property (nonatomic, strong) RCTBridge *sharedBridge;

@end

@implementation RNMetroSplitBundleManager

static RNMetroSplitBundleManager *manager = nil;

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [super allocWithZone:zone];
    });
    return manager;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return manager;
}

- (nonnull id)mutableCopyWithZone:(nullable NSZone *)zone {
    return manager;
}

- (void)initalManagerWithSplitEnabled:(BOOL)enabled
                       baseBundlePath:(NSURL *)localPath {
    _RNMetroSplitBundleManager_enable_split = enabled;
    _baseLocalPath = localPath;
    
    if (_RNMetroSplitBundleManager_enable_split) {
        _sharedBridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:NULL];
        
        _contextContainer = std::make_shared<facebook::react::ContextContainer const>();
        _reactNativeConfig = std::make_shared<facebook::react::EmptyReactNativeConfig const>();
        _contextContainer->insert("ReactNativeConfig", _reactNativeConfig);
        _bridgeAdapter = [[RCTSurfacePresenterBridgeAdapter alloc] initWithBridge:_sharedBridge contextContainer:_contextContainer];
        _sharedBridge.surfacePresenter = _bridgeAdapter.surfacePresenter;
    }
}

#pragma mark RCTCxxBridgeDelegate
- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge {
    return _baseLocalPath;
}

- (std::unique_ptr<facebook::react::JSExecutorFactory>)jsExecutorFactoryForBridge:(RCTBridge *)bridge {
  _turboModuleManager = [[RCTTurboModuleManager alloc] initWithBridge:bridge
                                                             delegate:self
                                                            jsInvoker:bridge.jsCallInvoker];
  return RCTAppSetupDefaultJsExecutorFactory(bridge, _turboModuleManager);
}

#pragma mark RCTTurboModuleManagerDelegate

- (Class)getModuleClassFromName:(const char *)name {
  return RCTCoreModulesClassProvider(name);
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name
                                                      jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker {
  return nullptr;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name
                                                     initParams:
                                                         (const facebook::react::ObjCTurboModule::InitParams &)params {
  return nullptr;
}

- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)moduleClass {
  return RCTAppSetupDefaultModuleFromClass(moduleClass);
}

@end

@interface RCTBridge (MyCustomerBridge)

- (RCTBridge *)batchedBridge;
- (void)executeSourceCode:(NSData *)sourceCode sync:(BOOL)sync;

@end

@interface RNMetroSplitBundleController()

@property (nonatomic, copy) NSString *moduleName;

@property (nonatomic, copy, readwrite) NSString *uri; // 模块标记

@property (nonatomic, strong, readwrite) NSDictionary *p; // 传入的属性

@property (nonatomic, strong) NSURL *url;

@end

@implementation RNMetroSplitBundleController

- (instancetype)initWithUri:(NSString *)uri url:(NSURL *)url moduleName:(NSString *)moduleName properties:(NSDictionary *)properties {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.uri = uri;
        self.moduleName = moduleName;
        self.url = url;
        self.p = [self privateLoadPropertiesWith:properties];
        
    }
    return self;
}

- (void)setCommonPropertiesWith:(NSMutableDictionary *)properties {
    
}

- (NSMutableDictionary *)privateLoadPropertiesWith:(NSDictionary *)properties {
    NSMutableDictionary *res = nil;
    if ([properties isKindOfClass:[NSMutableDictionary class]]) {
        res = (NSMutableDictionary *)properties;
    } else if ([properties isKindOfClass:[NSDictionary class]]) {
        res = [properties mutableCopy];
    } else {
        res = [NSMutableDictionary dictionary];
    }
    
    // This method controls whether the `concurrentRoot`feature of React18 is turned on or off.
    ///
    /// @see: https://reactjs.org/blog/2022/03/29/react-v18.html
    /// @note: This requires to be rendering on Fabric (i.e. on the New Architecture).
    /// @return: `true` if the `concurrentRoot` feture is enabled. Otherwise, it returns `false`.
    res[kRNConcurrentRoot] = @(YES);
    
    [self setCommonPropertiesWith:res];
    
    return res;
}

- (void)loadView {
    RCTBridge *bridge = [RNMetroSplitBundleManager sharedManager].sharedBridge;
    NSData *data = [NSData dataWithContentsOfURL:self.url];
    [bridge.batchedBridge executeSourceCode:data sync:NO];
    UIView *rootView = RCTAppSetupDefaultRootView(bridge, self.moduleName, self.p, YES);

    if (@available(iOS 13.0, *)) {
      rootView.backgroundColor = [UIColor systemBackgroundColor];
    } else {
      rootView.backgroundColor = [UIColor whiteColor];
    }
    self.view = rootView;
}

@end
