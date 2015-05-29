//
//  NetbarDetailCell.m
//  WangYu
//
//  Created by KID on 15/5/11.
//  Copyright (c) 2015年 KID. All rights reserved.
//

#import "NetbarDetailCell.h"

@interface NetbarDetailCell()

@property (nonatomic, weak) UIFont *font;

@end

@implementation NetbarDetailCell

- (void)awakeFromNib {
    // Initialization code
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        self.font = SKIN_FONT_FROMNAME(12);
        dispatch_async(dispatch_get_main_queue(),^{
            self.titleLabel.font = self.font;
            self.dateLabel.font = self.font;
            self.joinNumLabel.font = self.font;
            self.nameLabel.font = self.font;
        });
    });
    self.titleLabel.textColor = SKIN_TEXT_COLOR1;
    self.dateLabel.textColor = SKIN_TEXT_COLOR2;
    self.joinNumLabel.textColor = SKIN_TEXT_COLOR2;
    self.nameLabel.textColor = SKIN_TEXT_COLOR1;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setMatchWarInfo:(WYMatchWarInfo *)matchWarInfo {
    _matchWarInfo = matchWarInfo;
    self.titleLabel.text = matchWarInfo.title;
    self.dateLabel.text = [WYUIUtils dateDiscriptionFromDate:matchWarInfo.startTime];;
    
    self.nameLabel.text = matchWarInfo.itemName;
}

@end
