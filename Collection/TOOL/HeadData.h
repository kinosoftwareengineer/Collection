//
//  HeadData.h
//  Collection
//
//  Created by 平台部 on 2019/12/2.
//  Copyright © 2019 ShuJuTang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HeadData : NSObject
+(NSData *)WriteWavFileHeader:(long) totalAudioLen
                DtotalDataLen: (long) totalDataLen
                DlongSampleRate:(long) longSampleRate
                Dchannels:(int) channels
                DbyteRate:(long) byteRate;

@end

NS_ASSUME_NONNULL_END
