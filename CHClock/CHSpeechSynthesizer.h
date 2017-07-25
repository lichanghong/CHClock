//
//  CHSpeechSynthesizer.h
//  CHClock
//
//  Created by lichanghong on 7/25/17.
//  Copyright © 2017 lichanghong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHSpeechSynthesizer : NSObject

- (void)startString:(NSString *)str;
- (void)pause;
- (void)resume;
- (void)cancel;

@end
