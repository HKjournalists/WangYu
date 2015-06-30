//
//  MatchMemberViewController.m
//  WangYu
//
//  Created by XuLei on 15/6/23.
//  Copyright (c) 2015年 KID. All rights reserved.
//

#import "MatchMemberViewController.h"
#import "MatchMemberCell.h"
#import "InviteMemberViewController.h"

@interface MatchMemberViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray *userInfos;
@property (strong, nonatomic) IBOutlet UITableView *memberTableView;

@end

@implementation MatchMemberViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initNormalTitleNavBarSubviews {
    [self setTitle:@"我的队友"];
     [self setRightButtonWithImageName:@"match_invite_icon" selector:@selector(inviteAction)];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MatchMemberCell";
    MatchMemberCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray* cells = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:nil options:nil];
        cell = [cells objectAtIndex:0];
    }
//    cell.rightImageView.hidden = YES;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath* selIndexPath = [tableView indexPathForSelectedRow];
    [tableView deselectRowAtIndexPath:selIndexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        [_userInfos removeObjectAtIndex:indexPath.row];
//        [self.memberTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)inviteAction {
    InviteMemberViewController *imVc = [[InviteMemberViewController alloc] init];
    [self.navigationController pushViewController:imVc animated:YES];
}

@end