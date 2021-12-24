//
//  FixtureViewControl.m
//  DFU_DebugTool
//
//  Created by ciwei luo on 2021/9/12.
//  Copyright © 2021 macdev. All rights reserved.
//

#import "InterfaceViewPlugin.h"
#import "ExtensionConst.h"

@implementation InterfaceViewPlugin

+(NSString *)appResourcePath{
    return [[NSBundle mainBundle] resourcePath];
}
+(NSString *)runShellCmd:(NSString *)cmd{
    return [Task cw_termialWithCmd:cmd];
}
+(void)popupAlert:(NSString *)title info:(NSString *)info{
    if (!title.length) {
        title = @"Warning";
    }
    if (!info.length) {
        info = @"";
    }
    [Alert cw_RemindException:title Information:info];
}

//[Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];


-(void)printDutLog:(NSString *)log slot:(int )slot{

    if (slot>=1 && slot<=4) {
        if (_dutVC) {
            [_dutVC printDutLog:log slot:slot];
        }
    }else{
        if (_fixtureVC) {
            [_fixtureVC printLog:log];
        }
    }
}

-(void)printFixtureLog:(NSString *)log slot:(int )slot{
    if (slot>=1 && slot<=4) {
        if (_dutVC) {
            [_dutVC printFixtureLog:log slot:slot];
        }
    }else{
        if (_fixtureVC) {
            [_fixtureVC printLog:log];
        }
    }

}


-(void)setDutStautsLedLight:(BOOL)isOn channel:(int)channel{
    if (_dutVC==nil) {
        return;
    }
    
    [_dutVC setDutStautsLedLight:isOn channel:channel];
    
}

-(void)setFixtureActionStautsLedLight:(BOOL)isOn status:(NSString *)status{
    if (_fixtureVC==nil) {
        return;
    }
    
    [_fixtureVC setFixtureActionStautsLedLight:isOn status:status];
    
}
-(void)setFixtureRunningTime:(NSString *)time{
    if (_fixtureVC==nil) {
        return;
    }
    
    [_fixtureVC showRunningTime:time];
}


@end
