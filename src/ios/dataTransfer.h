//
//  dataTransfer.h
//  showapp
//
//  Created by LEIBI on 10/10/15.
//
//

#import <Cordova/CDV.h>

@interface dataTransfer : CDVPlugin

@property (strong, nonatomic) NSMutableData *datas;

- (void) upload:(CDVInvokedUrlCommand*)command;

@end

