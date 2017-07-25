//
//  CHAlertAVPlayer.m
//  CHClock
//
//  Created by lichanghong on 7/25/17.
//  Copyright © 2017 lichanghong. All rights reserved.
//

#import "CHAlertAVPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface CHAlertAVPlayer ()
@property (strong, nonatomic) AVPlayer *audioPlayer;
@property (strong, nonatomic) NSTimer *runloopTimer;

@end

@implementation CHAlertAVPlayer

-(void) keepVolumeMax:(NSTimer*)timer
{
    //these two will not alter system settings
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
    musicPlayer.volume = 1.0f;
    if (self.audioPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        NSURL* fileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"alarm.mp3" ofType:nil]];
        AVPlayerItem * currentItem = [AVPlayerItem playerItemWithURL:fileURL];
        [self.audioPlayer replaceCurrentItemWithPlayerItem:currentItem];
        [self.audioPlayer play];
    }
}

-(void)startAlarm
{
    [self stopAlarm];
    @synchronized(self)
    {
        if(self.audioPlayer==nil) //for background play, this object MUST be initialized during foreground running?
        {
            self.audioPlayer = [[AVPlayer alloc] init];
        }
        NSURL* fileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"alarm.mp3" ofType:nil]];
        
        AVPlayerItem * currentItem = [AVPlayerItem playerItemWithURL:fileURL];
        [self.audioPlayer replaceCurrentItemWithPlayerItem:currentItem];
        
        self.runloopTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                          target:self
                                                        selector:@selector(keepVolumeMax:)
                                                        userInfo:nil
                                                         repeats:YES];
        [self.audioPlayer play];
     }
}

-(void)stopAlarm
{
    @synchronized(self)
    {
        [self.audioPlayer pause];
        self.audioPlayer=nil;
        [self.runloopTimer invalidate];
    }
}




@end
