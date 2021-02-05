//
//  VVOrm+Update.m
//  VVSequelize
//
//  Created by Valo on 2018/9/12.
//

#import "VVOrm+Update.h"
#import "NSObject+VVKeyValue.h"
#import "NSObject+VVOrm.h"
#import "VVOrmView.h"

@implementation VVOrm (Update)

- (BOOL)_update:(nullable VVExpr *)condition keyValues:(NSDictionary<NSString *, id> *)keyValues
{
    [self createTableAndIndexes];

    NSString *where = [condition sqlWhere];
    where = where.length == 0 ? @"" : [NSString stringWithFormat:@" WHERE %@", where];

    NSMutableArray *sets = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *vals = [NSMutableArray arrayWithCapacity:0];

    [keyValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        if (key && obj && [self.config.columns containsObject:key]) {
            NSString *tmp = [NSString stringWithFormat:@"%@ = ?", key.quoted];
            [sets addObject:tmp];
            [vals addObject:[obj vv_dbStoreValue]];
        }
    }];

    if (sets.count == 0) return NO;

    if (self.config.logAt) {
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        NSString *tmp = [NSString stringWithFormat:@"%@ = ?", kVVUpdateAt.quoted];
        [sets addObject:tmp];
        [vals addObject:@(now)];
    }

    NSString *setString = [sets componentsJoinedByString:@","];
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ %@", self.name.quoted, setString, where];
    return [self.vvdb run:sql bind:vals];
}

- (BOOL)_updateOne:(id)object fields:(nullable NSArray<NSString *> *)fields
{
    NSDictionary *condition = [self uniqueConditionForObject:object];
    if (condition.count == 0) return NO;
    NSDictionary *dic = [object isKindOfClass:[NSDictionary class]] ? object : [object vv_keyValues];
    NSMutableDictionary *keyValues = nil;
    if (fields.count == 0) {
        keyValues = dic.mutableCopy;
    } else {
        keyValues = [NSMutableDictionary dictionaryWithCapacity:fields.count];
        for (NSString *field in fields) {
            keyValues[field] = dic[field];
        }
    }
    if (keyValues.count == 0) return NO;
    return [self _update:condition keyValues:keyValues];
}

- (BOOL)update:(nullable VVExpr *)condition keyValues:(NSDictionary<NSString *, id> *)keyValues
{
    return [self _update:condition keyValues:keyValues];
}

- (BOOL)updateOne:(id)object
{
    return [self _updateOne:object fields:nil];
}

- (BOOL)updateOne:(id)object fields:(nullable NSArray<NSString *> *)fields
{
    return [self _updateOne:object fields:fields];
}

- (NSUInteger)updateMulti:(NSArray *)objects
{
    return [self updateMulti:objects fields:nil];
}

- (NSUInteger)updateMulti:(NSArray *)objects fields:(nullable NSArray<NSString *> *)fields
{
    __block NSUInteger count = 0;
    [self.vvdb transaction:VVDBTransactionImmediate block:^BOOL {
        for (id object in objects) {
            if ([self _updateOne:object fields:fields]) { count++; }
        }
        return count > 0;
    }];
    return count;
}

- (BOOL)increase:(nullable VVExpr *)condition
           field:(NSString *)field
           value:(NSInteger)value
{
    if (value == 0) {
        return YES;
    }
    NSMutableString *setString = [NSMutableString stringWithFormat:@"%@ = %@%@%@",
                                  field.quoted, field.quoted, value > 0 ? @"+" : @"-", @(ABS(value))];
    if (self.config.logAt) {
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        [setString appendFormat:@",%@ = %@", kVVUpdateAt.quoted, @(now).stringValue.quoted];
    }

    NSString *where = [condition sqlWhere];
    where = where.length == 0 ? @"" : [NSString stringWithFormat:@" WHERE %@", where];

    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ %@", self.name.quoted, setString, where];
    return [self.vvdb run:sql];
}

@end
