//
//  VVOrmView.m
//  VVSequelize
//
//  Created by Valo on 2020/4/23.
//

#import "VVOrmView.h"
#import "NSObject+VVOrm.h"

@interface VVOrmView ()
/// source table name
@property (nonatomic, copy) NSString *sourceTable;
@end

@implementation VVOrmView

@synthesize name = _name;

+ (nullable instancetype)ormWithConfig:(VVOrmConfig *)config {
    return [self ormWithConfig:config tableName:nil dataBase:nil];
}

+ (nullable instancetype)ormWithConfig:(VVOrmConfig *)config
                             tableName:(nullable NSString *)tableName
                              dataBase:(nullable VVDatabase *)vvdb
{
    return [[VVOrmView alloc] initWithConfig:config name:tableName database:vvdb];
}

- (instancetype)initWithName:(NSString *)name
                         orm:(VVOrm *)orm
                   condition:(VVExpr *)condition
                   temporary:(BOOL)temporary
                     columns:(nullable NSArray<NSString *> *)columns
{
    self = [super initWithConfig:orm.config name:orm.name database:orm.vvdb];
    if (self) {
        _sourceTable = orm.name;
        _name = name;
        _condition = condition;
        _temporary = temporary;
        _columns = columns;
    }
    return self;
}

- (instancetype)initWithConfig:(VVOrmConfig *)config name:(NSString *)name database:(VVDatabase *)database
{
    self = [super initWithConfig:config name:name database:database];
    if (self) {
        _sourceTable = name;
        _name = @"";
    }
    return self;
}

//MARK: - public
- (BOOL)exist
{
    NSAssert(_name.length > 0, @"Please set view name first!");
    NSString *sql = [NSString stringWithFormat:@"SELECT count(*) as 'count' FROM sqlite_master WHERE type ='view' and tbl_name = %@", _name.quoted];
    return [[self.vvdb scalar:sql bind:nil] boolValue];
}

- (BOOL)createView
{
    NSString *where = [_condition sqlWhere];
    NSAssert(_name.length > 0 && where.length > 0, @"Please set view name and condition first!");

    NSArray *cols = nil;
    if (_columns.count > 0) {
        NSSet *all = [NSSet setWithArray:self.config.columns];
        NSMutableSet *set = [NSMutableSet setWithArray:_columns];
        [set intersectSet:all];
        cols = set.allObjects;
    }

    NSString *sql = [NSString stringWithFormat:
                     @"CREATE %@ VIEW %@ AS "
                     "SELECT %@ "
                     "FROM %@"
                     "WHERE %@",
                     (_temporary ? @"TEMP" : @""), _name.quoted,
                     (cols.count > 0 ? cols.sqlJoin : @"*"),
                     _sourceTable.quoted,
                     where];

    return [self.vvdb run:sql];
}

- (BOOL)dropView
{
    NSString *sql = [NSString stringWithFormat:@"DROP VIEW %@", _name.quoted];
    return [self.vvdb run:sql];
}

- (BOOL)recreateView
{
    BOOL ret = YES;
    if (self.exist) {
        ret = [self dropView];
    }
    if (ret) {
        ret = [self createView];
    }
    return ret;
}

//MAKR: - UNAVAILABLE
- (void)createTable
{
}

- (void)rebuildTable
{
}

@end
