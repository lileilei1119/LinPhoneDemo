//
//  PhoneBridge.m
//  CommonProject
//
//  Created by lileilei on 15/9/24.
//

#import "PhoneBridge.h"
#import "LinphoneManager.h"

#import "Utilities.h"

@implementation PhoneBridge

static PhoneBridge *phoneBridge = nil;

+ (PhoneBridge*)shareInstance {
    if(phoneBridge == nil) {
        phoneBridge = [[PhoneBridge alloc] init];
        [[LinphoneManager instance] setLogsEnabled:NO];
    }
    return phoneBridge;
}

-(void)toggleVoipSer{
    
    UIApplication* app= [UIApplication sharedApplication];
    
    if( [app respondsToSelector:@selector(registerUserNotificationSettings:)] ){
        UIUserNotificationType notifTypes = UIUserNotificationTypeSound;
        UIUserNotificationSettings* userSettings = [UIUserNotificationSettings settingsForTypes:notifTypes categories:nil];
        [app registerUserNotificationSettings:userSettings];
        [app registerForRemoteNotifications];
    } else {
        NSUInteger notifTypes = UIRemoteNotificationTypeSound;
        [app registerForRemoteNotificationTypes:notifTypes];
    }
    
    
    bgStartId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"Background task for application launching expired.");
        [[UIApplication sharedApplication] endBackgroundTask:bgStartId];
    }];
    
    [[LinphoneManager instance]	startLibLinphone];
    
    if (bgStartId!=UIBackgroundTaskInvalid) [[UIApplication sharedApplication] endBackgroundTask:bgStartId];
    
    [self loadSettings];
    
}

#pragma --mark 生命周期
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self toggleVoipSer];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* call = linphone_core_get_current_call(lc);
    
    if (call){
        const LinphoneCallParams* params = linphone_call_get_current_params(call);
        if (linphone_call_params_video_enabled(params)) {
            linphone_call_enable_camera(call, false);
        }
    }
    
    if (![[LinphoneManager instance] resignActive]) {
        
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[LinphoneManager instance] enterBackgroundMode];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    LinphoneManager* instance = [LinphoneManager instance];
    
    [instance becomeActive];
    
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* call = linphone_core_get_current_call(lc);
    
    if (call){
        if (call == instance->currentCallContextBeforeGoingBackground.call) {
            const LinphoneCallParams* params = linphone_call_get_current_params(call);
            if (linphone_call_params_video_enabled(params)) {
                linphone_call_enable_camera(
                                            call,
                                            instance->currentCallContextBeforeGoingBackground.cameraIsEnabled);
            }
            instance->currentCallContextBeforeGoingBackground.call = 0;
        } else if ( linphone_call_get_state(call) == LinphoneCallIncomingReceived ) {
            [self fixRing];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self fixRing];
    
    if([notification.userInfo objectForKey:@"callId"] != nil) {
        
        LinphoneCall* call = [[LinphoneManager instance] getCallById:[notification.userInfo objectForKey:@"callId"]];
        if (call) {
//            [self acceptCallFromPeer:call];
        }
        
    }
}

- (void)fixRing{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 1];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    }
}

#pragma phone配置
-(void)loadSettings{
    [self loadWizardConfig:@"wikijoin_phone_sip.conf"];
    
    BOOL success = [self addProxyConfig:MY_NAME password:MY_NAME];//_user.mobile
    NSLog(@"account PLogn is success? my computer says:%i",success);
    
    settingsStore = [[PhoneSettings alloc] init];
    [settingsStore transformLinphoneCoreToKeys];
    
    [settingsStore setBool:true forKey:@"accept_video_preference"];//automatically_accept
    [settingsStore setBool:false forKey:@"start_video_preference"];//automatically_initiate
    
    [settingsStore setBool:false forKey:@"mp4v-es_preference"];
    [settingsStore setBool:false forKey:@"vp8_preference"];
    [settingsStore setBool:true forKey:@"h264_preference"];
    
    [settingsStore setBool:true forKey:@"enable_video_preference"];
    
    [settingsStore synchronize];
}

- (BOOL)addProxyConfig:(NSString*)username password:(NSString*)password{
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneProxyConfig* proxyCfg = linphone_core_create_proxy_config(lc);
    
    char normalizedUserName[256];
    linphone_proxy_config_normalize_number(proxyCfg, [username cStringUsingEncoding:[NSString defaultCStringEncoding]], normalizedUserName, sizeof(normalizedUserName));
    
    const char* identity = linphone_proxy_config_get_identity(proxyCfg);
    
    LinphoneAddress* linphoneAddress = linphone_address_new(identity);
    linphone_address_set_username(linphoneAddress, normalizedUserName);
    
    char* extractedAddres = linphone_address_as_string_uri_only(linphoneAddress);
    
    LinphoneAddress* parsedAddress = linphone_address_new(extractedAddres);
    ms_free(extractedAddres);
    
    if( parsedAddress == NULL || !linphone_address_is_sip(parsedAddress) ){
        if( parsedAddress ) linphone_address_destroy(parsedAddress);
        NSLog(@"==phone: 用户名或密码错误！！！！");
        return FALSE;
    }
    
    char *c_parsedAddress = linphone_address_as_string_uri_only(parsedAddress);
    
    linphone_proxy_config_set_identity(proxyCfg, c_parsedAddress);
    
    linphone_address_destroy(parsedAddress);
    ms_free(c_parsedAddress);
    
    LinphoneAuthInfo* info = linphone_auth_info_new([username UTF8String]
                                                    , NULL, [password UTF8String]
                                                    , NULL
                                                    , NULL
                                                    ,linphone_proxy_config_get_domain(proxyCfg));
    
    [self setDefaultSettings:proxyCfg];
    
    [self clearProxyConfig];
    
    linphone_proxy_config_enable_register(proxyCfg, true);
    linphone_core_add_auth_info(lc, info);
    linphone_core_add_proxy_config(lc, proxyCfg);
    linphone_core_set_default_proxy_config(lc, proxyCfg);
    return TRUE;
}

- (void)clearProxyConfig {
    linphone_core_clear_proxy_config([LinphoneManager getLc]);
    linphone_core_clear_all_auth_info([LinphoneManager getLc]);
}

- (void)setDefaultSettings:(LinphoneProxyConfig*)proxyCfg {
    LinphoneManager* lm = [LinphoneManager instance];
    
    [lm configurePushTokenForProxyConfig:proxyCfg];
    
}

- (void)loadWizardConfig:(NSString*)rcFilename {
    NSString* fullPath = [@"file://" stringByAppendingString:[LinphoneManager bundleFile:rcFilename]];
    linphone_core_set_provisioning_uri([LinphoneManager getLc], [fullPath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    [[LinphoneManager instance] lpConfigSetInt:1 forKey:@"transient_provisioning" forSection:@"misc"];
    [[LinphoneManager instance] resetLinphoneCore];
}

@end
