//
//  ViewController.m
//  NetworkWatchDog
//
//  Created by Topband on 2018/3/19.
//  Copyright © 2018年 Ramon. All rights reserved.
//

#import "ViewController.h"
#import "RFNetworkWatchDog.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[RFNetworkWatchDog shareInstance] openWatchDog];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
