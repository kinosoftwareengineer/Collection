//
//  MD5String.h
//  Collection
//
//  Created by kino on 2019/11/15.
//  Copyright © 2019 ShuJuTang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MD5String : NSObject
#pragma mark - 32位 大写
+(NSString *)MD5ForUpper32Bate:(NSString *)str;
@end

NS_ASSUME_NONNULL_END
