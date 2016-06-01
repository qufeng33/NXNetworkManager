//
//  NXNetworkManager.m
//  NXNetworkManagerDemo
//
//  Created by 蒋瞿风 on 16/5/29.
//  Copyright © 2016年 nightx. All rights reserved.
//

#import "NXNetworkManager.h"
#import <AFNetworking/AFNetworking.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

#define WeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;
#define StrongObj(o) autoreleasepool{} __strong typeof(o) o = o##Weak;

static const int ddLogLevel = DDLogLevelDebug;

//static inline NSString *cachePath() {
//    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/NXNetworkManagerCaches"];
//}

@interface NXNetworkManager ()

@property (assign, nonatomic) NSTimeInterval      timeout;
@property (assign, nonatomic) BOOL                isDebug;
@property (assign, nonatomic) BOOL                shouldAutoEncode;
@property (assign, nonatomic) NXRequestType       requestType;
@property (assign, nonatomic) NXResponseType      responseType;
@property (strong, nonatomic) NSDictionary        *httpHeaders;
@property (strong, nonatomic) NSDictionary        *defaultParameters;
@property (copy  , nonatomic) NXCompletionHandler completionHandler;
@property (strong, nonatomic) NSMutableArray      *allTasks;

@end

@implementation NXNetworkManager

+ (instancetype)sharedManager{
    static NXNetworkManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self defaultSetting];
    }
    return self;
}

- (void)defaultSetting{
    self.timeout                         = 60;
    self.isDebug                         = YES;
    self.requestType                     = NXRequestTypeJSON;
    self.responseType                    = NXResponseTypeJSON;
    self.shouldAutoEncode                = NO;
    self.allTasks                        = [[NSMutableArray alloc] init];

    [self startMonitoringNetwork];
    [self configLogSetting];
    [self configURLCache];
}

- (void)startMonitoringNetwork{
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown: {
                _networkStatus = NXNetworkStatusUnknown;
                break;
            }
            case AFNetworkReachabilityStatusNotReachable: {
                _networkStatus = NXNetworkStatusNotReachable;
                break;
            }
            case AFNetworkReachabilityStatusReachableViaWWAN: {
                _networkStatus = NXNetworkStatusReachableViaWWAN;
                break;
            }
            case AFNetworkReachabilityStatusReachableViaWiFi: {
                _networkStatus = NXNetworkStatusReachableViaWiFi;
                break;
            }
        }
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

- (void)configURLCache{
    NSURLCache *cache = [NSURLCache sharedURLCache];
    if (cache.memoryCapacity < 1 || cache.diskCapacity < 1) {
        cache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:nil];
        [NSURLCache setSharedURLCache:cache];
    }
}

- (void)configLogSetting{
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor greenColor] backgroundColor:nil forFlag:DDLogFlagDebug];
    // Enable Colors
    setenv("XcodeColors", "YES", 0);
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
}

- (void)updateBaseUrl:(NSString *)baseURL{
    _baseURL = baseURL;
}

- (void)setTimeout:(NSTimeInterval)timeout{
    _timeout = timeout;
}

- (void)enableInterfaceDebug:(BOOL)isDebug{
    _isDebug = isDebug;
}

- (void)configRequestType:(NXRequestType)requestType
             responseType:(NXResponseType)responseType
      shouldAutoEncodeUrl:(BOOL)shouldAutoEncode{
    self.requestType                   = requestType;
    self.responseType                  = responseType;
    self.shouldAutoEncode              = shouldAutoEncode;
}

