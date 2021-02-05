//
//  VVDBUpgrader.h
//  VVSequelize
//
//  Created by Valo on 2018/8/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (VVDBUpgrader)
+ (NSComparisonResult)vv_compareVersion:(NSString *)version1 with:(NSString *)version2;
@end

typedef NS_ENUM(NSUInteger, VVDBUpgradeStrategy) {
    VVDBUpgradeStrategyDefault = 0,
    VVDBUpgradeStrategyForceNoRecord,
    VVDBUpgradeStrategyForceAnyCase,
};

/// upgrade item
@interface VVDBUpgradeItem : NSObject <NSCopying>
@property (nonatomic, weak, nullable) id target;
@property (nonatomic, assign, nullable) SEL action; ///< - (BOOL)dosomething:(VVDBUpgradeItem*)item;
@property (nonatomic, copy, nullable) BOOL (^ handler)(VVDBUpgradeItem *);

@property (nonatomic, copy, nonnull) NSString *identifier; ///< set as unique
@property (nonatomic, copy, nonnull) NSString *version;
@property (nonatomic, assign) NSUInteger stage;
@property (nonatomic, assign) CGFloat priority; ///< 0.0 ~ 1.0, default is 0.5
@property (nonatomic, assign) CGFloat weight;   ///< 1.0 ~ ∞, default is 1.0
@property (nonatomic, assign) CGFloat progress; ///< 0.0 ~ 100.0
@property (nonatomic, assign) VVDBUpgradeStrategy strategy; ///< default is VVDBUpgradeStrategyDefault

@property (nonatomic, strong) id reserved; ///< for additional data

+ (instancetype)itemWithIdentifier:(NSString *)identifier
                           version:(NSString *)version
                             stage:(NSUInteger)stage
                            target:(id)target
                            action:(SEL)action;

+ (instancetype)itemWithIdentifier:(NSString *)identifier
                           version:(NSString *)version
                             stage:(NSUInteger)stage
                           handler:(BOOL (^)(VVDBUpgradeItem *))handler;

- (instancetype)initWithIdentifier:(NSString *)identifier
                           version:(NSString *)version
                             stage:(NSUInteger)stage;

/// compare with other item
- (NSComparisonResult)compare:(VVDBUpgradeItem *)other;

@end

@interface VVDBUpgrader : NSObject

/// Key to save the last upgraded version in NSUserDefaults
@property (nonatomic, copy) NSString *versionKey;

/// upgrade progress
@property (nonatomic, strong) NSProgress *progress;

/// upgrading or not
@property (nonatomic, assign, readonly, getter = isUpgrading) BOOL upgrading;

/// add upgrade item
- (void)addItem:(VVDBUpgradeItem *)item;

/// add upgrade items
- (void)addItems:(NSArray<VVDBUpgradeItem *> *)items;

/// cancel upgrade
- (void)cancel;

/// check if the updater needs to be executed
- (BOOL)needUpgrade;

/// check if the item needs to be upgraded
- (BOOL)isNeedToUpgrade:(VVDBUpgradeItem *)item;

/// upgrade all stages
- (void)upgradeAll;

/// upgrade one stage
- (void)upgradeStage:(NSUInteger)stage;

/// debug upgrade items
- (void)debugUpgradeItems:(NSArray<VVDBUpgradeItem *> *)items progress:(NSProgress *)progress;

@end

NS_ASSUME_NONNULL_END
