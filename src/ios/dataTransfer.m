#import "dataTransfer.h"

@implementation dataTransfer
@synthesize callbackID;

- (void)upload:(CDVInvokedUrlCommand *)command {
    self.callbackID = [command callbackId];
    NSString *postURL = [[command arguments] objectAtIndex:0];
    NSDictionary *postData = [[command arguments] objectAtIndex:1];
    
    NSString *photoPath = [[command arguments] objectAtIndex:2];
    NSFileManager *file = [NSFileManager defaultManager];
    
    if ([file fileExistsAtPath:photoPath] == YES) {
        NSLog(@"file is Exists!");
        [file contentsAtPath:photoPath];
    }
    
    NSDictionary *fileAttr = [file attributesOfItemAtPath:photoPath error:NULL];
    if(fileAttr!=nil){
        NSLog(@"文件大小:%llu bytes",[[fileAttr objectForKey:NSFileSize] unsignedLongLongValue]);
    }
    
    
    NSLog(@"%@", postURL);
    NSLog(@"%@", postData);
    
    //[self startRequest:postURL withPostData:postData];
}
- (void)startRequest:(NSString *)strURL withPostData:(NSDictionary *)data {
    NSLog(@"startRequest!");
    
    strURL = [strURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *postURL = [NSURL URLWithString:strURL];
    NSString *postString = [[NSString alloc] init];
    NSString *strData = [[NSString alloc] init];
    NSData *jsonData = [[NSData alloc] init];
    NSString *json;
    NSError *error;
    
    NSEnumerator *dataKey = [data keyEnumerator];
    for (NSObject *param in dataKey) {
        //NSLog(@"%@", [NSJSONSerialization isValidJSONObject:[data objectForKey:param]]?@"YES":@"NO");
        if ([NSJSONSerialization isValidJSONObject:[data objectForKey:param]]) {
            jsonData = [NSJSONSerialization dataWithJSONObject:[data objectForKey:param] options:NSJSONWritingPrettyPrinted error:&error];
            json = [[NSString alloc] initWithData: jsonData encoding:NSUTF8StringEncoding];
            strData = [NSString stringWithFormat:@"&%@=%@", param, json];
            postString = [postString stringByAppendingString:strData];
        } else {
            strData = [NSString stringWithFormat:@"&%@=%@", param, [data objectForKey:param]];
            postString = [postString stringByAppendingString:strData];
        }
    }
    
    NSLog(@"%@", postString);
    
    NSLog(@"Traversal success!");
    
    NSString *httpHeader = @"Content-type";
    NSString *httpValue = @"application/x-www-form-urlencoded";
    httpHeader = [httpHeader stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    httpValue = [httpValue stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:postURL];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    //[request setValue:httpValue forHTTPHeaderField:httpHeader];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (connection) {
        self.responseData = [NSMutableData new];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(nonnull NSData *)data {
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(nonnull NSError *)error {
    NSLog(@"%@",[error localizedDescription]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"upload is done!");
    NSError *error;
    
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingAllowFragments error:&error];
    
    //NSDictionary *status = [response objectForKey:@"status"];
    //NSString *error_desc = @"error_desc";
    //NSLog(@"%@", status);
    //NSLog(@"%@", [status objectForKey: error_desc]);
    
    NSString* callbackId = self.callbackID;
    
    CDVPluginResult* pluginResult = [CDVPluginResult
                                     resultWithStatus:CDVCommandStatus_OK
                                     messageAsDictionary:response];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}
@end