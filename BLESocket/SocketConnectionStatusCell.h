//
//  SocketConnectionStatusCell.h
//  BLESocket
//
//  Created by Victor Ilyukevich on 11/21/14.
//  Copyright (c) 2014 Victor Ilyukevich. All rights reserved.
//

@import CoreBluetooth;

@interface SocketConnectionStatusCell : UITableViewCell

- (void)configureForState:(CBPeripheralState)state;

@end
