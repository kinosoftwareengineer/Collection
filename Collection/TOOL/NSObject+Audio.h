//
//  NSObject+Audio.h
//  DTRecorder
//
//  Created by NSDeveloper on 10/12/15.
//  Copyright © 2015 DataTang Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Audio)

+ (void)removeFLLRfromWavHeader:(NSString *)wavPath;
+ (void)removeJUNKfromWavHeader:(NSString *)wavPath;

@end
