
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class VVDatabase,VVOrm;

@interface VVItem : NSObject
@property (nonatomic, copy  ) NSString *tableName;
@property (nonatomic, assign) unsigned long long count;
@property (nonatomic, assign) unsigned long long maxCount;
@property (nonatomic, weak  ) UILabel *label;

@property (nonatomic, copy  ) NSString   *dbName;
@property (nonatomic, copy  ) NSString   *dbPath;
@property (nonatomic, strong) VVOrm      *orm;
@property (nonatomic, strong) VVDatabase *db;
@property (nonatomic, assign) unsigned long long fileSize;

@property (nonatomic, copy  ) NSString   *ftsDbName;
@property (nonatomic, copy  ) NSString   *ftsDbPath;
@property (nonatomic, strong) VVOrm      *ftsOrm;
@property (nonatomic, strong) VVDatabase *ftsDb;
@property (nonatomic, assign) unsigned long long ftsFileSize;

@end

NS_ASSUME_NONNULL_END
