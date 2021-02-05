
#import "VVMessage.h"
#import "VVMock.h"

@implementation VVMessage

+ (NSArray<VVMessage *> *)mockThousandModels:(long long)startMessageId {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:1000];
    for (long long i = 0; i < 1000; i++) {
        VVMessage *message = [VVMessage new];
        message.dialog_id = @"S-10086";
        message.message_id = startMessageId + i;
        message.client_message_id = startMessageId + i;
        message.send_time = [[NSDate date] timeIntervalSince1970];
        message.type = arc4random_uniform(5);
        message.info = [VVMock.shared shortText];
        [array addObject:message];
    }
    return array;
}

+ (NSArray<VVMessage *> *)mockThousandModels:(NSArray<NSString *> *)infos start:(long long)startMessageId {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:1000];
    long long count = infos.count;
    for (long long i = 0; i < 1000; i++) {
        long long messageId = startMessageId + i;
        VVMessage *message = [VVMessage new];
        message.dialog_id = @"S-10086";
        message.message_id = messageId;
        message.client_message_id = startMessageId + i;
        message.send_time = [[NSDate date] timeIntervalSince1970];
        message.type = arc4random_uniform(5);
        message.info = infos[(NSUInteger)messageId % count];
        [array addObject:message];
    }
    return array;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@,%@,%@,%@: %@", _dialog_id, @(_message_id), @(_send_time), @(_type), _info];
}

@end

@implementation VVMessage (VVOrmable)

+ (NSArray<NSString *> *)primaries
{
    return @[@"message_id"];
}

@end

@implementation VVMessage (VVFtsable)

+ (NSArray<NSString *> *)fts_indexes
{
    return @[@"info"];
}

+ (NSString *)fts_tokenizer
{
    return @"sequelize 3";
}

@end
