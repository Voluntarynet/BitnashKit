//
//  BitnashJ.m
//  BitnashKit
//
//  Created by Rich Collins on 3/9/14.
//  Copyright (c) 2014 Bitmarkets. All rights reserved.
//

#import "BNServer.h"
#import "NSObject+BNJSON.h"

@implementation BNServer

- (void)start
{
    self.error = nil;
    
    [self createDir];
    
    if (_error)
    {
        return;
    }
    
    NSBundle *frameworkBundle = [NSBundle bundleForClass:self.class];
    
    NSString *classPath = [[NSArray arrayWithObjects:
                            frameworkBundle.resourcePath,
                            [frameworkBundle pathForResource:@"bitcoinj-0.11-bundled" ofType:@"jar"],
                            [frameworkBundle pathForResource:@"json-simple-1.1.1" ofType:@"jar"],
                            [frameworkBundle pathForResource:@"slf4j-simple-1.7.6" ofType:@"jar"],
                            nil] componentsJoinedByString:@":"];
    
    self.task = [[NSTask alloc] init];
    _task.currentDirectoryPath = _path;
    _task.launchPath = @"/usr/bin/java"; //TODO: Locate it first?
    _task.arguments = [NSArray arrayWithObjects:
                         @"-Dfile.encoding=MacRoman",
                         @"-classpath", classPath,
                         @"org.bitmarkets.bitnash.App",
                         nil];
    
    _task.standardInput = [NSPipe pipe];
    _task.standardOutput = [NSPipe pipe];
    
    _task.standardError = [NSPipe pipe];
    
    [_task launch];
}

- (void)createDir
{
    NSError *error = nil;
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:_path])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:_path withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (error) {
        self.error = error;
    }
}

- (id)sendMessage:(NSString *)messageName withObject:(id)object
{
    self.error = nil;
    
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    [message setObject:messageName forKey:@"name"];
    
    if (object == nil)
    {
        object = [NSNull null];
    }
    
    [message setObject:[object asJSONObject] forKey:@"data"];
    
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message options:0x0 error:&error];
    
    if (error)
    {
        self.error = error;
        return nil;
    }
    
    [[_task.standardInput fileHandleForWriting] writeData:jsonData];
    [[_task.standardInput fileHandleForWriting] writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableData *output = [NSMutableData data];
    
    while (![[[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding] hasSuffix:@"\n"])
    {
        NSData *data = [[_task.standardOutput fileHandleForReading] availableData];
        [output appendData:data];
    }
    
NSLog(@"Output: %@", [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding]);

    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:output options:0x0 error:&error];
    
    if (error)
    {
        self.error = error;
        return nil;
    }
    
    if ([response objectForKey:@"error"])
    {
        self.error = [NSError errorWithDomain:@"com.bitmarkets.Bitnash" code:0 userInfo:[NSDictionary dictionaryWithObject:[response objectForKey:@"error"] forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
    else
    {
        return [[response objectForKey:@"data"] asObjectFromJSONObject];
    }
}


@end
