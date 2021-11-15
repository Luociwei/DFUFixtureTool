//
//  FixtureVC.m
//  DfuDebugTool
//
//  Created by ciwei luo on 2021/2/28.
//  Copyright © 2021 macdev. All rights reserved.
//

#import "FixtureVC.h"
//#import <CwGeneralManagerFrameWork/TextView.h>
//#import <CwGeneralManagerFrameWork/Task.h>
//#import <CwGeneralManagerFrameWork/Image.h>
//#import <CwGeneralManagerFrameWork/Alert.h>
//#import <CwGeneralManagerFrameWork/FileManager.h>
//#import <CwGeneralManagerFrameWork/NSString+Extension.h>
#import "DFUFixture.h"

#import "ExtensionConst.h"
@interface FixtureVC ()
//@property (unsafe_unretained) IBOutlet TextView *textView;
//@property (unsafe_unretained) IBOutlet NSTextView *logTextView;
@property (weak) IBOutlet NSButton *loopInBtn;
@property (weak) IBOutlet NSButton *loopOutBtn;

@property (weak) IBOutlet NSButton *slot4View;

@property (weak) IBOutlet NSButton *slot1View;
@property (weak) IBOutlet NSButton *slot3View;

@property (weak) IBOutlet NSButton *slot2View;

@property (unsafe_unretained) IBOutlet TextView *logTextView;

@property (weak) IBOutlet NSTextField *fwPathView;



//@property (nonatomic,strong)TextView *textView;

@property (weak) IBOutlet NSProgressIndicator *loopProgress;

@property (weak) IBOutlet NSImageView *inImage;
@property (weak) IBOutlet NSImageView *outImage;
@property (weak) IBOutlet NSImageView *upImage;
@property (weak) IBOutlet NSImageView *downImage;

@property (weak) IBOutlet NSPopUpButton *LedChannel;

@property (weak) IBOutlet NSPopUpButton *FanChannel;
@property (weak) IBOutlet NSPopUpButton *sendCmdChannel;
@property (weak) IBOutlet NSSlider *fanSilder;

@property (weak) IBOutlet NSTextField *CmdView1;
@property (weak) IBOutlet NSTextField *CmdView2;
@property (weak) IBOutlet NSTextField *CmdView3;
@property (weak) IBOutlet NSTextField *CmdView4;
@property (weak) IBOutlet NSTextField *snView;
@property (weak) IBOutlet NSPopUpButton *cmdType1;
@property (weak) IBOutlet NSPopUpButton *cmdType2;
@property (weak) IBOutlet NSPopUpButton *cmdType3;
@property (weak) IBOutlet NSPopUpButton *cmdType4;

@property (weak) IBOutlet NSPopUpButton *loopType;
@property (weak) IBOutlet NSTextField *loopCount;
@property (weak) IBOutlet NSTextField *loopInterval;

@property (weak) IBOutlet NSTextField *timeShow;

@property (weak) IBOutlet NSTabView *DebugTableView;

@property (weak) IBOutlet NSView *LogView;
//@property (strong,nonatomic)NSMutableString *mutLogString;



@end

@implementation FixtureVC{
    void *rpcController;
    BOOL isDiagsOn_Ch1;
    BOOL isDiagsOn_Ch2;
    BOOL isDiagsOn_Ch3;
    BOOL isDiagsOn_Ch4;
}
-(void)addItemsWithTitles:(NSArray *)titles popBtn:(NSPopUpButton *)popBtn{
    
    [popBtn removeAllItems];
    [popBtn addItemsWithTitles:titles];
}
-(void)showRunningTime:(NSString *)time{
    if (!time.length) {
        return;
    }
    [self.timeShow setStringValue:time];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [self addItemsWithTitles:@[@"All",@"UUT1",@"UUT2",@"UUT3",@"UUT4",@"Power"] popBtn:self.LedChannel];
    [self addItemsWithTitles:@[@"All",@"UUT1",@"UUT2",@"UUT3",@"UUT4"] popBtn:self.FanChannel];
    [self addItemsWithTitles:@[@"UUT1",@"UUT2",@"UUT3",@"UUT4"] popBtn:self.sendCmdChannel];
    [self addItemsWithTitles:@[@"Fixture Cmd",@"Diags Cmd"] popBtn:self.cmdType1];
    [self addItemsWithTitles:@[@"Fixture Cmd",@"Diags Cmd"] popBtn:self.cmdType2];
    [self addItemsWithTitles:@[@"Fixture Cmd",@"Diags Cmd"] popBtn:self.cmdType3];
    [self addItemsWithTitles:@[@"Fixture Cmd",@"Diags Cmd"] popBtn:self.cmdType4];

}


