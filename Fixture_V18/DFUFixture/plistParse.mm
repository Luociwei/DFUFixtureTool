#import "plistParse.h"

@implementation plistParse

+(NSDictionary*)parsePlist:(NSString *)file
{
    if(!file)
        file = @"/usr/local/lib/DFUFixtureCmd.plist";
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:file];
    return dic;
}

+(NSDictionary *)readAllCMD
{
    NSString *file=@"/Users/gdlocal/Library/Atlas/supportFiles/DFUFixtureCmd.plist";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:file])
    {
        NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:file];
        NSLog(@"-->file exist at path:%@",file);
        return dic;
    }
    else
    {
        NSDictionary *dic=@{
                            kFIXTUREPORT:@{
                                    @"UUT0":@"169.254.1.32:7801",
                                    @"UUT1":@"169.254.1.32:7802",
                                    @"UUT2":@"169.254.1.32:7803",
                                    @"UUT3":@"169.254.1.32:7804"
                                    },
                            
                            kFIXTURESLOTS:@"4",
                            kVENDER:@"Suncode",
                            kFIXTUREOPEN:@[@"fixturecontrol.release()"],
                            kFIXTURECLOSE:@[@"fixturecontrol.press()"],
                            kFIXTURESTATUS:@"fixturecontrol.get_fixture_status()",
                            
                            kAPPLEIDOFF:@[@""],
                            kAPPLEIDON:@[@""],
                            
                            kBATTERYPOWEROFF:@[@""],
                            kBATTERYPOWERON:@[@""],
                            
                            kCONNDETGNDOFF:@[@""],
                            kCONNDETGNDON:@[@""],
                            
                            kDUTPOWEROFF:@[@"io.set(bit26=0;bit22=0;bit42=1)",
//                                           @"io.set(bit42=1)",
                                           @"Delay:0.5",
                                           @"batt.volt_set(0)",
                                           @"reset_all.reset()",
                                           @"io.set(bit26=0;bit22=0;bit40=0)",
                                           @"io.set(bit30=1;bit42=1;bit43=1)",
                                           @"Delay:10",
//                                           @"io.set(bit30=0;bit42=0;bit43=0)"
                                            ],//1023 David add bit30=1 to discharge vbus
                            
                            kDUTPOWERON:@[@""],
                            
                            kFORCEDFUOFF:@[@"io.set(bit26=0;bit22=0;bit42=1)",
//                                           @"io.set(bit42=1)",
                                           @"Delay:0.5",
                                           @"batt.volt_set(0)",
                                           @"reset_all.reset()",
                                           @"io.set(bit26=0;bit22=0;bit40=0)",
                                           @"io.set(bit30=1;bit42=1;bit43=1)",
                                           @"Delay:2",
//                                           @"io.set(bit30=0;bit42=0;bit43=0)"
                            ],
                            
                            kFORCEDFUON:@[@"io.set(bit30=0;bit42=0;bit43=0)",
                                          @"batt.volt_set(0)",
                                          @"reset_all_reset()",
                                          @"Delay:0.2",
                                          @"batt.volt_set(4200)",
                                          @"io.set(bit30=0;bit42=0;bit43=0;bit34=1;bit39=1;bit40=1;bit32=1;bit35=1;bit22=1;bit26=1)"],   // force dfu on
                                                      
                            kFORCEDIAGSOFF:@[@"io.set(bit26=0;bit22=0;bit42=1)",
//                                             @"io.set(bit42=1)",
                                             @"Delay:0.5",
                                             @"batt.volt_set(0)",
                                             @"reset_all.reset()",
                                             @"io.set(bit26=0;bit22=0;bit40=0)",
                                             @"io.set(bit30=1;bit42=1;bit43=1)",
                                             @"Delay:2",
//                                             @"io.set(bit30=0;bit42=0;bit43=0)"
                            ],
                            
                            kFORCEDIAGSON:@[@"batt.volt_set(0)",
                                            @"reset_all.reset()",
                                            @"io.set(bit39=0;bit24=0;bit40=0;bit34=0;bit22=0;bit26=0;bit30=1;bit42=1;bit43=1)",
                                            @"Delay:2",
                                            @"io.set(bit30=0;bit42=0;bit43=0)",
                                            @"batt.volt_set(4200)",
                                            @"io.set(bit39=1;bit24=1;bit40=1;bit34=1;bit22=1;bit26=1)"],   //force diags on  1023 david change bit31 from 1 to 0 and change bit36=0

                            kFORCEIBOOTOFF:@[@""],
                            kFORCEIBOOTON:@[@""],
                            
                            kHI5OFF:@[@""],
                            kHI5ON:@[@""],
                            
                            kINIT:@[@"io.set(bit24=1)",
                                    @"Delay:0.5",
                                    @"batt.volt_set(0)",
                                    @"reset_all.reset()",
                                    @"io.set(bit27=1;bit28=1;bit29=1)",
                                    @"fan.speed_set(4000,100)"],  // fan off
                            
                            kLEDSTATE:@{kFAIL:@[@"",
                                                @""],
                                        
                                        kFAILGOTOFA:@[@"",
                                                      @""],
                                        
                                        kINPROCESS:@[@"",
                                                     @""],
                                        
                                        kOFF:@[@"",
                                               @""],
                                        
                                        kPANIC:@[@"",
                                                 @""],
                                        
                                        kPASS:@[@"",
                                                @""]},
                            
                            kRESET:@[@"io.set(bit24=1)",
                                     @"Delay:0.5",
                                     @"batt.volt_set(0)",
                                     @"reset_all.reset()",
                                     @"io.set(bit27=1;bit28=1;bit29=1)"],
                            
                            kFIXTUREFANSPEEDSETIO:@"io.set(bit27=1;bit29=1)",
                            kFIXTUREFANSPEEDSET:@"fan.speed_set",
                            
                            kFIXTUREFANSPEEDGETIO:@"io.set(bit28=1)",
                            kFIXTUREFANSPEEDGET:@"fan.speed_get",
                            
                            kFIXTUREUUTDETECT:@"uut_detect.read_Volt",
                            
                            kLED_POWEROFF:  @"io.set(bit49=1;bit50=1;bit51=1)",
                            kLED_POWERRED:  @"io.set(bit49=0;bit50=1;bit51=1)",
                            kLED_POWERGREEN:@"io.set(bit49=1;bit50=0;bit51=1)",
                            kLED_POWERBLUE: @"io.set(bit49=1;bit50=1;bit51=0)",
                            
                            kLED_UUT1OFF  : @"io.set(bit52=1;bit53=1;bit54=1)",  //off
                            kLED_UUT1RED  : @"io.set(bit52=0;bit53=1;bit54=1)",  //red
                            kLED_UUT1GREEN: @"io.set(bit52=1;bit53=0;bit54=1)",  //green
                            kLED_UUT1BLUE : @"io.set(bit52=1;bit53=1;bit54=0)",  //blue
                            
                            kLED_UUT2OFF  :@"io.set(bit55=1;bit56=1;bit57=1)",  //off
                            kLED_UUT2RED  :@"io.set(bit55=0;bit56=1;bit57=1)",  //red
                            kLED_UUT2GREEN:@"io.set(bit55=1;bit56=0;bit57=1)",  //green
                            kLED_UUT2BLUE :@"io.set(bit55=1;bit56=1;bit57=0)",  //blue
                            
                            kLED_UUT3OFF  :@"io.set(bit65=1;bit66=1;bit67=1)",  //off
                            kLED_UUT3RED  :@"io.set(bit65=0;bit66=1;bit67=1)",  //red
                            kLED_UUT3GREEN:@"io.set(bit65=1;bit66=0;bit67=1)",  //green
                            kLED_UUT3BLUE :@"io.set(bit65=1;bit66=1;bit67=0)",  //blue
                            
                            kLED_UUT4OFF  :@"io.set(bit68=1;bit69=1;bit70=1)",  // off
                            kLED_UUT4RED  :@"io.set(bit68=0;bit69=1;bit70=1)",  // red
                            kLED_UUT4GREEN:@"io.set(bit68=1;bit69=0;bit70=1)",  // green
                            kLED_UUT4BLUE :@"io.set(bit68=1;bit69=1;bit70=0)",  // blue
                            
                            kSERIAL:@"eeprom.read_string(0,19)",
                            
                            kUARTPATH:@{@"UUT0":@"",  //not use kUARTPATH, using auto detecting
                                        @"UUT1":@""},
                            
                            kUARTSIGNALOFF:@[@""],
                            kUARTSIGNALON:@[@""],
                            
                            kUSBLOCATION:@{@"UUT0":@"",   //not use
                                           @"UUT1":@"",
                                           @"UUT2":@"",
                                           @"UUT3":@"",
                                           @"UUT4":@"",
                                           @"UUT5":@"",
                                           @"UUT6":@"",
                                           @"UUT7":@""},
                            
                            kUSBPOWEROFF:@[@""],
                            
                            kUSBPOWERON:@[@""],
                            
                            kUSBSIGNALOFF:@[@""],
                            kUSBSIGNALON:@[@""],
                            
                            };
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *plistFile =@"/vault/Atlas/FixtureLog/SunCode/DFUFixtureCmd.plist";
        if (![fileManager fileExistsAtPath:plistFile]){
            [dic writeToFile:plistFile atomically:YES];
        }
        
        NSLog(@"-->file not exist at path:%@",file);
        return dic;
    }
}


