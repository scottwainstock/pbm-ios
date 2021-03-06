#import "ProfileView.h"
#import "LoginViewController.h"
#import "NSDate+DateFormatting.h"
#import "LocationCell.h"
#import "LocationProfileView.h"
#import "LocationProfileView-iPad.h"
#import "AppDelegate.h"
#import "UIDevice+Model.h"

@interface ProfileView ()

@end

@implementation ProfileView

@synthesize usernameLabel, highScoresTableView, editedLocationsTableView, locationsEditedInLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Profile";

    [self reloadUser];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadLabelsAndTables) name:@"LoggedIn" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUser) name:@"addedMachine" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUser) name:@"removedMachine" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUser) name:@"updatedMachine" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUser) name:@"updatedLocation" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUser) name:@"updatedConfirmed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUser) name:@"addedScore" object:nil];

    [self.editedLocationsTableView registerNib:[UINib nibWithNibName:@"LocationCell" bundle:nil] forCellReuseIdentifier:@"LocationCell"];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
 
    if ([[PinballMapManager sharedInstance] isLoggedInAsGuest]) {
        [self.view setHidden:YES];
        
        [self sendToRootAndLogin];
    } else {
        [self reloadLabelsAndTables];
    }
}

- (void)reloadUser {
    [[PinballMapManager sharedInstance] loadUserData:[[PinballMapManager sharedInstance] currentUser]];
}

- (void)reloadLabelsAndTables {
    NSLog(@"RELOADING LABELS AND TABLES");
    [self reloadLabels];
    [self reloadTables];
}

- (void)reloadLabels {
    [self.view setHidden:NO];
    
    User *user = [[PinballMapManager sharedInstance] currentUser];
    Region *region = [[PinballMapManager sharedInstance] currentRegion];
    self.usernameLabel.text = user.username;
    self.locationsEditedInLabel.text = [NSString stringWithFormat:@"Locations Edited in %@:",region.fullName];
    
    self.usernameDateCreatedLabel.text = [user.dateCreated threeLetterMonthPretty];
    self.numCommentsLeftLabel.text = user.numCommentsLeft;
    self.numMachinesAddedLabel.text = user.numMachinesAdded;
    self.numLocationsEditedLabel.text = user.numLocationsEdited;
    self.numMachinesRemovedLabel.text = user.numMachinesRemoved;
    self.numLocationsSuggestedLabel.text = user.numLocationsSuggested;
}

- (void)reloadTables {
    [self.highScoresTableView reloadData];
    [self.editedLocationsTableView reloadData];
}
- (void)sendToRootAndLogin{
    LoginViewController *loginViewController = [[UIStoryboard storyboardWithName:@"SecondaryControllers" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewController"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;

    if ([UIDevice currentModel] == ModelTypeiPad){
        [self.tabBarController setSelectedIndex:0];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    [self presentViewController:nav animated:YES completion:nil];
}

- (IBAction)logout:(id)sender {
    [self sendToRootAndLogin];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    User *user = [[PinballMapManager sharedInstance] currentUser];

    if (tableView == self.editedLocationsTableView){
        return [user.userProfileEditedLocations count];
    } else if (tableView == self.highScoresTableView) {
        return [user.userProfileHighScores count];
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    User *user = [[PinballMapManager sharedInstance] currentUser];

    if (tableView == self.editedLocationsTableView){
        LocationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LocationCell"];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"location.name" ascending:YES];
        NSArray *sortDescriptors = [NSMutableArray arrayWithObject:sortDescriptor];
        NSArray *sortedArray = [[user.userProfileEditedLocations allObjects] sortedArrayUsingDescriptors:sortDescriptors];

        UserProfileEditedLocation *currentEditedLocation = [[NSMutableArray arrayWithArray:sortedArray] objectAtIndex:indexPath.row];
        Location *location = currentEditedLocation.location;
        cell.locationName.text = location.name;
        
        if ([location.locationDistance isEqual:@(0)]){
            cell.locationDetail.text = [NSString stringWithFormat:@"%@, %@",location.street,location.city];
        }else{
            cell.locationDetail.text = [NSString stringWithFormat:@"%.02f miles",[location.locationDistance floatValue]];
        }
        
        cell.machineCount.text = [NSString stringWithFormat:@"%lu",(unsigned long)location.machines.count];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        return cell;
    } else if (tableView == self.highScoresTableView) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SimpleTableCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SimpleTableCell"];
        }
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
        NSArray *sortDescriptors = [NSMutableArray arrayWithObject:sortDescriptor];
        NSArray *sortedArray = [[user.userProfileHighScores allObjects] sortedArrayUsingDescriptors:sortDescriptors];
        
        UserProfileHighScore *currentHighScore = [[NSMutableArray arrayWithArray:sortedArray] objectAtIndex:indexPath.row];
        
        NSString *highScore = [NSString stringWithFormat:@"%@\r%@\rat %@ on %@", currentHighScore.machineName, currentHighScore.locationName, currentHighScore.score, [currentHighScore.dateCreated threeLetterMonthPretty]];
        
        NSMutableAttributedString *formattedHighScore = [[NSMutableAttributedString alloc] initWithString:highScore];
        NSRange boldRange = [highScore rangeOfString:currentHighScore.score];
        NSRange underscoreRange = [highScore rangeOfString:currentHighScore.machineName];
        [formattedHighScore setAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize]} range:boldRange];
        [formattedHighScore setAttributes:@{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)} range:underscoreRange];
        
        cell.textLabel.attributedText = formattedHighScore;
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.highScoresTableView){
        return 44.0 * 2.0;
    } else {
        return 44.0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (tableView == self.editedLocationsTableView){
        User *user = [[PinballMapManager sharedInstance] currentUser];
        UserProfileEditedLocation *currentEditedLocation = [[user.userProfileEditedLocations allObjects] objectAtIndex:indexPath.row];
        
        if ([UIDevice iPad]){
            [self.tabBarController setSelectedIndex:0];
            LocationProfileView_iPad *locationView = (LocationProfileView_iPad *)[[self.tabBarController.viewControllers firstObject] navigationRootViewController];
            [locationView setCurrentLocation:currentEditedLocation.location];
        }else{
            LocationProfileView *profile = [self.storyboard instantiateViewControllerWithIdentifier:@"LocationProfileView"];
            profile.showMapSnapshot = true;
            profile.currentLocation = currentEditedLocation.location;
            [self.navigationController pushViewController:profile animated:YES];
        }
    }
}

@end
