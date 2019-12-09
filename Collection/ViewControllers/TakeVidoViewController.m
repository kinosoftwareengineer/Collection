//
//  TakeVidoViewController.m
//  Collection
//
//  Created by kino on 2019/12/9.
//  Copyright © 2019 ShuJuTang. All rights reserved.
//

#import "TakeVidoViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface TakeVidoViewController ()
/* 捕获设备，通常是前置摄像头、后置摄像头、麦克风 */
@property (nonatomic, strong) AVCaptureDevice *device;
/* 输入设备，使用AVCaptureDevice来初始化 */
@property (nonatomic, strong) AVCaptureDeviceInput *input;
/* 输出视频 */
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieOutput;
/* 可以把输入输出结合在一起，并开始启动捕获设备(摄像头) */
@property (nonatomic, strong) AVCaptureSession *session;
/* 图像预览层，实时显示捕获的图像 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
/* 闪光灯 */
@property (nonatomic, assign) AVCaptureFlashMode mode;
/* 前后置摄像头 */
@property (nonatomic, assign) AVCaptureDevicePosition position;
/* cameraTool */
//@property (nonatomic, strong) ZSWCameraTool *cameraTool;
/* 聚焦框 */
@property (nonatomic, strong) UIView *focusView;

/* 获取屏幕方向 */
@property (nonatomic,strong) NSMutableDictionary * contentDic;
@end

@implementation TakeVidoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self performSelector:@selector(startSavePhoto) withObject:nil afterDelay:3];
    
    [self setupforCaptureSession];
    self.contentDic=[NSMutableDictionary dictionary];
}

/**
 一些参数值：
 1、照片大小
   AVCaptureSessionPresetHigh   Highest recording quality.This varies per device.
   AVCaptureSessionPresetMedium  Suitable for Wi-Fi sharing.The actual values may change.
   AVCaptureSessionPresetLow Suitable for 3G sharing.The actual values may change.
   AVCaptureSessionPreset352x288  CIF  AVCaptureSessionPreset640x480
   AVCaptureSessionPreset1280x720    1280x720    720p HD.
   AVCaptureSessionPreset1920x1080    1920x1080    1080P
   AVCaptureSessionPreset3840x2160    3840x2160    UHD or 4K
   
   AVCaptureSessionPresetiFrame1280x720    1280x720    Specifies capture settings to achieve 1280x720 quality iFrame H.264
   video at about 40 Mbits/sec with AAC audio.
          AVCaptureSessionPresetiFrame960x540    960x540    Specifies capture settings to achieve 960x540 quality iFrame H.264 video at about 30 Mbits/sec with AAC audio.
   2,前后摄像头
 
   */
//设置一个初始界面
-(void)setupforCaptureSession{
//------------第一个参数设置的地方-----显示大小
    self.session = [[AVCaptureSession alloc] init];
    
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset3840x2160]) {
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
    } else {
        NSLog(@"设置session失败");
    }
//------------第二个参数设置的地方-----前后摄像头
    self.position=AVCaptureDevicePositionBack;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for(AVCaptureDevice *device in devices) {
          
               if ([device hasMediaType:AVMediaTypeVideo]) {
                    if ([device position] ==  self.position) {
                        NSLog(@"Device position : back");
                        self.input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
                        if([self.session canAddInput:self.input]) {
                            [self.session addInput:self.input];
                            self.device=device;
                        }
                    }
//------------第三个参数设置的地方-----曝光
                    NSError * error=nil;

                   if([self.device lockForConfiguration:&error]) {
                       if ([self.device isExposureModeSupported:AVCaptureExposureModeCustom]){
                            CGPoint exposurePoint = CGPointMake(0.5f,0.5f);
                            [self.device setExposurePointOfInterest:exposurePoint];
                           [self.device setExposureTargetBias:2 completionHandler:nil];

                        [self.device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                       }
                   }
                   [self.device unlockForConfiguration];
                /**
                 typedef NS_ENUM(NSInteger, AVCaptureExposureMode) {
                     AVCaptureExposureModeLocked                            = 0,
                     AVCaptureExposureModeAutoExpose                        = 1,
                     AVCaptureExposureModeContinuousAutoExposure            = 2,
                     AVCaptureExposureModeCustom API_AVAILABLE(macos(10.15), ios(8.0)) = 3,
                 } API_AVAILABLE(macos(10.7), ios(4.0)) __WATCHOS_PROHIBITED __TVOS_PROHIBITED;
                 */

            if([self.device lockForConfiguration:&error]) {
                if([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                    [self.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
                }
                 [self.device unlockForConfiguration];
            }
        }
            
        else {
            NSLog(@"Device position : front");
        }
    }
    
       self.previewLayer.frame = [UIScreen mainScreen].bounds;
       [self.view.layer insertSublayer:self.previewLayer atIndex:0];
      

       if([self.session canAddOutput:self.imageOutput]) {
           [self.session addOutput:self.imageOutput];
       }
    [self.session beginConfiguration];
    [self.session commitConfiguration];
    [self.session startRunning];
        
}

-(void)startSavePhoto{
    /**
                    AVCaptureFlashModeOff  = 0,
                      AVCaptureFlashModeOn   = 1,
                      AVCaptureFlashModeAuto = 2,
                    */
//------------第四个参数设置的地方----------闪光灯
    NSError * error=nil;
    if([self.device lockForConfiguration:&error]) {
        if ([self.device hasTorch]){
               [self.device setTorchMode:AVCaptureTorchModeOn];
        }
          [self.device unlockForConfiguration];
     }
    if([self.device lockForConfiguration:&error]) {
        //自动闪光灯
        if([self.device isFlashModeSupported:AVCaptureFlashModeAuto]) {
            [self.device setFlashMode:AVCaptureFlashModeAuto];
        }
        [self.device unlockForConfiguration];
     }else {
        NSLog(@"%@",error);
    }
    //开始直接保存图片
    AVCaptureConnection *connect = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
      if(!connect) {
          NSLog(@"拍摄失败");
          return;
      }
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:connect completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
         //停止取景
         [self.session stopRunning];
        //默认是jpg
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
         
        //可以换成png
        UIImage * image=[UIImage imageWithData:imageData];
        UIImage * imagePNG= [UIImage imageWithData:UIImagePNGRepresentation(image)];
        //可以把png图片保存到相册
//------------第五个参数设置的地方----------编码方式，jpg 和 png
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        
    }];
}
- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo{
    if(error != NULL){
        
       NSLog(@"保存图片失败");
        
    }else{
        NSLog(@"保存图片成功");
        
    }
}
- (AVCaptureStillImageOutput *)imageOutput {
    if(!_movieOutput) {
        _movieOutput = [[AVCaptureMovieFileOutput alloc] init];
    }
    return _movieOutput;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if(!_previewLayer) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    }
    return _previewLayer;
}
@end