- (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders{
    self.httpHeaders = httpHeaders;
}

- (void)addDefaultParameters:(NSDictionary *)parameters{
    self.defaultParameters = parameters;
}

- (void)setCompletionHandler:(NXCompletionHandler)completionHandler{
    self.completionHandler = completionHandler;
}

- (void)clearCaches{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)cancelAllRequest{
    for (NSURLSessionTask *task in self.allTasks) {
        if ([task isKindOfClass:[NSURLSessionTask class]]) {
            [task cancel];
        }
    }
    [self.allTasks removeAllObjects];
}


- (void)cancelRequestWithURL:(NSString *)url{
    for (NSURLSessionTask *task in self.allTasks) {
        if ([task isKindOfClass:[NSURLSessionTask class]] && [task.currentRequest.URL.absoluteString hasSuffix:url]) {
            [task cancel];
            [self.allTasks removeObject:task];
            return;
        }
    }
}


- (AFHTTPSessionManager *)manager {
    AFHTTPSessionManager *manager = nil;;
    if (self.baseURL != nil) {
        manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:self.baseURL]];
    } else {
        manager = [AFHTTPSessionManager manager];
    }
    
    switch (self.requestType) {
        case NXRequestTypeJSON: {
            manager.requestSerializer  = [AFJSONRequestSerializer serializer];
            break;
        }
        case NXRequestTypeHTTP: {
            manager.requestSerializer  = [AFHTTPRequestSerializer serializer];
            break;
        }
    }
    
    switch (self.responseType) {
        case NXResponseTypeJSON: {
            manager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        }
        case NXResponseTypeXML: {
            manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        }
        case NXResponseTypeData: {
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        }
    }
    
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    
    for (NSString *key in self.httpHeaders.allKeys) {
        if (self.httpHeaders[key] != nil) {
            [manager.requestSerializer setValue:self.httpHeaders[key] forHTTPHeaderField:key];
        }
    }
    
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                              @"text/html",
                                                                              @"text/json",
                                                                              @"text/plain",
                                                                              @"text/javascript",
                                                                              @"text/xml",
                                                                              @"image/*"]];
    
    manager.requestSerializer.timeoutInterval = self.timeout;
    
    // 设置允许同时最大并发数量
    manager.operationQueue.maxConcurrentOperationCount = 3;

    return manager;
}

- (NSURLSessionDataTask *)requestWithPath:(NSString *)path
                            requestMethod:(NXRequestMethod)method
                               parameters:(NSDictionary *)parameters
                         downloadProgress:(NXProgressHandler)downloadProgressHandler
                           uploadProgress:(NXProgressHandler)uploadProgressHandler
                            completeBlock:(NXRequestCallBack)block{

    if (![self isURL:path]) {
        return nil;
    }
    
    if (self.shouldAutoEncode) {
        path = [self encodeURL:path];
    }
    
    //添加参数
    if (self.defaultParameters) {
        NSMutableDictionary * result = [NSMutableDictionary dictionaryWithDictionary:self.defaultParameters];
        for (NSString *key in parameters.allKeys) {
            [result setValue:[parameters objectForKey:key] forKey:key];
        }
        parameters = (NSDictionary *)[result mutableCopy];
    }
    
    AFHTTPSessionManager *manager = [self manager];
    
    NSURLSessionDataTask *sessionTask = nil;
    @WeakObj(self);
    
    switch (method) {
        case GET: {
            sessionTask = [manager GET:path parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
                if (downloadProgressHandler) {
                    downloadProgressHandler(downloadProgress);
                }
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                @StrongObj(self);
                [self successHandlerWithSessionTask:task responseObject:responseObject url:path params:parameters requestBlock:block];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                @StrongObj(self);
                [self failureHandlerWithSessionTask:task error:error url:path params:parameters requestBlock:block];
            }];
           
            break;
        }
        case POST: {
            sessionTask = [manager POST:path parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
                if (uploadProgressHandler) {
                    uploadProgressHandler(uploadProgress);
                }
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                @StrongObj(self);
                [self successHandlerWithSessionTask:task responseObject:responseObject url:path params:parameters requestBlock:block];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                @StrongObj(self);
                [self failureHandlerWithSessionTask:task error:error url:path params:parameters requestBlock:block];
            }];
            break;
        }
        case HEAD: {
            sessionTask = [manager HEAD:path parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task) {
                @StrongObj(self);
                [self successHandlerWithSessionTask:task responseObject:nil url:path params:parameters requestBlock:block];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                @StrongObj(self);
                [self failureHandlerWithSessionTask:task error:error url:path params:parameters requestBlock:block];
            }];
            break;
        }
        case PUT: {
            sessionTask = [manager PUT:path parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                @StrongObj(self);
                [self successHandlerWithSessionTask:task responseObject:responseObject url:path params:parameters requestBlock:block];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                @StrongObj(self);
                [self failureHandlerWithSessionTask:task error:error url:path params:parameters requestBlock:block];
            }];
            break;
        }
        case PATCH: {
            sessionTask = [manager PATCH:path parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                @StrongObj(self);
                [self successHandlerWithSessionTask:task responseObject:responseObject url:path params:parameters requestBlock:block];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                @StrongObj(self);
                [self failureHandlerWithSessionTask:task error:error url:path params:parameters requestBlock:block];
            }];
            break;
        }
        case DELETE: {
            sessionTask = [manager DELETE:path parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                @StrongObj(self);
                [self successHandlerWithSessionTask:task responseObject:responseObject url:path params:parameters requestBlock:block];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                @StrongObj(self);
                [self failureHandlerWithSessionTask:task error:error url:path params:parameters requestBlock:block];
            }];
            break;
        }
    }
    
    if (sessionTask) {
        [self.allTasks addObject:sessionTask];
    }
    
    return sessionTask;
}

