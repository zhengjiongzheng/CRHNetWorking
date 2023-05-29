//
//  NBJsonModel.h
//  NBJSONModelDemo
//
//  Created by linsheng on 15/11/30.
//  Copyright © 2015年 linsheng. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface NBJsonModel : NSObject<NSCoding,NSCopying>

/**
 *  字典初始化
 *
 *  @param dict 字典对象
 *
 *  @return 对象
 */
- (instancetype)initWithJSONDict:(NSDictionary *)dict;

/**
 *  字典重置
 *
 *  @param jsonData 字典对象
 */
- (void)injectJSONData:(NSDictionary*)jsonData;

/**
 *  对象重置
 *
 *  @param model 数据对象
 */
- (void)injectDataWithModel:(NBJsonModel*)model;

/**
 *  获取字典
 *
 *  @return 字典
 */
- (NSDictionary *)jsonDict;

/**
 *  获取字符串
 *
 *  @return 字符串
 */
- (NSString *)jsonString;

@end
