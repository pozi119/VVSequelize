//
//  VVOrm+FTS.m
//  VVSequelize
//
//  Created by Valo on 2018/9/15.
//

#import "VVOrm+FTS.h"
#import "VVSelect.h"
#import "NSObject+VVOrm.h"
#import "VVDatabase+FTS.h"
#import "VVDBStatement.h"
#import "VVFtsable.h"
#import "NSString+Tokenizer.h"

NSString *const VVOrmFtsCount = @"vvdb_fts_count";

@implementation VVOrm (FTS)

//MARK: - Public

- (NSString *)fts5HighlightOfFields:(NSArray<NSString *> *)fields
{
    return [self fts5HighlightOfFields:fields resultColumns:nil leftMark:@"<b>" rightMark:@"</b>"];
}

- (NSString *)fts5HighlightOfFields:(NSArray<NSString *> *)fields
                      resultColumns:(nullable NSArray<NSString *> *)resultColumns
                           leftMark:(NSString *)leftMark
                          rightMark:(NSString *)rightMark
{
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ LIMIT 0;", self.name.quoted];
    VVDBStatement *statement = [VVDBStatement statementWithDatabase:self.vvdb sql:sql];
    NSArray *tableColumns = [[statement columnNames] copy];
    statement = nil;

    NSString *result = [NSString fts5HighlightOfFields:fields tableName:self.name tableColumns:tableColumns resultColumns:resultColumns leftMark:leftMark rightMark:rightMark];
    return result;
}

- (NSArray *)match:(nullable VVExpr *)condition
           orderBy:(nullable VVOrderBy *)orderBy
             limit:(NSUInteger)limit
            offset:(NSUInteger)offset
{
    VVSelect *select = VVSelect.new.orm(self).where(condition).orderBy(orderBy).offset(offset).limit(limit);
    return [select allObjects];
}

- (NSArray *)match:(nullable VVExpr *)condition
         highlight:(NSArray<NSString *> *)fields
           orderBy:(nullable VVOrderBy *)orderBy
             limit:(NSUInteger)limit
            offset:(NSUInteger)offset
{
    VVSelect *select = VVSelect.new.orm(self).where(condition).orderBy(orderBy).offset(offset).limit(limit);
    NSString *fieldsString = [self fts5HighlightOfFields:fields];
    select.fields(fieldsString);
    return [select allObjects];
}

- (NSArray *)match:(nullable VVExpr *)condition
           groupBy:(nullable VVGroupBy *)groupBy
             limit:(NSUInteger)limit
            offset:(NSUInteger)offset
{
    NSString *fields = [NSString stringWithFormat:@"*,count(*) as %@", VVOrmFtsCount];
    NSString *orderBy = @"rowid".desc;
    VVSelect *select = VVSelect.new.orm(self).where(condition).fields(fields)
        .groupBy(groupBy).orderBy(orderBy).offset(offset).limit(limit);
    return [select allKeyValues];
}

- (NSUInteger)matchCount:(nullable VVExpr *)condition
{
    NSString *fields = @"count(*) as count";
    VVSelect *select = VVSelect.new.orm(self).where(condition).fields(fields);
    NSDictionary *dic = [select allKeyValues].firstObject;
    return [dic[@"count"] integerValue];
}

- (NSDictionary *)matchAndCount:(nullable VVExpr *)condition
                        orderBy:(nullable VVOrderBy *)orderBy
                          limit:(NSUInteger)limit
                         offset:(NSUInteger)offset
{
    NSUInteger count = [self matchCount:condition];
    NSArray *array = [self match:condition orderBy:orderBy limit:limit offset:offset];
    return @{ @"count": @(count), @"list": array };
}

@end
