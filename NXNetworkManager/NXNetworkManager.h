//
//  NXNetworkManager.h
//  NXNetworkManagerDemo
//
//  Created by 蒋瞿风 on 16/5/29.
//  Copyright © 2016年 nightx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NXHTTPSessionManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NXRequestType) {
    NXRequestTypeJSON = 1, // 默认
    NXRequestTypeHTTP = 2  // 普通text/html
};

typedef NS_ENUM(NSUInteger, NXResponseType) {
    NXResponseTypeJSON = 1, // 默认
    NXResponseTypeXML  = 2, // XML
    NXResponseTypeData = 3
};

typedef NS_ENUM(NSInteger, NXNetworkStatus) {
    NXNetworkStatusUnknown          = -1,//未知网络
    NXNetworkStatusNotReachable     = 0, //网络无连接
    NXNetworkStatusReachableViaWWAN = 1, //2，3，4G网络
    NXNetworkStatusReachableViaWiFi = 2  //WIFI网络
};

typedef NS_ENUM(NSUInteger, NXRequestMethod) {
    GET    = 1,
    POST   = 2,
    HEAD   = 3,
    PUT    = 4,
    PATCH  = 5,
    DELETE = 6
};


typedef void(^_Nullable NXRequestCallBack)(BOOL success,NSURLSessionTask * _Nonnull task,id __nullable responseObject, NSError *__nullable error, NSInteger statusCode);
typedef void(^ _Nullable NXProgressHandler)(NSProgress * _Nonnull progress);
typedef void(^_Nullable NXCompletionHandler)(NSURLResponse *response, id _Nullable responseObject,  NSError * _Nullable error);
@interface NXNetworkManager : NSObject

@property (strong, nonatomic, readonly ) NSString        *baseURL;
@property (assign, nonatomic, readonly ) NXNetworkStatus networkStatus;
@property (assign, nonatomic, readwrite) BOOL            removesKeysWithNullValues;


/**
 *  初始化
 *
 *  @return 返回单例
 */
+ (instancetype)sharedManager;

/**
 *  用于指定网络请求接口的基础URL，如：
 *  http://www.baidu.com或者http://8.8.8.8
 *  通常在AppDelegate中启动时就设置一次就可以了。如果接口有来源
 *  于多个服务器，可以调用更新
 *
 *  @param baseURL 网络接口的基础URL
 */
- (void)updateBaseUrl:(nullable NSString *)baseURL;


/**
 *	设置请求超时时间，默认为60秒
 *
 *	@param timeout 超时时间
 */
- (void)setTimeout:(NSTimeInterval)timeout;


/**
 *  显示或不显示调试信息,默认为YES
 *
 *  @param isDebug YES/NO
 */
- (void)enableInterfaceDebug:(BOOL)isDebug;

/**
 *  为网络请求增加统一的参数
 *
 *  @param parameters 增加的参数
 */
- (void)addDefaultParameters:(nullable NSDictionary *)parameters;

/**
 *  全局的请求后的回调，比NXRequestCallBack优先
 *
 *  @param completionHandler 请求完成后的回调
 */
- (void)addCompletionHandler:(nullable NXCompletionHandler)completionHandler;


/**
 *  配置请求格式，默认为JSON。如果要求传XML或者PLIST，请在全局配置一下
 *
 *  @param requestType 请求格式，默认为JSON
 *  @param responseType 响应格式，默认为JSON，
 *  @param shouldAutoEncode YES or NO,默认为NO，是否自动encode url
 */
- (void)configRequestType:(NXRequestType)requestType
             responseType:(NXResponseType)responseType
      shouldAutoEncodeUrl:(BOOL)shouldAutoEncode;


/**
 *  配置公共的请求头，只调用一次即可
 *
 *  @param httpHeaders 只需要将与服务器商定的固定参数设置即可
 */
