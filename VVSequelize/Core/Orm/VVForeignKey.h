//
//  VVForeignKey.h
//  VVSequelize
//
//  Created by Valo on 2020/12/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, VVForeignKeyAction) {
    VVForeignKeyActionNone,
    VVForeignKeyActionCascade,
    VVForeignKeyActionSetNull,
    VVForeignKeyActionNoAction,
    VVForeignKeyActionRestrict,
    VVForeignKeyActionSetDefault,
};

@interface VVForeignKey : NSObject
@property (nonatomic, copy) NSString *table;
@property (nonatomic, copy) NSString *from;
@property (nonatomic, copy) NSString *to;
@property (nonatomic, assign) VVForeignKeyAction on_update;
@property (nonatomic, assign) VVForeignKeyAction on_delete;

+ (instancetype)foreignKeyWithTable:(NSString *)table
                               from:(NSString *)from
                                 to:(NSString *)to
                          on_update:(VVForeignKeyAction)on_update
                          on_delete:(VVForeignKeyAction)on_delete;

@end

NS_ASSUME_NONNULL_END
