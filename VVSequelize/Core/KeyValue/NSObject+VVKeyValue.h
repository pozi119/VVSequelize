//
//  NSObject+VVKeyValue.h
//  VVSequelize
//
//  Created by Valo on 2018/7/13.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

NS_ASSUME_NONNULL_BEGIN

/// coordinate -> string
FOUNDATION_EXPORT NSString * NSStringFromCoordinate2D(CLLocationCoordinate2D coordinate2D);

/// string -> coordinate
FOUNDATION_EXPORT CLLocationCoordinate2D Coordinate2DFromString(NSString *string);

@interface NSData (VVKeyValue)

/// NSValue -> NSData
+ (instancetype)dataWithValue:(NSValue *)value;

/// NSData -> NSValue
+ (instancetype)dataWithNumber:(NSNumber *)number;

/// hex data string -> NSData
+ (nullable instancetype)vv_dataWithHexString:(NSString *)hexString;

/// data -> hex string
- (NSString *)hexString;
@end

@interface NSValue (VVKeyValue)

/// encode NSValue as <ObjCType>|<valueString>|<Data String>
- (NSString *)vv_encodedString;

/// decode <ObjCType>|<valueString>|<Data String> into NSValue
+ (nullable instancetype)vv_decodedWithString:(NSString *)encodedString;

/// NSValue -> coordinate
- (CLLocationCoordinate2D)coordinate2DValue;

/// coordinate -> NSValue
+ (instancetype)valueWithCoordinate2D:(CLLocationCoordinate2D)coordinate2D;

@end

@interface NSDate (VVKeyValue)

/// NSDate -> "yyyy-MM-dd HH:mm:ss.SSS"
- (NSString *)vv_dateString;

/// "yyyy-MM-dd HH:mm:ss.SSS" -> NSDate
+ (instancetype)vv_dateWithString:(NSString *)dateString;

@end

@protocol VVKeyValue <NSObject>
@optional
/// class in Array/Set, key: array property name, value: class or name
+ (nullable NSDictionary *)vv_collectionMapper;

/// black list
+ (nullable NSArray<NSString *> *)vv_blackProperties;

/// white list
+ (nullable NSArray<NSString *> *)vv_whiteProperties;

@end

/// NSObject <-> NSDictionary/NSArray, used for VVDB
/// @note basic converision, field mapping and white/black list is not supported, do not consider efficiency
@interface NSObject (VVKeyValue)

/// generate store value for db
/// @return NSData/NSString/NSNumber
- (nullable id)vv_dbStoreValue;

/// object -> dictionary
/// @note support NSSelector and C types: char, string, struct, union
- (NSDictionary *)vv_keyValues;

/// dictionary -> object
+ (instancetype)vv_objectWithKeyValues:(NSDictionary<NSString *, id> *)keyValues;

/// objects -> dictionary array
+ (NSArray *)vv_keyValuesArrayWithObjects:(NSArray *)objects;

/// dictionary array -> objects
+ (NSArray *)vv_objectsWithKeyValuesArray:(id)keyValuesArray;

@end

NS_ASSUME_NONNULL_END
