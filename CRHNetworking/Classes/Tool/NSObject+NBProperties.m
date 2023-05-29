//
//  NSObject+NBProperties.m
//  NBJSONModelDemo
//
//  Created by linsheng on 15/11/30.
//  Copyright (c) 2015年 linsheng. All rights reserved.
//

#import "NSObject+NBProperties.h"
#import <objc/runtime.h>

#define NBTypeIndicator @"T"
#define NBReadonlyIndicator @"R"

@interface NBModelPropertyType()
@property (nonatomic,assign) BOOL notManage;
- (instancetype)initWithAttributes:(NSString *)attributes;
@end

@implementation NBModelPropertyType
+ (NSDictionary *)encodedTypesMap{
    static NSDictionary *encodedTypesMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        encodedTypesMap = @{@"c":@1, @"i":@2, @"s":@3, @"l":@4, @"q":@5,
                            @"C":@6, @"I":@7, @"S":@8, @"L":@9, @"Q":@10,
                            @"B":@11,@"f":@12,@"d":@13,@"v":@14,@"*":@15,
                            @"@":@16,@"#":@17,@":":@18,@"[":@19,@"{":@20,
                            @"(":@21,@"b":@22,@"^":@23,@"?":@24};
    });
    return encodedTypesMap;
}

- (instancetype)initWithAttributes:(NSString *)attributes {
    self = [super init];
    if (self) {
        if (self != nil) {
            NSArray *typeStringComponents = [attributes componentsSeparatedByString:@","];
            //解析类型信息
            if ([typeStringComponents count] > 0) {
                //检查是否包含只读属性
                if ([typeStringComponents containsObject:NBReadonlyIndicator]) {
                    _notManage = YES;
                    return self;
                }
                //类型信息肯定是放在最前面的且以“T”打头
                NSString *typeInfo = [typeStringComponents objectAtIndex:0];
                NSScanner *scanner = [NSScanner scannerWithString:typeInfo];
                [scanner scanUpToString:NBTypeIndicator intoString:NULL];
                [scanner scanString:NBTypeIndicator intoString:NULL];
                NSUInteger scanLocation = scanner.scanLocation;
                if ([typeInfo length] > scanLocation) {
                    NSString *typeCode = [typeInfo substringWithRange:NSMakeRange(scanLocation, 1)];
                    NSNumber *indexNumber = [[self.class encodedTypesMap] objectForKey:typeCode];
                    self.propertyType = (NBFetchModelPropertyValueType)[indexNumber integerValue];
                    //当当前的类型为对象的时候，解析出对象对应的类型的相关信息
                    //T@"NSArray<NBMyModel>"
                    if (self.propertyType == NBClassPropertyTypeObject) {
                        scanner.scanLocation += 1;
                        if ([scanner scanString:@"\"" intoString:NULL]) {
                            NSString *objectClassName = nil;
                            [scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet]
                                                intoString:&objectClassName];
                            self.objClass = NSClassFromString(objectClassName);
                            if(![self.objClass conformsToProtocol:@protocol(NSCoding)]){
                                _notManage = YES;
                                return self;
                            }
                            if ([self.objClass isSubclassOfClass:[NSArray class]]||[self.objClass isSubclassOfClass:[NSDictionary class]]) {
                                while ([scanner scanString:@"<" intoString:NULL]) {
                                    NSString* protocolName = nil;
                                    [scanner scanUpToString:@">" intoString: &protocolName];
                                    if (protocolName != nil) {
                                        Class protocalClass = NSClassFromString(protocolName);
                                        if (protocalClass) {
                                            _arrUsedClass = protocalClass;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return self;
}

@end

static const char *NBPropertiesMapDictionaryKey;

@implementation NSObject (NBProperties)

+ (NSDictionary*)NBCachedProperties {
    NSMutableDictionary*propertyMap = objc_getAssociatedObject(self, &NBPropertiesMapDictionaryKey);
    if (!propertyMap) {
        Class class = self;
        propertyMap = [NSMutableDictionary dictionary];
        while (class != [NSObject class]) {
            unsigned int count;
            objc_property_t *properties = class_copyPropertyList(class, &count);
            NSArray *noManagerArr = [self NBNoManagePropertyNames];
            for (int i = 0; i < count; i++) {
                objc_property_t property = properties[i];
                NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
                if ([noManagerArr containsObject:propertyName]) {
                    continue;
                }
                NSString *propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(property)];
                NBModelPropertyType *propertyType = [[NBModelPropertyType alloc] initWithAttributes:propertyAttributes];
                if (!propertyType.notManage) {
                    propertyType.propertyName = propertyName;
                    propertyMap[[propertyName lowercaseString]] = propertyType;
                }
            }
            free(properties);
            class = [class superclass];
        }
        objc_setAssociatedObject(self, &NBPropertiesMapDictionaryKey, propertyMap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return propertyMap;
}

+(NSString *)NBPrimaryKeyPropertyName
{
    return @"";
}

+(NSArray*)NBNoManagePropertyNames
{
    return @[];
}
- (BOOL)bzCopyWithModel:(NSObject *)model
{
    unsigned int count;
    //获取类的property成员变量
    objc_property_t *properties = class_copyPropertyList([model class], &count);
    //获取当前类的所有对象
    NSDictionary *dictSelfProperty=[[self class] NBCachedProperties];
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        NSString *propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(property)];
        NSArray *typeStringComponents = [propertyAttributes componentsSeparatedByString:@","];
        NSString *typeInfo = [typeStringComponents objectAtIndex:0];
        NSScanner *scanner = [NSScanner scannerWithString:typeInfo];
        scanner.scanLocation += 2;
        if ([scanner scanString:@"\"" intoString:NULL]) {
            NSString *objectClassName = nil;
            [scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet]
                                intoString:&objectClassName];
            //这一步目的是检查类型是否一致
            Class classtmp = NSClassFromString(objectClassName);
            
            NSString *stringIvarName=[NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            if (dictSelfProperty[[stringIvarName lowercaseString]]) {
                NBModelPropertyType *propertyType=dictSelfProperty[[stringIvarName lowercaseString]];
                if ([propertyType isKindOfClass:classtmp]) {
                    SEL selector = NSSelectorFromString(stringIvarName);
                    if ([model respondsToSelector:selector]) {
                        //                NSObject *m_nsUsrName=((id (*)(id, SEL))[model methodForSelector:selector])(model, selector);
                        NSObject *tmpObject= [model valueForKey:stringIvarName];
                        if (tmpObject) {
                            [self setValue:tmpObject forKey:propertyType.propertyName];
                        }
                        
                    }
                }
            }
            
        }
    }
    return true;
}
@end
