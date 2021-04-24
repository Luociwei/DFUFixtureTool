//
//  WindowVC.m
//  DfuDebugTool
//
//  Created by ciwei luo on 2021/2/28.
//  Copyright © 2021 macdev. All rights reserved.
//

#import "WindowVC.h"
#import "ViewController.h"
#import "FixtureVC.h"
#import <CwGeneralManagerFrameWork/TextView.h>
#import <CwGeneralManagerFrameWork/Task.h>
#import <CwGeneralManagerFrameWork/Image.h>
#import <CwGeneralManagerFrameWork/FileManager.h>
#import "DFUFixture.h"
#import "AtlasLogVC.h"
#import "CatchFwVc.h"

@interface WindowVC ()

@property (weak) IBOutlet NSImageView *isMixReadyImage;
@property (strong,nonatomic)EditCmdsVC *editVC;
@property (strong,nonatomic)CatchFwVc *catchFwVc;
@property (strong,nonatomic)ViewController *vc_ch1;
@property (strong,nonatomic)ViewController *vc_ch2;
@property (strong,nonatomic)ViewController *vc_ch3;
@property (strong,nonatomic)ViewController *vc_ch4;
@property (strong,nonatomic)FixtureVC *vc_fixture;
@property (strong,nonatomic)AtlasLogVC *atlasCsvLogVC;

@end

@implementation WindowVC{
    void *rpcController;
}



- (IBAction)CatchFW:(NSButton *)sender {
    
    [self.catchFwVc showViewOnViewController:self.contentViewController];
}


- (void)windowDidLoad {
    [super windowDidLoad];
    NSString *cmd = @"fix.ss()";
    NSArray *arrCmd = nil;
    if ([cmd containsString:@"]"])
    {
        NSArray *arrSub= [cmd componentsSeparatedByString:@"]"];
        arrCmd = [arrSub[1] componentsSeparatedByString:@"("];
    }
    else
    {
        arrCmd = [cmd componentsSeparatedByString:@"("];
    }
    if ([arrCmd count]<2)
    {
//        return @"command format error\r\n";
    }
    
    NSString *method = arrCmd[0];
    NSString * strArgs = [arrCmd[1] stringByReplacingOccurrencesOfString:@")" withString:@""];
    NSArray *arrArgs = [strArgs componentsSeparatedByString:@","];
    
    NSMutableDictionary* dicKwargs = [NSMutableDictionary dictionary];
    [dicKwargs setObject:@(100) forKey:@"timeout_ms"];
    NSString *rpc_args = [arrArgs componentsJoinedByString:@" "];
    NSLog(@"[rpc_client] %@ %@  . Method: %@, args: %@, kwargs: nil,timeout_ms: %d",method,rpc_args,method,strArgs,100);
    
    if ([[arrArgs[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""] )
    {
        arrArgs = nil;
    }
    
    
    
    
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
//    NSMutableArray *vcs = [[NSMutableArray alloc]init];
    NSString *pathLogFile = @"/vault/Atlas/FixtureLog/SunCode/SCFixture_Command.txt";
    NSString *pathTempLogFile = @"/vault/Atlas/FixtureLog/SunCode/SCFixture_Temp_Command.txt";
    [FileManager cw_createFile:pathLogFile isDirectory:NO];
    [FileManager cw_createFile:pathTempLogFile isDirectory:NO];
    
    _vc_fixture =  [[FixtureVC alloc] init];
    _vc_fixture.title = @"Fixture";
    _atlasCsvLogVC =  [[AtlasLogVC alloc] init];
    _atlasCsvLogVC.title = @"AtlasLog";
    _vc_ch1 =  [[ViewController alloc] init];
    _vc_ch2 =  [[ViewController alloc] init];
    _vc_ch3 =  [[ViewController alloc] init];
    _vc_ch4 =  [[ViewController alloc] init];
    _vc_ch1.title = @"Ch1";
    _vc_ch2.title = @"Ch2";
    _vc_ch3.title = @"Ch3";
    _vc_ch4.title = @"Ch4";


    [self cw_addViewControllers:@[_atlasCsvLogVC,_vc_ch1,_vc_ch2,_vc_ch3,_vc_ch4,_vc_fixture]];
    
    [self getMixSate];
}


- (IBAction)editClick:(id)sender {
    
    [self.editVC showViewAsSheetOnViewController:self.contentViewController];
}



-(void *)getRpcController{
    return rpcController;
}

-(void)getMixSate{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            
            if (![self getIpState:@"169.254.1.32"]) {
                [self setImageWithImageView:self.isMixReadyImage icon:@"NSTouchBarCommunicationAudioTemplate"];
                if (rpcController) {
                    release_fixture_controller(rpcController);
                }
                
                
            }else{
                [self setImageWithImageView:self.isMixReadyImage icon:@"NSTouchBarCommunicationVideoTemplate"];
                if (!rpcController) {
                    rpcController = create_fixture_controller(1);
                    [_vc_ch1 setRpcController:rpcController];
                    [_vc_ch2 setRpcController:rpcController];
                    [_vc_ch3 setRpcController:rpcController];
                    [_vc_ch4 setRpcController:rpcController];
                    [_vc_fixture setRpcController:rpcController];
                }
            }
            
            [NSThread sleepForTimeInterval:1];
            
        }
        
        
    });
    
}

-(void)dealloc{
    
    release_fixture_controller(rpcController);
}

-(void)setImageWithImageView:(NSImageView *)imageView icon:(NSString *)icon{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
//        if ([icon containsString:@"off"]) {
//            [imageView setImage:[NSImage imageNamed:@"NSTouchBarCommunicationAudioTemplate"]];
//        }else if([icon containsString:@"error"]){
//            [imageView setImage:[Image cw_getRedCircleImage]];
//        }else{
//            [imageView setImage:[Image cw_getGreenCircleImage]];
//        }
        //        [imageView setImage:[NSImage imageNamed:icon]];
        [self.isMixReadyImage setImage:[NSImage imageNamed:icon]];
        
    });
}

-(BOOL)getIpState:(NSString *)ip{
    
    BOOL isOk = NO;
    NSString *pingIP =[NSString stringWithFormat:@"ping %@ -t1",ip];
    NSString *read  = [Task termialWithCmd:pingIP];
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
-(PresentViewController *)catchFwVc{
    if (!_catchFwVc) {
        _catchFwVc =[[CatchFwVc alloc]init];
    }
    return _catchFwVc;
}
@end
