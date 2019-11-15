//
//  COTime.m
//  Collection
//
//  Created by kino on 2019/11/15.
//  Copyright © 2019 ShuJuTang. All rights reserved.
//

#import "COTime.h"

@implementation COTime
+(NSString *)getTimeStamp{
    NSDate *datenow = [NSDate date];
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)([datenow timeIntervalSince1970]*1000)];
    return timeSp;
}
@end
