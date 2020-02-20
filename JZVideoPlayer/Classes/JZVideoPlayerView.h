//
//  JZVideoPlayerView.h
//  JZVideoPlayer
//
//  Created by apple-new on 2020/2/20.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 设置视频播放填充模式
 */
typedef NS_ENUM(NSInteger, JZPlayerContentMode) {
    JZPlayerContentModeResizeFit,//尺寸适合
    JZPlayerContentModeResizeFitFill,//填充视图
    JZPlayerContentModeResize,//默认
};
typedef NS_ENUM(NSInteger, JZPlayerState) {
    JZPlayerStateFailed,        // 播放失败
    JZPlayerStateBuffering,     // 缓冲中
    JZPlayerStatePlaying,       // 播放中
    JZPlayerStateStopped,        //停止播放
};

@interface JZVideoPlayerView : UIView

//当视频没有播放为0,播放后是1
@property(nonatomic, assign) NSInteger isNormal;
//加载的image;
@property(nonatomic, strong) UIImageView *imageViewLogin;
//视频填充模式
@property(nonatomic, assign) JZPlayerContentMode contentMode;
//播放状态
@property(nonatomic, assign) JZPlayerState state;
//加载视图
//@property (nonatomic,strong) SBPlayerLoading *loadingView;
//是否正在播放
@property(nonatomic, assign, readonly) BOOL isPlaying;

@property(nonatomic, strong) UIImageView *playImage;
//暂停时的插图
//@property (nonatomic,strong) SBPlayerPlayPausedView *playPausedView;
//urlAsset
@property(nonatomic, strong) AVURLAsset *assert;
//当前时间
@property(nonatomic, assign) CMTime currentTime;

//播放器控制视图
//@property (nonatomic,strong) SBPlayerControl *playerControl;
//初始化
- (instancetype)initWithUrl:(NSURL *)url;

- (instancetype)initWithURLAsset:(AVURLAsset *)asset;

//跳到某个播放时间段
- (void)seekToTime:(CMTime)time;

//播放
- (void)play;

//暂停
- (void)pause;

//停止
- (void)stop;

//移除监听,notification,dealloc
- (void)remove;

//显示或者隐藏暂停按键
- (void)hideOrShowPauseView;

@end


NS_ASSUME_NONNULL_END
