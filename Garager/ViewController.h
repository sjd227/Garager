//
//  ViewController.h
//  Garager
//
//  Created by Steven Dourmashkin on 9/5/18.
//  Copyright © 2018 Steven Dourmashkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEHandler.h"

@interface ViewController : UIViewController<BLEHandlerDelegate>

// IBOUTLETS:
@property (weak, nonatomic) IBOutlet UILabel *bleMessage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *bleActivityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *lightButton;
@property (weak, nonatomic) IBOutlet UIButton *garageButton;
@property (weak, nonatomic) IBOutlet UIView *garageBackView;
@property (weak, nonatomic) IBOutlet UIView *lightBackView;

// IBACTIONS:
- (IBAction)lightButtonTapped:(UIButton *)sender;
- (IBAction)garageButtonTapped:(UIButton *)sender;

// CLASS PROPERTIES:
@property BLEHandler *bleHandler;

@end


