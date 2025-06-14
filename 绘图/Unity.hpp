//
//  Unity.h
//  IMgui框架
//
//  Created by CosmkZ on 2025/2/26.
//

#ifndef Unity_h
#define Unity_h
#include <string>
#include <algorithm>
#include <random>


#define __fastcall

#define Colour_红色 0xFF0000FF
#define Colour_绿色 0xFF00FF00
#define Colour_粉红 0xFFCBC0FF
#define Colour_蓝色 0xFFFF0000
#define Colour_浅蓝 0xFFFACE87
#define Colour_青色 0xFFFFFF00
#define Colour_碧绿 0xFFAAFF7F
#define Colour_草绿 0xFF00FC7C
#define Colour_橙黄 0xFF00A5FF
#define Colour_橙色 0xFF0066FF
#define Colour_桃红 0xFFB9DAFF
#define Colour_珊瑚红 0xFF507FFF
#define Colour_紫色 0xFFEE677A
#define Colour_石板灰 0xFF908070
#define Colour_白色 0xFFFFFFFF
#define Colour_黑色 0xFF000000
#define Colour_绿黄 0xFFADFF2F
#define Colour_黄色 0xFF00FFFF
#define Colour_透明红色 0x800000FF
#define Colour_透明橙黄 0x8000A5FF
#define Colour_透明绿黄 0x80ADFF2F
#define Colour_透明绿色 0x8000FF00
#define Colour_透明石板灰 0x80908070

template<typename ... Args>

static string string_format(const string& format, Args ... args){
    
    size_t size = 1 + snprintf(nullptr, 0, format.c_str(), args ...); // 计算格式化后的字符串长度
    char bytes[size]; // 用于存储格式化后的字符串
    snprintf(bytes, size, format.c_str(), args ...); // 格式化字符串并存储到 bytes 中
    return string(bytes); // 将 bytes 转换成 string 类型并返回
}

static int BoneColos(bool isAi) {
    return isAi ? Colour_白色 : Colour_红色;
}

int GetHelmetLevel(float a) {
    if (a <= 30) return 1;
    if (a <= 50) return 2;
    if (a <= 85) return 3;
    if (a <= 110) return 4;
    if (a <= 125) return 5;
    return 6;
}

int GetBreastPlateLevel(float a) {
    if (a <= 12) return 1;
    if (a <= 20) return 2;
    if (a <= 40) return 3;
    if (a <= 55) return 4;
    if (a <= 75) return 5;
    return 6;
}

struct ItemInfo {
    string name;
    int color;
};

