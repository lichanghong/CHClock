//
//  ViewController.m
//  CHClock
//
//  Created by lichanghong on 7/25/17.
//  Copyright © 2017 lichanghong. All rights reserved.
//

#import "ViewController.h"
#import <DateTools/DateTools.h>
#import "CHSpeechSynthesizer.h"
#import "CHAlertAVPlayer.h"

@interface ViewController ()
@property (nonatomic,strong)NSTimer *timer;
@property (nonatomic,strong)NSTimer *alertTimer;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIButton *closeAlertButton;

@property (nonatomic,strong)CHSpeechSynthesizer *speechSynthesizer;
@property (nonatomic,strong)CHAlertAVPlayer *alertAVPlayer;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"start.....");
    [self startTimer];
    

    // Do any additional setup after loading the view, typically from a nib.
}

- (CHSpeechSynthesizer *)speechSynthesizer
{
    if (!_speechSynthesizer) {
        _speechSynthesizer = [[CHSpeechSynthesizer alloc]init];
    }
    return _speechSynthesizer;
}

- (CHAlertAVPlayer *)alertAVPlayer
{
    if (!_alertAVPlayer ) {
        _alertAVPlayer = [[CHAlertAVPlayer alloc]init];
    }
    return _alertAVPlayer;
}

- (IBAction)handleAction:(id)sender {
    if (self.button == sender) {
        if (self.timer.isValid) {
            [self.timer invalidate];
            self.timer = nil;
            [self.button setTitle:@"未启动" forState:UIControlStateNormal];
            [self endSOS];
            [self endAlertTimer];
            
            NSLog(@"timer is valid, invalidate it");
        }
        else
        {
            NSLog(@"timer is invalidate，startTimer");
            [self startTimer];
            
        }

    }
    else if(self.closeAlertButton == sender)
    {
        [self endSOS];
    }
}

- (NSDate *)currentDate
{
    NSDate *date = [NSDate date];
    NSDate *currentDate = [date dateByAddingHours:8];
    return currentDate;
}

- (NSDate *)futureDateWithHour:(int)hour minute:(int)minute
{
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components =  [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:date];
    components.hour = hour;
    components.minute = minute;
    [components setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSDate *futureDate = [calendar dateFromComponents:components];
    return futureDate;
}
- (NSDate *)deadLineDate
{
    return [self futureDateWithHour:8 minute:30];
}

- (NSString *)LeftMinute
{
    NSDate *futureDate = [self deadLineDate];
    double second = [futureDate secondsLaterThan:[self currentDate]];
    return [NSString stringWithFormat:@"%0.f",second/60.0];
}

- (void)startTimer
{
    NSDate *currentDate = [self currentDate];
    NSDate *futureDate = [self deadLineDate];
    
    if ([futureDate isLaterThan:currentDate]) {
        if (futureDate.day == currentDate.day) {
            //同一天没超时的情况，定时
            __block BOOL isLessThan30 = NO;
            __block BOOL isLessThan10 = NO;
            __block BOOL isLessThan5 = NO;
            __block BOOL isLessThan1 = NO;

            self.timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
                [self.button setTitle:@"已启动" forState:UIControlStateNormal];
                //NSLog(@"timer = .....");
                double second = [futureDate secondsLaterThan:[self currentDate]];
                if (second<=60 && isLessThan1 == NO) {
                    //alert sos
                    NSLog(@"1分钟内，警报");
                    isLessThan1 = YES;
                    [self endAlertTimer];
                    [self startSOS];
                }
                else if (second<=300 && isLessThan5 == NO) {
                    NSLog(@"5分钟内，每分钟提醒一次");
                    isLessThan5 = YES;
                    [self endAlertTimer];
                    [self startAlertTimerWithInterval:60];
                }
                else if (second<=600 && isLessThan10 == NO) {
                    NSLog(@"10分钟内，每2分钟提醒一次");
                    isLessThan10 = YES;
                    [self endAlertTimer];
                    [self startAlertTimerWithInterval:2*60];
                }
                else if (second<=60*30 && isLessThan30 == NO) {
                    NSLog(@"30分钟内，每5分钟提醒一次");
                    isLessThan30 = YES;
                    [self endAlertTimer];
                    [self startAlertTimerWithInterval:5*60];
                }
                NSLog(@"%f....",second);
             
            }];
            [self.timer fire];

        }
        else NSLog(@"day is not equal");
    }
    else NSLog(@"future date is not later than current");
}

- (void)startSOS
{
    [self.alertAVPlayer startAlarm];

    NSLog(@"startSOS.....");
}
- (void)endSOS
{
    [self.alertAVPlayer stopAlarm];
}

- (void)startAlertTimerWithInterval:(NSInteger)interval
{
    __weak typeof(self) weakself = self;
    self.alertTimer = [NSTimer scheduledTimerWithTimeInterval:interval repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSDate *currentDate = [NSDate date];
        NSString *speechstr = [NSString stringWithFormat:@"现在是%ld点%ld分,还剩%@分钟", (long)currentDate.hour, (long)currentDate.minute,[self LeftMinute]];
        [weakself speechStr:speechstr];
    }];
    [self.alertTimer fire];
}

- (void)endAlertTimer
{
    [self.alertTimer invalidate];
    self.alertTimer = nil;
}

- (void)speechStr:(NSString *)timestr
{
    NSString *str = timestr;
    [self.speechSynthesizer startString:str];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
