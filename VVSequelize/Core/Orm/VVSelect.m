//
//  VVSelect.m
//  VVSequelize
//
//  Created by Valo on 2018/9/14.
//

#import "VVSelect.h"
#import "NSObject+VVKeyValue.h"
#import "NSObject+VVOrm.h"

@interface VVSelect ()
@property (nonatomic, copy) NSString *fieldsString;
@end

@implementation VVSelect
{
    VVDatabase *_vvdb;     ///< database
    NSString *_table;      ///< table name
    Class _clazz;          ///< results class
    
    BOOL _distinct;        ///< clear duplicate records or not
    VVFields *_fields;     ///< query fields: NSString, NSArray
    VVExpr *_where;        ///< query condition: NSString, NSDictionary, NSArray
    VVOrderBy *_orderBy;   ///< sort: NSString, NSArray
    VVGroupBy *_groupBy;   ///< group: NSString, NSArray
    VVExpr *_having;       ///< group filter: NSString, NSDictionary, NSArray
    NSUInteger _offset;    ///< offset
    NSUInteger _limit;     ///< limit
    NSArray *_values;      ///< bind values
}

- (NSArray *)allObjects
{
    return [self allResults:YES];
}

- (NSArray *)allKeyValues
{
    return [self allResults:NO];
}

- (NSArray *)allResults:(BOOL)useObjects
{
    NSAssert(_vvdb, @"set database or orm first!");
    NSArray *keyValuesArray = [_vvdb query:self.sql bind:_values];
    if (useObjects) {
        NSAssert(_clazz, @"set class or orm first!");
        return [_clazz vv_objectsWithKeyValuesArray:keyValuesArray];
    }
    return keyValuesArray;
}

- (NSArray *)allValues:(NSString *)field {
    if (field.length == 0) return @[];
    NSArray *allKeyValues = [self allKeyValues];
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:allKeyValues.count];
    for (NSDictionary *keyValues in allKeyValues) {
        [results addObject:keyValues[field] ? : NSNull.null];
    }
    return results;
}

//MARK: - chain
+ (instancetype)makeSelect:(void (^)(VVSelect *make))block
{
    VVSelect *select = [[VVSelect alloc] init];
    if (block) block(select);
    return select;
}

- (VVSelect *(^)(VVOrm *orm))orm
{
    return ^(VVOrm *orm) {
        self->_clazz = orm.metaClass ? : orm.config.cls;
        self->_vvdb = orm.vvdb;
        self->_table = orm.name;
        return self;
    };
}

- (VVSelect *(^)(VVDatabase *vvdb))vvdb
{
    return ^(VVDatabase *vvdb) {
        self->_vvdb = vvdb;
        return self;
    };
}

- (VVSelect *(^)(NSString *table))table
{
    return ^(NSString *table) {
        self->_table = table;
        return self;
    };
}

- (VVSelect *(^)(Class clazz))clazz
{
    return ^(Class clazz) {
        self->_clazz = clazz;
        return self;
    };
}

- (VVSelect *(^)(BOOL distinct))distinct
{
    return ^(BOOL distinct) {
        self->_distinct = distinct;
        return self;
    };
}

- (VVSelect *(^)(VVFields *fields))fields
{
    return ^(VVFields *fields) {
        self->_fields = fields;
        return self;
    };
}

- (VVSelect *(^)(VVExpr *where))where
{
    return ^(VVExpr *where) {
        self->_where = where;
        return self;
    };
}

- (VVSelect *(^)(VVOrderBy *orderBy))orderBy
{
    return ^(VVOrderBy *orderBy) {
        self->_orderBy = orderBy;
        return self;
    };
}

- (VVSelect *(^)(VVGroupBy *groupBy))groupBy
{
    return ^(VVGroupBy *groupBy) {
        self->_groupBy = groupBy;
        return self;
    };
}

- (VVSelect *(^)(VVExpr *having))having
{
    return ^(VVExpr *having) {
        self->_having = having;
        return self;
    };
}

- (VVSelect *(^)(NSUInteger offset))offset
{
    return ^(NSUInteger offset) {
        self->_offset = offset;
        return self;
    };
}

- (VVSelect *(^)(NSUInteger limit))limit
{
    return ^(NSUInteger limit) {
        self->_limit = limit;
        return self;
    };
}

- (VVSelect *(^)(NSArray *values))values
{
    return ^(NSArray *values) {
        self->_values = values;
        return self;
    };
}

- (NSString *)fieldsString
{
    if (!_fieldsString) {
        if ([_fields isKindOfClass:NSString.class]) {
            _fieldsString = (NSString *)_fields;
        } else if ([_fields isKindOfClass:NSArray.class] && [(NSArray *)_fields count] > 0) {
            _fieldsString = [(NSArray *)_fields sqlJoin];
        } else {
            _fieldsString = @"*";
        }
    }
    return _fieldsString;
}

//MARK: - generate query sql
- (NSString *)sql
{
    NSAssert(_table.length > 0, @"set table or orm first!");
    _fieldsString = nil;     // reset fieldsString

    NSString *where = [_where sqlWhere] ? : @"";
    if (where.length > 0) where =  [NSString stringWithFormat:@" WHERE %@", where];
    
    NSString *groupBy = [_groupBy sqlJoin] ? : @"";
    if (groupBy.length > 0) groupBy = [NSString stringWithFormat:@" GROUP BY %@", groupBy];
    
    NSString *having = groupBy.length > 0 ? ([_having sqlWhere] ? : @"") : @"";
    if (having.length > 0) having = [NSString stringWithFormat:@" HAVING %@", having];
    
    NSString *orderBy = [_orderBy sqlJoin] ? : @"";
    if (orderBy.length > 0) {
        if (![orderBy isMatch:@"( +ASC *$)|( +DESC *$)"]) orderBy = orderBy.asc;
        orderBy = [NSString stringWithFormat:@" ORDER BY %@", orderBy];
    }
    
    if (_offset > 0 && _limit <= 0) _limit = NSUIntegerMax;
    
    NSString *limit = _limit > 0 ? [NSString stringWithFormat:@" LIMIT %@", @(_limit)] : @"";
    
    NSString *offset = _offset > 0 ? [NSString stringWithFormat:@" OFFSET %@", @(_offset)] : @"";
    
    NSString *sql = [NSMutableString stringWithFormat:@"SELECT %@ %@ FROM %@ %@ %@ %@ %@ %@ %@",
                     _distinct ? @"DISTINCT" : @"", self.fieldsString, _table,
                     where, groupBy, having, orderBy, limit, offset].vv_strip;
    return sql;
}

@end
