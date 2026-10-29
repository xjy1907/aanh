//
//  ESP.h
//  IMgui框架
//
//  Created by CosmkZ on 2025/2/24.
//
#import "BBZViewController.h"
#import <UIKit/UIKit.h>
#include <vector>
#include <stdio.h>
#include <string>

@interface DrawWindow : NSObject






@end

using namespace std;

#ifndef IM_PI
#define IM_PI 3.14159265358979323846f
#endif

#define 纯红          0xFF0000FF  // 纯红色，不透明
#define 纯绿          0xFF00FF00  // 纯绿色，不透明
#define 纯蓝          0xFFFF0000  // 纯蓝色，不透明
#define 纯白          0xFFFFFFFF  // 纯白色，不透明
#define 纯黑          0xFF000000  // 纯黑色，不透明
#define 浅灰          0xFFD3D3D3  // 浅灰色，不透明
#define 深灰          0xFF808080  // 深灰色，不透明
#define 粉红          0xFFCBC0FF  // 粉红色，不透明
#define 天蓝          0xFFEBCE87  // 天蓝色，不透明
#define 金黄          0xFF00D7FF  // 金黄色，不透明
#define 深红          0xFF00008B  // 深红色，不透明
#define 深绿          0xFF006400  // 深绿色，不透明
#define 深蓝          0xFF8B0000  // 深蓝色，不透明
#define 半透明白      0x80FFFFFF  // 半透明白色
#define 半透明黑      0x80000000  // 半透明黑色
#define 橙黄          0xFF00A5FF  // 橙黄色，不透明
#define 紫罗兰        0xFFEE82EE  // 紫罗兰色，不透明
#define 青绿          0xFFFFFF00  // 青绿色，不透明
#define 深紫          0xFF800080  // 深紫色，不透明
#define 米白          0xFFDCF5F5  // 米白色，不透明
#define 珊瑚红        0xFF507FFF  // 珊瑚红色，不透明
#define 橄榄绿        0xFF008080  // 橄榄绿色，不透明
#define 巧克力色      0xFF1E69D2  // 巧克力色，不透明
#define 番茄红        0xFF4763FF  // 番茄红色，不透明
#define 松绿          0xFF578B2E  // 松绿色，不透明
#define 海军蓝        0xFF800000  // 海军蓝色，不透明
#define 玫瑰红        0xFF7F00FF  // 玫瑰红色，不透明
#define 柠檬黄        0xFF00FFFF  // 柠檬黄色，不透明
#define 靛蓝          0xFF82004B  // 靛蓝色，不透明
#define 桃红          0xFFB4E5FF  // 桃红色，不透明
#define 薄荷绿        0xFF98FB98  // 薄荷绿色，不透明
#define 咖啡色        0xFF374E6F  // 咖啡色，不透明
#define 象牙白        0xFFF0FFFF  // 象牙白色，不透明
#define 宝石蓝        0xFFE16941  // 宝石蓝色，不透明
#define 薰衣草紫      0xFFFAE6E6  // 薰衣草紫色，不透明
#define 砖红色        0xFF2222B2  // 砖红色，不透明
#define 孔雀蓝        0xFF808000  // 孔雀蓝色，不透明
#define 蜜橙          0xFF66B3FF  // 蜜橙色，不透明
#define 玫瑰金        0xFF796EB7  // 玫瑰金色，不透明
#define 雪白          0xFFFAFAFF  // 雪白色，不透明
#define 午夜蓝        0xFF701919  // 午夜蓝色，不透明



namespace Draw {

void StartBooks();

// 对标 wasd：用 ForegroundDrawList，保证盖在最上层
inline ImDrawList* DrawListFG() {
    return BBZGUI::GetForegroundDrawList();
}

inline void DrawLine(ImVec2 startPoint, ImVec2 endPoint, int color, float thicknes = 1)
{
    DrawListFG()->AddLine(startPoint, endPoint, color, thicknes);
}


inline void DrawCircle(ImVec2 center, float radius, int color, float thicknes = 1)
{
    DrawListFG()->AddCircle(center, radius, color, radius, thicknes);
}


inline void DrawCircleFilled(ImVec2 center, float radius, int color)
{
    DrawListFG()->AddCircleFilled(center, radius, color, radius);
}


inline void DrawRect(ImVec2 min, ImVec2 max, int color, float thicknes)
{
    DrawListFG()->AddRect(min, max, color, 5.0, 0.7f, thicknes);
}


inline void DrawRectFilled(const ImVec2& min, const ImVec2& max, ImU32 color, float rounding = 5.0f) {
    DrawListFG()->AddRectFilled(min, max, color, rounding);
}

inline void DrawConvexPolyFilled(const ImVec2* points, int num_points, ImU32 color) {
    DrawListFG()->AddConvexPolyFilled(points, num_points, color);
}

inline void DrawText(const char *str, ImVec2 pos, bool isCentered, int color, bool outline, float fontSize)
{
    if (!str) return;
    ImVec2 vec2 = pos;
    ImDrawList* dl = DrawListFG();
    if (!dl) return;

    if (isCentered) {
        ImFont* font = BBZGUI::GetFont();
        if (font) {
            ImVec2 textSize = font->CalcTextSizeA(fontSize, MAXFLOAT, 0.0f, str);
            vec2.x -= textSize.x * 0.5f;
        }
    }
    if (outline)
    {
        // 对标 wasd：70% 不透明黑色描边
        ImU32 outlineColor = IM_COL32(0, 0, 0, 178);
        dl->AddTextX(ImVec2(vec2.x + 1, vec2.y + 1), outlineColor, fontSize, str);
        dl->AddTextX(ImVec2(vec2.x - 1, vec2.y - 1), outlineColor, fontSize, str);
        dl->AddTextX(ImVec2(vec2.x + 1, vec2.y - 1), outlineColor, fontSize, str);
        dl->AddTextX(ImVec2(vec2.x - 1, vec2.y + 1), outlineColor, fontSize, str);
    }
    dl->AddTextX(vec2, color, fontSize, str);
}

inline void DrawText(const string &text, ImVec2 pos, bool isCentered, int color, bool outline, float fontSize)
{
    DrawText(text.c_str(), pos, isCentered, color, outline, fontSize);
}

}
