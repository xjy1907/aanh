// 全局绘制设置结构体 - 用于跨线程传值
struct 绘制设置 {
    BOOL 绘图开关 = NO;
    BOOL 人机显示 = NO;
    BOOL 骨骼显示 = NO;
    BOOL 射线显示 = NO;
    BOOL 信息显示 = NO;
    BOOL 装备显示 = NO;
    BOOL 距离显示 = NO;
    BOOL 雷达显示 = NO;
    BOOL 血条显示 = NO;
    BOOL 物资显示 = NO;
    BOOL 盒子显示 = NO;
    BOOL 头甲显示 = NO;
    BOOL 过直播 = NO;
};

// 全局设置实例声明
extern struct 绘制设置 全局绘制设置;

@interface 按钮存储方法 : NSObject

+ (instancetype) 初始化;

- (void) 设置按钮状态:(BOOL)状态 密钥:(NSString*)密钥;
- (BOOL) 取按钮状态:(NSString*)密钥;

// 同步设置到全局结构体
- (void) 同步全局设置;

@property (class, nonatomic, readonly) NSString* 绘图密钥;
@property (class, nonatomic, readonly) NSString* 人机密钥;
@property (class, nonatomic, readonly) NSString* 骨骼密钥;
@property (class, nonatomic, readonly) NSString* 射线密钥;
@property (class, nonatomic, readonly) NSString* 信息密钥;
@property (class, nonatomic, readonly) NSString* 装备密钥;
@property (class, nonatomic, readonly) NSString* 距离密钥;
@property (class, nonatomic, readonly) NSString* 雷达密钥;
@property (class, nonatomic, readonly) NSString* 血条密钥;
@property (class, nonatomic, readonly) NSString* 物资密钥;
@property (class, nonatomic, readonly) NSString* 盒子密钥;
@property (class, nonatomic, readonly) NSString* 头甲密钥;
@property (class, nonatomic, readonly) NSString* 过直播密钥;
@property (class, nonatomic, readonly) NSString* 类名密钥;
@property (class, nonatomic, readonly) NSString* 网页雷达密钥;
@end
