//
//  ViewController.m
//  DFU_FixtureTool
//
//  Created by Louis Luo on 2021/3/31.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "ViewController.h"
#import <CwGeneralManagerFrameWork/NSString+Extension.h>
#import <CwGeneralManagerFrameWork/FileManager.h>
#import <CwGeneralManagerFrameWork/Alert.h>
#import <CwGeneralManagerFrameWork/Task.h>
#import <CwGeneralManagerFrameWork/TextView.h>
#import <CwGeneralManagerFrameWork/Image.h>

#import "DFUFixture.h"

@interface ViewController ()
@property (weak) IBOutlet NSTextField *cmdView;
@property (weak) IBOutlet NSButton *btnSend;

@property (nonatomic,strong)TextView *textView;
@property (weak) IBOutlet NSTextField *portTextView;

@end

@implementation ViewController{
    void *rpcController;
    int ch_id;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    if ([self.title containsString:@"1"]) {
        self.portTextView.stringValue = @"7801";
        ch_id = 1;
    }else if ([self.title containsString:@"2"]){
        self.portTextView.stringValue = @"7802";
        ch_id = 2;
    }else if ([self.title containsString:@"3"]){
        self.portTextView.stringValue = @"7803";
        ch_id = 3;
    }else if ([self.title containsString:@"4"]){
        self.portTextView.stringValue = @"7804";
        ch_id = 4;
    }
    
    [NSString cw_getDesktopPath];
    
    
//    self.textView = [TextView cw_allocInitWithFrame:NSMakeRect(0, 0, 668, 258)];
    self.textView = [[TextView alloc] init];
    self.textView.frame =NSMakeRect(0, 0, 668, 258);
    [self.view addSubview:self.textView];
 
    
    
}

-(void)setRpcController:(void *)rpc{
    rpcController = rpc;
}





- (IBAction)connect:(id)sender {
 
//    create_fixture_controller(0);
}


- (IBAction)disconnect:(id)sender {
}




- (IBAction)bitClick:(NSSegmentedControl *)btn {
    if (!rpcController) {
        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!!"];
        return;
    }
    NSString *cmd_on =@"io.set(bit36=1)";
    NSString *cmd_off =@"io.set(bit36=0)";
 
    if (btn.selectedSegment) {//kLED_UUT3BLUE :@"io.set(bit65=1;bit66=1;bit67=0)",
        self.cmdView.stringValue = cmd_on;
        [self send:nil];
//        executeAction(rpcController, cmd_on, ch_id);
        
        
    }else{
        self.cmdView.stringValue = cmd_off;
        [self send:nil];
//        executeAction(rpcController, cmd_off, ch_id);
     
        
    }
    NSString *log = [FileManager cw_readFromFile:@"/vault/Atlas/FixtureLog/SunCode/SCFixture_Temp_Command.txt"];
//    [self showLog:[FileManager cw_readFromFile:@"/vault/Atlas/FixtureLog/SunCode/SCFixture_Temp_Command.txt"]];
}

//kFORCEDIAGSOFF:@[@"io.set(bit26=0;bit22=0;bit42=1)",
////                                             @"io.set(bit42=1)",
//@"Delay:0.5",
//@"batt.volt_set(0)",
//@"reset_all.reset()",
//@"io.set(bit26=0;bit22=0;bit40=0)",
//@"io.set(bit30=1;bit42=1;bit43=1)",
//@"Delay:2",
////                                             @"io.set(bit30=0;bit42=0;bit43=0)"
//],
- (IBAction)enterDiags:(NSSegmentedControl *)btn {
//    if (!rpcController) {
//        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!!"];
//        return;
//    }
    NSString *cmd_on =@"batt.volt_set(0)&&reset_all.reset()&&io.set(bit39=0;bit24=0;bit40=0;bit34=0;bit22=0;bit26=0;bit30=1;bit42=1;bit43=1)&&Delay:2&&io.set(bit30=0;bit42=0;bit43=0)&&batt.volt_set(4200)&&io.set(bit39=1;bit24=1;bit40=1;bit34=1;bit22=1;bit26=1)";
    NSString *cmd_off =@"io.set(bit26=0;bit22=0;bit42=1)&&Delay:0.5&&batt.volt_set(0)&&reset_all.reset()&&io.set(bit26=0;bit22=0;bit40=0)&&io.set(bit30=1;bit42=1;bit43=1)&&Delay:2";
    
    if (btn.selectedSegment) {//kLED_UUT3BLUE :@"io.set(bit65=1;bit66=1;bit67=0)",
        self.cmdView.stringValue = cmd_on;
        NSString *path = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
        path = [NSString stringWithFormat:@"%@/DutSocket.app",path];
        NSLog(@"===:::>>path : %@",path);
        [[NSWorkspace sharedWorkspace] launchApplication:path];
        [self send:nil];
//        executeAction(rpcController, cmd_on, ch_id);
        
        
    }else{
        self.cmdView.stringValue = cmd_off;
        [self send:nil];
//        executeAction(rpcController, cmd_off, ch_id);
        
        
    }
    NSString *log = [FileManager cw_readFromFile:@"/vault/Atlas/FixtureLog/SunCode/SCFixture_Temp_Command.txt"];
//    [self showLog:[FileManager cw_readFromFile:@"/vault/Atlas/FixtureLog/SunCode/SCFixture_Temp_Command.txt"]];
}



//
//kFORCEDIAGSON:@[@"batt.volt_set(0)",
//@"reset_all.reset()",
//@"io.set(bit39=0;bit24=0;bit40=0;bit34=0;bit22=0;bit26=0;bit30=1;bit42=1;bit43=1)",
//@"Delay:2",
//@"io.set(bit30=0;bit42=0;bit43=0)",
//@"batt.volt_set(4200)",
//@"io.set(bit39=1;bit24=1;bit40=1;bit34=1;bit22=1;bit26=1)"],   //force diags on  1023 david change bit31 from 1 to 0 and change bit36=0

- (IBAction)send:(NSButton *)btn {
    NSString *cmd =self.cmdView.stringValue;
    if (cmd.length) {
         const char * const ret =executeAction_original(rpcController, cmd, ch_id);
        NSString *ret_str = [NSString stringWithUTF8String:ret];
//        [self showLog:ret_str];
//        executeAction(rpcController, cmd, ch_id);
    }
}


@end
