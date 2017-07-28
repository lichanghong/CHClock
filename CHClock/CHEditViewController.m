//
//  CHEditViewController.m
//  CHClock
//
//  Created by lichanghong on 7/26/17.
//  Copyright © 2017 lichanghong. All rights reserved.
//

#import "CHEditViewController.h"
#import <BAAlertController/BAAlertController.h>
#import <CHBaseUtil/CHBaseUtil.h>
#import "TimeModel+CoreDataModel.h"
#import <MagicalRecord/MagicalRecord.h>


@interface CHEditViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBarButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong)NSArray *dataSource;

@property (weak, nonatomic) IBOutlet UITextField *hourTextF;
@property (weak, nonatomic) IBOutlet UITextField *minuteTextF;
@property (weak, nonatomic) IBOutlet UITextField *alertTextF;


@end

static NSString *cellIdentifier = @"CellIdentifier";
@implementation CHEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshData];
    
    self.hourTextF.keyboardType   = UIKeyboardTypeNumberPad;
    self.minuteTextF.keyboardType = UIKeyboardTypeNumberPad;
    self.alertTextF.keyboardType  = UIKeyboardTypeNumberPad;

    // Do any additional setup after loading the view.
}

- (IBAction)handleAction:(id)sender {
    if (sender == _saveBarButton) {
        int32_t hour =  self.hourTextF.text.intValue;
        int32_t minute =  self.minuteTextF.text.intValue;
        int32_t alertT =  self.alertTextF.text.intValue;
        [[NSUserDefaults standardUserDefaults]setInteger:hour forKey:@"hour_key"];
        [[NSUserDefaults standardUserDefaults]setInteger:minute forKey:@"minite_key"];
        [[NSUserDefaults standardUserDefaults]setInteger:alertT forKey:@"alert_time_key"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.navigationController popViewControllerAnimated:YES];
        [[UIApplication sharedApplication].keyWindow makeToast:@"保存成功"];
    }
    else if(sender == _addBarButton)
    {
        [self alertController3];
    }
}


- (void)alertController3
{
    // AlertController 的 textField placeholder 数组，根据这个添加 textField
    NSArray *textFieldPlaceholderArray = @[@"在几分钟内", @"每隔几分钟提醒一次"];
    NSArray *buttonTitleColorArray = @[BAKit_Color_Green, BAKit_Color_Green] ;
    
    [UIAlertController ba_alert2ShowInViewController:self title:@"添加间隔提醒" message:nil  buttonTitleArray:@[@"取 消", @"确 定"] buttonTitleColorArray:buttonTitleColorArray buttonEnabledNoWithTitleArray:@[@"确 定"] textFieldPlaceholderArray:textFieldPlaceholderArray textFieldConfigurationActionBlock:^(UITextField * _Nullable textField, NSInteger index) {
        // 添加通知，监听 textField 输入的文字变化
        [BAKit_NotiCenter addObserver:self selector:@selector(handleAlertTextFieldDidChangeAction:) name:UITextFieldTextDidChangeNotification object:textField];
        
        textField.keyboardType = UIKeyboardTypeNumberPad;
        
    } block:^(UIAlertController * _Nonnull alertController, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            UITextField *loginTextField = alertController.textFields[0];
            UITextField *passwordTextField = alertController.textFields[1];
            
            int32_t within = 0;
            int32_t interval = 0;
            NSString *loginText = loginTextField.text;
            NSString *passText  = passwordTextField.text;
            if (loginText.length>0 && [loginText intValue]) {
                within = loginText.intValue;
            }
            if (passText.length>0 && passText.intValue) {
                interval = passText.intValue;
            }
            if (within>0 && interval>0) {
                [self.view makeToast:@"保存成功"];
                TimeModel *model = [TimeModel MR_createEntity];
                model.withinTime = within;
                model.intervalTime = interval;
                [[NSManagedObjectContext MR_defaultContext]MR_saveToPersistentStoreAndWait];
                [self refreshData];
            }
            else  [self.view makeToast:@"保存失败"];
        }
      
        [BAKit_NotiCenter removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
        
    }];
}

