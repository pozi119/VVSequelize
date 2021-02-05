//
//  VVDBStatement.h
//  VVSequelize
//
//  Created by Valo on 2019/3/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VVDatabase, VVDBStatement;

/// sqlit3_stmt cursor, use to bind/read data
@interface VVDBCursor : NSObject
- (instancetype)initWithStatement:(VVDBStatement *)statement;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;

- (id)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

@end

/// packaged sqlite3_stmt
@interface VVDBStatement : NSObject
/// query/bind lines
@property (nonatomic, assign, readonly) int columnCount;

/// query/bind column names
@property (nonatomic, strong, readonly) NSArray<NSString *> *columnNames;

/// cursor
@property (nonatomic, strong, readonly) VVDBCursor *cursor;

/// create/get VVDBStatement object
/// @param vvdb db object
/// @param sql native sql
/// @note has cache
+ (nullable instancetype)statementWithDatabase:(VVDatabase *)vvdb sql:(NSString *)sql;

/// Initialize VVDBStatement
/// @param vvdb db object
/// @param sql native sql
- (nullable instancetype)initWithDatabase:(VVDatabase *)vvdb sql:(NSString *)sql;

/// bind data
/// @param values data array, corresponding to 'columnnames' one by one
- (VVDBStatement *)bind:(nullable NSArray *)values;

- (id)scalar:(nullable NSArray *)values;

/// execute sqlite3_stmt
- (BOOL)run;

/// execute sqlite3_stmt query
- (nullable NSArray<NSDictionary *> *)query;

/// execute sqlite3_step()
- (BOOL)step;

/// reset sqlite3_stmt, do not clean bind data
- (void)reset;

/// reset sqlite3_stmt, clean bind data
- (void)resetAndClear;

@end

NS_ASSUME_NONNULL_END
