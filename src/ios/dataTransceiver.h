//
//  dataTransceiver.h
//  showapp
//
//  Created by LEIBI on 10/10/15.
//
//

#import <Cordova/CDV.h>
#import "sqlite3.h"
#import "operatePlist.h"
#import "KVNProgress.h"

@interface dataTransceiver : CDVPlugin <NSURLSessionDelegate, NSURLSessionTaskDelegate>
{
    NSMutableData *responseData;
    NSString *callbackID;
    NSString *operateFlag;
    NSString *receivedTimestamp;
    NSString *currentTimestamp;
    
    //NSString *postURL;
    //NSArray *photoURL;
    //NSArray *voiceURL;
    
    BOOL downloadFinish;
    
    sqlite3 *database;
}

//@property(strong, nonatomic) NSMutableData *responseData;
//@property(strong, nonatomic) NSString* callbackID;

- (void)upload:(CDVInvokedUrlCommand*)command;
- (void)download:(CDVInvokedUrlCommand*)command;

@end