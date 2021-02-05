//
//  VVClassInfo.m
//  VVSequelize
//
//  Created by Valo on 2018/7/17.
//

#import "VVClassInfo.h"
#import <CoreLocation/CLLocation.h>

static OS_ALWAYS_INLINE VVEncodingType VVGetEncodingType(const char *typeEncoding, VVPropertyQualifier *qualifier)
{
    char *type = (char *)typeEncoding;
    if (!type) return VVEncodingTypeUnknown;
    size_t len = strlen(type);
    if (len == 0) return VVEncodingTypeUnknown;
    VVPropertyQualifier t_qualifier = 0;
    bool prefix = true;
    while (prefix) {
        switch (*type) {
            case 'r': {
                t_qualifier |= VVPropertyQualifierConst;
                type++;
            } break;
            case 'n': {
                t_qualifier |= VVPropertyQualifierIn;
                type++;
            } break;
            case 'N': {
                t_qualifier |= VVPropertyQualifierInout;
                type++;
            } break;
            case 'o': {
                t_qualifier |= VVPropertyQualifierOut;
                type++;
            } break;
            case 'O': {
                t_qualifier |= VVPropertyQualifierBycopy;
                type++;
            } break;
            case 'R': {
                t_qualifier |= VVPropertyQualifierByref;
                type++;
            } break;
            case 'V': {
                t_qualifier |= VVPropertyQualifierOneway;
                type++;
            } break;
            default: { prefix = false; } break;
        }
    }
    *qualifier = t_qualifier;

    len = strlen(type);
    if (len == 0) return VVEncodingTypeUnknown;
    switch (*type) {
        case 'v': return VVEncodingTypeVoid;
        case 'B': return VVEncodingTypeCNumber;
        case 'c': return VVEncodingTypeCNumber;
        case 'C': return VVEncodingTypeCNumber;
        case 's': return VVEncodingTypeCNumber;
        case 'S': return VVEncodingTypeCNumber;
        case 'i': return VVEncodingTypeCNumber;
        case 'I': return VVEncodingTypeCNumber;
        case 'l': return VVEncodingTypeCNumber;
        case 'L': return VVEncodingTypeCNumber;
        case 'q': return VVEncodingTypeCNumber;
        case 'Q': return VVEncodingTypeCNumber;
        case 'f': return VVEncodingTypeCRealNumber;
        case 'd': return VVEncodingTypeCRealNumber;
        case 'D': return VVEncodingTypeCRealNumber;
        case '#': return VVEncodingTypeClass;
        case ':': return VVEncodingTypeSEL;
        case '*': return VVEncodingTypeCString;
        case '^': return VVEncodingTypePointer;
        case '[': return VVEncodingTypeCArray;
        case '(': return VVEncodingTypeUnion;
        case '{': return VVEncodingTypeStruct;
        case '@': {
            if (len == 2 && *(type + 1) == '?') return VVEncodingTypeBlock;
            else return VVEncodingTypeObject;
        }
        default: return VVEncodingTypeUnknown;
    }
}

VVEncodingNSType VVClassGetNSType(Class cls)
{
    if (!cls) return VVEncodingTypeNSUndefined;
    if ([cls isSubclassOfClass:[NSMutableString class]]) return VVEncodingTypeNSMutableString;
    if ([cls isSubclassOfClass:[NSString class]]) return VVEncodingTypeNSString;
    if ([cls isSubclassOfClass:[NSDecimalNumber class]]) return VVEncodingTypeNSDecimalNumber;
    if ([cls isSubclassOfClass:[NSNumber class]]) return VVEncodingTypeNSNumber;
    if ([cls isSubclassOfClass:[NSValue class]]) return VVEncodingTypeNSValue;
    if ([cls isSubclassOfClass:[NSMutableData class]]) return VVEncodingTypeNSMutableData;
    if ([cls isSubclassOfClass:[NSData class]]) return VVEncodingTypeNSData;
    if ([cls isSubclassOfClass:[NSDate class]]) return VVEncodingTypeNSDate;
    if ([cls isSubclassOfClass:[NSURL class]]) return VVEncodingTypeNSURL;
    if ([cls isSubclassOfClass:[NSMutableArray class]]) return VVEncodingTypeNSMutableArray;
    if ([cls isSubclassOfClass:[NSArray class]]) return VVEncodingTypeNSArray;
    if ([cls isSubclassOfClass:[NSMutableDictionary class]]) return VVEncodingTypeNSMutableDictionary;
    if ([cls isSubclassOfClass:[NSDictionary class]]) return VVEncodingTypeNSDictionary;
    if ([cls isSubclassOfClass:[NSMutableSet class]]) return VVEncodingTypeNSMutableSet;
    if ([cls isSubclassOfClass:[NSSet class]]) return VVEncodingTypeNSSet;
    return VVEncodingTypeNSUnknown;
}

VVStructType VVStructGetType(NSString *typeEncodeing)
{
    if (typeEncodeing.length == 0) return VVStructTypeUnknown;
    const char *encoding = [typeEncodeing UTF8String];
    if (strcmp(encoding, @encode(NSRange)) == 0) return VVStructTypeNSRange;
    if (strcmp(encoding, @encode(CGPoint)) == 0) return VVStructTypeCGPoint;
    if (strcmp(encoding, @encode(CGVector)) == 0) return VVStructTypeCGVector;
    if (strcmp(encoding, @encode(CGSize)) == 0) return VVStructTypeCGSize;
    if (strcmp(encoding, @encode(CGRect)) == 0) return VVStructTypeCGRect;
    if (strcmp(encoding, @encode(CGAffineTransform)) == 0) return VVStructTypeCGAffineTransform;
    if (strcmp(encoding, @encode(UIEdgeInsets)) == 0) return VVStructTypeUIEdgeInsets;
    if (strcmp(encoding, @encode(UIOffset)) == 0) return VVStructTypeUIOffset;
    if (strcmp(encoding, @encode(CLLocationCoordinate2D)) == 0) return VVStructTypeCLLocationCoordinate2D;
    if (@available(iOS 11.0, *)) {
        if (strcmp(encoding, @encode(NSDirectionalEdgeInsets)) == 0) return VVStructTypeNSDirectionalEdgeInsets;
    }
    return VVStructTypeUnknown;
}

