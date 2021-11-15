//
//  DebugTestVC.m
//  DFU_DebugTool
//
//  Created by ciwei luo on 2021/9/18.
//  Copyright © 2021 macdev. All rights reserved.
//

#import "DutDebugVC.h"

@interface DutDebugVC ()

@property (weak) IBOutlet NSButton *btnSlot1;
@property (weak) IBOutlet NSButton *btnSlot2;
@property (weak) IBOutlet NSButton *btnSlot3;
@property (weak) IBOutlet NSButton *btnSlot4;
@property (weak) IBOutlet NSSegmentedControl *btnForceDFU;
//@property (weak) IBOutlet NSSegmentedControl *btnOther;
@property (weak) IBOutlet NSSegmentedControl *btnForceDiags;
@property (weak) IBOutlet NSTextField *viewFixtureCmd;
@property (weak) IBOutlet NSTextField *viewDutCmd;
@property (weak) IBOutlet NSButton *btnFixtureSend;
@property (weak) IBOutlet NSButton *btnDutSend;
@property (weak) IBOutlet NSTableView *itemsTableView;

@property (unsafe_unretained) IBOutlet TextView *viewFixtureSlot1Log;
@property (unsafe_unretained) IBOutlet TextView *viewDutSlot1Log;
@property (unsafe_unretained) IBOutlet TextView *viewFixtureSlot2Log;
@property (unsafe_unretained) IBOutlet TextView *viewDutSlot2Log;
@property (unsafe_unretained) IBOutlet TextView *viewFixtureSlot3Log;
@property (unsafe_unretained) IBOutlet TextView *viewDutSlot3Log;
@property (unsafe_unretained) IBOutlet TextView *viewFixtureSlot4Log;
@property (unsafe_unretained) IBOutlet TextView *viewDutSlot4Log;
@property(nonatomic,strong)NSMutableDictionary *slotsSelected;
@property(nonatomic,strong)TableDataDelegate *tableDataDelegate;

@property (weak) IBOutlet NSImageView *slotImage1;
@property (weak) IBOutlet NSImageView *slotImage2;
@property (weak) IBOutlet NSImageView *slotImage3;
@property (weak) IBOutlet NSImageView *slotImage4;


@property (weak) IBOutlet NSPopUpButton *scriptTestBtn;


@end

@implementation DutDebugVC




- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
//    self.cmdData = [[NSMutableArray alloc]init];

    [self getScriptTestList];
    self.tableDataDelegate.owner = self.itemsTableView;
    
    LSCValue *value = [self luaRegisterWithMethodName:@"appDidFinishLaunched" arguments:nil];
    
        NSArray *cmds = [value toArray];
        if (cmds.count) {
            self.cmdsData = cmds;
            
            [_tableDataDelegate reloadTableViewWithData:cmds];
        }
    
    
    //
    
}

//-(void)fixtureMoreClicked
- (IBAction)fixtureMore:(NSButton *)btn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(fixtureMoreClicked)]) {
        
        [self.delegate fixtureMoreClicked];
   
    }
}
//- (IBAction)scriptTestBtnClick:(NSPopUpButton *)bnt {
//    [self getScriptTestList];
//}

-(void)getScriptTestList{
    NSString *LuaScriptPath = [[NSString cw_getResourcePath] stringByAppendingPathComponent:@"LuaScript/ScriptTestFiles"];
    
    NSArray *pathArr = [FileManager cw_getFilenamelistOfType:@"json" fromDirPath:LuaScriptPath];
    
    [self.scriptTestBtn removeAllItems];
    [self.scriptTestBtn addItemsWithTitles:pathArr];
}
- (IBAction)openLuaScript:(id)sender {
    
    NSString *path = [NSString cw_getResourcePath];
    [Task cw_openFileWithPath:[path stringByAppendingPathComponent:@"LuaScript"]];
}

