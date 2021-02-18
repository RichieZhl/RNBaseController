//
//  RNAresViewController.m
//  QMRNAres
//
//  Created by lylaut on 2017/11/3.
//

#import "RNBaseController.h"
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <React/RCTConvert.h>

@interface RNBaseController ()

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:@"RCTJavaScriptDidFailToLoadNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceLoadSuccess:) name:RCTBridgeDidDownloadScriptNotification object:nil];
        
        self.uri = uri;
        self.moduleName = moduleName;
        self.isSupportScanGun = NO;
        self.finalUrl = local ? [self baseURL] : [self finalUrlWith:url];
        self.p = [self loadPropertiesWith:properties];
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:@"RCTJavaScriptDidFailToLoadNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceLoadSuccess:) name:RCTBridgeDidDownloadScriptNotification object:nil];
        
        self.moduleName = moduleName;
        self.finalUrl = [self finalUrlWith:url];
        self.isSupportScanGun = NO;
        self.p = [self loadPropertiesWith:properties];
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

- (void)handleNotification:(NSNotification *)notif {
    if ([NSThread isMainThread]) {
        [self hideLoadingView];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideLoadingView];
        });
    }
}

- (void)hideLoadingView {
    
}

- (NSDictionary *)loadPropertiesWith:(NSDictionary *)properties {
    return properties;
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

- (UIView *)rctLoadingView {
    return nil;
}

- (void)loadView {
    RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:self.finalUrl moduleName:self.moduleName initialProperties:self.p launchOptions:self.launchOptions];
    rootView.loadingView = [self rctLoadingView];
    self.view = rootView;
    self.bridge = rootView.bridge;
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
}

@end
