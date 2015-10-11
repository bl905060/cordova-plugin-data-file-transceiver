//
//  dataTransfer.m
//  showapp
//
//  Created by LEIBI on 10/10/15.
//
//

#import "dataTransfer.h"

@implementation dataTransfer
@synthesize callbackID;

- (void)upload:(CDVInvokedUrlCommand*)command
{
    
    //NSString* callbackId = [command callbackId];
    self.callbackID = [command callbackId];
    NSString* postURL = [[command arguments] objectAtIndex:0];
    //NSString* msg = [NSString stringWithFormat: @"Hello, %@", postURL];
    
    /*CDVPluginResult* result = [CDVPluginResult
     resultWithStatus:CDVCommandStatus_OK
     messageAsString:msg];*/
    
    [self startRequest:postURL];
    
    //[self success:result callbackId:callbackId];
}

- (void)startRequest:(NSString *)postURL {
    
    NSString *strURL = postURL;
    strURL = [strURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:strURL];
    NSString *post = [NSString stringWithFormat:@"testname=%@&testpasscode=%@",@"bl905060",@"12345678"];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (connection) {
        self.datas = [NSMutableData new];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(nonnull NSData *)data {
    [self.datas appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(nonnull NSError *)error {
    NSLog(@"%@",[error localizedDescription]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"upload is done!");
    NSError *error;
    
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:self.datas options:NSJSONReadingAllowFragments error:&error];
    NSString *error_desc = @"error_desc";
    NSDictionary *status = [response objectForKey:@"status"];
    
    NSLog(@"%@", status);
    NSLog(@"%@", [status objectForKey: error_desc]);
    
    NSString* callbackId = self.callbackID;
    
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsDictionary:response];
    
    [self success:result callbackId:callbackId];
}
@end