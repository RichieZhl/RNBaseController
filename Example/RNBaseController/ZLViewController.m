//
//  ZLViewController.m
//  RNBaseController
//
//  Created by richiezhl on 10/17/2019.
//  Copyright (c) 2019 richiezhl. All rights reserved.
//

#import "ZLViewController.h"
#import "RNBaseController.h"

@interface ZLViewController ()

@end

@implementation ZLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    RNBaseController *viewController = [[RNBaseController alloc] initWithUri:@"main" url:[NSURL URLWithString: @"http://0.0.0.0:8081/index.bundle?platform=ios&dev=true&minify=false"] moduleName:@"AwesomeProject" properties:nil useLocal:NO];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