- (IBAction)loopClick:(NSButton *)btn {
    if (!self.isConnected) {
        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication."];
        return;
    }
    //加载Lua脚本
    
    if ([btn.title.lowercaseString containsString:@"in"]) {
        [self.loopProgress startAnimation:nil];
        self.loopInBtn.enabled = NO;
        
//        self.
    }else{
        [self.loopProgress stopAnimation:nil];
        self.loopInBtn.enabled = YES;
    }
    
    LSCValue *type =[LSCValue stringValue:self.loopType.titleOfSelectedItem];
    LSCValue *count =[LSCValue stringValue:self.loopCount.stringValue];
    LSCValue *interval =[LSCValue stringValue:self.loopInterval.stringValue];
    LSCValue *title =[LSCValue stringValue: btn.title];

    [self callLuaMethodWithName:@"loopClick" arguments:@[title,type,count,interval]];
}




- (IBAction)cleanClick:(NSButton *)sender {
    [self.logTextView clean];
}


- (IBAction)mixUpdate:(NSButton *)btn {
    
    LSCValue *fwPath =[LSCValue stringValue:self.fwPathView.stringValue];
    LSCValue *title =[LSCValue stringValue: btn.title];
    
    LSCValue *value=[self callLuaMethodWithName:@"mixFwUpdate" arguments:@[fwPath,title]];
}



//- (IBAction)save:(NSButton *)btn {
////    NSString *log = self.mutLogString;
////    [FileManager savePanel:^(NSString * _Nonnull path) {
////        [FileManager cw_writeToFile:path content:log];
////    }];
//
//    [self.logTextView saveLog];
//}



-(void)viewDidLayout{
    [super viewDidLayout];
//    self.textView.frame = self.LogView.bounds;
}


-(void)setImageWithImageView:(NSImageView *)imageView icon:(NSString *)icon{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([icon containsString:@"off"]) {
            [imageView setImage:[Image cw_getGrayCircleImage]];
        }else{
            [imageView setImage:[Image cw_getGreenCircleImage]];
        }
        //        [imageView setImage:[NSImage imageNamed:icon]];
        
    });
}
-(void)setRpcController:(void *)rpc{
    rpcController = rpc;
    
    if (rpcController) {
        [self.logTextView showLog:@"RPC connect successful!!!"];
    }else{
        [self.logTextView showLog:@"RPC connect Fail!!!"];
    }
}

-(void)setFixtureActionStautsLedLight:(BOOL)isOn status:(NSString *)status{
    NSString *icon_name = isOn ? @"state_on" : @"state_off";
    NSImageView *slot_imageView = self.inImage ;
    if ([status isEqualToString:@"in"]) {
        slot_imageView= self.inImage ;
    }else if ([status isEqualToString:@"out"]){
        slot_imageView= self.outImage ;
    }else if ([status isEqualToString:@"up"]){
        slot_imageView= self.upImage ;
    }else if ([status isEqualToString:@"down"]){
        slot_imageView= self.downImage ;
    }
    [self setImageWithImageView:slot_imageView icon:icon_name];
}

- (IBAction)actionBtnClick:(NSButton *)btn {
    if (!self.isConnected) {
        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!!Pls click top left button to connect RPC communication."];
        return;
    }
    
    
    LSCValue *title =[LSCValue stringValue: btn.title];
    
    LSCValue *value=[self callLuaMethodWithName:@"actionClick" arguments:@[title]];
    
    NSLog(@"result = %@", [value toString]);

}

- (IBAction)ledClick:(NSButton *)btn{
    if (!self.isConnected) {
        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication."];
        return;
    }
    //加载Lua脚本
    
    LSCValue *channel =[LSCValue stringValue:self.LedChannel.titleOfSelectedItem];
    LSCValue *title =[LSCValue stringValue: btn.title];
    
    LSCValue *value=[self callLuaMethodWithName:@"ledClick" arguments:@[channel,title]];
    
    NSLog(@"result = %@", [value toString]);
    
}


-(LSCValue *)callLuaMethodWithName:(NSString *)methodName arguments:(NSArray<LSCValue *> *)arguments{
    
    // 加载Lua脚本
    
    NSString *LuaScriptPath = [[NSString cw_getResourcePath] stringByAppendingPathComponent:@"LuaScript"];
    
    NSArray *pathArr = [FileManager cw_findPathWithfFileName:@"SequenceControl.lua" dirPath:LuaScriptPath deepFind:YES];
    if (!pathArr.count) {
        return nil;
    }
    NSString *SequenceControlPath =pathArr[0];
    
    [self.context evalScriptFromFile:SequenceControlPath];
    
    LSCValue *value= [self.context callMethodWithName:methodName
                                            arguments:arguments];
    
    return value;
    
}



- (IBAction)fanClick:(NSButton *)btn {
    if (!self.isConnected) {
        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
        return;
    }
    NSString *type = self.FanChannel.titleOfSelectedItem.lowercaseString;
    NSInteger fan_speed = self.fanSilder.intValue;
    LSCValue *channel =[LSCValue stringValue:type];
    LSCValue *btnTitle =[LSCValue stringValue: btn.title];
    LSCValue *speed =[LSCValue integerValue:fan_speed];
    
    LSCValue *value=[self callLuaMethodWithName:@"fanClick" arguments:@[btnTitle,channel,speed]];
    
    NSLog(@"result = %@", [value toString]);
 
    
}

