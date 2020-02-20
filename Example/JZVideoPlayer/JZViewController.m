//
//  JZViewController.m
//  JZVideoPlayer
//
//  Created by jason8zhang on 02/20/2020.
//  Copyright (c) 2020 jason8zhang. All rights reserved.
//

#import "JZViewController.h"
#import <JZVideoPlayer/JZVideoPlayerView.h>
#import <Masonry/Masonry.h>

@interface JZViewController ()
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property(nonatomic,strong) JZVideoPlayerView *playerView;

@end

@implementation JZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.containerView addSubview:self.playerView];
    [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)playBtnAction:(id)sender {
    [self.playerView play];
}
- (IBAction)pauseBtnAction:(id)sender {
    [self.playerView pause];
}
- (IBAction)nextBtnAction:(id)sender {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test2" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    [self.playerView setAssert:asset];
//    [AVURLAsset URLAssetWithURL:_url options:@{@"AVURLAssetHTTPHeaderFieldsKey": headers}];
}
- (JZVideoPlayerView *)playerView {
    
    if (!_playerView) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test1" ofType:@"mp4"];
        NSURL *url = [NSURL fileURLWithPath:filePath];
        _playerView = [[JZVideoPlayerView alloc] initWithUrl:url];
    }
    return _playerView;
}
@end
