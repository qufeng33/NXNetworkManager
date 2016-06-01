//
//  ViewController.m
//  NXNetworkManagerDemo
//
//  Created by 蒋瞿风 on 16/6/1.
//  Copyright © 2016年 nightx. All rights reserved.
//

#import "ViewController.h"
#import "NXNetworkManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NXNetworkManager sharedManager] updateBaseUrl:@"https://www.v2ex.com"];
    
    [[NXNetworkManager sharedManager] getWithPath:@"/api/topics/latest.json" params:nil completeBlock:^(BOOL success, NSURLSessionTask * _Nonnull task, id  _Nullable responseObject, NSError * _Nullable error, NSInteger statusCode) {
       
    }];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
