//
//  VVDBUpgrader.m
//  VVSequelize
//
//  Created by Valo on 2018/8/11.
//

#import "VVDBUpgrader.h"

NSString *const VVDBUpgraderLastVersionKey = @"VVDBUpgraderLastVersionKey";
NSString *const VVDBUpgraderLastVersionsKeySuffix = @"-LastVersions";
CGFloat const VVDBUpgraderProgressAccuracy = 100.0;

@implementation NSString (VVDBUpgrader)

+ (NSComparisonResult)vv_compareVersion:(NSString *)version1 with:(NSString *)version2
{
    if ([version1 isEqualToString:version2]) return NSOrderedSame;

    NSCharacterSet *chset = [NSCharacterSet characterSetWithCharactersInString:@".-_"];
    NSArray *array1 = [version1 componentsSeparatedByCharactersInSet:chset];
    NSArray *array2 = [version2 componentsSeparatedByCharactersInSet:chset];
    NSUInteger count = MIN(array1.count, array2.count);
    for (NSUInteger i = 0; i < count; i++) {
        NSString *str1 = array1[i];
        NSString *str2 = array2[i];
        NSComparisonResult ret = [str1 compare:str2];
        if (ret != NSOrderedSame) {
            return ret;
        }
    }
    return array1.count < array2.count ? NSOrderedAscending :
           array1.count == array2.count ? NSOrderedSame : NSOrderedDescending;
}

@end

@interface VVDBUpgradeItem ()
@property (nonatomic, copy) void (^progressBlock)(CGFloat);
@end

@implementation VVDBUpgradeItem

+ (instancetype)itemWithIdentifier:(NSString *)identifier
                           version:(NSString *)version
                             stage:(NSUInteger)stage
                            target:(id)target
                            action:(SEL)action
{
    VVDBUpgradeItem *item = [[VVDBUpgradeItem alloc] initWithIdentifier:identifier version:version stage:stage];
    item.target = target;
    item.action = action;
    return item;
}

+ (instancetype)itemWithIdentifier:(NSString *)identifier
                           version:(NSString *)version
                             stage:(NSUInteger)stage
                           handler:(BOOL (^)(VVDBUpgradeItem *))handler
{
    VVDBUpgradeItem *item = [[VVDBUpgradeItem alloc] initWithIdentifier:identifier version:version stage:stage];
    item.handler = handler;
    return item;
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                           version:(NSString *)version
                             stage:(NSUInteger)stage
{
    self = [super init];
    if (self) {
        _identifier = identifier;
        _version = version;
        _stage = stage;
        _priority = 0.5;
        _weight = 1.0;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _priority = 0.5;
        _weight = 1.0;
    }
    return self;
}

- (void)reset
{
    self.progress = 0.0;
}

- (void)setWeight:(CGFloat)weight
{
    _weight = MAX(1.0, weight);
}

- (void)setPriority:(CGFloat)priority
{
    _priority = MAX(0.0, MIN(1.0, priority));
}

- (void)setProgress:(CGFloat)progress
{
    _progress = MAX(0.0, MIN(1.0, progress));
    if (_progressBlock) _progressBlock(_progress);
}

- (NSComparisonResult)compare:(VVDBUpgradeItem *)other
{
    NSComparisonResult result = self.stage < other.stage ? NSOrderedAscending : (self.stage == other.stage ? NSOrderedSame : NSOrderedDescending);
    if (result == NSOrderedSame) {
        result = [NSString vv_compareVersion:self.version with:other.version];
    }
    if (result == NSOrderedSame) {
        result = self.priority > other.priority ? NSOrderedAscending : (self.priority == other.priority ? NSOrderedSame : NSOrderedDescending);
    }
    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"id:'%@', stage:%@, version:'%@', priority:%.2f, weight:%.2f, progress:%.2f", _identifier, @(_stage), _version, _priority, _weight, _progress];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    VVDBUpgradeItem *item = [[[self class] allocWithZone:zone] init];
    item.identifier = self.identifier;
    item.stage = self.stage;
    item.version = self.version;
    item.handler = self.handler;
    item.target = self.target;
    item.action = self.action;
    item.priority = self.priority;
    item.weight = self.weight;
    item.progress = 0.0;
    item.strategy = self.strategy;
    item.reserved = self.reserved;
    return item;
}

@end

@interface VVDBUpgrader ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *itemLastVersions;

@property (nonatomic, strong) NSMutableArray<VVDBUpgradeItem *> *items;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *stages;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<VVDBUpgradeItem *> *> *stageItems;
@property (nonatomic, assign) NSUInteger totalItemsCount;
@property (nonatomic, assign) NSUInteger completedItemsCount;
@property (nonatomic, copy) NSString *toVersion;

@property (nonatomic, assign) BOOL pretreated;
@property (nonatomic, assign, getter = isUpgrading) BOOL upgrading;
@property (nonatomic, assign, getter = isCanceling) BOOL canceling;
@end

