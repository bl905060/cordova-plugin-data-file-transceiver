//
//  dataTransfer.h
//  showapp
//
//  Created by LEIBI on 10/10/15.
//
//

#import <Cordova/CDV.h>

@interface dataTransfer : CDVPlugin <NSURLSessionDelegate, NSURLSessionTaskDelegate>

@property (strong, nonatomic) NSMutableData *responseData;
@property(strong, nonatomic) NSString* callbackID;

- (void)upload:(CDVInvokedUrlCommand*)command;

@end