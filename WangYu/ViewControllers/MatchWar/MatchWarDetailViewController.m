//
//  MatchWarDetailViewController.m
//  WangYu
//
//  Created by Leejun on 15/7/1.
//  Copyright (c) 2015年 KID. All rights reserved.
//

#import "MatchWarDetailViewController.h"
#import "UIImageView+WebCache.h"
#import "UIScrollView+SVInfiniteScrolling.h"
#import "SettingViewCell.h"
#import "MatchCommentViewCell.h"
#import "WYEngine.h"
#import "NetbarDetailViewController.h"
#import "WYProgressHUD.h"
#import "WYShareActionSheet.h"

#define MATCH_DETAIL_TYPE_INFO          0
#define MATCH_DETAIL_TYPE_COMMENT       1

@interface MatchWarDetailViewController ()<UITableViewDataSource,UITableViewDelegate,WYShareActionSheetDelegate>
{
    WYShareActionSheet *_shareAction;
}
@property (nonatomic, strong) IBOutlet UITableView *matchInfoTableView;
@property (strong, nonatomic) NSMutableArray *commentInfos;
@property (nonatomic, strong) IBOutlet UITableView *commentTableView;

@property (assign, nonatomic) NSInteger selectedSegmentIndex;
@property (assign, nonatomic) SInt64  commentNextCursor;
@property (assign, nonatomic) BOOL commentCanLoadMore;

@property (nonatomic, strong) IBOutlet UIView *matchHeadContainerView;
@property (nonatomic, strong) IBOutlet UIImageView *bkImageView;
@property (nonatomic, strong) UIView   *supInfoHeadView;
@property (nonatomic, strong) UIView   *supCommentHeadView;
@property (nonatomic, strong) IBOutlet UILabel *matchTitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *matchOwnerAvatarImgView;
@property (nonatomic, strong) IBOutlet UIView *statusView;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) IBOutlet UIView *segmentView;
@property (nonatomic, strong) IBOutlet UIImageView *segmentMoveImageView;
@property (nonatomic, strong) IBOutlet UILabel *infoTipLabel;
@property (nonatomic, strong) IBOutlet UIButton *infoTabButton;
@property (nonatomic, strong) IBOutlet UILabel *commentNumTipLabel;
@property (nonatomic, strong) IBOutlet UIButton *commentTabButton;

@property (strong, nonatomic) IBOutlet UIView *customTitleBarView;
@property (strong, nonatomic) IBOutlet UIButton *cusBackButton;
@property (strong, nonatomic) IBOutlet UILabel *toobarTitleLabel;

@property (strong, nonatomic) IBOutlet UIView *shareBottomContainerView;
@property (strong, nonatomic) IBOutlet UIButton *manageButton;

@property (strong, nonatomic) IBOutlet UIView *commentBottomContainerView;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;

-(IBAction)matchInfoAction:(id)sender;
-(IBAction)commentSegmentAction:(id)sender;
-(IBAction)shareAction:(id)sender;
-(IBAction)manageAction:(id)sender;
-(IBAction)sendAction:(id)sender;

@end

@implementation MatchWarDetailViewController

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.supInfoHeadView = [[UIView alloc] init];
    self.supInfoHeadView.backgroundColor = [UIColor clearColor];
    self.supCommentHeadView = [[UIView alloc] init];
    self.supCommentHeadView.backgroundColor = [UIColor clearColor];
    
    UIEdgeInsets inset = UIEdgeInsetsMake(0, 0, 0, 0);
    [self setContentInsetForScrollView:self.matchInfoTableView inset:inset];
    [self setContentInsetForScrollView:self.commentTableView inset:inset];
    [self.view insertSubview:self.customTitleBarView aboveSubview:self.titleNavBar];
    
    _selectedSegmentIndex = 0;
    [self refreshHeadViewShow];
    
    [self feedsTypeSwitch:MATCH_DETAIL_TYPE_INFO needRefreshFeeds:YES];
    
    
    self.commentTableView.showsInfiniteScrolling = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initNormalTitleNavBarSubviews{
//    [self setTitle:@"约战详情"];
    self.titleNavBar.backgroundColor = SKIN_TEXT_COLOR1;
    self.titleNavBar.alpha = 0.0;
    [self setBarBackgroundColor:[UIColor clearColor] showLine:NO];
//    [self.titleNavBarLeftButton setTintColor:[UIColor whiteColor]];
    [self setTilteLeftViewHide:YES];
}