- (IBAction)fixtureControl:(NSButton *)btn {
    {
        if (!self.isConnected) {
            [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!!Pls click top left button to connect RPC communication."];
            return;
        }
        
        
        LSCValue *title =[LSCValue stringValue: btn.title];
        
        LSCValue *value=[self callLuaMethodWithName:@"actionClick" arguments:@[title]];
        
        NSLog(@"result = %@", [value toString]);
        
    }
}



-(LSCValue *)luaRegisterWithMethodName:(NSString *)methodName arguments:(NSArray<LSCValue *> *)arguments{
    
    // 加载Lua脚本
    
    NSString *LuaScriptPath = [[NSString cw_getResourcePath] stringByAppendingPathComponent:@"LuaScript"];
    
    NSArray *pathArr = [FileManager cw_findPathWithfFileName:@"SequenceControl.lua" dirPath:LuaScriptPath deepFind:YES];
    if (!pathArr.count) {
        return nil;
    }
    [self.context evalScriptFromFile:pathArr[0]];
    
    LSCValue *value= [self.context callMethodWithName:methodName
                                            arguments:arguments];
    
    return value;
    
}


//-(void)setCmdsData:(NSArray<NSDictionary *> *)cmdsData{
//    _cmdsData = cmdsData;
////    self.
//    [_tableDataDelegate reloadTableViewWithData:cmdsData];
//}


- (IBAction)saveAllLog:(NSButton *)btn {
    
    NSString *path = [[NSString cw_getDesktopPath] stringByAppendingPathComponent:@"DFU_Debug_Logs"];
    [FileManager cw_createFile:path isDirectory:YES];
    [FileManager cw_writeToFile:[path stringByAppendingPathComponent:@"DUT1.txt"] content:self.viewDutSlot1Log.string];
    [FileManager cw_writeToFile:[path stringByAppendingPathComponent:@"DUT2.txt"] content:self.viewDutSlot2Log.string];
    [FileManager cw_writeToFile:[path stringByAppendingPathComponent:@"DUT3.txt"] content:self.viewDutSlot3Log.string];
    [FileManager cw_writeToFile:[path stringByAppendingPathComponent:@"DUT4.txt"] content:self.viewDutSlot4Log.string];
    
    [FileManager cw_openFileWithPath:path];
}


- (IBAction)cleanAll:(NSButton *)btn {
    if (btn.tag) {
        [self.viewDutSlot1Log clean];
        [self.viewDutSlot2Log clean];
        [self.viewDutSlot3Log clean];
        [self.viewDutSlot4Log clean];
    }else{
        [self.viewFixtureSlot1Log clean];
        [self.viewFixtureSlot2Log clean];
        [self.viewFixtureSlot3Log clean];
        [self.viewFixtureSlot4Log clean];
    }

}



- (IBAction)logClean:(NSButton *)btn {
    NSInteger tag = btn.tag;
    if (tag == 1) {
        [self.viewFixtureSlot1Log clean];
    }else if (tag == 2){
        [self.viewDutSlot1Log clean];
    }else if (tag == 3){
        [self.viewFixtureSlot2Log clean];
    }else if (tag == 4){
        [self.viewDutSlot2Log clean];
    }else if (tag == 5){
        [self.viewFixtureSlot3Log clean];
    }else if (tag == 6){
        [self.viewDutSlot3Log clean];
    }else if (tag == 7){
        [self.viewFixtureSlot4Log clean];
    }else if (tag == 8){
        [self.viewDutSlot4Log clean];
    }
}

-(void)setDutStautsLedLight:(BOOL)isOn channel:(int)channel{
    NSString *icon_name = isOn ? @"state_on" : @"state_off";
    NSImageView *slot_imageView = self.slotImage1 ;
    if (channel == 1) {
        slot_imageView= self.slotImage1;
    }else if (channel == 2){
        slot_imageView= self.slotImage2;
    }else if (channel == 3){
        slot_imageView= self.slotImage3;
    }else if (channel == 4){
        slot_imageView= self.slotImage4;
    }
    [self setImageWithImageView:slot_imageView icon:icon_name];
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
- (IBAction)cmdsClean:(NSButton *)sender {
//    if (self.cmdData) {
//        [self.cmdData removeAllObjects];
////        [_tableDataDelegate reloadTableViewWithData:self.cmdData];
//    }
}


- (IBAction)fixtureSend:(NSButton *)btn {
//    if (!self.isConnected) {
//        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
//        return;
//    }
    NSString *cmd = self.viewFixtureCmd.stringValue;
    [self callLuaMethodWithName:@"fixtureSendClick" arguments:@[[LSCValue stringValue:cmd],[LSCValue dictionaryValue:self.slotsSelected]]];
    
    if (cmd.length) {
//        NSDictionary *dict = [NSDictionary alloc]init
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        [dict setObject:cmd forKey:@"Command"];
        [dict setObject:@"fixture" forKey:@"Type"];
//        [self.cmdData insertObject:dict atIndex:0];
//        [self.tableDataDelegate reloadTableViewWithData:self.cmdData];
    }
}


- (IBAction)dutSend:(NSButton *)btn {
//    if (!self.isConnected) {
//        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
//        return;
//    }
    NSString *cmd = self.viewDutCmd.stringValue;
    [self callLuaMethodWithName:@"dutSendClick" arguments:@[[LSCValue stringValue:cmd],[LSCValue dictionaryValue:self.slotsSelected]]];
    
    if (cmd.length) {
        //        NSDictionary *dict = [NSDictionary alloc]init
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        [dict setObject:cmd forKey:@"Command"];
        [dict setObject:@"dut" forKey:@"Type"];
//        [self.cmdData insertObject:dict atIndex:0];
//        [self.tableDataDelegate reloadTableViewWithData:self.cmdData];
    }
}


- (IBAction)resetClick:(id)btn {
    if (!self.isConnected) {
        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
        return;
    }
    
    //    LSCValue *s = [LSCValue booleanValue:isOn];
    //    LSCValue *s1 = [LSCValue dictionaryValue:self.slotsSelected];
    [self callLuaMethodWithName:@"resetClick" arguments:@[[LSCValue dictionaryValue:self.slotsSelected]]];
}


- (IBAction)scriptRun:(NSButton *)btn {
    {
        if (!self.isConnected) {
            [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
            return;
        }
        
        //    LSCValue *s = [LSCValue booleanValue:isOn];
        //    LSCValue *s1 = [LSCValue dictionaryValue:self.slotsSelected];
        NSString *name = self.scriptTestBtn.titleOfSelectedItem;
        [self callLuaMethodWithName:@"scriptRun" arguments:@[[LSCValue stringValue:name],[LSCValue dictionaryValue:self.slotsSelected]]];
    }
}


//- (IBAction)otherTest:(NSSegmentedControl *)btn {
//    if (!self.isConnected) {
//        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
//        return;
//    }
//    BOOL isOn =btn.selectedSegment;
////    LSCValue *s = [LSCValue booleanValue:isOn];
////    LSCValue *s1 = [LSCValue dictionaryValue:self.slotsSelected];
//    [self callLuaMethodWithName:@"otherTestClick" arguments:@[[LSCValue booleanValue:isOn],[LSCValue dictionaryValue:self.slotsSelected]]];
//
//}




- (IBAction)forceDFU:(NSSegmentedControl *)btn {
//    if (!self.isConnected) {
//        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
//        return;
//    }
    BOOL isOn =btn.selectedSegment;
    //    LSCValue *s = [LSCValue booleanValue:isOn];
    //    LSCValue *s1 = [LSCValue dictionaryValue:self.slotsSelected];
    [self callLuaMethodWithName:@"forceDFUClick" arguments:@[[LSCValue booleanValue:isOn],[LSCValue dictionaryValue:self.slotsSelected]]];
  
}

- (IBAction)enterDIagsClick:(NSSegmentedControl *)btn {
    if (!self.isConnected) {
        [Alert cw_RemindException:@"Error" Information:@"RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication."];
        return;
    }
    BOOL isOn =btn.selectedSegment;

    [self callLuaMethodWithName:@"enterDIagsClick" arguments:@[[LSCValue booleanValue:isOn],[LSCValue dictionaryValue:self.slotsSelected]]];
   
}


-(NSMutableDictionary *)slotsSelected{
    if (!_slotsSelected) {
        _slotsSelected =[[NSMutableDictionary alloc]init];
    }
    
    [_slotsSelected setObject:[NSNumber numberWithBool:self.btnSlot1.state]  forKey:@"isSelectedSlot1"];
    [_slotsSelected setObject:[NSNumber numberWithBool:self.btnSlot2.state] forKey:@"isSelectedSlot2"];
    [_slotsSelected setObject:[NSNumber numberWithBool:self.btnSlot3.state] forKey:@"isSelectedSlot3"];
    [_slotsSelected setObject:[NSNumber numberWithBool:self.btnSlot4.state] forKey:@"isSelectedSlot4"];
    return _slotsSelected;
}



-(LSCValue *)callLuaMethodWithName:(NSString *)methodName arguments:(NSArray<LSCValue *> *)arguments{
    
    // 加载Lua脚本
    
    NSString *SequenceControlPath = [[NSString cw_getResourcePath] stringByAppendingPathComponent:@"LuaScript/SequenceControl.lua"];
    [self.context evalScriptFromFile:SequenceControlPath];
    
    LSCValue *value= [self.context callMethodWithName:methodName
                                            arguments:arguments];
    
    return value;
    
}

-(void)printFixtureLog:(NSString *)log slot:(int)slot{
    if (slot == 1) {
        [self.viewFixtureSlot1Log showLog:log];
    }else if (slot == 2){
        [self.viewFixtureSlot2Log showLog:log];
    }else if (slot == 3){
        [self.viewFixtureSlot3Log showLog:log];
    }else if (slot == 4){
        [self.viewFixtureSlot4Log showLog:log];
    }
}
-(void)printDutLog:(NSString *)log slot:(int)slot{
    if (slot == 1){
        [self.viewDutSlot1Log showLog:log];
    }else if (slot == 2){
        [self.viewDutSlot2Log showLog:log];
    }else if (slot == 3){
        [self.viewDutSlot3Log showLog:log];
    }else if (slot == 4){
        [self.viewDutSlot4Log showLog:log];
    }
}


- (void)controlTextDidChange:(NSNotification *)obj{
    NSTextField *textF=obj.object;
    NSString *cmd_input = textF.stringValue;
    if (cmd_input.length==0) {
        [self.tableDataDelegate setData:self.cmdsData];
        [self.itemsTableView reloadData];
        return;
    }
    if (textF==self.viewFixtureCmd) {
        NSMutableArray *newData = [[NSMutableArray alloc]init];
        for (NSDictionary *dict in self.cmdsData) {
            NSString *module = [dict valueForKey:@"Module"];
            NSString *func = [dict valueForKey:@"Function"];
            NSString *cmd = [NSString stringWithFormat:@"%@%@",module,func];
            if ([cmd.lowercaseString containsString:cmd_input.lowercaseString]) {
                [newData addObject:dict];
            }
        }
        
        if (newData.count) {
            [self.tableDataDelegate setData:newData];
            [self.itemsTableView reloadData];
        }

    }
}

-(TableDataDelegate *)tableDataDelegate{
    if (!_tableDataDelegate) {
        __weak __typeof(self)weakSelf = self;
        _tableDataDelegate = [[TableDataDelegate alloc]initWithTaleView:_itemsTableView isDargData:NO];
//        _tableDataDelegate.tableViewForTableColumnCallback = ^(id view, NSInteger row, NSDictionary *data,NSString *identifier) {
//            NSString *value = [data valueForKey:identifier];
//            //NSString *search_keyword =[data valueForKey:key_IsSearch];
//
//            NSTextField *textField = (NSTextField *)view;
//
//
//        };
        
        _tableDataDelegate.tableViewHeightOfRowCallback = ^float(NSInteger row) {
            
            NSString *doc = [weakSelf.cmdsData[row] valueForKey:@"Doc"];
            int len= doc.length;
            float h =len/2.2;
            if (h<20) {
                h = 20;
            }
//            float h = [doc sizeWithAttributes:nil].height;
            return h;
        };
        _tableDataDelegate.selectionChangedCallback = ^(NSInteger clickIndex,NSDictionary *dict) {
            
            NSString *module = [dict valueForKey:@"Module"] ;
            NSString *func = [dict valueForKey:@"Function"];
            NSString *cmd = [NSString stringWithFormat:@"%@%@()",module,func];
            weakSelf.viewFixtureCmd.stringValue =[cmd  stringByReplacingOccurrencesOfString:@"\"" withString:@""];
  
            
        };
        

        
    }
    return _tableDataDelegate;
}

@end
