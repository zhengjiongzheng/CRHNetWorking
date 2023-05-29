//
//  NBFetchModel.h
//  NBFetchModel
//
//  Created by linsheng on 15/12/10.
//  Copyright © 2015年 linsheng. All rights reserved.
//

#import "NBJsonModel.h"

#define NBBizErrorDomain   @"NBBizErrorDomain"
//请求超时时间
#define NBBZTimeOutInt     20
@class NBFetchModel;
typedef void (^NBCompletionBlock) (BOOL isSucceeded, NSString *msg, NSError *error);
typedef void (^NBCompletionWithModelBlock) (BOOL isSucceeded, NSString *msg, NSError *error, NBFetchModel *model);
typedef void (^NBCompletionWithModelData) (BOOL isSucceeded, NSString *msg, NSError *error,id responseObjectData);

@interface NBFetchModel : NBJsonModel
//请求是否成功
@property (nonatomic, assign) BOOL boolLoadingSuccess;
//错误码 0为成功
@property (nonatomic, assign) long long flag;
//错误信息
@property (nonatomic, assign) NSString *resultDesc;
// 请求参数
@property (nonatomic, strong) NSDictionary *requestParams;
//是否请求中
@property (nonatomic, assign) BOOL boolRequesting;
//主动设置请求url
@property (nonatomic, copy) NSString *requestHost;
/**
 *  扩展容器 自动存储器
 *
 *  @return 回调
 */
- (instancetype)requestPoolAutoRetain;

/**
 *  form表单
 *
 *  @param path          地址
 *  @param completeBlock 回调
 */
- (void)fetchFormWithPath:(NSString *)path completionWithData:(NBCompletionWithModelData)completeBlock;

/**
 *  直接调 默认post
 *
 *  @param path          地址
 *  @param completeBlock 回调
 */
- (void)fetchWithPath:(NSString *)path completion:(NBCompletionBlock)completeBlock;


/**
 *  直接调用 返回model数据
 *
 *  @param path          地址
 *  @param completeBlock 回调
 */
- (void)fetchWithPath:(NSString *)path completionWithModel:(NBCompletionWithModelBlock)completeBlock;


- (void)fetchWithPath:(NSString *)path completionHandleWithModel:(NBCompletionWithModelData)completeBlock;


/**
 *  直接调用，返回data数据
 *
 *  @param path          地址
 *  @param completeBlock 回调
 */
- (void)fetchWithPath:(NSString *)path completionWithData:(NBCompletionWithModelData)completeBlock;

/**
 *  调用get方法
 *
 *  @param path          地址
 *  @param completeBlock 回调
 */
- (void)fetchGetWithPath:(NSString *)path completionWithData:(NBCompletionWithModelData)completeBlock;

/**
 *  取消请求
 */
- (void)cancelOperation;


/**
 *  Option 子类覆盖此方法，提供不同URL请求地址,不覆盖提供默认的基本url
 *
 *  @return 返回url
 */
- (NSString *)baseURLString;

/**
 文件上传
 */
- (void)uploadFileFetchWithPath:(NSString *)path completionWithData:(NBCompletionWithModelData)completeBlock ;

@end
