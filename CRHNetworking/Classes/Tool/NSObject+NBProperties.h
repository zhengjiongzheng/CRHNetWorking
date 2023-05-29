//
//  NSObject+NBProperties.h
//  NBJSONModelDemo
//
//  Created by linsheng on 15/11/30.
//  Copyright © 2015年 linsheng. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NBFetchModelPropertyValueType) {
    NBClassPropertyValueTypeNone = 0,
    NBClassPropertyTypeChar,
    NBClassPropertyTypeInt,
    NBClassPropertyTypeShort,
    NBClassPropertyTypeLong,
    NBClassPropertyTypeLongLong,
    NBClassPropertyTypeUnsignedChar,
    NBClassPropertyTypeUnsignedInt,
    NBClassPropertyTypeUnsignedShort,
    NBClassPropertyTypeUnsignedLong,
    NBClassPropertyTypeUnsignedLongLong,
    NBClassPropertyTypeBool,
    NBClassPropertyTypeFloat,
    NBClassPropertyTypeDouble,
    NBClassPropertyTypeVoid,
    NBClassPropertyTypeCharString,
    NBClassPropertyTypeObject,
    NBClassPropertyTypeClassObject,
    NBClassPropertyTypeSelector,
    NBClassPropertyTypeArray,
    NBClassPropertyTypeStruct,
    NBClassPropertyTypeUnion,
    NBClassPropertyTypeBitField,
    NBClassPropertyTypePointer,
    NBClassPropertyTypeUnknow
};

@interface NBModelPropertyType : NSObject
@property (nonatomic, copy) NSString *propertyName;
//数组内部使用 以协议标识
@property (nonatomic, assign) Class objClass;
//正常的类型 当属性类型为对象的时候使用
@property (nonatomic, assign) Class arrUsedClass;
//属性类型 上述情况并未完全处理
@property (nonatomic, assign)NBFetchModelPropertyValueType propertyType;

@end

@interface NSObject (NBProperties)
//存储的属性表 字典键为小写 只有基本数据类型 支持NSCoding协议的对象支持自动解析
+(NSDictionary*)NBCachedProperties;
//存储数据库的主键名 不可随意更新 主键的更新需要优化 现在属性减少会重建表 小写
+(NSString*)NBPrimaryKeyPropertyName;
//不进行持久化保存和自动化解析的键 都要小写...
+(NSArray*)NBNoManagePropertyNames;
- (BOOL)bzCopyWithModel:(NSObject *)model;
@end
