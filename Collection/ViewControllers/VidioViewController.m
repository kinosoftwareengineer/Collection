//
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

@end

@implementation VidioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self creatrUI];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:@"stop" object:nil];
   
}
-(void)creatrUI{
       self.voiceView1 = [PQVoiceInputView pgq_reateVoiceViewWithRect:CGRectMake(0, 0, 100, 100) voiceColor:[UIColor cyanColor] volumeColor:[UIColor colorWithRed:117/255.0 green:224/255.0 blue:205/255.0 alpha:1] title:@"按下说话" showType:1 hidden:^(PQVoiceInputView * _Nullable view, NSString * _Nullable text, NSInteger type) {
       }];
       [self.view addSubview:self.voiceView1];
       [self.voiceView1 updateTitle:@"正在聆听" textColor:[UIColor greenColor]];
    [self.voiceView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(HEIGHT/3.0*2);
        make.left.mas_equalTo(self.view.frame.size.width/2.0-50);
        make.height.mas_equalTo(100);
        make.width.mas_equalTo(100);
    }];
       [self.voiceView1 startCircleAnimation];
}
-(void)stop{
    [self.voiceView1 stopCircleAnimation];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
