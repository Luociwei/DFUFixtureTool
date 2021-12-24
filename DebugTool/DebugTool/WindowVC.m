//
//  WindowVC.m
//  DfuDebugTool
//
//  Created by ciwei luo on 2021/2/28.
//  Copyright © 2021 macdev. All rights reserved.
//

#import "WindowVC.h"
#import "DutDebugVC.h"
#import "FixtureVC.h"
#import "DFUFixture.h"
#import "LuaScriptCore.h"
#import "RPCPlugin.h"
#import "InterfaceViewPlugin.h"
@interface WindowVC ()<DutDebugVCProtocol>

@property (weak) IBOutlet NSImageView *isMixReadyImage;
@property (strong,nonatomic)EditCmdsVC *editVC;

@property (strong,nonatomic)DutDebugVC *vc_debugTest;
@property (strong,nonatomic)FixtureVC *vc_fixture;
@property(nonatomic, strong) LSCContext *context;

@property(nonatomic, strong) InterfaceViewPlugin *interfaceViewPlugin;



@end

@implementation WindowVC{
    void *rpcController;

    NSMutableDictionary *_deviceInfo;
}


-(void)windowWillLoad{
    [super windowWillLoad];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    _vc_fixture =  [[FixtureVC alloc] init];
    
    _vc_debugTest = [[DutDebugVC alloc]init];
    _vc_debugTest.delegate = self;
    _vc_debugTest.title = @"DUT";
    _vc_fixture.title = @"Fixture";
    
    self.context = [[LSCContext alloc] init];
    
    //捕获异常
    [self.context onException:^(NSString *message) {
        
        NSLog(@"error = %@", message);
        
    }];
    
    
    LSCValue *device = [self luaRegisterWithMethodName:@"loadPulgins" arguments:nil];

    [self.context registerMethodWithName:@"getDeviceInfo"
                                   block:^LSCValue *(NSArray *arguments) {
                                       
                                       return device;
                                       
                                   }];
    
    NSDictionary *deviceDict =[device toDictionary];
    if (deviceDict == nil) {
        [NSApp terminate:nil];
    }
//    _deviceInfo = [NSMutableDictionary dictionaryWithDictionary:deviceDict];
    
     _interfaceViewPlugin = [deviceDict objectForKey:@"InterfaceViewPlugin"];

    _interfaceViewPlugin.fixtureVC =_vc_fixture;
    _interfaceViewPlugin.dutVC =_vc_debugTest;
    
    
    _vc_fixture.context = self.context;
    _vc_debugTest.context = self.context;
    
    _vc_fixture.isConnected = deviceDict.allKeys.count>=2;
    _vc_debugTest.isConnected = deviceDict.allKeys.count>=2;
    [self cw_addViewControllers:@[_vc_debugTest]];
      
}


-(void)fixtureMoreClicked{
    [self.vc_fixture showViewOnViewController:self.vc_debugTest];
}

- (void)windowWillClose:(NSNotification *)notification{
  
//    [self reset_all:nil];
    NSString *title =[notification.object title];
    if ([title containsString:@"DFU_DebugTool"]) {
        LSCValue *device = [self luaRegisterWithMethodName:@"appWillBeClose" arguments:nil];
        NSLog(@"result--%@",device);
    }

    [super windowWillClose:notification];
}



//- (IBAction)editClick:(id)sender {
//    
//    [self.editVC showViewAsSheetOnViewController:self.contentViewController];
//}



