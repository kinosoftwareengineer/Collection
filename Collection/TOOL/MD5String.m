//
//  MD5String.m
//  Collection
//
//  Created by kino on 2019/11/15.
//  Copyright © 2019 ShuJuTang. All rights reserved.
//

#import "MD5String.h"
#import <CommonCrypto/CommonDigest.h>
@implementation MD5String
#pragma mark - 32位 大写
+(NSString *)MD5ForUpper32Bate:(NSString *)str{
    
    //要进行UTF8的转码
    const char* input = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(input, (CC_LONG)strlen(input), result);
    
    NSMutableString *digest = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [digest appendFormat:@"%02X", result[i]];
    }
    
    return digest;
}
@end
