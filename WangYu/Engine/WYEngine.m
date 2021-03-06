//
//  WYEngine.m
//  WangYu
//
//  Created by KID on 15/4/22.
//  Copyright (c) 2015年 KID. All rights reserved.
//

#import "WYEngine.h"
#import "EGOCache.h"
#import "JSONKit.h"
#import "PathHelper.h"
#import "WYSettingConfig.h"
#import "WYCommonUtils.h"
#import "AFNetworking.h"
#import "URLHelper.h"
#import "NSDictionary+objectForKey.h"
#import "QHQnetworkingTool.h"
#import "WYAlertView.h"
#import "AppDelegate.h"
#import "WelcomeViewController.h"
#import "WYNavigationController.h"
#import "WYUserGuideConfig.h"
#import "WYPayManager.h"

#define CONNECT_TIMEOUT 20

static NSString* IMG_URL = @"http://img.wangyuhudong.com";
static NSString* API_URL = @"http://api.wangyuhudong.com";//

static WYEngine* s_ShareInstance = nil;

@interface WYEngine (){
    
    int _connectTag;
    
    NSMutableDictionary* _onAppServiceBlockMap;
    //....
    EGOCache* _cacheInstance;
    
    NSDictionary* _globalDefaultConfig;
    
    NSMutableSet* _needCacheUrls;
    
    NSMutableDictionary* _urlCacheTagMap;
    
    NSMutableDictionary* _urlTagMap;
}

@end

@implementation WYEngine

+ (WYEngine *)shareInstance{
    @synchronized(self) {
        if (s_ShareInstance == nil) {
            s_ShareInstance = [[WYEngine alloc] init];
        }
    }
    return s_ShareInstance;
}

+ (NSDictionary*)getReponseDicByContent:(NSData*)content err:(NSError*)err{
    if (err || !content || content.length == 0) {
        NSLog(@"#######content=nil");
        return nil;
    }
    NSDictionary* json = [content objectFromJSONData];
    return json;
}

+ (NSString*)getErrorMsgWithReponseDic:(NSDictionary*)dic{
    if (dic == nil) {
        return @"网络相当不给力";
    }
    if ([[dic objectForKey:@"code"] intValue] == 0){
        return nil;
    }else{
        NSString* error = [dic objectForKey:@"result"];
        if (!error) {
            error = [dic objectForKey:@"result"];
        }
        if (error == nil) {
            error = @"unknow error";
        }
        return error;
    }
}

+ (NSString*)getErrorCodeWithReponseDic:(NSDictionary*)dic {
    
    return [[dic stringObjectForKey:@"code"] description];
}

+ (NSString*)getSuccessMsgWithReponseDic:(NSDictionary*)dic{
    
    if (dic == nil) {
        return nil;
    }
    if ([[dic objectForKey:@"code"] intValue] == 0){
        return [dic objectForKey:@"result"];
    }else{
        return nil;
    }
}

- (id)init{
    self = [super init];
    
    _connectTag = 100;
    _onAppServiceBlockMap = [[NSMutableDictionary alloc] init];
    _needCacheUrls = [[NSMutableSet alloc] init];
    _urlCacheTagMap = [[NSMutableDictionary alloc] init];
    _urlTagMap = [[NSMutableDictionary alloc] init];
    
    _uid = nil;
    _userPassword = nil;
    
    //获取用户
    [self loadAccount];
    
    _userInfo = [[WYUserInfo alloc] init];
    _userInfo.uid = _uid;
    //加载用户信息
    [self loadUserInfo];
    
    _serverPlatform = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"serverPlatform"];
    if (_serverPlatform == 0)
    {
        _serverPlatform = OnlinePlatform;//默认线上平台
    }
    
    [self serverInit];
    
    _wyInstanceDocPath = [PathHelper documentDirectoryPathWithName:@"WY_Path"];
    NSLog(@"cache file path: %@", _wyInstanceDocPath);
    
    return self;
}

- (void)serverInit{
    if (self.serverPlatform == TestPlatform) {
        API_URL = @"http://192.168.16.29";
    } else {
        API_URL = @"http://api.wangyuhudong.com";
    }
}

- (void)logout{
    _firstLogin = YES;
    [WYUserGuideConfig logout];
    [[WYPayManager shareInstance] logout];
    [self logout:NO];
}

