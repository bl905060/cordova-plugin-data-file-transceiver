//
//  dataTransceiver.m
//  showapp
//
//  Created by LEIBI on 10/10/15.
//
//

#import "dataTransceiver.h"

@implementation dataTransceiver

- (void)upload:(CDVInvokedUrlCommand *)command {
    self->operateFlag = @"upload";
    self->callbackID = [command callbackId];
    NSString *postURL = [[command arguments] objectAtIndex:0];
    NSDictionary *postData = [[command arguments] objectAtIndex:1];
    NSArray *photoURL = [[NSArray alloc] initWithArray:[[command arguments] objectAtIndex:2]];
    NSArray *voiceURL = [[NSArray alloc] initWithArray:[[command arguments] objectAtIndex:3]];
    
    NSLog(@"photoURL: %@", photoURL);
    NSLog(@"voiceURL: %@", voiceURL);
    NSLog(@"postURL: %@", postURL);
    NSLog(@"postData: %@", postData);
    
    /*NSDictionary *fileAttr = [file attributesOfItemAtPath:strPath error:NULL];
     if(fileAttr!=nil){
     NSLog(@"文件大小:%llu bytes",[[fileAttr objectForKey:NSFileSize] unsignedLongLongValue]);
     }*/
    
    [self startUploadRequest:postURL withPostData:postData withPhotoPath:photoURL withVoicePath:voiceURL];
}

- (void)download:(CDVInvokedUrlCommand *)command {
    NSLog(@"begin to download!");
    
    self->operateFlag = @"download";
    self->callbackID = [command callbackId];
    NSString *postURL = [[command arguments] objectAtIndex:0];
    NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
    NSArray *photoURL = [[NSArray alloc] init];
    NSArray *voiceURL = [[NSArray alloc] init];
    operatePlist *readPlist = [[operatePlist alloc] init];
    downloadFinish = NO;
    
    if ([[command argumentAtIndex:1] isKindOfClass:[NSDictionary class]]) {
        postData = [[command arguments] objectAtIndex:1];
    }

    if (postData == nil || [postData count] == 0) {
        NSDictionary *info = [[NSDictionary alloc] initWithDictionary:[readPlist read:@"userinfo"]];
        NSMutableDictionary *tmp = [[NSMutableDictionary alloc] init];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
         if ([info objectForKey:@"errorStr"] == nil) {
            [tmp setObject:[info objectForKey:@"user_id"] forKey:@"user_id"];
            [tmp setObject:[info objectForKey:@"org_id"] forKey:@"org_id"];
            [tmp setObject:[info objectForKey:@"updateTimestamp"] forKey:@"timestamp"];
            [postData setObject:tmp forKey:@"json"];
        }
        else {
            NSLog(@"error: %@", [info objectForKey:@"errorStr"]);
        }
    }
    
    NSLog(@"photoURL: %@", photoURL);
    NSLog(@"voiceURL: %@", voiceURL);
    NSLog(@"postURL: %@", postURL);
    NSLog(@"postData: %@", postData);
    
    /*NSDictionary *fileAttr = [file attributesOfItemAtPath:strPath error:NULL];
     if(fileAttr!=nil){
     NSLog(@"文件大小:%llu bytes",[[fileAttr objectForKey:NSFileSize] unsignedLongLongValue]);
     }*/
    
    [self startUploadRequest:postURL withPostData:postData withPhotoPath:photoURL withVoicePath:voiceURL];
    [KVNProgress show];
}

- (void)startDownloadRequest:(NSArray *)downloadURL {
    NSLog(@"begin to download!");
}

