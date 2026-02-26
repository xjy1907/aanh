string 取英雄名(uint64_t HeroId) {
    switch (HeroId) {
        case 88000000030:
            return " [ 红狼 ]";
        case 88000000027:
            return " [ 蜂医 ]";
        case 88000000029:
            return " [ 牧羊人 ]";
        case 88000000028:
            return " [ 露娜 ]";
        case 88000000025:
            return " [ 威龙 ]";
        case 88000000036:
            return " [ 蛊 ]";
        case 88000000035:
            return " [ 乌鲁鲁 ]";
        case 88000000026:
            return " [ 骇爪 ]";
        case 88000000037:
            return " [ 深蓝 ]";
        case 88000000038:
            return " [ 无名 ]";
        case 88000000039:
            return " [ 疾风 ]";
        case 88000000040:
            return " [ 银翼 ]";
        case 88000000041:
            return " [ 比特 ]";
        case 88000000042:
            return " [ 赤枭 ]";
        case 88000000043:
            return " [ 卫队副官 ]";
        case 88000000044:
            return " [ 卫队副官 ]";
        case 88000000045:
            return " [ 蝶 ]";
        case 42040020001:
            return " [ 赛伊德 ]";
    };
    return to_string(HeroId);
};

string 取物品名(uint64_t ID) {
    switch (ID) {
#pragma mark -- 步枪
        case 18010000043:
            return "MK47突击步枪";
        case 18010000042:
            return "KC17突击步枪";
        case 18010000040:
            return "K437突击步枪";
        case 18010000038:
            return "腾龙突击步枪";
        case 18010000037:
            return "AS Val突击步枪";
        case 18010000031:
            return "CAR-15突击步枪";
        case 18010000024:
            return "PTR-32突击步枪";
        case 18010000023:
            return "G3战斗步枪";
        case 18010000021:
            return "SCAR-H战斗步枪";
        case 18010000018:
            return "AK-12突击步枪";
        case 18010000017:
            return "SG552突击步枪";
        case 18010000016:
            return "M7战斗步枪";
        case 18010000015:
            return "AUG突击步枪";
        case 18010000014:
            return "M16A4突击步枪";
        case 18010000013:
            return "K416突击步枪";
        case 18010000012:
            return "ASh-12战斗步枪";
        case 18010000010:
            return "AKS-74U突击步枪";
        case 18010000006:
            return "AKM突击步枪";
        case 18010000001:
            return "M4A1突击步枪";
#pragma mark -- 冲锋枪
        case 18020000012:
            return "MK4冲锋枪";
        case 18020000011:
            return "QCQ171冲锋枪";
        case 18020000010:
            return "MP7冲锋枪";
        case 18020000009:
            return "勇士冲锋枪";
        case 18020000008:
            return "SR-3M紧凑突击步枪";
        case 18020000006:
            return "SMG-45冲锋枪";
        case 18020000005:
            return "野牛冲锋枪";
        case 18020000004:
            return "UZI冲锋枪";
        case 18020000003:
            return "Vector冲锋枪";
        case 18020000002:
            return "P90冲锋枪";
        case 18020000001:
            return "MP5冲锋枪";
#pragma mark -- 霰弹枪
        case 18030000005:
            return "725双管霰弹枪";
        case 18030000004:
            return "M870霰弹枪";
        case 18030000002:
            return "S12K霰弹枪";
        case 18030000001:
            return "M1014霰弹枪";
#pragma mark -- 轻机枪
        case 18040000004:
            return "QJB201轻机枪";
        case 18040000003:
            return "M250通用机枪";
        case 18040000002:
            return "M249轻机枪";
        case 18040000001:
            return "PKM通用机枪";
#pragma mark -- 精确射手步枪
        case 18050000032:
            return "杠杆式步枪";
        case 18050000031:
            return "PSG-1射手步枪";
        case 18050000008:
            return "SR9射手步枪";
        case 18050000007:
            return "SR-25射手步枪";
        case 18050000006:
            return "SKS射手步枪";
        case 18050000005:
            return "M14射手步枪";
        case 18050000004:
            return "SVD狙击步枪";
        case 18050000003:
            return "VSS射手步枪";
        case 18050000002:
            return "Mini-14射手步枪";
#pragma mark -- 狙击步枪
        case 18060000011:
            return "AWM狙击步枪";
        case 18060000009:
            return "M700狙击步枪";
        case 18060000008:
            return "R93狙击步枪";
        case 18060000007:
            return "SV-98狙击步枪";
#pragma mark -- 特殊
        case 18150000001:
            return "复合弓";
#pragma mark -- 手枪
        case 18070000033:
            return "M1911";
        case 18070000010:
            return "G17";
        case 18070000006:
            return "93R";
        case 18070000005:
            return "G18";
        case 18070000004:
            return "沙漠之鹰";
        case 18070000003:
            return ".375左轮";
        case 18070000002:
            return "GSZ92G";
#pragma mark -- 特殊
        case 18080000007:
            return "火箭筒 [ 特殊 ]";
        case 18040000008:
            return "机枪 [ 特殊 ]";
        case 18110000000:
            return "喷火枪 [ 特殊 ]";
#pragma mark -- 匕首
        case 18100000009:
            return "黑鹰";
        case 18100000002:
            return "战术匕首";
        case 18100000020:
            return "刺客信条";
        case 18100000008:
            return "赤枭";
        case 18100000017:
            return "电锯";
#pragma mark -- 头盔
#pragma mark -- 1级
        case 11010001001:
            return "老式钢盔";
        case 11010001002:
            return "安保头盔";
        case 11010001003:
            return "奔尼帽";
        case 11010001004:
            return "户外棒球帽";
#pragma mark -- 2级
        case 11010002002:
            return "HO1 战术头盔";
        case 11010002003:
            return "DRO 战术头盔";
        case 11010002001:
            return "复古摩托头盔";
        case 11010002004:
            return "MC 防弹头盔";
#pragma mark -- 3级
        case 11010003001:
            return "防暴头盔";
        case 11010003002:
            return "H07 战术头盔";
        case 11010003004:
            return "DAS 防弹头盔";
        case 11010003003:
            return "MC201 防弹头盔";
#pragma mark -- 4级
        case 11010004001:
            return "D6 战术头盔";
        case 11010004002:
            return "MHS 战术头盔";
        case 11010004004:
            return "GT1 战术头盔";
        case 11010004003:
            return "DICH 战术头盔";
#pragma mark -- 5级
        case 11010005001:
            return "Mask-1铁壁头盔";
        case 11010005002:
            return "GN 久战重型夜视头盔";
        case 11010005003:
            return "H09 防爆头盔";
        case 11010005004:
            return "GN 重型头盔";
        case 11010005005:
            return "DICH-1战术头盔";
        case 11010005006:
            return "GN 重型夜视头盔";
#pragma mark -- 6级
        case 11010006005:
            return "幸运头盔";
        case 11010006003:
            return "DICH-9重型头盔";
        case 11010006002:
            return "GT5 指挥官头盔";
        case 11010006004:
            return "H70 夜视精英头盔";
        case 11010006001:
            return "H70 精英头盔";
#pragma mark -- 防弹衣
#pragma mark -- 1级
        case 11050001001:
            return "摩托马甲";
        case 22:
            return "安保防弹衣";
        case 11050001003:
            return "尼龙防弹衣";
        case 11050001004:
            return "轻型防弹衣";
#pragma mark -- 2级
        case 11050002001:
            return "简易防刺服";
        case 11050002002:
            return "HT战术背心";
        case 11050002003:
            return "TG战术防弹衣";
        case 11050002004:
            return "通用战术背心";
#pragma mark -- 3级
        case 11050003002:
            return "Hvk快拆防弹衣";
        case 11050003001:
            return "制式防弹背心";
        case 11050003003:
            return "TG-H防弹衣";
        case 11050003004:
            return "射手战术背心";
#pragma mark -- 4级
        case 11050004001:
            return "武士防弹背心";
        case 11050004007:
            return "HMP特勤防弹衣";
        case 11050004002:
            return "突击手防弹背心";
        case 11050004003:
            return "DT-AVS防弹衣";
        case 11050004004:
            return "MK-2战术背心";
#pragma mark -- 5级
        case 11050005001:
            return "精英防弹背心";
        case 11050005002:
            return "Hvk-2防弹衣";
        case 11050005003:
            return "FS复合防弹衣";
        case 11050005004:
            return "重型突击背心";
#pragma mark -- 6级
        case 11050006002:
            return "特里克MAS2.0装甲";
        case 11050006003:
            return "泰坦防弹装甲";
        case 11050006004:
            return "金刚防弹衣";
        case 11050006001:
            return "HA-2重型防弹衣";
#pragma mark -- 胸挂
#pragma mark -- 1级
        case 11070001001:
             return "便携胸包";
        case 11070001002:
            return "快速侦察胸挂";
        case 11070001003:
            return "轻型战术胸挂";
        case 11070001004:
            return "简易挂载包";
#pragma mark -- 2级
        case 11070002001:
            return "尼龙挎包";
        case 11070002002:
            return "HK3便携胸挂";
        case 11070002003:
            return "D01轻型胸挂";
        case 11070002004:
            return "通用战术胸挂";
#pragma mark -- 3级
        case 11070003001:
            return "简易携行弹挂";
        case 11070003002:
            return "HD3战术胸挂";
        case 11070003003:
            return "DSA战术胸挂";
        case 11070003004:
            return "G01战术胸挂";
#pragma mark -- 4级
        case 11070004001:
            return "强袭战术背心";
        case 11070004002:
            return "突击者战术背心";
        case 11070004003:
            return "DRC先进侦察胸挂";
        case 11070004004:
            return "GIR野战胸挂";
#pragma mark -- 5级
        case 11070006001:
            return "DRA突击手胸挂";
        case 11070006002:
            return "黑影野战胸挂";
#pragma mark -- 背包
#pragma mark -- 1级
        case 11080001001:
            return "斜挎包";
        case 11080001002:
            return "运动背包";
        case 11080001003:
            return "旅行背包";
        case 11080001005:
            return "帆布背囊";
        case 11080001004:
            return "DG运动背包";
#pragma mark -- 2级
        case 11080002001:
            return "轻型户外背包";
        case 11080002004:
            return "露营背包";
        case 11080002002:
            return "战术快拆背包";
        case 11080002003:
            return "突袭战术背包";
#pragma mark -- 3级
        case 11080003001:
            return "大型登山包";
        case 11080003002:
            return "3H战术背包";
        case 11080003003:
            return "DASH战术背包";
        case 11080003004:
            return "GA野战背包";
        case 11080003005:
            return "雨林猎手背包";
#pragma mark -- 4级
        case 11080004001:
            return "MAP侦察背包";
        case 11080004002:
            return "野战徒步背包";
        case 11080004003:
            return "D2战术登山包";
        case 11080004004:
            return "GT1户外登山包";
        case 11080004005:
            return "生存战术背包";
#pragma mark -- 5级
        case 11080005001:
            return "ALS背负系统";
        case 11080005002:
            return "HLS-2重型背包";
        case 11080005003:
            return "D3战术登山包";
        case 11080005004:
            return "GT5野战背包";
#pragma mark -- 6级
        case 11080006001:
            return "重型登山包";
        case 11080006002:
            return "D7战术背包";
        case 11080006003:
            return "GTO重型战术包";
#pragma mark -- 安全箱
        case 11090000001:
            return "基础安全箱";
        case 11090000002:
            return "进阶安全箱";
        case 11090000004:
            return "进阶安全箱";
        case 11090000072:
            return "高级安全箱";
        case 11090000073:
            return "高级安全箱";
        case 11090000074:
            return "顶级安全箱";
#pragma mark -- 物品
#pragma mark -- 1级
        case 15030010009:
            return "鼠标";
        case 15040010016:
            return "网线";
        case 14020000002:
            return "车载急救包";
#pragma mark -- 2级
        case 15080040004:
            return "残弹挂坠";
        case 15080050111:
            return "9V电池";
        case 15020010008:
            return "原木木板";
        case 15030010014:
            return "键盘";
        case 15030010011:
            return "电源";
        case 15030010019:
            return "机械硬盘";
        case 15020040003:
            return "压力计";
        case 15080050110:
            return "充电电池组";
        case 15070010006:
            return "建筑图纸2号";
        case 15200000134:
            return "好粥道-莲子玉米粥";
        case 15200000138:
            return "好粥道-薏米红豆粥";
#pragma mark -- 3级
        case 15080050076:
            return "糖三角";
        case 15080050193:
            return "鸟雕";
        case 14070000008:
            return "OE2战斗兴奋剂";
        case 15060010006:
            return "听诊器";
        case 15200000139:
            return "好粥道-紫薯紫米粥";
        case 15070040002:
            return "资料: 商业文件";
        case 15020010015:
            return "一包水泥";
        case 15110400001:
            return "青铜身份牌";
        case 15110400002:
            return "白银身份牌";
#pragma mark -- 4级
        case 14050000003:
            return "DVE止疼片";
        case 15030050005:
            return "HIFI声卡";
        case 15070050002:
            return "资料: 军事情报";
        case 15080050114:
            return "人工膝关节";
        case 15030040014:
            return "电子干扰器";
        case 15080050001:
            return "后妃耳环";
        case 14030000003:
            return "DEK手术包";
        case 14060000005:
            return "标准头修";
        case 14060000006:
            return "标准甲修";
        case 15080050038:
            return "专业声卡";
        case 15080050064:
            return "卫队档案";
        case 15030040007:
            return "ASOS电脑主板";
        case 15090910149:
            return "一盘监控录像";
        case 15080050018:
            return "黄金饰章";
        case 15040010014:
            return "阿萨拉风情水壶";
        case 15080050136:
            return "鳄鱼蛋";
        case 15030040006:
            return "内存条";
        case 15080050139:
            return "图腾箭矢";
        case 15020050005:
            return "特种钢";
        case 15030040005:
            return "固态硬盘";
#pragma mark -- 5级
        case 15200000014:
            return "好粥道-椰奶燕麦粥";
        case 15080050015:
            return "阿萨拉特色酒杯";
        case 16110900023:
            return "隐秘协议箱#D6";
    };
    return to_string(ID);
};