-(void)feedsTypeSwitch:(int)tag needRefreshFeeds:(BOOL)needRefresh
{
    if (tag == MATCH_DETAIL_TYPE_INFO) {
        //减速率
        self.commentTableView.decelerationRate = 0.0f;
        self.matchInfoTableView.decelerationRate = 1.0f;
        self.commentTableView.hidden = YES;
        self.matchInfoTableView.hidden = NO;
        
        if ([self.matchHeadContainerView superview]) {
            [self.matchHeadContainerView removeFromSuperview];
        }
        _supInfoHeadView.frame = self.matchHeadContainerView.frame;
        [_supInfoHeadView addSubview:self.matchHeadContainerView];
        self.matchInfoTableView.tableHeaderView = _supInfoHeadView;
        
        [self scrollViewDidScroll:self.matchInfoTableView];
        [self refreshBottomViewShow];
        
        if (needRefresh) {
            [self getCacheMatchWarInfo];
            [self refreshMatchWarInfo];
        }
    }else if (tag == MATCH_DETAIL_TYPE_COMMENT){
        
        self.commentTableView.decelerationRate = 1.0f;
        self.matchInfoTableView.decelerationRate = 0.0f;
        self.matchInfoTableView.hidden = YES;
        self.commentTableView.hidden = NO;
        
        if ([self.matchHeadContainerView superview]) {
            [self.matchHeadContainerView removeFromSuperview];
        }
        _supCommentHeadView.frame = self.matchHeadContainerView.frame;
        [_supCommentHeadView addSubview:self.matchHeadContainerView];
        self.commentTableView.tableHeaderView = _supCommentHeadView;
        
        [self scrollViewDidScroll:self.commentTableView];
        [self refreshBottomViewShow];
        
        if (!_commentInfos) {
            [self getCacheCommentInfos];
            [self refreshCommentInfos];
            return;
        }
        if (needRefresh) {
            [self refreshCommentInfos];
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - custom
-(void)refreshHeadViewShow{
    
    self.infoTipLabel.font = SKIN_FONT_FROMNAME(14);
    self.infoTipLabel.textColor = SKIN_TEXT_COLOR1;
    self.commentNumTipLabel.font = SKIN_FONT_FROMNAME(14);
    self.commentNumTipLabel.textColor = SKIN_TEXT_COLOR1;
    self.matchTitleLabel.font = SKIN_FONT_FROMNAME(15);
    
    [self.matchOwnerAvatarImgView.layer setBorderWidth:1]; //边框宽度
    [self.matchOwnerAvatarImgView.layer setBorderColor:[UIColor whiteColor].CGColor];//边框颜色
    self.matchOwnerAvatarImgView.layer.masksToBounds = YES;
    self.matchOwnerAvatarImgView.layer.cornerRadius = self.matchOwnerAvatarImgView.frame.size.width/2;
    self.matchOwnerAvatarImgView.clipsToBounds = YES;
    self.matchOwnerAvatarImgView.contentMode = UIViewContentModeScaleAspectFill;
    [self.matchOwnerAvatarImgView sd_setImageWithURL:_matchWarInfo.userInfo.smallAvatarUrl placeholderImage:[UIImage imageNamed:@"personal_avatar_default_icon_small"]];
    
    self.bkImageView.clipsToBounds = YES;
    self.bkImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.bkImageView sd_setImageWithURL:nil placeholderImage:[UIImage imageNamed:@"match_detail_bg_lol"]];
    
    self.statusView.alpha = 0.7;
    self.statusView.layer.cornerRadius = self.statusView.frame.size.width/2;
    self.statusView.clipsToBounds = YES;
    self.statusView.backgroundColor = UIColorToRGB(0xfdd730);
    self.statusLabel.font = SKIN_FONT_FROMNAME(11);
    self.statusLabel.textColor = SKIN_TEXT_COLOR1;
    self.statusLabel.text = @"进行中";
    
    self.toobarTitleLabel.font = SKIN_FONT_FROMNAME(18);
    self.toobarTitleLabel.textColor = [UIColor whiteColor];
    self.toobarTitleLabel.text = _matchWarInfo.title;
    
    self.matchTitleLabel.text = _matchWarInfo.title;
    
    
    self.manageButton.titleLabel.font = SKIN_FONT_FROMNAME(14);
    [self.manageButton setTitleColor:SKIN_TEXT_COLOR1 forState:UIControlStateNormal];
    [self.manageButton.layer setMasksToBounds:YES];
    [self.manageButton.layer setCornerRadius:4.0];
    self.manageButton.backgroundColor = SKIN_COLOR;
    [self.manageButton setTitle:@"加入约战" forState:0];
    
    self.sendButton.titleLabel.font = SKIN_FONT_FROMNAME(14);
    [self.sendButton setTitleColor:SKIN_TEXT_COLOR1 forState:UIControlStateNormal];
    [self.sendButton.layer setMasksToBounds:YES];
    [self.sendButton.layer setCornerRadius:4.0];
    self.sendButton.backgroundColor = SKIN_COLOR;
    [self.sendButton setTitle:@"发送" forState:0];
    
    if (_matchWarInfo.isStart == 0) {
        self.statusLabel.text = @"未开始";
        self.statusView.backgroundColor = UIColorToRGB(0xf1f1f1);
    }else if (_matchWarInfo.isStart == 1){
        self.statusLabel.text = @"已开始";
        self.statusView.backgroundColor = UIColorToRGB(0xfdd730);
    }else{
        self.statusLabel.text = @"";
    }
    
    if (_matchWarInfo.userStatus == 1) {
        [self.manageButton setTitle:@"约战管理" forState:0];
    }else if (_matchWarInfo.userStatus == 2){
        [self.manageButton setTitle:@"退出约战" forState:0];
    }else if (_matchWarInfo.userStatus == 3){
        [self.manageButton setTitle:@"加入约战" forState:0];
    }
    
    
    CGPoint center = self.segmentMoveImageView.center;
    center.x = SCREEN_WIDTH/4;
    self.segmentMoveImageView.center = center;
    
}

-(void)refreshSegmentViewUI:(UIButton *)sender{
    if (sender == self.infoTabButton) {
        self.infoTabButton.selected = YES;
        self.commentTabButton.selected = NO;
        self.infoTipLabel.textColor = UIColorToRGB(0xf03f3f);
        self.commentNumTipLabel.textColor = SKIN_TEXT_COLOR1;
        _selectedSegmentIndex = MATCH_DETAIL_TYPE_INFO;
        [self feedsTypeSwitch:(int)_selectedSegmentIndex needRefreshFeeds:NO];
    }else if (sender == self.commentTabButton){
        self.commentTabButton.selected = YES;
        self.infoTabButton.selected = NO;
        self.commentNumTipLabel.textColor = UIColorToRGB(0xf03f3f);
        self.infoTipLabel.textColor = SKIN_TEXT_COLOR1;
        _selectedSegmentIndex = MATCH_DETAIL_TYPE_COMMENT;
        [self feedsTypeSwitch:(int)_selectedSegmentIndex needRefreshFeeds:YES];
    }
    [UIView animateWithDuration:0.2 animations:^{
        CGPoint center = self.segmentMoveImageView.center;
        center.x = sender.center.x;
        self.segmentMoveImageView.center = center;
    }];
}

-(void)refreshBottomViewShow{
    
    if (_selectedSegmentIndex == MATCH_DETAIL_TYPE_INFO) {
        if (_commentBottomContainerView.superview) {
            [_commentBottomContainerView removeFromSuperview];
        }
        CGRect frame = self.shareBottomContainerView.frame;
        frame.origin.y = SCREEN_HEIGHT - frame.size.height;
        self.shareBottomContainerView.frame = frame;
        [self.view addSubview:self.shareBottomContainerView];
        
    }else if (_selectedSegmentIndex == MATCH_DETAIL_TYPE_COMMENT){
        if (_shareBottomContainerView.superview) {
            [_shareBottomContainerView removeFromSuperview];
        }
        CGRect frame = self.commentBottomContainerView.frame;
        frame.origin.y = SCREEN_HEIGHT - frame.size.height;
        frame.size.width = SCREEN_WIDTH;
        self.commentBottomContainerView.frame = frame;
        [self.view addSubview:self.commentBottomContainerView];
    }
}
#pragma mark - IBAction
-(IBAction)matchInfoAction:(id)sender{
    if (self.infoTabButton.selected) {
        return;
    }
    [self refreshSegmentViewUI:sender];
}
-(IBAction)commentSegmentAction:(id)sender{
    if (self.commentTabButton.selected) {
        return;
    }
    [self refreshSegmentViewUI:sender];
}

-(IBAction)shareAction:(id)sender{
    _shareAction = [[WYShareActionSheet alloc] init];
    _shareAction.matchWarInfo = _matchWarInfo;
    _shareAction.owner = self;
    [_shareAction showShareAction];
}
-(IBAction)manageAction:(id)sender{
    
    if ([[WYEngine shareInstance] needUserLogin:@"登录后才能报名约战"]) {
        return;
    }
    if (_matchWarInfo.userStatus == 1) {
        
    }else if (_matchWarInfo.userStatus == 2){
        
    }else if (_matchWarInfo.userStatus == 3){
        
    }else if (_matchWarInfo.userStatus == -1){
        if ([[WYEngine shareInstance] needUserLogin:@"登录后才能报名约战"]) {
            return;
        }
    }
}
-(IBAction)sendAction:(id)sender{
    if ([[WYEngine shareInstance] needUserLogin:@"登录后才能评论"]) {
        return;
    }
}
#pragma mark - request
-(void)getCacheMatchWarInfo{
    WS(weakSelf);
    int tag = [[WYEngine shareInstance] getConnectTag];
    [[WYEngine shareInstance] addGetCacheTag:tag];
    [[WYEngine shareInstance] getMatchDetailsWithMatchId:_matchWarInfo.mId uid:[WYEngine shareInstance].uid tag:tag];
    [[WYEngine shareInstance] getCacheReponseDicForTag:tag complete:^(NSDictionary *jsonRet){
        if (jsonRet == nil) {
            //...
        }else{
            
            NSDictionary *object = [jsonRet dictionaryObjectForKey:@"object"];
            if ([object isKindOfClass:[NSDictionary class]]) {
                [weakSelf.matchWarInfo setMatchWarInfoByJsonDic:object];
            }
            [weakSelf refreshHeadViewShow];
            [weakSelf.matchInfoTableView reloadData];
        }
    }];
}
-(void)refreshMatchWarInfo{
    self.commentNextCursor = 2;
    WS(weakSelf);
    int tag = [[WYEngine shareInstance] getConnectTag];
    [[WYEngine shareInstance] getMatchDetailsWithMatchId:_matchWarInfo.mId uid:[WYEngine shareInstance].uid tag:tag];
    [[WYEngine shareInstance] addOnAppServiceBlock:^(NSInteger tag, NSDictionary *jsonRet, NSError *err) {
        NSString* errorMsg = [WYEngine getErrorMsgWithReponseDic:jsonRet];
        if (!jsonRet || errorMsg) {
            if (!errorMsg.length) {
                errorMsg = @"请求失败";
            }
            [WYProgressHUD AlertError:errorMsg At:weakSelf.view];
            return;
        }
        NSDictionary *object = [jsonRet dictionaryObjectForKey:@"object"];
        if ([object isKindOfClass:[NSDictionary class]]) {
            [weakSelf.matchWarInfo setMatchWarInfoByJsonDic:object];
        }
        
        weakSelf.commentCanLoadMore = [[[jsonRet dictionaryObjectForKey:@"object"]  dictionaryObjectForKey:@"comments"] boolValueForKey:@"isLast"];
        if (weakSelf.commentCanLoadMore) {
            weakSelf.commentTableView.showsInfiniteScrolling = NO;
        }else{
            weakSelf.commentTableView.showsInfiniteScrolling = YES;
            //可以加载更多
            weakSelf.commentNextCursor ++;
        }
        
        [weakSelf refreshHeadViewShow];
        [weakSelf.matchInfoTableView reloadData];
        
    }tag:tag];
}

-(void)getCacheCommentInfos{
    
}
-(void)refreshCommentInfos{
    _commentInfos = [[NSMutableArray alloc] init];
    for (int i = 0; i < 100; i++) {
        [_commentInfos addObject:@(0)];
    }
    [self.commentTableView reloadData];
}

#pragma mark - dataModule
-(NSDictionary *)tableDataModule{
    NSDictionary *moduleDict;
    
    NSMutableDictionary *tmpMutDict = [NSMutableDictionary dictionary];
    [tmpMutDict setObject:[self matchBasicInfosDict] forKey:[NSString stringWithFormat:@"s%d",(int)tmpMutDict.count]];
    moduleDict = tmpMutDict;
    return moduleDict;
}
-(NSDictionary *)matchBasicInfosDict{
    NSDictionary *minfoRows =  nil;
    
    NSMutableDictionary *tmpMutDict = [NSMutableDictionary dictionary];
    NSString *intro = _matchWarInfo.itemName;
    NSDictionary *dict00 = @{@"titleLabel": @"竞技项目",
                                 @"icon": @"match_publish_game_icon",
                                 @"intro": intro!=nil?intro:@"",
                                 };
    intro = _matchWarInfo.itemServer;
    NSDictionary *dict01 = @{@"titleLabel": @"服务器",
                             @"icon": @"matchWar_fuwu_icon",
                             @"intro": intro!=nil?intro:@"",
                             };
    intro = [WYUIUtils dateDiscriptionFromDate:_matchWarInfo.startTime];
    NSDictionary *dict02 = @{@"titleLabel": @"时间",
                             @"icon": @"match_detail_time_icon",
                             @"intro": intro!=nil?intro:@"",
                             };
    intro = nil;
    if (_matchWarInfo.way == 1) {
        intro = @"线上";
    }else if (_matchWarInfo.way ==2){
        intro = [NSString stringWithFormat:@"线下/%@",_matchWarInfo.netbarName];
    }
    NSDictionary *dict03 = @{@"titleLabel": @"地点",
                             @"icon": @"book_wangba",
                             @"intro": intro!=nil?intro:@"",
                             };
    intro = _matchWarInfo.remark;
    NSDictionary *dict04 = @{@"titleLabel": @"联系方式",
                             @"icon": @"match_publish_intro_icon",
                             @"intro": intro!=nil?intro:@"",
                             };
    intro = _matchWarInfo.spoils;
    NSDictionary *dict05 = @{@"titleLabel": @"介绍",
                             @"icon": @"match_publish_intro_icon",
                             @"intro": intro!=nil?intro:@"",
                             };
    [tmpMutDict setObject:dict00 forKey:[NSString stringWithFormat:@"r%d",(int)tmpMutDict.count]];
    [tmpMutDict setObject:dict01 forKey:[NSString stringWithFormat:@"r%d",(int)tmpMutDict.count]];
    [tmpMutDict setObject:dict02 forKey:[NSString stringWithFormat:@"r%d",(int)tmpMutDict.count]];
    [tmpMutDict setObject:dict03 forKey:[NSString stringWithFormat:@"r%d",(int)tmpMutDict.count]];
    [tmpMutDict setObject:dict04 forKey:[NSString stringWithFormat:@"r%d",(int)tmpMutDict.count]];
    [tmpMutDict setObject:dict05 forKey:[NSString stringWithFormat:@"r%d",(int)tmpMutDict.count]];
    
    minfoRows = tmpMutDict;
    return minfoRows;
}

-(NSInteger)newSections{
    
    return [[self tableDataModule] allKeys].count;
}
-(NSInteger)newSectionPolicy:(NSInteger)section{
    
    NSDictionary *rowContentDic = [[self tableDataModule] objectForKey:[NSString stringWithFormat:@"s%d", (int)section]];
    return [rowContentDic count];
}
-(CGFloat)heightWithRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *cellDicts = [[self tableDataModule] objectForKey:[NSString stringWithFormat:@"s%d", (int)indexPath.section]];
    NSDictionary *rowDicts = [cellDicts objectForKey:[NSString stringWithFormat:@"r%d", (int)indexPath.row]];
    NSString *intro = [rowDicts objectForKey:@"intro"];
    UIFont *font = SKIN_FONT_FROMNAME(14);
    CGSize textSize = [WYCommonUtils sizeWithText:intro font:font width:SCREEN_WIDTH-114];
    return textSize.height + 23;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.commentTableView) {
        return 1;
    }
    return [self newSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.commentTableView) {
        return self.commentInfos.count;
    }
    return [self newSectionPolicy:section];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.commentTableView) {
        return 54;
    }
    return [self heightWithRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.commentTableView) {
        static NSString *CellIdentifier = @"MatchCommentViewCell";
        MatchCommentViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            NSArray* cells = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:nil options:nil];
            cell = [cells objectAtIndex:0];
        }
        return cell;
    }
    static NSString *CellIdentifier = @"SettingViewCell";
    SettingViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray* cells = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:nil options:nil];
        cell = [cells objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if (indexPath.row == 0) {
        [cell setLineImageViewWithType:0];
    }else if (indexPath.row == [self newSectionPolicy:indexPath.section]-1){
        [cell setLineImageViewWithType:2];
    }else{
        [cell setLineImageViewWithType:1];
    }
    
    cell.rightLabel.hidden = NO;
    cell.rightLabel.font = SKIN_FONT_FROMNAME(14);
    cell.avatarImageView.hidden = NO;
    cell.indicatorImage.hidden = YES;
    
    CGFloat rowHeight = [self heightWithRowAtIndexPath:indexPath];
    CGRect frame = cell.avatarImageView.frame;
    frame.origin.y = (rowHeight-12)/2;
    frame.size.width = 12;
    frame.size.height = 12;
    cell.avatarImageView.frame = frame;
    
    frame = cell.titleLabel.frame;
    frame.origin.x = cell.avatarImageView.frame.origin.x + cell.avatarImageView.frame.size.width + 7;
    cell.titleLabel.frame = frame;
    
    //    cell.rightLabel.backgroundColor = [UIColor lightGrayColor];
    cell.rightLabel.autoresizingMask = UIViewAutoresizingNone;
    cell.rightLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    cell.rightLabel.numberOfLines = 0;
    frame = cell.rightLabel.frame;
    frame.origin.x = 102;
    frame.size.width = SCREEN_WIDTH - frame.origin.x - 12;
    cell.rightLabel.frame = frame;
    cell.rightLabel.textAlignment = NSTextAlignmentRight;
    
    NSDictionary *cellDicts = [[self tableDataModule] objectForKey:[NSString stringWithFormat:@"s%d", (int)indexPath.section]];
    NSDictionary *rowDicts = [cellDicts objectForKey:[NSString stringWithFormat:@"r%d", (int)indexPath.row]];
    
    cell.titleLabel.text = [rowDicts objectForKey:@"titleLabel"];
    cell.avatarImageView.image = [UIImage imageNamed:[rowDicts objectForKey:@"icon"]];
    
    if (!cell.rightLabel.hidden) {
        NSString *intro = [rowDicts objectForKey:@"intro"];
        cell.rightLabel.text = intro;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.commentTableView) {
        
    }else{
        if (indexPath.row == 3) {
            NetbarDetailViewController *netbarDetailVc = [[NetbarDetailViewController alloc] init];
            [self.navigationController pushViewController:netbarDetailVc animated:YES];
        }
    }
    
    NSIndexPath* selIndexPath = [tableView indexPathForSelectedRow];
    [tableView deselectRowAtIndexPath:selIndexPath animated:YES];
}

