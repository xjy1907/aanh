#pragma once

#import <Foundation/Foundation.h>
#import <vector>
#import <string>
#import <mutex>

using namespace std;

// 雷达玩家数据
struct 雷达玩家数据 {
    float x, y;           // 世界坐标
    int teamId;           // 队伍ID
    string name;          // 玩家名
    float health;         // 血量 0-100
    float direction;      // 朝向
    string weapon;        // 武器
    string helmetLevel;   // 头盔等级
    float helmetDurability;    // 头盔耐久（实际值）
    float helmetMaxDurability; // 头盔最大耐久
    string armorLevel;    // 护甲等级
    float armorDurability;     // 护甲耐久（实际值）
    float armorMaxDurability;  // 护甲最大耐久
    bool isAI;
};

// 雷达物资数据
struct 雷达物资数据 {
    float x, y;           // 世界坐标
    string name;          // 物资名称
    int quality;          // 品质等级
    int price;            // 价格
};

class 网页雷达客户端 {
private:
    string 服务器地址;
    string 房间号;
    string 当前地图;
    bool 运行中;
    
    mutex 数据锁;
    vector<雷达玩家数据> 当前玩家数据;
    vector<雷达物资数据> 当前物资数据;
    
    dispatch_queue_t 上传队列;
    dispatch_source_t 定时器;
    
    void 上传数据();
    string 玩家数据转JSON();
    
public:
    网页雷达客户端();
    ~网页雷达客户端();
    
    void 设置服务器(const string& url);
    bool 启动();
    void 停止();
    
    void 更新玩家数据(const vector<雷达玩家数据>& 玩家);
    void 更新物资数据(const vector<雷达物资数据>& 物资);
    void 设置地图(const string& 地图名);
    
    string 获取房间号() { return 房间号; }
    bool 是否运行中() { return 运行中 && !房间号.empty(); }
    string 获取访问信息();
};

extern 网页雷达客户端 g_网页雷达;
