//
//  ViewController.m
//  Garager
//
//  Created by Steven Dourmashkin on 9/5/18.
//  Copyright © 2018 Steven Dourmashkin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becameActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    // round some corners
    self.lightButton.layer.cornerRadius = self.lightButton.frame.size.width/2;
    self.garageButton.layer.cornerRadius = self.garageButton.frame.size.width/2;
    self.garageBackView.layer.cornerRadius = self.garageBackView.frame.size.width/2;
    self.lightBackView.layer.cornerRadius = self.lightBackView.frame.size.width/2;
    
    self.bleHandler = [[BLEHandler alloc]initWithDelegate:self];
    

}

- (void)becameActive:(NSNotification *) notification
{
    [self tryScanningForGarager];
}

-(void)tryScanningForGarager
{
    if(!self.bleHandler.peripheral)
    {
        [self.bleHandler scanForPeripherals];
        
        [self.bleActivityIndicator setHidden:NO];
        [self.bleActivityIndicator startAnimating];
        [self.bleMessage setText:@"Scanning for your Garager"];
        
        [self.lightButton setEnabled:NO];
        [self.garageButton setEnabled:NO];
    }
    else
    {
        [self displayConnectedMessage];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)lightButtonTapped:(UIButton *)sender {
    [self.bleHandler sendLightOn];
}

- (IBAction)garageButtonTapped:(UIButton *)sender {
    [self.bleHandler sendGarageOpen];

}

#pragma mark message definitions
-(void)displayConnectedMessage
{
    
    self.bleActivityIndicator.hidden = YES;
    [self.bleMessage setText:@"Connected to Garager."];
    
    [self.lightButton setEnabled:YES];
    [self.garageButton setEnabled:YES];
}
#pragma mark BLEHandlerDelegate methods
-(void)connectedToGarager
{
    [self displayConnectedMessage];
}
-(void)garagerDisconnected
{
    [self tryScanningForGarager];
}
@end
