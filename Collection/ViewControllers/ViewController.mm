//
//  ViewController.m
//  Collection
//
//  Created by kino on 2019/11/14.
//  Copyright © 2019 ShuJuTang. All rights reserved.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#include <errno.h>
#import <AVFoundation/AVFoundation.h>
#import "COTime.h"
#import "NSObject+Audio.h"
#import "WavHeader.h"
#import "VidioViewController.h"
#import "MD5String.h"
#define SECRET @"1"

@interface ViewController ()<AVAudioRecorderDelegate>
@property (weak, nonatomic)  IBOutlet UITextField *IPTextView;
@property (weak, nonatomic)  IBOutlet UITextField *portTextView;
@property (nonatomic,assign) NSInteger clinenId;
@property (nonatomic,strong) NSTimer * timer;
@property (weak, nonatomic)  IBOutlet UIButton *connectBtn;
@property (nonatomic,assign) int count;
@property (nonatomic,strong) NSUUID * myDeviceUUID;
@property (nonatomic,strong) AVAudioRecorder *recorder;
@property (nonatomic,copy)   NSString * filePath;
@property (nonatomic,strong) NSMutableArray * timeArrayBegin;
@property (nonatomic,strong) NSMutableArray * timeArrayEnd;
@property (nonatomic,assign) int  actNumber;
@end

