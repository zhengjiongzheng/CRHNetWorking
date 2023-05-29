//
//  NBFetchModel.m
//  NBFetchModel
//
//  Created by linsheng on 15/12/10.
//  Copyright (c) 2015年 linsheng. All rights reserved.
//

#import "NBFetchModel.h"
#import "AFNetworking.h"
#import "NSObject+NBProperties.h"
#import "NBRequestFetchModelPool.h"
#import "NSDictionary+NBJson.h"
//#import "MPErrorCodeManager.h"
@interface NBFetchModel ()

@property (nonatomic, readonly) AFHTTPSessionManager *sessionManager;
@property (nonatomic) NSURLSessionDataTask *sessionTask;

@end

@implementation NBFetchModel

@synthesize sessionManager = _sessionManager;
- (void)dealloc {
    [_sessionTask cancel];
}

- (void)cancelOperation {
    [_sessionTask cancel];
}

- (AFHTTPSessionManager *)sessionManager {
    
    NSString *host;
    if (self.requestHost) {
        host=self.requestHost;
    }
//    else host = [NSString stringWithFormat:@"%@://%@", NBREQ_HOST_PROTOCAL, NBREQ_HOST];
    if (self.baseURLString.length && ![self.baseURLString isEqualToString:host]) {
        NSURL *baseURL = [NSURL URLWithString:[self baseURLString]];
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
        _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/javascript", @"text/plain",@"application/javascript", nil];
        _sessionManager.requestSerializer.timeoutInterval = NBBZTimeOutInt;
//        [_sessionManager setSecurityPolicy:[self customSecurityPolicy]];
        return _sessionManager;
    }
    static AFHTTPSessionManager *manager;
    if (!manager) {
        NSURL *baseURL = [NSURL URLWithString:host];
        manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/javascript", @"text/plain",@"application/javascript", nil];
//		[manager setSecurityPolicy:[self customSecurityPolicy]];
        manager.requestSerializer.timeoutInterval = NBBZTimeOutInt;
    }
    return manager;
}

-  (AFSecurityPolicy *)customSecurityPolicy
{
    //先导入证书，找到证书的路径
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"ssl" ofType:@"cer"];
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    
    //AFSSLPinningModeCertificate 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    
    //allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    //如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    
    //validatesDomainName 是否需要验证域名，默认为YES；
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    securityPolicy.validatesDomainName = NO;
    NSSet *set = [[NSSet alloc] initWithObjects:certData, nil];
    securityPolicy.pinnedCertificates = set;
    
    return securityPolicy;
}


- (NSString *)baseURLString {
    return @"";
}

#pragma mark

- (instancetype)requestPoolAutoRetain {
    [[NBRequestFetchModelPool sharedRequestPool] retainRequetModel:self];
    return self;
}

#pragma marl

- (NSDictionary *)setupFetchReqPrams {
    NSMutableDictionary *reqPrams = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"iOS", @"sdkVersion", nil];
    [reqPrams addEntriesFromDictionary:_requestParams];
    return reqPrams;
}

- (void)fetchWithPath:(NSString *)path completionWithModel:(NBCompletionWithModelBlock)completeBlock {
    __weak typeof(self) weakSelf = self;
    [self fetchWithPath:path
             completion:^(BOOL isSucceeded, NSString *msg, NSError *error) {
                 if (completeBlock) {
                     completeBlock(isSucceeded, msg, error, weakSelf);
                 }
             }];
}

- (void)fetchWithPath:(NSString *)path completion:(NBCompletionBlock)completeBlock {

    [self fetchWithPath:path
        completionWithData:^(BOOL isSucceeded, NSString *msg, NSError *error, id responseObjectData) {
            if (completeBlock) {
                completeBlock(isSucceeded, msg, error);
            }
        }];
}

- (void)fetchWithPath:(NSString *)path completionHandleWithModel:(NBCompletionWithModelData)completeBlock {
    
    [self fetchWithPath:path
     completionWithData:^(BOOL isSucceeded, NSString *msg, NSError *error, id responseObjectData) {
         if (completeBlock) {
             completeBlock(isSucceeded, msg, error,responseObjectData);
         }
     }];
}


