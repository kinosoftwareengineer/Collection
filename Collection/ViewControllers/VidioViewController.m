
//  VidioViewController.m
//  Collection
//
//  Created by kino on 2019/11/15.
//  Copyright © 2019 ShuJuTang. All rights reserved.
//

#import "VidioViewController.h"
#import "PQVoiceInput.h"
#import "Masonry.h"
#define WIDTH  [UIScreen mainScreen].bounds.size.width
#define HEIGHT  [UIScreen mainScreen].bounds.size.height
@interface VidioViewController ()
@property (nonatomic,strong) PQVoiceInputView *voiceView1;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;

@end

@implementation VidioViewController
-(void)viewWillAppear:(BOOL)animated{
     [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(popVC) name:@"dismissVC" object:nil];
     [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(prepareRecord) name:@"prepare" object:nil];
     [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(recording) name:@"record" object:nil];
    
    
    
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self creatrUI];
   
   
}

-(void)creatrUI{
       int side=(int)[UIScreen mainScreen].bounds.size.height/6 ;
       self.voiceView1 = [PQVoiceInputView pgq_reateVoiceViewWithRect  : CGRectMake(0, 0, side, side)
                                                        voiceColor  : [UIColor colorWithRed:245/255.0 green:255/255.0 blue:246/255.0 alpha:0.5]
                          
                                                        volumeColor : [UIColor colorWithRed:0/255.0 green:160/255.0 blue:254/255.0 alpha:1]
                                                            title   : @""
                                                           showType : 1
                                                            hidden  : nil];
    
       [self.view addSubview:self.voiceView1];
     
    
       [self.voiceView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(HEIGHT/3.0*2);
        make.left.mas_equalTo([UIScreen mainScreen].bounds.size.width/2.0-side/2.0);
        make.height.mas_equalTo(side);
        make.width.mas_equalTo(side);
    }];
    
     dispatch_async(dispatch_get_main_queue(), ^{
              [self.voiceView1 updateTitle:@"" textColor:[UIColor whiteColor]];
           
        });
    self.stateLabel.text=@"准备录音";
}

-(void)popVC{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.voiceView1 stopCircleAnimation];
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}
-(void)viewWillDisappear:(BOOL)animated{
    
      [[NSNotificationCenter defaultCenter] removeObserver:self name:@"record" object:nil];
      [[NSNotificationCenter defaultCenter] removeObserver:self name:@"dismissVC" object:nil];
      [[NSNotificationCenter defaultCenter] removeObserver:self name:@"prepare" object:nil];
    
}
-(void)prepareRecord{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.stateLabel.text=@"停止录音";
        [self.voiceView1 stopCircleAnimation];
    });
}
-(void)recording{
    dispatch_async(dispatch_get_main_queue(), ^{
          self.stateLabel.text=@"录音中...";
           [self.voiceView1 startCircleAnimation];
    });
}
@end
