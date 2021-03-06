//
//  ContactView.m
//  PinballMap
//
//  Created by Frank Michael on 8/31/14.
//  Copyright (c) 2014 Frank Michael Sanchez. All rights reserved.
//

#import "ContactView.h"
#import "TextEditorView.h"
#import "PinballMapManager.h"
#import "UIAlertView+Application.h"

@interface ContactView () <TextEditorDelegate>
@property (nonatomic) NSString *messageContent;
@property (weak) IBOutlet UILabel *messageLabel;
@property (weak) IBOutlet UIView *messageCellView;
@property (weak) IBOutlet UITableViewCell *regionNameCell;
@property (weak) IBOutlet UITextField *regionNameField;

- (IBAction)cancelMessage:(id)sender;
- (IBAction)sendMessage:(id)sender;

@end

@implementation ContactView

- (id)initWithStyle:(UITableViewStyle)style{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewDidLoad{
    [super viewDidLoad];
    [self.regionNameCell setHidden:YES];
    switch (self.contactType) {
        case ContactTypeEvent:
            self.navigationItem.title = @"Suggest Event";
            break;
        case ContactTypeRegionContact:
            self.navigationItem.title = @"Contact Admin";
            break;
        case ContactTypeRegionSuggest:
            self.navigationItem.title = @"Region Suggest";
            [self.regionNameCell setHidden:NO];
            break;
        case ContactTypeAppFeedback:
            self.navigationItem.title = @"App Feedback";
            break;
        default:
            break;
    }
    self.messageContent = self.messageLabel.text;
}
- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Class Actions
- (IBAction)cancelMessage:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)sendMessage:(id)sender{
    NSDictionary *messageData;
    Region *currentRegion = [[PinballMapManager sharedInstance] currentRegion];
    
    if (self.contactType == ContactTypeRegionSuggest){
        if (self.regionNameField.text.length == 0){
            [UIAlertView simpleApplicationAlertWithMessage:@"You must enter a region name" cancelButton:@"Ok"];
            return;
        }
        messageData = @{
                        @"region_name": self.regionNameField.text,
                        @"comments": self.messageContent
                        };
    }else{
        if (self.messageContent.length > 0 && ![self.messageContent isEqualToString:@"Message"]){
            if (self.contactType == ContactTypeAppFeedback){
                User *user = [[PinballMapManager sharedInstance] currentUser];
                
                messageData = @{
                                @"os": @"iOS",
                                @"os_version": [[UIDevice currentDevice] systemVersion],
                                @"device_type": [[UIDevice currentDevice] model],
                                @"app_version": [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                @"message": self.messageContent,
                                @"region_id": currentRegion.regionId,
                                @"name": user.username,
                                @"email": user.email
                                };
            }else{
                messageData = @{
                                @"region_id": currentRegion.regionId,
                                @"message": self.messageContent,
                                };
            }
        }else{
            [UIAlertView simpleApplicationAlertWithMessage:@"You must enter a message" cancelButton:@"Ok"];
            return;
        }
    }

    [[PinballMapManager sharedInstance] sendMessage:messageData withType:self.contactType andCompletion:^(NSDictionary *status) {
            if (status[@"errors"]){
                NSString *errors;
                if ([status[@"errors"] isKindOfClass:[NSArray class]]){
                    errors = [status[@"errors"] componentsJoinedByString:@","];
                }else{
                    errors = status[@"errors"];
                }
                [UIAlertView simpleApplicationAlertWithMessage:errors cancelButton:@"Ok"];
            }else{
                [UIAlertView simpleApplicationAlertWithMessage:status[@"msg"] cancelButton:@"Ok"];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
    }];
}
#pragma mark - UITableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row != 2){
        return 44;
    }else{
        CGRect stringSize = [self.messageLabel.text boundingRectWithSize:CGSizeMake(self.messageLabel.frame.size.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]} context:nil];

        if (stringSize.size.height+2 < 44){
            return 44;
        }
        return stringSize.size.height+2;
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0){
        TextEditorView *editorView = [[TextEditorView alloc] initWithTitle:@"Message" andDelegate:self];
        editorView.textContent = self.messageContent;
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editorView];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    }
}
#pragma mark - Text Editor Delegate
- (void)editorDidComplete:(NSString *)text{
    self.messageContent = text;
    self.messageLabel.text = text;
    
    [self.tableView reloadData];
}
- (void)editorDidCancel{}

@end
