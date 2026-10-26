//
//  ItemConfig.mm
//  物资配置管理
//

#import "ItemConfig.h"

@implementation ItemConfig

+ (NSDictionary *)getItemDatabase {
    static NSDictionary *itemDatabase = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        itemDatabase = @{
            // 突击步枪 (7.62MM)
        @"突击步枪": @[
            @{@"className": @"BP_Rifle_AKM_Wrapper_C", @"name": @"AKM"},
            @{@"className": @"BP_Rifle_ACE32_Wrapper_C", @"name": @"ACE32"},
            @{@"className": @"BP_Rifle_HoneyBadger_Wrapper_C", @"name": @"蜜獾"},
            @{@"className": @"BP_Rifle_ARX200_CWrapper_C", @"name": @"ARX200"},
            @{@"className": @"BP_Rifle_M762_Wrapper_C", @"name": @"M762"},
            @{@"className": @"BP_Rifle_Groza_Wrapper_C", @"name": @"Groza"},
            @{@"className": @"BP_Rifle_SCAR_Wrapper_C", @"name": @"SCAR"},
            @{@"className": @"BP_Rifle_M416_Wrapper_C", @"name": @"M416"},
            @{@"className": @"BP_Rifle_G36_Wrapper_C", @"name": @"G36"},
            @{@"className": @"BP_Rifle_Famas_Wrapper_C", @"name": @"Famas"}
        ],
        
        // 冲锋枪
        @"冲锋枪": @[
            @{@"className": @"BP_MachineGun_UMP9_Wrapper_C", @"name": @"UMP45"},
            @{@"className": @"BP_MachineGun_JS9_Wrapper_C", @"name": @"JS9"},
            @{@"className": @"BP_MachineGun_AKS74U_Wrapper_C", @"name": @"AKS74U"},
            @{@"className": @"BP_MachineGun_Vector_Wrapper_C", @"name": @"Vector"}
        ],
        
        // 霰弹枪
        @"霰弹枪": @[
            @{@"className": @"BP_ShotGun_S12K_Wrapper_C", @"name": @"S12K"},
            @{@"className": @"BP_ShotGun_DP12_Wrapper_C", @"name": @"DBS"},
            @{@"className": @"BP_ShotGun_SPAS_Wrapper_C", @"name": @"SPAS"},
            @{@"className": @"BP_ShotGun_AA12_Wrapper_C", @"name": @"AA12"}
        ],
        
        // 栓动狙击
        @"栓动狙击": @[
            @{@"className": @"BP_Sniper_SVD_Wrapper_C", @"name": @"SVD"},
            @{@"className": @"BP_Sniper_M200_Wrapper_C", @"name": @"M200"},
            @{@"className": @"BP_Sniper_AMR_Wrapper_C", @"name": @"AMR"}
        ],
        
        // 射手步枪
        @"射手步枪": @[
            @{@"className": @"BP_Sniper_SKS_Wrapper_C", @"name": @"SKS"},
            @{@"className": @"BP_Rifle_M417_Wrapper_C", @"name": @"M417"},
            @{@"className": @"BP_Sniper_M1Garand_CWrapper_C", @"name": @"M1加兰德"},
            @{@"className": @"BP_Sniper_Mini14_Wrapper_C", @"name": @"Mini14"}
        ],
        
        // 轻机枪
        @"轻机枪": @[
            @{@"className": @"BP_Other_PKM_Wrapper_C", @"name": @"PKM"},
            @{@"className": @"BP_Other_MG36_Wrapper_C", @"name": @"MG36"}
        ],
        
        // 其他武器
        @"其他武器": @[
            @{@"className": @"BP_Other_Mortar_Wrapper_C", @"name": @"迫击炮"},
            @{@"className": @"BP_Other_HuntingBow_Wrapper_C", @"name": @"爆炸弓"}
        ],
        
        // 枪械配件
        @"枪械配件": @[
            // 冲锋枪配件
            @{@"className": @"QK_Mid_Suppressor", @"name": @"冲锋消音器"},
            @{@"className": @"DJ_Mid_EQ", @"name": @"冲锋快扩"},
            // 霰弹枪配件
            @{@"className": @"BP_QK_Choke_Pickup", @"name": @"收束器"},
            @{@"className": @"BP_QK_DuckBill_Pickup", @"name": @"鸭嘴"},
            @{@"className": @"BP_DJ_ShotGun_Pickup_C", @"name": @"散弹快扩"},
            // 狙击枪配件
            @{@"className": @"DJ_Sniper_EQ", @"name": @"狙击快扩"},
            @{@"className": @"BP_QT_Sniper_Pickup", @"name": @"狙击枪托"},
            @{@"className": @"QK_Sniper_Suppressor", @"name": @"狙击消音器"},
            // 步枪配件
            @{@"className": @"DJ_Large_EQ_Pickup_C", @"name": @"步枪快扩"},
            @{@"className": @"BP_QT_A_Pickup", @"name": @"步枪枪托"},
            @{@"className": @"BP_WB_LightGrip_Pickup_C", @"name": @"轻型握把"},
            @{@"className": @"BP_WB_Lasersight_Pickup_C", @"name": @"激光瞄准"},
            @{@"className": @"BP_WB_Angled_Pickup_C", @"name": @"直角握把"},
            @{@"className": @"QK_Large_Suppressor", @"name": @"步枪消音器"},
            // 倍镜
            @{@"className": @"MZJ_8X_Pickup_C", @"name": @"8倍镜"},
            @{@"className": @"MZJ_6X_Pickup_C", @"name": @"6倍镜"},
            @{@"className": @"MZJ_3X_Pickup_C", @"name": @"3倍镜"}
        ],
        
        // 游戏载具
    @"游戏载具": @[
        @{@"className": @"_Mountainbike_Training_C", @"name": @"自行车"},
        @{@"className": @"VH_HammerShark_C", @"name": @"小鲨鱼"},
        @{@"className": @"VH_Sleigh_C", @"name": @"雪橇飞车"},
        @{@"className": @"PickUp_BP_VH_Sleigh_Ground_C", @"name": @"飞车刷新"},
        @{@"className": @"BP_CG034_SleighShow_ControllRoom_C", @"name": @"飞车刷新"},
        @{@"className": @"Mirado", @"name": @"双人跑车"},
        @{@"className": @"VH_Motorcycle_1_C", @"name": @"沙舟车"},
        @{@"className": @"VH_FlyHorse_C", @"name": @"飞马"},
        @{@"className": @"Scooter", @"name": @"小绵羊"},
        @{@"className": @"VH_Horse", @"name": @"马"},
        @{@"className": @"_BRDM_C", @"name": @"装甲车"},
        @{@"className": @"VH_Motorcycle_C", @"name": @"摩托车"},
        @{@"className": @"Snowmobile", @"name": @"雪地摩托"},
        @{@"className": @"StationWagon", @"name": @"旅行车"},
        @{@"className": @"BP_VH_Buggy", @"name": @"蹦蹦车"},
        @{@"className": @"VH_Dacia_", @"name": @"轿车"},
        @{@"className": @"VH_UAZ01_New_C", @"name": @"吉普车"},
        @{@"className": @"PickUp_07_C", @"name": @"皮卡车"},
        @{@"className": @"CoupeRB", @"name": @"双人跑车"},
        @{@"className": @"_MiniBus_01_C", @"name": @"迷你巴士"},
        @{@"className": @"_PG117_C", @"name": @"快艇"},
        @{@"className": @"uaRail_1_C", @"name": @"摩托艇"},
        @{@"className": @"_Motorglider_C", @"name": @"滑翔机"},
        @{@"className": @"BP_VH_Bigfoot_C", @"name": @"大脚车"},
        @{@"className": @"VH_ATV1_C", @"name": @"四轮摩托"},
        @{@"className": @"Rony_01_C", @"name": @"行李车"},
        @{@"className": @"VH_UTV_C", @"name": @"越野车"},
        @{@"className": @"BP_VH_Tuk_1_C", @"name": @"三轮车"},
        @{@"className": @"VH_Snowmobile_C", @"name": @"雪橇车"},
        @{@"className": @"PG117", @"name": @"船"},
        @{@"className": @"VH_4SportCar_C", @"name": @"跑车"},
        @{@"className": @"BP_Excavator_C", @"name": @"挖掘机"},
        @{@"className": @"VH_Kite_C", @"name": @"风筝"},
        @{@"className": @"VH_Drift", @"name": @"拉力赛车"},
        @{@"className": @"VH_Blanc_C", @"name": @"SUV电车"},
        @{@"className": @"VH_Picobus_C", @"name": @"大巴车"},
        @{@"className": @"VH_DumpTruck_C", @"name": @"泥土车"},
        @{@"className": @"VH_Excavator_C", @"name": @"挖掘机"},
        @{@"className": @"HugeMouthJet_RPG_C", @"name": @"战斗机"},
        @{@"className": @"VH_LostMobile_C", @"name": @"霹雳车"},
        @{@"className": @"VH_BBCar_C", @"name": @"溜溜球"},
        @{@"className": @"BP_ShotGun_DP12_C", @"name": @"喷子"},
        @{@"className": @"BP_ShotGun_S12K_C", @"name": @"喷子"},
        @{@"className": @"BP_ShotGun_SPAS-12_C", @"name": @"喷子"},
        @{@"className": @"VH_DesertCar_C", @"name": @"沙漠越野车"}
        ],
        
        // 游戏道具
        @"游戏道具": @[
            @{@"className": @"ojGrenade_BP_C", @"name": @"手雷"},
            @{@"className": @"BP_PickUp_SnowBro_Ground_C", @"name": @"雪人"},
            @{@"className": @"BP_PickupWrapper_Key_C", @"name": @"密室"},
            @{@"className": @"BP_PickUp_SnowBro_C", @"name": @"雪人"},
            @{@"className": @"BP_CommercialWrapper_LV2_C", @"name": @"突击兵密钥"},
            @{@"className": @"BP_CommercialWrapper_LV3_C", @"name": @"特种兵密钥"},
            @{@"className": @"BP_CommercialWrapper_LV4_C", @"name": @"指挥官密钥"},
            @{@"className": @"PilotUAV_Vehicle_C", @"name": @"无人机"},
            @{@"className": @"BP_WarDog_C", @"name": @"旺财"},
            @{@"className": @"BP_IcePearADS_C", @"name": @"防雷"},
            @{@"className": @"BP_LandMin_Poison_C", @"name": @"地雷 冰"},
            @{@"className": @"BP_Stun_LandMine_C", @"name": @"地雷 闪"},
            @{@"className": @"BP_Flash_Transport_MarkEffect_C", @"name": @"闪电"},
            @{@"className": @"BP_PaintingGirl_ActivityActor_C", @"name": @"涂鸦"},
            @{@"className": @"BP_AirraidActor_C", @"name": @"空袭"},
            @{@"className": @"BP_TraceGrenade", @"name": @"追踪雷"},
            @{@"className": @"BP_DragonSpearActorOut_C", @"name": @"雷枪"},
            @{@"className": @"BP_QuantumBall_C", @"name": @"飞镖"},
            @{@"className": @"ojBurn_BP_C", @"name": @"燃烧"},
            @{@"className": @"BP_Pistol_RevivalFlaregun", @"name": @"召回枪"},
            @{@"className": @"BP_Ammo_RevivalFlare_Pickup_C", @"name": @"召回弹"},
            @{@"className": @"BP_Ammo_Flare_Pickup_C", @"name": @"信号弹"},
            @{@"className": @"Pistol_Flaregun", @"name": @"信号枪"},
            @{@"className": @"revivalAED_Pickup_C", @"name": @"自救器"},
            @{@"className": @"BP_Neon_Coin_Pickup_C", @"name": @"钱"},
            @{@"className": @"BP_Pickup_Finger_C", @"name": @"飞索"},
            @{@"className": @"BP_Grenade_EmergencyCall_Weapon_Wrapper_C", @"name": @"紧急呼救器"},
            @{@"className": @"BP_Other_Mortar_Bullet_C", @"name": @"迫击炮弹"},
            @{@"className": @"BP_AirdropChipBox_C", @"name": @"金仓"},
            @{@"className": @"perPeopleSkill", @"name": @"金插"}
        ],
        
        // 物资箱子
        @"物资箱子": @[
            @{@"className": @"CharacterDeadInventoryBox_C", @"name": @"盒子"},
            @{@"className": @"LostTombPlayerTombBox_C", @"name": @"盒子"},
            @{@"className": @"EscapePlayerTombBox_C", @"name": @"盒子"},
            @{@"className": @"BP_SuperPeopleDeadBox_C", @"name": @"盒子"},
            @{@"className": @"BP_LostTomb_TreeHole_C", @"name": @"树"},
            @{@"className": @"BP_LostTomb_SupplyBox1_C", @"name": @"1宝箱"},
            @{@"className": @"BP_LostTomb_SupplyBox1_2_C", @"name": @"2宝箱"},
            @{@"className": @"BP_LostTomb_Basket_C", @"name": @"篮子"},
            @{@"className": @"BP_LostTomb_Container1_C", @"name": @"首饰盒"},
            @{@"className": @"BP_LostTomb_SupplyBox1_3_C", @"name": @"3宝箱"},
            @{@"className": @"AirDropBox_C", @"name": @"空投"},
            @{@"className": @"AirDropBox", @"name": @"空投"},
            @{@"className": @"BP_AirDropBox_SuperPeople_C", @"name": @"空投"},
            @{@"className": @"AirDropListWrapperActor", @"name": @"空投"},
            @{@"className": @"MilitarySupplyBoxBase_Baltic", @"name": @"主题箱子"},
            @{@"className": @"MilitarySupp", @"name": @"主题箱子"},
            @{@"className": @"CG027_Lottery_C", @"name": @"扭蛋机"},
            @{@"className": @"CG030_Market_SafeBox_C", @"name": @"保险箱1"},
            @{@"className": @"CG030_Market_SafeBox_2_C", @"name": @"保险箱2"},
            @{@"className": @"EscapeBox_HardRadiationBox_Lv3_C", @"name": @"辐射"},
            @{@"className": @"EscapeBox_PeakRadiationBox_Lv3_C", @"name": @"辐射"},
            @{@"className": @"EscapeBoxPeak_SupplyBox_Lv4_C", @"name": @"物资箱"},
            @{@"className": @"EscapeBoxPeak_SupplyBox_Lv3_C", @"name": @"物资箱"},
            @{@"className": @"EscapeBox_SpeEffect_C", @"name": @"超级物资箱"},
            @{@"className": @"EscapeBox_DTSupplyBox_Lv4_C", @"name": @"物资箱"},
            @{@"className": @"EscapeBoxHard_DTSupplyBox_Lv3_5_C", @"name": @"物资箱"},
            @{@"className": @"EscapeBoxHight_RadiationBox_Lv4_C", @"name": @"辐射"},
            @{@"className": @"EscapeBoxHight_PLMSupplyBox_Lv4_C", @"name": @"物资箱"},
            @{@"className": @"EscapeBox_HardRadiationBox_Lv4_C", @"name": @"物资箱"},
            @{@"className": @"EscapeBoxHard_DTSupplyBox_Lv4_C", @"name": @"物资箱"},
            @{@"className": @"EscapeBoxPeak_RadiationBox_Lv4_C", @"name": @"物资箱"},
            @{@"className": @"BP_LostTomb_Carriage_C", @"name": @"马车"},
            @{@"className": @"BP_LostTomb_SupplyCoffin2_C", @"name": @"棺材"},
            @{@"className": @"EscapeBoxPeak_DTSupplyBox_Lv3_5_C", @"name": @"物资箱"},
            @{@"className": @"EscapeBoxPeak_DTSupplyBox_Lv4_C", @"name": @"物资箱"},
            @{@"className": @"EscapeBoxPeak_PLMSupplyBox_Lv4_C", @"name": @"物资箱"},
            @{@"className": @"EscapeBoxPeak_SupplyBox_Lv1_C", @"name": @"物资箱"},
            @{@"className": @"EscapeBox_PeakRadiationBox_Lv4_C", @"name": @"辐射"},
            @{@"className": @"EscapeBoxHight_SupplyBox_", @"name": @"物资箱"}
        ],
        
        // 治疗药品
        @"治疗药品": @[
            @{@"className": @"ink_Pickup_C", @"name": @"饮料"},
            @{@"className": @"lls_Pickup_C", @"name": @"止痛药"},
            @{@"className": @"jection_Pickup_C", @"name": @"肾上腺素"},
            @{@"className": @"rstAidbox_Pickup_C", @"name": @"医疗箱"}
        ],
        
        // 防具
        @"防具": @[
            @{@"className": @"BP_Armor_Lv3_C", @"name": @"三 甲"},
            @{@"className": @"Bag_Lv3", @"name": @"三 包"},
            @{@"className": @"BP_Helmet_Lv3_C", @"name": @"三 头"},
        ],
        
        // 弹药
        @"弹药": @[
            @{@"className": @"Ammo_556", @"name": @"5.56MM"},
            @{@"className": @"Ammo_9mm", @"name": @"9MM"},
            @{@"className": @"Ammo_45AC", @"name": @"45口径"},
            @{@"className": @"Ammo_762", @"name": @"7.62MM"},
            @{@"className": @"Ammo_12Guage", @"name": @"12口径"},
            @{@"className": @"BP_Other_Mortar_Bullet_C", @"name": @"迫击炮弹"},
            @{@"className": @"Ammo_Bolt", @"name": @"箭"}
            ]
        };
    });
    return itemDatabase;
}

