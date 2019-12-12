#import "TakeVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "XDXHardwareEncoder.h"

@interface TakeVideoViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession              *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer    *captureVideoPreviewLayer;

@end

@implementation TakeVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initCapture];
    [self initVideoEncoder];
}

- (void)initVideoEncoder {
    XDXHardwareEncoder *encoder = [XDXHardwareEncoder getInstance];
    // 修改enableH264, H265实现切换
    encoder.enableH264 = YES;
//     encoder.enableH265 = YES;
    [encoder prepareForEncode];
}

- (void)initCapture
{
    // 获取后置摄像头设备
    AVCaptureDevice *inputDevice            = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 创建输入数据对象
    AVCaptureDeviceInput *captureInput      = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
    if (!captureInput) return;
    
    // 创建一个视频输出对象
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    
    [captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    NSString     *key           = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber     *value         = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    
    [captureOutput setVideoSettings:videoSettings];
    
    
    self.captureSession = [[AVCaptureSession alloc] init];
    NSString *preset    = 0;
    if (!preset) preset = AVCaptureSessionPresetHigh;
    
    self.captureSession.sessionPreset = preset;
    if ([self.captureSession canAddInput:captureInput]) {
        [self.captureSession addInput:captureInput];
    }
    if ([self.captureSession canAddOutput:captureOutput]) {
        [self.captureSession addOutput:captureOutput];
    }
    
    // 创建视频预览图层
    if (!self.captureVideoPreviewLayer) {
        self.captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    }
    
    self.captureVideoPreviewLayer.frame         = [UIScreen mainScreen].bounds;
    self.captureVideoPreviewLayer.videoGravity  = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer     addSublayer:self.captureVideoPreviewLayer];
    [self.captureSession startRunning];
}

#pragma mark - Btn Click Event


#pragma mark ------------------AVCaptureVideoDataOutputSampleBufferDelegate--------------------------------
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    connection.videoOrientation=AVCaptureVideoOrientationPortrait;
    if( !CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog( @"sample buffer is not ready. Skipping sample" );
        return;
    }
    
    if([XDXHardwareEncoder getInstance] != NULL) {
        [[XDXHardwareEncoder getInstance] startWithWidth:2160 andHeight:3840 andFPS:30];
        [[XDXHardwareEncoder getInstance] encode:sampleBuffer];
    }
}

@end
