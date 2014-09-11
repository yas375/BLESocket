//
//  SocketsViewController.m
//  BLESocket
//
//  Created by Victor Ilyukevich on 8/16/14.
//  Copyright (c) 2014 Victor Ilyukevich. All rights reserved.
//

#import "SocketsViewController.h"
#import "SocketCell.h"
@import CoreBluetooth;

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

#define DEVICE_INFORMATION_SERVICE_UUID [CBUUID UUIDWithString:@"180A"]
#define SOCKET_SERVICE_UUID [CBUUID UUIDWithString:@"10FF91F6-F974-EEA6-4F4C-D732E03823B6"]
#define SOCKET_CURRENT_CHARACTERISTIC_UUID [CBUUID UUIDWithString:@"11FF91F6-F974-EEA6-4F4C-D732E03823B6"]

@interface SocketsViewController ()
<CBCentralManagerDelegate,CBPeripheralDelegate>
@property(nonatomic,strong) CBCentralManager *centralManager;
@property(nonatomic,strong) UISegmentedControl *scanModeSwitcher;
@property(nonatomic,strong) NSMutableArray *socketPeripherals;
@end

@implementation SocketsViewController

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

  self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)scanModeSegmentedControlAction:(UISegmentedControl *)sender
{
  [self recreateCentralManager];
}

- (NSArray *)servicesToScan
{
  if (self.scanModeSwitcher.selectedSegmentIndex == 0) {
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

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
  DDLogVerbose(@"centralManagerDidUpdateState %d", (int)central.state);

  if (central.state == CBCentralManagerStatePoweredOn) {
    NSArray *services = self.servicesToScan;
    DDLogVerbose(@"Will scan for peripharals with services: %@", services);
    [self.centralManager scanForPeripheralsWithServices:services options:nil];
  }
  else {
    NSString *message = [self errorMesssageForState:central.state];
    if (message) {
      [[[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
    [self.socketPeripherals removeAllObjects];
  }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
  DDLogVerbose(@"Discovered potential socket peripharal %@ with advertisement data: \n%@", peripheral, advertisementData);

  if ([self.socketPeripherals containsObject:peripheral] == NO) {
    [self.socketPeripherals addObject:peripheral];

    [self.centralManager connectPeripheral:peripheral options:nil];
  }
  [self.tableView reloadData];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
  DDLogError(@"Failed to connect peripharal %@ (%@)", peripheral, error);
  [self.tableView reloadData];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
  DDLogVerbose(@"Disconnected peripharal %@ (%@)", peripheral, error);
  [self.tableView reloadData];
}

 - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
  DDLogVerbose(@"Did connect peripharal %@", peripheral);

  peripheral.delegate = self;
  DDLogVerbose(@"Will discover service %@", SOCKET_SERVICE_UUID);
  [peripheral discoverServices:@[SOCKET_SERVICE_UUID]];
  [self.tableView reloadData];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
  DDLogVerbose(@"didDiscoverServices:");
  if (error) {
    DDLogError(@"Error while discovering services of peripheral %@ (%@)", peripheral, error);
  } else {
    for (CBService *service in peripheral.services) {
      if ([service.UUID isEqual:SOCKET_SERVICE_UUID]) {
        DDLogVerbose(@"Will discover characteristic %@", SOCKET_CURRENT_CHARACTERISTIC_UUID);
        [peripheral discoverCharacteristics:@[SOCKET_CURRENT_CHARACTERISTIC_UUID] forService:service];
      }
    }
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
  DDLogVerbose(@"didDiscoverCharacteristicsForService: %@; error: %@", service, error);
  BOOL needsToDisconnect = YES;

  if (error) {
    DDLogError(@"Error while discovering characteristic of service %@ of peripheral %@ (%@)", service, peripheral, error);
  } else if ([service.UUID isEqual:SOCKET_SERVICE_UUID]) {
    for (CBCharacteristic *characteristic in service.characteristics) {
      if ([characteristic.UUID isEqual:SOCKET_CURRENT_CHARACTERISTIC_UUID]) {
        DDLogVerbose(@"Reading value for characteristic %@", characteristic);
        [peripheral readValueForCharacteristic:characteristic];
        needsToDisconnect = NO;
      }
    }
  }

  if (needsToDisconnect) {
    [self.centralManager cancelPeripheralConnection:peripheral];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
  DDLogVerbose(@"Peripheral %@ did update value for characteristc %@. Error %@", peripheral, characteristic, error);
  [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.socketPeripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  SocketCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"SocketCellIdentifier"];

  CBPeripheral *peripheral = self.socketPeripherals[indexPath.row];

  NSString *connactionState;
  switch (peripheral.state) {
    case CBPeripheralStateDisconnected:
      connactionState = @"disconnected";
      break;
    case CBPeripheralStateConnecting:
      connactionState = @"connecting...";
      break;
    case CBPeripheralStateConnected:
      connactionState = @"connected";
      break;
  }
  cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", peripheral.name, connactionState];

  NSString *state = @"unknown";

  CBService *service = [peripheral.services bk_match:^BOOL(CBService *obj) {
    return [obj.UUID isEqual:SOCKET_SERVICE_UUID];
  }];

  if (service) {
    CBCharacteristic *characteristic = [service.characteristics bk_match:^BOOL(CBCharacteristic *obj) {
      return [obj.UUID isEqual:SOCKET_CURRENT_CHARACTERISTIC_UUID];
    }];

    if (characteristic) {
      if (characteristic.value) {
        uint8_t *bytes = (uint8_t *)characteristic.value.bytes;

        if (bytes == NULL) {
          state = @"read value is NULL";
        }
        else if (*bytes == 0x01) {
          state = @"enabled";
        }
        else if (*bytes == 0x00) {
          state = @"disabled";
        }
        else {
          DDLogVerbose(@"Error reading value of characteristic %@", characteristic);
          state = @"error during reading value";
        }
      }
      else {
        DDLogVerbose(@"nil value of characteristic %@", characteristic);
        state = @"value is nil";
      }
    }
  }

  cell.detailTextLabel.text = [NSString stringWithFormat:@"Socket state: %@", state];

  return cell;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.navigationItem.rightBarButtonItem = [self makeScanModeSwitcher];
  [self setupRefreshControl];

  self.socketPeripherals = [NSMutableArray array];
  self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];

  [self recreateCentralManager];
}

@end
