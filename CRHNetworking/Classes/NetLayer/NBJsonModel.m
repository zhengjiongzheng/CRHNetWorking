//
//  NBJsonModel.m
//  NBJSONModelDemo
//
//  Created by linsheng on 15/11/30.
//  Copyright (c) 2015年 linsheng. All rights reserved.
//

#import "NBJsonModel.h"
#import "NSObject+NBProperties.h" 
@interface NSDictionary (NBJsonModel)
- (instancetype)arrayWithModelClass:(Class)modelClass;
@end

@implementation NSDictionary (NBJsonModel)
- (instancetype)dictionaryWithModelClass:(Class)modelClass {
    NSMutableDictionary *dict = [@{} mutableCopy];
    for (NSString *key in self.allKeys) {
        id obj=self[key];
        if ([obj isKindOfClass:[NSArray class]]) {
            [dict setObject:[obj arrayWithModelClass:modelClass] forKey:key];
        }else if ([obj isKindOfClass:[NSDictionary class]]) {
            BOOL isModelClass = [modelClass isSubclassOfClass:[NBJsonModel class]];
            [dict setObject:isModelClass ? [[modelClass alloc] initWithJSONDict:obj] : obj forKey:key];
        }else{
             [dict setObject:obj forKey:key];
        }
    }
    return dict;
}
@end
@interface NSArray (NBJsonModel)
- (instancetype)arrayWithModelClass:(Class)modelClass;
@end

@implementation NSArray (NBJsonModel)
- (instancetype)arrayWithModelClass:(Class)modelClass {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.count];
    for (id obj in self) {
        if ([obj isKindOfClass:[NSArray class]]) {
            [array addObject:[obj arrayWithModelClass:modelClass]];
        }else if ([obj isKindOfClass:[NSDictionary class]]) {
            BOOL isModelClass = [modelClass isSubclassOfClass:[NBJsonModel class]];
            [array addObject:isModelClass ? [[modelClass alloc] initWithJSONDict:obj] : obj];
        }else{
            [array addObject:obj];
        }
    }
    return array;
}
@end

@interface NBModelPropertyType (NBJsonModelProperty)
-(id)usedValueWithOriginValue:(id)originValue;
@end

@implementation NBModelPropertyType(NBJsonModelProperty)
-(id)usedValueWithOriginValue:(id)originValue
{
    id usedValue;
    if (self.objClass && originValue) {
        if ([self.objClass isSubclassOfClass:[NSArray class]] && [originValue isKindOfClass:[NSArray class]]) {
            usedValue = [originValue arrayWithModelClass:self.arrUsedClass];
        }else if ([originValue isKindOfClass:[NSDictionary class]]) {
            usedValue = [self.objClass isSubclassOfClass:[NBJsonModel class]] ? [[self.objClass alloc] initWithJSONDict:originValue] : [self.objClass isSubclassOfClass:[NSDictionary class]]?[originValue dictionaryWithModelClass:self.arrUsedClass]:nil;
        }else if ([originValue isKindOfClass:self.objClass]) {
            usedValue = originValue;
        }else if([self.objClass isSubclassOfClass:[NSString class]]){
            usedValue = [NSString stringWithFormat:@"%@",originValue];
        }else if([self.objClass isSubclassOfClass:[NSNumber class]] && [originValue isKindOfClass:[NSString class]]){
            usedValue = @([originValue doubleValue]);
        }
    }else if (self.propertyType > NBClassPropertyValueTypeNone && self.propertyType < NBClassPropertyTypeVoid ) {
        if ([originValue isKindOfClass:[NSString class]]) {
            usedValue = @([originValue doubleValue]);
        }else{
            usedValue = originValue;
        }
    }
    return usedValue;
}
@end


