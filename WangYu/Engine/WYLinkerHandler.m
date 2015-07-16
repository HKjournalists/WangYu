//
//  WYLinkerHandler.m
//  WangYu
//
//  Created by KID on 15/6/1.
//  Copyright (c) 2015年 KID. All rights reserved.
//

#import "WYLinkerHandler.h"
#import "WYCommonWebVc.h"
#import "WYEngine.h"
#import "WYAlertView.h"
#import "WYSettingConfig.h"
#import "OrdersViewController.h"
#import "RedPacketViewController.h"
#import "MessageDetailsViewController.h"
#import "BookDetailViewController.h"
#import "OrderDetailViewController.h"
#import "WYMessageInfo.h"
#import "MatchWarDetailViewController.h"
#import "MatchDetailViewController.h"
#import "NetbarDetailViewController.h"
#import "GameDetailsViewController.h"

@implementation WYLinkerHandler

+(id)handleDealWithHref:(NSString *)href From:(UINavigationController*)nav{
    NSURL *realUrl = [NSURL URLWithString:href];
    if (realUrl == nil) {
        realUrl = [NSURL URLWithString:[href stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    NSString* scheme = [realUrl.scheme lowercaseString];
    if ([scheme isEqualToString:@"wycategory"]) {
        NSString *lastCompment = [[realUrl path] lastPathComponent];
        WYLog(@"lastCompment = %@",lastCompment);
        NSDictionary *paramDic = [WYCommonUtils getParamDictFrom:realUrl.query];
        WYLog(@"paramDic = %@",paramDic);
        if ([[realUrl host] isEqualToString:@"sys"]) {
            //系统消息
            MessageDetailsViewController *mdVc = [[MessageDetailsViewController alloc] init];
            WYMessageInfo *messageInfo = [[WYMessageInfo alloc] init];
            messageInfo.msgId = [[paramDic objectForKey:@"msgId"] description];
            mdVc.messageInfo = messageInfo;
            return mdVc;
        }else if ([[realUrl host] isEqualToString:@"redbag"]){
            //红包消息
            RedPacketViewController *rpVc = [[RedPacketViewController alloc] init];
            return rpVc;
        }else if ([[realUrl host] isEqualToString:@"reservation"]){
            //预定订单消息
            BookDetailViewController *bdVc = [[BookDetailViewController alloc] init];
            WYOrderInfo *orderInfo = [[WYOrderInfo alloc] init];
            orderInfo.reserveId = [[paramDic objectForKey:@"objId"] description];
            bdVc.orderInfo = orderInfo;
            return bdVc;
        }else if ([[realUrl host] isEqualToString:@"pay"]){
            //支付消息
            OrderDetailViewController *odVc = [[OrderDetailViewController alloc] init];
            WYOrderInfo *orderInfo = [[WYOrderInfo alloc] init];
            orderInfo.orderId = [[paramDic objectForKey:@"objId"] description];
            odVc.orderInfo = orderInfo;
            return odVc;
        }else if ([[realUrl host] isEqualToString:@"activity"]){
            //活动赛事消息
            MatchDetailViewController *mdVc = [[MatchDetailViewController alloc] init];
            WYActivityInfo *activityInfo = [[WYActivityInfo alloc] init];
            activityInfo.aId = [[paramDic objectForKey:@"objId"] description];
            mdVc.activityInfo = activityInfo;
            return mdVc;
        }else if ([[realUrl host] isEqualToString:@"match"]){
            //约战消息
            MatchWarDetailViewController *matchDetailVc = [[MatchWarDetailViewController alloc] init];
            WYMatchWarInfo *matchWarInfo = [[WYMatchWarInfo alloc] init];
            matchWarInfo.mId = [[paramDic objectForKey:@"objId"] description];
            matchDetailVc.matchWarInfo = matchWarInfo;
            return matchDetailVc;
        }else if ([[realUrl host] isEqualToString:@"redbag_weekly"]){
            //每周红包推送消息
            [[WYSettingConfig staticInstance] setWeekRedBagMessageUnreadEvent:YES];
        }else if ([[realUrl host] isEqualToString:@"member"]){
            //会员消息
        }else if ([[realUrl host] isEqualToString:@"netbar"]){
            //网吧
            NetbarDetailViewController *ndVc = [[NetbarDetailViewController alloc] init];
            WYNetbarInfo *netbarInfo = [[WYNetbarInfo alloc] init];
            netbarInfo.nid = [[paramDic objectForKey:@"objId"] description];
            ndVc.netbarInfo = netbarInfo;
            return ndVc;
        }else if ([[realUrl host] isEqualToString:@"game"]){
            GameDetailsViewController *gdVc = [[GameDetailsViewController alloc] init];
            WYGameInfo *gameInfo = [[WYGameInfo alloc] init];
            gameInfo.gameId = [[paramDic objectForKey:@"objId"] description];
            gdVc.gameInfo = gameInfo;
            return gdVc;
        }
        return nil;

    }else if ([scheme isEqualToString:@"wydsopen"]){
        NSDictionary *paramDic = [WYCommonUtils getParamDictFrom:realUrl.query];
        NSLog(@"query dict = %@", paramDic);
        NSString *action = [[realUrl.host lowercaseString] description];
        WYLog(@"url.host = %@",action);
        NSString *lastCompment = [[[realUrl path] lastPathComponent] lowercaseString];
        WYLog(@"lastCompment = %@",lastCompment);
        if ([lastCompment isEqualToString:@"matchdetail"]) {
            //约战详情
            MatchWarDetailViewController *matchDetailVc = [[MatchWarDetailViewController alloc] init];
            WYMatchWarInfo *matchWarInfo = [[WYMatchWarInfo alloc] init];
            matchWarInfo.mId = [[paramDic objectForKey:@"id"] description];
            matchDetailVc.matchWarInfo = matchWarInfo;
            return matchDetailVc;
        }
        
    }else if([scheme hasPrefix:@"http"]){
        //        NSString *lastCompment = [[realUrl path] lastPathComponent];
        //        NSDictionary *paramDic = [XECommonUtils getParamDictFrom:realUrl.query];
        //if...else
        
        if (nav) {
            NSString *url = [realUrl description];
            WYCommonWebVc *webvc = [[WYCommonWebVc alloc] initWithAddress:url];
            if ([url hasPrefix:[NSString stringWithFormat:@"%@/activity/info/web/detail",[WYEngine shareInstance].baseUrl]]) {
                NSDictionary *paramDic = [WYCommonUtils getParamDictFrom:realUrl.query];
                WYNewsInfo *newsInfo = [[WYNewsInfo alloc] init];
                newsInfo.nid = [[paramDic stringObjectForKey:@"id"] description];
                newsInfo.title = [[paramDic stringObjectForKey:@"title"] description];
                newsInfo.brief = [[paramDic stringObjectForKey:@"brief"] description];
                newsInfo.thumbImageUrl = [[paramDic stringObjectForKey:@"imageUrl"] description];
                webvc.newsInfo = newsInfo;
                webvc.isShareViewOut = YES;
            }
            [nav pushViewController:webvc animated:YES];
        }
        return nil;
    }
    
    return nil;
}

@end
