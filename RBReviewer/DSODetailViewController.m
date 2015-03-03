//
//  DSODetailViewController.m
//  RBReviewer
//
//  Created by Aaron Schachter on 1/22/15.
//  Copyright (c) 2015 DoSomething.org. All rights reserved.
//

#import "DSODetailViewController.h"
#import "DSOCaptionTableViewCell.h"
#import "DSOQuantityTableViewCell.h"
#import "DSOTitleTableViewCell.h"
#import "DSODynamicTextTableViewCell.h"
#import "DSOImageTableViewCell.h"
#import "DSOFlagViewController.h"
#import "DSODoSomethingAPIClient.h"
#import "DSOInboxZeroView.h"
#import <TSMessage.h>

@interface DSODetailViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *approveButton;
@property (weak, nonatomic) IBOutlet UIButton *excludeButton;
@property (weak, nonatomic) IBOutlet UIButton *flagButton;
@property (weak, nonatomic) IBOutlet UIButton *promoteButton;
@property (strong, nonatomic) NSMutableDictionary *reportbackFile;
@property (weak, nonatomic) IBOutlet DSOInboxZeroView *inboxZeroView;
- (IBAction)excludeTapped:(id)sender;
- (IBAction)approveTapped:(id)sender;
- (IBAction)promoteTapped:(id)sender;

@end

@implementation DSODetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.inboxZeroView.hidden = YES;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.hidden = YES;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44;

    self.screenName = self.taxonomyTerm[@"name"];
    [self updateTitle];
    [self updateTableView];
    [TSMessage setDelegate:self.navigationController];
}

- (void) updateTitle {
    self.title = [NSString stringWithFormat:@"%@ (%li)", self.taxonomyTerm[@"name"], self.inboxCount];
}

- (void)updateTableView {
    NSString *tidString = (NSString *)self.taxonomyTerm[@"tid"];
    NSInteger tid = [tidString integerValue];

    DSODoSomethingAPIClient *client = [DSODoSomethingAPIClient sharedClient];
    [client getSingleInboxReportbackWithCompletionHandler:^(NSMutableArray *response){
        if ([response count] > 0) {
            self.reportbackFile = (NSMutableDictionary *)response[0];
            [self.tableView reloadData];
            self.inboxZeroView.hidden = YES;
            self.tableView.hidden = NO;
        }
        else {
            self.tableView.hidden = YES;
            self.inboxZeroView.hidden = NO;
        }
    } andTid:tid];

    // Set TableFooterView to avoid repeating seperator lines.
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    switch (indexPath.row) {
        case 0: {
            DSOTitleTableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:@"titleCell" forIndexPath:indexPath];
            cell.titleLabel.text = self.reportbackFile[@"title"];
            cell.titleLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }

        case 2: {
            DSOImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell" forIndexPath:indexPath];
            NSData* imageData = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:self.reportbackFile[@"src"]]];
            UIImage* image = [[UIImage alloc] initWithData:imageData];
            cell.fullSizeImageView.image = image;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        case 3: {
            DSOCaptionTableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:@"captionCell" forIndexPath:indexPath];
            
            if ([self.reportbackFile[@"caption"] isEqualToString:@""]) {
                cell.captionLabel.text = @"(No caption)";
            } else {
                cell.captionLabel.text = self.reportbackFile[@"caption"];
            }
            
            cell.captionLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        case 1: {
            DSOQuantityTableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:@"quantityCell" forIndexPath:indexPath];
            cell.quantityLabel.text = nil;
            if (self.reportbackFile[@"quantity"] != nil) {
                cell.quantityLabel.text = [NSString stringWithFormat:@"%@ %@", self.reportbackFile[@"quantity"], self.reportbackFile[@"quantity_label"]];
            }
            cell.quantityLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }

        case 4: {
            DSODynamicTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"whyParticipatedCell" forIndexPath:indexPath];
            cell.dynamicTextLabel.text = self.reportbackFile[@"why_participated"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
    }
    return nil;
}

- (IBAction)unwindToDetail:(UIStoryboardSegue *)segue {
    DSOFlagViewController *source = [segue sourceViewController];
    NSDictionary *values = @{
                             @"fid":self.reportbackFile[@"fid"],
                             @"status":@"flagged",
                             @"flagged_reason":source.flaggedReason,
                             @"delete":[NSNumber numberWithBool:source.deleteImage],
                             @"source":@"ios"
                             };
    DSODoSomethingAPIClient *client = [DSODoSomethingAPIClient sharedClient];
    [client postReportbackReviewWithCompletionHandler:^(NSArray *response){
        [self displayStatusMessage:@"flagged"];
        [self updateTableView];
        int newValue = self.inboxCount;
        self.inboxCount = newValue - 1;
        [self updateTitle];
    } :values];
}

-(void)review:(id)sender
{
    UIButton *senderButton = (UIButton *)sender;
    NSString *status = @"approved";
    if (senderButton.tag == 0) {
        status = @"excluded";
    }
    else if (senderButton.tag == 20) {
        status = @"promoted";
    }
    [self postReview:status];
}

- (void) postReview:(NSString *)status
{
    NSDictionary *values = @{
                             @"fid":self.reportbackFile[@"fid"],
                             @"status":status,
                             @"source":@"ios"
                             };

    DSODoSomethingAPIClient *client = [DSODoSomethingAPIClient sharedClient];
    [client postReportbackReviewWithCompletionHandler:^(NSArray *response){
        [self displayStatusMessage:status];
        int newValue = self.inboxCount;
        self.inboxCount = newValue - 1;
        [self updateTitle];
        [self updateTableView];
    } :values];
}

- (void) displayStatusMessage:(NSString *)status {
    NSString *title = [NSString stringWithFormat:@"Reportback %@ %@.", self.reportbackFile[@"fid"], status];
    NSString *filename = [NSString stringWithFormat:@"%@.png", status];

    NSTimeInterval duration = 3;
    [TSMessage showNotificationInViewController:[TSMessage defaultViewController]
                                          title:title
                                       subtitle:nil
                                          image:[UIImage imageNamed:filename]
                                           type:TSMessageNotificationTypeSuccess
                                       duration:duration
                                       callback:nil
                                    buttonTitle:nil
                                 buttonCallback:nil
                                     atPosition:TSMessageNotificationPositionTop
                           canBeDismissedByUser:YES];
    
    [self.tableView setContentOffset:CGPointZero animated:YES];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)excludeTapped:(id)sender {
    [self postReview:@"excluded"];
}

- (IBAction)approveTapped:(id)sender {
    [self postReview:@"approved"];
}

- (IBAction)promoteTapped:(id)sender {
    [self postReview:@"promoted"];
}
@end