@implementation NBJsonModel
- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (instancetype)initWithJSONDict:(NSDictionary *)dict {
    if (self = [self init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [self init]) {
        NSArray *propertyValues = [[[self class] NBCachedProperties]allValues];
        for (NBModelPropertyType *type in propertyValues) {
            id objToSet = [aDecoder decodeObjectForKey:type.propertyName];
            if (objToSet) {
                [self setValue:objToSet forKey:type.propertyName];
            }
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    NSArray *propertyValues = [[[self class] NBCachedProperties]allValues];
    for (NBModelPropertyType *type in propertyValues) {
        id objToSet = [self valueForKey:type.propertyName];
        if ([objToSet conformsToProtocol:@protocol(NSCoding)]) {
            [aCoder encodeObject:objToSet forKey:type.propertyName];
        }
    }
}

-(id)copyWithZone:(NSZone *)zone
{
    typeof(self) copyOne = [[[self class]alloc]init];
    [copyOne injectDataWithModel:self];
    return copyOne;
}

-(void)injectJSONData:(NSDictionary*)jsonData
{
    if ([jsonData isKindOfClass:[NSDictionary class]]) {
        [self setValuesForKeysWithDictionary:jsonData];
    }
}

-(void)injectDataWithModel:(NBJsonModel *)model
{
    if (![model isKindOfClass:[NBJsonModel class]]) {
        return;
    }
    NSArray *propertyValues = [[[model class] NBCachedProperties]allValues];
    for (NBModelPropertyType *type in propertyValues) {
        id objToSet = [model valueForKey:type.propertyName];
        if (objToSet) {
            [self setValue:objToSet forKey:type.propertyName];
        }
    }
}

-(NSString *)description
{
    return [self jsonString];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    NSDictionary *propertyMap = [[self class]NBCachedProperties];
    NSString *usedKey = [key lowercaseString];
    NBModelPropertyType *propertyType = propertyMap[usedKey];
    if (propertyType) {
        id usedValue = [propertyType usedValueWithOriginValue:value];
        if (usedValue) {
            [super setValue:usedValue forKey:propertyType.propertyName];
        }else{
            [self setNilValueForKey:propertyType.propertyName];
        }
    }else{
        [super setValue:value forKey:key];
    }
}

-(id)valueForKey:(NSString *)key
{
    id value = [super valueForKey:key];
    return value;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSDictionary *propertyMap = [[self class]NBCachedProperties];
    NSString *usedKey = [key lowercaseString];
    NBModelPropertyType *propertyType = propertyMap[usedKey];
    if (propertyType) {
        id usedValue = [propertyType usedValueWithOriginValue:value];
        if (usedValue) {
            [super setValue:usedValue forKey:propertyType.propertyName];
        }else{
            [self setNilValueForKey:propertyType.propertyName];
        }
    }
}

- (void)setNilValueForKey:(NSString *)key {
    NSDictionary *propertyMap = [[self class]NBCachedProperties];
    NSString *usedKey = [key lowercaseString];
    NBModelPropertyType *propertyType = propertyMap[usedKey];
    id value;
    if (propertyType) {
        if (propertyType.propertyType == NBClassPropertyTypeObject) {
            if ([propertyType.objClass isSubclassOfClass:[NSArray class]]) {
                value = @[];
            }else if ([propertyType.objClass isSubclassOfClass:[NSString class]]) {
                value = @"";
            }else if ([propertyType.objClass isSubclassOfClass:[NSNumber class]]) {
                value = @(0);
            }
        }else{
            value = @(0);
        }
    }
    if (value) {
        [super setValue:value forKey:key];
    }
}

#pragma mark JsonRelated
- (NSDictionary *)jsonDict {
    NSDictionary *propertyMap = [[self class]NBCachedProperties];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *allProperties = [propertyMap allValues];
    for (NBModelPropertyType *propertyType in allProperties) {
        id obj = [self valueForKey:propertyType.propertyName];
        if ([obj isKindOfClass:[NBJsonModel class]]) {
            [dict setObject:[obj jsonDict] forKey:propertyType.propertyName];
        }else if ([obj isKindOfClass:[NSArray class]] && [propertyType.arrUsedClass isSubclassOfClass:[NBJsonModel class]]) {
            NSArray *items = (NSArray *)obj;
            NSMutableArray *jsonList = [NSMutableArray array];
            for (id item in items) {
                if ([item isKindOfClass:[NBJsonModel class]]) {
                    [jsonList addObject:[item jsonDict]];
                }
            }
            [dict setObject:jsonList forKey:propertyType.propertyName];
        }else {
            if (obj) {
                [dict setValue:obj forKey:propertyType.propertyName];
            }
        }
    }
    return dict;
}

-(NSString *)jsonString
{
    NSDictionary *dic = [self jsonDict];
    NSString *str = @"";
    if ([NSJSONSerialization isValidJSONObject:dic]) {
        NSError *error;
        NSData *date = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&error];
        if (!error) {
            str = [[NSString alloc]initWithData:date encoding:NSUTF8StringEncoding];
        }
    }
    return str;
}


@end
