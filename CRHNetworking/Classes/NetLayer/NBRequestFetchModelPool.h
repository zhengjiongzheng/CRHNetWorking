//
//  NBRequestFetchModelPool.h
//  MaiTalk
//
//  Created by linsheng on 16/2/29.
//  Copyright © 2016年 linsheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBFetchModel.h"
@interface NBRequestFetchModelPool : NSObject

+(instancetype)sharedRequestPool;

/**
 *  缓存当前请求对象
 *
 *  @param model 请求对象
 */
-(void)retainRequetModel:(NBFetchModel*)model;

/**
 *  释放当前请求对象
 *
 *  @param model 请求对象
 */
-(void)releaseRequestModel:(NBFetchModel*)model;

/**
 *  清空对象
 */
-(void)drainRequestPool;

@end
