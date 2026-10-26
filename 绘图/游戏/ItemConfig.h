//
//  ItemConfig.h
//  物资配置管理
//

#import <Foundation/Foundation.h>

@interface ItemConfig : NSObject

// 获取指定分类的所有物资
+ (NSArray<NSDictionary *> *)getItemsForCategory:(NSString *)category;

// 获取所有分类
+ (NSArray<NSString *> *)getAllCategories;

// 获取指定分类的默认配置（minDistance, maxDistance, hexColor, weaponID）
+ (NSDictionary *)getDefaultConfigForCategory:(NSString *)category;

@end
