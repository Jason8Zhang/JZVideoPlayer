//
//  JZVideoPlayerView.m
//  JZVideoPlayer
//
//  Created by apple-new on 2020/2/20.
//

#import "JZVideoPlayerView.h"

@interface JZVideoPlayerView () {
    NSURL *_url;
}
@property(nonatomic, strong) AVPlayerLayer *playerLayer;
@property(nonatomic, strong) AVPlayer *player;
@property(nonatomic, strong) AVPlayerItem *item;
//总时长
@property(nonatomic, assign) CGFloat totalDuration;
//监听播放值
@property(nonatomic, strong) id playbackTimerObserver;
//加载Loading提示
@property(nonatomic, strong) UIActivityIndicatorView *activityInDicatorView;
@end

@implementation JZVideoPlayerView

- (instancetype)initWithUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
        [self initAsset];
        [self setupPlayer];
    }
    return self;
}

- (instancetype)initWithURLAsset:(AVURLAsset *)asset {
    self = [super init];
    if (self) {
        self.assert = asset;
        [self setupPlayer];
    }
    return self;
}

- (void)setupPlayer {

    [self configPlayer];
    [self addLoadingView];
    [self addKVO];
    [self addNotification];
    [self showaAtivityInDicatorView:YES];
    [self addPlayView];
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}

#pragma mark - ConfigPlayer

- (void)initAsset {

    if (_url) {
        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        [headers setObject:@"https://www.qidian.com/" forKey:@"Referer"];
        self.assert = [AVURLAsset URLAssetWithURL:_url options:@{@"AVURLAssetHTTPHeaderFieldsKey": headers}];
    }
}

//配置播放器
- (void)configPlayer {

    self.backgroundColor = [UIColor blackColor];
    self.item = [AVPlayerItem playerItemWithAsset:self.assert];
    self.player = [[AVPlayer alloc] init];
    [self.player replaceCurrentItemWithPlayerItem:self.item];
    self.player.usesExternalPlaybackWhileExternalScreenIsActive = YES;
    self.playerLayer = [[AVPlayerLayer alloc] init];
    self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    self.playerLayer.player = self.player;
    self.playerLayer.frame = self.bounds;
    [self.playerLayer displayIfNeeded];
    [self.layer insertSublayer:self.playerLayer atIndex:0];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
}

//显示或者隐藏暂停按键
- (void)hideOrShowPauseView {

    if (!_isNormal) {
        self.playImage.hidden = YES;
        [self.player play];
    } else {
        self.playImage.hidden = NO;
        [self.player pause];
    }
    _isNormal = !_isNormal;
}

- (void)addLoadingView {

    self.activityInDicatorView = [[UIActivityIndicatorView alloc] init];
    [self addSubview:self.activityInDicatorView];
    [self.activityInDicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(100, 100));
        make.center.mas_equalTo(self);
    }];
}

- (void)addPlayView {

    self.playImage = [[UIImageView alloc] init];
    [self addSubview:self.playImage];
    [self.playImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(40, 40));
        make.center.mas_equalTo(self);
    }];
    self.playImage.image = [UIImage imageNamed:@"video_play"];

    UIButton *playBtn = [[UIButton alloc] init];
    [self addSubview:playBtn];
    [playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    [playBtn addTarget:self action:@selector(hideOrShowPauseView) forControlEvents:UIControlEventTouchUpInside];
}

- (void)showaAtivityInDicatorView:(BOOL)show {

    if (show) {

        [self.activityInDicatorView startAnimating];
    } else {
        [self.activityInDicatorView stopAnimating];
        [self.activityInDicatorView removeFromSuperview];
    }
}

