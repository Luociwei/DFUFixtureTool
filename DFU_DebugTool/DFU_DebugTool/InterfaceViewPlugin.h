//
//  FixtureViewControl.h
//  DFU_DebugTool
//
//  Created by ciwei luo on 2021/9/12.
//  Copyright © 2021 macdev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LuaScriptCore.h"
#import "FixtureVC.h"
#import "DutDebugVC.h"
NS_ASSUME_NONNULL_BEGIN

@interface InterfaceViewPlugin : NSObject<LSCExportType>
+(NSString *)appResourcePath;
+(NSString *)runShellCmd:(NSString *)cmd;
+(void)popupAlert:(NSString *)title info:(NSString *)info;

@property(nonatomic, strong) DutDebugVC *dutVC;
@property(nonatomic, strong) FixtureVC *fixtureVC;
//-(void)printFixtureLog:(NSString *)str;
-(void)printDutLog:(NSString *)log slot:(int )slot;
-(void)printFixtureLog:(NSString *)log slot:(int )slot;
-(void)setDutStautsLedLight:(BOOL)isOn channel:(int)channel;
-(void)setFixtureActionStautsLedLight:(BOOL)isOn status:(NSString *)status;
-(void)setFixtureRunningTime:(NSString *)time;

@end

NS_ASSUME_NONNULL_END
