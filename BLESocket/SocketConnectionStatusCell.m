//
//  SocketConnectionStatusCell.m
//  BLESocket
//
//  Created by Victor Ilyukevich on 11/21/14.
//  Copyright (c) 2014 Victor Ilyukevich. All rights reserved.
//

#import "SocketConnectionStatusCell.h"

@interface SocketConnectionStatusCell ()
@property (strong, nonatomic) IBOutlet UILabel *label;
@end

@implementation SocketConnectionStatusCell

- (void)configureForState:(CBPeripheralState)state
{
  switch (state) {
    case CBPeripheralStateDisconnected:
      self.label.text = @"Connect";
      self.label.textColor = [UIColor blueColor];
      break;
    case CBPeripheralStateConnecting:
      self.label.text = @"Connecting...";
      self.label.textColor = [UIColor grayColor];
      break;
    case CBPeripheralStateConnected:
      self.label.text = @"Disconnect";
      self.label.textColor = [UIColor redColor];
      break;
  }
}

@end
