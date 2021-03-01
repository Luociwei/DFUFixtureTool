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
            
            if (![self getIpState:@"169.254.1.32"]) {
                [self setImageWithImageView:self.slotImage1 icon:@"state_off"];
                [self setImageWithImageView:self.slotImage2 icon:@"state_off"];
                [self setImageWithImageView:self.slotImage3 icon:@"state_off"];
                [self setImageWithImageView:self.slotImage4 icon:@"state_off"];
            }else{
                [self setImageWithImageView:self.slotImage1 icon:@"state_on"];
                [self setImageWithImageView:self.slotImage2 icon:@"state_on"];
                [self setImageWithImageView:self.slotImage3 icon:@"state_on"];
                [self setImageWithImageView:self.slotImage4 icon:@"state_on"];
                
                
            }
            [NSThread sleepForTimeInterval:0.3];
            
        }
  
    });
}


-(void)getActionSate{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            
            if (![self getIpState:@"169.254.1.32"]) {
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



-(BOOL)getIpState:(NSString *)ip{
    
    BOOL isOk = NO;
    NSString *pingIP =[NSString stringWithFormat:@"ping %@ -t1",ip];
    NSString *read  = [Task termialWithCmd:pingIP];
    if ([read containsString:@"icmp_seq="]&&[read containsString:@"ttl="]) {
        
        isOk = YES;
    }
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
        NSLog(@"fixture staute:%d--",fixture_close(rpcController, 1)) ;
        
    }else if([btn.title.lowercaseString containsString:@"press"]){
        NSLog(@"fixture staute:%d--",fixture_open(rpcController, 1)) ;
        
    }
}



@end