+ (NSArray<NSDictionary *> *)getItemsForCategory:(NSString *)category {
    NSDictionary *database = [self getItemDatabase];
    return database[category] ?: @[];
}

+ (NSArray<NSString *> *)getAllCategories {
    return @[
        @"突击步枪",
        @"冲锋枪",
        @"霰弹枪",
        @"栓动狙击",
        @"射手步枪",
        @"轻机枪",
        @"其他武器",
        @"枪械配件",
        @"游戏载具",
        @"游戏道具",
        @"物资箱子",
        @"治疗药品",
        @"防具",
        @"弹药"
    ];
}

+ (NSDictionary *)getDefaultConfigForCategory:(NSString *)category {
    // 根据分类返回默认配置（包括颜色）
    // weaponID: 0=持枪隐藏（拿枪时隐藏），1=默认显示（拿枪时也显示）
    static NSDictionary *defaultConfigs = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultConfigs = @{
            // 突击步枪：钴蓝色，持枪隐藏
            @"突击步枪": @{@"minDistance": @0, @"maxDistance": @100, @"hexColor": @"0099FF", @"weaponID": @0},

            // 冲锋枪：酒红色，持枪隐藏
            @"冲锋枪": @{@"minDistance": @0, @"maxDistance": @100, @"hexColor": @"CC0066", @"weaponID": @0},

            // 霰弹枪：棕橙色，持枪隐藏
            @"霰弹枪": @{@"minDistance": @0, @"maxDistance": @100, @"hexColor": @"E68000", @"weaponID": @0},

            // 栓动狙击：深青色，持枪隐藏
            @"栓动狙击": @{@"minDistance": @0, @"maxDistance": @100, @"hexColor": @"006666", @"weaponID": @0},

            // 射手步枪：深青色，持枪隐藏
            @"射手步枪": @{@"minDistance": @0, @"maxDistance": @100, @"hexColor": @"006666", @"weaponID": @0},

            // 轻机枪：钴蓝色，持枪隐藏
            @"轻机枪": @{@"minDistance": @0, @"maxDistance": @100, @"hexColor": @"0099FF", @"weaponID": @0},

            // 其他武器：中灰色，持枪隐藏
            @"其他武器": @{@"minDistance": @0, @"maxDistance": @100, @"hexColor": @"808080", @"weaponID": @0},

            // 枪械配件：暗橙红，默认显示
            @"枪械配件": @{@"minDistance": @0, @"maxDistance": @100, @"hexColor": @"CC3333", @"weaponID": @0},

            // 游戏载具：纯绿，最小距离10，最大距离600，默认显示
            @"游戏载具": @{@"minDistance": @10, @"maxDistance": @600, @"hexColor": @"00FF00", @"weaponID": @0},

            // 游戏道具：纯黄，最大距离1700，默认显示
            @"游戏道具": @{@"minDistance": @0, @"maxDistance": @1700, @"hexColor": @"FFFF00", @"weaponID": @0},

            // 物资箱子：橄榄绿，最大距离1700，默认显示
            @"物资箱子": @{@"minDistance": @0, @"maxDistance": @1700, @"hexColor": @"4D4D00", @"weaponID": @0},

            // 治疗药品：薄荷绿，默认显示
            @"治疗药品": @{@"minDistance": @0, @"maxDistance": @100, @"hexColor": @"33CC66", @"weaponID": @0},

            // 防具：青蓝色，默认显示
            @"防具": @{@"minDistance": @0, @"maxDistance": @100, @"hexColor": @"00CCCC", @"weaponID": @0},

            // 弹药：橙黄色，默认显示
            @"弹药": @{@"minDistance": @0, @"maxDistance": @100, @"hexColor": @"FF9900", @"weaponID": @0}
        };
    });

    // 返回指定分类的默认配置，如果没有则返回通用默认值（默认显示）
    NSDictionary *config = defaultConfigs[category];
    if (!config) {
        config = @{@"minDistance": @0, @"maxDistance": @100, @"hexColor": @"00FF00", @"weaponID": @1};
    }
    return config;
}

@end
