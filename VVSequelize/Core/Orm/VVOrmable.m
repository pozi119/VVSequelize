//
//  VVOrmable.m
//  VVSequelize
//
//  Created by Valo on 2020/7/29.
//

#import "VVOrmable.h"
#import "VVForeignKey.h"

@implementation VVOrmConfig (VVOrmable)

+ (instancetype)configWithOrmable:(Class<VVOrmable>)cls
{
    NSAssert([cls conformsToProtocol:@protocol(VVOrmable)], @"class must confroms to VVOrmable");
    VVOrmConfig *config = [VVOrmConfig configWithClass:cls];
    if ([cls respondsToSelector:@selector(primaries)]) {
        config.primaries = [cls primaries] ? : @[];
    }
    if ([cls respondsToSelector:@selector(whites)]) {
        config.whiteList = [cls whites] ? : @[];
    }
    if ([cls respondsToSelector:@selector(blacks)]) {
        config.blackList = [cls blacks] ? : @[];
    }
    if ([cls respondsToSelector:@selector(indexes)]) {
        config.indexes = [cls indexes] ? : @[];
    }
    if ([cls respondsToSelector:@selector(notnulls)]) {
        config.notnulls = [cls notnulls] ? : @[];
    }
    if ([cls respondsToSelector:@selector(uniques)]) {
        config.uniques = [cls uniques] ? : @[];
    }
    if ([cls respondsToSelector:@selector(logAt)]) {
        config.logAt = [cls logAt];
    }
    if ([cls respondsToSelector:@selector(pkAutoInc)]) {
        config.pkAutoInc = [cls pkAutoInc];
    }
    if ([cls respondsToSelector:@selector(defaultValues)]) {
        config.defaultValues = [cls defaultValues] ? : @{};
    }
#ifdef VVSEQUELIZE_CONSTRAINTS
    if ([cls respondsToSelector:@selector(foreignKeys)]) {
        config.foreignKeys = [cls foreignKeys] ? : @[];
    }
    if ([cls respondsToSelector:@selector(checks)]) {
        config.checks = [cls checks] ? : @{};
    }
#endif
    return config;
}

@end

@implementation VVOrm (VVOrmable)

+ (instancetype)ormWithClass:(Class<VVOrmable>)clazz
{
    return [VVOrm ormWithClass:clazz name:nil database:nil];
}

+ (instancetype)ormWithClass:(Class<VVOrmable>)clazz name:(NSString *)name database:(VVDatabase *)vvdb
{
    return [VVOrm ormWithClass:clazz name:name database:vvdb setup:VVOrmSetupCreate];
}

+ (instancetype)ormWithClass:(Class<VVOrmable>)clazz name:(NSString *)name database:(VVDatabase *)vvdb setup:(VVOrmSetup)setup
{
    VVOrmConfig *config = [VVOrmConfig configWithOrmable:clazz];
    return [VVOrm ormWithConfig:config name:name database:vvdb setup:setup];
}

@end
