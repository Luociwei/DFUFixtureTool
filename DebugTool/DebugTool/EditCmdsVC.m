//
//  EditCmdsVC.m
//  DfuDebugTool
//
//  Created by ciwei luo on 2021/2/28.
//  Copyright © 2021 macdev. All rights reserved.
//

#import "EditCmdsVC.h"
#import "SnVauleMode.h"
@interface EditCmdsVC ()

@property (weak) IBOutlet NSTableView *editTableView;
@property (nonatomic,strong) NSMutableArray<SnVauleMode *> *sn_datas;
@end

@implementation EditCmdsVC



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    
    self.sn_datas =[[NSMutableArray alloc]init];
    
    for (int i =0; i<25; i++) {
        SnVauleMode *mode = [[SnVauleMode alloc]init];
        mode.name= [NSString stringWithFormat:@"ACE_TO_PARROT_RESET_L_%d",i];
        mode.command = [NSString stringWithFormat:@"[]io set(1,bit%d=1)",i+5];
        [self.sn_datas addObject:mode];
    }
    
    
    [self initTableView:self.editTableView];
    
}


- (IBAction)save:(id)sender {
    
    [self close];
}

- (IBAction)close:(id)sender {
    
    [self close];
}

-(void)initTableView:(NSTableView *)tableView{
    tableView.headerView.hidden=NO;
    tableView.usesAlternatingRowBackgroundColors=YES;
    tableView.rowHeight = 20;
    tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask |NSTableViewSolidVerticalGridLineMask ;

}




#pragma mark-  NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    //返回表格共有多少行数据

    
    return [self.sn_datas count];
    
}

#pragma mark-  NSTableViewDelegate
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    
    NSString *identifier = tableColumn.identifier;
    NSString *value = @"";
    NSTextField *textField;
    

        SnVauleMode *sv_data = self.sn_datas[row];
        sv_data= self.sn_datas[row];
        
        value=[sv_data getVauleWithKey:identifier];
  
    NSView *view = [tableView makeViewWithIdentifier:identifier owner:self];
    
    if(!view){
        
        textField =  [[NSTextField alloc]init];
        
        textField.identifier = identifier;
        view = textField ;
        
    }
    else{
        
        //        textField = (NSTextField*)view;
        NSArray *subviews = [view subviews];
        
        textField = subviews[0];
        
        
    }
    textField.wantsLayer=YES;
    [textField setBezeled:NO];
    [textField setDrawsBackground:NO];
    
    if(value){
        //更新单元格的文本
        [textField setStringValue: value];
    }
    
//    if ([identifier isEqualToString:@"command"]) {
//        [textField setTextColor:[NSColor blueColor]];
//        textField.layer.backgroundColor = [NSColor greenColor].CGColor;
//    }
    
    return view;
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification{
    
    NSLog(@"s");
    
    NSTableView *tableView = notification.object;
    NSInteger index = tableView.selectedRow;
//    if (tableView == self.itemsTableView) {
//        NSInteger index = tableView.selectedRow;
//        if (self.items_datas.count) {
//            ItemMode *item = self.items_datas[index];
//            [self.sn_datas removeAllObjects];
//            [self.sn_datas addObjectsFromArray:item.SnVauleArray];
//            [self.editTableView reloadData];
//        }
//        
//    }
}

@end
