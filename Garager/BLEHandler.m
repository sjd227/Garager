//
//  BLEHandler.m
//  Garager
//
//  Created by Steven Dourmashkin on 9/5/18.
//  Copyright © 2018 Steven Dourmashkin. All rights reserved.
//

#import "BLEHandler.h"

@interface BLEHandler()

@property CBService *service;
@property CBCharacteristic *lightCharacteristic;
@property CBCharacteristic *garageCharacteristic;
@end


@implementation BLEHandler
@synthesize peripheral = _peripheral;

@synthesize service = _service;
@synthesize lightCharacteristic = _lightCharacteristic;
@synthesize garageCharacteristic = _garageCharacteristic;


+ (CBUUID*)serviceUUID
{
    return [CBUUID UUIDWithString:@"1207"];
}
+ (CBUUID*)lightUUID
{
    return [CBUUID UUIDWithString:@"1207"];

}
+ (CBUUID*)garageUUID
{
    return [CBUUID UUIDWithString:@"1208"];
}

-(instancetype)initWithDelegate:(id<BLEHandlerDelegate>)delegate;
{
    self = [super init];
    if(self)
    {
        self.cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.delegate = delegate;
    }
    return self;
}
- (NSArray*)getConnectedPeripherals
{
    NSArray *connectedPeripherals = [self.cm retrieveConnectedPeripheralsWithServices:@[[BLEHandler serviceUUID]]];
    
    // connect each peripheral
    for (CBPeripheral *p in connectedPeripherals)
    {
        [self connectPeripheral:p];
    }
    return connectedPeripherals;
}

- (void)connectPeripheral:(CBPeripheral*)peripheral{
    
    //Connect Bluetooth LE device
    
    //Clear off any pending connections
    [self.cm cancelPeripheralConnection:peripheral];
    self.peripheral = peripheral;
    self.peripheral.delegate = self;
    
    //Connect
    [self.cm connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]}];
    NSLog(@"Attempting to connect to a Specdrums Ring.");

    
}

#pragma mark CBCentralManagerDelegate
- (void) centralManagerDidUpdateState:(CBCentralManager*)central{
    
    if (central.state == CBCentralManagerStatePoweredOn){
        
        //respond to powered on
        [self scanForPeripherals];
    }
    
    
    else if (central.state == CBCentralManagerStatePoweredOff)
    {
        
        //respond to powered off...
    
    }
    
}

- (void)scanForPeripherals{
    
    //Look for available Bluetooth LE devices
    
    NSLog(@"Scanning for Garager...");
    [self.cm scanForPeripheralsWithServices:@[self.class.serviceUUID]
                                    options:@{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:NO]}];
    }

- (void)sendLightOn
{
    uint8_t bytes[1]= {0x01};
    NSData *data= [[NSData alloc ]initWithBytes:bytes length:1];
    [self.peripheral writeValue:data forCharacteristic:self.lightCharacteristic type:CBCharacteristicWriteWithResponse];
}
- (void)sendGarageOpen
{
    uint8_t bytes[1]= {0x01};
    NSData *data= [[NSData alloc ]initWithBytes:bytes length:1];
    [self.peripheral writeValue:data forCharacteristic:self.garageCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void) centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber*)RSSI{
    
    NSLog(@"Did discover peripheral %@", peripheral.name);
    [self.cm stopScan];
    [self connectPeripheral:peripheral];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    
}

- (void) centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral*)peripheral{
    
    NSLog(@"Did connect peripheral %@", peripheral.name);
    [self didConnect:peripheral];
    return;
}

- (void) centralManager:(CBCentralManager*)central didDisconnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error{
    
    NSLog(@"Did disconnect peripheral %@", peripheral.name);
    
    //respond to disconnected
    [self peripheralDidDisconnect];
    [central connectPeripheral:peripheral options:@{}];
}


- (void)didConnect:(CBPeripheral*)peripheral
{
    //Respond to peripheral connection
    
    if(peripheral.services){
        printf("Skipping service discovery for %s\r\n", [peripheral.name UTF8String]);
        [self peripheral:peripheral didDiscoverServices:nil]; //already discovered services, DO NOT re-discover. Just pass along the peripheral.
        return;
    }
    
    printf("Starting service discovery for %s\r\n", [peripheral.name UTF8String]);
    
    //[_peripheral discoverServices:@[self.class.specdrumsRingServiceUUID]];
    [peripheral discoverServices:@[self.class.serviceUUID]];
    
}

- (void)peripheralDidDisconnect{
    
    //respond to device disconnecting
    
    //if we were in the process of scanning/connecting, dismiss alert
    self.peripheral = nil;
    [self didEncounterError:@"Peripheral disconnected"];
    [self.delegate garagerDisconnected];
}

- (void)didEncounterError:(NSString*)error{
    
    //Dismiss "scanning …" alert view if shown
    NSLog(@"-------ERROR--------: %@",error);
}


#pragma mark - CBPeripheral Delegate methods

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error{
    
    //Respond to finding a new service on peripheral
    
    printf("Did Discover Services\r\n");
    
    if (!error) {
        
        
        for (CBService *s in [peripheral services]){
            
            if (s.characteristics){
                [self peripheral:peripheral didDiscoverCharacteristicsForService:s error:nil]; //already discovered characteristic before, DO NOT do it again
            }
            
            else if ([self compareID:s.UUID toID:self.class.serviceUUID]){
                
                printf("Found Garager service\r\n");
                
                self.service = s;
                
                [peripheral discoverCharacteristics:@[self.class.lightUUID, self.class.garageUUID] forService:self.service];
            }
            
        }
    }
    
    else{
        
        printf("Error discovering services\r\n");
        
        [self didEncounterError:@"Error discovering services"];
        
        return;
    }
    
}

- (BOOL)compareID:(CBUUID*)firstID toID:(CBUUID*)secondID{
    
    if ([[firstID UUIDString] compare:[secondID UUIDString]] == NSOrderedSame) {
        return YES;
    }
    
    else
        return NO;
    
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error{
    
    //Respond to finding a new characteristic on service
    
    if (!error){
        
        CBService *s = [peripheral.services lastObject];
        if([self compareID:service.UUID toID:s.UUID]){
            
            //last service discovered
            printf("Found all characteristics\r\n");
            
            [self setupPeripheralForUse:peripheral];
            
            //[self setSpecdrumsAppMode]; // tell ring it's in "specdrums" app mode
        }
        
    }
    
    else{
        
        printf("Error discovering characteristics: %s\r\n", [error.description UTF8String]);
        
        [self didEncounterError:@"Error discovering characteristics"];
        
        return;
    }
    
}

- (void)setupPeripheralForUse:(CBPeripheral*)peripheral{
    
    printf("Set up peripheral for use\r\n");
    
    for (CBService *s in peripheral.services) {
        
        for (CBCharacteristic *c in [s characteristics]){
            
            if ([self compareID:c.UUID toID:self.class.lightUUID])
            {
                printf("Found light characteristic\r\n");
                self.lightCharacteristic = c;
                [self.peripheral setNotifyValue:YES forCharacteristic:self.lightCharacteristic];
            }
            
            if ([self compareID:c.UUID toID:self.class.garageUUID]){
                
                printf("Found garage characteristic\r\n");
                self.garageCharacteristic = c;
                
                [self.peripheral setNotifyValue:YES forCharacteristic:self.garageCharacteristic];
            }
            else
            {
                NSLog(@"unknown characteristic...");
            }
            
        }
        
    }
    [self.delegate connectedToGarager];
}
@end
