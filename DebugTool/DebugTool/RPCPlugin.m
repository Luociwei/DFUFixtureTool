//
//  FixturePlugin.m
//  DFU_DebugTool
//
//  Created by ciwei luo on 2021/9/11.
//  Copyright © 2021 macdev. All rights reserved.
//

#import "RPCPlugin.h"
#import "DFUFixture.h"



@implementation RPCPlugin{
    void *_rpcController;
}


+(instancetype)rpcPluginConnect:(NSArray *)ipPorts{
    if (!ipPorts.count) {
        return nil;
    }
//    for (int i =0; i<ipPorts.count; i++) {
//        NSLog(@"%d---%@",i,ipPorts[i]);
//    }
    //@"uart_SoC.shutdown_all()"
    RPCPlugin *rpcPlugin = [[self alloc]init];
    
    void *rpcController = create_fixture_controllerWithPorts(1, ipPorts);
    NSString *reply = [NSString stringWithUTF8String:executeAction_original(rpcController,@"version.version()",1)];
    if ([reply.lowercaseString containsString:@"error"] || [reply.lowercaseString containsString:@"timeout"]) {
//        NSLog(@"NOT CONNECT!!!!!!");
        return nil;
    }

    [rpcPlugin setRpcController:rpcController];
    
    return rpcPlugin;
}


-(BOOL)setIpPorts:(NSArray *)ipPorts{
    if (!ipPorts.count) {
        return NO;
    }
    void *rpcController = create_fixture_controllerWithPorts(1, ipPorts);
    if (rpcController ==nil) {
        return NO;
    }
    [self setRpcController:rpcController];
    return YES;
}



-(void *)getRpcController{
    return _rpcController;
    
}

-(void)setRpcController:(void *)rpc{
    _rpcController = rpc;
    
}

-(NSString *)fxitureWriteAndRead:(NSString *)cmd site:(int)site{
    if (_rpcController==nil) {
        return @"not connect!!!";
    }
    const char * const ret = executeAction_original(_rpcController,cmd,site);
//
    NSString *ret_str = [NSString stringWithUTF8String:ret];
    return ret_str;
//    return [NSString stringWithFormat:@"site:%d--cmd:%@--",site,cmd];
//
}


- (NSString *)dutWrite:(NSString *)cmd site:(int)site{
    if (_rpcController==nil) {
        return @"not connect!!!";
    }
    NSString *diags_cmd = [NSString stringWithFormat:@"uart_test.write(%@\n)",cmd];
    
    const char * const ret =executeAction_original(_rpcController, diags_cmd, site);
    NSString *ret_str = [NSString stringWithUTF8String:ret];
    if (!ret_str.length) {
        ret_str = @"";
    }
    
    return @"";
}

- (NSString *)dutRead:(int)site{
    if (_rpcController==nil) {
        return @"";
    }
    NSString *diags_cmd = @"uart_test.read()";
    
    const char * const ret =executeAction_original(_rpcController, diags_cmd, site);
    NSString *ret_str = [NSString stringWithUTF8String:ret];
    if (!ret_str.length) {
        ret_str = @"";
    }
    
    return @"";
}

- (BOOL)isBoardDetected:(int)site{
    if (_rpcController==nil) {
        return NO;
    }
    
    return is_board_detected(_rpcController,site);
}


-(void)shutdownAll{
    
    [self fxitureWriteAndRead:@"uart_SoC.shutdown_all()" site:1];
    [self fxitureWriteAndRead:@"uart_SoC.shutdown_all()" site:2];
    [self fxitureWriteAndRead:@"uart_SoC.shutdown_all()" site:3];
    [self fxitureWriteAndRead:@"uart_SoC.shutdown_all()" site:4];
}

@end