- (void)refreshData
{
    NSInteger hour = [[NSUserDefaults standardUserDefaults]integerForKey:@"hour_key"];
    NSInteger minute =  [[NSUserDefaults standardUserDefaults]integerForKey:@"minite_key"];
    NSInteger alert_time =  [[NSUserDefaults standardUserDefaults]integerForKey:@"alert_time_key"];
    
    self.hourTextF.text = [NSString stringWithFormat:@"%ld",hour];
    self.minuteTextF.text = [NSString stringWithFormat:@"%ld",minute];
    self.alertTextF.text = [NSString stringWithFormat:@"%ld",alert_time];

    NSArray *times = [TimeModel MR_findAll];
    self.dataSource = [times sortedArrayUsingComparator:^NSComparisonResult(TimeModel *obj1, TimeModel *obj2) {
        if (obj1.withinTime>obj2.withinTime) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    [self.tableView reloadData];
}

- (void)handleAlertTextFieldDidChangeAction:(NSNotification *)notification
{
    // 通知处理，判断文字输入的长度 大于 3 的时候，确定按钮可点击，否则，不可点击
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController)
    {
        UITextField *login = alertController.textFields[0];
        UIAlertAction *sureAction = alertController.actions[1];
        sureAction.enabled = login.text.length > 0;
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    TimeModel *model = self.dataSource[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%d分钟内每隔%d分钟提醒一次",model.withinTime,model.intervalTime];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *textFieldPlaceholderArray = @[@"在几分钟内", @"每隔几分钟提醒一次"];
    NSArray *buttonTitleColorArray = @[BAKit_Color_Green, BAKit_Color_Green] ;
    TimeModel *model = self.dataSource[indexPath.row];
    
    [UIAlertController ba_alert2ShowInViewController:self title:@"修改间隔" message:nil  buttonTitleArray:@[@"取 消", @"确 定"] buttonTitleColorArray:buttonTitleColorArray buttonEnabledNoWithTitleArray:nil textFieldPlaceholderArray:textFieldPlaceholderArray textFieldConfigurationActionBlock:^(UITextField * _Nullable textField, NSInteger index) {
        // 添加通知，监听 textField 输入的文字变化
        [BAKit_NotiCenter addObserver:self selector:@selector(handleAlertTextFieldDidChangeAction:) name:UITextFieldTextDidChangeNotification object:textField];
        if (index==0) {
            textField.text = [NSString stringWithFormat:@"%d",model.withinTime];
        }
        else if(index == 1)
        {
            textField.text = [NSString stringWithFormat:@"%d",model.intervalTime];
        }
        textField.keyboardType = UIKeyboardTypeNumberPad;
        
    } block:^(UIAlertController * _Nonnull alertController, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            UITextField *loginTextField = alertController.textFields[0];
            UITextField *passwordTextField = alertController.textFields[1];
            
            int32_t within = 0;
            int32_t interval = 0;
            NSString *loginText = loginTextField.text;
            NSString *passText  = passwordTextField.text;
            if (loginText.length>0 && [loginText intValue]) {
                within = loginText.intValue;
            }
            if (passText.length>0 && passText.intValue) {
                interval = passText.intValue;
            }
            if (within>0 && interval>0) {
                [self.view makeToast:@"修改成功"];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"withinTime==%d && intervalTime==%d",model.withinTime,model.intervalTime];
                NSArray *models = [TimeModel MR_findAllWithPredicate:predicate];
                TimeModel *model = [models firstObject];
                model.withinTime = within;
                model.intervalTime = interval;
                [[NSManagedObjectContext MR_defaultContext]MR_saveToPersistentStoreAndWait];
                [self refreshData];
            }
            else  [self.view makeToast:@"修改失败"];
        }

        [BAKit_NotiCenter removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
        
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return true;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *datas = [NSMutableArray arrayWithArray:self.dataSource];
        TimeModel *model = [datas objectAtIndex:indexPath.row];
        [datas removeObject:model];
        self.dataSource = datas;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"withinTime==%d && intervalTime==%d",model.withinTime,model.intervalTime];
        [TimeModel MR_deleteAllMatchingPredicate:predicate];
        [[NSManagedObjectContext MR_defaultContext]MR_saveToPersistentStoreAndWait];
        
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
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

@end