static ItemInfo InventoryId(const char *name) {
    if (strstr(name, "11010004002") != 0) {
        return {"MHS战术头盔", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "11010004004") != 0) {
        return {"GT1战术头盔", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "11010005001") != 0) {
        return {"Mask-1钢铁头盔", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "11050005002") != 0) {
        return {"护甲", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "11050004001") != 0) {
        return {"武士防弹衣", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "11050004002") != 0) {
        return {"突击手防弹衣", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "11050004007") != 0) {
        return {"HMP防弹衣", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "11050005004") != 0) {
        return {"重型突击防弹衣", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "11050006004") != 0) {
        return {"泰坦防弹装甲", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "11070004001") != 0) {
        return {"强袭战术胸挂", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "11070004002") != 0) {
        return {"突击者战术胸挂", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "11070004004") != 0) {
        return {"GIR野战胸挂", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "11080004004") != 0) {
        return {"GI1户外登山包", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "13110000067") != 0) {
        return {"先进白热成像", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "14020000004") != 0) {
        return {"野战急救包", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "14020000005") != 0) {
        return {"户外医疗箱", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "14020000006") != 0) {
        return {"战地医疗箱", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "14030000003") != 0) {
        return {"野战手术包", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "14050000003") != 0) {
        return {"DEV止疼片", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "14060000001") != 0) {
        return {"精密头盔维修", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "14060000002") != 0) {
        return {"精密护甲维修", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "14060000003") != 0) {
        return {"高级头盔维修", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "14060000004") != 0) {
        return {"高级护甲维修", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "14060000005") != 0) {
        return {"标准头盔维修", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "14060000006") != 0) {
        return {"标准护甲维修", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "14070000007") != 0) {
        return {"体能针", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15020010024") != 0) {
        return {"粉碎钳", static_cast<int>(Colour_蓝色)};
    } else if (strstr(name, "15020010033") != 0) {
        return {"火箭燃料", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15020010036") != 0) {
        return {"燃料电池", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15020050001") != 0) {
        return {"自旋型手锯", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15020050003") != 0) {
        return {"聚乙烯纤维", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15020050005") != 0) {
        return {"特种钢", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15020050008") != 0) {
        return {"继电器", static_cast<int>(Colour_蓝色)};
    } else if (strstr(name, "15030010012") != 0) {
        return {"摄影机", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15030010018") != 0) {
        return {"军用控制终端", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15030040001") != 0) {
        return {"镜头", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15030040002") != 0) {
        return {"摄像头", static_cast<int>(Colour_蓝色)};
    } else if (strstr(name, "15030040003") != 0) {
        return {"CPU", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15030040005") != 0) {
        return {"固态硬盘", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15030040006") != 0) {
        return {"内存条", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15030040007") != 0) {
        return {"电脑主板", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15030040012") != 0) {
        return {"收音机", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15030040013") != 0) {
        return {"手机", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15030040014") != 0) {
        return {"电子干扰器", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15030050001") != 0) {
        return {"显卡", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15030050005") != 0) {
        return {"HIFI声卡", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15030050006") != 0) {
        return {"数位相机", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15030050011") != 0) {
        return {"GS5手柄", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15030050012") != 0) {
        return {"高速磁盘阵列", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15030050013") != 0) {
        return {"卫星锅", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15030050014") != 0) {
        return {"飞行记录仪", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15030050017") != 0) {
        return {"军用炮弹", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15030050018") != 0) {
        return {"军用控制终端", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15030050019") != 0) {
        return {"军用炸药", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15040010014") != 0) {
        return {"阿萨拉风情水壶", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15040010015") != 0) {
        return {"间谍笔", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15040010019") != 0) {
        return {"E型滤毒罐", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15040040007") != 0) {
        return {"电动车电池", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15040050003") != 0) {
        return {"热像仪", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15040080005") != 0) {
        return {"生津柠檬茶", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15050200001") != 0) {
        return {"总裁", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15050400009") != 0) {
        return {"东城民宅卧室", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15050400016") != 0) {
        return {"Relink植入手术室", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15060040001") != 0) {
        return {"静脉定位器", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15060040002") != 0) {
        return {"血压仪", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15060040003") != 0) {
        return {"血氧仪", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15060080005") != 0) {
        return {"生津柠檬红茶", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15060080008") != 0) {
        return {"能量棒", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15060080014") != 0) {
        return {"咖啡", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15060080015") != 0) {
        return {"奥莉薇娅香槟", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15070040001") != 0) {
        return {"资料:设计图纸", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15070040003") != 0) {
        return {"实验数据", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15070050001") != 0) {
        return {"量子存储", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15070050002") != 0) {
        return {"军事情报", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15080040001") != 0) {
        return {"棘龙爪化石", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080040002") != 0) {
        return {"海盗弯刀", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15080040003") != 0) {
        return {"犄角墙饰", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15080050001") != 0) {
        return {"后妃耳环", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15080050002") != 0) {
        return {"纯金打火机", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050004") != 0) {
        return {"功绩勋章", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050009") != 0) {
        return {"亮闪闪的海盗金币", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050010") != 0) {
        return {"万足金条", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15080050013") != 0) {
        return {"雷斯的乐谱本", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050014") != 0) {
        return {"赛义德的怀表", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15080050015") != 0) {
        return {"阿萨拉特色酒杯", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050016") != 0) {
        return {"阿萨拉特色酒杯", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15080050018") != 0) {
        return {"黄金饰章", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15080050030") != 0) {
        return {"曼德尔超算单", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15080050031") != 0) {
        return {"便携军用雷达", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15080050032") != 0) {
        return {"军用信息终端", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15080050034") != 0) {
        return {"单反相机", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050036") != 0) {
        return {"军用热像仪", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050037") != 0) {
        return {"广角镜头", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15080050038") != 0) {
        return {"专业声卡", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15080050041") != 0) {
        return {"步战车模型", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15080050042") != 0) {
        return {"名贵机械表", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15080050043") != 0) {
        return {"经典匕首", static_cast<int>(Colour_红色)};
    } else if (strstr(name, "15080050045") != 0) {
        return {"加密路由器", static_cast<int>(Colour_紫色)};
    } else if (strstr(name, "15080050061") != 0) {
        return {"云存储阵列", static_cast<int>(Colour_紫色)};
    } else if (strstr(name, "15080050064") != 0) {
        return {"卫队档案", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15080050067") != 0) {
        return {"强力吸尘器", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15080050068") != 0) {
        return {"胶囊咖啡机", static_cast<int>(Colour_珊瑚红)};
    } else if (strstr(name, "15080050083") != 0) {
        return {"座钟", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050089") != 0) {
        return {"军用弹道计算机", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050090") != 0) {
        return {"高速固态硬盘", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050091") != 0) {
        return {"便携音箱", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050101") != 0) {
        return {"固体燃料", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050102") != 0) {
        return {"信号棒", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050103") != 0) {
        return {"燃气喷灯", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050105") != 0) {
        return {"军用露营灯", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050106") != 0) {
        return {"便携生存套组", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050114") != 0) {
        return {"人工膝关节", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050117") != 0) {
        return {"离心机", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050118") != 0) {
        return {"紫外线灯", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050119") != 0) {
        return {"植物样本", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050122") != 0) {
        return {"天圆地方", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050124") != 0) {
        return {"阿萨拉特色提灯", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050126") != 0) {
        return {"卫星电话", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050131") != 0) {
        return {"钻石-鱼罐头", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050132") != 0) {
        return {"蓝宝石-龙舌兰", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050133") != 0) {
        return {"珠宝头冠", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050134") != 0) {
        return {"马赛克灯台", static_cast<int>(Colour_橙色)};
    } else if (strstr(name, "15080050136") != 0) {
        return {"鳄鱼蛋", static_cast<int>(Colour_橙色)};
    }
    return {name, static_cast<int>(Colour_草绿)};
}

#pragma mark - 手持输出
static string GetWeaponIDName(int WeaponId) {
    switch (WeaponId) {
        case 920130818:
            return "小刀";
        case 830130817:
            return "M4A1突击步枪";
        case 830130833:
            return "SG552步枪";
        case 830130853:
            return "ASVar步枪";
        case 830130847:
            return "CAR-15步枪";
        case 830130840:
            return "PTR-32步枪";
        case 830130839:
            return "G3战斗步枪";
        case 830130837:
            return "SCAR-H步枪";
        case 830130834:
            return "AK-12步枪";
        case 830130832:
            return "M7战斗步枪";
        case 830130831:
            return "AUG突击步枪";
        case 830130830:
            return "M16A4";
        case 830130829:
            return "K416";
        case 830130828:
            return "ASh-12";
        case 830130826:
            return "AKS-74U";
        case 830130824:
            return "QBZ-95";
        case 830130822:
            return "AKM";
        case 850130820:
            return "M870霰弹枪";
        case 850130818:
            return "S12K霰弹枪";
        case 850130817:
            return "M1014霰弹枪";
        case 840130820:
            return "UZI冲锋枪";
        case 840130826:
            return "MP7冲锋枪";
        case 840130825:
            return "勇士冲锋枪";
        case 840130824:
            return "SR-3M冲锋枪";
        case 840130822:
            return "SMG-45冲锋枪";
        case 840130821:
            return "野牛冲锋枪";
        case 840130818:
            return "P90冲锋枪";
        case 840130819:
            return "维克托冲锋枪";
        case 840130817:
            return "MP5冲锋枪";
        case 860130818:
            return "M249坤枪";
        case 860130817:
            return "RPK坤枪";
        case 870130847:
            return "PSG-1连狙";
        case 870130823:
            return "SR-25连狙";
        case 870130822:
            return "SKS连狙";
        case 870130821:
            return "M14连狙";
        case 870130820:
            return "SVD连狙";
        case 870130819:
            return "VSS连狙";
        case 870130818:
            return "Mini-14连狙";
        case 880130827:
            return "AWM栓狙";
        case 880130825:
            return "M700栓狙";
        case 880130824:
            return "R93栓狙";
        case 880130823:
            return "SV98栓狙";
        default:
            return "";
    }
}

#define RAD2DEG( x )  ( (float)(x) * (float)(180.f /  M_PI) )
#define DEG2RAD( x ) ( (float)(x) * (float)( M_PI / 180.f) )
struct Mapinfo {
    float x = 0.f;
    float y = 0.f;
    float w = 0.f;
    float h = 0.f;
    int MapX = 0;
    int MapY = 0;
};

enum class EGPCharacterInCoverPoseType : uint8_t {
    None = 0,
    LeftLow = 1,
    RightLow = 2,
    EGPCharacterInCoverPoseType_MAX = 3
};

enum class EAttachPosition : uint32_t
{
    Attach_None = 0, // 无附着位置
    Attach_EquipmentStart = 100, // 装备开始位置
    Attach_Helmet = 101, // 头盔
    Attach_Headset = 102, // 耳机
    Attach_ArmedForceBaseProp = 103, // 武装部队基础道具
    Attach_Armband = 104, // 臂章
    Attach_BreastPlate = 105, // 胸甲
    Attach_Glasses = 106, // 眼镜
    Attach_ChestHanging = 107, // 胸前挂件
    Attach_Bag = 108, // 背包
    Attach_SafeBox = 109, // 保险箱
    Attach_Shoe = 110, // 鞋子
    Attach_MainWeaponLeft = 111, // 主武器（左侧）
    Attach_MainWeaponRight = 112, // 主武器（右侧）
    Attach_MeleeWeapon = 113, // 近战武器
    Attach_PistolWeapon = 114, // 手枪
    Attach_SecondaryWeapon = 1111, // 次要武器
    Attach_ArmedForceProp1 = 115, // 武装部队道具1
    Attach_KeyChain = 116, // 钥匙链
    Attach_ArmedForceProp2 = 117, // 武装部队道具2
    Attach_Character = 118, // 角色
    Attach_DogTag = 119, // 狗牌
    PVEMainWeaponLeft = 120, // PVE主武器（左侧）
    PVEMainWeaponRight = 121, // PVE主武器（右侧）
    Medical = 122, // 医疗物品
    Archive = 123, // 档案
    Attach_SceneWeapon = 124, // 场景武器
    Attach_ClassMeleeEquipment = 125, // 职业近战装备
    Attach_ClassThrowableEquipment = 126, // 职业投掷装备
    Attach_ClassConsumable = 127, // 职业消耗品
    Attach_PVEWeapon = 128, // PVE武器
    Attach_MissionMeleeEquipment = 129, // 任务近战装备
    Attach_BulletLeft = 131, // 左侧子弹
    Attach_BulletRight = 132, // 右侧子弹
    Attach_SkillWeaponSpecial = 133, // 特殊技能武器
    Attach_SkillWeaponUltimate = 134, // 终极技能武器
    Attach_SkillWeaponActive = 135, // 主动技能武器
    Attach_SkillWeaponSupport = 136, // 支援技能武器
    Attach_SkillWeaponBattleFieldPropSkill = 137, // 战场道具技能
    Attach_SkillWeaponCustom2 = 138, // 自定义技能武器2
    Attach_SkillWeaponCustom3 = 139, // 自定义技能武器3
    Attach_MP_Begin = 140, // 多人模式开始
    Attach_MP_ArmedForceBaseProp = 141, // MP武装部队基础道具
    Attach_MP_ArmedForceTDMProp = 142, // MP武装部队团队死斗道具
    Attach_MP_MainWeapon = 143, // MP主武器
    Attach_MP_SecondaryWeapon = 144, // MP次要武器
    Attach_MP_MeleeWeapon = 145, // MP近战武器
    Attach_MP_ArmedForceProp1 = 146, // MP武装部队道具1
    Attach_MP_ArmedForceProp2 = 147, // MP武装部队道具2
    Attach_MP_End = 148, // 多人模式结束
    Attach_EquipmentEnd = 150, // 装备结束
    Attach_Fashion = 200, // 时装
    Attach_AllNearby = 301, // 附近所有物品
    Attach_PickupBox = 302, // 拾取箱
    Attach_LootTmp = 303, // 临时战利品
    Attach_TmpPerk = 304, // 临时增益
    Attach_DeadbodyLootBox = 305, // 尸体战利品箱
    Attach_AbilityVehicle = 306, // 能力载具
    Attach_ContainerStart = 100000, // 容器开始
    Attach_ChestHangingContainer = 107001, // 胸前挂件容器
    Attach_BagContainer = 108001, // 背包容器
    Attach_SafeBoxContainer = 109001, // 保险箱容器
    Attach_KeyChainContainer = 116001, // 钥匙链容器
    Attach_ArchiveContainer = 123001, // 档案容器
    Attach_Pocket = 199997, // 口袋
    Attach_BagSpaceContainer = 199998, // 背包空间容器
    Attach_ContainerEnd = 199999, // 容器结束
    Attach_CarrayItem = 200001, // 携带物品
    Attach_Temp = 77777, // 临时
    Attach_TempContainer = 77777001, // 临时容器
    Attach_Temp_FortificationHammer = 77777002, // 临时防御锤
    Attach_PVE_RPG = 99999999, // PVE火箭筒
    EAttachPosition_MAX = 100000000 // 最大值
};

#pragma pack(push, 1) // 强制1字节对齐，防止编译器自动对齐
struct FArmorInfo2
{
    bool Status; // [偏移量: 0x00 | 大小: 0x01]
    char Padding1[3]; // 填充字节，使 AttachPosition 对齐到 0x04
    EAttachPosition AttachPosition; // [偏移量: 0x04 | 大小: 0x04]
    float ArmorHP; // [偏移量: 0x08 | 大小: 0x04]
    float MaxArmorHP; // [偏移量: 0x0C | 大小: 0x04]
    char Padding2[56]; // 填充至 0x48
    int32_t ArmorLevel; // [偏移量: 0x48 | 大小: 0x04]
};
#pragma pack(pop)

struct FEquipmentInfo {
    // Fields
    uint64_t ItemID; // Offset: 0x00 // Size: 0x08
    uint64_t gid; // Offset: 0x08 // Size: 0x08
    float Health; // Offset: 0x10 // Size: 0x04
    float MaxHealth; // Offset: 0x14 // Size: 0x04
    float Durability; // Offset: 0x18 // Size: 0x04
    float MaxDurability; // Offset: 0x1c // Size: 0x04
    float TotalEquipSeceonds; // Offset: 0x20 // Size: 0x04
    float LastEquipTimeSeconds; // Offset: 0x24 // Size: 0x04
    float TotalApplyDamage; // Offset: 0x28 // Size: 0x04
    char pad_0x2C[0x4]; // Offset: 0x2c // Size: 0x04
};

FArmorInfo2 GetArmorInfo2(FEquipmentInfo EquipmentInfo) {
    FArmorInfo2 info = { 0 };
    if (EquipmentInfo.ItemID > 10000000 && EquipmentInfo.ItemID < 20000000000) {
        std::string str = std::to_string(EquipmentInfo.ItemID);
        char* p = (char*)str.c_str();
        int v1 = (p[1] - '0') * 100;
        int v2 = (p[2] - '0') * 10;
        int v3 = p[3] - '0';
        int level = p[7] - '0';
        info.ArmorLevel = level;
        info.AttachPosition = (enum EAttachPosition)(v1 + v2 + v3);
        info.Status = TRUE;
    }
    return info;
}

#pragma mark - 字符串工具
static bool isContain(string str, const char* check) {
    size_t found = str.find(check);
    return (found != string::npos);
}

struct Vector2 {
    float X;
    float Y;
    
    Vector2() {
        this->X = 0;
        this->Y = 0;
    }
    Vector2(float x, float y) {
        this->X = x;
        this->Y = y;
    }
    
    static Vector2 Zero() {
        return Vector2(0.0f, 0.0f);
    }
    
    static float Distance(Vector2 a, Vector2 b) {
        Vector2 vector = Vector2(a.X - b.X, a.Y - b.Y);
        return sqrt((vector.X * vector.X) + (vector.Y * vector.Y));
    }
    
    bool operator!=(const Vector2 &src) const {
        return (src.X != X) || (src.Y != Y);
    }
    Vector2 operator+(const Vector2 &v) const {
        return Vector2(X + v.X, Y + v.Y);
    }
    
    Vector2 operator-(const Vector2 &v) const {
        return Vector2(X - v.X, Y - v.Y);
    }
    
    Vector2 operator/ (const float A) {
        return Vector2(this->X/A, this->Y/A);
    }
    
    Vector2 &operator+=(const Vector2 &v) {
        X += v.X;
        Y += v.Y;
        return *this;
    }
    
    Vector2 &operator-=(const Vector2 &v) {
        X -= v.X;
        Y -= v.Y;
        return *this;
    }
    float Size ()
    {
        return sqrt( ( this->X * this->X ) + ( this->Y * this->Y )  );
    }
    
};

static Vector2 CanvasSize;//屏幕大小


struct Vector3 {
    float X;
    float Y;
    float Z;

    Vector3() {
        this->X = 0;
        this->Y = 0;
        this->Z = 0;
    }

    Vector3(float x, float y, float z) {
        this->X = x;
        this->Y = y;
        this->Z = z;
    }
    float Size ();
    Vector3 operator+(const Vector3 &v) const {
        return Vector3(X + v.X, Y + v.Y, Z + v.Z);
    }

    Vector3 operator-(const Vector3 &v) const {
        return Vector3(X - v.X, Y - v.Y, Z - v.Z);
    }

    bool operator==(const Vector3 &v) {
        return X == v.X && Y == v.Y && Z == v.Z;
    }

    bool operator!=(const Vector3 &v) {
        return !(X == v.X && Y == v.Y && Z == v.Z);
    }
    Vector3 operator-= (const Vector3 &A) {
        this->X -= A.X;
        this->Y -= A.Y;
        this->Z -= A.Z;
        return *this;
    }
    
    Vector3 operator-= (const float A) {
        this->X -= A;
        this->Y -= A;
        this->Z -= A;
        return *this;
    }
    
    Vector3 operator/ (const float A) {
        return Vector3(this->X/A, this->Y/A, this->Z/A);
    }
    static Vector3 Zero() {
        return Vector3(0.0f, 0.0f, 0.0f);
    }
    
    static float Dot(Vector3 a, Vector3 b) {
        return a.X * b.X + a.Y * b.Y + a.Z * b.Z;
    }
    Vector3 operator*(float a) {
        return Vector3(X * a, Y * a, Z * a);
    }
    
    static float Distance(const Vector3& a, const Vector3& b) {
        float dx = a.X - b.X;
        float dy = a.Y - b.Y;
        float dz = a.Z - b.Z;
        return sqrt(dx * dx + dy * dy + dz * dz);
    }

    
    Vector3 Normalized() const {
        float length = sqrt(X * X + Y * Y + Z * Z);
        if (length == 0) return Vector3::Zero(); // 避免除以零
        return Vector3(X / length, Y / length, Z / length);
    }

    float Size() const {
        return sqrt(X * X + Y * Y + Z * Z);
    }

    static Vector3 Cross(const Vector3& a, const Vector3& b) {
        return Vector3(
            a.Y * b.Z - a.Z * b.Y,
            a.Z * b.X - a.X * b.Z,
            a.X * b.Y - a.Y * b.X
        );
    }
    
    Vector3 LookAt(const Vector3& target) const {
        return (target - *this).Normalized();
    }
    
};

struct FRotator {
    float Pitch;
    float Yaw;
    float Roll;
    inline FRotator()
        : Pitch(0.0f), Yaw(0.0f), Roll(0.0f)
    { }

    inline FRotator(float pitch, float yaw, float roll)
        : Pitch(pitch), Yaw(yaw), Roll(roll)
    { }
    
    inline FRotator operator+ (const FRotator &A) {
        return FRotator(this->Pitch + A.Pitch, this->Yaw + A.Yaw, this->Roll + A.Roll);
    }
    
    inline FRotator operator- (const FRotator &A) {
        return FRotator(this->Pitch - A.Pitch, this->Yaw - A.Yaw, this->Roll - A.Roll);
    }
    
    inline FRotator operator* (const FRotator &A) {
        return FRotator(this->Pitch * A.Pitch, this->Yaw * A.Yaw, this->Roll * A.Roll);
    }

    inline FRotator operator* (const float A) {
        return FRotator(this->Pitch * A, this->Yaw * A, this->Roll * A);
    }
    
    inline FRotator operator/ (const FRotator &A) {
        return FRotator(this->Pitch / A.Pitch, this->Yaw / A.Yaw, this->Roll / A.Roll);
    }

    inline FRotator operator/ (const float A) {
        return FRotator(this->Pitch / A, this->Yaw / A, this->Roll / A);
    }

};

class Ue4Rotator {
public:
    Ue4Rotator() : Pitch(0.f), Yaw(0.f), Roll(0.f) {

    }

    Ue4Rotator(float _Pitch, float _Yaw, float _Roll) : Pitch(_Pitch), Yaw(_Yaw), Roll(_Roll) {

    }

    ~Ue4Rotator() {

    }

    float Pitch;
    float Yaw;
    float Roll;

    inline Ue4Rotator Clamp() {

        if (Pitch > 180) {
            Pitch -= 360;
        } else {
            if (Pitch < -180) {
                Pitch += 360;
            }
        }
        if (Yaw > 180) {
            Yaw -= 360;
        } else {
            if (Yaw < -180) {
                Yaw += 360;
            }
        }
        if (Pitch > 89) {
            Pitch = 89;
        }
        if (Pitch < -89) {
            Pitch = -89;
        }
        while (Yaw < 180) {
            Yaw += 360;
        }
        while (Yaw > 180) {
            Yaw -= 360;
        }
        Roll = 0;
        return Ue4Rotator(Pitch, Yaw, Roll);
    }

    inline float Length() {
        return sqrtf(Pitch * Pitch + Yaw * Yaw + Roll * Roll);
    }

    inline Ue4Rotator operator* (const float A) {
        return Ue4Rotator(this->Pitch * A, this->Yaw * A, this->Roll * A);
    }
    
    Ue4Rotator operator+(Ue4Rotator v) {
        return Ue4Rotator(Pitch + v.Pitch, Yaw + v.Yaw, Roll + v.Roll);
    }

    Ue4Rotator operator-(Ue4Rotator v) {
        return Ue4Rotator(Pitch - v.Pitch, Yaw - v.Yaw, Roll - v.Roll);
    }
    
    Ue4Rotator AdjustAim(float hitProbability) {
        // 确保概率在合法范围内（0到1之间）
        if (hitProbability < 0.0f) {
            hitProbability = 0.0f;
        } else if (hitProbability > 1.0f) {
            hitProbability = 1.0f;
        }

        // 设置随机数生成器
        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_real_distribution<float> dist(-8.0f, 8.0f);

        // 根据概率和随机数调整准心欧拉角
        float pitchOffset = dist(gen) * (1 - hitProbability);
        float yawOffset = dist(gen) * (1 - hitProbability);

        float newPitch = Pitch + pitchOffset;
        float newYaw = Yaw + yawOffset;

        // 确保欧拉角在合法范围内（通常为[-180, 180]度）
        newPitch = fmod(newPitch + 180.0f, 360.0f) - 180.0f;
        newYaw = fmod(newYaw + 180.0f, 360.0f) - 180.0f;

        return Ue4Rotator(newPitch, newYaw, Roll);
    }
};


struct Vector4 {
    float x;
    float y;
    float z;
    float w;
};

struct VectorRect {
    int x;
    int y;
    int w;
    int h;
};

struct MinimalViewInfo {
    Vector3 location;
    Ue4Rotator rotation;
    float fov;
};

struct Ue4Matrix {
    float matrix[4][4];
    
    float *operator[](int index) {
        return matrix[index];
    }
    
};
static Ue4Matrix rotatorToMatrix(Ue4Rotator rotation) {
    float radPitch = rotation.Pitch * ((float) M_PI / 180.0f);
    float radYaw = rotation.Yaw * ((float) M_PI / 180.0f);
    float radRoll = rotation.Roll * ((float) M_PI / 180.0f);
    
    float SP = sinf(radPitch);
    float CP = cosf(radPitch);
    float SY = sinf(radYaw);
    float CY = cosf(radYaw);
    float SR = sinf(radRoll);
    float CR = cosf(radRoll);
    
    Ue4Matrix matrix;
    
    matrix[0][0] = (CP * CY);
    matrix[0][1] = (CP * SY);
    matrix[0][2] = (SP);
    matrix[0][3] = 0;
    
    matrix[1][0] = (SR * SP * CY - CR * SY);
    matrix[1][1] = (SR * SP * SY + CR * CY);
    matrix[1][2] = (-SR * CP);
    matrix[1][3] = 0;
    
    matrix[2][0] = (-(CR * SP * CY + SR * SY));
    matrix[2][1] = (CY * SR - CR * SP * SY);
    matrix[2][2] = (CR * CP);
    matrix[2][3] = 0;
    
    matrix[3][0] = 0;
    matrix[3][1] = 0;
    matrix[3][2] = 0;
    matrix[3][3] = 1;
    
    return matrix;
}
static Vector2 worldToScreen(Vector3 worldLocation, MinimalViewInfo camViewInfo, Vector2 screenCenter) {
    Ue4Matrix tempMatrix = rotatorToMatrix(camViewInfo.rotation);
    
    Vector3 vAxisX(tempMatrix[0][0], tempMatrix[0][1], tempMatrix[0][2]);
    Vector3 vAxisY(tempMatrix[1][0], tempMatrix[1][1], tempMatrix[1][2]);
    Vector3 vAxisZ(tempMatrix[2][0], tempMatrix[2][1], tempMatrix[2][2]);
    
    Vector3 vDelta = worldLocation - camViewInfo.location;
    
    Vector3 vTransformed(Vector3::Dot(vDelta, vAxisY), Vector3::Dot(vDelta, vAxisZ), Vector3::Dot(vDelta, vAxisX));
    
    if (vTransformed.Z < 1.0f) {
        vTransformed.Z = 1.0f;
    }
    Vector2 screenCoord;
    screenCoord.X = (screenCenter.X + vTransformed.X * (screenCenter.X / tanf(camViewInfo.fov * ((float) M_PI / 360.0f))) / vTransformed.Z);
    screenCoord.Y = (screenCenter.Y - vTransformed.Y * (screenCenter.X / tanf(camViewInfo.fov * ((float) M_PI / 360.0f))) / vTransformed.Z);
    return screenCoord;
}
static Vector2 WorldToScreen(Vector3 obj, float* matrix) {
    Vector2 screen;
    float w = matrix[3] * obj.X + matrix[7] * obj.Y + matrix[11] * obj.Z + matrix[15];
    if (w < 0.5) w = 0.5;
    
    float x =  (CanvasSize.X/2) + (matrix[0] * obj.X + matrix[4] * obj.Y + matrix[8] * obj.Z + matrix[12]) / w * (CanvasSize.X/2);
    float y =  (CanvasSize.Y/2) - (matrix[1] * obj.X + matrix[5] * obj.Y + matrix[9] * obj.Z + matrix[13]) / w * (CanvasSize.Y/2);
    
    screen.X = x;
    screen.Y = y;
    return screen;
}
//static void BoxConversion(Vector3 worldLocation, VectorRect *rect, MinimalViewInfo camViewInfo, Vector2 CanvasSize) {
//    Vector3 worldLocation2 = worldLocation;
//    worldLocation2.Z += 90.f;
//    
//    Vector2 calculate = worldToScreen(worldLocation,camViewInfo,CanvasSize); // 计算物体坐标在屏幕上的位置
//    Vector2 calculate2 = worldToScreen(worldLocation2,camViewInfo,CanvasSize); // 计算物体坐标在屏幕上的位置
//    
//    
//    rect->h = calculate.Y - calculate2.Y;
//    rect->w = rect->h / 2.5;
//    rect->x = calculate.X - rect->w;
//    rect->y = calculate2.Y;
//    rect->w = rect->w * 2;
//    rect->h = rect->h * 2;
//}

static void BoxConversion(Vector3 worldLocation, VectorRect *rect, float* matrix) {
    Vector3 worldLocation2 = worldLocation;
    worldLocation2.Z += 90.f;
    
    Vector2 calculate = WorldToScreen(worldLocation,matrix); // 计算物体坐标在屏幕上的位置
    Vector2 calculate2 = WorldToScreen(worldLocation2,matrix); // 计算物体坐标在屏幕上的位置
    
    
    rect->h = calculate.Y - calculate2.Y;
    rect->w = rect->h / 2.5;
    rect->x = calculate.X - rect->w;
    rect->y = calculate2.Y;
    rect->w = rect->w * 2;
    rect->h = rect->h * 2;
}

struct D3DXMATRIX {
    float _11, _12, _13, _14;
    float _21, _22, _23, _24;
    float _31, _32, _33, _34;
    float _41, _42, _43, _44;
};



struct FTransform
{
    Vector4 rot;
    Vector3 translation;
    Vector3 scale;
    D3DXMATRIX ToMatrixWithScale()
    {
        D3DXMATRIX m;
        m._41 = translation.X;
        m._42 = translation.Y;
        m._43 = translation.Z;

        float x2 = rot.x + rot.x;
        float y2 = rot.y + rot.y;
        float z2 = rot.z + rot.z;

        float xx2 = rot.x * x2;
        float yy2 = rot.y * y2;
        float zz2 = rot.z * z2;
        m._11 = (1.0f - (yy2 + zz2)) * scale.X;
        m._22 = (1.0f - (xx2 + zz2)) * scale.Y;
        m._33 = (1.0f - (xx2 + yy2)) * scale.Z;

        float yz2 = rot.y * z2;
        float wx2 = rot.w * x2;
        m._32 = (yz2 - wx2) * scale.Z;
        m._23 = (yz2 + wx2) * scale.Y;

        float xy2 = rot.x * y2;
        float wz2 = rot.w * z2;
        m._21 = (xy2 - wz2) * scale.Y;
        m._12 = (xy2 + wz2) * scale.X;

        float xz2 = rot.x * z2;
        float wy2 = rot.w * y2;
        m._31 = (xz2 + wy2) * scale.Z;
        m._13 = (xz2 - wy2) * scale.X;

        m._14 = 0.0f;
        m._24 = 0.0f;
        m._34 = 0.0f;
        m._44 = 1.0f;

        return m;
    }
    static D3DXMATRIX MatrixMultiplication(D3DXMATRIX pM1, D3DXMATRIX pM2) {

        D3DXMATRIX pOut;
        pOut._11 = pM1._11 * pM2._11 + pM1._12 * pM2._21 + pM1._13 * pM2._31 + pM1._14 * pM2._41;
        pOut._12 = pM1._11 * pM2._12 + pM1._12 * pM2._22 + pM1._13 * pM2._32 + pM1._14 * pM2._42;
        pOut._13 = pM1._11 * pM2._13 + pM1._12 * pM2._23 + pM1._13 * pM2._33 + pM1._14 * pM2._43;
        pOut._14 = pM1._11 * pM2._14 + pM1._12 * pM2._24 + pM1._13 * pM2._34 + pM1._14 * pM2._44;
        pOut._21 = pM1._21 * pM2._11 + pM1._22 * pM2._21 + pM1._23 * pM2._31 + pM1._24 * pM2._41;
        pOut._22 = pM1._21 * pM2._12 + pM1._22 * pM2._22 + pM1._23 * pM2._32 + pM1._24 * pM2._42;
        pOut._23 = pM1._21 * pM2._13 + pM1._22 * pM2._23 + pM1._23 * pM2._33 + pM1._24 * pM2._43;
        pOut._24 = pM1._21 * pM2._14 + pM1._22 * pM2._24 + pM1._23 * pM2._34 + pM1._24 * pM2._44;
        pOut._31 = pM1._31 * pM2._11 + pM1._32 * pM2._21 + pM1._33 * pM2._31 + pM1._34 * pM2._41;
        pOut._32 = pM1._31 * pM2._12 + pM1._32 * pM2._22 + pM1._33 * pM2._32 + pM1._34 * pM2._42;
        pOut._33 = pM1._31 * pM2._13 + pM1._32 * pM2._23 + pM1._33 * pM2._33 + pM1._34 * pM2._43;
        pOut._34 = pM1._31 * pM2._14 + pM1._32 * pM2._24 + pM1._33 * pM2._34 + pM1._34 * pM2._44;
        pOut._41 = pM1._41 * pM2._11 + pM1._42 * pM2._21 + pM1._43 * pM2._31 + pM1._44 * pM2._41;
        pOut._42 = pM1._41 * pM2._12 + pM1._42 * pM2._22 + pM1._43 * pM2._32 + pM1._44 * pM2._42;
        pOut._43 = pM1._41 * pM2._13 + pM1._42 * pM2._23 + pM1._43 * pM2._33 + pM1._44 * pM2._43;
        pOut._44 = pM1._41 * pM2._14 + pM1._42 * pM2._24 + pM1._43 * pM2._34 + pM1._44 * pM2._44;

        return pOut;
    }
};

struct FDeathInfo {
    bool bIsDead;//(ByteOffset: 0, ByteMask: 86, FieldMask: 0)[Offset: 0x0, Size: 0x1]
    float DyingTime;//[Offset: 0x4, Size: 0x4]
    float DeadTime;//[Offset: 0x8, Size: 0x4]
};






#endif /* Unity_h */
