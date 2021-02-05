//
//  VVOrmRoute.h
//  VVSequelize
//
//  Created by Valo on 2018/9/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// database and table to write to
@interface VVOrmRoute : NSObject <NSCopying>
@property (nonatomic, copy) NSString *dbPath;
@property (nonatomic, copy) NSString *tableName;
@end

/// database and table to write to
@protocol VVOrmRoute <NSObject>

+ (VVOrmRoute *)routeOfObject:(id)object;

+ (NSDictionary<VVOrmRoute *, id> *)routesOfObjects:(NSArray *)objects;

/// @return {route:[sub_start,sub_end]}
+ (NSDictionary<VVOrmRoute *, NSArray *> *)routesOfRange:(NSUInteger)type
                                                   start:(id)start
                                                     end:(id)end;

@end

NS_ASSUME_NONNULL_END