- (NSURLSessionDataTask *)getWithPath:(NSString *)path params:(NSDictionary *)params completeBlock:(NXRequestCallBack)block{
    return [self requestWithPath:path requestMethod:GET parameters:params downloadProgress:nil uploadProgress:nil completeBlock:block];
}

- (NSURLSessionDataTask *)postWithPath:(NSString *)path params:(NSDictionary *)params completeBlock:(NXRequestCallBack)block{
    return [self requestWithPath:path requestMethod:POST parameters:params downloadProgress:nil uploadProgress:nil completeBlock:block];
}

- (NSURLSessionDataTask *)headWithPath:(NSString *)path params:(NSDictionary *)params completeBlock:(NXRequestCallBack)block{
    return [self requestWithPath:path requestMethod:HEAD parameters:params downloadProgress:nil uploadProgress:nil completeBlock:block];
}

- (NSURLSessionDataTask *)putWithPath:(NSString *)path params:(NSDictionary *)params completeBlock:(NXRequestCallBack)block{
    return [self requestWithPath:path requestMethod:PUT parameters:params downloadProgress:nil uploadProgress:nil completeBlock:block];
}

- (NSURLSessionDataTask *)patchWithPath:(NSString *)path params:(NSDictionary *)params completeBlock:(NXRequestCallBack)block{
    return [self requestWithPath:path requestMethod:PATCH parameters:params downloadProgress:nil uploadProgress:nil completeBlock:block];
}

- (NSURLSessionDataTask *)deleteWithPath:(NSString *)path params:(NSDictionary *)params completeBlock:(NXRequestCallBack)block{
    return [self requestWithPath:path requestMethod:DELETE parameters:params downloadProgress:nil uploadProgress:nil completeBlock:block];
}

- (NSURLSessionDataTask *)uploadWithImage:(UIImage *)image
                                     path:(NSString *)path
                                 filename:(NSString *)filename
                                     name:(NSString *)name
                                 mimeType:(NSString *)mimeType
                               parameters:(NSDictionary *)parameters
                           uploadProgress:(NXProgressHandler)uploadProgressHandler
                            completeBlock:(NXRequestCallBack)block{
    
    if (![self isURL:path]) {
        return nil;
    }
    
    if ([self shouldAutoEncode]) {
        path = [self encodeURL:path];
    }
    
    AFHTTPSessionManager *manager = [self manager];
    NSURLSessionDataTask *sessionTask = nil;
    
    @WeakObj(self);
    sessionTask = [manager POST:path parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        
        NSString *imageFileName = filename;
        if (filename == nil || ![filename isKindOfClass:[NSString class]] || filename.length == 0) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
        }
        
        // 上传图片，以文件流的格式
        [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:mimeType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (uploadProgressHandler) {
            uploadProgressHandler(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        @StrongObj(self);
        [self successHandlerWithSessionTask:task responseObject:responseObject url:path params:parameters requestBlock:block];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        @StrongObj(self);
        [self failureHandlerWithSessionTask:task error:error url:path params:parameters requestBlock:block];
    }];
    
    [sessionTask resume];
    if (sessionTask) {
        [[self allTasks] addObject:sessionTask];
    }
    
    return sessionTask;
}

- (NSURLSessionUploadTask *)uploadFileWithPath:(NSString *)path
                                 uploadingFile:(NSString *)uploadingFile
                                uploadProgress:(NXProgressHandler)uploadProgressHandler
                                 completeBlock:(NXRequestCallBack)block{
    if ([NSURL URLWithString:uploadingFile] == nil) {
        DDLogError(@"uploadingFile无效，无法生成URL。请检查待上传文件是否存在");
        return nil;
    }
    
    NSURL *uploadURL = nil;
    if (self.baseURL == nil) {
        uploadURL = [NSURL URLWithString:path];
    } else {
        uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.baseURL, path]];
    }
    
    if (uploadURL == nil) {
        DDLogError(@"URLString无效，无法生成URL。可能是URL中有中文或特殊字符，请尝试Encode URL");
        return nil;
    }
    
    AFHTTPSessionManager *manager = [self manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:uploadURL];
    NSURLSessionUploadTask *sessionTask = nil;
    
    @WeakObj(self);
    sessionTask = [manager uploadTaskWithRequest:request fromFile:[NSURL URLWithString:uploadingFile] progress:^(NSProgress * _Nonnull uploadProgress) {
        if (uploadProgressHandler) {
            uploadProgressHandler(uploadProgress);
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        @StrongObj(self);
        if (error) {
        [self successHandlerWithSessionTask:sessionTask responseObject:responseObject url:path params:nil requestBlock:block];
        }else{
        [self failureHandlerWithSessionTask:sessionTask error:error url:path params:nil requestBlock:block];
        }
    }];
    
    if (sessionTask) {
        [[self allTasks] addObject:sessionTask];
    }
    
    return sessionTask;
}

