//
//  RBMainWindowDelegate.m
//  RiakBrowser
//
//  Created by ilja on 24.03.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import "RBMainWindowDelegate.h"

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"

@interface RBMainWindowDelegate ()

@property (strong) NSMutableDictionary	*requestParameters;
@property (assign) NSInteger			lastStatusCode;
@property (strong) NSString				*lastErrorMessage;

@property (weak) IBOutlet NSArrayController *secondaryIndexesController;

@end

@implementation RBMainWindowDelegate

- (id)init
{
    self = [super init];
    if (self)
	{
        self.requestParameters = [NSMutableDictionary dictionary];
		self.requestParameters[@"contentType"] = @"application/json";
		self.requestParameters[@"host"] = @"http://localhost";
		self.requestParameters[@"port"] = @"8098";
		self.requestParameters[@"bucket"] = @"my-bucket";
		self.requestParameters[@"key"] = @"123";
		self.requestParameters[@"secondaryIndexes"] = [NSMutableArray array];
    }
    return self;
}

- (IBAction)putAction:(id)sender
{
	AFHTTPClient *client = [self httpClientFromCurrentRequestParameters];
	
	NSMutableURLRequest *request = [client requestWithMethod:@"PUT" path:[self pathFromCurrentRequestParameters] parameters:nil];
	
	if ([self.requestParameters[@"content"] string])
	{
		[request setHTTPBody:[[self.requestParameters[@"content"] string] dataUsingEncoding:NSUTF8StringEncoding]];
		[request addValue:self.requestParameters[@"contentType"] forHTTPHeaderField:@"Content-Type"];
	}
	[self addSecondaryIndexesToRequest:request];
	AFHTTPRequestOperation *operation = [client HTTPRequestOperationWithRequest:request
																		success:^(AFHTTPRequestOperation *operation, id responseObject) {
																			[self updateInterfaceWithHTTPResponse:[operation response]];
																		}
																		failure:^(AFHTTPRequestOperation *operation, NSError *error) {
																			[self updateInterfaceWithError:error HTTPResponse:[operation response]];
																		}];
    [client enqueueHTTPRequestOperation:operation];
}

- (IBAction)getAction:(id)sender
{
	[[self httpClientFromCurrentRequestParameters]getPath:[self pathFromCurrentRequestParameters]
											   parameters:nil
												  success:^(AFHTTPRequestOperation *operation, id responseObject) {
													  [self updateInterfaceWithHTTPResponse:[operation response]];
													  
													  NSString *receivedString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
													  if (receivedString)
													  {
														  self.requestParameters[@"content"] = [[NSAttributedString alloc] initWithString:receivedString];
													  }
													  else
													  {
														  self.requestParameters[@"content"] = [[NSAttributedString alloc] init];
													  }
												  }
												  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
													  [self updateInterfaceWithError:error HTTPResponse:[operation response]];
												  }];
}

- (NSString*) pathFromCurrentRequestParameters
{
	return [NSString stringWithFormat:@"riak/%@/%@", self.requestParameters[@"bucket"], self.requestParameters[@"key"]];
}

- (AFHTTPClient*) httpClientFromCurrentRequestParameters
{
	NSString *baseURLString = [NSString stringWithFormat:@"%@:%@",
							   self.requestParameters[@"host"],
							   self.requestParameters[@"port"]];
							   
	AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:baseURLString]];
		
	return client;
}

- (void) updateInterfaceWithHTTPResponse:(NSHTTPURLResponse*) inResponse
{
	self.lastStatusCode = [inResponse statusCode];
	self.lastErrorMessage = @"";
}

- (void) updateInterfaceWithError:(NSError*) inError HTTPResponse:(NSHTTPURLResponse*) inResponse
{
	self.lastStatusCode = [inResponse statusCode];
	self.lastErrorMessage = [inError localizedDescription];
}

- (IBAction)generateKey:(id)sender
{
	// Keep 10.7 folks happy, restrained from using NSUUID for now
	CFUUIDRef	uuidRef = CFUUIDCreate (kCFAllocatorDefault);
	CFStringRef stringRef = CFUUIDCreateString (kCFAllocatorDefault, uuidRef);
	
	self.requestParameters[@"key"] = [(__bridge NSString*)stringRef copy];
	
	CFRelease (uuidRef);
	CFRelease (stringRef);
}

- (IBAction)addSecondaryIndex:(id)sender
{
	NSMutableDictionary *indexDescription = [NSMutableDictionary dictionary];
	
	indexDescription[@"name"] = @"keyName";
	indexDescription[@"value"] = @"keyValue";
	indexDescription[@"type"] = @"Binary";

	[self.secondaryIndexesController addObject:indexDescription];
}

- (void) addSecondaryIndexesToRequest:(NSMutableURLRequest*) inRequest
{
	for (NSDictionary *keyDescription in self.requestParameters[@"secondaryIndexes"])
	{
		NSString *headerName;
		
		headerName = [NSString stringWithFormat:@"X-Riak-Index-%@_%@",
					  keyDescription[@"name"], [keyDescription[@"type"] isEqualToString:@"Binary" ]? @"bin":@"int"];
		
		[inRequest addValue:keyDescription[@"value"] forHTTPHeaderField:headerName];
	}
}

- (IBAction)clearSecondaryIndexes:(id)sender
{
	self.requestParameters[@"secondaryIndexes"] = [NSMutableArray array];
}

@end