- (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders;


/**
 *  清除缓存
 */
- (void)clearCaches;


/**
 *  取消所有的请求
 */
- (void)cancelAllRequest;


/**
 *  取消指定的请求
 *
 *  @param url URL，可以是绝对URL，也可以是path
 */
- (void)cancelRequestWithURL:(nonnull NSString *)url;


/**
 *  请求接口，若不指定baseURL，可传完整的URL
 *
 *  @param path                    接口路径，如/path/getArticleList
 *  @param method                  请求方法
 *  @param parameters              接口中所需要的拼接参数，如@{"categoryid" : @(12)}
 *  @param downloadProgress        下载进度
 *  @param uploadProgress          上传进度
 *  @param block                   请求后的回调
 *
 *  @return 返回的请求对象
 */
- (NSURLSessionDataTask *)requestWithPath:(nonnull  NSString *)path
                            requestMethod:(NXRequestMethod)method
                               parameters:(nullable NSDictionary *)parameters
                         downloadProgress:(nullable NXProgressHandler)downloadProgressHandler
                           uploadProgress:(nullable NXProgressHandler)uploadProgressHandler
                          requestCallBack:(nullable NXRequestCallBack)block;


/**
 *  GET请求接口，若不指定baseURL，可传完整的URL
 *
 *  @param url      接口路径，如/path/getArticleList
 *  @param params   接口中所需要的拼接参数，如@{"categoryid" : @(12)}
 *  @param block    请求后的会回调
 *
 *  @return 返回的请求对象
 */
- (NSURLSessionDataTask *)getWithPath:(nonnull  NSString *)path
                               params:(nullable NSDictionary *)params
                      requestCallBack:(nullable NXRequestCallBack)block;


/**
 *  POST请求接口，若不指定baseURL，可传完整的URL
 *
 *  @param url      接口路径，如/path/getArticleList
 *  @param params   接口中所需要的拼接参数，如@{"categoryid" : @(12)}
 *  @param block    请求后的会回调
 *
 *  @return 返回的请求对象
 */
- (NSURLSessionDataTask *)postWithPath:(nonnull NSString *)path
                                params:(nullable NSDictionary *)params
                       requestCallBack:(nullable NXRequestCallBack)block;

/**
 *  HEAD请求接口，若不指定baseURL，可传完整的URL
 *
 *  @param url      接口路径，如/path/getArticleList
 *  @param params   接口中所需要的拼接参数，如@{"categoryid" : @(12)}
 *  @param block    请求后的会回调
 *
 *  @return 返回的请求对象
 */
- (NSURLSessionDataTask *)headWithPath:(nonnull  NSString *)path
                                params:(nullable NSDictionary *)params
                       requestCallBack:(nullable NXRequestCallBack)block;

/**
 *  PUT请求接口，若不指定baseURL，可传完整的URL
 *
 *  @param url      接口路径，如/path/getArticleList
 *  @param params   接口中所需要的拼接参数，如@{"categoryid" : @(12)}
 *  @param block    请求后的会回调
 *
 *  @return 返回的请求对象
 */
- (NSURLSessionDataTask *)putWithPath:(nonnull  NSString *)path
                               params:(nullable NSDictionary *)params
                      requestCallBack:(nullable NXRequestCallBack)block;

/**
 *  PATCH请求接口，若不指定baseURL，可传完整的URL
 *
 *  @param url      接口路径，如/path/getArticleList
 *  @param params   接口中所需要的拼接参数，如@{"categoryid" : @(12)}
 *  @param block    请求后的会回调
 *
 *  @return 返回的请求对象
 */
- (NSURLSessionDataTask *)patchWithPath:(nonnull  NSString *)path
                                 params:(nullable NSDictionary *)params
                        requestCallBack:(nullable NXRequestCallBack)block;

/**
 *  DELETE请求接口，若不指定baseURL，可传完整的URL
 *
 *  @param url      接口路径，如/path/getArticleList
 *  @param params   接口中所需要的拼接参数，如@{"categoryid" : @(12)}
 *  @param block    请求后的会回调
 *
 *  @return 返回的请求对象
 */
- (NSURLSessionDataTask *)deleteWithPath:(nonnull  NSString *)path
                                  params:(nullable NSDictionary *)params
                         requestCallBack:(nullable NXRequestCallBack)block;


/**
 *	图片上传接口，若不指定baseurl，可传完整的url
 *
 *	@param image            图片对象
 *	@param url              上传图片的接口路径，如/path/images/
 *	@param filename         给图片起一个名字，默认为当前日期时间,格式为"yyyyMMddHHmmss"，后缀为`jpg`
 *	@param name             与指定的图片相关联的名称，这是由后端写接口的人指定的，如imagefiles
 *	@param mimeType         默认为image/jpeg
 *	@param parameters       参数
 *	@param uploadProgress	上传进度
 *	@param block            请求后的会回调
 *
 *	@return 返回的请求对象
 */
- (NSURLSessionDataTask *)uploadWithImage:(nonnull  UIImage *)image
                                     path:(nonnull  NSString *)path
                                 filename:(nullable NSString *)filename
                                     name:(nullable NSString *)name
                                 mimeType:(nullable NSString *)mimeType
                               parameters:(nullable NSDictionary *)parameters
                           uploadProgress:(nullable NXProgressHandler)uploadProgressHandler
                          requestCallBack:(nullable NXRequestCallBack)block;

/**
 *	上传文件操作
 *
 *	@param url				上传路径
 *	@param uploadingFile	待上传文件的路径
 *	@param uploadProgress   上传进度
 *	@param block            请求后的会回调
 *
 *	@return 返回的请求对象
 *
 */
- (NSURLSessionUploadTask *)uploadFileWithPath:(nonnull  NSString *)path
                                 uploadingFile:(nonnull  NSString *)uploadingFile
                                uploadProgress:(nullable NXProgressHandler)uploadProgressHandler
                             completionHandler:(nullable void (^)(BOOL success, NSURLResponse *response, id _Nullable responseObject, NSError  * _Nullable error, NSInteger statusCode))completionHandler;


/**
 *  下载文件
 *
 *  @param url              下载URL
 *  @param saveToPath       下载到哪个路径下
 *  @param downloadProgress 下载进度
 *	@param block            请求后的会回调
 *
 *	@return 返回的请求对象
 *
 */
- (NSURLSessionDownloadTask *)downloadWithPath:(nonnull  NSString *)path
                                saveToFilePath:(nullable NSString *)filePath
                              downloadProgress:(nullable NXProgressHandler)downloadProgressHandler
                               completionHandler:(nullable void (^)(BOOL success, NSURLResponse *response, id _Nullable responseObject, NSError  * _Nullable error, NSInteger statusCode))completionHandler;


@end

NS_ASSUME_NONNULL_END