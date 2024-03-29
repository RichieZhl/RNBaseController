//
//  RNAresViewController.m
//  QMRNAres
//
//  Created by lylaut on 2017/11/3.
//

#import "RNBaseController.h"
#import <CommonCrypto/CommonDigest.h>
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
#import <zlib.h>

@interface NSData (gzip)

- (nullable NSData *)gzippedDataWithCompressionLevel:(float)level;

- (nullable NSData *)gzippedData;

- (nullable NSData *)gunzippedData;

- (BOOL)isGzippedData;

@end

@implementation NSData (gzip)

- (NSData *)gzippedDataWithCompressionLevel:(float)level {
    if (self.length == 0 || [self isGzippedData]) {
        return self;
    }

    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.opaque = Z_NULL;
    stream.avail_in = (uint)self.length;
    stream.next_in = (Bytef *)(void *)self.bytes;
    stream.total_out = 0;
    stream.avail_out = 0;

    static const NSUInteger ChunkSize = 16384;

    NSMutableData *output = nil;
    int compression = (level < 0.0f)? Z_DEFAULT_COMPRESSION: (int)(roundf(level * 9));
    if (deflateInit2(&stream, compression, Z_DEFLATED, 31, 8, Z_DEFAULT_STRATEGY) == Z_OK) {
        output = [NSMutableData dataWithLength:ChunkSize];
        while (stream.avail_out == 0) {
            if (stream.total_out >= output.length) {
                output.length += ChunkSize;
            }
            stream.next_out = (uint8_t *)output.mutableBytes + stream.total_out;
            stream.avail_out = (uInt)(output.length - stream.total_out);
            deflate(&stream, Z_FINISH);
        }
        deflateEnd(&stream);
        output.length = stream.total_out;
    }

    return output;
}

- (NSData *)gzippedData {
    return [self gzippedDataWithCompressionLevel:-1.0f];
}

- (NSData *)gunzippedData {
    if (self.length == 0 || ![self isGzippedData]) {
        return self;
    }

    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.avail_in = (uint)self.length;
    stream.next_in = (Bytef *)self.bytes;
    stream.total_out = 0;
    stream.avail_out = 0;

    NSMutableData *output = nil;
    if (inflateInit2(&stream, 47) == Z_OK) {
        int status = Z_OK;
        output = [NSMutableData dataWithCapacity:self.length * 2];
        while (status == Z_OK) {
            if (stream.total_out >= output.length) {
                output.length += self.length / 2;
            }
            stream.next_out = (uint8_t *)output.mutableBytes + stream.total_out;
            stream.avail_out = (uInt)(output.length - stream.total_out);
            status = inflate (&stream, Z_SYNC_FLUSH);
        }
        if (inflateEnd(&stream) == Z_OK) {
            if (status == Z_STREAM_END) {
                output.length = stream.total_out;
            }
        }
    }

    return output;
}

- (BOOL)isGzippedData {
    const UInt8 *bytes = (const UInt8 *)self.bytes;
    return (self.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b);
}

@end

static NSString *const kRNConcurrentRoot = @"concurrentRoot";

static inline NSString *getMd5Str(NSString *str) {
    //传入参数,转化成char
    const char *cStr = [str UTF8String];
    //开辟一个16字节的空间
    unsigned char result[16];
    /*
     extern unsigned char * CC_MD5(const void *data, CC_LONG len, unsigned char *md)官方封装好的加密方法
     把str字符串转换成了32位的16进制数列（这个过程不可逆转） 存储到了md这个空间中
     */
    CC_MD5(cStr, (unsigned)strlen(cStr), result);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
             result[0], result[1], result[2], result[3],
             result[4], result[5], result[6], result[7],
             result[8], result[9], result[10], result[11],
             result[12], result[13], result[14], result[15]
             ];
}

@interface RNBaseController () <RCTCxxBridgeDelegate, RCTTurboModuleManagerDelegate> {
    RCTTurboModuleManager *_turboModuleManager;
    RCTSurfacePresenterBridgeAdapter *_bridgeAdapter;
    std::shared_ptr<const facebook::react::ReactNativeConfig> _reactNativeConfig;
    facebook::react::ContextContainer::Shared _contextContainer;
    
    BOOL asyncDownload;
}

@property (nonatomic, strong) NSMutableString *resultString;