int 取装备等级(string ItemID) {
    if (ItemID == "老式钢盔" ||
        ItemID == "安保头盔" ||
        ItemID == "奔尼帽" ||
        ItemID == "户外棒球帽" ||
        
        ItemID == "摩托马甲" ||
        ItemID == "安保防弹衣" ||
        ItemID == "尼龙防弹衣" ||
        ItemID == "轻型防弹衣" ||
        
        ItemID == "便携胸包" ||
        ItemID == "快速侦察胸挂" ||
        ItemID == "轻型战术胸挂" ||
        ItemID == "简易挂载包" ||
        
        ItemID == "斜挎包" ||
        ItemID == "运动背包" ||
        ItemID == "旅行背包" ||
        ItemID == "帆布背囊" ||
        ItemID == "DG运动背包" ||
        
        ItemID == "基础安全箱") {
        return 1;
    };
    if (ItemID == "HO1 战术头盔" ||
        ItemID == "DRO 战术头盔" ||
        ItemID == "复古摩托头盔" ||
        ItemID == "MC 防弹头盔" ||
        
        ItemID == "简易防刺服" ||
        ItemID == "HT战术背心" ||
        ItemID == "TG战术防弹衣" ||
        ItemID == "通用战术背心" ||
        
        ItemID == "尼龙挎包" ||
        ItemID == "HK3便携胸挂" ||
        ItemID == "D01轻型胸挂" ||
        ItemID == "通用战术胸挂" ||
        
        ItemID == "轻型户外背包" ||
        ItemID == "露营背包" ||
        ItemID == "战术快拆背包" ||
        ItemID == "突袭战术背包" ||
        
        ItemID == "进阶安全箱") {
        return 2;
    };
    if (ItemID == "防暴头盔" ||
        ItemID == "H07 战术头盔" ||
        ItemID == "DAS 防弹头盔" ||
        ItemID == "MC201 防弹头盔" ||
        
        ItemID == "Hvk快拆防弹衣" ||
        ItemID == "制式防弹背心" ||
        ItemID == "TG-H防弹衣" ||
        ItemID == "射手战术背心" ||
        
        ItemID == "简易携行弹挂" ||
        ItemID == "HD3战术胸挂" ||
        ItemID == "DSA战术胸挂" ||
        ItemID == "G01战术胸挂" ||
        
        ItemID == "大型登山包" ||
        ItemID == "3H战术背包" ||
        ItemID == "DASH战术背包" ||
        ItemID == "GA野战背包" ||
        ItemID == "雨林猎手背包" ||
        
        ItemID == "高级安全箱") {
        return 3;
    };
    if (ItemID == "D6 战术头盔" ||
        ItemID == "MHS 战术头盔" ||
        ItemID == "GT1 战术头盔" ||
        ItemID == "DICH 战术头盔" ||
        
        ItemID == "武士防弹背心" ||
        ItemID == "HMP特勤防弹衣" ||
        ItemID == "突击手防弹背心" ||
        ItemID == "DT-AVS防弹衣" ||
        ItemID == "MK-2战术背心" ||
        
        ItemID == "强袭战术背心" ||
        ItemID == "突击者战术背心" ||
        ItemID == "DRC先进侦察胸挂" ||
        ItemID == "GIR野战胸挂" ||
        
        ItemID == "MAP侦察背包" ||
        ItemID == "野战徒步背包" ||
        ItemID == "D2战术登山包" ||
        ItemID == "GT1户外登山包" ||
        ItemID == "生存战术背包" ||
        
        ItemID == "顶级安全箱") {
        return 4;
    };
    if (ItemID == "Mask-1铁壁头盔" ||
        ItemID == "GN 久战重型夜视头盔" ||
        ItemID == "H09 防爆头盔" ||
        ItemID == "GN 重型头盔" ||
        ItemID == "DICH-1战术头盔" ||
        ItemID == "GN 重型夜视头盔" ||
        
        ItemID == "精英防弹背心" ||
        ItemID == "Hvk-2防弹衣" ||
        ItemID == "FS复合防弹衣" ||
        ItemID == "重型突击背心" ||
        
        ItemID == "DRA突击手胸挂" ||
        ItemID == "黑影野战胸挂" ||
        
        ItemID == "ALS背负系统" ||
        ItemID == "HLS-2重型背包" ||
        ItemID == "D3战术登山包" ||
        ItemID == "GT5野战背包") {
        return 5;
    };
    if (ItemID == "幸运头盔" ||
        ItemID == "DICH-9重型头盔" ||
        ItemID == "GT5 指挥官头盔" ||
        ItemID == "H70 夜视精英头盔" ||
        ItemID == "H70 精英头盔" ||
        
        ItemID == "特里克MAS2.0装甲" ||
        ItemID == "泰坦防弹装甲" ||
        ItemID == "金刚防弹衣" ||
        ItemID == "HA-2重型防弹衣" ||
        ItemID == "重型登山包" ||
        ItemID == "D7战术背包" ||
        ItemID == "GTO重型战术包") {
        return 6;
    };
    return 0;
};