@implementation VVDBUpgrader

- (instancetype)init
{
    self = [super init];
    if (self) {
        _items = [NSMutableArray array];
        _stages = [NSMutableSet set];
        _progress = [NSProgress progressWithTotalUnitCount:100];
        _versionKey = VVDBUpgraderLastVersionKey;
        _toVersion = @"0";
    }
    return self;
}

- (NSMutableDictionary<NSString *,NSString *> *)itemLastVersions
{
    NSAssert(_versionKey.length > 0, @"set versionKey first!");
    if (!_itemLastVersions) {
        NSString *lastVersionsKey = [_versionKey stringByAppendingString:VVDBUpgraderLastVersionsKeySuffix];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *dic = [defaults objectForKey:lastVersionsKey];
        if (![dic isKindOfClass:NSDictionary.class]) {
            if(dic) [defaults removeObjectForKey:lastVersionsKey];
            dic = @{};
            [defaults setObject:dic forKey:lastVersionsKey];
            [defaults synchronize];
        }
        _itemLastVersions = [dic mutableCopy];
    }
    return _itemLastVersions;
}

- (void)reset
{
    for (VVDBUpgradeItem *item in self.items) {
        [item reset];
    }
    
    _itemLastVersions = nil;
    _stageItems = nil;
    _totalItemsCount = 0;
    _completedItemsCount = 0;
    _toVersion = @"0";
    
    _progress.completedUnitCount = 0;
    
    _pretreated = NO;
    _upgrading = NO;
    _canceling = NO;

}

- (void)cancel
{
    if (!_upgrading) return;
    _canceling = YES;
}

- (void)addItem:(VVDBUpgradeItem *)item
{
    [self.items addObject:item];
    [self.stages addObject:@(item.stage)];
    _pretreated = NO;
}

- (void)addItems:(NSArray<VVDBUpgradeItem *> *)items
{
    for (VVDBUpgradeItem *item in items) {
        [self addItem:item];
    }
}

- (void)addItem:(VVDBUpgradeItem *)item to:(NSMutableDictionary<NSNumber *, NSMutableArray<VVDBUpgradeItem *> *> *)stageItems
{
    NSAssert(item.version.length > 0, @"Invalid upgrade item.");
    NSMutableArray *items = stageItems[@(item.stage)];
    if (!items) {
        items = [NSMutableArray array];
        stageItems[@(item.stage)] = items;
    }
    [items addObject:item];
}

- (void)calculateProgress{
    CGFloat completedWeight = 0;
    for (NSMutableArray<VVDBUpgradeItem *> *items in self.stageItems.allValues) {
        for (VVDBUpgradeItem *item in items) {
            completedWeight += item.weight * item.progress;
        }
    }
    self.progress.completedUnitCount = (int64_t)(completedWeight * VVDBUpgraderProgressAccuracy);
}

- (void)pretreat
{
    if (_pretreated || _upgrading) return;
    @synchronized (self) {
        [self _pretreat];
    }
}

- (void)_pretreat
{
    [self reset];
    
    NSDictionary<NSString *, NSString *> *itemVersions = [NSDictionary dictionaryWithDictionary:self.itemLastVersions];
    CGFloat totalWeight = 0;
    __weak typeof(self) weakSelf = self;
    NSMutableDictionary<NSNumber *, NSMutableArray<VVDBUpgradeItem *> *> *stageItems = [NSMutableDictionary dictionary];
    for (VVDBUpgradeItem *item in self.items) {
        NSString *lastVersion = [itemVersions objectForKey:item.identifier];
        if (![self isNeedToUpgrade:item lastVersion:lastVersion]) continue;
        [self addItem:item to:stageItems];
        _totalItemsCount ++;
        totalWeight += item.weight;
        
        [item setProgressBlock:^(CGFloat progress) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf calculateProgress];
        }];
        
        if ([NSString vv_compareVersion:_toVersion with:item.version] == NSOrderedAscending) {
            _toVersion = item.version;
        }
    }
    
    _progress.totalUnitCount = (int64_t)(totalWeight * VVDBUpgraderProgressAccuracy);
    _progress.completedUnitCount = 0;
    _stageItems = stageItems;
    _pretreated = YES;
}

- (BOOL)needUpgrade
{
    [self pretreat];
    return self.stageItems.count > 0;
}

- (BOOL)isNeedToUpgrade:(VVDBUpgradeItem *)item lastVersion:(NSString *)lastVersion {
    switch (item.strategy) {
        case VVDBUpgradeStrategyDefault:
            if (!lastVersion.length ||
                (lastVersion.length && item.version.length &&
                 [NSString vv_compareVersion:lastVersion with:item.version] > NSOrderedAscending)) {
                return NO;
            }
            break;

        case VVDBUpgradeStrategyForceNoRecord:
            if (lastVersion.length && item.version.length &&
                 [NSString vv_compareVersion:lastVersion with:item.version] > NSOrderedAscending) {
                return NO;
            }
            break;

        default:
            break;
    }
    return YES;
}