- (void)fetchGetWithPath:(NSString *)path completionWithData:(NBCompletionWithModelData)completeBlock {
    _boolRequesting = true;
    __weak typeof(self) weakSelf = self;
    
    [self.sessionManager GET:path parameters:_requestParams headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completeBlock) {
            completeBlock(YES, nil, nil, responseObject);
        }
        weakSelf.boolRequesting = false;
        weakSelf.boolLoadingSuccess = true;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completeBlock && error.code != -999) {
            NSString *msg = [error.userInfo objectForKey:NSLocalizedDescriptionKey];
            if (error.code == -1009 || error.code == -1005) {
                msg = @"网络无连接";
            } else if (error.code == -1001) {
                msg = @"网络不好";
            }
            completeBlock(NO, msg, error, nil);
        }
        weakSelf.boolRequesting = false;
        weakSelf.boolLoadingSuccess = false;
    }];
}

- (void)fetchFormWithPath:(NSString *)path completionWithData:(NBCompletionWithModelData)completeBlock {
    __weak typeof(self) weakSelf = self;
    _boolRequesting = true;
    NSMutableDictionary *reqPrams = [NSMutableDictionary dictionary];
    [reqPrams addEntriesFromDictionary:[self setupFetchReqPrams]];
    NSMutableDictionary *imageDictionary = [@{} mutableCopy];
    for (NSInteger i = reqPrams.allValues.count - 1; i >= 0; i--) {
        id data = reqPrams.allValues[i];
        NSString *key = reqPrams.allKeys[i];
        if ([data isKindOfClass:[NSData class]] || [data isKindOfClass:[UIImage class]]) {
            [imageDictionary setObject:data forKey:key];
            [reqPrams removeObjectForKey:key];
        }
    }
    [_sessionTask cancel];

    self.sessionTask = [self.sessionManager POST:path parameters:reqPrams headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (NSString *key in imageDictionary.allKeys) {
            id data = imageDictionary[key];
            if ([data isKindOfClass:[NSData class]]) {
                [formData appendPartWithFileData:data name:key fileName:key mimeType:@"image/png"];
            } else if ([data isKindOfClass:[UIImage class]]) {
                NSData *datanew = UIImageJPEGRepresentation(data, 0.1);
                [formData appendPartWithFileData:datanew name:key fileName:[NSString stringWithFormat:@"%@.jpg", key] mimeType:@"image/jpg"];
            }
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (!weakSelf) {
            return;
        }

        [weakSelf loadSuccessWithTask:task data:responseObject completionWithData:completeBlock];
        weakSelf.boolRequesting = false;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (!weakSelf) {
            return;
        }

        [weakSelf loadFailWithTask:task error:error completionWithData:completeBlock];
        weakSelf.boolRequesting = false;
    }];
}

