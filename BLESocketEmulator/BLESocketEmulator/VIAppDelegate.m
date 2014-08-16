//
//  VIAppDelegate.m
//  BLESocketEmulator
//
//  Created by Victor Ilyukevich on 8/16/14.
//  Copyright (c) 2014 Victor Ilyukevich. All rights reserved.
//

#import "VIAppDelegate.h"
@import IOBluetooth;

#define SOCKET_SERVICE_UUID [CBUUID UUIDWithString:@"FF10"]
#define SOCKET_CURRENT_CHARACTERISTIC_UUID [CBUUID UUIDWithString:@"FF11"]

@interface VIAppDelegate ()
<CBPeripheralManagerDelegate>
@property(nonatomic,strong) CBPeripheralManager *peripheralManager;
@property(nonatomic,strong) CBMutableCharacteristic *current;
@end

@implementation VIAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
  if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
    uint16_t value[1] = { 0x01 };
    NSData *a = [NSData dataWithBytes:value length:sizeof(unsigned char)];

    CBMutableService *service = [[CBMutableService alloc] initWithType:SOCKET_SERVICE_UUID primary:YES];
    CBMutableCharacteristic *current = [[CBMutableCharacteristic alloc] initWithType:SOCKET_CURRENT_CHARACTERISTIC_UUID properties:CBCharacteristicPropertyRead value:a permissions:CBAttributePermissionsReadable];
    service.characteristics = @[current];
    self.current = current;
    [self.peripheralManager addService:service];
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[service.UUID] }];
  } else {
    [self.peripheralManager stopAdvertising];
    NSLog(@"Peripheral manager's state is not poweredOn %ld", peripheral.state);
  }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
  if (error) {
    NSLog(@"Error publishing service: %@", [error localizedDescription]);
  }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
  NSLog(@"peripheralManagerDidStartAdvertising %@ (%@)", peripheral, error);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
  static BOOL enabled = YES;

  uint16_t value[1] = { (enabled ? 0x01 : 0x00) };
  self.current.value = [NSData dataWithBytes:value length:sizeof(unsigned char)];

  [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];

  enabled = !enabled;
}

@end