+(void)checkLogFileExist:(NSString *)filePath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL isExist = [fm fileExistsAtPath:filePath];
    if (!isExist)
    {
        BOOL ret = [fm createFileAtPath:filePath contents:nil attributes:nil];
        if (ret)
        {
            NSLog(@"create file is successful");
        }
        else
        {
            [fm createDirectoryAtPath:@"/vault/Atlas/FixtureLog/SunCode/" withIntermediateDirectories:YES attributes:nil error:&error];
            [fm createDirectoryAtPath:@"/vault/FixtureLog/SunCode/" withIntermediateDirectories:YES attributes:nil error:&error];
            [fm createFileAtPath:filePath contents:nil attributes:nil];
            NSLog(@"create folder and file is successful");
        }
    }
    else
    {
        NSLog(@"file already exit");
    }
}


+(void)writeLog2File:(NSString *)filePath withTime:(NSString *) testTime andContent:(NSString *)str
{
    NSFileHandle* fh=[NSFileHandle fileHandleForWritingAtPath:filePath];
    [fh seekToEndOfFile];
    [fh writeData:[[NSString stringWithFormat:@"%@  %@\r\n",testTime,str] dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
}

+(void)writeLog1File:(NSString *)filePath withTime:(NSString *) testTime andContent:(NSString *)str
{
    NSFileHandle* fh=[NSFileHandle fileHandleForWritingAtPath:filePath];
    //    [fh seekToEndOfFile];
    [fh writeData:[[NSString stringWithFormat:@"%@  %@\r\n",testTime,str] dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
}

@end
