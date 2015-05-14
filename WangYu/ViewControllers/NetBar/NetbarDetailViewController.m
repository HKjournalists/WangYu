//
//  NetbarDetailViewController.m
//  WangYu
//
//  Created by KID on 15/5/11.
//  Copyright (c) 2015年 KID. All rights reserved.
//

#import "NetbarDetailViewController.h"
#import "NetbarDetailCell.h"
#import "QuickBookViewController.h"
#import "QuickPayViewController.h"
#import "WYNetbarInfo.h"
#import "WYEngine.h"
#import "WYProgressHUD.h"
#import "UIImageView+WebCache.h"

@interface NetbarDetailViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UIView *maskView;

@property (strong, nonatomic) IBOutlet UIImageView *netbarImage;
@property (strong, nonatomic) IBOutlet UITableView *teamTable;
@property (strong, nonatomic) IBOutlet UIView *sectionView;
@property (strong, nonatomic) IBOutlet UIButton *bookButton;
@property (strong, nonatomic) IBOutlet UIButton *payButton;

@property (strong, nonatomic) IBOutlet UILabel *netbarLabel;
@property (strong, nonatomic) IBOutlet UILabel *colorLabel;
@property (strong, nonatomic) IBOutlet UILabel *sectionLabel;
@property (strong, nonatomic) IBOutlet UILabel *priceLabel1;
@property (strong, nonatomic) IBOutlet UILabel *priceLabel2;
@property (strong, nonatomic) IBOutlet UILabel *addressLabel;
@property (strong, nonatomic) IBOutlet UILabel *phoneLabel;
@property (strong, nonatomic) IBOutlet UILabel *descLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;


- (IBAction)bookAction:(id)sender;
- (IBAction)payAction:(id)sender;

@end

@implementation NetbarDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self refreshUI];
    [self refreshHeaderView];
    [self getNetbarDataSource];
}

- (void)refreshUI {
    self.teamTable.tableHeaderView = self.headerView;
    
    self.netbarImage.layer.cornerRadius = 4.0;
    self.netbarImage.layer.masksToBounds = YES;
    
    self.netbarLabel.textColor = SKIN_TEXT_COLOR1;
    self.netbarLabel.font = SKIN_FONT(15);
    
    self.priceLabel1.textColor = SKIN_TEXT_COLOR2;
    self.priceLabel1.font = SKIN_FONT(12);
    
    self.addressLabel.textColor = SKIN_TEXT_COLOR1;
    self.addressLabel.font = SKIN_FONT(12);
    self.phoneLabel.textColor = SKIN_TEXT_COLOR1;
    self.phoneLabel.font = SKIN_FONT(12);
    self.descLabel.textColor =SKIN_TEXT_COLOR1;
    self.descLabel.font = SKIN_FONT(12);
    self.timeLabel.textColor = SKIN_TEXT_COLOR2;
    self.timeLabel.font = SKIN_FONT(12);
    
    self.colorLabel.backgroundColor = UIColorToRGB(0xfac402);
    self.colorLabel.layer.cornerRadius = 1.0;
    self.colorLabel.layer.masksToBounds = YES;
    
    self.sectionLabel.textColor = SKIN_TEXT_COLOR1;
    self.sectionLabel.font = SKIN_FONT(15);
    
    [self.bookButton setTitleColor:SKIN_TEXT_COLOR1 forState:UIControlStateNormal];
    self.bookButton.titleLabel.font = SKIN_FONT(14);
    self.bookButton.backgroundColor = SKIN_COLOR;
    self.bookButton.layer.cornerRadius = 4.0;
    self.bookButton.layer.masksToBounds = YES;
    
    [self.payButton setTitleColor:SKIN_TEXT_COLOR1 forState:UIControlStateNormal];
    self.payButton.titleLabel.font = SKIN_FONT(14);
    self.payButton.backgroundColor = SKIN_COLOR;
    self.payButton.layer.cornerRadius = 4.0;
    self.payButton.layer.masksToBounds = YES;

}

- (void)refreshHeaderView {
    if (![self.netbarInfo.smallImageUrl isEqual:[NSNull null]]) {
        [self.netbarImage sd_setImageWithURL:self.netbarInfo.smallImageUrl placeholderImage:[UIImage imageNamed:@"netbar_load_icon"]];
    }else{
        [self.netbarImage sd_setImageWithURL:nil];
        [self.netbarImage setImage:[UIImage imageNamed:@"netbar_load_icon"]];
    }
    self.phoneLabel.text = self.netbarInfo.telephone;
    self.addressLabel.text = self.netbarInfo.address;
    self.netbarLabel.text = self.netbarInfo.netbarName;
    
    self.priceLabel2.text = [NSString stringWithFormat:@"￥%d",self.netbarInfo.price];
    
    CGFloat priceLabelWidth = [WYCommonUtils widthWithText:self.priceLabel2.text font:self.priceLabel2.font lineBreakMode:self.priceLabel2.lineBreakMode];
    CGRect frame = self.priceLabel2.frame;
    frame.size.width = priceLabelWidth;
    self.priceLabel2.frame = frame;
    
    frame = self.timeLabel.frame;
    frame.origin.x = self.priceLabel2.frame.size.width + self.priceLabel2.frame.origin.x;
    self.timeLabel.frame = frame;
    self.timeLabel.text = [NSString stringWithFormat:@"/小时"];
}

- (void)getNetbarDataSource {
    WS(weakSelf);
    int tag = [[WYEngine shareInstance] getConnectTag];
    [[WYEngine shareInstance] getNetbarDetailWithUid:[WYEngine shareInstance].uid netbarId:self.netbarInfo.nid tag:tag];
    [[WYEngine shareInstance] addOnAppServiceBlock:^(NSInteger tag, NSDictionary *jsonRet, NSError *err) {
        [WYProgressHUD AlertLoadDone];
        NSString* errorMsg = [WYEngine getErrorMsgWithReponseDic:jsonRet];
        if (!jsonRet || errorMsg) {
            if (!errorMsg.length) {
                errorMsg = @"请求失败";
            }
            [WYProgressHUD AlertError:errorMsg At:weakSelf.view];
            return;
        }
        NSDictionary *dic = [jsonRet objectForKey:@"object"];
        [weakSelf.netbarInfo setNetbarInfoByJsonDic:dic];
        [weakSelf refreshHeaderView];
    }tag:tag];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initNormalTitleNavBarSubviews{
    [self setTitle:@"网吧详情"];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 39;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 64;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 39)];
    CGRect frame = self.sectionView.frame;
    frame.size.width = SCREEN_WIDTH;
    self.sectionView.frame = frame;
    [view addSubview:self.sectionView];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"NetbarDetailCell";
    NetbarDetailCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray* cells = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:nil options:nil];
        cell = [cells objectAtIndex:0];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath* selIndexPath = [tableView indexPathForSelectedRow];
    [tableView deselectRowAtIndexPath:selIndexPath animated:YES];
}

- (IBAction)bookAction:(id)sender {
    QuickBookViewController *qbVc = [[QuickBookViewController alloc] init];
    [self.navigationController pushViewController:qbVc animated:YES];
}

- (IBAction)payAction:(id)sender {
    QuickPayViewController *qpVc = [[QuickPayViewController alloc] init];
    [self.navigationController pushViewController:qpVc animated:YES];
}

-(void)dealloc{
    WYLog(@"NetbarDetailViewController dealloc!!!");
    _teamTable.delegate = nil;
    _teamTable.dataSource = nil;
}

@end
