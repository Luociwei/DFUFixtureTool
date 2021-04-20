//
//  FixtureVC.m
//  DfuDebugTool
//
//  Created by ciwei luo on 2021/2/28.
//  Copyright © 2021 macdev. All rights reserved.
//

#import "FixtureVC.h"
#import <CwGeneralManagerFrameWork/TextView.h>
#import <CwGeneralManagerFrameWork/Task.h>
#import <CwGeneralManagerFrameWork/Image.h>
#import <CwGeneralManagerFrameWork/Alert.h>
#import "DFUFixture.h"
@interface FixtureVC ()
@property (nonatomic,strong)TextView *textView;
@property (weak) IBOutlet NSImageView *slotImage1;
@property (weak) IBOutlet NSImageView *slotImage2;
@property (weak) IBOutlet NSImageView *slotImage3;
@property (weak) IBOutlet NSImageView *slotImage4;

@property (weak) IBOutlet NSImageView *inImage;
@property (weak) IBOutlet NSImageView *outImage;
@property (weak) IBOutlet NSImageView *upImage;
@property (weak) IBOutlet NSImageView *downImage;

@end

@implementation FixtureVC{
    void *rpcController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.textView = [TextView cw_allocInitWithFrame:NSMakeRect(0, 0, 668, 258)];
    [self.view addSubview:self.textView];
    
    
    [self getDutSate];
    
    
    [self getActionSate];
    
}



-(void)getDutSate{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            
            if (![self getSlotState:1]) {
                [self setImageWithImageView:self.slotImage1 icon:@"state_off"];
                
            }else{
                [self setImageWithImageView:self.slotImage1 icon:@"state_on"];
                
                
            }
            [NSThread sleepForTimeInterval:0.2];
            if (![self getSlotState:2]) {
                
                [self setImageWithImageView:self.slotImage2 icon:@"state_off"];
                
            }else{
                
                [self setImageWithImageView:self.slotImage2 icon:@"state_on"];
                
                
            }
            [NSThread sleepForTimeInterval:0.2];
            if (![self getSlotState:3]) {
                
                [self setImageWithImageView:self.slotImage3 icon:@"state_off"];
                
            }else{
                
                [self setImageWithImageView:self.slotImage3 icon:@"state_on"];
                
                
            }
            [NSThread sleepForTimeInterval:0.2];
            if (![self getSlotState:4]) {
                
                [self setImageWithImageView:self.slotImage4 icon:@"state_off"];
            }else{
                
                [self setImageWithImageView:self.slotImage4 icon:@"state_on"];
                
            }
            [NSThread sleepForTimeInterval:0.5];
            
        }
  
    });
}


-(void)getActionSate{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            
            if (![self getSlotState:1]) {
                [self setImageWithImageView:self.inImage icon:@"state_off"];
                [self setImageWithImageView:self.outImage icon:@"state_off"];
                [self setImageWithImageView:self.upImage icon:@"state_off"];
                [self setImageWithImageView:self.downImage icon:@"state_off"];
            }else{
                [self setImageWithImageView:self.inImage icon:@"state_on"];
                [self setImageWithImageView:self.outImage icon:@"state_on"];
                [self setImageWithImageView:self.upImage icon:@"state_on"];
                [self setImageWithImageView:self.downImage icon:@"state_on"];
                
                
            }
            [NSThread sleepForTimeInterval:0.3];
            
        }
        
        
    });
    
}

-(BOOL)isEmptyDut{
    
    if (!rpcController) {
        return NO;
    }
    
    BOOL isOk1 = is_board_detected(rpcController, 1);
    BOOL isOk2 = is_board_detected(rpcController, 1);
    BOOL isOk3 = is_board_detected(rpcController, 1);
    BOOL isOk4 = is_board_detected(rpcController, 1);
    BOOL isOk =!isOk1&&!isOk2&&!isOk3&&!isOk4;
    return isOk;
}

//is_board_detected
-(BOOL)getSlotState:(int)slot{
    
    if (!rpcController) {
        return NO;
    }
    BOOL isOk = is_board_detected(rpcController, slot);

    return isOk;
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
}


- (IBAction)actionBtnClick:(NSButton *)btn {
    if (!rpcController) {
        [Alert cw_RemindException:@"Error" Information:@"RPC is not ready!"];
        return;
    }
    if ([btn.title.lowercaseString containsString:@"release"]) {
        NSLog(@"fixture staute:%d--",fixture_open(rpcController, 1)) ;
        
    }else if([btn.title.lowercaseString containsString:@"press"]){
//        if ([self isEmptyDut]) {
//            [Alert cw_RemindException:@"Error" Information:@"No product detected!Pls put in the product."];
//        }
        NSLog(@"fixture staute:%d--",fixture_close(rpcController, 1));
        
    }
    else if([btn.title.lowercaseString containsString:@"up"]){//@[@"fixturecontrol.release()"]
 
        NSLog(@"fixture staute:%d--",executeAction(rpcController, @"fixturecontrol.up()", 1));
        
    }else if([btn.title.lowercaseString containsString:@"in"]){
   
        NSLog(@"fixture staute:%d--",executeAction(rpcController, @"fixturecontrol.in()", 1));
 
    }else if([btn.title.lowercaseString containsString:@"down"]){
        
        NSLog(@"fixture staute:%d--",executeAction(rpcController, @"fixturecontrol.down()", 1));
        
    }else if([btn.title.lowercaseString containsString:@"out"]){
        
        NSLog(@"fixture staute:%d--",executeAction(rpcController, @"fixturecontrol.out()", 1));
        
    }
}



@end
