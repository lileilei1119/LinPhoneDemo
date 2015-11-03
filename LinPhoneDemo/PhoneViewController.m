//
//  PhoneViewController.m
//  LinPhoneDemo
//
//  Created by lileilei on 15/11/3.
//  Copyright (c) 2015年 lileilei. All rights reserved.
//

#import "PhoneViewController.h"
#import "Utilities.h"

@implementation PhoneViewController

#pragma --mark viewlife
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(registrationUpdate:) name:kLinphoneRegistrationUpdate object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(callUpdate:) name:kLinphoneCallUpdate object:nil];
    
    //注册状态
    LinphoneProxyConfig* config = NULL;
    linphone_core_get_default_proxy([LinphoneManager getLc], &config);
    [self proxyConfigUpdate: config];
    
     linphone_core_set_native_video_window_id([LinphoneManager getLc], (unsigned long)_videoView);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)registrationUpdate: (NSNotification*) notif {
    LinphoneProxyConfig* config = NULL;
    linphone_core_get_default_proxy([LinphoneManager getLc], &config);
    [self proxyConfigUpdate:config];
}

- (void)proxyConfigUpdate: (LinphoneProxyConfig*) config {
    LinphoneRegistrationState state = LinphoneRegistrationNone;
    NSString* message = nil;
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneGlobalState gstate = linphone_core_get_global_state(lc);
    
    if( gstate == LinphoneGlobalConfiguring ){
        message = @"状态:获取远程配置";
    } else if (config == NULL) {
        state = LinphoneRegistrationNone;
        if(linphone_core_is_network_reachable([LinphoneManager getLc])){
            message = @"状态:sip账号不存在";
        }else{
            message = @"状态:网络连接失败";
        }
    } else {
        state = linphone_proxy_config_get_state(config);
        
        switch (state) {
            case LinphoneRegistrationOk:
                message = @"状态:注册成功"; break;
            case LinphoneRegistrationNone:
            case LinphoneRegistrationCleared:
                message =  @"状态:未注册"; break;
            case LinphoneRegistrationFailed:
                message =  @"状态:注册失败"; break;
            case LinphoneRegistrationProgress:
                message =  @"状态:注册中……"; break;
            default: break;
        }
    }
    NSLog(@"proxyConfigUpdate regist msg:%@",message);
    [self.statusLabel setText:message];
}

#pragma --mark phone status
- (void)callUpdate:(NSNotification*)notif {
    LinphoneCall *call = [[notif.userInfo objectForKey: @"call"] pointerValue];
    LinphoneCallState state = [[notif.userInfo objectForKey: @"state"] intValue];
    NSString *message = [notif.userInfo objectForKey: @"message"];
    
    NSLog(@"lll=================callUpdateMsg：%@",message);
    
    //    linphone_core_get_calls([LinphoneManager getLc]);
    switch (state) {
        case LinphoneCallIncomingReceived:
        case LinphoneCallIncomingEarlyMedia:
        {
            [[LinphoneManager instance] setSpeakerEnabled:TRUE];
            AudioServicesPlaySystemSound([LinphoneManager instance].sounds.vibrate);
            
            if ([UIApplication sharedApplication].applicationState ==  UIApplicationStateActive) {
                [self acceptCallFromPeer:call];
            }
            
            NSLog(@"lll=================LinphoneCallIncomingEarlyMedia");
            
            break;
        }
        case LinphoneCallOutgoingInit:
        case LinphoneCallPausedByRemote:
        case LinphoneCallConnected:
        case LinphoneCallStreamsRunning:
        {
            NSLog(@"lll=================LinphoneCallStreamsRunning");
            break;
        }
        case LinphoneCallUpdatedByRemote:
        {
            NSLog(@"lll=================LinphoneCallUpdatedByRemote");
            break;
        }
        case LinphoneCallError:
        case LinphoneCallEnd:
        {
            NSLog(@"lll=================LinphoneCallEnd");
            
//            [self exitPhoneView];
            break;
        }
        default:
            break;
    }
    
}

-(void)acceptCallFromPeer:(LinphoneCall*) call{
    //    [[LinphoneManager instance] setSpeakerEnabled:TRUE];
    if (linphone_call_camera_enabled(call)) {
        linphone_call_enable_camera(call,false);
    }
    
    if(linphone_core_mic_enabled([LinphoneManager getLc])){
        linphone_core_enable_mic([LinphoneManager getLc], FALSE);
    }
    
    [[LinphoneManager instance] acceptCall:call];
    
//    [self pushPhoneView];
}

- (void)setVideoEnable:(BOOL)isOn {
    LinphoneCore* lc = [LinphoneManager getLc];
    
    if (!linphone_core_video_enabled(lc))
        return;
    
    LinphoneCall* call = linphone_core_get_current_call([LinphoneManager getLc]);
    if (call) {
        LinphoneCallParams* call_params =  linphone_call_params_copy(linphone_call_get_current_params(call));
        linphone_call_params_enable_video(call_params, isOn);
        linphone_core_update_call(lc, call, call_params);
        linphone_call_params_destroy(call_params);
    }
}

- (IBAction)onCall:(id)sender {
    NSString *yourAdd = [NSString stringWithFormat:@"sip:%@@%@",YOU_NAME,OUR_DOMAIN];
    [[LinphoneManager instance] call:yourAdd displayName:YOU_NAME transfer:NO];
}

- (IBAction)onAnswer:(id)sender {
    //    [[LinphoneManager instance] acceptCall:_call];
    linphone_core_enable_mic([LinphoneManager getLc], TRUE);
    [self sendDtmf:'0'];
}

- (IBAction)onRingup:(id)sender {
    linphone_core_terminate_call([LinphoneManager getLc], linphone_core_get_current_call([LinphoneManager getLc]));
}

- (IBAction)onOpenDoor:(id)sender {
    [self sendDtmf:'#'];
}

-(void)sendDtmf:(char) digit{
    if (linphone_core_in_call([LinphoneManager getLc])) {
        linphone_core_send_dtmf([LinphoneManager getLc], digit);
        linphone_core_play_dtmf([LinphoneManager getLc], digit, 100);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            linphone_core_stop_dtmf([LinphoneManager getLc]);
        });
    }
}

@end
