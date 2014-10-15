//
//  SocketViewController.m
//  PlayingWithNav
//
//  Created by Victor Ilyukevich on 10/15/14.
//  Copyright (c) 2014 Victor Ilyukevich. All rights reserved.
//

#import "SocketViewController.h"

@interface SocketViewController ()

@end

@implementation SocketViewController

- (void)setDetailItem:(id)newDetailItem {
  if (_detailItem != newDetailItem) {
    _detailItem = newDetailItem;

    [self configureView];
  }
}

- (void)configureView {
  if (self.detailItem) {
    self.detailDescriptionLabel.text = [self.detailItem description];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self configureView];
}

@end
