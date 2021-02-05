//
//  NSObject+VVKeyValue.m
//  VVSequelize
//
//  Created by Valo on 2018/7/13.
//

#import "NSObject+VVKeyValue.h"
#import "VVClassInfo.h"
#import <objc/message.h>

NSString * NSStringFromCoordinate2D(CLLocationCoordinate2D coordinate2D)
{
    return [NSString stringWithFormat:@"{%f,%f}", coordinate2D.latitude, coordinate2D.longitude];
}

CLLocationCoordinate2D Coordinate2DFromString(NSString *string)
{
    if ([string hasPrefix:@"{"] && [string hasSuffix:@"}"]) {
        NSString *content = [string substringWithRange:NSMakeRange(1, string.length - 2)];
        NSArray *array = [content componentsSeparatedByString:@","];
        if (array.count == 2) {
            return CLLocationCoordinate2DMake([array[0] doubleValue], [array[1] doubleValue]);
        }
    }
    return CLLocationCoordinate2DMake(0, 0);
}

static const uint8_t invalidDigit = 128;

static uint8_t digitFromChar(unichar c)
{
    if (c >= '0' && c <= '9') {
        return c - '0';
    } else if (c >= 'A' && c <= 'F') {
        return 10 + c - 'A';
    } else if (c >= 'a' && c <= 'f') {
        return 10 + c - 'a';
    } else {
        return invalidDigit;
    }
}

@implementation NSData (VVKeyValue)
+ (instancetype)dataWithValue:(NSValue *)value
{
    NSUInteger size;
    const char *encoding = [value objCType];
    NSGetSizeAndAlignment(encoding, &size, NULL);
    void *ptr = malloc(size);
    [value getValue:ptr];
    NSData *data = [NSData dataWithBytes:ptr length:size];
    free(ptr);
    return data;
}

+ (instancetype)dataWithNumber:(NSNumber *)number
{
    return [NSData dataWithValue:(NSValue *)number];
}

+ (nullable instancetype)vv_dataWithHexString:(NSString *)hexString
{
    if (!hexString) return nil;

    const NSUInteger charLength = hexString.length;
    const NSUInteger maxByteLength = charLength / 2;
    uint8_t *const bytes = malloc(maxByteLength);
    uint8_t *bytePtr = bytes;

    CFStringInlineBuffer inlineBuffer;
    CFStringInitInlineBuffer((CFStringRef)hexString, &inlineBuffer, CFRangeMake(0, charLength));

    // Each byte is made up of two hex characters; store the outstanding half-byte until we read the second
    uint8_t hiDigit = invalidDigit;
    for (CFIndex i = 0; i < charLength; ++i) {
        uint8_t nextDigit = digitFromChar(CFStringGetCharacterFromInlineBuffer(&inlineBuffer, i));

        if (nextDigit == invalidDigit) {
            free(bytes);
            return nil;
        } else if (hiDigit == invalidDigit) {
            hiDigit = nextDigit;
        } else if (nextDigit != invalidDigit) {
            // Have next full byte
            *bytePtr++ = (hiDigit << 4) | nextDigit;
            hiDigit = invalidDigit;
        }
    }

    if (hiDigit != invalidDigit) { // trailing hex character
        free(bytes);
        return nil;
    }

    return [[NSData alloc] initWithBytesNoCopy:bytes length:(bytePtr - bytes) freeWhenDone:YES];
}

