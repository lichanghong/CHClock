//
//  BackgroundAudoTask.h
//  MobiSentry
//
//  Created by MobiSentry on 12/31/13.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface BackgroundTask : NSObject

+(void) startAudioTasks;
+(void) stopAudioTask;

+ (void)sleepAudio;

@end