- (void)logout:(BOOL)removeAccout{
    
    if (removeAccout) {
        _account = nil;
    }

    _userPassword = nil;
    _token = nil;
    [self saveAccount];
    _userInfo = [[WYUserInfo alloc] init];
    [[WYSettingConfig staticInstance] logout];
    _cacheInstance = nil;
}

-(NSString *)baseUrl{
    return API_URL;
}
-(NSString *)baseImgUrl{
    return IMG_URL;
}

- (void)setServerPlatform:(ServerPlatform)serverPlatform {
    _serverPlatform = serverPlatform;
    [[NSUserDefaults standardUserDefaults] setInteger:_serverPlatform forKey:@"serverPlatform"];
    [self serverInit];
}

- (NSDictionary*)globalDefaultConfig {
    if (_globalDefaultConfig == nil) {
        _globalDefaultConfig = [NSDictionary dictionaryWithContentsOfFile:[self getGlobalDefaultConfigPath]];
        
        if (_globalDefaultConfig == nil) {
            _globalDefaultConfig = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"globalDefaultConfig" ofType:nil]];
        }
    }
    
    return _globalDefaultConfig;
}

- (void)setGlobalDefaultConfig:(NSDictionary *)globalDefaultConfig {
    _globalDefaultConfig = globalDefaultConfig;
}

- (NSString *)getGlobalDefaultConfigPath{
    NSString *filePath = [[PathHelper documentDirectoryPathWithName:nil] stringByAppendingPathComponent:@"globalDefaultConfig"];
    return filePath;
}

#pragma mark - userInfo
- (void)setUserInfo:(WYUserInfo *)userInfo{
    _userInfo = userInfo;
    [[WYSettingConfig staticInstance] setUserCfg:_userInfo.userInfoByJsonDic];
    [[NSNotificationCenter defaultCenter] postNotificationName:WY_USERINFO_CHANGED_NOTIFICATION object:self];
    [self saveUserInfo];
}

