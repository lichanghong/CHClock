//
//  BackgroundTask.m
// MobiSentry
//
//  Created by MobiSentry on 12/31/13.
//

#import "BackgroundTask.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

void interruptionListenerCallback (void *inUserData, UInt32 interruptionState);

@implementation BackgroundTask
static  AVAudioPlayer *player;
static UIBackgroundTaskIdentifier bgTask;

-(id) init
{
    self = [super init];
    if(self)
    {
        bgTask =UIBackgroundTaskInvalid;
    }
    return  self;
}

+(void) startAudioTasks
{
    if(player != nil && [player isPlaying]){
        return;
    }
    [self initBackgroudTask];
}

+(void) initBackgroudTask
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       if([self running])
                           [self stopAudio];
                       
                       while([self running])
                       {
                           [NSThread sleepForTimeInterval:1]; //wait for finish
                       }
                       [self playAudio];
                   });
}


+(void) audioInterrupted:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    NSNumber *interuptionType = [interuptionDict valueForKey:AVAudioSessionInterruptionTypeKey];
    if([interuptionType intValue] == 1)
    {
        [self initBackgroudTask];
    }
}

void interruptionListenerCallback (void *inUserData, UInt32 interruptionState)
{
    if (interruptionState == kAudioSessionBeginInterruption)
    {
        /// [self initBackgroudTask];
    }
}

+(void) playAudio
{
    UIApplication * app = [UIApplication sharedApplication];
    NSString *version = [[UIDevice currentDevice] systemVersion];
    if([version floatValue] >= 6.0f)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
    }
    else
    {
        AudioSessionInitialize(NULL, NULL, interruptionListenerCallback, nil);
    }
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        [player stop];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *resourceName = @"silence";
        NSURL* fileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:resourceName ofType:@"mp3"]];
        
        OSStatus osStatus;
        NSError * error;
        if([version floatValue] >= 6.0f)
        {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
            [[AVAudioSession sharedInstance] setActive: YES error: &error];
        }
        else
        {
            osStatus = AudioSessionSetActive(true);
            UInt32 category = kAudioSessionCategory_MediaPlayback;
            osStatus = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
            UInt32 allowMixing = true;
            osStatus = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof (allowMixing), &allowMixing );
        }
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
        player.volume = 0.1;
        player.numberOfLoops = -1; //Infinite
        [player prepareToPlay];
        [player play];
    });
}

+ (void)sleepAudio
{
    if (player.isPlaying) {
        [player stop];
    }
    else
    {
        [player prepareToPlay];
        [player play];
    }
}

+(void) stopAudio
{
    NSString *version = [[UIDevice currentDevice] systemVersion];
    
    if([version floatValue] >= 6.0f)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
    }
  
    if(player != nil && [player isPlaying])
    {
        [player stop];
    }
    
    if(bgTask != UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
}
+(BOOL) running
{
    if(bgTask == UIBackgroundTaskInvalid)
        return FALSE;
    return TRUE;
}

+(void) stopAudioTask
{
    [self stopAudio];
}
 
@end
