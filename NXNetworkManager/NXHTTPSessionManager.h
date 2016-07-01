//
//  NXHTTPSessionManager.h
//  NXNetworkManagerDemo
//
//  Created by 蒋瞿风 on 16/7/1.
//  Copyright © 2016年 nightx. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

typedef void(^_Nullable NXRequestCallBack)(BOOL success,NSURLSessionTask * __nullable task,id __nullable responseObject, NSError *__nullable error, NSInteger statusCode);

NS_ASSUME_NONNULL_BEGIN

@interface NXHTTPSessionManager : AFHTTPSessionManager


- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                            parameters:(nullable id)parameters
                              progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                       requestCallBack:(NXRequestCallBack)requestCallBack;


- (nullable NSURLSessionDataTask *)HEAD:(NSString *)URLString
                             parameters:(nullable id)parameters
                        requestCallBack:(NXRequestCallBack)requestCallBack;


- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable id)parameters
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                        requestCallBack:(NXRequestCallBack)requestCallBack;


- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable id)parameters
              constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                        requestCallBack:(NXRequestCallBack)requestCallBack;


- (nullable NSURLSessionDataTask *)PUT:(NSString *)URLString
                            parameters:(nullable id)parameters
                       requestCallBack:(NXRequestCallBack)requestCallBack;


- (nullable NSURLSessionDataTask *)PATCH:(NSString *)URLString
                              parameters:(nullable id)parameters
                         requestCallBack:(NXRequestCallBack)requestCallBack;


- (nullable NSURLSessionDataTask *)DELETE:(NSString *)URLString
                               parameters:(nullable id)parameters
                          requestCallBack:(NXRequestCallBack)requestCallBack;


@end

NS_ASSUME_NONNULL_END