- (void)saveUserInfo{
    if (!_uid) {
        return;
    }
    
    if (!self.userInfo.jsonString) {
        return;
    }
    NSString* path = [[self getCurrentAccoutDocDirectory] stringByAppendingPathComponent:@"myUserInfo.xml"];
    [self.userInfo.jsonString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (NSString*)getCurrentAccoutDocDirectory{
    return [PathHelper documentDirectoryPathWithName:[NSString stringWithFormat:@"accounts/%@", _uid]];
}

- (NSString *)getAccountsStoragePath{
    NSString *filePath = [[PathHelper documentDirectoryPathWithName:nil] stringByAppendingPathComponent:@"account"];
    return filePath;
}

- (NSString *)getLoginedAccountsStoragePath{
    NSString *filePath = [[PathHelper documentDirectoryPathWithName:nil] stringByAppendingPathComponent:@"loginedAccount"];
    return filePath;
}

- (void)loadAccount{
    NSDictionary * accountDic = [NSDictionary dictionaryWithContentsOfFile:[self getAccountsStoragePath]];
    //.....account信息
    _uid = [accountDic objectForKey:@"uid"];
    _account = [accountDic objectForKey:@"account"];
    _userPassword = [accountDic objectForKey:@"accountPwd"];
    _token = [accountDic objectForKey:@"token"];
}

- (void)loadUserInfo{
    if(!_uid){
        return;
    }
    NSString *path = [[self getCurrentAccoutDocDirectory] stringByAppendingPathComponent:@"myUserInfo.xml"];
    NSString *jsonString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (!jsonString) {
        [self refreshUserInfo];
    }
    NSDictionary *userDic = [jsonString objectFromJSONString];
    WYLog(@"WYEngine loadUserInfo userDic =%@ ",userDic);
    if (userDic) {
        if (_userInfo == nil) {
            _userInfo = [[WYUserInfo alloc] init];
        }
        [_userInfo setUserInfoByJsonDic:userDic];
    }
}

- (void)saveAccount{
    NSMutableDictionary* accountDic= [NSMutableDictionary dictionaryWithCapacity:2];
    if (_uid) {
        [accountDic setValue:_uid forKey:@"uid"];
    }
    if (_account)
        [accountDic setValue:_account forKey:@"account"];
    if(_userPassword)
        [accountDic setValue:_userPassword forKey:@"accountPwd"];
    if (_token) {
        [accountDic setValue:_token forKey:@"token"];
    }
    [accountDic writeToFile:[self getAccountsStoragePath] atomically:NO];
    
    [self saveLoginedAccounts];
}

-(void)removeAccount{
    [[NSFileManager defaultManager] removeItemAtPath:[self getAccountsStoragePath] error:nil];
}

//记忆登录过的Account
-(void)saveLoginedAccounts{
    NSMutableDictionary* accountDic= [NSMutableDictionary dictionaryWithCapacity:1];
    if (_account)
        [accountDic setValue:_account forKey:@"account"];
    [accountDic writeToFile:[self getLoginedAccountsStoragePath] atomically:NO];
}
- (NSString*)getMemoryLoginedAccout{
    NSDictionary * accountDic = [NSDictionary dictionaryWithContentsOfFile:[self getLoginedAccountsStoragePath]];
    NSString *account = [accountDic stringObjectForKey:@"account"];
    return account;
}


- (void)refreshUserInfo{
//    int tag = [self getConnectTag];
//    [self getUserInfoWithUid:self.uid tag:tag error:nil];
//    [self addOnAppServiceBlock:^(NSInteger tag, NSDictionary *jsonRet, NSError *err) {
//        NSString* errorMsg = [WYEngine getErrorMsgWithReponseDic:jsonRet];
//        if (jsonRet && !errorMsg) {
//            [[WYEngine shareInstance].userInfo setUserInfoByJsonDic:[jsonRet objectForKey:@"object"]];
//            [WYEngine shareInstance].userInfo = [WYEngine shareInstance].userInfo;
//        }
//        
//    } tag:tag];
}

- (BOOL)hasAccoutLoggedin{
    NSLog(@"_account=%@, _userPassword=%@, _uid=%@", _account, _userPassword, _uid);
    return (_account && _userPassword && _uid);
}


#pragma mark - Visitor
- (void)visitorLogin{
    _uid = nil;
    _account = nil;
    _userPassword = nil;
    _token = nil;
    [self removeAccount];
    _userInfo = [[WYUserInfo alloc] init];
}
- (BOOL)needUserLogin:(NSString *)message{
    if (![self hasAccoutLoggedin]) {
        if (message == nil) {
            message = @"请登录";
        }
        WYAlertView *alertView = [[WYAlertView alloc] initWithTitle:@"温馨提示" message:message cancelButtonTitle:@"取消" cancelBlock:^{
        } okButtonTitle:@"登录" okBlock:^{
            [self gotoLogin];
        }];
        [alertView show];
        return YES;
    }
    return NO;
}

-(void)gotoLogin{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    WelcomeViewController *welcomeVc = [[WelcomeViewController alloc] init];
    welcomeVc.showBackButton = YES;
    WYNavigationController* navigationController = [[WYNavigationController alloc] initWithRootViewController:welcomeVc];
    navigationController.navigationBarHidden = YES;
    [appDelegate.mainTabViewController.navigationController presentViewController:navigationController animated:YES completion:^{
        
    }];
}

#pragma mark - request
- (int)getConnectTag{
    return _connectTag++;
}

- (void)addOnAppServiceBlock:(onAppServiceBlock)block tag:(int)tag{
    [_onAppServiceBlockMap setObject:[block copy] forKey:[NSNumber numberWithInt:tag]];
}

- (void)removeOnAppServiceBlockForTag:(int)tag{
    [_onAppServiceBlockMap removeObjectForKey:[NSNumber numberWithInt:tag]];
}

- (onAppServiceBlock)getonAppServiceBlockByTag:(int)tag{
    return [_onAppServiceBlockMap objectForKey:[NSNumber numberWithInt:tag]];
}

- (EGOCache *)getCacheInstance{
    @synchronized(self) {
        if (_uid.length == 0) {
            return [EGOCache globalCache];
        }else{
            if (_cacheInstance == nil) {
                NSString* cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
                cachesDirectory = [[[cachesDirectory stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]] stringByAppendingPathComponent:_uid] copy];
                _cacheInstance = [[EGOCache alloc] initWithCacheDirectory:cachesDirectory];
                _cacheInstance.defaultTimeoutInterval = 365*24*60*60;
            }
        }
    }
    return _cacheInstance;
}

- (void)addGetCacheTag:(int)tag{
    [_urlCacheTagMap setObject:@"" forKey:[NSNumber numberWithInt:tag]];
}

- (void)getCacheReponseDicForTag:(int)tag complete:(void(^)(NSDictionary* jsonRet))complete{
    NSString* urlString = [_urlCacheTagMap objectForKey:[NSNumber numberWithInt:tag]];
    [_urlCacheTagMap removeObjectForKey:[NSNumber numberWithInt:tag]];
    if (urlString == nil) {
        complete(nil);
        return;
    }
    if (urlString.length == 0) {
        complete(nil);
        return;
    }
    [self getCacheReponseDicForUrl:urlString complete:complete];
}

- (void)getCacheReponseDicForUrl:(NSString*)url complete:(void(^)(NSDictionary* jsonRet))complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *response = [[self getCacheInstance] stringForKey:[WYCommonUtils fileNameEncodedString:url]];
        NSDictionary* jsonRet = [response objectFromJSONString];
        ls_dispatch_main_sync_safe(^{
            //catch缓存异常，并删除该缓存
            @try {
                complete(jsonRet);
            }
            @catch (NSException *exception) {
                NSLog(@"getCacheReponseDicForUrl complete exception=%@", exception);
                [[self getCacheInstance] removeCacheForKey:[WYCommonUtils fileNameEncodedString:url]];
            }
        });
    });
}

