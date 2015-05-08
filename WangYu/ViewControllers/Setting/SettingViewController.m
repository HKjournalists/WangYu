//
//  SettingViewController.m
//  WangYu
//
//  Created by KID on 15/5/8.
//  Copyright (c) 2015年 KID. All rights reserved.
//

#import "SettingViewController.h"
#import "SettingViewCell.h"
#import "WYAlertView.h"
#import "WYEngine.h"
#import "WYCommonUtils.h"
#import "WelcomeViewController.h"
#import "AboutViewController.h"
#import "AppDelegate.h"
#import "UIImageView+WebCache.h"
#import "WYProgressHUD.h"
#import "WYActionSheet.h"
#import "WYSettingConfig.h"

@interface SettingViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *setTableView;

@property (assign, nonatomic) unsigned long long cacheSize;

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.view setBackgroundColor:UIColorRGB(234, 234, 234)];
    [self getCacheSize];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)initNormalTitleNavBarSubviews{
    [self setTitle:@"设置"];
}

- (void)getCacheSize{
    //获取缓存文件大小
    self.cacheSize = UINT64_MAX;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        unsigned long long size = [WYCommonUtils getDirectorySizeForPath:[[WYEngine shareInstance] wyInstanceDocPath]];
        size += [[SDImageCache sharedImageCache] getSize];
        size += [[WYEngine shareInstance] getUrlCacheSize];
        __weak SettingViewController* weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.cacheSize = size;
            [weakSelf.setTableView reloadData];
        });
    });
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 3;
    }
#ifdef DEBUG
    return 2;
#endif
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 20)];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SettingViewCell";
    SettingViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray* cells = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:nil options:nil];
        cell = [cells objectAtIndex:0];
    }
    
    switch (indexPath.section) {
        case 0:{
            if (indexPath.row == 0) {
                cell.titleLabel.text = @"清理缓存";
                if (self.cacheSize != UINT64_MAX) {
                    NSString* cacheSizeStr = @"";
                    if (self.cacheSize > 1024*1024*1024) {
                        cacheSizeStr = [NSString stringWithFormat:@"%.2f GB", self.cacheSize*1.0/(1024*1024*1024)];
                    } else {
                        cacheSizeStr = [NSString stringWithFormat:@"%.2f MB", self.cacheSize*1.0/(1024*1024)];
                    }
                    cell.rightLabel.text = cacheSizeStr;
                    cell.rightLabel.hidden = NO;
                }
                break;
            }
            //            }else if (indexPath.row == 1){
            //                cell.titleLabel.text = @"检查更新";
            //                break;
            //            }
            else if (indexPath.row == 1){
                cell.titleLabel.text = @"给我评分";
                break;
            }
            else if (indexPath.row == 2){
                cell.titleLabel.text = @"关于我们";
                break;
            }
        }
        case 1:{
            if (indexPath.row == 0) {
                if (![[WYEngine shareInstance] hasAccoutLoggedin]) {
                    cell.titleLabel.text = @"注册或登录";
                }else{
                    cell.titleLabel.text = @"退出当前帐号";
                }
                cell.indicatorImage.hidden = YES;
                break;
            }else if (indexPath.row == 1){
                if ([WYEngine shareInstance].serverPlatform == OnlinePlatform) {
                    cell.titleLabel.text = @"测试环境";
                }else{
                    cell.titleLabel.text = @"线上环境";
                }
                cell.indicatorImage.hidden = YES;
                break;
            }
        }
        default:
            break;
    }
    
    if (indexPath.row == 0) {
        // cell.topline.hidden = NO;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:{
            if (indexPath.row == 0) {
                [self showClearCacheAction];
                break;
            }
            //            else if (indexPath.row == 1){
            //                [self checkVersion];
            //                break;
            //            }
            else if (indexPath.row == 1){
                [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@""]];//itms-apps://itunes.apple.com/app/id967105015
                break;
            }else if (indexPath.row == 2){
                AboutViewController *aVc = [[AboutViewController alloc] init];
                [self.navigationController pushViewController:aVc animated:YES];
                break;
            }
        }
        case 1:{
            if (indexPath.row == 0) {
                __weak SettingViewController *weakSelf = self;
                if (![[WYEngine shareInstance] hasAccoutLoggedin]) {
                    [self signOutAndLogin];
                }else{
                    WYActionSheet *sheet = [[WYActionSheet alloc] initWithTitle:nil actionBlock:^(NSInteger buttonIndex) {
                        if (buttonIndex == 1) {
                            return;
                        }
                        if (buttonIndex == 0) {
                            [weakSelf signOutAndLogin];
                        }
                    }];
                    [sheet addButtonWithTitle:@"退出登录"];
                    sheet.destructiveButtonIndex = sheet.numberOfButtons - 1;
                    
                    [sheet addButtonWithTitle:@"取消"];
                    sheet.cancelButtonIndex = sheet.numberOfButtons -1;
                    [sheet showInView:self.view];
                }
                break;
            }else if (indexPath.row == 1){
                [self onLogoutWithError:nil];
                break;
            }
        }
        default:
            break;
    }
    
    NSIndexPath* selIndexPath = [tableView indexPathForSelectedRow];
    [tableView deselectRowAtIndexPath:selIndexPath animated:YES];
}