-(void)printLog:(NSString *)log{
    [self.logTextView showLog:log];
}

//- (IBAction)get_fan_click:(NSButton *)btn {
//    if (!self.isConnected) {
//        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
//        return;
//    }
//    NSString *type = self.FanChannel.titleOfSelectedItem.lowercaseString;
////    int fan_speed = self.fanSilder.intValue;
//    int site = 0;
//    if ([type isEqualToString:@"uut1"]) {
//        site = 1;
//    }else if ([type isEqualToString:@"uut2"]){
//        site = 2;
//    }else if ([type isEqualToString:@"uut3"]){
//        site = 3;
//    }else if ([type isEqualToString:@"uut4"]){
//        site = 4;
//    }
//
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"CmdsList.json" ofType:nil];
//    NSDictionary *cmd_dict = [FileManager cw_serializationWithJsonFilePath:path];
//    if (cmd_dict==nil) {
//        return;
//    }
//
//    int index = site;
//    int count = site;
//    if (site == 0) {
//        index = 1;
//        count = 4;
//    }
//
//    NSArray *cmds = [cmd_dict objectForKey:@"get_fan_speed"];
//    for (int j = index ; j<=count; j++) {
//        for (int i =0; i<cmds.count; i++) {
//            NSString *cmd = cmds[i];
//            if ([cmd containsString:@"?"]) {
//                //            cmd =[NSString stringWithFormat:@"%@(4000,%d)",@"fan.speed_set",100-fan_speed];
//                NSString *site_str = [NSString stringWithFormat:@"%d",j];
//                cmd = [cmd stringByReplacingOccurrencesOfString:@"?" withString:site_str];
//            }
//            [self.logTextView showLog:[NSString stringWithFormat:@"site %d--[cmd] %@\n",j,cmd]];
//            NSString *ret =[NSString stringWithUTF8String:executeAction_original(rpcController,cmd,j)];
//            NSString *log = [NSString stringWithFormat:@"[result] %@",ret];
//            [self.logTextView showLog:log];
//        }
//    }
//
//
//}


- (IBAction)send:(NSButton *)btn {
//    if (!self.isConnected) {
//        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
//        return;
//    }
    NSString *type = self.DebugTableView.selectedTabViewItem.label.lowercaseString;
    NSTextField *cmdView = nil;
    NSPopUpButton *cmdPopBtn = nil;
    int site = 1;
    if ([type isEqualToString:@"uut1"]) {
        site = 1;
        cmdView = self.CmdView1;
        cmdPopBtn = self.cmdType1;
    }else if ([type isEqualToString:@"uut2"]){
        site = 2;
        cmdView = self.CmdView2;
        cmdPopBtn = self.cmdType2;
    }else if ([type isEqualToString:@"uut3"]){
        site = 3;
        cmdView = self.CmdView3;
        cmdPopBtn = self.cmdType3;
    }else if ([type isEqualToString:@"uut4"]){
        site = 4;
        cmdView = self.CmdView4;
        cmdPopBtn = self.cmdType4;
    }
    NSString *cmd =cmdView.stringValue;
    NSString *cmd_type = cmdPopBtn.titleOfSelectedItem.lowercaseString;
    if (cmd.length) {
        
        if ([cmd_type containsString:@"diags"]) {
            
            NSString *ret = [self uartWrite:cmd site:site];
            if (ret.length) {

                [self.logTextView showLog:[NSString stringWithFormat:@"site %d--[result] %@\n",site,ret]];

            }
            
        }else{
            
            const char * const ret =executeAction_original(rpcController, cmd, site);
            NSString *ret_str = [NSString stringWithUTF8String:ret];
            if (ret_str.length) {
                
                [self.logTextView showLog:[NSString stringWithFormat:@"%@--site %d",ret_str,site]];
            }
        }

        //        executeAction(rpcController, cmd, ch_id);
    }
    
}



-(NSString *)uartWriteAndRead:(NSString *)cmd site:(int)site{
    if (!self.isConnected) {
        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
        return @"";
    }
    NSMutableString *mutStr = [[NSMutableString alloc]initWithString:@""];
    NSString *diags_cmd = [NSString stringWithFormat:@"uart_test.write_read(%@)",cmd];

    const char * const ret =executeAction_original(rpcController, diags_cmd, site);
    NSString *ret_str = [NSString stringWithUTF8String:ret];
    [mutStr appendString:ret_str];
    
    while (ret_str.length) {
        const char * const ret =executeAction_original(rpcController, @"uart_test.read()", site);
        ret_str = [NSString stringWithUTF8String:ret];
        if (ret_str.length) {
            [mutStr appendString:ret_str];
        }
        [NSThread sleepForTimeInterval:0.3];
    }
    return mutStr;
}