#pragma mark - scrollViewDelegat
static CGFloat beginOffsetY = 63*2;
static CGFloat BKImageHeight = 320;
static CGFloat beginImageH = 0;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGPoint offset = scrollView.contentOffset;
//    WYLog(@"offset = %f",offset.y);
    CGRect frame = CGRectMake(0, -63, SCREEN_WIDTH, BKImageHeight);
    CGFloat factor;
    
    //pull animation
    if (offset.y < 0) {
        factor = 0.5;
    } else {
        factor = 1;
    }
    
    float topOffset = -63;
    frame.origin.y = topOffset-offset.y*factor;
    if (frame.origin.y > 0) {
        frame.origin.y =  topOffset/factor - offset.y;
    }
    
    // zoom image
    if (offset.y <= -beginOffsetY) {
        factor = (ABS(offset.y+beginOffsetY)+BKImageHeight) * SCREEN_WIDTH/BKImageHeight;
        frame = CGRectMake(-(factor-SCREEN_WIDTH)/2, beginImageH, factor, BKImageHeight+ABS(offset.y+beginOffsetY));
    }
//     WYLog(@"frame = %@",NSStringFromCGRect(frame));
    _bkImageView.frame = frame;
    
    [self setTitleNavBarAlpha:scrollView point:offset];
}

- (void)setTitleNavBarAlpha:(UIScrollView *)scrollView point:(CGPoint)offset{
    CGFloat tmpHeight = 76;
    int type = 0;
    if (offset.y <= 0) {
        type = 0;
        [self.titleNavBar setAlpha:0.0];
    }else if (offset.y >= tmpHeight){
        type = 1;
        [self.titleNavBar setAlpha:0.6];
    }else{
        type = 0;
        CGFloat alpha = fabs((offset.y)/tmpHeight);
        if (alpha >= 0.6) {
            alpha = 0.6;
        }
        [self.titleNavBar setAlpha:alpha];
    }
    [self refreshTitleBarUI:type];
}

-(void)refreshTitleBarUI:(int)type{
    if (type == 0) {
        self.toobarTitleLabel.hidden = YES;
    }else if (type == 1){
        self.toobarTitleLabel.text = _matchWarInfo.title;
        self.toobarTitleLabel.hidden = NO;
    }
}
- (UIStatusBarStyle)preferredStatusBarStyle NS_AVAILABLE_IOS(7_0){
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden NS_AVAILABLE_IOS(7_0){
    return NO;
}

@end
