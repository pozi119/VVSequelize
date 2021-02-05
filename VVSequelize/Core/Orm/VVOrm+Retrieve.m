//
//  VVOrm+Retrieve.m
//  VVSequelize
//
//  Created by Valo on 2018/9/12.
//

#import "VVOrm+Retrieve.h"
#import "NSObject+VVOrm.h"
#import "VVSelect.h"

@implementation VVOrm (Retrieve)

- (id)findOne:(nullable VVExpr *)condition
{
    VVSelect *select = VVSelect.new.orm(self).where(condition).limit(1);
    return [select allObjects].firstObject;
}

- (id)findOne:(nullable VVExpr *)condition
      orderBy:(nullable VVOrderBy *)orderBy
{
    VVSelect *select = VVSelect.new.orm(self).where(condition).orderBy(orderBy).limit(1);
    return [select allObjects].firstObject;
}

- (NSArray *)findAll:(nullable VVExpr *)condition
{
    VVSelect *select = VVSelect.new.orm(self).where(condition);
    return [select allObjects];
}

- (NSArray *)findAll:(nullable VVExpr *)condition
             orderBy:(nullable VVOrderBy *)orderBy
{
    VVSelect *select = VVSelect.new.orm(self).where(condition).orderBy(orderBy);
    return [select allObjects];
}

- (NSArray *)findAll:(nullable VVExpr *)condition
             orderBy:(nullable VVOrderBy *)orderBy
               limit:(NSUInteger)limit
              offset:(NSUInteger)offset
{
    VVSelect *select = VVSelect.new.orm(self).where(condition).orderBy(orderBy).offset(offset).limit(limit);
    return [select allObjects];
}

- (NSArray *)findAll:(nullable VVExpr *)condition
             groupBy:(nullable VVGroupBy *)groupBy
{
    VVSelect *select = VVSelect.new.orm(self).where(condition).groupBy(groupBy);
    return [select allObjects];
}

- (NSArray *)findAll:(nullable VVExpr *)condition
             groupBy:(nullable VVGroupBy *)groupBy
               limit:(NSUInteger)limit
              offset:(NSUInteger)offset
{
    VVSelect *select = VVSelect.new.orm(self).where(condition).groupBy(groupBy).offset(offset).limit(limit);
    return [select allObjects];
}

- (NSArray *)findAll:(nullable VVExpr *)condition
            distinct:(BOOL)distinct
              fields:(nullable VVFields *)fields
             groupBy:(nullable VVGroupBy *)groupBy
              having:(nullable VVExpr *)having
             orderBy:(nullable VVOrderBy *)orderBy
               limit:(NSUInteger)limit
              offset:(NSUInteger)offset
{
    VVSelect *select = VVSelect.new.orm(self).where(condition).distinct(distinct).fields(fields)
        .groupBy(groupBy).having(having).orderBy(orderBy)
        .offset(offset).limit(limit);
    return [select allObjects];
}

- (NSInteger)count:(nullable VVExpr *)condition
{
    return [[self calc:@"*" method:@"count" condition:condition] unsignedIntegerValue];
}

- (BOOL)isExist:(id)object
{
    NSDictionary *condition = [self uniqueConditionForObject:object];
    if (condition.count == 0) return NO;
    return [self count:condition] > 0;
}

- (NSDictionary *)findAndCount:(nullable VVExpr *)condition
                       orderBy:(nullable VVOrderBy *)orderBy
                         limit:(NSUInteger)limit
                        offset:(NSUInteger)offset
{
    NSUInteger count = [self count:condition];
    NSArray *array = [self findAll:condition orderBy:orderBy limit:limit offset:offset];
    return @{ @"count": @(count), @"list": array };
}

- (NSUInteger)maxRowid
{
    return [[self max:@"rowid" condition:nil] unsignedIntegerValue];
}

- (id)max:(NSString *)field condition:(nullable VVExpr *)condition
{
    return [self calc:field method:@"max" condition:condition];
}

- (id)min:(NSString *)field condition:(nullable VVExpr *)condition
{
    return [self calc:field method:@"min" condition:condition];
}

- (id)sum:(NSString *)field condition:(nullable VVExpr *)condition
{
    return [self calc:field method:@"sum" condition:condition];
}

- (id)calc:(NSString *)field method:(NSString *)method condition:(nullable VVExpr *)condition
{
    if (!([method isEqualToString:@"max"]
          || [method isEqualToString:@"min"]
          || [method isEqualToString:@"sum"]
          || [method isEqualToString:@"count"])) return nil;
    NSString *fields = [NSString stringWithFormat:@"%@(%@) AS %@", method, field.quoted, method];
    VVSelect *select = VVSelect.new.orm(self).where(condition).fields(fields);
    NSArray *array = [select allKeyValues];
    NSDictionary *dic = array.firstObject;
    id result = dic[method];
    return [result isKindOfClass:NSNull.class] ? nil : result;
}

@end
