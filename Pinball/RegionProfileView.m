//
//  RegionProfileView.m
//  PinballMap
//
//  Created by Frank Michael on 10/5/14.
//  Copyright (c) 2014 Frank Michael Sanchez. All rights reserved.
//

#import "RegionProfileView.h"
#import "UIAlertView+Application.h"
#import "RegionLink.h"
#import "RegionsView.h"
#import "AboutView.h"
#import "HighRoller.h"
#import "HighRollerProfileView.h"

@interface RegionProfileView ()

@property (nonatomic) Region *currentRegion;
@property (nonatomic) NSMutableArray *regionLinks;
@property (nonatomic) NSMutableArray *highRollers;
@property (nonatomic) NSString *regionMOTD;

- (IBAction)showAbout:(id)sender;

@end

@implementation RegionProfileView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *aboutButton = [[UIBarButtonItem alloc] initWithTitle:@"About" style:UIBarButtonItemStylePlain target:self action:@selector(showAbout:)];
    self.navigationItem.leftBarButtonItem = aboutButton;
    UIBarButtonItem *changeRegionButton = [[UIBarButtonItem alloc] initWithTitle:@"Change" style:UIBarButtonItemStylePlain target:self action:@selector(changeRegion:)];
    self.navigationItem.rightBarButtonItem = changeRegionButton;
    
    self.currentRegion = [[PinballMapManager sharedInstance] currentRegion];
    self.navigationItem.title = self.currentRegion.fullName;
    
    self.regionLinks = [NSMutableArray new];
    self.highRollers = [NSMutableArray new];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshRegionData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRegion) name:@"RegionUpdate" object:nil];
    
    [self refreshRegionData];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)refreshRegionData{
    [[PinballMapManager sharedInstance] refreshBasicRegionData:^(NSDictionary *status) {
        if (status[@"errors"]){
            NSString *errors;
            if ([status[@"errors"] isKindOfClass:[NSArray class]]){
                errors = [status[@"errors"] componentsJoinedByString:@","];
            }else{
                errors = status[@"errors"];
            }
            [UIAlertView simpleApplicationAlertWithMessage:errors cancelButton:@"Ok"];
        }else{
            self.regionMOTD = status[@"region"][@"motd"];
            NSDictionary *links = status[@"region"][@"filtered_region_links"];
            NSDictionary *highRollers = status[@"region"][@"n_high_rollers"];
            [self.regionLinks removeAllObjects];
            
            [links enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *links, BOOL *stop) {
                NSMutableArray *linkCategories = [NSMutableArray new];
                for (NSDictionary *link in links) {
                    RegionLink *newLink = [[RegionLink alloc] initWithData:link];
                    [linkCategories addObject:newLink];
                }
                [self.regionLinks addObject:linkCategories];
            }];
            
            [self.highRollers removeAllObjects];
            [highRollers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *scores, BOOL *stop) {
                if (key.length > 0){
                    HighRoller *highRoller = [[HighRoller alloc] initWithInitials:key andScores:scores];
                    [self.highRollers addObject:highRoller];
                }
            }];
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
        });
    }];
}
- (void)updateRegion{
    self.navigationItem.title = [NSString stringWithFormat:@"%@",[[[PinballMapManager sharedInstance] currentRegion] fullName]];
    [self refreshRegionData];
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
}
#pragma mark - Class Actions
- (IBAction)showAbout:(id)sender{
    AboutView *about = [self.storyboard instantiateViewControllerWithIdentifier:@"AboutView"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:about];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}
- (IBAction)changeRegion:(id)sender{
    RegionsView *regionsView = [self.storyboard instantiateViewControllerWithIdentifier:@"RegionsView"];
    regionsView.isSelecting = true;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:regionsView];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}
#pragma mark - TableView Datasource/Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    // 0->MOTD
    // 1->Local Stuff
    // 2->High Scores
    return self.regionLinks.count+2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0){
        return 1;
    }else if (section > 0 && section <= self.regionLinks.count){
        return [self.regionLinks[section-1] count];
    }else{
        return self.highRollers.count;
    }
    return 0;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0){
        return @"Message of the Day";
    }else if (section > 0 && section <= self.regionLinks.count){
        RegionLink *link = [self.regionLinks[section-1] firstObject];
        return link.category;
    }else{
        return @"High Rollers";
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        CGRect titleSize = [self.regionMOTD boundingRectWithSize:CGSizeMake(290, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18]} context:nil];
        titleSize.size.height = titleSize.size.height+10;   // Take into account the 10 points of padding within a cell.
        if (titleSize.size.height < 44){
            return 44;
        }else{
            return titleSize.size.height;
        }
    }else if (indexPath.section > 0 && indexPath.section <= self.regionLinks.count){
        RegionLink *link = [self.regionLinks[indexPath.section-1] objectAtIndex:indexPath.row];

        NSString *cellDetail = link.linkDescription;
        NSString *cellTitle = link.name;
        
        CGRect titleSize = [cellTitle boundingRectWithSize:CGSizeMake(290, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18]} context:nil];
        CGRect detailSize = [cellDetail boundingRectWithSize:CGSizeMake(290, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]} context:nil];
        
        titleSize.size.height = titleSize.size.height+detailSize.size.height+10;   // Take into account the 10 points of padding within a cell.
        if (titleSize.size.height < 44){
            return 44;
        }else{
            return titleSize.size.height;
        }
    }
    
    return 44;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier;
    
    if (indexPath.section == 0){
        cellIdentifier = @"BasicCell";
    }else{
        cellIdentifier = @"DetailCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (indexPath.section == 0){
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.text = self.regionMOTD;
    }else if (indexPath.section > 0 && indexPath.section <= self.regionLinks.count){
        RegionLink *link = [self.regionLinks[indexPath.section-1] objectAtIndex:indexPath.row];
        cell.detailTextLabel.numberOfLines = 0;
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.text = link.name;
        cell.detailTextLabel.text = link.linkDescription;
    }else{
        HighRoller *highRoller = self.highRollers[indexPath.row];
        cell.textLabel.text = highRoller.initials;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu Scores",(unsigned long)highRoller.highScores.count];
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section > self.regionLinks.count){
        HighRoller *highRoller = self.highRollers[indexPath.row];
        
        HighRollerProfileView *profile = (HighRollerProfileView *)[[self.storyboard instantiateViewControllerWithIdentifier:@"HighRollerProfileView"] navigationRootViewController];
        profile.highRoller = highRoller;
        
        [self.navigationController presentViewController:[profile parentViewController] animated:YES completion:nil];
    }
    
}

@end