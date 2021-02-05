
#import <Foundation/Foundation.h>

@interface VVMock : NSObject

+ (instancetype)shared;

- (NSString *)nick;

- (NSString *)name;

- (NSString *)shortText;

- (NSString *)longText;

- (NSString *)longLongText;

- (NSString *)textEn;

- (NSString *)mobile;

- (NSString *)email;

@end
