#import "TakeVidoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "LZBRecordVideoTool.h"

@interface TakeVidoViewController ()

@property (nonatomic, strong) UIView *containerView;
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层
@property (nonatomic, strong) LZBRecordVideoTool *videoTool;
@property (nonatomic,assign)NSInteger count;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation TakeVidoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCaptureSession];
    [self performSelector:@selector(startRecordingVideo) withObject:nil afterDelay:2.0f];
    [self performSelector:@selector(endRecordingVideo) withObject:nil afterDelay:8.0f];
    [self.view addSubview:self.containerView];
    
}
- (void)setupCaptureSession
{
   self.captureVideoPreviewLayer  =  [self.videoTool previewLayer];
    CALayer *layer=self.containerView.layer;
    layer.masksToBounds=YES;
    self.captureVideoPreviewLayer.frame = layer.bounds;
    [layer addSublayer:self.captureVideoPreviewLayer];
    //开启录制功能
    [self.videoTool startRecordFunction];
}

#pragma mark- action
- (void)startRecordingVideo
{
    [self startTimer];
    [self.videoTool startCapture];
}

- (void)endRecordingVideo
{
    [self stopTimer];
    [self.videoTool stopCapture];
}

#pragma mark - 定时器
- (void)startTimer
{
    self.timer = [NSTimer  scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)updateProgress
{
    NSLog(@"%ld",self.count++);
}



#pragma mark - lazy


- (UIView *)containerView
{
  if(_containerView == nil)
  {
      _containerView = [[UIView alloc]initWithFrame:self.view.bounds];
      _containerView.backgroundColor = [UIColor clearColor];
  }
    return _containerView;
}




- (LZBRecordVideoTool *)videoTool
{
  if(_videoTool == nil)
  {
      _videoTool = [[LZBRecordVideoTool alloc]init];
  }
    return _videoTool;
}
@end
