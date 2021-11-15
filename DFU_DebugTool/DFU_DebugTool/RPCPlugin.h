//
//  FixturePlugin.h
//  DFU_DebugTool
//
//  Created by ciwei luo on 2021/9/11.
//  Copyright © 2021 macdev. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import "LuaScriptCore.h"

NS_ASSUME_NONNULL_BEGIN

@interface RPCPlugin : NSObject<LSCExportType>
+(instancetype)rpcPluginConnect:(NSArray *)ipPorts;
-(BOOL)setIpPorts:(NSArray *)ipPorts;
-(void *)getRpcController;
- (NSString *)fxitureWriteAndRead:(NSString *)cmd site:(int)site;
- (NSString *)dutWrite:(NSString *)cmd site:(int)site;
- (NSString *)dutRead:(int)site;
- (BOOL)isBoardDetected:(int)site;
-(void)shutdownAll;
@end

NS_ASSUME_NONNULL_END