@implementation ViewController
#pragma  mark------------初始化时间数组
-(NSMutableArray *)timeArrayBegin{
    if (_timeArrayBegin==nil){
        NSMutableArray * array=[[NSMutableArray alloc]init];
        _timeArrayBegin=array;
    }
    return _timeArrayBegin;
}
-(NSMutableArray *)timeArrayEnd{
    if (_timeArrayEnd==nil){
        NSMutableArray * array=[[NSMutableArray alloc]init];
        _timeArrayEnd=array;
    }
    return _timeArrayEnd;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self requestForMic];
    [self setBaseContent];
    
}
-(void)setBaseContent{
    self.count=0;
    self.actNumber=1;
    [self configSession];
    self.connectBtn.layer.cornerRadius=5;
    [self.connectBtn.layer masksToBounds];
}
#pragma  mark------------配置audiosession信息
-(void)configSession{
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
       NSError *activeErr = nil;
       [audioSession setActive:YES error:&activeErr];
       if (activeErr) {
           NSLog(@"active err:%@",activeErr);
       }
}
-(void)closeAudioSession{
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
       NSError *activeErr = nil;
       [audioSession setActive:NO error:&activeErr];
}
- (IBAction)connnection:(UIButton *)sender {
    
      NSCharacterSet* set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
      NSString* ip = [self.IPTextView.text stringByTrimmingCharactersInSet:set];
      if (!ip.length) {
          return;
      }
      NSString* portText = [self.portTextView.text stringByTrimmingCharactersInSet:set];
      if (!portText.length) {
          return;
      }
      [self createSocket];
}
#pragma  mark------------创建socket
-(void)createSocket{
     int socketID = socket(AF_INET, SOCK_STREAM, 0);
     self.clinenId= socketID;
     if (socketID == -1) {
         NSLog(@"创建socket失败");
         self.connectBtn.enabled=YES;
         return;
     }
     
     // 2: 连接socket
     const char * ipC = NULL;
     if ([self.IPTextView.text canBeConvertedToEncoding:NSUTF8StringEncoding]) {
         ipC = [self.IPTextView.text cStringUsingEncoding:NSUTF8StringEncoding];
     }
     //将port转成数字
     int portNumber=[self.portTextView.text intValue];
    //结构体
     struct sockaddr_in socketAddr;
         socketAddr.sin_family = AF_INET;
         socketAddr.sin_port   = htons(portNumber);
         struct in_addr socketIn_addr;
         socketIn_addr.s_addr  = inet_addr(ipC);
         socketAddr.sin_addr   = socketIn_addr;
             
     int result = connect(socketID, (const struct sockaddr *)&socketAddr, sizeof(socketAddr));

     if (result != 0) {
         NSLog(@"连接失败的数值%d---并且对应原因为%s",errno,strerror(errno));
         NSLog(@"连接失败");
         self.connectBtn.enabled = YES;
         
     }else{
         NSLog(@"连接成功");
         [self connectSuccess];
        
     }
}
#pragma  mark------------连接成功调用
-(void)connectSuccess{
    [self.connectBtn setTitle:@"已连接" forState:UIControlStateNormal];
    self.connectBtn.backgroundColor=[UIColor colorWithRed:107/255.0 green:175/255.0 blue:214/255.0152 alpha:1];
    [self sendMyDeviceInformation];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self receiveMessage];
    });
    
   
}
#pragma  mark------------收到信息
-(void)receiveMessage{
      while(1){
          if (self.count==2){
              [self.timeArrayBegin addObject:[COTime getTimeStamp]];
          }
          else if(self.count==3){
              [self.timeArrayEnd addObject:[COTime getTimeStamp]];
          }
            char buffer[1024];
            ssize_t recvLen;
            recvLen = recv((int)self.clinenId, buffer, sizeof(buffer), 0);
            
            if (recvLen==0) continue;
            
            else if (recvLen<0){
                dispatch_async(dispatch_get_main_queue(), ^{
                      [self endSocket];
            });
                 break;
                 return;
            }
            
            NSData *data = [NSData dataWithBytes:buffer length:recvLen];
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([json isKindOfClass:[NSDictionary class]]) {
                NSDictionary* dict = json;
                const int type = [dict[@"secret"] intValue];
                if (type==1) {
                     NSLog(@"socket已连接");
                    
                    if (self.count==0){
                         NSDictionary * data=[dict objectForKey:@"data"];
                        if ([[data objectForKey:@"status"] intValue]==200){
                            NSLog(@"判断后连接成功");
                            self.count=1;
                        }
                    }
                    
                     else if(self.count==1){
                        NSDictionary * sensors=[dict objectForKey:@"sensors"];
                        NSString * type=[sensors objectForKey:@"type"];
                        if ([type isEqualToString:@"mic"]){
                            [self sendStatusOK];
                            self.count=2;
                        }
                        else{
                            [self sendStatusFailed];
                        }
                     }
                    
                     else if(self.count==2||self.count==3){
                        NSString * type=[dict objectForKey:@"type"];
                        NSArray *sensorsArray=[dict objectForKey:@"content"];
                        NSDictionary * firstItem=[sensorsArray firstObject];
                        if ([[firstItem objectForKey:@"sensorId"] intValue]==1){
                            if ([type isEqualToString:@"start"]){
                                self.filePath=[firstItem objectForKey:@"filepath"];
                                [self startRecord];
                                self.count=3;
                            }
                            else if([type isEqualToString:@"end"]){
                                [self stopRecord];
                                self.count=4;
                            }
                        }
                        
                    }
                     else{
                         
                         NSString * type=[dict objectForKey:@"type"];
                         if ([type isEqualToString:@"close"]){
                             if(self.clinenId==-1){
                                 [self sendCloseAgain];
                             }else{
                                 [self sendSocketEndMessage];
                                 [self endSocket];
                             }
                         }
                     }
                    
                }
            }
                else{
                    NSDictionary * data=@{@"status": @401,
                                        @"message": @"Invalid Secret",
                                        @"agentId": self.myDeviceUUID.UUIDString};
                    self.actNumber++;
                    NSDictionary * dic=@{@"type": @"ack-open",
                                        @"operationId":[NSNumber numberWithInt:self.actNumber],
                                        @"secret": SECRET,
                                        @"data": data};
                    [self sendMsgAction:dic];
                    self.actNumber=1;
                    
                }
      }
}
#pragma  mark-----------发送开始停止成功/失败消息
-(void)sendBeginTimeMessage{
    NSString * offset=[NSString stringWithFormat:@"%lld",[self.timeArrayBegin[2] longLongValue]-[self.timeArrayBegin[1] longLongValue]];
    NSDictionary *contentItem=@{@"agentId": self.myDeviceUUID.UUIDString,
                         @"sensorId": @1,
                         @"filepath": self.filePath,
                         @"begin": self.timeArrayBegin[0],
                         @"beforeCall": self.timeArrayBegin[1],
                         @"afterCall": self.timeArrayBegin[2],
                                @"offset": [NSNumber numberWithInt:[offset intValue]]};
    
    
    NSDictionary * extra=@{@"desc":@"micphone",
                           @"sessionId":@1,
                           @"content":@[contentItem]};
    
    NSDictionary * data=@{@"status": @200,
                         @"message": @"OK",
                         @"agentId": self.myDeviceUUID.UUIDString,
                          @"extra":extra};
    NSDictionary * dic=@{@"type": @"ack-start",
                         @"operationId": [NSNumber numberWithInt:++self.actNumber],
                         @"secret": SECRET,
                         @"data":data};
    
    [self sendMsgAction:dic];
}
//目前用不到
-(void)sendBeginTimeMessageFailed{
    NSDictionary * data=@{@"status": @301,
                          @"message": @"Sensor lost",
                          @"agentId": self.myDeviceUUID.UUIDString};
    NSDictionary * dic=@{@"type": @"ack-start",
                         @"operationId": [NSNumber numberWithInt:++self.actNumber],
                         @"secret":SECRET,
                         @"data":data};
    [self sendMsgAction:dic];
}
-(void)sendStopTimeMessage{
    NSString * offset=[NSString stringWithFormat:@"%lld",[self.timeArrayEnd[2] longLongValue]-[self.timeArrayEnd[1] longLongValue]];
    NSDictionary *contentItem=@{@"agentId": self.myDeviceUUID.UUIDString,
                               @"sensorId": @1,
                               @"filepath": self.filePath,
                               @"begin": self.timeArrayEnd[0],
                               @"beforeCall": self.timeArrayEnd[1],
                               @"afterCall": self.timeArrayEnd[2],
                               @"offset": [NSNumber numberWithInt:[offset intValue]]};
       
       
    NSDictionary * extra=@{@"desc":@"micphone",
                          @"sessionId":@1,
                          @"content":@[contentItem]};
       
    NSDictionary * data=@{@"status": @200,
                         @"message": @"OK",
                         @"agentId": self.myDeviceUUID.UUIDString,
                         @"extra":extra};
    
    NSDictionary * dic=@{@"type": @"ack-end",
                        @"operationId": [NSNumber numberWithInt:++self.actNumber],
                        @"secret": SECRET,
                        @"data":data};
       
    [self sendMsgAction:dic];
}
-(void)sendStopTimeMessageFailed{
    NSDictionary * data=@{@"status": [NSNumber numberWithInt:++self.actNumber],
                        @"message": @"No space",
                          @"agentId": self.myDeviceUUID.UUIDString};
    NSDictionary * dic=@{@"type": @"ack-end",
           @"operationId": [NSNumber numberWithInt:++self.actNumber],
           @"secret":SECRET,
           @"data":data};
    [self sendMsgAction:dic];
}

