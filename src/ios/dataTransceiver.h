//
//  dataTransceiver.h
//  showapp
//
//  Created by LEIBI on 10/10/15.
//
//

#import <Cordova/CDV.h>

@interface dataTransceiver : CDVPlugin <NSURLSessionDelegate, NSURLSessionTaskDelegate>
{
    NSMutableData *responseData;
    NSString* callbackID;
}

//@property(strong, nonatomic) NSMutableData *responseData;
//@property(strong, nonatomic) NSString* callbackID;

- (void)upload:(CDVInvokedUrlCommand*)command;
- (void)download:(CDVInvokedUrlCommand*)command;

@end