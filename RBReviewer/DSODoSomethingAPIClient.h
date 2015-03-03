//
//  DSODoSomethingAPIClient.h
//  RBReviewer
//
//  Created by Aaron Schachter on 12/11/14.
//  Copyright (c) 2014 DoSomething.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"

@interface DSODoSomethingAPIClient : AFHTTPSessionManager

@property (retain, nonatomic) NSDictionary *authHeaders;
@property (retain, nonatomic) NSString *serviceName;
@property (retain, nonatomic) NSString *serviceTokensName;
@property (retain, nonatomic) NSDictionary *user;


+ (DSODoSomethingAPIClient *)sharedClient;

- (instancetype)initWithBaseURL:(NSURL *)url;

-(void)loginWithUsername:(NSString *)username andPassword:(NSString *)password andCompletionHandler:(void(^)(NSDictionary *))completionHandler andErrorHandler:(void(^)(NSError *))errorHandler;

-(void)checkStatusWithCompletionHandler:(void(^)(NSDictionary *))completionHandler andErrorHandler:(void(^)(NSDictionary *))errorHandler;

- (void)getSingleInboxReportbackWithCompletionHandler:(void(^)(NSMutableArray *))completionHandler andTid:(NSInteger)tid;

- (void)getTermsWithCompletionHandler:(void(^)(NSMutableArray *))completionHandler;

- (void)logoutUserWithCompletionHandler:(void(^)(NSDictionary *))completionHandler;

- (void)postReportbackReviewWithCompletionHandler:(void(^)(NSArray *))completionHandler :(NSDictionary *)values;

- (NSDictionary *) getSavedLogin;

- (NSMutableDictionary *) getSavedTokens;

@end