- (void)saveCacheWithString:(NSString*)str url:(NSString*)url {
    [[self getCacheInstance] setString:str forKey:[WYCommonUtils fileNameEncodedString:url]];
}

- (void)clearAllCache {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[self getCacheInstance] clearCache];
    });
}

- (unsigned long long)getUrlCacheSize {
    NSString* cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    
    cachesDirectory = [[[cachesDirectory stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]] stringByAppendingPathComponent:_uid] copy];
    return [WYCommonUtils getDirectorySizeForPath:cachesDirectory];
}

- (NSDictionary*)getRequestJsonWithUrl:(NSString*)url type:(int)type parameters:(NSDictionary *)params{
    return [self getRequestJsonWithUrl:url requestType:type serverType:1 parameters:params fileParam:nil];
}

- (NSDictionary*)getRequestJsonWithUrl:(NSString*)url requestType:(int)requestType serverType:(int)serverType parameters:(NSDictionary *)params fileParam:(NSString*)fileParam{
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setObject:url forKey:@"url"];
    [dic setObject:[NSNumber numberWithInt:requestType]  forKey:@"requestType"];
    [dic setObject:[NSNumber numberWithInt:serverType] forKey:@"serverType"];
    //    if ([params count] > 0) {
    //        [dic setObject:[URLHelper getURL:nil queryParameters:params prefixed:NO] forKey:@"params"];
    //    }
    //    if (fileParam) {
    //        [dic setObject:fileParam forKey:@"fileParam"];
    //    }
    if (params) {
        [dic setObject:params forKey:@"params"];
    }
    return dic;
}

