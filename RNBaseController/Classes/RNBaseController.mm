//
//  RNAresViewController.m
//  QMRNAres
//
//  Created by lylaut on 2017/11/3.
//

#import "RNBaseController.h"
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

@interface RNBaseController () <RCTCxxBridgeDelegate, RCTTurboModuleManagerDelegate> {
    RCTTurboModuleManager *_turboModuleManager;
    RCTSurfacePresenterBridgeAdapter *_bridgeAdapter;
    std::shared_ptr<const facebook::react::ReactNativeConfig> _reactNativeConfig;
    facebook::react::ContextContainer::Shared _contextContainer;
}

@property (nonatomic, strong) NSMutableString *resultString;

@property (nonatomic, copy) NSURL *finalUrl;

@property (nonatomic, strong, readwrite) NSDictionary *p;

@property (nonatomic, copy) NSString *uri;

@property (nonatomic, copy) NSString *moduleName;

@property (nonatomic, weak) RCTBridge *bridge;

@property (nonatomic, strong) NSDictionary *launchOptions;

@end

@implementation RNBaseController

#pragma mark - init
- (instancetype)initWithUri:(NSString *)uri url:(NSURL *)url moduleName:(NSString *)moduleName properties:(NSDictionary *)properties useLocal:(BOOL)local {
    if (self = [self initWithNibName:nil bundle:nil]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceLoadSuccess:) name:RCTBridgeDidDownloadScriptNotification object:nil];
        
        self.uri = uri;
        self.moduleName = moduleName;
        self.isSupportScanGun = NO;
        self.finalUrl = local ? [self baseURL] : [self finalUrlWith:url];
        self.p = [self privateLoadPropertiesWith:properties];
        if (local) {
            if (self.p == NULL) {
                self.p = @{@"remote": url};
            } else {
                NSMutableDictionary *copy = self.p.mutableCopy;
                copy[@"remote"] = url;
                self.p = copy;
            }
        }
    }
    return self;
}

- (instancetype)initWitUrl:(NSURL *)url moduleName:(NSString *)moduleName properties:(NSDictionary *)properties launchOptions:(NSDictionary *)launchOptions {
    if (self = [self initWithNibName:nil bundle:nil]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceLoadSuccess:) name:RCTBridgeDidDownloadScriptNotification object:nil];
        
        self.moduleName = moduleName;
        self.finalUrl = [self finalUrlWith:url];
        self.isSupportScanGun = NO;
        self.p = [self privateLoadPropertiesWith:properties];
        self.launchOptions = launchOptions;
    }
    return self;
}

- (NSURL *)baseURL {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ghost.ios" ofType:@"bundle"];
    if (path == NULL) {
        return NULL;
    }
    return [NSURL fileURLWithPath:path];
}

- (NSURL *)finalUrlWith:(NSURL *)url {
    if (!self.needsCache) {
        return url;
    }
    if ([self rnlocalPathExsit:url]) {
        return [self rnlocalPath:url];
    } else {
        
    }
    return url;
}

- (NSURL *)rnlocalPath:(NSURL *)url {
    return NULL;
}

- (BOOL)rnlocalPathExsit:(NSURL *)url {
    return NO;
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

- (void)sourceLoadSuccess:(NSNotification *)notif {
    if ([notif.object isEqual:self.bridge]) {
        RCTSource *source = notif.userInfo[RCTBridgeDidDownloadScriptNotificationSourceKey];
        if ([self.finalUrl.absoluteString hasPrefix:@"http"] && ![self rnlocalPathExsit:self.finalUrl]) {
            NSData *data = source.data;
            if (data && [data isKindOfClass:[NSData class]]) {
                if (self.needsCache && self.loadSourceBlock) {
                    self.loadSourceBlock([data writeToURL:[self rnlocalPath:self.finalUrl] atomically:YES]);
                }
                return;
            }
            self.loadSourceBlock(NO);
        }
    }
}

- (void)loadView {
    RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:self.launchOptions];
    _contextContainer = std::make_shared<facebook::react::ContextContainer const>();
    _reactNativeConfig = std::make_shared<facebook::react::EmptyReactNativeConfig const>();
    _contextContainer->insert("ReactNativeConfig", _reactNativeConfig);
    _bridgeAdapter = [[RCTSurfacePresenterBridgeAdapter alloc] initWithBridge:bridge contextContainer:_contextContainer];
    bridge.surfacePresenter = _bridgeAdapter.surfacePresenter;
    
    UIView *rootView = RCTAppSetupDefaultRootView(bridge, @"AwesomeProject", self.p);

    if (@available(iOS 13.0, *)) {
      rootView.backgroundColor = [UIColor systemBackgroundColor];
    } else {
      rootView.backgroundColor = [UIColor whiteColor];
    }
    self.view = rootView;
    self.bridge = bridge;
}

- (NSMutableString *)resultString {
    if (_resultString == nil) {
        _resultString = [NSMutableString string];
    }
    return _resultString;
}


- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
    if (!self.isSupportScanGun) {
        return [super keyCommands];
    }
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:[UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:0 action:@selector(_handler)]];
    for (int i = 48; i < 58; ++i) {//0..9
        [array addObject:[UIKeyCommand keyCommandWithInput:[NSString stringWithFormat:@"%c", i] modifierFlags:0 action:@selector(commandChanged:)]];
    }
    for (int i = 65; i < 123; ++i) {//A..Za..z
        [array addObject:[UIKeyCommand keyCommandWithInput:[NSString stringWithFormat:@"%c", i] modifierFlags:0 action:@selector(commandChanged:)]];
    }
    return array;
}

- (void)commandChanged:(UIKeyCommand *)command {
    [self.resultString appendString:command.input];
}

- (void)_handler {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"code" object:self.resultString];
    _resultString = nil;
}

- (void)dealloc {
    _p = nil;
    _resultString = nil;
    _uri = nil;
    _finalUrl = nil;
    _resultString = nil;
    _loadSourceBlock = nil;
    _launchOptions = nil;
    _moduleName = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _bridgeAdapter = nil;
    _turboModuleManager = nil;
    _turboModuleManager = nil;
    _contextContainer.reset();
    _reactNativeConfig.reset();
}

#pragma mark RCTCxxBridgeDelegate
- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge {
    if (self.finalUrl == nil) {
        return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
    }
    return self.finalUrl;
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
