//
//  BLEHandler.h
//  Garager
//
//  Created by Steven Dourmashkin on 9/5/18.
//  Copyright © 2018 Steven Dourmashkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@protocol BLEHandlerDelegate;

@interface BLEHandler : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

+ (CBUUID*)serviceUUID;
+ (CBUUID*)lightUUID;
+ (CBUUID*)garageUUID;

@property id<BLEHandlerDelegate> delegate;
@property CBCentralManager    *cm;
@property CBPeripheral *peripheral;

- (void)scanForPeripherals;
- (void)sendLightOn;
- (void)sendGarageOpen;
-(instancetype)initWithDelegate:(id<BLEHandlerDelegate>)delegate;
@end

@protocol BLEHandlerDelegate<NSObject>
-(void)connectedToGarager;
-(void)garagerDisconnected;

@end