-(void *)getRpcController{
    return rpcController;
}
- (IBAction)connect:(NSButton *)btn {
    
//    if (_deviceInfo.allKeys.count>=2) {
//
//        [Alert cw_RemindException:@"Warning" Information:@"RPC is already connected,if fixture is just reboot,pls wait to ping is ok!!!"];
//        return;
//    }
//    NSString *reply = [Task cw_termialWithCmd:@"ping 169.254.1.32 -c 1 -t 1"];
//    if (![reply containsString:@", 0.0% packet loss"]) {
////        ("Error","ping 169.254.1.32 failed!!! Pls check the mix is ready?")
//        [Alert cw_RemindException:@"Warning" Information:@"ping 169.254.1.32 failed!!! Pls check the mix is ready?"];
//        return;
//    }
//
//
    
    LSCValue *device = [self luaRegisterWithMethodName:@"connectClick" arguments:@[[LSCValue dictionaryValue:_deviceInfo]]];
    NSDictionary *deviceDict =[device toDictionary];
    //NSLog(@"result--%@",deviceDict);
    _deviceInfo = [NSMutableDictionary dictionaryWithDictionary:deviceDict];
    [self.context registerMethodWithName:@"getDeviceInfo"
                                   block:^LSCValue *(NSArray *arguments) {

                                       return device;

                                   }];

    LSCValue *value = [self luaRegisterWithMethodName:@"getAllMethods" arguments:nil];
    NSArray *cmds = [value toArray];
    if (cmds.count) {
        _vc_debugTest.cmdsData = cmds;
    }
    
    
    
    _vc_fixture.isConnected = deviceDict.allKeys.count>=2;
    _vc_debugTest.isConnected = deviceDict.allKeys.count>=2;


}


-(LSCValue *)luaRegisterWithMethodName:(NSString *)methodName arguments:(NSArray<LSCValue *> *)arguments{
    
    // 加载Lua脚本
    
    NSString *LuaScriptPath = [[NSString cw_getResourcePath] stringByAppendingPathComponent:@"LuaScript"];
    
    NSArray *pathArr = [FileManager cw_findPathWithfFileName:@"SequenceControl.lua" dirPath:LuaScriptPath deepFind:YES];
    if (!pathArr.count) {
        return nil;
    }
    [self.context evalScriptFromFile:pathArr[0]];
    
    LSCValue *value= [self.context callMethodWithName:methodName
                                            arguments:arguments];
    
    return value;
    
}



-(void)dealloc{
    
    release_fixture_controller(rpcController);
}

-(void)setImageWithImageView:(NSImageView *)imageView icon:(NSString *)icon{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.isMixReadyImage setImage:[NSImage imageNamed:icon]];
        
    });
}

-(BOOL)getIpState:(NSString *)ip{
    
    BOOL isOk = NO;
    NSString *pingIP =[NSString stringWithFormat:@"ping %@ -t1",ip];
    NSString *read  = [Task cw_termialWithCmd:pingIP];
    if ([read containsString:@"icmp_seq="]&&[read containsString:@"ttl="]) {
        
        isOk = YES;
    }
    return isOk;
}


-(PresentViewController *)editVC{
    if (!_editVC) {
        _editVC =[[EditCmdsVC alloc]init];
    }
    return _editVC;
}


//- (IBAction)CatchFW:(NSButton *)sender {
//
//    [self.catchFwVc showViewOnViewController:self.contentViewController];
//}


//-(void)getMixSate{
//
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        while (1) {
//
//            if (![self getIpState:@"169.254.1.32"]) {
//                [self setImageWithImageView:self.isMixReadyImage icon:@"NSTouchBarCommunicationAudioTemplate"];
//                if (rpcController) {
//                    release_fixture_controller(rpcController);
//                }
//
//
//            }else{
//                [self setImageWithImageView:self.isMixReadyImage icon:@"NSTouchBarCommunicationVideoTemplate"];
//                if (!rpcController) {
//                    rpcController = create_fixture_controller(1);
//                    [_vc_ch1 setRpcController:rpcController];
//                    [_vc_ch2 setRpcController:rpcController];
//                    [_vc_ch3 setRpcController:rpcController];
//                    [_vc_ch4 setRpcController:rpcController];
//                    [_vc_fixture setRpcController:rpcController];
//                }
//            }
//
//            [NSThread sleepForTimeInterval:1];
//
//        }
//
//
//    });
//
//}


@end