- (void)signOutAndLogin{
    AppDelegate * appDelgate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    WYLog(@"signOut for user logout from SettingViewController");
    [appDelgate signOut];
    [[WYEngine shareInstance] visitorLogin];
}

- (void)onLogoutWithError:(NSError *)error {
    if ([WYEngine shareInstance].serverPlatform == TestPlatform) {
        [WYEngine shareInstance].serverPlatform = OnlinePlatform;
    } else {
        [WYEngine shareInstance].serverPlatform = TestPlatform;
    }
    AppDelegate * appDelgate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSLog(@"signOut for user logout");
    [appDelgate signOut];
}

- (void)checkVersion{
//    int tag = [[WYEngine shareInstance] getConnectTag];
//    //去服务器取版本信息
//    [[WYEngine shareInstance] getAppNewVersionWithTag:tag];
//    [[WYEngine shareInstance] addOnAppServiceBlock:^(NSInteger tag, NSDictionary *jsonRet, NSError *err) {
//        if (!jsonRet || err){
//            return ;
//        }
//        
//        NSString *localVserion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
//        NSString* version = nil;
//        
//        version = [jsonRet stringObjectForKey:@"object"];
//        
//        //        NSString* checkedVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"checkedVersion"];
//        //        if ([checkedVersion isEqualToString:version]) {
//        //            return;
//        //        }
//        //        localVserion
//        //        [[NSUserDefaults standardUserDefaults] setObject:version forKey:@"checkedVersion"];
//        if ([XECommonUtils isVersion:version greaterThanVersion:localVserion]) {
//            XEAlertView *alert = [[XEAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@版本已上线", version] message:@"宝爸宝妈快去更新吧" cancelButtonTitle:@"取消" cancelBlock:nil okButtonTitle:@"立刻更新" okBlock:^{
//                NSURL *url = [[ NSURL alloc ] initWithString: @"http://itunes.apple.com/app/id967105015"] ;
//                [[UIApplication sharedApplication] openURL:url];
//            }];
//            [alert show];
//            return;
//        }else{
//            [XEProgressHUD AlertSuccess:@"当前版本已经是最新版本"];
//        }
//    } tag:tag];
    
}

- (void)showClearCacheAction
{
    __weak SettingViewController* weakSelf = self;
    WYAlertView *alertView = [[WYAlertView alloc] initWithTitle:@"确认清除" message:@"是否清除本地所有图片和内容缓存" cancelButtonTitle:@"取消" cancelBlock:^{
    } okButtonTitle:@"清除" okBlock:^{
        [weakSelf clearCacheAction];
    }];
    [alertView show];
}

- (void)clearCacheAction{
    [[SDImageCache sharedImageCache] clearDisk];
    [[SDImageCache sharedImageCache] clearMemory];
    
    [[WYEngine shareInstance] clearAllCache];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSFileManager defaultManager] removeItemAtPath:[[WYEngine shareInstance] wyInstanceDocPath] error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:[[WYEngine shareInstance] wyInstanceDocPath] withIntermediateDirectories:YES attributes:nil error:nil];
    });
    self.cacheSize = 0;
    [self.setTableView reloadData];
    [WYProgressHUD AlertSuccess:@"缓存已清空"];
}

@end