-(NSString *)uartWrite:(NSString *)cmd site:(int)site{
    if (!self.isConnected) {
        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
        return @"";
    }
    [self.logTextView showLog:[NSString stringWithFormat:@"site %d-- [diags cmd] %@\n",site,cmd]];
    NSString *diags_cmd = [NSString stringWithFormat:@"uart_test.write(%@\n)",cmd];
    
    const char * const ret =executeAction_original(rpcController, diags_cmd, site);
    NSString *ret_str = [NSString stringWithUTF8String:ret];
    if (!ret_str.length) {
        ret_str = @"";
    }
    return ret_str;
}



- (IBAction)othersTest:(NSSegmentedControl *)btn {
    //    NSString *type = self.sendCmdChannel.titleOfSelectedItem.lowercaseString;
    if (!self.isConnected) {
        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
        return;
    }
    NSString *type = self.DebugTableView.selectedTabViewItem.label.lowercaseString;
    
    int site = 1;
    if ([type isEqualToString:@"uut1"]) {
        site = 1;
    }else if ([type isEqualToString:@"uut2"]){
        site = 2;
    }else if ([type isEqualToString:@"uut3"]){
        site = 3;
    }else if ([type isEqualToString:@"uut4"]){
        site = 4;
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"CmdsList.json" ofType:nil];
    NSDictionary *cmd_list = [FileManager cw_serializationWithJsonFilePath:path];
    if (cmd_list==nil) {
        return;
    }
    
    
    NSArray *cmds =btn.selectedSegment ? [cmd_list objectForKey:@"others_test_on"] : [cmd_list objectForKey:@"others_test_off"];
    
    for (int i =0; i<cmds.count; i++) {
        NSString *cmd_str =cmds[i];
        [self.logTextView showLog:[NSString stringWithFormat:@"[cmd] %@\n",cmd_str]];
        const char * const ret = executeAction_original(rpcController,cmd_str,site);
        NSString *ret_str = [NSString stringWithUTF8String:ret];
        [self.logTextView showLog:[NSString stringWithFormat:@"site %d--result:%@\n",site,ret_str]];
    }
}


- (IBAction)forceDFU:(NSSegmentedControl *)btn {
//    NSString *type = self.sendCmdChannel.titleOfSelectedItem.lowercaseString;
    if (!self.isConnected) {
        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
        return;
    }
    NSString *type = self.DebugTableView.selectedTabViewItem.label.lowercaseString;
    
    int site = 1;
    if ([type isEqualToString:@"uut1"]) {
        site = 1;
    }else if ([type isEqualToString:@"uut2"]){
        site = 2;
    }else if ([type isEqualToString:@"uut3"]){
        site = 3;
    }else if ([type isEqualToString:@"uut4"]){
        site = 4;
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"CmdsList.json" ofType:nil];
    NSDictionary *cmd_list = [FileManager cw_serializationWithJsonFilePath:path];
    if (cmd_list==nil) {
        return;
    }

    
    NSArray *cmds =btn.selectedSegment ? [cmd_list objectForKey:@"force_dfu_on"] : [cmd_list objectForKey:@"force_dfu_off"];
    
    for (int i =0; i<cmds.count; i++) {
        NSString *cmd_str =cmds[i];
        [self.logTextView showLog:[NSString stringWithFormat:@"[cmd] %@\n",cmd_str]];
        const char * const ret = executeAction_original(rpcController,cmd_str,site);
        NSString *ret_str = [NSString stringWithUTF8String:ret];
        [self.logTextView showLog:[NSString stringWithFormat:@"site %d--result:%@\n",site,ret_str]];
    }
}

- (IBAction)enterDIagsClick:(NSSegmentedControl *)btn {
//    NSString *type = self.sendCmdChannel.titleOfSelectedItem.lowercaseString;
//    if (!self.isConnected) {
//        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
//        return;
//    }
//    
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"CmdsList.json" ofType:nil];
//    NSDictionary *cmd_list = [FileManager cw_serializationWithJsonFilePath:path];
//    if (cmd_list==nil) {
//        return;
//    }
//    NSArray *cmds =btn.selectedSegment ? [cmd_list objectForKey:@"force_diags_on"] : [cmd_list objectForKey:@"force_diags_off"];
//    
//    NSString *type = self.DebugTableView.selectedTabViewItem.label.lowercaseString;
//    
//    int site = 1;
//    if ([type isEqualToString:@"uut1"]) {
//        site = 1;
//        isDiagsOn_Ch1 = btn.selectedSegment;
//    }else if ([type isEqualToString:@"uut2"]){
//        site = 2;
//        isDiagsOn_Ch2 = btn.selectedSegment;
//    }else if ([type isEqualToString:@"uut3"]){
//        site = 3;
//        isDiagsOn_Ch3 = btn.selectedSegment;
//    }else if ([type isEqualToString:@"uut4"]){
//        site = 4;
//        isDiagsOn_Ch4 = btn.selectedSegment;
//    }
//
//
//    for (int i =0; i<cmds.count; i++) {
//        NSString *cmd_str =cmds[i];
//        [self.logTextView showLog:[NSString stringWithFormat:@"site %d--[cmd] %@\n",site,cmd_str]];
//        const char * const ret = executeAction_original(rpcController,cmd_str,site);
//        NSString *ret_str = [NSString stringWithUTF8String:ret];
//        [self.logTextView showLog:[NSString stringWithFormat:@"site %d--[result]%@\n",site,ret_str]];
//    }
}