- (NSString *)hexString
{
    const char *hexTable = "0123456789ABCDEF";

    const NSUInteger byteLength = self.length;
    const NSUInteger charLength = byteLength * 2;
    char *const hexChars = malloc(charLength * sizeof(*hexChars));
    __block char *charPtr = hexChars;

    [self enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        const uint8_t *bytePtr = bytes;
        for (NSUInteger count = 0; count < byteRange.length; ++count) {
            const uint8_t byte = *bytePtr++;
            *charPtr++ = hexTable[(byte >> 4) & 0xF];
            *charPtr++ = hexTable[byte & 0xF];
        }
    }];

    return [[NSString alloc] initWithBytesNoCopy:hexChars length:charLength encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

@end

@implementation NSValue (VVKeyValue)
- (NSString *)vv_encodedString
{
    NSString *convertStr = @"<unconvertable>";
    NSString *typeEncoding = [NSString stringWithUTF8String:self.objCType];
    VVStructType structType = VVStructGetType(typeEncoding);
    switch (structType) {
        case VVStructTypeNSRange: convertStr = NSStringFromRange(self.rangeValue); break;
        case VVStructTypeCGPoint: convertStr = NSStringFromCGPoint(self.CGPointValue); break;
        case VVStructTypeCGVector: convertStr = NSStringFromCGVector(self.CGVectorValue); break;
        case VVStructTypeCGSize: convertStr = NSStringFromCGSize(self.CGSizeValue); break;
        case VVStructTypeCGRect: convertStr = NSStringFromCGRect(self.CGRectValue); break;
        case VVStructTypeCGAffineTransform: convertStr = NSStringFromCGAffineTransform(self.CGAffineTransformValue); break;
        case VVStructTypeUIEdgeInsets: convertStr = NSStringFromUIEdgeInsets(self.UIEdgeInsetsValue); break;
        case VVStructTypeUIOffset: convertStr = NSStringFromUIOffset(self.UIOffsetValue); break;
        case VVStructTypeCLLocationCoordinate2D: convertStr = NSStringFromCoordinate2D(self.coordinate2DValue); break;
        case VVStructTypeNSDirectionalEdgeInsets:
            if (@available(iOS 11.0, *)) {
                convertStr = NSStringFromDirectionalEdgeInsets(self.directionalEdgeInsetsValue);
            }
            break;
        default: break;
    }
    NSData *data = [NSData dataWithValue:self];
    return [NSString stringWithFormat:@"%@|%@|%@", typeEncoding, convertStr, data.hexString];
}

+ (nullable instancetype)vv_decodedWithString:(NSString *)encodedString
{
    NSArray *array = [encodedString componentsSeparatedByString:@"|"];
    if (array.count != 3) return nil;
    NSData *data = [NSData vv_dataWithHexString:array[2]];
    char *objCType = (char *)[array[0] UTF8String];
    return [NSValue valueWithBytes:data.bytes objCType:objCType];
}

- (CLLocationCoordinate2D)coordinate2DValue
{
    CLLocationCoordinate2D coordinate2D = CLLocationCoordinate2DMake(0, 0);
    if (@available(iOS 11.0, *)) {
        NSUInteger size;
        NSGetSizeAndAlignment(@encode(CLLocationCoordinate2D), &size, NULL);
        [self getValue:&coordinate2D size:size];
    } else {
        [self getValue:&coordinate2D];
    }
    return coordinate2D;
}

+ (instancetype)valueWithCoordinate2D:(CLLocationCoordinate2D)coordinate2D
{
    return [NSValue valueWithBytes:&coordinate2D objCType:@encode(CLLocationCoordinate2D)];
}

@end

@implementation NSDate (VVKeyValue)

+ (NSDateFormatter *)vv_dateFormater
{
    static NSDateFormatter *_dateFormater;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormater = [[NSDateFormatter alloc] init];
        _dateFormater.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormater.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        _dateFormater.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    });
    return _dateFormater;
}

- (NSString *)vv_dateString
{
    return [[NSDate vv_dateFormater] stringFromDate:self];
}

+ (instancetype)vv_dateWithString:(NSString *)dateString
{
    return [[NSDate vv_dateFormater] dateFromString:dateString];
}

@end

@implementation NSObject (VVKeyValue)

