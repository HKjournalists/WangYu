//
//  WYNetbarInfo.h
//  WangYu
//
//  Created by KID on 15/5/13.
//  Copyright (c) 2015年 KID. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WYNetbarInfo : NSObject

@property(nonatomic, strong) NSString* nid;                         //网吧id
@property(nonatomic, strong) NSString* netbarName;                  //名称
@property(nonatomic, strong) NSString* netbarImageUrl;              //图片地址
@property(nonatomic, strong) NSString* address;                     //位置
@property(nonatomic, strong) NSString* distance;                    //距离
@property(nonatomic, assign) BOOL isOrder;                          //是否支持预订
@property(nonatomic, assign) BOOL isPay;                            //是否支持支付
@property(nonatomic, assign) BOOL isRecommend;                      //是否被推荐
@property(nonatomic, assign) int price;                             //上网价格
@property(nonatomic, readonly) NSURL* smallImageUrl;                //图片网络地址
@property(nonatomic, strong) NSDictionary* netbarInfoByJsonDic;     //网吧字典

@end