- (IBAction)reset:(NSButton *)btn {
    //    NSString *type = self.sendCmdChannel.titleOfSelectedItem.lowercaseString;
//    if (!self.isConnected) {
//        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
//        return;
//    }
//    NSString *type = self.DebugTableView.selectedTabViewItem.label.lowercaseString;
//
//    int site = 1;
//    if ([type isEqualToString:@"uut1"]) {
//        site = 1;
//    }else if ([type isEqualToString:@"uut2"]){
//        site = 2;
//    }else if ([type isEqualToString:@"uut3"]){
//        site = 3;
//    }else if ([type isEqualToString:@"uut4"]){
//        site = 4;
//    }
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"CmdsList.json" ofType:nil];
//    NSDictionary *cmd_list = [FileManager cw_serializationWithJsonFilePath:path];
//    if (cmd_list==nil) {
//        return;
//    }
//    NSArray *cmds =[cmd_list objectForKey:@"reset"];
//
//    for (int i =0; i<cmds.count; i++) {
//        NSString *cmd_str =cmds[i];
//        [self.logTextView showLog:[NSString stringWithFormat:@"[cmd] %@\n",cmd_str]];
//        const char * const ret = executeAction_original(rpcController,cmd_str,site);
//        NSString *ret_str = [NSString stringWithUTF8String:ret];
//        [self.logTextView showLog:[NSString stringWithFormat:@"site %d--result:%@\n",site,ret_str]];
//    }
}




- (IBAction)snWriteOrRead:(NSButton *)btn {//
    if (!self.isConnected) {
        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
        return;
    }
//        NSString *cmd_str =self.snView.stringValue;
//        if (cmd_str.length != 19) {
//            [Alert cw_RemindException:@"Error" Information:@"Pls check sn length!"];
//            return;
//        }
//
    LSCValue *sn =[LSCValue stringValue:[NSString stringWithFormat:@"%@",self.snView.stringValue]];
    LSCValue *btnTitle =[LSCValue stringValue: btn.title];
    
    
    LSCValue *value=[self callLuaMethodWithName:@"fixtureSnWriteOrReadClick" arguments:@[btnTitle,sn]];
    
    NSLog(@"result = %@", [value toString]);
    

//    NSString *cmd = [NSString stringWithFormat:@"eeprom.write_string(0,%@)",cmd_str];
////    [self.logTextView showLog:[NSString stringWithFormat:@"[cmd] %@\n",cmd]];
//    const char * const ret = executeAction_original(rpcController,cmd,1);
//    NSString *ret_str = [NSString stringWithUTF8String:ret];
//    [self.logTextView showLog:[NSString stringWithFormat:@"result:%@\n",ret_str]];
}

//- (IBAction)loopClick:(NSButton *)btn {
//
//    [self.catchFwVc showViewAsSheetOnViewController:self];
//}

//-(void)setDutStautsLedLight:(BOOL)isOn channel:(int)channel{
//    NSString *icon_name = isOn ? @"state_on" : @"state_off";
//    NSImageView *slot_imageView = self.slotImage1 ;
//    if (channel == 1) {
//        slot_imageView= self.slotImage1;
//    }else if (channel == 2){
//        slot_imageView= self.slotImage2;
//    }else if (channel == 3){
//        slot_imageView= self.slotImage3;
//    }else if (channel == 4){
//        slot_imageView= self.slotImage4;
//    }
//    [self setImageWithImageView:slot_imageView icon:icon_name];
//}


//
//-(NSViewController *)catchFwVc{
//    if (!_catchFwVc) {
//        _catchFwVc =[[ActionLoop alloc]init];
//    }
//    return _catchFwVc;
//}

//-(BOOL)isEmptyDut{
//
//    if (!self.isConnected) {
//        return NO;
//    }
//
//    BOOL isOk1 = is_board_detected(rpcController, 1);
//    BOOL isOk2 = is_board_detected(rpcController, 1);
//    BOOL isOk3 = is_board_detected(rpcController, 1);
//    BOOL isOk4 = is_board_detected(rpcController, 1);
//    BOOL isOk =!isOk1&&!isOk2&&!isOk3&&!isOk4;
//    return isOk;
//}


//-(void)dealloc{
//    //    NSString *type = self.sendCmdChannel.titleOfSelectedItem.lowercaseString;
//    if (!self.isConnected) {
//        
//        return;
//    }
//
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"CmdsList.json" ofType:nil];
//    NSDictionary *cmd_list = [FileManager cw_serializationWithJsonFilePath:path];
//    if (cmd_list==nil) {
//        return;
//    }
//    NSArray *cmds =[cmd_list objectForKey:@"reset"];
//    for (int j = 1; j<=4; j++) {
//        for (int i =0; i<cmds.count; i++) {
//            NSString *cmd_str =cmds[i];
//            [self.logTextView showLog:[NSString stringWithFormat:@"[cmd] %@\n",cmd_str]];
//            const char * const ret = executeAction_original(rpcController,cmd_str,j);
//            NSString *ret_str = [NSString stringWithUTF8String:ret];
//            [self.logTextView showLog:[NSString stringWithFormat:@"result:%@\n",ret_str]];
//        }
//    }
//    
//
//}


