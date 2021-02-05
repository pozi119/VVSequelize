//
//  VVFtsable.m
//  VVSequelize
//
//  Created by Valo on 2020/7/29.
//

#import "VVFtsable.h"
#import "VVTokenEnumerator.h"

@implementation VVOrmConfig (VVFtsable)

+ (instancetype)configWithFtsable:(Class<VVFtsable>)cls
{
    NSAssert([cls conformsToProtocol:@protocol(VVFtsable)], @"class must confroms to VVFtsable");
    VVOrmConfig *config = [VVOrmConfig configWithClass:cls];
    config.fts = YES;
    if ([cls respondsToSelector:@selector(fts_whites)]) {
        config.whiteList = [cls fts_whites] ? : @[];
    }
    if ([cls respondsToSelector:@selector(fts_blacks)]) {
        config.blackList = [cls fts_blacks] ? : @[];
    }
    if ([cls respondsToSelector:@selector(fts_indexes)]) {
        config.indexes = [cls fts_indexes] ? : @[];
    }
    if ([cls respondsToSelector:@selector(fts_module)]) {
        config.ftsModule = [cls fts_module] ? : @"fts5";
    }
    if ([cls respondsToSelector:@selector(fts_tokenizer)]) {
        config.ftsTokenizer = [cls fts_tokenizer] ? : @"sequelize";
    }
    return config;
}

@end

@implementation VVOrm (VVFtsable)

+ (instancetype)ormWithFtsClass:(Class<VVFtsable>)clazz
{
    return [VVOrm ormWithFtsClass:clazz name:nil database:nil];
}

+ (instancetype)ormWithFtsClass:(Class<VVFtsable>)clazz name:(NSString *)name database:(VVDatabase *)vvdb
{
    return [VVOrm ormWithFtsClass:clazz name:name database:vvdb setup:VVOrmSetupCreate];
}

+ (instancetype)ormWithFtsClass:(Class<VVFtsable>)clazz name:(NSString *)name database:(VVDatabase *)vvdb setup:(VVOrmSetup)setup
{
    VVOrmConfig *config = [VVOrmConfig configWithFtsable:clazz];
    return [VVOrm ormWithConfig:config name:name database:vvdb setup:setup];
}

@end
