//
//  VVOrmRoute.m
//  VVSequelize
//
//  Created by Valo on 2018/9/20.
//

#import "VVOrmRoute.h"

@implementation VVOrmRoute

- (id)copyWithZone:(NSZone *)zone
{
    VVOrmRoute *route = [[VVOrmRoute alloc] init];
    route.dbPath = [self.dbPath copy];
    route.tableName = [self.tableName copy];
    return route;
}

@end
