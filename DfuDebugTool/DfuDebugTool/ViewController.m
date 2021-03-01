//
//  ViewController.m
//  MixUpgrade
//
//  Created by Louis Luo on 2020/3/31.
//  Copyright © 2020 Suncode. All rights reserved.
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
    
    
    self.textView = [TextView cw_allocInitWithFrame:NSMakeRect(0, 0, 668, 258)];
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
        [Alert cw_RemindException:@"Error" Information:@"RPC is not ready!"];
        return;
    }
    NSString *cmd_on =@"io.set(bit36=1)";
    NSString *cmd_off =@"io.set(bit36=0)";
    if (btn.selectedSegment) {//kLED_UUT3BLUE :@"io.set(bit65=1;bit66=1;bit67=0)",
        
        executeAction(rpcController, cmd_on, ch_id);
        
        
    }else{
        executeAction(rpcController, cmd_off, ch_id);
     
        
    }
    [self.textView showLog:[FileManager cw_readFromFile:@"/vault/Atlas/FixtureLog/SunCode/SCFixture_Command.txt"]];
    
}



@end