- (void)addKVO {

    //监听状态属性
    [self.item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监听网络加载情况属性
    [self.item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监听播放的区域缓存是否为空
    [self.item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    //缓存可以播放的时候调用
    [self.item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    //监听暂停或者播放中
    [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    [self.player addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {

    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerStatusUnknown: {
                NSLog(@"未知状态");
                self.state = YWWriterPlayerStateBuffering;
                [self showaAtivityInDicatorView:NO];
            }
                break;
            case AVPlayerStatusReadyToPlay: {
                NSLog(@"开始播放状态");
                self.state = YWWriterPlayerStatePlaying;
                //总时长
                self.totalDuration = self.item.duration.value / self.item.duration.timescale;
                //转换成时间格式的总时长
                NSLog(@"视频总时长 ---> %f", self.totalDuration);
                [self showaAtivityInDicatorView:NO];
            }
                break;
            case AVPlayerStatusFailed:
                self.state = YWWriterPlayerStateFailed;
                NSLog(@"播放失败");
                [self showaAtivityInDicatorView:NO];
                break;
            default:
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {  //监听播放器的下载进度
        NSArray *loadedTimeRanges = [self.item loadedTimeRanges];
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
        CMTime duration = self.item.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        //缓存值
        //        self.playerControl.bufferValue=timeInterval / totalDuration;
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) { //监听播放器在缓冲数据的状态
        self.state = YWWriterPlayerStateBuffering;
        NSLog(@"缓冲不足暂停");
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        NSLog(@"缓冲达到可播放");
    } else if ([keyPath isEqualToString:@"rate"]) {//当rate==0时为暂停,rate==1时为播放,当rate等于负数时为回放
        if ([[change objectForKey:NSKeyValueChangeNewKey] integerValue] == 0) {
            _isPlaying = false;
        } else {
            _isPlaying = true;
        }
    } else if ([keyPath isEqualToString:@"timeControlStatus"]) {
        //timeControlStatus==0是暂停,==1时播放
        NSLog(@"timeControlStatus:%@", [change objectForKey:NSKeyValueChangeNewKey]);

    }
}

- (void)addNotification {

    //监听当视频播放结束时
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
}

- (void)playerItemDidPlayToEndTimeNotification:(NSNotification *)notification {

    [self.item seekToTime:kCMTimeZero];
    [self.player pause];
    _isNormal = 0;
    self.playImage.hidden = NO;

}

//将数值转换成时间
- (NSString *)convertTime:(CGFloat)second {

    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second / 3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}

//设置播放器大小
- (void)setFrame:(CGRect)frame {

    self.playerLayer.frame = frame;
}

//获取当前时间
- (CMTime)currentTime {

    return self.item.currentTime;
}

//设置视频填充模式
- (void)setContentMode:(YWWriterPlayerContentMode)contentMode {

    switch (contentMode) {
        case YWWriterPlayerContentModeResizeFit:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case YWWriterPlayerContentModeResizeFitFill:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        case YWWriterPlayerContentModeResize:
            self.playerLayer.videoGravity = AVLayerVideoGravityResize;
            break;
    }
}

- (void)seekToTime:(CMTime)time {

    [self.item seekToTime:time];
}

- (void)play {

    if (self.player != nil) {
        [self.playerLayer isReadyForDisplay];
        [self.player play];
    }
}

- (void)pause {

    if (self.player != nil) {
        [self.player pause];
    }
}

- (void)stop {

    [self.item seekToTime:kCMTimeZero];
    [self.player pause];
    _isNormal = 0;
}

- (void)remove {

    [self.item removeObserver:self forKeyPath:@"status"];
    [self.item removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.player removeObserver:self forKeyPath:@"rate"];
    [self.player removeObserver:self forKeyPath:@"timeControlStatus"];
    [self.player removeTimeObserver:self.playbackTimerObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemTimeJumpedNotification object:[self.player currentItem]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemTimeJumpedNotification object:[self.player currentItem]];
    [self.item seekToTime:kCMTimeZero];
    self.assert = nil;
    [self.player setRate:0];
    [self.player pause];
    self.item = nil;
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.playerLayer.player = nil;
    self.totalDuration = 0;
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    [self.playerLayer removeFromSuperlayer];
    [self removeFromSuperview];
}

- (void)dealloc {

    [self remove];
}

@end
