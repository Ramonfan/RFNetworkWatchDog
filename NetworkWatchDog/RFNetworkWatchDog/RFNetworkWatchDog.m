//
//  RFNetworkWatchDog.m
//  NetworkWatchDog
//
//  Created by Topband on 2018/3/19.
//  Copyright © 2018年 Ramon. All rights reserved.
//

#import "RFNetworkWatchDog.h"
#import <SystemConfiguration/CaptiveNetwork.h>

NSString *const RFNetworkChangeNotification = @"_RFNetworkChangeNotification";
static NSString *const PROBE_HOST_NAME = @"www.apple.com";

#ifdef DEBUG
#define Log(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define Log(...) ;
#endif

@interface RFNetworkWatchDog()

@property (nonatomic, strong) Reachability *reachability;
@property (nonatomic, copy) NSString *curSSID;

@end

@implementation RFNetworkWatchDog

- (BOOL)isWiFi {
    if (self.networkStatus == ReachableViaWiFi) {
        return YES;
    }
    @autoreleasepool {
        if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == ReachableViaWiFi) {
            return YES;
        }
        return [[Reachability reachabilityForLocalWiFi] isReachableViaWiFi];
    }
}

- (BOOL)isWWAN {
    if (self.networkStatus == ReachableViaWWAN) {
        return YES;
    }
    @autoreleasepool {
        if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == ReachableViaWWAN) {
            return YES;
        }
        return [[Reachability reachabilityForInternetConnection] isReachableViaWWAN];
    }
}

- (BOOL)isNetworkAvailable {
    if ([self isWWAN]) {
        return YES;
    }else {
        return [[Reachability reachabilityWithHostname:PROBE_HOST_NAME]isReachable];
    }
}

- (void)openWatchDog {
    [self.reachability stopNotifier];
    [self.reachability startNotifier];
}

- (void)postNetworkChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:RFNetworkChangeNotification object:@(self.networkStatus)];
}

- (void)setNetworkNotifierBlock {
    __block RFNetworkWatchDog *weakSelf = self;
    // 有网络但发生变化
    self.reachability.reachableBlock = ^(Reachability * _reachability) {
        
        NetworkStatus curNtwkStus = [_reachability currentReachabilityStatus];
        NSString *curSSid = (curNtwkStus == NotReachable) ? @"无网络链接": [RFNetworkWatchDog currentSSID];
        if (curNtwkStus == NotReachable) {
            Log(@"无网络链接");
        }
        if ((weakSelf.networkStatus == NotReachable)
            && (curNtwkStus == ReachableViaWiFi)) { // 从 无网 切换到wifi
            Log(@"从 无网 切换到wifi:%@", curSSid);
        } else if ((weakSelf.networkStatus == ReachableViaWiFi)
                   && (curNtwkStus == ReachableViaWiFi)) { // 从 wifi 切换到另一个 wifi
            Log(@"从 wifi:%@ 切换到另一个 wifi:%@",weakSelf.curSSID, curSSid);
        } else if ((weakSelf.networkStatus == ReachableViaWWAN)
                   && (curNtwkStus == ReachableViaWiFi)) { // 从3G 切换到 wifi
            Log(@"从3G 切换到 wifi:%@", curSSid);
        } else if ((weakSelf.networkStatus == ReachableViaWiFi)
                   &&(curNtwkStus == ReachableViaWWAN)) { // 从 wifi 切换到3G
            Log(@"从 wifi:%@ 切换到3G", curSSid);
        } else if ((weakSelf.networkStatus == NotReachable)
                   &&(curNtwkStus == ReachableViaWWAN)) { // 从 无网 切换到3G
            Log(@"从 无网 切换到3G");
        } else if ((weakSelf.networkStatus == ReachableViaWWAN)
                   &&(curNtwkStus == NotReachable)) { // 从 3G 切换到无网
            Log(@"从 3G 切换到无网");
        } else if ((weakSelf.networkStatus == ReachableViaWiFi)
                   &&(curNtwkStus == NotReachable)) { // 从 wifi 切换到无网
            Log(@"从 wifi:%@ 切换到无网", curSSid);
        }
        
        // ssid发生变化或者网络状态发生变化才发送通知
        if ((![curSSid isEqualToString:weakSelf.curSSID]) || weakSelf.networkStatus != curNtwkStus) {
            weakSelf.curSSID = curSSid;
            weakSelf.networkStatus = curNtwkStus;
            Log(@"SSID发生变化或者网络状态发生变化");
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf postNetworkChange];
            });
        }
    };
    
    self.reachability.unreachableBlock = ^(Reachability * _reachability) { // 从有网络变为无网络
        Log(@"无网络连接");
        weakSelf.networkStatus = [_reachability currentReachabilityStatus];
        // 网络发生变化
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf postNetworkChange];
        });
    };
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _reachability = [Reachability reachabilityWithHostName:PROBE_HOST_NAME];
        _networkStatus = NotReachable;
        [self setNetworkNotifierBlock];
    }
    return self;
}

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static RFNetworkWatchDog *watchDog = nil;
    dispatch_once(&onceToken, ^{
        watchDog = [[RFNetworkWatchDog alloc] init];
    });
    return watchDog;
}

#pragma mark - 获取网络信息
#pragma mark - 获取WIFI网络名称
+ (NSDictionary *)fetchSSIDInfo {
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    NSDictionary * info = nil;
    for (NSString *ifnam in ifs) {
        info = (id)CFBridgingRelease(CNCopyCurrentNetworkInfo((CFStringRef)ifnam));
        if (info && [info count]) {
            break;
        }
    }
    return info;
}

+ (NSString *)currentSSID {
    NSDictionary *ifs = [[self class] fetchSSIDInfo];
    NSString *ssid = [ifs objectForKey:@"SSID"];
    return ssid;
}

@end
