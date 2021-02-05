//
//  VVOrm+Create.m
//  VVSequelize
//
//  Created by Valo on 2018/9/12.
//

#import "VVOrm+Create.h"
#import "NSObject+VVKeyValue.h"
#import "NSObject+VVOrm.h"
#import "VVOrmView.h"

@implementation VVOrm (Create)

- (BOOL)_insertOne:(nonnull id)object upsert:(BOOL)upsert
{
    [self createTableAndIndexes];

    NSDictionary *dic = [object isKindOfClass:[NSDictionary class]] ? object : [object vv_keyValues];
    if (!upsert && self.config.primaries.count == 1 && self.config.pkAutoInc) {
        dic = [dic vv_removeObjectsForKeys:self.config.primaries];
    }

    NSMutableArray *keys = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *placeholders = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:0];

    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        if (key && obj && [self.config.columns containsObject:key]) {
            [keys addObject:key.quoted];
            [placeholders addObject:@"?"];
            [values addObject:[obj vv_dbStoreValue]];
        }
    }];

    if (keys.count == 0) return NO;

    if (self.config.logAt) {
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        [keys addObject:kVVCreateAt.quoted];
        [placeholders addObject:@"?"];
        [values addObject:@(now)];

        [keys addObject:kVVUpdateAt.quoted];
        [placeholders addObject:@"?"];
        [values addObject:@(now)];
    }

    NSString *keyString = [keys componentsJoinedByString:@","];
    NSString *placeholderString = [placeholders componentsJoinedByString:@","];
    NSString *sql = [NSString stringWithFormat:@"%@ INTO %@ (%@) VALUES (%@)",
                     (upsert ? @"INSERT OR REPLACE" : @"INSERT"),
                     self.name.quoted, keyString, placeholderString];
    return [self.vvdb run:sql bind:values];
}

- (BOOL)insertOne:(nonnull id)object
{
    return [self _insertOne:object upsert:NO];
}

- (NSUInteger)insertMulti:(nullable NSArray *)objects
{
    __block NSUInteger count = 0;
    [self.vvdb transaction:VVDBTransactionImmediate block:^BOOL {
        for (id obj in objects) {
            if ([self _insertOne:obj upsert:NO]) { count++; }
        }
        return count > 0;
    }];
    return count;
}

- (BOOL)upsertOne:(nonnull id)object
{
    return [self _insertOne:object upsert:YES];
}

- (NSUInteger)upsertMulti:(NSArray *)objects
{
    __block NSUInteger count = 0;
    [self.vvdb transaction:VVDBTransactionImmediate block:^BOOL {
        for (id obj in objects) {
            if ([self _insertOne:obj upsert:YES]) { count++; }
        }
        return count > 0;
    }];
    return count;
}

@end
