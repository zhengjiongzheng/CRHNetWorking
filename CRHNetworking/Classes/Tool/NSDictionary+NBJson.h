//
//  NSDictionary+NBJson.h
//  MaiTalk
//
//  Created by linsheng on 16/4/12.
//  Copyright © 2016年 linsheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (NBJson)

- (NSString *)nbJsonString;

+ (NSDictionary *)nbDictionaryWithJsonString:(NSString*)jsonString;

@end