- (void)uploadFileFetchWithPath:(NSString *)path completionWithData:(NBCompletionWithModelData)completeBlock {
    
    NSMutableDictionary *reqPrams = [NSMutableDictionary dictionary];
    [reqPrams addEntriesFromDictionary:[self setupFetchReqPrams]];
    [_sessionTask cancel];
    _boolRequesting = true;
//    [self setCookie];
    
    self.sessionTask = [self.sessionManager POST:path parameters:reqPrams headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *uploadData = [reqPrams objectForKey:@"file"];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSString *str = [formatter stringFromDate:[NSDate date]];
        NSString *fileName = [NSString stringWithFormat:@"%@.jpeg", str];
        [formData appendPartWithFileData:uploadData name:@"file" fileName:fileName mimeType:@"image/jpeg"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if(completeBlock){
            completeBlock(YES,@"",nil,responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(completeBlock){
            completeBlock(NO,@"",error,nil);
        }
    }];
}

- (void)fetchWithPath:(NSString *)path completionWithData:(NBCompletionWithModelData)completeBlock {
    __weak typeof(self) weakSelf = self;
    NSMutableDictionary *reqPrams = [NSMutableDictionary dictionary];
    [reqPrams addEntriesFromDictionary:[self setupFetchReqPrams]];
    [_sessionTask cancel];
    _boolRequesting = true;
    [self setCookie];
    
    
    self.sessionTask = [self.sessionManager POST:path parameters:reqPrams headers:nil progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (!weakSelf) {
            return;
        }
        [weakSelf loadSuccessWithTask:task data:responseObject completionWithData:completeBlock];
        weakSelf.boolRequesting = false;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (!weakSelf) {
            return;
        }
        NSData *data = error.userInfo[@"com.alamofire.serialization.response.error.data"];
        if (data) {
            NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *data = [NSDictionary nbDictionaryWithJsonString:result];
            if (data) {
                [self loadSuccessWithTask:task data:data completionWithData:completeBlock];
                return;
            }
            [weakSelf loadFailWithTask:task error:error completionWithData:completeBlock];
            weakSelf.boolRequesting = false;
        }
    }];
}

- (void)loadFailWithTask:(NSURLSessionDataTask *)task error:(NSError *)error completionWithData:(NBCompletionWithModelData)completeBlock {
    self.boolLoadingSuccess = false;
    if (completeBlock && error.code != -999) {
        NSString *msg = [error.userInfo objectForKey:NSLocalizedDescriptionKey];
        if (error.code == -1009 || error.code == -1005) {
            msg = @"网络无连接";
        } else if (error.code == -1001) {
            msg = @"网络不好";
        }
        completeBlock(NO, msg, error, nil);
    }

    [[NBRequestFetchModelPool sharedRequestPool] releaseRequestModel:self];
}

- (void)loadSuccessWithTask:(NSURLSessionDataTask *)task data:(id)responseObject completionWithData:(NBCompletionWithModelData)completeBlock {

    self.boolLoadingSuccess = true;
    NSNumber *flag = [responseObject objectForKey:@"resultCode"];
    self.flag = flag.longLongValue;

    NSString *msg = [responseObject objectForKey:@"resultDesc"];

    self.resultDesc = msg;
    if (responseObject[@"data"]) {
        [self injectJSONData:responseObject[@"data"]];
    } else if ([responseObject isKindOfClass:[NSDictionary class]]) {
        [self injectJSONData:responseObject];
        for (id tmpData in ((NSDictionary *) responseObject).allValues) {
            if ([tmpData isKindOfClass:[NSDictionary class]]) {
                [self injectJSONData:tmpData];
            }
        }
    }
    // >=0 表示返回正常
    if (self.flag == 0) {

        if (completeBlock) {
            completeBlock(YES, nil, nil, responseObject);
        }

    } else {
        NSInteger statusCode = 0;
        if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
            statusCode = ((NSHTTPURLResponse *) (task.response)).statusCode;
        }
        NSDictionary *dict = @{ NSLocalizedDescriptionKey : msg ?: @"" };
        NSError *bizError = [NSError errorWithDomain:NBBizErrorDomain
                                                code:statusCode
                                            userInfo:dict];
        if (completeBlock) {
            completeBlock(NO, msg, bizError, responseObject);
        }
    }

    [[NBRequestFetchModelPool sharedRequestPool] releaseRequestModel:self];
}

+ (NSArray *)NBNoManagePropertyNames {
    return @[ @"flag", @"requestParams", @"sessionManager", @"sessionTask" ];
}

- (void)setCookie {
//    NSString *urlStr = [NSString stringWithFormat:@"%@%@",NB_TALK_BEFOREDOUBLERECORD_IP,NB_TALK_BEFOREDOUBLERECORD];
//    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:urlStr]];
//    NSHTTPCookie *cookie;
//    NSLog(@"nCookies: %@",cookies);
//    for (cookie in cookies) {
//        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
//    }
    
    
//
//    NSArray *cookies = [NBWebInteractiveDataManager sharedManager].cookies;
//    for (NSHTTPCookie *cookie in cookies) {
//        //创建字典存储cookie的属性值
//        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
//        //设置cookie名
//        [cookieProperties setObject:cookie.name forKey:NSHTTPCookieName];
//        //设置cookie值
//        [cookieProperties setObject:cookie.value forKey:NSHTTPCookieValue];
//        //设置cookie域名
//        [cookieProperties setObject:cookie.domain forKey:NSHTTPCookieDomain];
//        //设置cookie路径 一般写"/"
//        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
//        //设置cookie过期时间
//        [cookieProperties setObject:[NSDate dateWithTimeIntervalSinceNow:60*5] forKey:NSHTTPCookieMaximumAge];//NSHTTPCookieExpires
//        //删除原cookie, 如果存在的话
//        NSArray * arrayCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
//        for (NSHTTPCookie * cookice in arrayCookies) {
//            if ([cookice.domain rangeOfString:cookie.domain].length>0) {
//                [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookice];
//            }
//        }
//        //使用字典初始化新的cookie
//        NSHTTPCookie *newcookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
//        //使用cookie管理器 存储cookie
//        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:newcookie];
//    }
}



@end