- (BOOL)isNeedToUpgrade:(VVDBUpgradeItem *)item
{
    NSString *lastVersion = [self.itemLastVersions objectForKey:item.identifier];
    return [self isNeedToUpgrade:item lastVersion:lastVersion];
}

- (void)upgradeAll
{
    [self pretreat];
    NSArray *sorted = [self.stages.allObjects sortedArrayUsingComparator:^NSComparisonResult (NSNumber *stage1, NSNumber *stage2) {
        NSUInteger s1 = stage1.unsignedIntegerValue;
        NSUInteger s2 = stage2.unsignedIntegerValue;
        return s1 < s2 ? NSOrderedAscending : (s1 > s2 ? NSOrderedDescending : NSOrderedSame);
    }];
    for (NSNumber *stage in sorted) {
        [self upgradeStage:stage.unsignedIntegerValue];
    }
}

- (void)upgradeStage:(NSUInteger)stage
{
    [self pretreat];
    NSArray<VVDBUpgradeItem *> *items = self.stageItems[@(stage)];
    [self upgradeItems:items];
}

- (void)upgradeItems:(NSArray<VVDBUpgradeItem *> *)items
{
    if (_upgrading) return;
    _upgrading = YES;

    [self pretreat];
    NSArray *sorted = [items sortedArrayUsingComparator:^NSComparisonResult (VVDBUpgradeItem *item1, VVDBUpgradeItem *item2) {
        return [item1 compare:item2];
    }];

    for (VVDBUpgradeItem *item in sorted) {
        if (_canceling) break;
        BOOL ret = [self upgradeItem:item];
        if (ret) {
            [self completeItem:item];
        }
    }
    _canceling = NO;
    _upgrading = NO;
}

- (BOOL)upgradeItem:(VVDBUpgradeItem *)item
{
    if (item.progress >= 1.0) return YES;
    BOOL ret = NO;
    if (item.target && item.action) {
        if ([item.target respondsToSelector:item.action]) {
            NSMethodSignature *signature = [(NSObject *)item.target methodSignatureForSelector:item.action];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            invocation.target = item.target;
            invocation.selector = item.action;
            [invocation setArgument:&item atIndex:2];
            [invocation invoke];
            [invocation getReturnValue:&ret];
        }
    } else if (item.handler) {
        ret = item.handler(item);
    } else {
        ret = YES;
    }
    if (ret) {
        item.progress = 1.0;
    }
#if DEBUG
    printf("\nU-> %s\n", item.description.UTF8String);
#endif
    return ret;
}

- (void)updateLastVersion:(VVDBUpgradeItem *)item
{
    NSAssert(_versionKey.length > 0, @"set versionKey first!");
    NSString *lastVersionsKey = [_versionKey stringByAppendingString:VVDBUpgraderLastVersionsKeySuffix];
    self.itemLastVersions[item.identifier] = item.version;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.itemLastVersions forKey:lastVersionsKey];
    [defaults synchronize];
}

- (void)completeItem:(VVDBUpgradeItem *)item
{
    [self updateLastVersion:item];
    
    _completedItemsCount ++;
    BOOL completedAll = _completedItemsCount >= _totalItemsCount;
    if (completedAll) {
        [[NSUserDefaults standardUserDefaults] setObject:_toVersion forKey:_versionKey];
    }
}

//MARK: - Debug
- (void)debugUpgradeItems:(NSArray<VVDBUpgradeItem *> *)items progress:(NSProgress *)progress
{
    if (_upgrading) return;
    _upgrading = YES;
    NSMutableArray *copied = [NSMutableArray arrayWithCapacity:items.count];
    for (VVDBUpgradeItem *item in items) {
        [copied addObject:item.copy];
    }
    
    NSArray *sorted = [copied sortedArrayUsingComparator:^NSComparisonResult (VVDBUpgradeItem *item1, VVDBUpgradeItem *item2) {
        return [item1 compare:item2];
    }];
    
    CGFloat totalWeight = 0;
    for (VVDBUpgradeItem *item in sorted) {
        totalWeight += item.weight;
        [item setProgressBlock:^(CGFloat x) {
            CGFloat completedWeight = 0;
            for (VVDBUpgradeItem *dbgitem in sorted) {
                completedWeight += dbgitem.weight * dbgitem.progress;
            }
            progress.completedUnitCount = (int64_t)(completedWeight * VVDBUpgraderProgressAccuracy);
        }];
    }

    progress.totalUnitCount = (int64_t)(totalWeight * VVDBUpgraderProgressAccuracy);
    progress.completedUnitCount = 0;
    for (VVDBUpgradeItem *item in sorted) {
        if (_canceling) break;
        [self upgradeItem:item];
    }
    _canceling = NO;
    _upgrading = NO;
}

@end
