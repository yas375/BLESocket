//
//  SocketsViewController.m
//  PlayingWithNav
//
//  Created by Victor Ilyukevich on 10/15/14.
//  Copyright (c) 2014 Victor Ilyukevich. All rights reserved.
//

#import "SocketsViewController.h"
#import "SocketViewController.h"
@import CoreBluetooth;

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

#define DEVICE_INFORMATION_SERVICE_UUID [CBUUID UUIDWithString:@"180A"]
#define SOCKET_SERVICE_UUID [CBUUID UUIDWithString:@"10FF91F6-F974-EEA6-4F4C-D732E03823B6"]
#define SOCKET_CURRENT_CHARACTERISTIC_UUID [CBUUID UUIDWithString:@"11FF91F6-F974-EEA6-4F4C-D732E03823B6"]

@interface SocketsViewController ()
<CBCentralManagerDelegate>
@property(nonatomic,strong) CBCentralManager *centralManager;
@property(nonatomic,strong) UISegmentedControl *scanModeSwitcher;
// udid -> @YES/@NO
@property(nonatomic,strong) NSMutableDictionary *discoveredStatuses;
@property(nonatomic,strong) NSMutableArray *socketPeripherals; // TODO: rename to otherDevices
@property(nonatomic,strong) NSMutableArray *knownDevices;
@property(nonatomic,strong) SocketViewController *socketViewController;
@end

@implementation SocketsViewController

#pragma mark - Getters

- (NSMutableDictionary *)discoveredStatuses
{
  if (_discoveredStatuses == nil) {
    _discoveredStatuses = [NSMutableDictionary dictionary];
  }
  return _discoveredStatuses;
}

- (NSMutableArray *)knownDevices
{
  if (_knownDevices == nil) {
    _knownDevices = [NSMutableArray array];
  }
  return _knownDevices;
}

- (NSMutableArray *)socketPeripherals
{
  if (_socketPeripherals == nil) {
    _socketPeripherals = [NSMutableArray array];
  }
  return _socketPeripherals;
}

#pragma mark - Methods

- (void)didTriggerRefreshControl:(UIRefreshControl *)sender
{
  [self recreateCentralManager];
  [sender endRefreshing];
}

- (NSString *)errorMesssageForState:(CBCentralManagerState)state
{
  if (state == CBCentralManagerStateUnsupported) {
    return @"This device doesn't support Bluetooth low energy.";
  }
  else if (state == CBCentralManagerStateUnauthorized) {
    return @"The app is not authorized to use Bluetooth low energy. Please go to Settings and allow the app to use Bluettoth";
  }
  else if (state == CBCentralManagerStatePoweredOff) {
    return @"Bluetooth is currently powered off. Please turn it on.";
  }
  else {
    return nil;
  }
}

- (UIBarButtonItem *)makeScanModeSwitcher
{
  NSArray *elements = @[@"All", @"FF10"];
  self.scanModeSwitcher = [[UISegmentedControl alloc] initWithItems:elements];
  self.scanModeSwitcher.selectedSegmentIndex = 0;

  [self.scanModeSwitcher addTarget:self action:@selector(scanModeSegmentedControlAction:) forControlEvents:UIControlEventValueChanged];
  UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.scanModeSwitcher];
  return barButtonItem;
}

- (void)recreateCentralManager
{
  [self.centralManager stopScan];
  [self.socketPeripherals bk_each:^(CBPeripheral *obj) {
    [self.centralManager cancelPeripheralConnection:obj];
  }];
  [self.socketPeripherals removeAllObjects];
  [self.tableView reloadData];

  self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{ CBCentralManagerOptionRestoreIdentifierKey: kVICentralManagerIdentifier }];
}

- (void)scanModeSegmentedControlAction:(UISegmentedControl *)sender
{
  [self recreateCentralManager];
}

- (NSArray *)servicesToScan
{
  if (BluetoothDebuggingEnabled() && self.scanModeSwitcher.selectedSegmentIndex == 0) {
    return nil;
  }
  return @[SOCKET_SERVICE_UUID];
}

