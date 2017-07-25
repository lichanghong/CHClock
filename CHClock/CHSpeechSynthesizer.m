//
//  CHSpeechSynthesizer.m
//  CHClock
//
//  Created by lichanghong on 7/25/17.
//  Copyright © 2017 lichanghong. All rights reserved.
//

#import "CHSpeechSynthesizer.h"
#import <AVFoundation/AVFAudio.h>

@interface CHSpeechSynthesizer ()<AVSpeechSynthesizerDelegate>
@property (nonatomic,strong) AVSpeechSynthesizer* speechSynthesizer;


@end

@implementation CHSpeechSynthesizer

- (void)startString:(NSString *)str
{
    if ([self.speechSynthesizer isPaused]) {
        [self.speechSynthesizer continueSpeaking];
    }
    [_speechSynthesizer speakUtterance:[self speechUtteranceWithString:str]];//开始
}
- (void)pause
{
    if ([self.speechSynthesizer isSpeaking]) {
        [self.speechSynthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryWord];//暂停
    }
}
- (void)cancel
{
    if (![self.speechSynthesizer isPaused]) {
       // [self.speechSynthesizer ];//暂停
    }
}

- (void)resume
{
    if ([self.speechSynthesizer isPaused]) {
        [self.speechSynthesizer continueSpeaking];
    }
}
- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didStartSpeechUtterance:(AVSpeechUtterance*)utterance{
    NSLog(@"---开始播放");
    
}
- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance*)utterance{
    
    NSLog(@"---完成播放");
    
}
- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance*)utterance{
    
    NSLog(@"---播放中止");
    
}
- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance*)utterance{
    
    NSLog(@"---恢复播放");
    
}

- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance*)utterance{
    
    NSLog(@"---播放取消");
    
}

- (AVSpeechUtterance *)speechUtteranceWithString:(NSString *)string
{
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:string];
    utterance.rate=0.5;// 设置语速，范围0-1，注意0最慢，1最快；AVSpeechUtteranceMinimumSpeechRate最慢，AVSpeechUtteranceMaximumSpeechRate最快
    AVSpeechSynthesisVoice* voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];//设置发音，这是中文普通话
    utterance.voice= voice;
    return utterance;
}

- (AVSpeechSynthesizer *)speechSynthesizer
{
    if (!_speechSynthesizer) {
        _speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
        _speechSynthesizer.delegate = self;
    }
    return _speechSynthesizer;
}


@end
