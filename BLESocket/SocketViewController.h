//
//  SocketViewController.h
//  PlayingWithNav
//
//  Created by Victor Ilyukevich on 10/15/14.
//  Copyright (c) 2014 Victor Ilyukevich. All rights reserved.
//

@import CoreBluetooth;

@interface SocketViewController : UITableViewController

@property (strong, nonatomic) CBPeripheral *socket;

@end