- (void)setupRefreshControl
{
  UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
  [refreshControl addTarget:self action:@selector(didTriggerRefreshControl:) forControlEvents:UIControlEventValueChanged];
  self.refreshControl = refreshControl;
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
  // Very first call if the app is relaunched and central manager is already scanning.

  DDLogVerbose(@"centralManager:willRestoreState:");
  // TODO: do we need to set the reference?
  DDLogVerbose(@"%@ - %@", self.centralManager, central);
  NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];

  for (CBPeripheral *peripheral in peripherals) {
    [self.socketPeripherals addObject:peripheral];
  }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
  DDLogVerbose(@"centralManagerDidUpdateState %d", (int)central.state);

  if (central.state == CBCentralManagerStatePoweredOn) {
    NSArray *services = self.servicesToScan;
    DDLogVerbose(@"Will scan for peripharals with services: %@", services);
    [self.centralManager scanForPeripheralsWithServices:services options:nil];

    // TODO: state restoration
//    // If we were restored with connected devices we might want to subscribe to the changes
//    for (CBPeripheral *peripheral in self.socketPeripherals) {
//      if (peripheral.state == CBPeripheralStateConnected) {
//        // Have we discovered needed service?
//        // - NO - start discovering for services
//        // Have we discovered the characteristic?
//        // - NO - start discovering
//        // Are we subscribed?
//        // - NO - subscribe
//      }
//    }
  }
  else {
    NSString *message = [self errorMesssageForState:central.state];
    if (message) {
      [[[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
    [self.socketPeripherals removeAllObjects];
  }
}

- (void)extractStatusForDevice:(CBPeripheral *)device fromAdvertisementData:(NSDictionary *)advertisementData
{
  NSUUID *identifier = device.identifier;
  NSNumber *value;

  NSDictionary *serviceData = advertisementData[@"kCBAdvDataServiceData"];

  if (serviceData != nil) {
    CBUUID *uuid = [CBUUID UUIDWithString:@"11FF"]; // todo: define somewehere in one place
    NSData *valueAsData = serviceData[uuid];

    if (valueAsData != nil) {
      uint16_t decodedInteger;
      [valueAsData getBytes:&decodedInteger length:valueAsData.length];
      uint16_t isEnabled = CFSwapInt16(decodedInteger);
      value = @((BOOL)isEnabled);
    }
  }
  if (value) {
    self.discoveredStatuses[identifier] = value;
  }
  else {
    [self.discoveredStatuses removeObjectForKey:identifier];
  }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
  DDLogVerbose(@"Discovered potential socket peripharal %@ with advertisement data: \n%@", peripheral, advertisementData);

  [self extractStatusForDevice:peripheral fromAdvertisementData:advertisementData]; // TODO: update the list in any case?

  if ([self.socketPeripherals containsObject:peripheral] == NO) {
    [self.socketPeripherals addObject:peripheral];
  }
  [self.tableView reloadData];
}

#pragma mark - NSObject

- (void)awakeFromNib
{
  [super awakeFromNib];

  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    self.clearsSelectionOnViewWillAppear = NO;
    self.preferredContentSize = CGSizeMake(320.0, 600.0);
  }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.socketViewController = (SocketViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];

  if (BluetoothDebuggingEnabled()) {
    self.navigationItem.rightBarButtonItem = [self makeScanModeSwitcher];
  }
  [self setupRefreshControl];

  [self recreateCentralManager];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"showDetail"]) {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    CBPeripheral *object = self.socketPeripherals[indexPath.row];
    SocketViewController *controller = (SocketViewController *)[[segue destinationViewController] topViewController];
    controller.socket = object;

    controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    controller.navigationItem.leftItemsSupplementBackButton = YES;
  }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (section == 0) {
    return self.knownDevices.count;
  }

  return self.socketPeripherals.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == 0) {
    return @"My sockets";
  }
  else {
    return @"Other sockets";
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];

  CBPeripheral *peripheral = self.socketPeripherals[indexPath.row];
  cell.textLabel.text = peripheral.name;

  NSNumber *number = self.discoveredStatuses[peripheral.identifier];
  if (number && number.boolValue) {
    cell.detailTextLabel.text = @"Enabled";
  }
  else {
    cell.detailTextLabel.text = @"Disabled";
  }

  return cell;
}

@end
