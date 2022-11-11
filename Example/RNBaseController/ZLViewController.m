//
//  ZLViewController.m
//  RNBaseController
//
//  Created by richiezhl on 10/17/2019.
//  Copyright (c) 2019 richiezhl. All rights reserved.
//

#import "ZLViewController.h"
#import "RNBaseController.h"
#import "RNMetroSplitBundleController.h"

@interface ZLViewController ()

@end

@implementation ZLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
//    RNBaseController *viewController = [[RNBaseController alloc] initWithUri:@"main" url:[NSURL URLWithString: @"http://0.0.0.0:8081/index.bundle?platform=ios&dev=true&minify=false"] moduleName:@"AwesomeProject" properties:nil launchOptions:nil];
//    viewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
//    [self presentViewController:viewController animated:YES completion:nil];
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"business.ios" ofType:@".bundle"];
    RNMetroSplitBundleController *cvt = [[RNMetroSplitBundleController alloc] initWithUri:@"main" url:[NSURL fileURLWithPath:filepath] moduleName:@"AwesomeProject" properties:nil];
    cvt.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:cvt animated:YES completion:nil];
}

@end