- (BOOL)reDirectXECommonWithFormatDic:(NSDictionary *)dic withData:(NSArray *)dataArray withTag:(int)tag withTimeout:(NSTimeInterval)timeout error:(NSError *)errPtr {
    
    NSString* url = [dic objectForKey:@"url"];
    NSString* method = @"POST";
    if ([[dic objectForKey:@"requestType"] integerValue] == 1) {
        method = @"GET";
    }
    
    NSDictionary *params = [dic objectForKey:@"params"];
    
    if ([method isEqualToString:@"GET"]) {
        NSString* fullUrl = url;
        if (params) {
            NSString *param = [URLHelper getURL:nil queryParameters:params prefixed:NO];
            fullUrl = [NSString stringWithFormat:@"%@?%@", fullUrl, param];
        }
        NSLog(@"getFullUrl=%@",fullUrl);
        if ([_urlCacheTagMap objectForKey:[NSNumber numberWithInt:tag]]) {
            [_urlCacheTagMap setObject:fullUrl forKey:[NSNumber numberWithInt:tag]];
            [_needCacheUrls addObject:fullUrl];
            return YES;
        }
        [_urlTagMap setObject:fullUrl forKey:[NSNumber numberWithInteger:tag]];
        [QHQnetworkingTool getWithURL:fullUrl params:nil success:^(id response) {
            NSLog(@"getFullUrl===========%@ response%@",fullUrl,response);
            [self onResponse:response withTag:tag withError:errPtr];
        } failure:^(NSError *error) {
            [self onResponse:nil withTag:tag withError:error];
        }];
        return YES;
    }else {
        NSString* fullUrl = url;
        if (params) {
            NSString *param = [URLHelper getURL:nil queryParameters:params prefixed:NO];
            NSString *postFullUrl = [NSString stringWithFormat:@"%@?%@", fullUrl, param];
            NSLog(@"postFullUrl=%@",postFullUrl);
        }
        if (dataArray) {
            [QHQnetworkingTool postWithURL:fullUrl params:params formDataArray:dataArray success:^(id response) {
                NSLog(@"postFullUrl===========%@ response%@",fullUrl,response);
                [self onResponse:response withTag:tag withError:errPtr];
            } failure:^(NSError *error) {
                [self onResponse:nil withTag:tag withError:error];
            }];
        }else{
            [QHQnetworkingTool postWithURL:fullUrl params:params success:^(id response) {
                NSLog(@"postFullUrl===========%@ response%@",fullUrl,response);
                [self onResponse:response withTag:tag withError:errPtr];
            } failure:^(NSError *error) {
                [self onResponse:nil withTag:tag withError:error];
            }];
        }
        return YES;
    }
    
    NSError* err = nil;
    if (errPtr) {
        err = errPtr;
    }
    onAppServiceBlock block = [self getonAppServiceBlockByTag:tag];
    if (block) {
        [self removeOnAppServiceBlockForTag:tag];
        block(tag, nil, err);
    }
    
    return NO;
}

- (void)onResponse:(id)jsonRet withTag:(int)tag withError:(NSError *)errPtr
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        BOOL timeout = NO;
        if (!jsonRet) {
            timeout = YES;
        }
        if (jsonRet && !errPtr) {
            NSString* fullUrl = [_urlTagMap objectForKey:[NSNumber numberWithInt:tag]];
            if (fullUrl) {
                //有错误的内容不缓存
                if ([_needCacheUrls containsObject:fullUrl] && ![WYEngine getErrorMsgWithReponseDic:jsonRet]) {
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonRet options:NSJSONWritingPrettyPrinted error:nil];
                    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    [[self getCacheInstance] setString:jsonString forKey:[WYCommonUtils fileNameEncodedString:fullUrl]];
                    //   NSLog(@"=======================%@",jsonRet);
                }
            }
        }
        
        [_urlTagMap removeObjectForKey:[NSNumber numberWithInt:tag]];
        
        onAppServiceBlock block = [self getonAppServiceBlockByTag:tag];
        if (block) {
            [self removeOnAppServiceBlockForTag:tag];
            if (timeout) {
                block(tag, nil, [NSError errorWithDomain:@"timeout" code:408 userInfo:nil]);
            }else{
                int code = [[WYEngine getErrorCodeWithReponseDic:jsonRet] intValue];
                if (code == -1) {
                    [self gotoLogin];
//                    return;
                }else if (code == -4){
                    [self needUserLogin:@"亲，您还没登陆咯"];
                }
                block(tag, jsonRet, errPtr);
            }
        }
    });
}

