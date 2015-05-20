//
//  WYShareManager.m
//  WangYu
//
//  Created by KID on 15/5/19.
//  Copyright (c) 2015年 KID. All rights reserved.
//

#import "WYShareManager.h"
#import "WYProgressHUD.h"

static WYShareManager* wy_shareManager = nil;

@interface WYShareManager ()
@property(nonatomic, strong) WYWeiboShareResultBlock shareBlock;

@end

@implementation WYShareManager

+ (WYShareManager*)shareInstance {
    @synchronized(self) {
        if (wy_shareManager == nil) {
            wy_shareManager = [[WYShareManager alloc] init];
        }
    }
    return wy_shareManager;
}

- (id)init{
    self = [super init];
    if (self) {
        [WXApi registerApp:WX_ID withDescription:@"WY"];
        
#ifdef DEBUG
        [WeiboSDK enableDebugMode:YES];
#endif
        [WeiboSDK registerApp:SINA_ID];
    }
    return self;
}

+ (BOOL)shareToWXWithScene:(int)scene title:(NSString *)title description:(NSString *)description webpageUrl:(NSString *)webpageUrl image:(UIImage*)image{
    
    if (!([WXApi isWXAppInstalled])) {
        NSLog(@"not support or not install weixin");
        [WYUIUtils showAlertWithMsg:@"微信未安装！"];
        return NO;
    }
    
    WXMediaMessage *msg = [WXMediaMessage message];
    msg.title = title;
    msg.description = description;
    
    if (msg.title.length > 512) {
        msg.title = [msg.title substringToIndex:512];
    }
    if (msg.description.length>1024) {
        msg.description = [msg.description substringToIndex:1024];
    }
    
    if (scene == WXSceneTimeline) {
        if (msg.description.length > 0) {
            msg.title = [msg.description substringToIndex:MIN(msg.description.length, 512)];
        }
    }
    
    WXWebpageObject *ext = [WXWebpageObject object];
    ext.webpageUrl = webpageUrl;
    
    NSData *imgData = nil;
    
    if (!image) {
        image = [UIImage imageNamed:@"netbar_load_icon"];
    }
    if (image) {
        imgData = UIImageJPEGRepresentation(image, WY_IMAGE_COMPRESSION_QUALITY);
        if (imgData.length > MAX_WX_IMAGE_SIZE) {//try again
            imgData = UIImageJPEGRepresentation(image, WY_IMAGE_COMPRESSION_QUALITY/2);
        }
        
    }
    msg.mediaObject = ext;
    if (imgData && imgData.length < MAX_WX_IMAGE_SIZE) {
        [msg setThumbData:imgData];
    }else{
    }
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = msg;
    req.scene = scene;
    BOOL ret = [WXApi sendReq:req];
    WYLog(@"shareToWX send ret:%d", ret);
    return ret;
}

- (void)shareToWb:(WYWeiboShareResultBlock)result title:(NSString *)title description:(NSString *)description webpageUrl:(NSString *)webpageUrl image:(UIImage*)image VC:(id)VC{
    self.shareBlock = result;
    
    /*****多媒体
    WBWebpageObject *msg = [WBWebpageObject object];
    msg.title = title;
    msg.description = description;
    [msg setObjectID:@"identifier1"];
    if (msg.description.length>1024) {
        msg.description = [msg.description substringToIndex:1024];
    }
    NSData *imgData = nil;
    if (!image) {
        image = [UIImage imageNamed:@"netbar_load_icon"];
    }
    if (image) {
        imgData = UIImageJPEGRepresentation(image, WY_IMAGE_COMPRESSION_QUALITY);
        if (imgData.length > MAX_WX_IMAGE_SIZE) {//try again
            imgData = UIImageJPEGRepresentation(image, WY_IMAGE_COMPRESSION_QUALITY/2);
        }
    }
    if (imgData && imgData.length < MAX_WX_IMAGE_SIZE) {
        [msg setThumbnailData:imgData];
    }else{
    }
    msg.webpageUrl = webpageUrl;
    */
    
    WBImageObject *msg = [WBImageObject object];
    NSData *imgData = nil;
    if (!image) {
        image = [UIImage imageNamed:@"netbar_load_icon"];
    }
    if (image) {
        imgData = UIImageJPEGRepresentation(image, WY_IMAGE_COMPRESSION_QUALITY);
        if (imgData.length > MAX_WX_IMAGE_SIZE) {//try again
            imgData = UIImageJPEGRepresentation(image, WY_IMAGE_COMPRESSION_QUALITY/2);
        }
    }
    if (imgData && imgData.length < MAX_WX_IMAGE_SIZE) {
        msg.imageData = imgData;
    }else{
    }
    
    WBMessageObject *sendMsg = [WBMessageObject message];
    sendMsg.imageObject = msg;
//    sendMsg.mediaObject = msg;
    NSString* shareTitle = [NSString stringWithFormat:@"%@  %@ %@",title,@"(分享自@网娱大师)",webpageUrl];
    sendMsg.text = shareTitle;
    
    //不能SSO分享
//    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest request];
//    request.message = sendMsg;
    
    //SSO分享
    WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
    authRequest.redirectURI = Sina_RedirectURL;
    authRequest.scope = @"all";
    NSString *vcStr = NSStringFromClass([VC class]);
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:sendMsg authInfo:authRequest access_token:nil];
    request.userInfo = @{@"ShareMessageFrom":vcStr};
    
    BOOL ret = [WeiboSDK sendRequest:request];
    WYLog(@"shareToWb send ret:%d", ret);
}

#pragma mark - WXApiDelegate
-(void)onResp:(BaseResp *)resp{
    if([resp isKindOfClass:[SendMessageToWXResp class]]){
        NSString *strMsg = [NSString stringWithFormat:@"Wx发送消息结果:%d", resp.errCode];
        NSLog(@"send ret:%@", strMsg);
        switch (resp.errCode) {
            case WXSuccess:{
                [WYProgressHUD AlertSuccess:@"分享微信成功"];
            }
                break;
                
            default:
                [WYProgressHUD AlertError:@"分享微信失败"];
                break;
        }
    }
}

#pragma mark - WeiboSDKDelegate
- (void)didReceiveWeiboRequest:(WBBaseRequest *)request{
    
}
- (void)didReceiveWeiboResponse:(WBBaseResponse *)response {
    
    if ([response isKindOfClass:WBAuthorizeResponse.class])
    {
    }else if ([response isKindOfClass:WBSendMessageToWeiboResponse.class]){
        if (response.statusCode == WeiboSDKResponseStatusCodeSuccess) {
            [WYProgressHUD AlertSuccess:@"分享微博成功"];
        }else{
            [WYProgressHUD AlertError:@"分享微博失败"];
        }
        if (self.shareBlock) {
            self.shareResponse = (WBSendMessageToWeiboResponse *)response;
            self.shareBlock((WBSendMessageToWeiboResponse *)response);
            self.shareResponse = nil;
        }
    }
}

@end
