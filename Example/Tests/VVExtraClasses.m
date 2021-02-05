//
//  VVExtraClasses.m
//  VVSequelize_Tests
//
//  Created by Valo on 2020/12/28.
//  Copyright © 2020 Valo. All rights reserved.
//

#import "VVExtraClasses.h"

@implementation VVTestClass

+ (NSArray<NSString *> *)primaries
{
    return @[@"cid"];
}

+ (BOOL)pkAutoInc
{
    return YES;
}

@end


@implementation VVTestStudent

+ (NSArray<NSString *> *)primaries
{
    return @[@"sid"];
}

+ (BOOL)pkAutoInc
{
    return YES;
}

+ (NSArray<NSString *> *)notnulls
{
    return @[@"sno"];
}

+ (NSArray<NSString *> *)uniques
{
    return @[@"sno"];
}

+ (NSArray<VVForeignKey *> *)foreignKeys
{
    VVForeignKey *fk = [VVForeignKey foreignKeyWithTable:@"classes" from:@"cid" to:@"cid" on_update:VVForeignKeyActionCascade on_delete:VVForeignKeyActionRestrict];
    return @[fk];
}

+ (NSArray<NSString *> *)checks
{
    return @[@"age > 12"];
}

@end
