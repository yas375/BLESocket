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

#define SOCKET_SERVICE_UUID [CBUUID UUIDWithString:@"FF10"]
#define SOCKET_CURRENT_CHARACTERISTIC_UUID [CBUUID UUIDWithString:@"FF11"]

@interface SocketsViewController ()
<CBCentralManagerDelegate,CBPeripheralDelegate>
@property(nonatomic,strong) CBCentralManager *centralManager;
@property(nonatomic,strong) NSMutableArray *socketPeripherals;
@end

@implementation SocketsViewController

#pragma mark - Methods

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

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
  DDLogVerbose(@"centralManagerDidUpdateState %d", central.state);

  if (central.state == CBCentralManagerStatePoweredOn) {
    [self.centralManager scanForPeripheralsWithServices:@[SOCKET_SERVICE_UUID] options:nil];
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
  if ([self.socketPeripherals containsObject:peripheral] == NO) {
    [self.socketPeripherals addObject:peripheral];

    DDLogVerbose(@"Discovered potential socket peripharal %@", peripheral);
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
  [peripheral discoverServices:@[SOCKET_SERVICE_UUID]];
  [self.tableView reloadData];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
  BOOL needsToDisconnect = YES;

  if (error) {
    DDLogError(@"Error while discovering services of peripheral %@ (%@)", peripheral, error);
  } else {
    for (CBService *service in peripheral.services) {
      if ([service.UUID isEqual:SOCKET_SERVICE_UUID]) {
        [peripheral discoverCharacteristics:@[SOCKET_CURRENT_CHARACTERISTIC_UUID] forService:service];
        needsToDisconnect = NO;
      }
    }
  }

  if (needsToDisconnect) {
    [self.centralManager cancelPeripheralConnection:peripheral];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
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

  NSString *state;
  switch (peripheral.state) {
    case CBPeripheralStateDisconnected:
      state = @"disconnected";
      break;
    case CBPeripheralStateConnecting:
      state = @"connecting...";
      break;
    case CBPeripheralStateConnected:
      state = @"connected";
      break;
  }
  cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", peripheral.name, state];

  return cell;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.socketPeripherals = [NSMutableArray array];
  self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

@end
