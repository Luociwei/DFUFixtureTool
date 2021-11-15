//
//  FixtureVC.h
//  DfuDebugTool
//
//  Created by ciwei luo on 2021/2/28.
//  Copyright © 2021 macdev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LuaScriptCore.h"
#import "ExtensionConst.h"
NS_ASSUME_NONNULL_BEGIN

@interface FixtureVC : PresentViewController
-(void)setRpcController:(void *)rpc;
@property BOOL isConnected;
@property(nonatomic, strong) LSCContext *context;
//-(void)setLSCContext:(void *)context;
-(void)printLog:(NSString *)log;
-(void)showRunningTime:(NSString *)time;
-(void)setFixtureActionStautsLedLight:(BOOL)isOn status:(NSString *)status;
@end

NS_ASSUME_NONNULL_END
