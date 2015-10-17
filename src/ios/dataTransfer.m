#import "dataTransfer.h"

@implementation dataTransfer
@synthesize callbackID;

- (void)upload:(CDVInvokedUrlCommand *)command {
    self.callbackID = [command callbackId];
    NSString *postURL = [[command arguments] objectAtIndex:0];
    NSDictionary *postData = [[command arguments] objectAtIndex:1];
    NSArray *photoURL = [[NSArray alloc] initWithArray:[[command arguments] objectAtIndex:2]];
    NSArray *voiceURL = [[NSArray alloc] initWithArray:[[command arguments] objectAtIndex:3]];
    
    NSLog(@"%@", photoURL);
    NSLog(@"%@", voiceURL);
    NSLog(@"%@", postURL);
    NSLog(@"%@", postData);
    
    /*NSFileManager *file = [NSFileManager defaultManager];
     if ([file fileExistsAtPath:strPath] == YES) {
     NSLog(@"file is Exists!");
     [file contentsAtPath:strPath];
     }
     
     NSDictionary *fileAttr = [file attributesOfItemAtPath:strPath error:NULL];
     if(fileAttr!=nil){
     NSLog(@"文件大小:%llu bytes",[[fileAttr objectForKey:NSFileSize] unsignedLongLongValue]);
     }*/
    
    [self startRequest:postURL withPostData:postData withPhotoPath:photoURL withVoicePath:voiceURL];
}

- (void)startRequest:(NSString *)strURL
        withPostData:(NSDictionary *)postData
       withPhotoPath:(NSArray *)photoURL
       withVoicePath:(NSArray *)voiceURL {
    NSLog(@"startRequest!");
    
    strURL = [strURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:strURL]];
    NSMutableData *requestData = [NSMutableData data];
    NSData *jsonData = [[NSData alloc] init];
    NSString *jsonStr;
    NSError *error;
    
    NSString *boundaryMark = @"0xAAbbCCddEE";
    NSString *startBoundary = [[NSString alloc] initWithFormat:@"--%@", boundaryMark];
    NSString *endBoundary = [[NSString alloc] initWithFormat:@"%@--", startBoundary];
    NSMutableString *body = [[NSMutableString alloc] init];
    NSEnumerator *dataKey = [postData keyEnumerator];
    
    for (NSObject *param in dataKey) {
        NSLog(@"%@", [NSJSONSerialization isValidJSONObject:[postData objectForKey:param]]?@"YES":@"NO");
        if ([NSJSONSerialization isValidJSONObject:[postData objectForKey:param]]) {
            jsonData = [NSJSONSerialization dataWithJSONObject:[postData objectForKey:param] options:NSJSONWritingPrettyPrinted error:&error];
            jsonStr = [[NSString alloc] initWithData: jsonData encoding:NSUTF8StringEncoding];
            [body appendFormat:@"%@\r\n", startBoundary];
            [body appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param];
            [body appendFormat:@"%@\r\n", jsonStr];
        } else {
            [body appendFormat:@"%@\r\n", startBoundary];
            [body appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param];
            [body appendFormat:@"%@\r\n", [postData objectForKey:param]];
        }
    }
    
    NSLog(@"%@", body);
    
    NSMutableString *path = [[NSMutableString alloc] initWithString:[photoURL objectAtIndex:1]];
    
    [path deleteCharactersInRange:NSMakeRange(0, 7)];
    NSFileManager *file = [NSFileManager defaultManager];
    if ([file fileExistsAtPath:path] == YES) {
        NSLog(@"file is exists!");
        [file contentsAtPath:path];
    }
    NSData *photo = [[NSData alloc] initWithContentsOfFile:path];
    
    NSString *input = @"file";
    NSString *fname = [file displayNameAtPath:path];
    NSLog(@"file name: %@", fname);
    
    
    
    [body appendFormat:@"Content-Disposition: from-data; name=\"%@\"; filename=\"%@\"\r\n", input, fname];
    [body appendFormat:@"Content-Type: image/jpeg, image/gif, image/pjpeg\r\n\r\n"];
    NSString *end = [[NSString alloc] initWithFormat:@"\r\n%@", endBoundary];
    
    
    [requestData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [requestData appendData:photo];
    [requestData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSLog(@"Traversal success!");
    
    NSString *content = [[NSString alloc] initWithFormat:@"multipart/form-data; boundary=%@", boundaryMark];
    [request setValue:content forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    
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