#pragma mark - API LIST
- (BOOL)getUserInfoWithUid:(NSString*)uid tag:(int)tag error:(NSError **)errPtr{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userid"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/user/sync",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)loginWithPhone:(NSString *)phone password:(NSString *)password tag:(int)tag error:(NSError **)errPtr
{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (phone) {
        [params setObject:phone forKey:@"username"];
    }
    if (password) {
        [params setObject:password forKey:@"password"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/login",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)registerWithPhone:(NSString*)phone password:(NSString*)password invitationCode:(NSString*)invitationCode tag:(int)tag
{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (phone) {
        [params setObject:phone forKey:@"mobile"];
    }
    if (password) {
        [params setObject:password forKey:@"password"];
    }
    if (invitationCode) {
        [params setObject:invitationCode forKey:@"invitationCode"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/register",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getCodeWithPhone:(NSString*)phone type:(NSString*)type tag:(int)tag
{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (phone) {
        [params setObject:phone forKey:@"mobile"];
    }
    if (type) {
        [params setObject:type forKey:@"type"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/sendSMSCode",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)checkCodeWithPhone:(NSString*)phone code:(NSString*)msgcode codeType:(NSString*)type tag:(int)tag
{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (phone) {
        [params setObject:phone forKey:@"mobile"];
    }
    if (msgcode) {
        [params setObject:msgcode forKey:@"checkCode"];
    }
    if (type) {
        [params setObject:type forKey:@"type"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/checkSMSCode",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
    
}

- (BOOL)resetPassword:(NSString*)password withPhone:(NSString*)phone phoneCode:(NSString*)phoneCode tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (password) {
        [params setObject:password forKey:@"password"];
    }
    if (phone) {
        [params setObject:phone forKey:@"mobile"];
    }
    if (phoneCode) {
        [params setObject:phoneCode forKey:@"code"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/resetPassword",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)checkInvitationCodeWithCode:(NSString*)invitationCode tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (invitationCode) {
        [params setObject:invitationCode forKey:@"invitationCode"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/checkInvitationCode",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getAppNewVersionWithTag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/settings/version/client/ios",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getNetbarListWithUid:(NSString *)uid  latitude:(float)latitude longitude:(float)longitude areaCode:(NSString *)areaCode tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (latitude != 0 && longitude != 0) {
        [params setObject:[[NSNumber numberWithFloat:longitude] description] forKey:@"longitude"];
        [params setObject:[[NSNumber numberWithFloat:latitude] description] forKey:@"latitude"];
    }
    if (areaCode) {
        [params setObject:areaCode forKey:@"areaCode"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/list",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getNetbarDetailWithUid:(NSString *)uid netbarId:(NSString *)nid tag:(int)tag {
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (nid) {
        [params setObject:nid forKey:@"netbarId"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/detail",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

//一键支付
- (BOOL)quickBookingWithUid:(NSString *)uid reserveDate:(NSString *)date amount:(double)amount netbarId:(NSString *)nid hours:(int)hours num:(int)num remark:(NSString *)remark tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (nid) {
        [params setObject:nid forKey:@"netbarId"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (date) {
        [params setObject:date forKey:@"reserveDate"];
    }
 
    [params setObject:[NSNumber numberWithDouble:amount] forKey:@"amount"];
    
    if (hours) {
        [params setObject:[NSNumber numberWithInt:hours] forKey:@"hours"];
    }
    if (num) {
        [params setObject:[NSNumber numberWithInt:num] forKey:@"num"];
    }
    if (remark) {
        [params setObject:remark forKey:@"remark"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/doReserve",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

//预订订单支付
- (BOOL)reservePayWithUid:(NSString *)uid body:(NSString *)body orderId:(NSString *)orderId packetsId:(NSArray*)pids type:(int)type tag:(int)tag {
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (body) {
        [params setObject:body forKey:@"body"];
    }
    if (orderId) {
        [params setObject:orderId forKey:@"orderId"];
    }
    [params setObject:[NSNumber numberWithInt:type] forKey:@"type"];
    if (pids != nil && pids.count > 0) {
        NSString * pidsString;
        pidsString = [WYCommonUtils stringSplitWithCommaForIds:pids];
        [params setObject:pidsString forKey:@"rids"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/pay/reservePay",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

//支付订单支付
- (BOOL)orderPayWithUid:(NSString *)uid body:(NSString *)body amount:(double)amount netbarId:(NSString *)nid packetsId:(NSArray*)pids type:(int)type origAmount:(double)origAmount tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (body) {
        [params setObject:body forKey:@"body"];
    }
    [params setObject:[NSNumber numberWithDouble:amount] forKey:@"amount"];
    [params setObject:[NSNumber numberWithDouble:origAmount] forKey:@"origAmount"];
    if (nid) {
        [params setObject:nid forKey:@"netbar_id"];
    }
    if (pids != nil && pids.count > 0) {
        NSString * pidsString;
        pidsString = [WYCommonUtils stringSplitWithCommaForIds:pids];
        [params setObject:pidsString forKey:@"rids"];
    }
    [params setObject:[NSNumber numberWithInt:type] forKey:@"type"];
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/pay/orderPay",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

//定金支付
- (BOOL)reserveToOrderWithUid:(NSString *)uid reserveId:(NSString *)reserveId tag:(int)tag {
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    [params setObject:uid forKey:@"userId"];
    [params setObject:reserveId forKey:@"reserveId"];
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/reserveToOrder",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}
- (BOOL)confirmReserveWithUid:(NSString *)uid reserveId:(NSString *)reserveId tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (reserveId) {
        [params setObject:reserveId forKey:@"reserveId"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/confirmReserve",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getReserveOrderListWithUid:(NSString *)uid page:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"pageSize"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/reserveList",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getPayOrderListWithUid:(NSString *)uid page:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"pageSize"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/orderList",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)cancelReserveOrderWithUid:(NSString *)uid reserveId:(NSString *)reserveId tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (reserveId) {
        [params setObject:reserveId forKey:@"reserveId"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/cancleReserve",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}
- (BOOL)deletePayOrderWithUid:(NSString *)uid orderId:(NSString *)orderId tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (orderId) {
        [params setObject:orderId forKey:@"orderId"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/deleteOrder",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getNetbarAllListWithUid:(NSString *)uid page:(int)page pageSize:(int)pageSize latitude:(float)latitude longitude:(float)longitude areaCode:(NSString *)areaCode tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"pageSize"];
    }
    if (latitude != 0 && longitude != 0) {
        [params setObject:[[NSNumber numberWithFloat:longitude] description] forKey:@"longitude"];
        [params setObject:[[NSNumber numberWithFloat:latitude] description] forKey:@"latitude"];
    }
    if (areaCode) {
        [params setObject:areaCode forKey:@"areaCode"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/listAll",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}
//搜索网吧(网吧名称)
- (BOOL)searchNetbarWithUid:(NSString *)uid netbarName:(NSString *)netbarName latitude:(float)latitude longitude:(float)longitude tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (netbarName) {
        [params setObject:netbarName forKey:@"netbarName"];
    }
    if (latitude != 0 && longitude != 0) {
        [params setObject:[[NSNumber numberWithFloat:longitude] description] forKey:@"longitude"];
        [params setObject:[[NSNumber numberWithFloat:latitude] description] forKey:@"latitude"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/searchNetbar",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)searchLocalNetbarWithUid:(NSString *)uid latitude:(float)latitude longitude:(float)longitude tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (latitude != 0 && longitude != 0) {
        [params setObject:[[NSNumber numberWithFloat:longitude] description] forKey:@"longitude"];
        [params setObject:[[NSNumber numberWithFloat:latitude] description] forKey:@"latitude"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/searchLocalNetbar",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)searchMapNetbarWithUid:(NSString *)uid city:(NSString *)city latitude:(float)latitude longitude:(float)longitude tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (city) {
        [params setObject:city forKey:@"city"];
    }
    if (latitude != 0 && longitude != 0) {
        [params setObject:[[NSNumber numberWithFloat:longitude] description] forKey:@"longitude"];
        [params setObject:[[NSNumber numberWithFloat:latitude] description] forKey:@"latitude"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/searchNetbarForMap",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

//网吧收藏
- (BOOL)collectionNetbarWithUid:(NSString *)uid netbarId:(NSString *)nid tag:(int)tag {
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (nid) {
        [params setObject:nid forKey:@"netbarId"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/favor",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)unCollectionNetbarWithUid:(NSString *)uid netbarId:(NSString *)nid tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (nid) {
        [params setObject:nid forKey:@"netbarId"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/unfavor",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getAllValidCityListWithTag:(int)tag{
    //    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/common/area/allvalidcity",API_URL] type:1 parameters:nil];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}
- (BOOL)validateAreaWithAreaName:(NSString *)areaName tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (areaName) {
        [params setObject:areaName forKey:@"areaName"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/netbar/validateArea",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

#pragma mark - mine
- (BOOL)editUserInfoWithUid:(NSString *)uid nickName:(NSString *)nickName avatar:(NSArray *)avatar userHead:(NSString *)userHead tag:(int)tag;{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (nickName) {
        [params setObject:nickName forKey:@"nickname"];
    }
    if (userHead) {
        [params setObject:userHead forKey:@"userhead"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/my/editUser",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:avatar withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)editUserCityWithUid:(NSString *)uid cityCode:(NSString *)cityCode cityName:(NSString *)cityName tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (cityCode) {
        [params setObject:cityCode forKey:@"cityCode"];
    }
    if (cityName) {
        [params setObject:cityName forKey:@"cityName"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/my/editCity",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getHeadAvatarListWithTag:(int)tag{
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/my/heads",API_URL] type:1 parameters:nil];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getUnReadMessageCountWithUid:(NSString *)uid type:(int)type tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    [params setObject:[NSNumber numberWithInt:type] forKey:@"type"];
    
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/my/msgCount",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}
- (BOOL)setMessageReadWithUid:(NSString *)uid type:(int)type tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    [params setObject:[NSNumber numberWithInt:type] forKey:@"type"];
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/my/msgRead",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getMessageListWithUid:(NSString *)uid page:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"pageSize"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/my/myMsg",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getCollectNetBarListWithUid:(NSString *)uid latitude:(float)latitude longitude:(float)longitude page:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (latitude != 0 && longitude != 0) {
        [params setObject:[[NSNumber numberWithFloat:longitude] description] forKey:@"longitude"];
        [params setObject:[[NSNumber numberWithFloat:latitude] description] forKey:@"latitude"];
    }
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"pageSize"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/my/netbarFavor",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}
- (BOOL)getCollectGameListWithUid:(NSString *)uid page:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"pageSize"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/my/gameFavor",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}
- (BOOL)getFreeRedPacketListWithUid:(NSString *)uid page:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"pageSize"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/my/currentRedbag",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}
- (BOOL)getHistoryRedPacketListWithUid:(NSString *)uid page:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"pageSize"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/my/historyRedbag",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getApplyActivityListWithUid:(NSString *)uid page:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"rows"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/activity/reged",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getPulishMatchWarListWithUid:(NSString *)uid page:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"rows"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/activity/match/pub",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getApplyMatchWarListWithUid:(NSString *)uid page:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"rows"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/activity/match/reged",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

#pragma mark - 活动
- (BOOL)getActivityListWithPage:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"rows"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/activity/list",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getInfoListWithPage:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"rows"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/activity/info/list",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getMatchListWithPage:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"rows"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/activity/match/list",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getActivityDetailWithUid:(NSString *)uid activityId:(NSString *)aId tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (aId) {
        [params setObject:aId forKey:@"id"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }

    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/activity/detail",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)collectionActivityWithUid:(NSString *)uid activityId:(NSString *)aId tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (aId) {
        [params setObject:aId forKey:@"id"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/activity/favor",API_URL] type:0 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getActivityAddressWithUid:(NSString *)uid activityId:(NSString *)aId tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (aId) {
        [params setObject:aId forKey:@"id"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/activity/address",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getActivityHotListWithTag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/activity/info/hots",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getTopicsInfoWithTag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/activity/info",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getTopicsListWithTid:(NSString *)tid page:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (tid) {
        [params setObject:tid forKey:@"id"];
    }
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"rows"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/activity/info/subject/list",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

#pragma mark - 手游
- (BOOL)getGameListWithUid:(NSString*)uid page:(int)page pageSize:(int)pageSize tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    if (page > 0) {
        [params setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    }
    if (pageSize > 0) {
        [params setObject:[NSNumber numberWithInt:pageSize] forKey:@"rows"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/game/list",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)getGameDetailsWithGameId:(NSString *)gameId uid:(NSString*)uid tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (gameId) {
        [params setObject:gameId forKey:@"id"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/game/detail",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

- (BOOL)collectGameWithUid:(NSString *)uid gameId:(NSString *)gameId tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (gameId) {
        [params setObject:gameId forKey:@"id"];
    }
    if (uid) {
        [params setObject:uid forKey:@"userId"];
    }
    if (_token) {
        [params setObject:_token forKey:@"token"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/game/favor",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}
- (BOOL)getGameDownloadUrlWithGameId:(NSString*)gameId tag:(int)tag{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    if (gameId) {
        [params setObject:gameId forKey:@"id"];
    }
    NSDictionary* formatDic = [self getRequestJsonWithUrl:[NSString stringWithFormat:@"%@/game/download",API_URL] type:1 parameters:params];
    return [self reDirectXECommonWithFormatDic:formatDic withData:nil withTag:tag withTimeout:CONNECT_TIMEOUT error:nil];
}

@end
