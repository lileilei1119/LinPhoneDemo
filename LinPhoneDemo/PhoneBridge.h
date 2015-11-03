//
//  PhoneBridge.h
//  CommonProject
//
//  Created by lileilei on 15/9/24.
//

#import <Foundation/Foundation.h>
#import "PhoneSettings.h"

@interface PhoneBridge : NSObject{
    UIBackgroundTaskIdentifier bgStartId;
    BOOL startedInBackground;
    PhoneSettings* settingsStore;
}

@property (strong, nonatomic) UIWindow *window;


+ (PhoneBridge*)shareInstance;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (void)applicationWillResignActive:(UIApplication *)application;
- (void)applicationDidEnterBackground:(UIApplication *)application;
- (void)applicationWillEnterForeground:(UIApplication *)application;
- (void)applicationDidBecomeActive:(UIApplication *)application;

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification;

@end