#pragma  mark-----------开始录制停止方法
-(void)startRecord{
    NSString* audioName = [NSString stringWithFormat:@"temp_%@.wav",@(arc4random())];
       NSString *tempPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:audioName];
       NSURL *tmpRecordURL = [NSURL fileURLWithPath:tempPath];
       NSDictionary *recordSetting = @{AVSampleRateKey: @(44100.),
                                       AVFormatIDKey: @(kAudioFormatLinearPCM),
                                       AVLinearPCMBitDepthKey: @(16),
                                       AVNumberOfChannelsKey: @(1),
                                       AVLinearPCMIsBigEndianKey: @(NO),
                                       AVLinearPCMIsFloatKey: @(NO),
                                       };
       self.recorder= nil;
       self.recorder = [[AVAudioRecorder alloc]initWithURL:tmpRecordURL settings:recordSetting error:nil];
       self.recorder.delegate = self;
       [self.recorder prepareToRecord];
       [self.recorder setMeteringEnabled:YES];
       [self.timeArrayBegin addObject:[COTime getTimeStamp]];
       [self.recorder record];
       [self.timeArrayBegin addObject:[COTime getTimeStamp]];
       [self sendBeginTimeMessage];
       dispatch_async(dispatch_get_main_queue(), ^{
          VidioViewController * videoVC=[[VidioViewController alloc]init];
          videoVC.modalPresentationStyle=UIModalPresentationFullScreen;
          [self presentViewController:videoVC animated:YES completion:nil];
       });
}
-(void)stopRecord{
    NSURL *tmpURL = self.recorder.url;
    if (!tmpURL) {
        NSLog(@"未录制成功");
        [self sendStopTimeMessageFailed];
        return;
    }
    
    [self.timeArrayEnd addObject:[COTime getTimeStamp]];
    [self.recorder stop];
    [self.timeArrayEnd addObject:[COTime getTimeStamp]];
    
    [self sendStopTimeMessage];
    
    NSString* rootPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"wav"];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:rootPath]) {
        [fileManager createDirectoryAtPath:rootPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString* path = [rootPath stringByAppendingPathComponent:self.filePath];
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:nil];
    }
    NSLog(@"停止录音：%@",path);
    
        NSURL* url = [NSURL fileURLWithPath:path];
        [fileManager moveItemAtURL:tmpURL toURL:url error:nil];
        [NSObject removeFLLRfromWavHeader:path];
        [NSObject removeJUNKfromWavHeader:path];
        const char* file = [path UTF8String];
        const char* snr = GetSnrJson(file);