- (nullable id)vv_dbStoreValue
{
    if ([self isKindOfClass:[NSString class]]
        || [self isKindOfClass:[NSNumber class]]
        || [self isKindOfClass:[NSData class]]) {
        return self;
    }
    id targetVal = [self vv_targetValue];
    if ([targetVal isKindOfClass:[NSString class]]) {
        return targetVal;
    } else if ([targetVal isKindOfClass:[NSArray class]]) {
        NSArray *array = [[self class] convertArrayInlineDataToString:targetVal];
        NSData *data = [NSJSONSerialization dataWithJSONObject:array options:0 error:nil];
        if (data.length == 0) return nil;
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else if ([targetVal isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dic = [[self class] convertDictionaryInlineDataToString:targetVal];
        NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
        if (data.length == 0) return nil;
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return [targetVal description];
}

- (NSDictionary *)vv_keyValues
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    VVClassInfo *info = [VVClassInfo classInfoWithClass:self.class];
    NSSet *whites = [NSSet setWithArray:[[self class] whiteProperties]];
    if (whites.count > 0) {
        for (VVPropertyInfo *prop in info.properties) {
            if (![whites containsObject:prop.name]) continue;
            dic[prop.name] = [self valueForProperty:prop];
        }
    } else {
        NSSet *blacks = [NSSet setWithArray:[[self class] blackProperties]];
        for (VVPropertyInfo *prop in info.properties) {
            if ([blacks containsObject:prop.name]) continue;
            dic[prop.name] = [self valueForProperty:prop];
        }
    }
    return dic;
}

+ (instancetype)vv_objectWithKeyValues:(NSDictionary<NSString *, id> *)keyValues
{
    NSObject *obj = [[self alloc] init];
    VVClassInfo *info = [VVClassInfo classInfoWithClass:self.class];
    NSArray *whites = [self whiteProperties];
    if (whites.count > 0) {
        for (VVPropertyInfo *prop in info.properties) {
            if (![whites containsObject:prop.name]) continue;
            [obj setValue:keyValues[prop.name] forProperty:prop];
        }
    } else {
        NSArray *blacks = [self blackProperties];
        for (VVPropertyInfo *prop in info.properties) {
            if ([blacks containsObject:prop.name]) continue;
            [obj setValue:keyValues[prop.name] forProperty:prop];
        }
    }
    return obj;
}

+ (NSArray *)vv_keyValuesArrayWithObjects:(NSArray *)objects
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
    for (NSObject *obj in objects) {
        [array addObject:[obj vv_keyValues]];
    }
    return array;
}

+ (NSArray *)vv_objectsWithKeyValuesArray:(id)keyValuesArray
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
    for (NSDictionary *dic in keyValuesArray) {
        [array addObject:[self vv_objectWithKeyValues:dic]];
    }
    return array;
}