- (NSURLSessionDownloadTask *)downloadWithPath:(NSString *)path
                            saveToFilePath:(NSString *)filePath
                          downloadProgress:(NXProgressHandler)downloadProgressHandler
                             completeBlock:(NXRequestCallBack)block{
    if (![self isURL:path]) {
        return nil;
    }
    
    AFHTTPSessionManager *manager = [self manager];
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:path]];
    NSURLSessionDownloadTask *sessionTask = nil;
    
    @WeakObj(self);
    sessionTask = [manager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        if (downloadProgressHandler) {
            downloadProgressHandler(downloadProgress);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL URLWithString:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        @StrongObj(self);
        if (error) {
            [self successHandlerWithSessionTask:sessionTask responseObject:filePath url:path params:nil requestBlock:block];
        }else{
            [self failureHandlerWithSessionTask:sessionTask error:error url:path params:nil requestBlock:block];
        }
    }];
    
    [sessionTask resume];
    if (sessionTask) {
        [[self allTasks] addObject:sessionTask];
    }
    
    return sessionTask;
    
}

- (void)successHandlerWithSessionTask:(NSURLSessionTask *)task
                       responseObject:(id)responseObject
                                  url:(NSString *)url
                               params:(NSDictionary *)params
                         requestBlock:(NXRequestCallBack)block{
    [self.allTasks removeObject:task];
    if (self.isDebug) {
        [self logWithSuccessResponseObject:responseObject url:url params:params];
    }
    if (self.completionHandler) {
        self.completionHandler(task.response,responseObject,nil);
    }
    if (block) {
        NSInteger statusCode = [(NSHTTPURLResponse *)task.response statusCode];
        block(YES,task,responseObject,nil,statusCode);
    }
}

- (void)failureHandlerWithSessionTask:(NSURLSessionTask *)task
                                error:(NSError *)error
                                  url:(NSString *)url
                               params:(NSDictionary *)params
                         requestBlock:(NXRequestCallBack)block{
    [self.allTasks removeObject:task];
    if (self.isDebug) {
        [self logWithFailError:error url:url params:params];
    }
    if (self.completionHandler) {
        self.completionHandler(task.response,nil,error);
    }
    if (block) {
        NSInteger statusCode = [(NSHTTPURLResponse *)task.response statusCode];
        block(NO,task,nil,error,statusCode);
    }
}


- (void)logWithSuccessResponseObject:(id)responseObject url:(NSString *)url params:(NSDictionary *)params {
    DDLogInfo(@"\n");
    DDLogInfo(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",url,params,responseObject);
}

- (void)logWithFailError:(NSError *)error url:(NSString *)url params:(id)params {
    NSString *format = @" params: ";
    if (params == nil || ![params isKindOfClass:[NSDictionary class]]) {
        format = @"";
        params = @"";
    }
    
    DDLogError(@"\n");
    if ([error code] == NSURLErrorCancelled) {
        DDLogError(@"\nRequest was canceled mannully, URL: %@ %@%@\n\n",url,format,params);
    } else {
        DDLogError(@"\nRequest error, URL: %@ %@%@\n errorInfos:%@\n\n",url,format,params,[error localizedDescription]);
    }
}


- (NSString *)encodeURL:(NSString *)url {
    NSString *newString =
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)url,
                                                              NULL,
                                                              CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
    if (newString) {
        return newString;
    }
    
    return url;
}

- (BOOL)isURL:(NSString *)urlString{
    if ([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"]) {
        NSURL *url = [[NSURL alloc] initWithString:urlString];
        if (url) {
            return YES;
        }
    }
    
    if ([self.baseURL hasPrefix:@"http://"] || [self.baseURL hasPrefix:@"https://"]) {
        NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@",self.baseURL,urlString]];
        if (url) {
            return YES;
        }
    }
    
    DDLogError(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
    return NO;
}

@end