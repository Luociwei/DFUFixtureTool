//
//  ViewController.h
//  DFU_FixtureTool
//
//  Created by Louis Luo on 2021/3/31.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ViewController : NSViewController
//- (IBAction)Get_Led_Status:(id)sender;

-(void)setRpcController:(void *)rpc;

@end

NS_ASSUME_NONNULL_END