//        int ret = JudgeClip(file, 0.05, 0.3);
        NSString* snrTxt = [NSString stringWithFormat:@"%s",snr];
        NSData* snrData = [snrTxt dataUsingEncoding:NSUTF8StringEncoding];
        NSArray* snrArr = [NSJSONSerialization JSONObjectWithData:snrData options:NSJSONReadingMutableContainers error:nil];
    
        
        NSString * mdString=[MD5String MD5ForUpper32Bate:snrTxt];
        //发送语音的文件
        NSDictionary * info=@{@"agentId":self.myDeviceUUID.UUIDString,
                            @"sensorId":@1,
                            @"operationId":[NSNumber numberWithInt:++self.actNumber],
                            @"filename":self.filePath};
    
        NSDictionary* dic = @{@"method":@"POST",
                           @"secret":SECRET,
                           @"md5":mdString,
                           @"info":info,
                           @"data":snrArr};
        [self sendMsgAction:dic];
    
        NSNotification * stopNotification=[[NSNotification alloc]initWithName:@"stop" object:nil userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotification:stopNotification];
}
#pragma  mark-----------准备前状态
-(void)sendStatusOK{
    NSDictionary * data=@{ @"status":@200,
                          @"message":@"ok",
                          @"agentId":self.myDeviceUUID.UUIDString,};
    NSDictionary * dic=@{@"type":@"ack-setup",
                         @"operationId":[NSNumber numberWithInt:++self.actNumber],
                         @"secret":SECRET,
                         @"data":data};
    
    [self sendMsgAction:dic];
}
//目前用不到
-(void)sendStatusFailed{
      
    NSDictionary * sensors=@{@"id":@1,
                             @"status":@300,
                             @"message":@"Unable to record"};
    
    NSDictionary * data=@{@"message":@"Unknown spec",
                         @"agentId":self.myDeviceUUID.UUIDString,
                          @"sensors":@[sensors]};
    
    NSDictionary * dic=@{@"type":@"ack-setup",
                        @"operationId":[NSNumber numberWithInt:++self.actNumber],
                        @"status":@"300",
                        @"secret":SECRET,
                        @"data":data};
    [self sendMsgAction:dic];
}
#pragma mark ------------发送设备信息
-(void)sendMyDeviceInformation{

     NSDictionary *recordSetting = @{AVSampleRateKey: @(44100.),
                                    AVFormatIDKey: @(kAudioFormatLinearPCM),
                                    AVLinearPCMBitDepthKey: @(16),
                                    AVNumberOfChannelsKey: @(1),
                                    AVLinearPCMIsBigEndianKey: @(NO),
                                    AVLinearPCMIsFloatKey: @(NO),};
    
    NSDictionary * sensors=@{@"name":@"micphone",
                            @"type":@"mic",
                            @"id": @1,
                            @"desc":@"micphone",
                            @"spec":recordSetting};
                            
    
    NSString * name=[[UIDevice currentDevice] name];
    self.myDeviceUUID=[[UIDevice currentDevice] identifierForVendor];
    NSDictionary * data=@{@"name":name,
                          @"agentId":self.myDeviceUUID.UUIDString,
                          @"sensors":@[sensors]};
    
    NSDictionary * dic=@{@"type":@"open",
                         @"operationId":[NSNumber numberWithInt:self.actNumber],
                         @"secret":SECRET,
                         @"data":data};

    [self sendMsgAction:dic];
    
}
-(void)sendCloseAgain{
    
    NSDictionary * data=@{@"status": @303,
                         @"message": @"Closed already",
                         @"agentId": self.myDeviceUUID.UUIDString,};
    NSDictionary * dic=@{@"type": @"ack-close",
                        @"secret": SECRET,
                        @"operationId": [NSNumber numberWithInt:++self.actNumber],
                        @"data": data};
    
    [self sendMsgAction:dic];
}
-(void)sendSocketEndMessage{
    NSDictionary * data=@{@"status": @200,
                         @"message": @"OK",
                         @"agentId": self.myDeviceUUID.UUIDString};
                                
    NSDictionary * dic=@{@"type": @"ack-close",
                        @"secret":SECRET,
                        @"operationId": [NSNumber numberWithInt:++self.actNumber],
                        @"data": data};
    [self sendMsgAction:dic];
}
#pragma mark ---------发送数据
- (void)sendMsgAction:(NSDictionary *)dic{
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
    NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    const char *msg = json.UTF8String;
    send((int)self.clinenId,msg, strlen(msg), 0);
}
#pragma mark ---------请求麦克风
-(void)requestForMic{
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            
        }
        else{
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"麦克风权限未开启" message:@"麦克风权限未开启，请进入系统【设置】>【隐私】>【麦克风】中打开开关,开启麦克风功能" preferredStyle:UIAlertControllerStyleAlert];
               UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

               }];
               UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                   //跳入当前App设置界面
                    NSURL* url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                   if (@available(iOS 10.0, *)) {
                       [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                   } else {
                       [[UIApplication sharedApplication]openURL:url];
                   }
               }];
               [alertVC addAction:cancelAction];
               [alertVC addAction:setAction];

               [self presentViewController:alertVC animated:YES completion:nil];
           }
    }];
}
#pragma mark ---------socket关闭
-(void)endSocket{
    [self closeAudioSession];
    [self.connectBtn setTitle:@"请求连接" forState:UIControlStateNormal];
    self.connectBtn.backgroundColor=[UIColor colorWithRed:86/255.0 green:214/255.0 blue:189/255.0152 alpha:1];
    self.clinenId=-1;
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.IPTextView resignFirstResponder];
    [self.portTextView resignFirstResponder];
}
@end
