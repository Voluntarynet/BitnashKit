//
//  BNPayToAddressScriptPubKey.m
//  BitnashKit
//
//  Created by Rich Collins on 3/9/14.
//  Copyright (c) 2014 Bitmarkets. All rights reserved.
//

#import "BNPayToAddressScriptPubKey.h"

@implementation BNPayToAddressScriptPubKey

- (id)init
{
    self = [super init];
    [self.serializedSlotNames addObjectsFromArray:[NSArray arrayWithObjects:
                                                   @"address",
                                                   nil]];
    return self;
}

@end