//MARK: - Private
+ (NSDictionary *)customMapper
{
    SEL sel = @selector(vv_collectionMapper);
    if ([self respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSDictionary *dic = [self performSelector:sel];
#pragma clang diagnostic pop
        return dic;
    }
    return nil;
}

+ (NSArray *)blackProperties
{
    SEL sel = @selector(vv_blackProperties);
    if ([self respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSArray *array = [self performSelector:sel];
#pragma clang diagnostic pop
        return array;
    }
    return nil;
}

+ (NSArray *)whiteProperties
{
    SEL sel = @selector(vv_whiteProperties);
    if ([self respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSArray *array = [self performSelector:sel];
#pragma clang diagnostic pop
        return array;
    }
    return nil;
}

/// generate db storage data
/// @note NSData->Blob, NSURL->String, Array->JsonString, Dictionary->JsonString, NSValue->Blob, OtherClass->JsonString
- (id)vv_targetValue
{
    VVEncodingNSType nstype = VVClassGetNSType(self.class);
    switch (nstype) {
        case VVEncodingTypeNSDate: //NSDate --> date string
            return [(NSDate *)self vv_dateString];

        case VVEncodingTypeNSURL:  //NSURL转换为字符串
            return [(NSURL *)self relativeString];

        case VVEncodingTypeNSArray:
        case VVEncodingTypeNSMutableArray:
        case VVEncodingTypeNSSet:
        case VVEncodingTypeNSMutableSet: {
            id<NSFastEnumeration> colletion = (id<NSFastEnumeration>)self;
            NSMutableArray *vals = [NSMutableArray arrayWithCapacity:0];
            for (id obj in colletion) {
                id subval = [obj vv_targetValue];
                if (subval) [vals addObject:subval];
            }
            return vals;
        }

        case VVEncodingTypeNSDictionary:
        case VVEncodingTypeNSMutableDictionary: {
            NSDictionary *dic = (NSDictionary *)self;
            NSMutableDictionary *vals = [NSMutableDictionary dictionaryWithCapacity:0];
            for (NSString *key in dic.allKeys) {
                vals[key] = [dic[key] vv_targetValue];
            }
            return vals;
        }

        case VVEncodingTypeNSValue: {
            NSValue *val = (NSValue *)self;
            return [val vv_encodedString];
        }

        case VVEncodingTypeNSUnknown: {
            return [self vv_keyValues];
        }

        default:
            return self;
    }
}

+ (NSArray *)convertArrayInlineDataToString:(NSArray *)array
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:0];
    for (id obj in array) {
        if ([obj isKindOfClass:NSData.class]) {
            [tempArray addObject:[obj hexString]];
        } else if ([obj isKindOfClass:NSArray.class]) {
            [tempArray addObject:[self convertArrayInlineDataToString:obj]];
        } else if ([obj isKindOfClass:NSDictionary.class]) {
            [tempArray addObject:[self convertDictionaryInlineDataToString:obj]];
        } else {
            [tempArray addObject:obj];
        }
    }
    return tempArray;
}

+ (NSDictionary *)convertDictionaryInlineDataToString:(NSDictionary *)dictionary
{
    NSMutableDictionary *tempdic = [NSMutableDictionary dictionaryWithCapacity:0];
    for (NSString *key in dictionary) {
        id obj = dictionary[key];
        if ([obj isKindOfClass:NSData.class]) {
            tempdic[key] = [obj hexString];
        } else if ([obj isKindOfClass:NSArray.class]) {
            tempdic[key] = [self convertArrayInlineDataToString:obj];
        } else if ([obj isKindOfClass:NSDictionary.class]) {
            tempdic[key] = [self convertDictionaryInlineDataToString:obj];
        } else {
            tempdic[key] = obj;
        }
    }
    return tempdic;
}

/// get  storage type for property
/// @note SEL->String, Struct->Blob, Union->Blob, CNumber->Number
- (id)valueForProperty:(VVPropertyInfo *)propertyInfo
{
    id value = [self valueForKey:propertyInfo.name];
    if ([value isKindOfClass:[NSNull class]]) return nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    switch (propertyInfo.type) {
        case VVEncodingTypeCNumber:
        case VVEncodingTypeCRealNumber:
            return value;

        case VVEncodingTypeCString: {
            char *str = (char *)(__bridge void *)[self performSelector:propertyInfo.getter];
            return [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
        }

        case VVEncodingTypeSEL: {
            SEL selector = (__bridge void *)[self performSelector:propertyInfo.getter];
            if (selector) return NSStringFromSelector(selector);
        }

        case VVEncodingTypeStruct: {
            return [(NSValue *)value vv_encodedString];
        }

        case VVEncodingTypeUnion: {
            size_t t = ((size_t (*)(id, SEL))(void *) objc_msgSend)(self, propertyInfo.getter);
            const char *objCType = [propertyInfo.typeEncoding UTF8String];
            NSValue *val = [NSValue valueWithBytes:&t objCType:objCType];
            return [val vv_encodedString];
        }

        case VVEncodingTypePointer: {
            char *bytes = (char *)(__bridge void *)[self performSelector:propertyInfo.getter];
            NSUInteger length = (NSUInteger)strlen(bytes);
            return [NSData dataWithBytes:bytes length:length];
        }

        case VVEncodingTypeObject:
            return [value vv_targetValue];

        default:
            break;
    }
#pragma clang diagnostic pop
    return nil;
}

/// stored data -> original data
- (void)setValue:(id)value forProperty:(VVPropertyInfo *)propertyInfo
{
    NSString *propertyName = propertyInfo.name;
    NSArray *undefinedKeys = @[@"hash", @"description", @"debugDescription"];
    if ([undefinedKeys containsObject:propertyName]) return;
    if (value == nil || [value isKindOfClass:[NSNull class]]) return;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    switch (propertyInfo.type) {
        case VVEncodingTypeCNumber:
        case VVEncodingTypeCRealNumber:
            [self setValue:value forKey:propertyName];
            break;

        case VVEncodingTypeCString:
            if ([value isKindOfClass:[NSString class]]) {
                const char *str = [(NSString *)value UTF8String];
                ((void (*)(id, SEL, const char *))(void *) objc_msgSend)(self, propertyInfo.setter, str);
            }
            break;

        case VVEncodingTypeSEL:
            if ([value isKindOfClass:[NSString class]]) {
                SEL selector = NSSelectorFromString(value);
                ((void (*)(id, SEL, void *))(void *) objc_msgSend)(self, propertyInfo.setter, (void *)selector);
            }
            break;

        case VVEncodingTypeStruct:
            if ([value isKindOfClass:[NSString class]]) {
                NSValue *val = [NSValue vv_decodedWithString:value];
                [self setValue:val forKey:propertyName];
            }
            break;

        case VVEncodingTypeUnion:
            if ([value isKindOfClass:[NSString class]]) {
                NSValue *val = [NSValue vv_decodedWithString:value];
                size_t t;
                NSUInteger size;
                NSGetSizeAndAlignment(val.objCType, &size, NULL);
                if (@available(iOS 11.0, *)) {
                    [val getValue:&t size:size];
                } else {
                    [val getValue:&t];
                }
                ((void (*)(id, SEL, size_t))(void *) objc_msgSend)(self, propertyInfo.setter, t);
            }
            break;

        case VVEncodingTypePointer: {
            NSData *data = nil;
            if ([value isKindOfClass:NSData.class]) {
                data = value;
            } else if ([value isKindOfClass:NSString.class]) {
                data = [NSData vv_dataWithHexString:value];
            }
            if (data) {
                ((void (*)(id, SEL, const void *))(void *) objc_msgSend)(self, propertyInfo.setter, data.bytes);
            }
        } break;

        case VVEncodingTypeObject: {
            VVEncodingNSType nstype = propertyInfo.nsType;
            switch (nstype) {
                case VVEncodingTypeNSDate: //NSDate <-- date string
                {
                    NSDate *date = nil;
                    if ([value isKindOfClass:[NSDate class]]) {
                        date = value;
                    } else if ([value isKindOfClass:[NSString class]]) {
                        date = [NSDate vv_dateWithString:value];
                    }
                    if (date) [self setValue:date forKey:propertyName];
                } break;

                case VVEncodingTypeNSURL:  //NSURL转换为字符串
                    if ([value isKindOfClass:[NSNumber class]]) {
                        NSURL *url = [NSURL URLWithString:value];
                        if (url) [self setValue:url forKey:propertyName];
                    }
                    break;

                case VVEncodingTypeNSArray:
                case VVEncodingTypeNSMutableArray: {
                    NSArray *tempArray = nil;
                    if ([value isKindOfClass:[NSArray class]]) tempArray = value;
                    else if ([value isKindOfClass:[NSString class]]) {
                        NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
                        if (data.length > 0) tempArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    } else if ([value isKindOfClass:[NSData class]]) {
                        tempArray = [NSObject vv_unarchivedObjectOfClass:NSArray.class fromData:value];
                    }
                    if (tempArray && [tempArray isKindOfClass:[NSArray class]]) {
                        NSDictionary *mapper = [[self class] customMapper];
                        Class cls = mapper[propertyName];
                        NSArray *array = cls ? [cls vv_objectsWithKeyValuesArray:tempArray] : tempArray;
                        [self setValue:array forKey:propertyName];
                    }
                } break;

                case VVEncodingTypeNSSet:
                case VVEncodingTypeNSMutableSet: {
                    NSArray *tempArray = nil;
                    if ([value isKindOfClass:[NSArray class]]) tempArray = value;
                    else if ([value isKindOfClass:[NSString class]]) {
                        NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
                        if (data.length > 0) tempArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    } else if ([value isKindOfClass:[NSData class]]) {
                        tempArray = [NSObject vv_unarchivedObjectOfClass:NSArray.class fromData:value];
                    }
                    NSMutableSet *set = nil;
                    if (tempArray) {
                        if ([tempArray isKindOfClass:[NSSet class]]) {
                            set = [(NSSet *)tempArray mutableCopy];
                        } else if ([tempArray isKindOfClass:[NSArray class]]) {
                            set = [NSMutableSet setWithArray:tempArray];
                        }
                    }
                    if (set) [self setValue:set forKey:propertyName];
                } break;

                case VVEncodingTypeNSDictionary:
                case VVEncodingTypeNSMutableDictionary: {
                    NSDictionary *tempDic = nil;
                    if ([value isKindOfClass:[NSDictionary class]]) tempDic = value;
                    else if ([value isKindOfClass:[NSString class]]) {
                        NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
                        if (data.length > 0) tempDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    } else if ([value isKindOfClass:[NSData class]]) {
                        tempDic = [NSObject vv_unarchivedObjectOfClass:NSDictionary.class fromData:value];
                    }
                    if (tempDic) [self setValue:[tempDic mutableCopy] forKey:propertyName];
                } break;

                case VVEncodingTypeNSValue:
                    if ([value isKindOfClass:[NSString class]]) {
                        NSValue *val = [NSValue vv_decodedWithString:value];
                        [self setValue:val forKey:propertyName];
                    }
                    break;

                case VVEncodingTypeNSData:
                    if ([value isKindOfClass:NSString.class]) {
                        NSData *data = [NSData vv_dataWithHexString:value];
                        [self setValue:data forKey:propertyName];
                    } else if ([value isKindOfClass:NSData.class]) {
                        [self setValue:value forKey:propertyName];
                    }
                    break;

                case VVEncodingTypeNSUnknown: {
                    Class cls = propertyInfo.cls;
                    if (!cls) {
                        NSDictionary *mapper = [[self class] customMapper];
                        cls = mapper[propertyName];
                    }
                    if (cls) {
                        if ([value isKindOfClass:[NSDictionary class]]) {
                            id obj = [cls vv_objectWithKeyValues:value];
                            if (obj) [self setValue:obj forKey:propertyName];
                        }
                        if ([value isKindOfClass:[NSString class]]) {
                            NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
                            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                            id obj = [cls vv_objectWithKeyValues:dic];
                            if (obj) [self setValue:obj forKey:propertyName];
                        } else if ([value isKindOfClass:[NSData class]]) {
                            id obj = [NSObject vv_unarchivedObjectOfClass:NSDictionary.class fromData:value];
                            if ([obj isKindOfClass:NSDictionary.class]) {
                                obj = [cls vv_objectWithKeyValues:(NSDictionary *)obj];
                            }
                            if ([obj isKindOfClass:cls]) {
                                [self setValue:obj forKey:propertyName];
                            }
                        } else if ([value isKindOfClass:cls]) {
                            [self setValue:value forKey:propertyName];
                        }
                    }
                } break;

                case VVEncodingTypeNSString:
                    if ([value isKindOfClass:NSString.class]) {
                        [self setValue:value forKey:propertyName];
                    } else if ([value isKindOfClass:NSNumber.class]) {
                        [self setValue:((NSNumber *)value).stringValue forKey:propertyName];
                    } else {
                        [self setValue:[value description] forKey:propertyName];
                    }
                    break;

                case VVEncodingTypeNSNumber:
                    if ([value isKindOfClass:NSNumber.class]) {
                        [self setValue:value forKey:propertyName];
                    } else if ([value isKindOfClass:NSString.class]) {
                        [self setValue:@(((NSString *)value).doubleValue) forKey:propertyName];
                    } else {
                        [self setValue:@([value description].doubleValue) forKey:propertyName];
                    }
                    break;

                case VVEncodingTypeNSUndefined:
                    break;

                default:
                    [self setValue:value forKey:propertyName];
                    break;
            }
        } break;

        default:
            break;
    }
#pragma clang diagnostic pop
}

+ (nullable id)vv_unarchivedObjectOfClass:(Class<NSMutableCopying>)cls fromData:(NSData *)data {
    if (data.length == 0) return nil;
    id object = nil;
    if (@available(iOS 11.0, *)) {
        object = [NSKeyedUnarchiver unarchivedObjectOfClass:cls fromData:data error:nil];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#pragma clang diagnostic pop
    }
    if (!object) object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return object;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    // do Nothing
#if DEBUG
    printf("[VVDB][WARN] setValue: %s forUndefinedKey: %s", [value description].UTF8String, key.UTF8String);
#endif
}

- (void)setNilValueForKey:(NSString *)key
{
#if DEBUG
    printf("[VVDB][WARN] setNilValueForKey: %s", key.UTF8String);
#endif
}

- (id)valueForUndefinedKey:(NSString *)key
{
#if DEBUG
    printf("[VVDB][WARN] valueForUndefinedKey: %s", key.UTF8String);
#endif
    return nil;
}

@end