@implementation VVPropertyInfo
- (instancetype)initWithProperty:(objc_property_t)property
{
    if (!property) return nil;
    self = [super init];
    _property = property;
    const char *name = property_getName(property);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    VVPropertyKeyword keyword = 0;
    VVPropertyQualifier qualifier = 0;
    unsigned int attrCount;
    objc_property_attribute_t *attrs = property_copyAttributeList(property, &attrCount);
    for (unsigned int i = 0; i < attrCount; i++) {
        switch (attrs[i].name[0]) {
            //MAKR: type & nsType
            case 'T': { // Type encoding
                if (attrs[i].value) {
                    _typeEncoding = [NSString stringWithUTF8String:attrs[i].value];
                    _type = VVGetEncodingType(attrs[i].value, &qualifier);
                    _qualifier = qualifier;
                    if (_typeEncoding.length > 0) {
                        switch (_type) {
                            case VVEncodingTypeObject: {
                                NSScanner *scanner = [NSScanner scannerWithString:_typeEncoding];
                                if (![scanner scanString:@"@\"" intoString:NULL]) continue;

                                NSString *clsName = nil;
                                if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"<"] intoString:&clsName]) {
                                    if (clsName.length) {
                                        _cls = objc_getClass(clsName.UTF8String);
                                        _nsType = VVClassGetNSType(_cls);
                                    }
                                }
                            } break;

                            case VVEncodingTypeStruct:
                            case VVEncodingTypeUnion: {
                                NSArray *array = [_typeEncoding componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"({=})"]];
                                if (array.count == 4) _structUnionName = [array[1] isEqualToString:@"?"] ? nil : array[1];
                            } break;

                            default:
                                break;
                        }
                    }
                }
            } break;
            //MARK: ivar name
            case 'V': { // Instance variable
                if (attrs[i].value) {
                    _ivarName = [NSString stringWithUTF8String:attrs[i].value];
                }
            } break;
            //MARK: keyword
            case 'R': {
                keyword |= VVPropertyKeywordReadonly;
            } break;
            case 'C': {
                keyword |= VVPropertyKeywordCopy;
            } break;
            case '&': {
                keyword |= VVPropertyKeywordRetain;
            } break;
            case 'N': {
                keyword |= VVPropertyKeywordNonatomic;
            } break;
            case 'D': {
                keyword |= VVPropertyKeywordDynamic;
            } break;
            case 'W': {
                keyword |= VVPropertyKeywordWeak;
            } break;
            case 'G': {
                keyword |= VVPropertyKeywordCustomGetter;
                if (attrs[i].value) {
                    _getter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                }
            } break;
            case 'S': {
                keyword |= VVPropertyKeywordCustomSetter;
                if (attrs[i].value) {
                    _setter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                }
            } // break; commented for code coverage in next line
            default: break;
        }
    }
    if (attrs) {
        free(attrs);
    }
    _keyword = keyword;

    if (_name.length) {
        if (!_getter) {
            _getter = NSSelectorFromString(_name);
        }
        if (!_setter) {
            _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", [_name substringToIndex:1].uppercaseString, [_name substringFromIndex:1]]);
        }
    }
    return self;
}

@end

@implementation VVClassInfo

- (instancetype)initWithClass:(Class)cls
{
    if (!cls) return nil;
    self = [super init];
    _cls = cls;
    _isMeta = class_isMetaClass(cls);
    if (!_isMeta) {
        _metaCls = objc_getMetaClass(class_getName(cls));
    }
    _name = NSStringFromClass(cls);
    _properties = [VVClassInfo propertyInfosWith:cls];
    return self;
}

+ (instancetype)classInfoWithClass:(Class)cls
{
    if (!cls) return nil;
    static CFMutableDictionaryRef classCache;
    static CFMutableDictionaryRef metaCache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        classCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        metaCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));
    VVClassInfo *info = CFDictionaryGetValue(class_isMetaClass(cls) ? metaCache : classCache, (__bridge const void *)(cls));
    dispatch_semaphore_signal(lock);
    if (!info) {
        info = [[VVClassInfo alloc] initWithClass:cls];
        if (info) {
            dispatch_semaphore_wait(lock, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));
            CFDictionarySetValue(info.isMeta ? metaCache : classCache, (__bridge const void *)(cls), (__bridge const void *)(info));
            dispatch_semaphore_signal(lock);
        }
    }
    return info;
}

+ (NSArray<VVPropertyInfo *> *)propertyInfosWith:(Class)clazz
{
    if ([@"NSObject" isEqualToString:NSStringFromClass(clazz)]) return @[];
    NSArray *ignoreProperties = @[@"hash", @"description", @"debugDescription", @"superclass"];
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(clazz, &propertyCount);
    NSMutableArray *infos = [self propertyInfosWith:clazz.superclass].mutableCopy;
    for (unsigned int i = 0; i < propertyCount; i++) {
        VVPropertyInfo *info = [[VVPropertyInfo alloc] initWithProperty:properties[i]];
        if (info.name.length == 0 || [ignoreProperties containsObject:info.name]) continue;
        [infos addObject:info];
    }
    if (properties) {
        free(properties);
    }
    return infos.copy;
}

@end
