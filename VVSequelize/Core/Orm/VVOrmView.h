//
//  VVOrmView.h
//  VVSequelize
//
//  Created by Valo on 2020/4/23.
//

#import "VVOrm.h"
#import "VVOrm+Create.h"
#import "VVOrm+Delete.h"
#import "VVOrm+Update.h"

NS_ASSUME_NONNULL_BEGIN

@interface VVOrmView : VVOrm
@property (nonatomic, strong) VVExpr *condition;
@property (nonatomic, assign) BOOL temporary;
@property (nonatomic, strong) NSArray *columns;

@property (nonatomic, assign, readonly) BOOL exist;

/// init view
/// @param viewName view name
/// @param orm source table orm
/// @param condition view condition
/// @param temporary temporary view or not
/// @param columns specify columns for view
- (instancetype)initWithName:(NSString *)viewName
                         orm:(VVOrm *)orm
                   condition:(VVExpr *)condition
                   temporary:(BOOL)temporary
                     columns:(nullable NSArray<NSString *> *)columns;

/// create view
- (BOOL)createView;

/// drop view
- (BOOL)dropView;

/// drop old view and create new view
- (BOOL)recreateView;

//MARK: - UNAVAILABLE

#define VVORMVIEW_UNAVAILABLE __attribute__((unavailable("This method is not supported by VVOrmView.")))

//MARK: Setup

- (void)createTable VVORMVIEW_UNAVAILABLE;

- (void)rebuildTable VVORMVIEW_UNAVAILABLE;

//MARK: Create
- (BOOL)insertOne:(nonnull id)object VVORMVIEW_UNAVAILABLE;

- (NSUInteger)insertMulti:(nullable NSArray *)objects VVORMVIEW_UNAVAILABLE;

- (BOOL)upsertOne:(nonnull id)object VVORMVIEW_UNAVAILABLE;

- (NSUInteger)upsertMulti:(nullable NSArray *)objects VVORMVIEW_UNAVAILABLE;

//MARK: Delete
- (BOOL)drop VVORMVIEW_UNAVAILABLE;

- (BOOL)deleteOne:(nonnull id)object VVORMVIEW_UNAVAILABLE;

- (NSUInteger)deleteMulti:(nullable NSArray *)objects VVORMVIEW_UNAVAILABLE;

- (BOOL)deleteWhere:(nullable VVExpr *)condition VVORMVIEW_UNAVAILABLE;

//MARK: Update
- (BOOL)update:(nullable VVExpr *)condition keyValues:(NSDictionary<NSString *, id> *)keyValues VVORMVIEW_UNAVAILABLE;

- (BOOL)updateOne:(nonnull id)object VVORMVIEW_UNAVAILABLE;

- (BOOL)updateOne:(nonnull id)object fields:(nullable NSArray<NSString *> *)fields VVORMVIEW_UNAVAILABLE;

- (NSUInteger)updateMulti:(nullable NSArray *)objects fields:(nullable NSArray<NSString *> *)fields VVORMVIEW_UNAVAILABLE;

- (NSUInteger)updateMulti:(nullable NSArray *)objects VVORMVIEW_UNAVAILABLE;

- (BOOL)increase:(nullable VVExpr *)condition
           field:(nonnull NSString *)field
           value:(NSInteger)value VVORMVIEW_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
