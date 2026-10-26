#pragma once
#include <string>

// 常见 PUBG 手持武器 ID → 中文显示名（对齐 wasd 纹理编号）
static inline std::string GetWeaponDisplayName(int id) {
  switch (id) {
    // 突击步枪 101xxx
    case 101001: return "M16A4";
    case 101002: return "AKM";
    case 101003: return "SCAR-L";
    case 101004: return "M416";
    case 101005: return "Groza";
    case 101006: return "AUG";
    case 101007: return "QBZ";
    case 101008: return "M762";
    case 101009: return "Mk47";
    case 101010: return "G36C";
    case 101011: return "AC-Val";
    case 101012: return "蜜獾";
    case 101013: return "FAMAS";
    case 101014: return "ACE32";
    case 101016: return "ARX200";
    // 冲锋枪 102xxx
    case 102001: return "UZI";
    case 102002: return "UMP45";
    case 102003: return "Vector";
    case 102004: return "汤姆逊";
    case 102005: return "野牛";
    case 102007: return "MP5K";
    case 102008: return "P90";
    case 102009: return "JS9";
    case 102010: return "AKS74U";
    case 102105: return "MP5";
    // 狙击 / 射手 103xxx
    case 103001: return "Kar98K";
    case 103002: return "M24";
    case 103003: return "AWM";
    case 103004: return "SKS";
    case 103005: return "VSS";
    case 103006: return "Mini14";
    case 103007: return "Mk14";
    case 103008: return "Win94";
    case 103009: return "SLR";
    case 103010: return "QBU";
    case 103011: return "莫辛纳甘";
    case 103012: return "Mk12";
    case 103013: return "M417";
    case 103014: return "SVD";
    case 103015: return "M200";
    case 103016: return "AMR";
    case 103017: return "MK20-H";
    case 103018: return "M1加兰德";
    case 103100: return "爆炸弓";
    case 103101: return "十字弩";
    // 霰弹枪 104xxx
    case 104001: return "S1897";
    case 104002: return "S686";
    case 104003: return "S12K";
    case 104004: return "DBS";
    case 104005: return "SPAS-12";
    case 104100: return "AA12";
    // 轻机枪 105xxx
    case 105001: return "M249";
    case 105002: return "DP-28";
    case 105010: return "MG3";
    case 105012: return "PKM";
    case 105013: return "MG36";
    case 105015: return "轻机枪";
    // 投掷物 602xxx
    case 602001: return "破片手雷";
    case 602002: return "震撼弹";
    case 602003: return "烟雾弹";
    case 602004: return "燃烧瓶";
    case 602075: return "粘性炸弹";
    default:
      return std::to_string(id);
  }
}