- (void)startUploadRequest:(NSString *)strURL
        withPostData:(NSDictionary *)postData
       withPhotoPath:(NSArray *)photoURL
       withVoicePath:(NSArray *)voiceURL {
    NSLog(@"startRequest!");
    
    strURL = [strURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:strURL]];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    
    NSMutableData *requestData = [NSMutableData data];
    NSMutableString *photoPath = [[NSMutableString alloc] init];
    NSMutableString *voicePath = [[NSMutableString alloc] init];
    NSFileManager *fileHandle = [NSFileManager defaultManager];
    NSData *file = [[NSData alloc] init];
    NSData *jsonData = [[NSData alloc] init];
    NSString *jsonStr;
    NSString *inputType = [[NSString alloc] init];
    NSString *filename = [[NSString alloc] init];
    NSString *CRNL = @"\r\n";
    NSString *content;
    NSError *error;
    
    NSString *boundaryMark = @"0xAAbbCCddEE";
    NSString *startBoundary = [[NSString alloc] initWithFormat:@"--%@", boundaryMark];
    NSString *endBoundary = [[NSString alloc] initWithFormat:@"%@--", startBoundary];
    NSMutableString *body = [[NSMutableString alloc] init];
    NSEnumerator *dataKey = [postData keyEnumerator];
    
    for (NSObject *param in dataKey) {
        NSLog(@"%@", [NSJSONSerialization isValidJSONObject:[postData objectForKey:param]]?@"Is Json":@"Not Json");
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
    
    [requestData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"Parameters Assemble Success!");
    
    if (photoURL != nil) {
        NSLog(@"begin to handle photoURL!");
        for (int i = 0; i < [photoURL count]; i++) {
            photoPath = [NSMutableString stringWithFormat:@"%@", [photoURL objectAtIndex:i]];
            NSRange filePrefix = [photoPath rangeOfString:@"file://"];
            if (filePrefix.length > 0) {
                [photoPath deleteCharactersInRange:NSMakeRange(0, 7)];
                NSLog(@"%@", photoPath);
                
                if ([fileHandle fileExistsAtPath:photoPath] == YES) {
                    body = [[NSMutableString alloc] init];
                    [fileHandle contentsAtPath:photoPath];
                    file = [[NSData alloc] initWithContentsOfFile:photoPath];
                    inputType = [NSString stringWithFormat:@"file%d", (i)];
                    filename = [fileHandle displayNameAtPath:photoPath];
                    
                    [body appendFormat:@"%@\r\n", startBoundary];
                    [body appendFormat:@"Content-Disposition: from-data; name=\"%@\"; filename=\"%@\"\r\n", inputType, filename];
                    [body appendFormat:@"Content-Type: image/jpeg, image/gif, image/pjpeg\r\n\r\n"];
                    [requestData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
                    [requestData appendData:file];
                    [requestData appendData:[CRNL dataUsingEncoding:NSUTF8StringEncoding]];
                } else {
                    NSLog(@"photograph is not exist!");
                }
            } else {
                NSLog(@"photo file URL is worng!");
            }
        }
    }
    
    NSLog(@"Photo Assemble Success!");
    
    if (voiceURL != nil) {
        NSLog(@"begin to handle voiceURL!");
        for (int i = 0; i < [voiceURL count]; i++) {
            voicePath = [NSMutableString stringWithFormat:@"%@", [voiceURL objectAtIndex:i]];
            NSRange filePerfix = [voicePath rangeOfString:@"file://"];
            if (filePerfix.length > 0) {
                [voicePath deleteCharactersInRange:NSMakeRange(0, 7)];
                NSLog(@"%@", voicePath);
                
                if ([fileHandle fileExistsAtPath:voicePath] == YES) {
                    body = [[NSMutableString alloc] init];
                    [fileHandle contentsAtPath:voicePath];
                    file = [[NSData alloc] initWithContentsOfFile:voicePath];
                    inputType = [NSString stringWithFormat:@"voice%d", (i)];
                    filename = [fileHandle displayNameAtPath:voicePath];
                    
                    [body appendFormat:@"%@\r\n", startBoundary];
                    [body appendFormat:@"Content-Disposition: from-data; name=\"%@\"; filename=\"%@\"\r\n", inputType, filename];
                    [body appendFormat:@"Content-Type: image/jpeg, image/gif, image/pjpeg\r\n\r\n"];
                    [requestData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
                    [requestData appendData:file];
                    [requestData appendData:[CRNL dataUsingEncoding:NSUTF8StringEncoding]];
                } else {
                    NSLog(@"audio record is not exist!");
                }
            } else {
                NSLog(@"audio file URL is wrong!");
            }
        }
    }
    
    NSLog(@"Voice Assemble Success!");
    
    NSString *end = [[NSString alloc] initWithFormat:@"%@", endBoundary];
    [requestData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];
    
    content = [[NSString alloc] initWithFormat:@"multipart/form-data; boundary=%@", boundaryMark];
    [request setValue:content forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    
    NSURLSessionUploadTask *dataTask = [session uploadTaskWithRequest:request fromData:requestData];
    
    [dataTask resume];
    
    if (dataTask) {
        self->responseData = [NSMutableData new];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [self->responseData appendData:data];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSLog(@"%@", response);
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSLog(@"statusCode:%ld", (long)httpResponse.statusCode);
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    NSLog(@"upload is done!");

    NSString *callbackId = self->callbackID;
    CDVPluginResult *pluginResult;
    NSError *jsonError;
    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
    
    if ([operateFlag isEqualToString: @"upload"]) {
        response = [NSJSONSerialization JSONObjectWithData:self->responseData
                                                   options:NSJSONReadingAllowFragments
                                                     error:&jsonError];
        
        /*NSString *error_desc = @"error_desc";
         NSDictionary *status = [response objectForKey:@"status"];
         NSLog(@"%@", status);
         NSLog(@"%@", [status objectForKey: error_desc]);*/
        
        if (error) {
            NSLog(@"error description: %@", [error localizedDescription]);
            NSLog(@"error failure reason: %@", [error localizedFailureReason]);
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                             messageAsString:[error localizedDescription]];
        }
        else if (jsonError) {
            NSLog(@"response json analysis is fail!");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                             messageAsString:[jsonError localizedDescription]];
        }
        else {
            NSLog(@"data transceiver is OK!");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        
    }
    else if ([operateFlag isEqualToString:@"download"]) {
        response = [NSJSONSerialization JSONObjectWithData:self->responseData
                                                   options:NSJSONReadingAllowFragments
                                                     error:&jsonError];
        //NSLog(@"response data is : %@", response);
        NSDictionary *status = [[NSDictionary alloc] init];
        NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithDictionary:response];
        
        if (!downloadFinish) {
            status = [data valueForKey:@"status"];
            self->receivedTimestamp = [status valueForKey:@"timestamp"];
            [data removeObjectForKey:@"status"];
            [self saveData:data];
            
            downloadFinish = YES;
            NSString *postURL = @"http://115.159.76.70/dingdong/index.php/Home/Getdata/getbill";
            NSArray *photoURL = [[NSArray alloc] init];
            NSArray *voiceURL = [[NSArray alloc] init];
            NSMutableArray *queryResult = [[NSMutableArray alloc] init];
            NSMutableDictionary *secondRequestData = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *tmpData = [[NSMutableDictionary alloc] init];
            
            NSString *sql = @"select user_id, org_id, contact_userid, contact_orgid, timestamp, busy, dirty from myshop_contact";
            queryResult = [self searchData:sql];
            [tmpData setObject:queryResult forKey:@"data"];
            sql = @"select * from myshop_contactagent";
            queryResult = [self searchData:sql];
            [tmpData setObject:queryResult forKey:@"contactagent"];
            [secondRequestData setObject:tmpData forKey:@"json"];
            [self startUploadRequest:postURL
                        withPostData:secondRequestData
                       withPhotoPath:photoURL
                       withVoicePath:voiceURL];
        }
        else {
            NSMutableDictionary *secondResponseData = [[NSMutableDictionary alloc] init];
            NSArray *records = [[NSArray alloc] init];
            NSMutableArray *tmp = [[NSMutableArray alloc] init];
            //NSMutableArray *value = [[NSMutableArray alloc] init];
            
            NSArray *key = [data allKeys];
            for (int i = 0; i < [data count]; i++) {//提取出所有联系人的数据
                records = [data objectForKey:[key objectAtIndex:i]];
                for (NSDictionary *table in records) {//提取出每个联系人的数据
                    NSArray *tableName = [table allKeys];
                    for (int i = 0; i < [tableName count]; i++) {//提取出每个联系人的数据表
                        if ([secondResponseData objectForKey:[tableName objectAtIndex:i]] == nil) {
                            if ([table objectForKey:[tableName objectAtIndex:i]] == [NSNull null]) {
                                [secondResponseData setObject:[tmp mutableCopy]
                                                       forKey:[NSString stringWithString:[tableName objectAtIndex:i]]];
                            } else if (!([[tableName objectAtIndex:i] isEqualToString:@"status"])) {
                                NSLog(@"%@", [table objectForKey:[tableName objectAtIndex:i]]);
                                [secondResponseData setObject:[NSMutableArray arrayWithArray:[table objectForKey:[tableName objectAtIndex:i]]]
                                                       forKey:[NSString stringWithString:[tableName objectAtIndex:i]]];
                            }
                        } else if ([table objectForKey:[tableName objectAtIndex:i]] != [NSNull null]){
                            [[secondResponseData objectForKey:[tableName objectAtIndex:i]] addObjectsFromArray:[table objectForKey:[tableName objectAtIndex:i]]];
                        }
                    }
                }
            }
            [KVNProgress showSuccess];
            [self saveData:secondResponseData];
            
            operatePlist *writePlist = [[operatePlist alloc] init];
            NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys: self->currentTimestamp, @"updateTimestamp", nil];
            
            [writePlist write:@"userinfo" withInfo: info];
        }
    }
}

- (void)saveData:(NSMutableDictionary *)response {
    NSLog(@"begin to save database!");
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    self->currentTimestamp = [dateFormat stringFromDate:[NSDate date]];
    NSString *newTimestamp07 = [dateFormat stringFromDate:[[NSDate date] initWithTimeInterval:-7*24*60*60 sinceDate:[NSDate date]]];
    NSString *newTimestamp14 = [dateFormat stringFromDate:[[NSDate date] initWithTimeInterval:-14*24*60*60 sinceDate:[NSDate date]]];
    
    NSArray *checkList = [[NSArray alloc] initWithObjects:@"myshop_brands",
                          @"myshop_category",
                          @"myshop_company",
                          @"myshop_contact",
                          @"myshop_basiccontact",
                          @"myshop_contactagent",
                          @"myshop_logistics",
                          @"myshop_manufacturer",
                          @"myshop_units",
                          @"myshop_simplegoods",
                          @"myshop_positions",
                          @"myshop_users",
                          @"myshop_photo",
                          @"myshop_voice",
                          @"myshop_staff",
                          @"myshop_salesbill",
                          @"myshop_salesbilldetail",
                          @"myshop_deliverybill",
                          @"myshop_deliverybilldetail",
                          @"myshop_deliveryrelationbill",
                          @"myshop_collectionbill",
                          @"myshop_collectionrelationbill",
                          @"myshop_issueinvoicebill",
                          @"myshop_issueinvoicerelationbill",
                          @"myshop_purchasebill",
                          @"myshop_purchasebilldetail",
                          @"myshop_takeoverbill",
                          @"myshop_takeoverbilldetail",
                          @"myshop_takeoverrelationbill",
                          @"myshop_paymentbill",
                          @"myshop_paymentrelationbill",
                          @"myshop_receiveinvoicebill",
                          @"myshop_receiveinvoicerelationbill",
                          @"myshop_ticketbill",
                          @"myshop_demands",
                          @"myshop_demandreplies",
                          @"myshop_supply",
                          @"myshop_supplyreplies",
                          @"myshop_CART",
                          @"myshop_implementation",
                          @"myshop_statusupdate",
                          @"myshop_msg",
                          @"myshop_sysmsg",
                          @"myshop_contactagenttimestamp",
                          nil];
    NSString *folderName = [[NSString alloc] init];
    NSString *writableDBPath = [self GetPathByFolderName:folderName withFileName:@"myshop"];
    //NSLog(@"database path is : %@", writableDBPath);
    
    //生成contactagenttimestamp表
    if ([response objectForKey:@"contactList"] != nil) {
        NSMutableArray *myshop_contactagenttimestamp = [[NSMutableArray alloc] initWithArray:[response objectForKey:@"contactList"] copyItems:YES];//取出所有记录
        NSArray *removeKeys = [[NSArray alloc] initWithObjects:@"contact_id", @"contact_name", @"contact_mobile", @"contact_email", @"contact_org", @"contact_position", @"contact_phone", @"contact_fax", @"contact_QQ", @"contact_addr", @"contact_remark", @"contact_photoid", @"contact_type", @"from_userid", @"delflag", @"leaveflag", nil];
        NSMutableDictionary *records;
        for (int i = 0; i < [myshop_contactagenttimestamp count]; i++) {//读取每条记录的字段
            records = [NSMutableDictionary dictionaryWithDictionary:[myshop_contactagenttimestamp objectAtIndex:i]];
            [records removeObjectsForKeys:removeKeys];
            [myshop_contactagenttimestamp replaceObjectAtIndex:i withObject:records];
        }
        [response setObject:myshop_contactagenttimestamp forKey:@"contactagenttimestampList"];
    }
    
    /*if ([response objectForKey:@"voice"] != nil) {
        operatePlist *writePlist = [[operatePlist alloc] init];
        NSMutableDictionary * key = [[NSMutableDictionary alloc] init];
        NSArray *param = [[NSArray alloc] init];
        
        NSArray *voice = [[NSArray alloc] initWithArray:[response objectForKey:@"voice"]];
        for (int i = 0; i < [voice count]; i++) {
            key = [NSMutableDictionary dictionaryWithDictionary:[voice objectAtIndex:i]];
            param = [key allKeys];
            for (int j = 0; j < [param count]; j++) {
                if ([key objectForKey:[param objectAtIndex:j]] == [NSNull null] ||
                    [[key objectForKey:[param objectAtIndex:j]] isEqualToString:@""]) {
                    [key setObject:@"NULL" forKey:[param objectAtIndex:j]];
                }
            }
            [writePlist write:@"voice" withInfo:key];
        }
        
        NSArray *purchasebillList = [[NSArray alloc] initWithArray:[response objectForKey:@"purchasebillList"]];
        [writePlist write:@"purchasebillList" withArray:purchasebillList];
        
        NSArray *receiveinvoicebillList = [[NSArray alloc] initWithArray:[response objectForKey:@"receiveinvoicebillList"]];
        [writePlist write:@"receiveinvoicebillList" withArray:receiveinvoicebillList];
        
        NSArray *ticketbillList = [[NSArray alloc] initWithArray:[response objectForKey:@"ticketbillList"]];
        [writePlist write:@"ticketbillList" withArray:ticketbillList];
        
        NSArray *issueinvoicebillList = [[NSArray alloc] initWithArray:[response objectForKey:@"issueinvoicebillList"]];
        [writePlist write:@"issueinvoicebillList" withArray:issueinvoicebillList];
        
        NSArray *supplyList = [[NSArray alloc] initWithArray:[response objectForKey:@"supplyList"]];
        [writePlist write:@"supplyList" withArray:supplyList];
    }*/
    
    NSMutableString *tableName;
    NSArray *allTableKeys = [response allKeys];
    int tableCount = (int)[response count];
    NSArray *allRecordKeys;
    int columnCount;
    int recordCount;
    
    //NSLog(@"all list: %@", allKeys);
    //NSLog(@"list count: %i", count);
    
    NSMutableString *initInsertSql = [[NSMutableString alloc] init];
    NSMutableString *initInsertValues = [[NSMutableString alloc] init];
    NSMutableString *initUpdateSql = [[NSMutableString alloc] init];
    NSMutableString *initUpdateValues = [[NSMutableString alloc] init];
    NSMutableArray *insertSql = [[NSMutableArray alloc] init];
    NSMutableArray *insertRecords = [[NSMutableArray alloc] init];
    NSMutableArray *updateSql = [[NSMutableArray alloc] init];
    NSMutableArray *updateRecords = [[NSMutableArray alloc] init];
    NSMutableArray *insertColumn = [[NSMutableArray alloc] init];
    NSMutableArray *updateColumn = [[NSMutableArray alloc] init];
    NSMutableString *checkSql = [[NSMutableString alloc] init];
    NSMutableString *checkWhere = [[NSMutableString alloc] init];
    NSMutableArray *checkRecord = [[NSMutableArray alloc] init];
    NSArray *table = [[NSArray alloc] init];
    NSMutableDictionary *record;

    const char* cpath = [writableDBPath UTF8String];
    if (sqlite3_open(cpath, &database) != SQLITE_OK) {
        sqlite3_close(database);
        NSAssert(NO, @"open database is filure!");
    } else {
        for (int i = 0; i < tableCount; i++) {//提取每张数据表
            if ([response objectForKey:[allTableKeys objectAtIndex:i]] == [NSNull null]) continue;
            table = [response objectForKey:[allTableKeys objectAtIndex:i]];
            if ([[allTableKeys objectAtIndex:i] isEqualToString:@"voice"] || [[allTableKeys objectAtIndex:i] isEqualToString:@"photo"]) {
                tableName = [[NSMutableString alloc] initWithFormat:@"myshop_%@", [allTableKeys objectAtIndex:i]];
            }
            else if ([[allTableKeys objectAtIndex:i] isEqualToString:@"contactdemandrepliesList"] ||
                     [[allTableKeys objectAtIndex:i] isEqualToString:@"contactsupplyList"] ||
                     [[allTableKeys objectAtIndex:i] isEqualToString:@"contactdemandsList"] ||
                     [[allTableKeys objectAtIndex:i] isEqualToString:@"contactsupplyrepliesList"] ) {
                tableName = [[NSMutableString alloc] initWithFormat:@"myshop_%@", [allTableKeys objectAtIndex:i]];
                [tableName deleteCharactersInRange:[tableName rangeOfString:@"List"]];
                [tableName deleteCharactersInRange:[tableName rangeOfString:@"contact"]];
            }
            else {
                tableName = [[NSMutableString alloc] initWithFormat:@"myshop_%@", [allTableKeys objectAtIndex:i]];
                [tableName deleteCharactersInRange:[tableName rangeOfString:@"List"]];
                if ([tableName isEqualToString:@"myshop_takeoverrelation"] ||
                    [tableName isEqualToString:@"myshop_deliveryrelation"]) {
                    [tableName appendString:@"bill"];
                }
            }
            NSLog(@"table name is: %@", tableName);
            
            recordCount = (int)[table count];
            for (int j = 0; j < recordCount; j++) {//提取每条记录
                record = [[NSMutableDictionary alloc] initWithDictionary:[table objectAtIndex:j]];
                [record removeObjectForKey:@"ID"];
                allRecordKeys = [record allKeys];
                columnCount = (int)[record count];

                //创建SQL语句，并生成校验查询语句
                initInsertSql = [NSMutableString stringWithFormat:@"INSERT INTO %@ (", tableName];
                initInsertValues = [NSMutableString stringWithString:@""];
                //NSLog(@"preInsertSql: %@", preInsertSql);
                
                initUpdateSql = [NSMutableString stringWithFormat:@"UPDATE %@ SET", tableName];
                initUpdateValues = [NSMutableString stringWithString:@""];
                //NSLog(@"initUpdateSql: %@", initUpdateSql);
                
                switch ([checkList indexOfObject:tableName]) {//生成校验查询语句
                    case 0:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_brands"];
                        checkWhere = [NSMutableString stringWithString:@" where brand_id = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"brand_id"],
                                       nil];
                        break;
                    case 1:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_category"];
                        checkWhere = [NSMutableString stringWithString:@" where category_id = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"category_id"],
                                       nil];
                        break;
                    case 2:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_company"];
                        checkWhere = [NSMutableString stringWithString:@" where company_id = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"company_id"],
                                       nil];
                        break;
                    case 3:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_contact"];
                        checkWhere = [NSMutableString stringWithString:@" where user_id = ? and org_id = ? and contact_orgid = ? and contact_userid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"user_id"],
                                       [record objectForKey:@"org_id"],
                                       [record objectForKey:@"contact_orgid"],
                                       [record objectForKey:@"contact_userid"],
                                       nil];
                        break;
                    case 4:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_basiccontact"];
                        checkWhere = [NSMutableString stringWithString:@" where user_id = ? and contact_userid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"user_id"],
                                       [record objectForKey:@"contact_userid"],
                                       nil];
                        break;
                    case 5:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_contactagent"];
                        checkWhere = [NSMutableString stringWithString:@" where contactagentid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"contactagentid"],nil];
                        break;
                    case 6:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_logistics"];
                        checkWhere = [NSMutableString stringWithString:@" where logistics_id = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"logistics_id"],
                                       nil];
                        break;
                    case 7:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_manufacturer"];
                        checkWhere = [NSMutableString stringWithString:@" where manufacturer_id = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"manufacturer_id"], nil];
                        break;
                    case 8:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_units"];
                        checkWhere = [NSMutableString stringWithString:@" where unit_id = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"unit_id"],nil];
                        break;
                    case 9:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_simplegoods"];
                        checkWhere = [NSMutableString stringWithString:@" where goods_id = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"goods_id"],
                                       nil];
                        break;
                    case 10:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_positions"];
                        checkWhere = [NSMutableString stringWithString:@" where position_id = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"position_id"],
                                       nil];
                        break;
                    case 11:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_users"];
                        checkWhere = [NSMutableString stringWithString:@" where user_id = ? and org_id = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"user_id"],
                                       [record objectForKey:@"org_id"],
                                       nil];
                        break;
                    case 12:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_photo"];
                        checkWhere = [NSMutableString stringWithString:@" where photo_id = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"photo_id"],
                                       nil];
                        break;
                    case 13:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_voice"];
                        checkWhere = [NSMutableString stringWithString:@" where voice_id = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"voice_id"],
                                       nil];
                        break;
                    case 14:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_staff"];
                        checkWhere = [NSMutableString stringWithString:@" where org_id = ? and user_id = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"org_id"],
                                       [record objectForKey:@"user_id"],
                                       nil];
                        break;
                    case 15:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_salesbill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 16:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_salesbilldetail"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 17:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_deliverybill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 18:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_deliverybilldetail"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 19:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_deliveryrelationbill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 20:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_collectionbill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 21:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_collectionrelationbill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 22:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_issueinvoicebill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 23:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_issueinvoicerelationbill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 24:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_purchasebill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 25:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_purchasebilldetail"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 26:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_takeoverbill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 27:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_takeoverbilldetail"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 28:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_takeoverrelationbill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 29:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_paymentbill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 30:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_paymentrelationbill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 31:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_receiveinvoicebill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 32:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_receiveinvoicerelationbill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 33:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_ticketbill"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 34:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_demands"];
                        checkWhere = [NSMutableString stringWithString:@" where demandsid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"demandsid"],
                                       nil];
                        break;
                    case 35:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_demandreplies"];
                        checkWhere = [NSMutableString stringWithString:@" where replyid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"replyid"],
                                       nil];
                        break;
                    case 36:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_supply"];
                        checkWhere = [NSMutableString stringWithString:@" where publishid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"publishid"],
                                       nil];
                        break;
                    case 37:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_supplyreplies"];
                        checkWhere = [NSMutableString stringWithString:@" where replyid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"replyid"],
                                       nil];
                        break;
                    /*case 38:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_CART"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 39:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_implementation"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;
                    case 40:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_statusupdate"];
                        checkWhere = [NSMutableString stringWithString:@" where billid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"billid"],
                                       nil];
                        break;*/
                    case 41:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_msg"];
                        checkWhere = [NSMutableString stringWithString:@" where messageid = ? and msgowner_orgid = ? and msgowner_userid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"messageid"],
                                       [record objectForKey:@"msgowner_orgid"],
                                       [record objectForKey:@"msgowner_userid"],
                                       nil];
                        break;
                    case 42:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_sysmsg"];
                        checkWhere = [NSMutableString stringWithString:@" where messageid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"messageid"],
                                       nil];
                        break;
                    case 43:
                        checkSql = [NSMutableString stringWithString:@"select count(*) as count from myshop_contactagenttimestamp"];
                        checkWhere = [NSMutableString stringWithString:@" where user_id = ? and org_id = ? and contact_orgid = ? and contact_userid = ?"];
                        [checkSql appendString:checkWhere];
                        checkRecord = [NSMutableArray arrayWithObjects:[record objectForKey:@"user_id"],
                                       [record objectForKey:@"org_id"],
                                       [record objectForKey:@"contact_orgid"],
                                       [record objectForKey:@"contact_userid"],
                                       nil];
                        break;
                    default:
                    NSLog(@"Error! out of check list!");
                    break;
                }
                
                //NSLog(@"check sql: %@", checkSql);
                //NSLog(@"check record: %@", checkRecord);
                
                //NSLog(@"%@", allRecordKeys);
                if ([self checkData:checkRecord withSql:checkSql]) {
                    for (int k = 0; k < columnCount; k++) {//记录已存在，提取每个字段进行更新操作
                        [initUpdateValues appendFormat:@" %@ = ?,", [allRecordKeys objectAtIndex:k]];
                        if ([record objectForKey:[allRecordKeys objectAtIndex:k]] == [NSNull null]) {
                            [updateColumn addObject:@"NULL"];
                        }
                        else {
                            [updateColumn addObject:[record objectForKey:[allRecordKeys objectAtIndex:k]]];
                        }
                    }
                } else {
                    for (int k = 0; k < columnCount; k++) {//该记录不存在，提取每个字段进行插入操作
                        if (k == (columnCount - 1)) {//拼接SQL语句
                            [initInsertSql appendFormat:@"%@) VALUES ", [allRecordKeys objectAtIndex:k]];
                            //needToCompose = NO;
                        } else {
                            [initInsertSql appendFormat:@"%@, ", [allRecordKeys objectAtIndex:k]];
                        }
                        
                        if (k == 0) {
                            [initInsertValues appendString:@"(?, "];
                        } else if (k == (columnCount - 1)) {
                            [initInsertValues appendString:@"?), "];
                        } else {
                            [initInsertValues appendString:@"?, "];
                        }
                        
                        if ([tableName isEqualToString:@"myshop_contactagent"] && [[allRecordKeys objectAtIndex:k] isEqualToString:@"timestamp"]) {
                            [insertColumn addObject:newTimestamp14];
                        }
                        else if ([tableName isEqualToString:@"myshop_contactagenttimestamp"] && [[allRecordKeys objectAtIndex:k] isEqualToString:@"timestamp"]) {
                            [insertColumn addObject:newTimestamp07];
                        }
                        else if ([record objectForKey:[allRecordKeys objectAtIndex:k]] == [NSNull null]) {
                            [insertColumn addObject:@"NULL"];
                        }
                        else {
                            [insertColumn addObject:[record objectForKey:[allRecordKeys objectAtIndex:k]]];
                        }
                        //NSLog(@"%@", insertColumn);
                    }
                    //NSLog(@"%@", initInsertValues);
                }
                if ([updateColumn count]) {
                    [initUpdateSql appendString:initUpdateValues];
                    [initUpdateSql deleteCharactersInRange:NSMakeRange(([initUpdateSql length] - 1), 1)];
                    [initUpdateSql appendString:checkWhere];
                    [updateColumn addObjectsFromArray:checkRecord];
                    [updateRecords addObject:[updateColumn mutableCopy]];
                    [updateSql addObject:[initUpdateSql mutableCopy]];
                }
                [updateColumn removeAllObjects];
                initUpdateValues = [NSMutableString stringWithString:@""];
                
                if ([insertColumn count]) {
                    [initInsertSql appendString:initInsertValues];
                    [initInsertSql deleteCharactersInRange:NSMakeRange(([initInsertSql length] - 2), 1)];
                    [insertRecords addObject:[insertColumn mutableCopy]];
                    [insertSql addObject:[initInsertSql mutableCopy]];
                }
                [insertColumn removeAllObjects];
                initInsertValues = [NSMutableString stringWithString:@""];
            }
        }
        //NSLog(@"%@", insertSql);
        //NSLog(@"%@", insertRecords);
        //NSLog(@"%@", updateSql);
        //NSLog(@"%@", updateRecords);
        
        if ([insertSql count]) {
            [self insertData:insertRecords withSql:insertSql];
        }
        if ([updateSql count]) {
            [self updateData:updateRecords withSql:updateSql];
        }
        
        sqlite3_close(database);
    }
}

- (void)insertData:(NSMutableArray *)record withSql:(NSMutableArray *)sql{
    //NSLog(@"begin to insert records into database");
    
    NSArray *column = [[NSArray alloc] init];
    bool resultStatus = false;
    char *errorMsg;
    @try {
        if (sqlite3_exec(database, "BEGIN", NULL, NULL, &errorMsg) == SQLITE_OK) {
            NSLog(@"sqlite transaction is launch!");
            sqlite3_free(errorMsg);
            
            sqlite3_stmt *statement;
            //NSLog(@"%lu", (unsigned long)[sql count]);
            for (int i = 0; i < [sql count]; i++) {
                //NSLog(@"%@", [sql objectAtIndex:i]);
                if (sqlite3_prepare_v2(database, [[sql objectAtIndex:i] UTF8String], -1, &statement, NULL) == SQLITE_OK) {
                    column = [record objectAtIndex:i];
                    for (int j = 0; j < [column count]; j++) {
                        //NSLog(@"%@", [column objectAtIndex:j]);
                        sqlite3_bind_text(statement, (j+1), [[column objectAtIndex:j] UTF8String], -1, NULL);
                    }
                    if (sqlite3_step(statement) == SQLITE_DONE) {
                        resultStatus = YES;
                        sqlite3_finalize(statement);
                    } else {
                        resultStatus = NO;
                    }
                }
                else {
                    NSLog(@"Error: %s", sqlite3_errmsg(database));
                    NSAssert1(0, @"Error: %s", sqlite3_errmsg(database));
                }
            }
            if (sqlite3_exec(database, "COMMIT", NULL, NULL, &errorMsg) == SQLITE_OK) {
                NSLog(@"sqlite transaction commit success!");
            }
            sqlite3_free(errorMsg);
        } else {
            NSLog(@"Error: %s", sqlite3_errmsg(database));
            NSAssert1(0, @"Error: %s", sqlite3_errmsg(database));
            sqlite3_free(errorMsg);
        }
    }
    @catch (NSException *exception) {
        if (sqlite3_exec(database, "ROLLBACK", NULL, NULL, &errorMsg) == SQLITE_OK) {
            NSLog(@"sqilte transaction is rollback!");
        }
    }
    @finally {
        
    }
}

- (void)updateData:(NSMutableArray *)record withSql:(NSMutableArray *)sql{
    //NSLog(@"begin to update records in database");
    
    NSArray *column = [[NSArray alloc] init];
    bool resultStatus = false;
    char *errorMsg;
    @try {
        if (sqlite3_exec(database, "BEGIN", NULL, NULL, &errorMsg) == SQLITE_OK) {
            NSLog(@"sqlite transaction is launch!");
            sqlite3_free(errorMsg);
            
            sqlite3_stmt *statement;
            //NSLog(@"%lu", (unsigned long)[sql count]);
            for (int i = 0; i < [sql count]; i++) {
                //NSLog(@"%@", [sql objectAtIndex:i]);
                if (sqlite3_prepare_v2(database, [[sql objectAtIndex:i] UTF8String], -1, &statement, NULL) == SQLITE_OK) {
                    column = [record objectAtIndex:i];
                    for (int j = 0; j < [column count]; j++) {
                        //NSLog(@"%@", [column objectAtIndex:j]);
                        sqlite3_bind_text(statement, (j+1), [[column objectAtIndex:j] UTF8String], -1, NULL);
                    }
                    if (sqlite3_step(statement) == SQLITE_DONE) {
                        resultStatus = YES;
                        sqlite3_finalize(statement);
                    } else {
                        resultStatus = NO;
                    }
                }
                else {
                    NSLog(@"Error: %s", sqlite3_errmsg(database));
                    NSAssert1(0, @"Error: %s", sqlite3_errmsg(database));
                }
            }
            if (sqlite3_exec(database, "COMMIT", NULL, NULL, &errorMsg) == SQLITE_OK) {
                NSLog(@"sqlite transaction commit success!");
            }
            sqlite3_free(errorMsg);
        } else {
            NSLog(@"Error: %s", sqlite3_errmsg(database));
            NSAssert1(0, @"Error: %s", sqlite3_errmsg(database));
            sqlite3_free(errorMsg);
        }
    }
    @catch (NSException *exception) {
        if (sqlite3_exec(database, "ROLLBACK", NULL, NULL, &errorMsg) == SQLITE_OK) {
            NSLog(@"sqilte transaction is rollback!");
        }
    }
    @finally {
        
    }
}

- (BOOL)checkData:(NSMutableArray *)record withSql:(NSString *)sql{
    //NSLog(@"begin to check record is alread exist in database or not!");
    NSString *result = [[NSString alloc] init];
    const char *cSql = [sql UTF8String];
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(database, cSql, -1, &statement, NULL) == SQLITE_OK) {
        int i = 0;
        for (NSString *key in record) {
            const char *param= [key UTF8String];
            sqlite3_bind_text(statement, ++i, param, -1, NULL);
        }
        if (sqlite3_step(statement) == SQLITE_ROW) {
            char *buffData = (char *)sqlite3_column_text(statement, 0);
            result = [[NSString alloc] initWithUTF8String:buffData];
        }
    }
    sqlite3_finalize(statement);
    //NSLog(@"check result: %@", result?@"YES":@"NO");
    if ([result intValue] > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (NSMutableArray *)searchData:(NSString *)sql {
    //NSLog(@"begin to query database!");
    
    NSString *folderName = [[NSString alloc] init];
    NSString *writableDBPath = [self GetPathByFolderName:folderName withFileName:@"myshop"];

    NSMutableArray *result = [[NSMutableArray alloc] init];
    const char *cSql = [sql UTF8String];
    sqlite3_stmt *statement;
    
    const char* cpath = [writableDBPath UTF8String];
    if (sqlite3_open(cpath, &database) != SQLITE_OK) {
        sqlite3_close(database);
        NSAssert(NO, @"open database is filure!");
    } else {
        if (sqlite3_prepare_v2(database, cSql, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int num_clos = sqlite3_column_count(statement);
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:num_clos];
                if (num_clos > 0) {
                    for (int j = 0; j < num_clos; j++) {
                        const char *col_name = sqlite3_column_name(statement, j);
                        if (col_name) {
                            NSString *colName = [NSString stringWithUTF8String:col_name];
                            id value = nil;
                            switch (sqlite3_column_type(statement, j)) {
                                case SQLITE_INTEGER: {
                                    int i_value = sqlite3_column_int(statement, j);
                                    value = [NSNumber numberWithInt:i_value];
                                    break;
                                }
                                case SQLITE_FLOAT: {
                                    double d_value = sqlite3_column_double(statement, j);
                                    value = [NSNumber numberWithDouble:d_value];
                                    break;
                                }
                                case SQLITE_TEXT: {
                                    char *c_value = (char *)sqlite3_column_text(statement, j);
                                    value = [[NSString alloc] initWithUTF8String:c_value];
                                    break;
                                }
                                case SQLITE_BLOB: {
                                    value = (__bridge id)(sqlite3_column_blob(statement, j));
                                    break;
                                }
                            }
                            if (value) {
                                [dict setObject:value forKey:colName];
                            }
                        }
                    }
                }
                [result addObject:dict];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }
    return result;
}

- (NSString *)GetPathByFolderName:(NSString *)_folderName withFileName:(NSString *)_fileName {
    //NSLog(@"begin to generate file path!");
    
    NSError *error;
    NSFileManager *filePath = [NSFileManager defaultManager];
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    directory = [directory stringByAppendingString: _folderName];
    
    if (![filePath fileExistsAtPath:directory]) {
        [filePath createDirectoryAtPath:directory
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:&error];
    }
    
    NSString *fileDirectory = [[[directory stringByAppendingPathComponent:_fileName]
                                stringByAppendingPathExtension:@"db"]
                               stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"%@",fileDirectory);
    return fileDirectory;
}
@end