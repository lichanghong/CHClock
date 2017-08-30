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
#import "TimeModel+CoreDataClass.h"
#import <MagicalRecord/MagicalRecord.h>


@interface ViewController ()
@property (nonatomic,strong)NSTimer *timer;
@property (nonatomic,strong)NSTimer *alertTimer;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIButton *closeAlertButton;

@property (nonatomic,strong)CHSpeechSynthesizer *speechSynthesizer;
@property (nonatomic,strong)CHAlertAVPlayer *alertAVPlayer;

@property (nonatomic,strong)NSArray *dataSource;

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
            [UIApplication sharedApplication].idleTimerDisabled = NO;

            NSLog(@"timer is valid, invalidate it");
        }
        else
        {
            NSLog(@"timer is invalidate，startTimer");
            [self startTimer];
            [UIApplication sharedApplication].idleTimerDisabled = YES;

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
    int hour = (int)[[NSUserDefaults standardUserDefaults]integerForKey:@"hour_key"];
    int minute = (int)[[NSUserDefaults standardUserDefaults]integerForKey:@"minite_key"];
    return [self futureDateWithHour:hour minute:minute];
}

- (NSString *)LeftMinute
{
    NSDate *futureDate = [self deadLineDate];
    double second = [futureDate secondsLaterThan:[self currentDate]];
    return [NSString stringWithFormat:@"%0.f",second/60.0];
}

- (void)makeLessThanParam:(BOOL)can
{
    NSArray *times = [TimeModel MR_findAll];
    int count = (int)[times count];
    for (int i=0; i<count; i++) {
        TimeModel *model = [times objectAtIndex:i];
        NSString *key = [NSString stringWithFormat:@"param_key_%d",model.withinTime];
        [[NSUserDefaults standardUserDefaults]setBool:can forKey:key];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)startTimer
{
    NSDate *currentDate = [self currentDate];
    NSDate *futureDate = [self deadLineDate];
    
    if ([futureDate isLaterThan:currentDate]) {
        if (futureDate.day == currentDate.day) {
            //同一天没超时的情况，定时
            [self makeLessThanParam:NO];
            __block BOOL isLessThan = NO;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
                [self.button setTitle:@"已启动" forState:UIControlStateNormal];
                //NSLog(@"timer = .....");
                double second = [futureDate secondsLaterThan:[self currentDate]];
                NSInteger alert_time =  [[NSUserDefaults standardUserDefaults]integerForKey:@"alert_time_key"];
                
                if (second<=alert_time*60 && isLessThan == NO) {
                    //alert sos
                    NSLog(@"1分钟内，警报");
                    [self endAlertTimer];
                    [self startSOS];
                    isLessThan = YES;
                }
                //排序
                NSArray *times = [TimeModel MR_findAll];
                self.dataSource = [times sortedArrayUsingComparator:^NSComparisonResult(TimeModel *obj1, TimeModel *obj2) {
                    if (obj1.withinTime>obj2.withinTime) {
                        return NSOrderedAscending;
                    }
                    return NSOrderedDescending;
                }];
                
                
                {
                    int count = [[TimeModel MR_numberOfEntities] intValue];
                    
                    //找最小
                    NSMutableArray *marr = [NSMutableArray array];
                    
                    for (int i=0; i<count; i++) {
                        TimeModel *model = [self.dataSource objectAtIndex:i];
                        if (second<=model.withinTime*60) {
                            [marr addObject:model];
                        }
                    }
                    [marr sortUsingComparator:^NSComparisonResult(TimeModel *obj1,TimeModel *obj2) {
                        return obj1.withinTime>obj2.withinTime?NSOrderedAscending:NSOrderedDescending;
                    }];
                   TimeModel* minTimeModel = [marr lastObject];
                    
                    NSString *key = [NSString stringWithFormat:@"param_key_%d",minTimeModel.withinTime];
                    if ([[NSUserDefaults standardUserDefaults]boolForKey:key] == NO) {
                        [self endAlertTimer];
                        [self startAlertTimerWithInterval:minTimeModel.intervalTime*60];
                        NSString *key = [NSString stringWithFormat:@"param_key_%d",minTimeModel.withinTime];
                        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:key];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                    
                   // NSLog(@"min=%d inter=%d",minTimeModel.withinTime,minTimeModel.intervalTime);
                }
                
            }];
            [self.timer fire];
            [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
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
