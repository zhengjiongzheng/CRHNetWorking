//
//  NBRequestFetchModelPool.m
//  MaiTalk
//
//  Created by linsheng on 16/2/29.
//  Copyright © 2016年 linsheng. All rights reserved.
//

#import "NBRequestFetchModelPool.h"

@interface NBRequestFetchModelPool ()

@property (nonatomic,strong) NSMutableSet *requestModelPoolSet;

@end

@implementation NBRequestFetchModelPool

+(instancetype)sharedRequestPool
{
    static NBRequestFetchModelPool *pool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pool = [[NBRequestFetchModelPool alloc]init];
    });
    return pool;
}

-(instancetype)init
{
    if (self = [super init]) {
        _requestModelPoolSet = [NSMutableSet set];
    }
    return self;
}

-(void)retainRequetModel:(NBFetchModel *)model
{
    if (model) {
        [_requestModelPoolSet addObject:model];
    }
}

-(void)releaseRequestModel:(NBFetchModel *)model
{
    if (model) {
        [_requestModelPoolSet removeObject:model];
    }
}

-(void)drainRequestPool
{
    [_requestModelPoolSet removeAllObjects];
}

@end
