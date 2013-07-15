/******************************************************************************
 *
 * Copyright (C) 2013 T Dispatch Ltd
 *
 * Licensed under the GPL License, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.gnu.org/licenses/gpl-3.0.html
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 ******************************************************************************
 *
 * @author Marcin Orlowski <marcin.orlowski@webnet.pl>
 *
 ****/

#import "LocationSelectorViewController.h"

@interface LocationSelectorViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *locationView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UITextField *locationTextField;
@property (weak, nonatomic) IBOutlet UIView *separatorView;

@property (nonatomic, strong) NSArray* locations;

@end

@implementation LocationSelectorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView.backgroundColor = [UIColor searchDialogBackgroundColor];
    
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.locationType == LocationTypePickup)
    {
        self.logoImage = [UIImage imageNamed:@"map_marker_pickup"];
        self.placeholder = NSLocalizedString(@"address_search_pickup_hint", @"");
    }
    else
    {
        self.logoImage = [UIImage imageNamed:@"map_marker_dropoff"];
        self.placeholder = NSLocalizedString(@"address_search_dropoff_hint", @"");
    }

    _locationTextField.placeholder = _placeholder;
    _locationTextField.text = _locationName;
    _logoImageView.image = _logoImage;
    
    _logoImageView.backgroundColor = [UIColor clearColor];
    _locationView.backgroundColor = [UIColor searchDialogBackgroundColor];

    [_separatorView setBackgroundColor:[UIColor searchDialogSeparatorColor]];
    
    _locationTextField.backgroundColor = [UIColor searchDialogBackgroundColor];
    _locationTextField.textColor = [UIColor searchDialogTextColor];
    
    _locationTextField.font = [UIFont lightOpenSansOfSize:17];
    _locationTextField.delegate = self;
    [_locationTextField becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(UITextFieldTextDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:_locationTextField];
    
    if (_locationName)
        [self searchForLocation:_locationName];
    
/*    UIView* accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    accessoryView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    UIButton* b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setTitle:NSLocalizedString(@"address_search_button_cancel", @"")forState:UIControlStateNormal];
    [b addTarget:self action:@selector(cancelSelection) forControlEvents:UIControlEventTouchUpInside];
    [b setTitleColor:[UIColor buttonTextColor] forState:UIControlStateNormal];
    [b setBackgroundColor:[UIColor buttonColor]];
    [b.titleLabel setFont:[UIFont lightOpenSansOfSize:16]];
    b.frame = CGRectMake(12, 4, 64, 32);
    [accessoryView addSubview:b];
    _locationTextField.inputAccessoryView = accessoryView;
*/
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_locationTextField becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_locationTextField resignFirstResponder];
}

- (void)cancelSelection
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidChangeNotification
                                                  object:_locationTextField];
    [_locationTextField resignFirstResponder];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setLogoImageView:nil];
    [self setLocationTextField:nil];
    [self setLocationView:nil];
    [self setTableView:nil];
    [self setSeparatorView:nil];
    [super viewDidUnload];
}

#pragma mark table view source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _locations.count > 4 ? 4 : _locations.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 36;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* location = [_locations objectAtIndex:indexPath.row];
    
    static NSString *cellIdentifier = @"locationTableViewCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    cell.textLabel.text = location[@"address"];
    cell.textLabel.font = [UIFont lightOpenSansOfSize:13];
    cell.textLabel.textColor = [UIColor searchDialogTextColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.completionBlock)
    {
        NSDictionary *d = [_locations objectAtIndex:indexPath.row];
        NSNumber* lat = d[@"location"][@"lat"];
        NSNumber* lng = d[@"location"][@"lng"];
        CLLocationCoordinate2D c = CLLocationCoordinate2DMake([lat floatValue], [lng floatValue]);
        
        MapAnnotation* a = [[MapAnnotation alloc] initWithCoordinate:c withTitle:d[@"address"] withImageName:nil];
        a.zipCode = d[@"postcode"];
        self.completionBlock(self.locationType, a);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return NO;
}

- (void)searchForLocation:(NSString *)location
{
    if (location.length)
    {
        
        [[NetworkEngine getInstance] cancelAllOperations];
        [[NetworkEngine getInstance] searchForLocation:location
                                                  type:self.locationType
                                       completionBlock:^(NSObject *o){
                                           self.locations = (NSArray *)o;
                                           [self.tableView reloadData];
                                           
                                       }
                                          failureBlock:^(NSError *error) {
                                              
                                          }];
    }
    else
    {
        self.locations = nil;
        [_tableView reloadData];
    }
}

#pragma mark UITextField delegate

- (void) UITextFieldTextDidChange:(NSNotification*)notification
{
    UITextField * textfield = (UITextField*)notification.object;
    NSString * text = textfield.text;

    [self searchForLocation:text];

}
@end
