//
//  RFNetworkWatchDog.h
//  NetworkWatchDog
//
//  Created by Topband on 2018/3/19.
//  Copyright © 2018年 Ramon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Reachability/Reachability.h>

extern NSString *const RFNetworkChangeNotification;

NS_ASSUME_NONNULL_BEGIN
@interface RFNetworkWatchDog : NSObject

+ (instancetype)shareInstance;

//当前网络状态
@property (nonatomic , assign) NetworkStatus networkStatus;

//开始监听网络变化
- (void)openWatchDog;

//网络是否可用
- (BOOL)isNetworkAvailable;
//是否为移动网络
- (BOOL)isWWAN;
//是否为WiFi网络
- (BOOL)isWiFi;
//获取当前WiFI的getSSID
+ (nullable NSString *)currentSSID;
@end
NS_ASSUME_NONNULL_END
