//
//  ViewController.m
//  Compass
//
//  Created by Dimitar Stojcev on 2/14/18.
//  Copyright © 2018 Dimitar Stojcev. All rights reserved.
//

#import "ViewController.h"
#import "BLE.h"

@import CoreLocation;

@interface ViewController ()<CLLocationManagerDelegate,BLEDelegate>{
    CLLocationManager *locationManager;
    BOOL isUpdating;
    double timerCompass;
    double previousX,previousY;
    
    BLE *bleShield;
}

@end

@implementation ViewController

#pragma mark - CustomFunctions
- (void)setupLocationManager {
    locationManager = [[CLLocationManager alloc] init];
    if ([CLLocationManager headingAvailable] == NO) {
        locationManager = nil;
    } else {
        locationManager.headingFilter = kCLHeadingFilterNone;
        locationManager.delegate = self;
    }
}

#pragma mark - IBActions
-(IBAction)onBtnStart:(UIButton *)sender{
    if (!isUpdating) {
        [locationManager startUpdatingHeading];
        isUpdating = YES;
        [sender setTitle:@"Stop" forState:UIControlStateNormal];
    }
    else{
        [sender setTitle:@"Start" forState:UIControlStateNormal];
        [locationManager stopUpdatingHeading];
        isUpdating = NO;
    }
}
-(IBAction)onBtnCollistion:(UIButton *)sender{
    [self drawColision];
}
-(IBAction)searchBLE:(UIButton *)sender{
    if (bleShield.activePeripheral){
        [[bleShield CM] cancelPeripheralConnection:[bleShield activePeripheral]];
        return;
    }
    if (bleShield.peripherals){
        bleShield.peripherals = nil;
    }
    [bleShield findBLEPeripherals:3];
    [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
}
-(void)connectionTimer:(NSTimer *)timer{
    if(bleShield.peripherals.count > 0){
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"BLE" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
        
        for(int i=0;i<bleShield.peripherals.count;i++){
            CBPeripheral *p = [bleShield.peripherals objectAtIndex:i];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:p.name style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [bleShield connectPeripheral:p];
            }];
            [alert addAction:action];
        }
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:cancel];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - BLE Delegate
-(void)bleDidReceiveData:(unsigned char *)data length:(int)length{
    NSData *dataRecv = [NSData dataWithBytes:data length:length];
    NSString *stringRecv = [[NSString alloc] initWithData:dataRecv encoding:NSUTF8StringEncoding];
   
    //if(NSDate.date.timeIntervalSince1970 - timerCompass < 0.3){
    //    return;
   // }
   // timerCompass = NSDate.date.timeIntervalSince1970;
    
    printf("%s",[stringRecv UTF8String]);
    
    if([stringRecv containsString:@"c"]){
        [self drawColision];
    }
    else{
        [self drawRoverPoint:[stringRecv doubleValue] fromBLE:YES];
    }
}
-(void)bleDidDisconnect{
    NSLog(@"BLE DISCONNECT");
}
-(void)bleDidConnect{
    NSLog(@"CONNECT");
}
-(void)bleDidUpdateRSSI:(NSNumber *)rssi{
    
}


#pragma mark - CustomFunction
-(double) degreesToRadians:(double)degrees{
    return (degrees * M_PI) / 180;
}
-(void)drawColision{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.strokeColor = [[UIColor redColor] CGColor];
    shapeLayer.fillColor = [[UIColor redColor] CGColor];
    [shapeLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(previousX, previousY, 5, 5)] CGPath]];
    [self.view.layer addSublayer:shapeLayer];
}
-(void)drawRoverPoint:(double)degrees fromBLE:(BOOL)ble{
    int step = 1;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(previousX, previousY)];
    
    previousX = previousX + (step * cos([self degreesToRadians:degrees]));
    previousY = previousY + (step * sin([self degreesToRadians:degrees]));
    
    [path addLineToPoint:CGPointMake(previousX,previousY)];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [path CGPath];
    shapeLayer.strokeColor = [ble ? [UIColor blackColor] : [UIColor redColor] CGColor];
    shapeLayer.lineWidth = 1.5;
    shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    [self.view.layer addSublayer:shapeLayer];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)heading {
    
    if(NSDate.date.timeIntervalSince1970 - timerCompass < 0.1){
        return;
    }
    timerCompass = NSDate.date.timeIntervalSince1970;
    NSInteger newHeading = heading.magneticHeading; //in degrees
    [self drawRoverPoint:newHeading fromBLE:NO];
}

#pragma mark - UIViewDelegates
-(void)viewDidLoad {
    [super viewDidLoad];
    [self setupLocationManager];
    timerCompass = NSDate.date.timeIntervalSince1970;
    
    previousX = self.view.frame.size.width / 2;
    previousY = self.view.frame.size.height / 2;
    
    bleShield = [[BLE alloc] init];
    [bleShield controlSetup];
    bleShield.delegate = self;
}
-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
