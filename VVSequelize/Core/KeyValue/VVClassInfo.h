//
//  VVClassInfo.h
//  VVSequelize
//
//  Created by Valo on 2018/7/17.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, VVEncodingType) {
    VVEncodingTypeUnknown = 0,  ///< unknown
    VVEncodingTypeVoid,         ///< void
    VVEncodingTypeCNumber,      ///< bool /char / unsigned char ....
    VVEncodingTypeCRealNumber,  ///< float / double ..
    VVEncodingTypeObject,       ///< id
    VVEncodingTypeClass,        ///< Class
    VVEncodingTypeSEL,          ///< SEL
    VVEncodingTypeBlock,        ///< block
    VVEncodingTypePointer,      ///< void*
    VVEncodingTypeStruct,       ///< struct
    VVEncodingTypeUnion,        ///< union
    VVEncodingTypeCString,      ///< char*
    VVEncodingTypeCArray,       ///< char[10] (for example)
};

typedef NS_ENUM (NSUInteger, VVEncodingNSType) {
    VVEncodingTypeNSUndefined = 0,
    VVEncodingTypeNSString,
    VVEncodingTypeNSMutableString,
    VVEncodingTypeNSValue,
    VVEncodingTypeNSNumber,
    VVEncodingTypeNSDecimalNumber,
    VVEncodingTypeNSData,
    VVEncodingTypeNSMutableData,
    VVEncodingTypeNSDate,
    VVEncodingTypeNSURL,
    VVEncodingTypeNSArray,
    VVEncodingTypeNSMutableArray,
    VVEncodingTypeNSDictionary,
    VVEncodingTypeNSMutableDictionary,
    VVEncodingTypeNSSet,
    VVEncodingTypeNSMutableSet,
    VVEncodingTypeNSUnknown = 999,
};

typedef NS_ENUM (NSUInteger, VVStructType) {
    VVStructTypeUnknown = 0,
    VVStructTypeNSRange,
    VVStructTypeCGPoint,
    VVStructTypeCGVector,
    VVStructTypeCGSize,
    VVStructTypeCGRect,
    VVStructTypeCGAffineTransform,
    VVStructTypeUIEdgeInsets,
    VVStructTypeUIOffset,
    VVStructTypeCLLocationCoordinate2D,
    VVStructTypeNSDirectionalEdgeInsets,
};

FOUNDATION_EXPORT VVEncodingNSType VVClassGetNSType(Class cls);
FOUNDATION_EXPORT VVStructType VVStructGetType(NSString *typeEncodeing);

typedef NS_OPTIONS (NSUInteger, VVPropertyKeyword) {
    VVPropertyKeywordReadonly     = 1 << 0, ///< readonly
    VVPropertyKeywordCopy         = 1 << 1, ///< copy
    VVPropertyKeywordRetain       = 1 << 2, ///< retain
    VVPropertyKeywordNonatomic    = 1 << 3, ///< nonatomic
    VVPropertyKeywordWeak         = 1 << 4, ///< weak
    VVPropertyKeywordCustomGetter = 1 << 5, ///< getter=
    VVPropertyKeywordCustomSetter = 1 << 6, ///< setter=
    VVPropertyKeywordDynamic      = 1 << 7, ///< @dynamic
};

typedef NS_OPTIONS (NSUInteger, VVPropertyQualifier) {
    VVPropertyQualifierConst  = 1 << 0,  ///< const
    VVPropertyQualifierIn     = 1 << 1,  ///< in
    VVPropertyQualifierInout  = 1 << 2, ///< inout
    VVPropertyQualifierOut    = 1 << 3, ///< out
    VVPropertyQualifierBycopy = 1 << 4, ///< bycopy
    VVPropertyQualifierByref  = 1 << 5, ///< byref
    VVPropertyQualifierOneway = 1 << 6, ///< oneway
};

@interface VVPropertyInfo : NSObject
@property (nonatomic, assign, readonly) objc_property_t property;       ///< property's opaque struct
@property (nonatomic, strong, readonly) NSString *name;                 ///< property's name
@property (nonatomic, strong, readonly) NSString *typeEncoding;         ///< property's encoding value
@property (nonatomic, strong, readonly) NSString *ivarName;             ///< property's ivar name
@property (nonatomic, assign, readonly) VVPropertyKeyword keyword;      ///< property's keywords
@property (nonatomic, assign, readonly) VVPropertyQualifier qualifier;  ///< property's qualifier
@property (nonatomic, assign, readonly) SEL getter;                     ///< getter (nonnull)
@property (nonatomic, assign, readonly) SEL setter;                     ///< setter (nonnull)
@property (nonatomic, assign, readonly) VVEncodingType type;            ///< property's type
@property (nonatomic, assign, readonly) VVEncodingNSType nsType;        ///< property's NSType
@property (nullable, nonatomic, assign, readonly) Class cls;            ///< may be nil
@property (nullable, nonatomic, strong, readonly) NSString *structUnionName;      ///< property's struct or union name, maybe null

/**
 Creates and returns a property info object.

 @param property property opaque struct
 @return A new object, or nil if an error occurs.
 */
- (instancetype)initWithProperty:(objc_property_t)property;
@end

@interface VVClassInfo : NSObject
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, assign, readonly) Class cls;
@property (nonatomic, assign, readonly) Class metaCls;
@property (nonatomic, readonly) BOOL isMeta;
@property (nullable, nonatomic, strong, readonly) NSArray<VVPropertyInfo *> *properties;

+ (nullable instancetype)classInfoWithClass:(Class)cls;
@end

NS_ASSUME_NONNULL_END