//-(void)getDutSate{
//
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        while (1) {
//
//            if (![self getSlotState:1]) {
//                [self setImageWithImageView:self.slotImage1 icon:@"state_off"];
//
//            }else{
//                [self setImageWithImageView:self.slotImage1 icon:@"state_on"];
//
//
//            }
//            [NSThread sleepForTimeInterval:0.3];
//            if (![self getSlotState:2]) {
//
//                [self setImageWithImageView:self.slotImage2 icon:@"state_off"];
//
//            }else{
//
//                [self setImageWithImageView:self.slotImage2 icon:@"state_on"];
//
//
//            }
//            [NSThread sleepForTimeInterval:0.3];
//            if (![self getSlotState:3]) {
//
//                [self setImageWithImageView:self.slotImage3 icon:@"state_off"];
//
//            }else{
//
//                [self setImageWithImageView:self.slotImage3 icon:@"state_on"];
//
//
//            }
//            [NSThread sleepForTimeInterval:0.3];
//            if (![self getSlotState:4]) {
//
//                [self setImageWithImageView:self.slotImage4 icon:@"state_off"];
//            }else{
//
//                [self setImageWithImageView:self.slotImage4 icon:@"state_on"];
//
//            }
//            [NSThread sleepForTimeInterval:0.3];
//
//        }
//
//    });
//}


//is_board_detected
//-(BOOL)getSlotState:(int)slot{
//
//    if (!self.isConnected) {
//        return NO;
//    }
//    BOOL isOk = is_board_detected(rpcController, slot);
//
//    return isOk;
//}





//- (IBAction)snRead:(NSButton *)btn {
//    if (!self.isConnected) {
//        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
//        return;
//    }
//    NSString *cmd = [NSString stringWithFormat:@"eeprom.read_string(0,19)"];
////    [self.logTextView showLog:[NSString stringWithFormat:@"[cmd] %@\n",cmd]];
//    const char * const ret = executeAction_original(rpcController,cmd,1);
//    NSString *ret_str = [NSString stringWithUTF8String:ret];
//    [self.logTextView showLog:[NSString stringWithFormat:@"[result] %@\n",ret_str]];
//}


//-(void)getActionSate{
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        while (1) {
//
//            if (!self.isConnected) {
//                [NSThread sleepForTimeInterval:2];
//                continue;
//            }
////
//            const char * const ret =executeAction_original(rpcController, @"fixturecontrol.get_fixture_status()", 1);
//            NSString *ret_str = [NSString stringWithUTF8String:ret];
//            if ([ret_str.lowercaseString containsString:@"in"]) {
//                [self setImageWithImageView:self.inImage icon:@"state_on"];
//                [self setImageWithImageView:self.outImage icon:@"state_off"];
//                [self setImageWithImageView:self.upImage icon:@"state_on"];
//                [self setImageWithImageView:self.downImage icon:@"state_off"];
//            }else if([ret_str.lowercaseString containsString:@"out"]) {
//                [self setImageWithImageView:self.inImage icon:@"state_off"];
//                [self setImageWithImageView:self.outImage icon:@"state_on"];
//                [self setImageWithImageView:self.upImage icon:@"state_on"];
//                [self setImageWithImageView:self.downImage icon:@"state_off"];
//
//
//            }else if([ret_str.lowercaseString containsString:@"down"]) {
//                [self setImageWithImageView:self.inImage icon:@"state_on"];
//                [self setImageWithImageView:self.outImage icon:@"state_off"];
//                [self setImageWithImageView:self.upImage icon:@"state_off"];
//                [self setImageWithImageView:self.downImage icon:@"state_on"];
//
//
//            }else{
//                [self setImageWithImageView:self.inImage icon:@"state_off"];
//                [self setImageWithImageView:self.outImage icon:@"state_off"];
//                [self setImageWithImageView:self.upImage icon:@"state_off"];
//                [self setImageWithImageView:self.downImage icon:@"state_off"];
//            }
//            [NSThread sleepForTimeInterval:1.5];
//
//        }
//
//
//    });
//
//}

//- (IBAction)ledClick:(NSButton *)btn{
    //    if (!self.isConnected) {
    //        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
    //        return;
    //    }
    //
    ////    NSString *path =[[NSString cw_getResourcePath] stringByAppendingPathComponent:file];
    //    NSString *path = [[NSBundle mainBundle] pathForResource:@"CmdsList.json" ofType:nil];
    //    NSDictionary *cmd = [FileManager cw_serializationWithJsonFilePath:path];
    //    if (cmd==nil) {
    //        return;
    //    }
    //    NSString *title_btn = btn.title.lowercaseString;
    //    NSString *type = self.LedChannel.titleOfSelectedItem.lowercaseString;
    //    NSString *ledKey = [NSString stringWithFormat:@"%@_led_%@",type,title_btn];
    //    NSArray *ledCmds = [cmd objectForKey:ledKey];
    //
    //    int site = 0;
    //    if ([type isEqualToString:@"uut1"]||[type isEqualToString:@"power"]) {
    //        site = 1;
    //    }else if ([type isEqualToString:@"uut2"]){
    //        site = 2;
    //    }else if ([type isEqualToString:@"uut3"]){
    //        site = 3;
    //    }else if ([type isEqualToString:@"uut4"]){
    //        site = 4;
    //    }
    //    int index = site;
    //    int count = site;
    //    if (site == 0) {
    //        index = 1;
    //        count = 5;
    //    }
    //    for (int j = index ; j<=count; j++) {
    //        if (site ==0) {
    //            if (j==5) {
    //                ledKey = [NSString stringWithFormat:@"power_led_%@",title_btn];
    //                ledCmds = [cmd objectForKey:ledKey];
    //            }else{
    //                ledKey = [NSString stringWithFormat:@"uut%d_led_%@",j,title_btn];
    //                ledCmds = [cmd objectForKey:ledKey];
    //            }
    //
    //        }
    //        int site_index = j;
    //        for (int i =0; i<ledCmds.count; i++) {
    //
    //            if (j==5) {
    //                site_index = 1;
    //            }
    //            NSString *cmd_str =ledCmds[i];
    //            [self.logTextView showLog:[NSString stringWithFormat:@"site %d--[cmd] %@\n",site_index,cmd_str]];
    //            const char * const ret = executeAction_original(rpcController,cmd_str,site_index);
    //            NSString *ret_str = [NSString stringWithUTF8String:ret];
    //            [self.logTextView showLog:[NSString stringWithFormat:@"[result] %@\n",ret_str]];
    //        }
    //    }
    //
    
    
//}

//- (IBAction)actionBtnClick:(NSButton *)btn {

    //    NSString *ret_str = @"";
    //    if ([btn.title.lowercaseString containsString:@"release"]) {
    ////        NSLog(@"fixture staute:%d--",fixture_open(rpcController, 1)) ;
    //        [self.logTextView showLog:[NSString stringWithFormat:@"[cmd] fixturecontrol.release()\n"]];
    //        const char * const ret =executeAction_original(rpcController, @"fixturecontrol.release()", 1);
    //        ret_str = [NSString stringWithUTF8String:ret];
    //
    //
    //    }else if([btn.title.lowercaseString containsString:@"press"]){
    ////        if ([self isEmptyDut]) {
    ////            [Alert cw_RemindException:@"Error" Information:@"No product detected!Pls put in the product."];
    ////        }
    ////        NSLog(@"fixture staute:%d--",fixture_close(rpcController, 1));
    //        [self.logTextView showLog:[NSString stringWithFormat:@"[cmd] fixturecontrol.press()\n"]];
    //        const char * const ret =executeAction_original(rpcController, @"fixturecontrol.press()", 1);
    //        ret_str = [NSString stringWithUTF8String:ret];
    //    }
    //    else if([btn.title.lowercaseString containsString:@"up"]){//@[@"fixturecontrol.release()"]
    //        [self.logTextView showLog:[NSString stringWithFormat:@"[cmd] fixturecontrol.Up()\n"]];
    //        const char * const ret =executeAction_original(rpcController, @"fixturecontrol.Up()", 1);
    //        ret_str = [NSString stringWithUTF8String:ret];
    //    }else if([btn.title.lowercaseString containsString:@"in"]){
    //        [self.logTextView showLog:[NSString stringWithFormat:@"[cmd] fixturecontrol.In()\n"]];
    //        const char * const ret =executeAction_original(rpcController, @"fixturecontrol.In()", 1);
    //        ret_str = [NSString stringWithUTF8String:ret];
    //    }else if([btn.title.lowercaseString containsString:@"down"]){
    //        [self.logTextView showLog:[NSString stringWithFormat:@"[cmd] fixturecontrol.Down()\n"]];
    //        const char * const ret =executeAction_original(rpcController, @"fixturecontrol.Down()", 1);
    //        ret_str = [NSString stringWithUTF8String:ret];
    //    }else if([btn.title.lowercaseString containsString:@"out"]){
    //        [self.logTextView showLog:[NSString stringWithFormat:@"[cmd] fixturecontrol.Out()\n"]];
    //        const char * const ret =executeAction_original(rpcController, @"fixturecontrol.Out()", 1);
    //        ret_str = [NSString stringWithUTF8String:ret];
    //    }
    //
    //    [self.logTextView showLog:[NSString stringWithFormat:@"[result] %@\n",ret_str]];
//}

//- (IBAction)fanClick:(NSButton *)btn {
//        if (!self.isConnected) {
//            [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
//            return;
//        }
//
//    NSString *type = self.FanChannel.titleOfSelectedItem.lowercaseString;
//    NSInteger fan_speed = self.fanSilder.intValue;
//    int site = 0;
//    if ([type isEqualToString:@"uut1"]) {
//        site = 1;
//    }else if ([type isEqualToString:@"uut2"]){
//        site = 2;
//    }else if ([type isEqualToString:@"uut3"]){
//        site = 3;
//    }else if ([type isEqualToString:@"uut4"]){
//        site = 4;
//    }
//
    //
    //    NSString *path = [[NSBundle mainBundle] pathForResource:@"CmdsList.json" ofType:nil];
    //    NSDictionary *cmd_dict = [FileManager cw_serializationWithJsonFilePath:path];
    //    if (cmd_dict==nil) {
    //        return;
    //    }
    //
    //    NSArray *cmds = [cmd_dict objectForKey:@"set_fan_speed"];
    //
    //    int index = site;
    //    int count = site;
    //    if (site == 0) {
    //        index = 1;
    //        count = 4;
    //    }
    //    for (int j = index ; j<=count; j++) {
    //        for (int i =0; i<cmds.count; i++) {
    //            NSString *cmd = cmds[i];
    //            if ([cmd containsString:@"?"]) {
    //                //            cmd =[NSString stringWithFormat:@"%@(4000,%d)",@"fan.speed_set",100-fan_speed];
    //                NSString *speed = [NSString stringWithFormat:@"%d",100-fan_speed];
    //                cmd = [cmd stringByReplacingOccurrencesOfString:@"?" withString:speed];
    //            }
    //            [self.logTextView showLog:[NSString stringWithFormat:@"site %d--[cmd] %@\n",j,cmd]];
    //            NSString *ret =[NSString stringWithUTF8String:executeAction_original(rpcController,cmd,j)];
    //            NSString *log = [NSString stringWithFormat:@"[result] %@",ret];
    //            [self.logTextView showLog:log];
    //        }
    //    }
    //
    //
    //
    //    if (fan_speed==0) {
    //        for (int j = index ; j<=count; j++) {
    //            NSString *ret =[NSString stringWithUTF8String:executeAction_original(rpcController,@"io.set(bit29=0)",j)];
    //            NSString *log = [NSString stringWithFormat:@"site %d--[cmd] %@, [result] %@",j,@"io.set(bit29=0)",ret];
    //            [self.logTextView showLog:log];
    //        }
    //
    //    }
    
//}


//-(void)diagsRepose{
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"CmdsList.json" ofType:nil];
//    NSDictionary *cmd_dict = [FileManager cw_serializationWithJsonFilePath:path];
//    if (cmd_dict==nil) {
//        return;
//    }
//    NSString *cmd = @"uart_test.read()";
//    //    NSArray *cmds = [cmd_dict objectForKey:@"uart_wr"];
//    //    if (cmds.count) {
//    //        cmd = cmds[0];
//    //    }
//
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        //        NSMutableString *mutStr = [[NSMutableString alloc]initWithString:@""];
//        while (1) {
//            {
//
//
//                if (rpcController == nil) {
//                    [NSThread sleepForTimeInterval:2];
//                    continue;
//                }
//                if (isDiagsOn_Ch1) {
//                    const char * const ret1 =executeAction_original(rpcController,cmd, 1);
//                    NSString *ret_str1 = [NSString stringWithUTF8String:ret1];
//                    if (ret_str1.length) {
//                        //                    [mutStr appendString:ret_str1];
//                        [self.logTextView showLog:ret_str1];
//                    }
//
//                }
//
//                [NSThread sleepForTimeInterval:0.3];
//
//                if (isDiagsOn_Ch2) {
//                    const char * const ret2 =executeAction_original(rpcController,cmd, 2);
//                    NSString *ret_str2 = [NSString stringWithUTF8String:ret2];
//                    if (ret_str2.length) {
//                        //                    [mutStr appendString:ret_str2];
//                        [self.logTextView showLog:ret_str2];
//                    }
//
//                }
//
//                [NSThread sleepForTimeInterval:0.3];
//
//                if (isDiagsOn_Ch3) {
//                    const char * const ret3 =executeAction_original(rpcController,cmd, 3);
//                    NSString *ret_str3 = [NSString stringWithUTF8String:ret3];
//                    if (ret_str3.length) {
//                        //                    [mutStr appendString:ret_str3];
//                        [self.logTextView showLog:ret_str3];
//                    }
//
//                }
//
//                [NSThread sleepForTimeInterval:0.3];
//
//                if (isDiagsOn_Ch4) {
//                    const char * const ret4 =executeAction_original(rpcController,cmd, 4);
//                    NSString *ret_str4 = [NSString stringWithUTF8String:ret4];
//                    if (ret_str4.length) {
//                        //                    [mutStr appendString:ret_str4];
//                        [self.logTextView showLog:ret_str4];
//                    }
//                    //                [NSThread sleepForTimeInterval:0.5];
//
//                }
//
//                [NSThread sleepForTimeInterval:0.3];
//
//
//            }
//        }
//
//    });
//}


@end
