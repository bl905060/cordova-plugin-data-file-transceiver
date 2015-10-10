//
//  dataTransfer.m
//  showapp
//
//  Created by LEIBI on 10/10/15.
//
//

#import "dataTransfer.h"

@implementation ConvertMedia

- (void) greet:(CDVInvokedUrlCommand*)command
{
    
    NSString* callbackId = [command callbackId];
    NSString* name = [[command arguments] objectAtIndex:0];
    NSString* msg = [NSString stringWithFormat: @"Hello, %@", name];
    
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:msg];
    
    NSLog(@"this is my first plugin!");
    
    [self success:result callbackId:callbackId];
}

@end