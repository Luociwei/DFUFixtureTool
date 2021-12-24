//
//  DebugTestVC.h
//  DFU_DebugTool
//
//  Created by ciwei luo on 2021/9/18.
//  Copyright © 2021 macdev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LuaScriptCore.h"
#import "ExtensionConst.h"
NS_ASSUME_NONNULL_BEGIN

//typedef NS_ENUM(nss, NSBorderType) {
//    NSNoBorder                = 0,
//    NSLineBorder            = 1,
//    NSBezelBorder            = 2,
//    NSGrooveBorder            = 3
//};


@protocol DutDebugVCProtocol <NSObject>

-(void)fixtureMoreClicked;

@end

@interface DutDebugVC : NSViewController
@property (weak) id<DutDebugVCProtocol>delegate;
@property(nonatomic, strong) LSCContext *context;
@property BOOL isConnected;
-(void)printDutLog:(NSString *)log slot:(int)slot;
-(void)setDutStautsLedLight:(BOOL)isOn channel:(int)channel;
-(void)printFixtureLog:(NSString *)log slot:(int)slot;
//@property (nonatomic,strong) NSMutableArray<NSDictionary *> *cmdData;
@property (nonatomic,strong) NSArray<NSDictionary *> *cmdsData;


@end

NS_ASSUME_NONNULL_END
