
#import <Foundation/Foundation.h>
#import <VVSequelize/VVSequelize.h>

NS_ASSUME_NONNULL_BEGIN

@interface VVMessage : NSObject

@property (nonatomic, copy) NSString *dialog_id;
@property (nonatomic, assign) long long message_id;
@property (nonatomic, assign) long long client_message_id;
@property (nonatomic, assign) long long send_time;
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, copy) NSString *info;

+ (NSArray<VVMessage *> *)mockThousandModels:(long long)startMessageId;

+ (NSArray<VVMessage *> *)mockThousandModels:(NSArray<NSString *> *)infos start:(long long)startMessageId;

@end

@interface VVMessage (VVOrmable) <VVOrmable>

@end

@interface VVMessage (VVFtsable) <VVFtsable>

@end

NS_ASSUME_NONNULL_END
