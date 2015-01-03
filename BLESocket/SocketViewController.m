//
//  SocketViewController.m
//  PlayingWithNav
//
//  Created by Victor Ilyukevich on 10/15/14.
//  Copyright (c) 2014 Victor Ilyukevich. All rights reserved.
//

#import "SocketViewController.h"
#import "SocketConnectionStatusCell.h"

@interface SocketViewController ()

@end

@implementation SocketViewController

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SocketConnectionStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConnectionStatus"];

  [cell configureForState:self.socket.state];

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSLog(@"Tapped %@", indexPath);
}

@end