@property (nonatomic, copy) NSURL *finalUrl;

@property (nonatomic, strong, readwrite) NSDictionary *p;

@property (nonatomic, copy) NSString *uri;

@property (nonatomic, copy) NSString *moduleName;

@property (nonatomic, weak) RCTBridge *bridge;

@property (nonatomic, strong) NSDictionary *launchOptions;

@end

static NSString *rnbundleDir;

@implementation RNBaseController

+ (void)initialize {
    rnbundleDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"rnbundle"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fileManager fileExistsAtPath:rnbundleDir isDirectory:&isDir] || !isDir) {
        NSError *createError = nil;
        [fileManager createDirectoryAtPath:rnbundleDir withIntermediateDirectories:YES attributes:nil error:&createError];
        if (createError != nil) {
            createError = nil;
            [fileManager createDirectoryAtPath:rnbundleDir withIntermediateDirectories:YES attributes:nil error:&createError];
            if (createError != nil) {
                abort();
            }
        }
    }
}

#pragma mark - init
- (instancetype)initWithUri:(NSString *)uri url:(NSURL *)url moduleName:(NSString *)moduleName properties:(NSDictionary *)properties launchOptions:(NSDictionary *)launchOptions {
    if (self = [super initWithNibName:nil bundle:nil]) {
        asyncDownload = NO;
        self.uri = uri;
        self.moduleName = moduleName;
        self.launchOptions = launchOptions;
        self.isSupportScanGun = NO;
        [self finalUrlWith:url];
        self.p = [self privateLoadPropertiesWith:properties];
    }
    return self;
}

- (NSData *)handleDownloadedData:(NSData *)data {
    return [data gunzippedData];
}

- (void)finalUrlWith:(NSURL *)url {
    if ([url.absoluteString containsString:@":8081"]) {
        self.finalUrl = url;
        return;
    }
    if ([self rnlocalPathExsit:url]) {
        [self rnlocalPath:url];
    } else {
        asyncDownload = YES;
        [self rnlocalPath:url];
        [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error != nil || data == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self handleDownloadError];
                });
                return;
            }
            
            NSData *resultD = [self handleDownloadedData:data];
            if (resultD == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self handleDownloadError];
                });
                return;
            }
            if (![resultD writeToURL:self.finalUrl atomically:YES]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self handleDownloadError];
                });
                return;
            }
            
            if (self.loadSourceBlock != nil) {
                self.loadSourceBlock(YES);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loadRootView];
            });
        }] resume];
    }
}

- (UIView *)downloadAnimationView {
    return nil;
}

- (void)handleDownloadError {
    
}

- (void)rnlocalPath:(NSURL *)url {
    NSString *bundlePath = [rnbundleDir stringByAppendingFormat:@"/%@.bundle", getMd5Str(url.absoluteString)];
    self.finalUrl = [NSURL fileURLWithPath:bundlePath];
}

- (BOOL)rnlocalPathExsit:(NSURL *)url {
    NSString *bundlePath = [rnbundleDir stringByAppendingFormat:@"/%@.bundle", getMd5Str(url.absoluteString)];
    return [[NSFileManager defaultManager] fileExistsAtPath:bundlePath];
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
    if (!asyncDownload) {
        [self loadRootView];
        return;
    }
    
    [super loadView];
    
    UIView *v = [self downloadAnimationView];
    if (v != nil) {
        [self.view addSubview:v];
    }
}

- (void)loadRootView {
    RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:self.launchOptions];
    _contextContainer = std::make_shared<facebook::react::ContextContainer const>();
    _reactNativeConfig = std::make_shared<facebook::react::EmptyReactNativeConfig const>();
    _contextContainer->insert("ReactNativeConfig", _reactNativeConfig);
    _bridgeAdapter = [[RCTSurfacePresenterBridgeAdapter alloc] initWithBridge:bridge contextContainer:_contextContainer];
    bridge.surfacePresenter = _bridgeAdapter.surfacePresenter;
    
    UIView *rootView = RCTAppSetupDefaultRootView(bridge, self.moduleName, self.p, YES);

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
    _launchOptions = nil;
    _moduleName = nil;
    
    _contextContainer.reset();
    _reactNativeConfig.reset();
    _turboModuleManager = nil;
    _bridgeAdapter = nil;
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
