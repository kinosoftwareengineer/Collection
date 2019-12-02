//
//  NSObject+Audio.m
//  DTRecorder
//
//  Created by NSDeveloper on 10/12/15.
//  Copyright © 2015 DataTang Inc. All rights reserved.
//

#import "NSObject+Audio.h"

@implementation NSObject (Audio)

+ (void)removeChunk:(NSString* )chunk fromWavHeader:(NSString *)wavPath {
    if (chunk.length!=4) {
        NSLog(@"传入Chunk名称错误！！！");
        return ;
    }

    @autoreleasepool {
        NSMutableData *data = [NSMutableData dataWithContentsOfFile:wavPath];
        NSInteger len = data.length;
        if (len<4096) {
            return;
        }
        
        int start = 0,end=0;
        Byte *bytes = data.mutableBytes;
        NSInteger audioLen = bytes[4] | (bytes[5]<<8) | (bytes[6]<<16) | (bytes[7]<<24);
        unichar first = [chunk characterAtIndex:0];
        unichar second = [chunk characterAtIndex:1];
        unichar third = [chunk characterAtIndex:2];
        unichar fourth = [chunk characterAtIndex:3];
        for (int i=0; i<len-5; i++) {
            if (bytes[i]==first&&
                bytes[i+1]==second&&
                bytes[i+2]==third&&
                bytes[i+3]==fourth) {
                start = i;
                i+=4;
                continue;
            }
            if (start>0&&isalnum(bytes[i])) {
                end = i;
                break;
            }
        }
        if (end>start) {
            NSInteger chunkLen = end-start;
            [data replaceBytesInRange:NSMakeRange(start, chunkLen) withBytes:NULL length:0];
            NSInteger fileLen = audioLen-chunkLen; //data.length-8
            bytes[4] = (Byte) (fileLen & 0xff);
            bytes[5] = (Byte) ((fileLen >> 8) & 0xff);
            bytes[6] = (Byte) ((fileLen >> 16) & 0xff);
            bytes[7] = (Byte) ((fileLen >> 24) & 0xff);
            [data writeToFile:wavPath atomically:YES];
        }
        else {
            NSLog(@"该音频未找到为%@的Chunk",chunk);
        }
    }
}

@end
