//
//  NXHTTPSessionManager.m
//  NXNetworkManagerDemo
//
//  Created by 蒋瞿风 on 16/7/1.
//  Copyright © 2016年 nightx. All rights reserved.
//

#import "NXHTTPSessionManager.h"

@implementation NXHTTPSessionManager

- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                            parameters:(nullable id)parameters
                              progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                       requestCallBack:(NXRequestCallBack)requestCallBack{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"GET"
                                                        URLString:URLString
                                                       parameters:parameters
                                                   uploadProgress:nil
                                                 downloadProgress:downloadProgress
                                                  requestCallBack:requestCallBack];
    [dataTask resume];
    return dataTask;
}


- (nullable NSURLSessionDataTask *)HEAD:(NSString *)URLString
                             parameters:(nullable id)parameters
                        requestCallBack:(NXRequestCallBack)requestCallBack{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"HEAD"
                                                        URLString:URLString
                                                       parameters:parameters
                                                   uploadProgress:nil
                                                 downloadProgress:nil
                                                  requestCallBack:requestCallBack];
    [dataTask resume];
    return dataTask;
}


- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable id)parameters
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                        requestCallBack:(NXRequestCallBack)requestCallBack{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"POST"
                                                        URLString:URLString
                                                       parameters:parameters
                                                   uploadProgress:uploadProgress
                                                 downloadProgress:nil
                                                  requestCallBack:requestCallBack];
    [dataTask resume];
    return dataTask;
}


- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable id)parameters
              constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                        requestCallBack:(NXRequestCallBack)requestCallBack{
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:&serializationError];
    if (serializationError) {
        if (requestCallBack) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                requestCallBack(NO, nil, nil, serializationError, 0);
            });
#pragma clang diagnostic pop
        }
        
        return nil;
    }
    
    __block NSURLSessionDataTask *task = [self uploadTaskWithStreamedRequest:request progress:uploadProgress completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (error) {
            if (requestCallBack) {
                requestCallBack(NO, task, responseObject, error, statusCode);
            }
        } else {
            if (requestCallBack) {
                requestCallBack(YES, task, responseObject, nil, statusCode);
            }
        }
    }];
    [task resume];
    return task;
}


- (nullable NSURLSessionDataTask *)PUT:(NSString *)URLString
                            parameters:(nullable id)parameters
                       requestCallBack:(NXRequestCallBack)requestCallBack{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"PUT"
                                                        URLString:URLString
                                                       parameters:parameters
                                                   uploadProgress:nil
                                                 downloadProgress:nil
                                                  requestCallBack:requestCallBack];
    [dataTask resume];
    return dataTask;
}


- (nullable NSURLSessionDataTask *)PATCH:(NSString *)URLString
                              parameters:(nullable id)parameters
                         requestCallBack:(NXRequestCallBack)requestCallBack{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"PATCH"
                                                        URLString:URLString
                                                       parameters:parameters
                                                   uploadProgress:nil
                                                 downloadProgress:nil
                                                  requestCallBack:requestCallBack];
    [dataTask resume];
    return dataTask;
}


- (nullable NSURLSessionDataTask *)DELETE:(NSString *)URLString
                               parameters:(nullable id)parameters
                          requestCallBack:(NXRequestCallBack)requestCallBack{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"DELETE"
                                                        URLString:URLString
                                                       parameters:parameters
                                                   uploadProgress:nil
                                                 downloadProgress:nil
                                                  requestCallBack:requestCallBack];
    [dataTask resume];
    return dataTask;
}



- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                  uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgress
                                downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress
                                 requestCallBack:(NXRequestCallBack)requestCallBack
{
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:&serializationError];
    if (serializationError) {
        if (requestCallBack) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                requestCallBack(NO, nil, nil, serializationError,0);
            });
#pragma clang diagnostic pop
        }
        
        return nil;
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest:request
                          uploadProgress:uploadProgress
                        downloadProgress:downloadProgress
                       completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           NSInteger statusCode = [(NSHTTPURLResponse *)dataTask.response statusCode];
                           if (error) {
                               if (requestCallBack) {
                                   requestCallBack(NO, dataTask, responseObject, error, statusCode);
                               }
                           } else {
                               if (requestCallBack) {
                                   requestCallBack(YES, dataTask, responseObject, nil, statusCode);
                               }
                           }
                       }];
    
    return dataTask;
}

@end
