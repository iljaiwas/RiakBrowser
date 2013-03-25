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
@property (weak) IBOutlet NSPopover			*searchResultsPopover;
@property (weak) IBOutlet NSArrayController	*searchResultsController;
@property (weak) IBOutlet NSButton			*keySearchButton;
@property (weak) IBOutlet NSTableView		*searchResultsTableView;

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

- (void) awakeFromNib
{
	[self.searchResultsTableView setTarget:self];
	[self.searchResultsTableView setDoubleAction:@selector(getObjectForSelectedSearchResult:)];
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
												  success:^(AFHTTPRequestOperation *operation, id responseObject){
													  [self updateInterfaceWithHTTPResponse:[operation response]];
													  [self updateSecondaryIndexesFromHTTPResponse:[operation response]];
													  
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

- (NSString*) pathForKeySearchFromCurrentRequestParameters
{
	NSDictionary *selectedKeyDict = [self.secondaryIndexesController selectedObjects][0];
	
	return [NSString stringWithFormat:@"buckets/%@/index/%@/%@",
			self.requestParameters[@"bucket"],
			[self indexNameFieldFromKeyDescription:selectedKeyDict],
			selectedKeyDict[@"value"]];
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
		
		headerName = [self indexHeaderNameFieldFromKeyDescription:keyDescription];
		
		[inRequest addValue:keyDescription[@"value"] forHTTPHeaderField:headerName];
	}
}

- (NSString*) indexHeaderNameFieldFromKeyDescription:(NSDictionary*) keyDescription
{
	return [NSString stringWithFormat:@"x-riak-index-%@", [self indexNameFieldFromKeyDescription:keyDescription]];
}

- (NSString*) indexNameFieldFromKeyDescription:(NSDictionary*) keyDescription
{
	return [NSString stringWithFormat:@"%@_%@", keyDescription[@"name"], [keyDescription[@"type"] isEqualToString:@"Binary" ]? @"bin":@"int"];
}

- (IBAction)clearSecondaryIndexes:(id)sender
{
	[self updateInterfaceWithHTTPResponse:nil];
}

- (void) updateSecondaryIndexesFromHTTPResponse:(NSHTTPURLResponse*) inResponse
{
	self.requestParameters[@"secondaryIndexes"] = [NSMutableArray array];
	
	for (NSString *headerName in inResponse.allHeaderFields)
	{
		if ([[headerName lowercaseString] hasPrefix:@"x-riak-index-"])
		{
			NSString *keyName;
			NSString *keyType;
			
			keyName = [headerName substringFromIndex:[@"x-riak-index-" length]];
			keyType = [keyName substringFromIndex:keyName.length - 3]; // extract either 'bin' or 'int' suffix
			keyName = [keyName substringToIndex:keyName.length - 4];  // remove '_bin' or '_int' sufix
			
			NSMutableDictionary *indexDescription = [NSMutableDictionary dictionary];

			indexDescription[@"name"] = keyName;
			indexDescription[@"value"] = inResponse.allHeaderFields[headerName];
			indexDescription[@"type"] = [keyType isEqualToString:@"bin"] ? @"Binary" : @"Integer";
			
			[self.secondaryIndexesController addObject:indexDescription];
		}
	}
}

- (IBAction)findSelectedIndexKey:(id)sender
{
	[[self httpClientFromCurrentRequestParameters]getPath:[self pathForKeySearchFromCurrentRequestParameters]
											   parameters:nil
												  success:^(AFHTTPRequestOperation *operation, id responseObject){
													  NSError	*error;
													  id		receivedObject;
													  
													  receivedObject = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
													  if ([receivedObject isKindOfClass:[NSDictionary class]])
													  {
														  NSArray *foundKeys = receivedObject[@"keys"];
														  
														  if (foundKeys.count)
														  {
															  [self.searchResultsController setContent:foundKeys];
															  [self.searchResultsPopover setBehavior:NSPopoverBehaviorTransient];
															  [self.searchResultsPopover showRelativeToRect:[self.keySearchButton frame]
																									 ofView:[self.keySearchButton superview]
																							  preferredEdge:CGRectMinYEdge];
														  }
													  }
												  }
												  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
													  [self updateInterfaceWithError:error HTTPResponse:[operation response]];
												  }];
}

- (IBAction)getObjectForSelectedSearchResult:(id)sender
{
	NSString *selectedKey = [self.searchResultsController selectedObjects][0];
	
	self.requestParameters[@"key"] = selectedKey;
	[self.searchResultsPopover close];
	[self getAction:nil];
}

@end
