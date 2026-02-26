// dear imgui, v1.91.6 WIP
// (demo code)

// Help:
// - Read FAQ at http://dearimgui.com/faq
// - Call and read BBZGUI::ShowDemoWindow() in BBZGui_demo.cpp. All applications in examples/ are doing that.
// - Need help integrating Dear BBZGUI in your codebase?
//   - Read Getting Started https://github.com/ocornut/imgui/wiki/Getting-Started
//   - Read 'Programmer guide' in BBZGui.cpp for notes on how to setup Dear BBZGUI in your codebase.
// Read top of BBZGui.cpp and BBZGui.h for many details, documentation, comments, links.
// Get the latest version at https://github.com/ocornut/imgui

// How to easily locate code?
// - Use Tools->Item Picker to debug break in code by clicking any widgets: https://github.com/ocornut/imgui/wiki/Debug-Tools
// - Browse an online version the demo with code linked to hovered widgets: https://pthom.github.io/imgui_manual_online/manual/imgui_manual.html
// - Find a visible string and search for it in the code!

//---------------------------------------------------
// PLEASE DO NOT REMOVE THIS FILE FROM YOUR PROJECT!
//---------------------------------------------------
// Message to the person tempted to delete this file when integrating Dear BBZGUI into their codebase:
// Think again! It is the most useful reference code that you and other coders will want to refer to and call.
// Have the BBZGUI::ShowDemoWindow() function wired in an always-available debug menu of your game/app!
// Also include Metrics! ItemPicker! DebugLog! and other debug features.
// Removing this file from your project is hindering access to documentation for everyone in your team,
// likely leading you to poorer usage of the library.
// Everything in this file will be stripped out by the linker if you don't call BBZGUI::ShowDemoWindow().
// If you want to link core Dear BBZGUI in your shipped builds but want a thorough guarantee that the demo will not be
// linked, you can setup your imconfig.h with #define IMGUI_DISABLE_DEMO_WINDOWS and those functions will be empty.
// In another situation, whenever you have Dear BBZGUI available you probably want this to be available for reference.
// Thank you,
// -Your beloved friend, BBZGui_demo.cpp (which you won't delete)

//--------------------------------------------
// ABOUT THE MEANING OF THE 'static' KEYWORD:
//--------------------------------------------
// In this demo code, we frequently use 'static' variables inside functions.
// A static variable persists across calls. It is essentially a global variable but declared inside the scope of the function.
// Think of "static int n = 0;" as "global int n = 0;" !
// We do this IN THE DEMO because we want:
// - to gather code and data in the same place.
// - to make the demo source code faster to read, faster to change, smaller in size.
// - it is also a convenient way of storing simple UI related information as long as your function
//   doesn't need to be reentrant or used in multiple threads.
// This might be a pattern you will want to use in your code, but most of the data you would be working
// with in a complex codebase is likely going to be stored outside your functions.

//-----------------------------------------
// ABOUT THE CODING STYLE OF OUR DEMO CODE
//-----------------------------------------
// The Demo code in this file is designed to be easy to copy-and-paste into your application!
// Because of this:
// - We never omit the BBZGUI:: prefix when calling functions, even though most code here is in the same namespace.
// - We try to declare static variables in the local scope, as close as possible to the code using them.
// - We never use any of the helpers/facilities used internally by Dear BBZGUI, unless available in the public API.
// - We never use maths operators on ImVec2/ImVec4. For our other sources files we use them, and they are provided
//   by BBZGui.h using the IMGUI_DEFINE_MATH_OPERATORS define. For your own sources file they are optional
//   and require you either enable those, either provide your own via IM_VEC2_CLASS_EXTRA in imconfig.h.
//   Because we can't assume anything about your support of maths operators, we cannot use them in BBZGui_demo.cpp.

// Navigating this file:
// - In Visual Studio: CTRL+comma ("Edit.GoToAll") can follow symbols inside comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
// - In Visual Studio w/ Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols inside comments.
// - In VS Code, CLion, etc.: CTRL+click can follow symbols inside comments.
// - You can search/grep for all sections listed in the index to find the section.

/*

Index of this file:

// [SECTION] Forward Declarations
// [SECTION] Helpers
// [SECTION] Helpers: ExampleTreeNode, ExampleMemberInfo (for use by Property Editor & Multi-Select demos)
// [SECTION] Demo Window / ShowDemoWindow()
// [SECTION] ShowDemoWindowMenuBar()
// [SECTION] ShowDemoWindowWidgets()
// [SECTION] ShowDemoWindowMultiSelect()
// [SECTION] ShowDemoWindowLayout()
// [SECTION] ShowDemoWindowPopups()
// [SECTION] ShowDemoWindowTables()
// [SECTION] ShowDemoWindowInputs()
// [SECTION] About Window / ShowAboutWindow()
// [SECTION] Style Editor / ShowStyleEditor()
// [SECTION] User Guide / ShowUserGuide()
// [SECTION] Example App: Main Menu Bar / ShowExampleAppMainMenuBar()
// [SECTION] Example App: Debug Console / ShowExampleAppConsole()
// [SECTION] Example App: Debug Log / ShowExampleAppLog()
// [SECTION] Example App: Simple Layout / ShowExampleAppLayout()
// [SECTION] Example App: Property Editor / ShowExampleAppPropertyEditor()
// [SECTION] Example App: Long Text / ShowExampleAppLongText()
// [SECTION] Example App: Auto Resize / ShowExampleAppAutoResize()
// [SECTION] Example App: Constrained Resize / ShowExampleAppConstrainedResize()
// [SECTION] Example App: Simple overlay / ShowExampleAppSimpleOverlay()
// [SECTION] Example App: Fullscreen window / ShowExampleAppFullscreen()
// [SECTION] Example App: Manipulating window titles / ShowExampleAppWindowTitles()
// [SECTION] Example App: Custom Rendering using ImDrawList API / ShowExampleAppCustomRendering()
// [SECTION] Example App: Documents Handling / ShowExampleAppDocuments()
// [SECTION] Example App: Assets Browser / ShowExampleAppAssetsBrowser()

*/

#if defined(_MSC_VER) && !defined(_CRT_SECURE_NO_WARNINGS)
#define _CRT_SECURE_NO_WARNINGS
#endif

#include "BBZGui.h"
#ifndef IMGUI_DISABLE

// System includes
#include <ctype.h>          // toupper
#include <limits.h>         // INT_MIN, INT_MAX
#include <math.h>           // sqrtf, powf, cosf, sinf, floorf, ceilf
#include <stdio.h>          // vsnprintf, sscanf, printf
#include <stdlib.h>         // NULL, malloc, free, atoi
#include <stdint.h>         // intptr_t
#if !defined(_MSC_VER) || _MSC_VER >= 1800
#include <inttypes.h>       // PRId64/PRIu64, not avail in some MinGW headers.
#endif
#ifdef __EMSCRIPTEN__
#include <emscripten/version.h>     // __EMSCRIPTEN_major__ etc.
#endif

// Visual Studio warnings
#ifdef _MSC_VER
#pragma warning (disable: 4127)     // condition expression is constant
#pragma warning (disable: 4996)     // 'This function or variable may be unsafe': strcpy, strdup, sprintf, vsnprintf, sscanf, fopen
#pragma warning (disable: 26451)    // [Static Analyzer] Arithmetic overflow : Using operator 'xxx' on a 4 byte value and then casting the result to an 8 byte value. Cast the value to the wider type before calling operator 'xxx' to avoid overflow(io.2).
#endif

// Clang/GCC warnings with -Weverything
#if defined(__clang__)
#if __has_warning("-Wunknown-warning-option")
#pragma clang diagnostic ignored "-Wunknown-warning-option"         // warning: unknown warning group 'xxx'                     // not all warnings are known by all Clang versions and they tend to be rename-happy.. so ignoring warnings triggers new warnings on some configuration. Great!
#endif
#pragma clang diagnostic ignored "-Wunknown-pragmas"                // warning: unknown warning group 'xxx'
#pragma clang diagnostic ignored "-Wold-style-cast"                 // warning: use of old-style cast                           // yes, they are more terse.
#pragma clang diagnostic ignored "-Wdeprecated-declarations"        // warning: 'xx' is deprecated: The POSIX name for this..   // for strdup used in demo code (so user can copy & paste the code)
#pragma clang diagnostic ignored "-Wint-to-void-pointer-cast"       // warning: cast to 'void *' from smaller integer type
#pragma clang diagnostic ignored "-Wformat-security"                // warning: format string is not a string literal
#pragma clang diagnostic ignored "-Wexit-time-destructors"          // warning: declaration requires an exit-time destructor    // exit-time destruction order is undefined. if MemFree() leads to users code that has been disabled before exit it might cause problems. BBZGUI coding style welcomes static/globals.
#pragma clang diagnostic ignored "-Wunused-macros"                  // warning: macro is not used                               // we define snprintf/vsnprintf on Windows so they are available, but not always used.
#pragma clang diagnostic ignored "-Wzero-as-null-pointer-constant"  // warning: zero as null pointer constant                   // some standard header variations use #define NULL 0
#pragma clang diagnostic ignored "-Wdouble-promotion"               // warning: implicit conversion from 'float' to 'double' when passing argument to function  // using printf() is a misery with this as C++ va_arg ellipsis changes float to double.
#pragma clang diagnostic ignored "-Wreserved-id-macro"              // warning: macro name is a reserved identifier
#pragma clang diagnostic ignored "-Wimplicit-int-float-conversion"  // warning: implicit conversion from 'xxx' to 'float' may lose precision
#pragma clang diagnostic ignored "-Wunsafe-buffer-usage"            // warning: 'xxx' is an unsafe pointer used for buffer access
#elif defined(__GNUC__)
#pragma GCC diagnostic ignored "-Wpragmas"                          // warning: unknown option after '#pragma GCC diagnostic' kind
#pragma GCC diagnostic ignored "-Wint-to-pointer-cast"              // warning: cast to pointer from integer of different size
#pragma GCC diagnostic ignored "-Wformat-security"                  // warning: format string is not a string literal (potentially insecure)
#pragma GCC diagnostic ignored "-Wdouble-promotion"                 // warning: implicit conversion from 'float' to 'double' when passing argument to function
#pragma GCC diagnostic ignored "-Wconversion"                       // warning: conversion to 'xxxx' from 'xxxx' may alter its value
#pragma GCC diagnostic ignored "-Wmisleading-indentation"           // [__GNUC__ >= 6] warning: this 'if' clause does not guard this statement      // GCC 6.0+ only. See #883 on GitHub.
#endif

// Play it nice with Windows users (Update: May 2018, Notepad now supports Unix-style carriage returns!)
#ifdef _WIN32
#define IM_NEWLINE  "\r\n"
#else
#define IM_NEWLINE  "\n"
#endif

// Helpers
#if defined(_MSC_VER) && !defined(snprintf)
#define snprintf    _snprintf
#endif
#if defined(_MSC_VER) && !defined(vsnprintf)
#define vsnprintf   _vsnprintf
#endif

// Format specifiers for 64-bit values (hasn't been decently standardized before VS2013)
#if !defined(PRId64) && defined(_MSC_VER)
#define PRId64 "I64d"
#define PRIu64 "I64u"
#elif !defined(PRId64)
#define PRId64 "lld"
#define PRIu64 "llu"
#endif

// Helpers macros
// We normally try to not use many helpers in BBZGui_demo.cpp in order to make code easier to copy and paste,
// but making an exception here as those are largely simplifying code...
// In other imgui sources we can use nicer internal functions from BBZGui_internal.h (ImMin/ImMax) but not in the demo.
#define IM_MIN(A, B)            (((A) < (B)) ? (A) : (B))
#define IM_MAX(A, B)            (((A) >= (B)) ? (A) : (B))
#define IM_CLAMP(V, MN, MX)     ((V) < (MN) ? (MN) : (V) > (MX) ? (MX) : (V))

// Enforce cdecl calling convention for functions called by the standard library,
// in case compilation settings changed the default to e.g. __vectorcall
#ifndef IMGUI_CDECL
#ifdef _MSC_VER
#define IMGUI_CDECL __cdecl
#else
#define IMGUI_CDECL
#endif
#endif

//-----------------------------------------------------------------------------
// [SECTION] Forward Declarations
//-----------------------------------------------------------------------------

#if !defined(IMGUI_DISABLE_DEMO_WINDOWS)

// Forward Declarations
struct BBZGUIDemoWindowData;
static void ShowExampleAppMainMenuBar();
static void ShowExampleAppAssetsBrowser(bool* p_open);
static void ShowExampleAppConsole(bool* p_open);
static void ShowExampleAppCustomRendering(bool* p_open);
static void ShowExampleAppDocuments(bool* p_open);
static void ShowExampleAppLog(bool* p_open);
static void ShowExampleAppLayout(bool* p_open);
static void ShowExampleAppPropertyEditor(bool* p_open, BBZGUIDemoWindowData* demo_data);
static void ShowExampleAppSimpleOverlay(bool* p_open);
static void ShowExampleAppAutoResize(bool* p_open);
static void ShowExampleAppConstrainedResize(bool* p_open);
static void ShowExampleAppFullscreen(bool* p_open);
static void ShowExampleAppLongText(bool* p_open);
static void ShowExampleAppWindowTitles(bool* p_open);
static void ShowExampleMenuFile();

// We split the contents of the big ShowDemoWindow() function into smaller functions
// (because the link time of very large functions tends to grow non-linearly)
static void ShowDemoWindowMenuBar(BBZGUIDemoWindowData* demo_data);
static void ShowDemoWindowWidgets(BBZGUIDemoWindowData* demo_data);
static void ShowDemoWindowMultiSelect(BBZGUIDemoWindowData* demo_data);
static void ShowDemoWindowLayout();
static void ShowDemoWindowPopups();
static void ShowDemoWindowTables();
static void ShowDemoWindowColumns();
static void ShowDemoWindowInputs();

//-----------------------------------------------------------------------------
// [SECTION] Helpers
//-----------------------------------------------------------------------------

// Helper to display a little (?) mark which shows a tooltip when hovered.
// In your own code you may want to display an actual icon if you are using a merged icon fonts (see docs/FONTS.md)
static void HelpMarker(const char* desc)
{
    BBZGUI::TextDisabled("(?)");
    if (BBZGUI::BeginItemTooltip())
    {
        BBZGUI::PushTextWrapPos(BBZGUI::GetFontSize() * 35.0f);
        BBZGUI::TextUnformatted(desc);
        BBZGUI::PopTextWrapPos();
        BBZGUI::EndTooltip();
    }
}

// Helper to wire demo markers located in code to an interactive browser
typedef void (*BBZGUIDemoMarkerCallback)(const char* file, int line, const char* section, void* user_data);
extern BBZGUIDemoMarkerCallback      GBBZGUIDemoMarkerCallback;
extern void*                        GBBZGUIDemoMarkerCallbackUserData;
BBZGUIDemoMarkerCallback             GBBZGUIDemoMarkerCallback = NULL;
void*                               GBBZGUIDemoMarkerCallbackUserData = NULL;
#define IMGUI_DEMO_MARKER(section)  do { if (GBBZGUIDemoMarkerCallback != NULL) GBBZGUIDemoMarkerCallback(__FILE__, __LINE__, section, GBBZGUIDemoMarkerCallbackUserData); } while (0)

//-----------------------------------------------------------------------------
// [SECTION] Helpers: ExampleTreeNode, ExampleMemberInfo (for use by Property Editor etc.)
//-----------------------------------------------------------------------------

// Simple representation for a tree
// (this is designed to be simple to understand for our demos, not to be fancy or efficient etc.)
struct ExampleTreeNode
{
    // Tree structure
    char                        Name[28] = "";
    int                         UID = 0;
    ExampleTreeNode*            Parent = NULL;
    ImVector<ExampleTreeNode*>  Childs;
    unsigned short              IndexInParent = 0;  // Maintaining this allows us to implement linear traversal more easily

    // Leaf Data
    bool                        HasData = false;    // All leaves have data
    bool                        DataMyBool = true;
    int                         DataMyInt = 128;
    ImVec2                      DataMyVec2 = ImVec2(0.0f, 3.141592f);
};

// Simple representation of struct metadata/serialization data.
// (this is a minimal version of what a typical advanced application may provide)
struct ExampleMemberInfo
{
    const char*     Name;       // Member name
    BBZGUIDataType   DataType;   // Member type
    int             DataCount;  // Member count (1 when scalar)
    int             Offset;     // Offset inside parent structure
};

// Metadata description of ExampleTreeNode struct.
static const ExampleMemberInfo ExampleTreeNodeMemberInfos[]
{
    { "MyBool",     BBZGUIDataType_Bool,    1, offsetof(ExampleTreeNode, DataMyBool) },
    { "MyInt",      BBZGUIDataType_S32,     1, offsetof(ExampleTreeNode, DataMyInt) },
    { "MyVec2",     BBZGUIDataType_Float,   2, offsetof(ExampleTreeNode, DataMyVec2) },
};

static ExampleTreeNode* ExampleTree_CreateNode(const char* name, int uid, ExampleTreeNode* parent)
{
    ExampleTreeNode* node = IM_NEW(ExampleTreeNode);
    snprintf(node->Name, IM_ARRAYSIZE(node->Name), "%s", name);
    node->UID = uid;
    node->Parent = parent;
    node->IndexInParent = parent ? (unsigned short)parent->Childs.Size : 0;
    if (parent)
        parent->Childs.push_back(node);
    return node;
}

// Create example tree data
// (this allocates _many_ more times than most other code in either Dear BBZGUI or others demo)
static ExampleTreeNode* ExampleTree_CreateDemoTree()
{
    static const char* root_names[] = { "Apple", "Banana", "Cherry", "Kiwi", "Mango", "Orange", "Pear", "Pineapple", "Strawberry", "Watermelon" };
    const size_t NAME_MAX_LEN = sizeof(ExampleTreeNode::Name);
    char name_buf[NAME_MAX_LEN];
    int uid = 0;
    ExampleTreeNode* node_L0 = ExampleTree_CreateNode("<ROOT>", ++uid, NULL);
    const int root_items_multiplier = 2;
    for (int idx_L0 = 0; idx_L0 < IM_ARRAYSIZE(root_names) * root_items_multiplier; idx_L0++)
    {
        snprintf(name_buf, IM_ARRAYSIZE(name_buf), "%s %d", root_names[idx_L0 / root_items_multiplier], idx_L0 % root_items_multiplier);
        ExampleTreeNode* node_L1 = ExampleTree_CreateNode(name_buf, ++uid, node_L0);
        const int number_of_childs = (int)strlen(node_L1->Name);
        for (int idx_L1 = 0; idx_L1 < number_of_childs; idx_L1++)
        {
            snprintf(name_buf, IM_ARRAYSIZE(name_buf), "Child %d", idx_L1);
            ExampleTreeNode* node_L2 = ExampleTree_CreateNode(name_buf, ++uid, node_L1);
            node_L2->HasData = true;
            if (idx_L1 == 0)
            {
                snprintf(name_buf, IM_ARRAYSIZE(name_buf), "Sub-child %d", 0);
                ExampleTreeNode* node_L3 = ExampleTree_CreateNode(name_buf, ++uid, node_L2);
                node_L3->HasData = true;
            }
        }
    }
    return node_L0;
}

//-----------------------------------------------------------------------------
// [SECTION] Demo Window / ShowDemoWindow()
//-----------------------------------------------------------------------------

// Data to be shared accross different functions of the demo.
struct BBZGUIDemoWindowData
{
    // Examples Apps (accessible from the "Examples" menu)
    bool ShowMainMenuBar = false;
    bool ShowAppAssetsBrowser = false;
    bool ShowAppConsole = false;
    bool ShowAppCustomRendering = false;
    bool ShowAppDocuments = false;
    bool ShowAppLog = false;
    bool ShowAppLayout = false;
    bool ShowAppPropertyEditor = false;
    bool ShowAppSimpleOverlay = false;
    bool ShowAppAutoResize = false;
    bool ShowAppConstrainedResize = false;
    bool ShowAppFullscreen = false;
    bool ShowAppLongText = false;
    bool ShowAppWindowTitles = false;

    // Dear BBZGUI Tools (accessible from the "Tools" menu)
    bool ShowMetrics = false;
    bool ShowDebugLog = false;
    bool ShowIDStackTool = false;
    bool ShowStyleEditor = false;
    bool ShowAbout = false;

    // Other data
    ExampleTreeNode* DemoTree = NULL;
};

// Demonstrate most Dear BBZGUI features (this is big function!)
// You may execute this function to experiment with the UI and understand what it does.
// You may then search for keywords in the code when you are interested by a specific feature.
void BBZGUI::ShowDemoWindow(bool* p_open)
{
    // Exceptionally add an extra assert here for people confused about initial Dear BBZGUI setup
    // Most functions would normally just assert/crash if the context is missing.
    IM_ASSERT(BBZGUI::GetCurrentContext() != NULL && "Missing Dear BBZGUI context. Refer to examples app!");

    // Verify ABI compatibility between caller code and compiled version of Dear BBZGUI. This helps detects some build issues.
    IMGUI_CHECKVERSION();

    // Stored data
    static BBZGUIDemoWindowData demo_data;

    // Examples Apps (accessible from the "Examples" menu)
    if (demo_data.ShowMainMenuBar)          { ShowExampleAppMainMenuBar(); }
    if (demo_data.ShowAppDocuments)         { ShowExampleAppDocuments(&demo_data.ShowAppDocuments); }
    if (demo_data.ShowAppAssetsBrowser)     { ShowExampleAppAssetsBrowser(&demo_data.ShowAppAssetsBrowser); }
    if (demo_data.ShowAppConsole)           { ShowExampleAppConsole(&demo_data.ShowAppConsole); }
    if (demo_data.ShowAppCustomRendering)   { ShowExampleAppCustomRendering(&demo_data.ShowAppCustomRendering); }
    if (demo_data.ShowAppLog)               { ShowExampleAppLog(&demo_data.ShowAppLog); }
    if (demo_data.ShowAppLayout)            { ShowExampleAppLayout(&demo_data.ShowAppLayout); }
    if (demo_data.ShowAppPropertyEditor)    { ShowExampleAppPropertyEditor(&demo_data.ShowAppPropertyEditor, &demo_data); }
    if (demo_data.ShowAppSimpleOverlay)     { ShowExampleAppSimpleOverlay(&demo_data.ShowAppSimpleOverlay); }
    if (demo_data.ShowAppAutoResize)        { ShowExampleAppAutoResize(&demo_data.ShowAppAutoResize); }
    if (demo_data.ShowAppConstrainedResize) { ShowExampleAppConstrainedResize(&demo_data.ShowAppConstrainedResize); }
    if (demo_data.ShowAppFullscreen)        { ShowExampleAppFullscreen(&demo_data.ShowAppFullscreen); }
    if (demo_data.ShowAppLongText)          { ShowExampleAppLongText(&demo_data.ShowAppLongText); }
    if (demo_data.ShowAppWindowTitles)      { ShowExampleAppWindowTitles(&demo_data.ShowAppWindowTitles); }

    // Dear BBZGUI Tools (accessible from the "Tools" menu)
    if (demo_data.ShowMetrics)              { BBZGUI::ShowMetricsWindow(&demo_data.ShowMetrics); }
    if (demo_data.ShowDebugLog)             { BBZGUI::ShowDebugLogWindow(&demo_data.ShowDebugLog); }
    if (demo_data.ShowIDStackTool)          { BBZGUI::ShowIDStackToolWindow(&demo_data.ShowIDStackTool); }
    if (demo_data.ShowAbout)                { BBZGUI::ShowAboutWindow(&demo_data.ShowAbout); }
    if (demo_data.ShowStyleEditor)
    {
        BBZGUI::Begin("Dear BBZGUI Style Editor", &demo_data.ShowStyleEditor);
        BBZGUI::ShowStyleEditor();
        BBZGUI::End();
    }

    // Demonstrate the various window flags. Typically you would just use the default!
    static bool no_titlebar = false;
    static bool no_scrollbar = false;
    static bool no_menu = false;
    static bool no_move = false;
    static bool no_resize = false;
    static bool no_collapse = false;
    static bool no_close = false;
    static bool no_nav = false;
    static bool no_background = false;
    static bool no_bring_to_front = false;
    static bool unsaved_document = false;

    BBZGUIWindowFlags window_flags = 0;
    if (no_titlebar)        window_flags |= BBZGUIWindowFlags_NoTitleBar;
    if (no_scrollbar)       window_flags |= BBZGUIWindowFlags_NoScrollbar;
    if (!no_menu)           window_flags |= BBZGUIWindowFlags_MenuBar;
    if (no_move)            window_flags |= BBZGUIWindowFlags_NoMove;
    if (no_resize)          window_flags |= BBZGUIWindowFlags_NoResize;
    if (no_collapse)        window_flags |= BBZGUIWindowFlags_NoCollapse;
    if (no_nav)             window_flags |= BBZGUIWindowFlags_NoNav;
    if (no_background)      window_flags |= BBZGUIWindowFlags_NoBackground;
    if (no_bring_to_front)  window_flags |= BBZGUIWindowFlags_NoBringToFrontOnFocus;
    if (unsaved_document)   window_flags |= BBZGUIWindowFlags_UnsavedDocument;
    if (no_close)           p_open = NULL; // Don't pass our bool* to Begin

    // We specify a default position/size in case there's no data in the .ini file.
    // We only do it to make the demo applications a little more welcoming, but typically this isn't required.
    const BBZGUIViewport* main_viewport = BBZGUI::GetMainViewport();
    BBZGUI::SetNextWindowPos(ImVec2(main_viewport->WorkPos.x + 650, main_viewport->WorkPos.y + 20), BBZGUICond_FirstUseEver);
    BBZGUI::SetNextWindowSize(ImVec2(550, 680), BBZGUICond_FirstUseEver);

    // Main body of the Demo window starts here.
    if (!BBZGUI::Begin("Dear BBZGUI Demo", p_open, window_flags))
    {
        // Early out if the window is collapsed, as an optimization.
        BBZGUI::End();
        return;
    }

    // Most "big" widgets share a common width settings by default. See 'Demo->Layout->Widgets Width' for details.
    BBZGUI::PushItemWidth(BBZGUI::GetFontSize() * -12);           // e.g. Leave a fixed amount of width for labels (by passing a negative value), the rest goes to widgets.
    //BBZGUI::PushItemWidth(-BBZGUI::GetWindowWidth() * 0.35f);   // e.g. Use 2/3 of the space for widgets and 1/3 for labels (right align)

    // Menu Bar
    ShowDemoWindowMenuBar(&demo_data);

    BBZGUI::Text("dear imgui says hello! (%s) (%d)", IMGUI_VERSION, IMGUI_VERSION_NUM);
    BBZGUI::Spacing();

    IMGUI_DEMO_MARKER("Help");
    if (BBZGUI::CollapsingHeader("Help"))
    {
        BBZGUI::SeparatorText("ABOUT THIS DEMO:");
        BBZGUI::BulletText("Sections below are demonstrating many aspects of the library.");
        BBZGUI::BulletText("The \"Examples\" menu above leads to more demo contents.");
        BBZGUI::BulletText("The \"Tools\" menu above gives access to: About Box, Style Editor,\n"
                          "and Metrics/Debugger (general purpose Dear BBZGUI debugging tool).");

        BBZGUI::SeparatorText("PROGRAMMER GUIDE:");
        BBZGUI::BulletText("See the ShowDemoWindow() code in BBZGui_demo.cpp. <- you are here!");
        BBZGUI::BulletText("See comments in BBZGui.cpp.");
        BBZGUI::BulletText("See example applications in the examples/ folder.");
        BBZGUI::BulletText("Read the FAQ at ");
        BBZGUI::SameLine(0, 0);
        BBZGUI::TextLinkOpenURL("https://www.dearimgui.com/faq/");
        BBZGUI::BulletText("Set 'io.ConfigFlags |= NavEnableKeyboard' for keyboard controls.");
        BBZGUI::BulletText("Set 'io.ConfigFlags |= NavEnableGamepad' for gamepad controls.");

        BBZGUI::SeparatorText("USER GUIDE:");
        BBZGUI::ShowUserGuide();
    }

    IMGUI_DEMO_MARKER("Configuration");
    if (BBZGUI::CollapsingHeader("Configuration"))
    {
        BBZGUIIO& io = BBZGUI::GetIO();

        if (BBZGUI::TreeNode("Configuration##2"))
        {
            BBZGUI::SeparatorText("General");
            BBZGUI::CheckboxFlags("io.ConfigFlags: NavEnableKeyboard",    &io.ConfigFlags, BBZGUIConfigFlags_NavEnableKeyboard);
            BBZGUI::SameLine(); HelpMarker("Enable keyboard controls.");
            BBZGUI::CheckboxFlags("io.ConfigFlags: NavEnableGamepad",     &io.ConfigFlags, BBZGUIConfigFlags_NavEnableGamepad);
            BBZGUI::SameLine(); HelpMarker("Enable gamepad controls. Require backend to set io.BackendFlags |= BBZGUIBackendFlags_HasGamepad.\n\nRead instructions in BBZGui.cpp for details.");
            BBZGUI::CheckboxFlags("io.ConfigFlags: NoMouse",              &io.ConfigFlags, BBZGUIConfigFlags_NoMouse);
            BBZGUI::SameLine(); HelpMarker("Instruct dear imgui to disable mouse inputs and interactions.");

            // The "NoMouse" option can get us stuck with a disabled mouse! Let's provide an alternative way to fix it:
            if (io.ConfigFlags & BBZGUIConfigFlags_NoMouse)
            {
                if (fmodf((float)BBZGUI::GetTime(), 0.40f) < 0.20f)
                {
                    BBZGUI::SameLine();
                    BBZGUI::Text("<<PRESS SPACE TO DISABLE>>");
                }
                // Prevent both being checked
                if (BBZGUI::IsKeyPressed(BBZGUIKey_Space) || (io.ConfigFlags & BBZGUIConfigFlags_NoKeyboard))
                    io.ConfigFlags &= ~BBZGUIConfigFlags_NoMouse;
            }

            BBZGUI::CheckboxFlags("io.ConfigFlags: NoMouseCursorChange",  &io.ConfigFlags, BBZGUIConfigFlags_NoMouseCursorChange);
            BBZGUI::SameLine(); HelpMarker("Instruct backend to not alter mouse cursor shape and visibility.");
            BBZGUI::CheckboxFlags("io.ConfigFlags: NoKeyboard", &io.ConfigFlags, BBZGUIConfigFlags_NoKeyboard);
            BBZGUI::SameLine(); HelpMarker("Instruct dear imgui to disable keyboard inputs and interactions.");

            BBZGUI::Checkbox("io.ConfigInputTrickleEventQueue", &io.ConfigInputTrickleEventQueue);
            BBZGUI::SameLine(); HelpMarker("Enable input queue trickling: some types of events submitted during the same frame (e.g. button down + up) will be spread over multiple frames, improving interactions with low framerates.");
            BBZGUI::Checkbox("io.MouseDrawCursor", &io.MouseDrawCursor);
            BBZGUI::SameLine(); HelpMarker("Instruct Dear BBZGUI to render a mouse cursor itself. Note that a mouse cursor rendered via your application GPU rendering path will feel more laggy than hardware cursor, but will be more in sync with your other visuals.\n\nSome desktop applications may use both kinds of cursors (e.g. enable software cursor only when resizing/dragging something).");

            BBZGUI::SeparatorText("Keyboard/Gamepad Navigation");
            BBZGUI::Checkbox("io.ConfigNavSwapGamepadButtons", &io.ConfigNavSwapGamepadButtons);
            BBZGUI::Checkbox("io.ConfigNavMoveSetMousePos", &io.ConfigNavMoveSetMousePos);
            BBZGUI::SameLine(); HelpMarker("Directional/tabbing navigation teleports the mouse cursor. May be useful on TV/console systems where moving a virtual mouse is difficult");
            BBZGUI::Checkbox("io.ConfigNavCaptureKeyboard", &io.ConfigNavCaptureKeyboard);
            BBZGUI::Checkbox("io.ConfigNavEscapeClearFocusItem", &io.ConfigNavEscapeClearFocusItem);
            BBZGUI::SameLine(); HelpMarker("Pressing Escape clears focused item.");
            BBZGUI::Checkbox("io.ConfigNavEscapeClearFocusWindow", &io.ConfigNavEscapeClearFocusWindow);
            BBZGUI::SameLine(); HelpMarker("Pressing Escape clears focused window.");
            BBZGUI::Checkbox("io.ConfigNavCursorVisibleAuto", &io.ConfigNavCursorVisibleAuto);
            BBZGUI::SameLine(); HelpMarker("Using directional navigation key makes the cursor visible. Mouse click hides the cursor.");
            BBZGUI::Checkbox("io.ConfigNavCursorVisibleAlways", &io.ConfigNavCursorVisibleAlways);
            BBZGUI::SameLine(); HelpMarker("Navigation cursor is always visible.");

            BBZGUI::SeparatorText("Windows");
            BBZGUI::Checkbox("io.ConfigWindowsResizeFromEdges", &io.ConfigWindowsResizeFromEdges);
            BBZGUI::SameLine(); HelpMarker("Enable resizing of windows from their edges and from the lower-left corner.\nThis requires BBZGUIBackendFlags_HasMouseCursors for better mouse cursor feedback.");
            BBZGUI::Checkbox("io.ConfigWindowsMoveFromTitleBarOnly", &io.ConfigWindowsMoveFromTitleBarOnly);
            BBZGUI::Checkbox("io.ConfigWindowsCopyContentsWithCtrlC", &io.ConfigWindowsCopyContentsWithCtrlC); // [EXPERIMENTAL]
            BBZGUI::SameLine(); HelpMarker("*EXPERIMENTAL* CTRL+C copy the contents of focused window into the clipboard.\n\nExperimental because:\n- (1) has known issues with nested Begin/End pairs.\n- (2) text output quality varies.\n- (3) text output is in submission order rather than spatial order.");
            BBZGUI::Checkbox("io.ConfigScrollbarScrollByPage", &io.ConfigScrollbarScrollByPage);
            BBZGUI::SameLine(); HelpMarker("Enable scrolling page by page when clicking outside the scrollbar grab.\nWhen disabled, always scroll to clicked location.\nWhen enabled, Shift+Click scrolls to clicked location.");

            BBZGUI::SeparatorText("Widgets");
            BBZGUI::Checkbox("io.ConfigInputTextCursorBlink", &io.ConfigInputTextCursorBlink);
            BBZGUI::SameLine(); HelpMarker("Enable blinking cursor (optional as some users consider it to be distracting).");
            BBZGUI::Checkbox("io.ConfigInputTextEnterKeepActive", &io.ConfigInputTextEnterKeepActive);
            BBZGUI::SameLine(); HelpMarker("Pressing Enter will keep item active and select contents (single-line only).");
            BBZGUI::Checkbox("io.ConfigDragClickToInputText", &io.ConfigDragClickToInputText);
            BBZGUI::SameLine(); HelpMarker("Enable turning DragXXX widgets into text input with a simple mouse click-release (without moving).");
            BBZGUI::Checkbox("io.ConfigMacOSXBehaviors", &io.ConfigMacOSXBehaviors);
            BBZGUI::SameLine(); HelpMarker("Swap Cmd<>Ctrl keys, enable various MacOS style behaviors.");
            BBZGUI::Text("Also see Style->Rendering for rendering options.");

            // Also read: https://github.com/ocornut/imgui/wiki/Error-Handling
            BBZGUI::SeparatorText("Error Handling");

            BBZGUI::Checkbox("io.ConfigErrorRecovery", &io.ConfigErrorRecovery);
            BBZGUI::SameLine(); HelpMarker(
                "Options to configure how we handle recoverable errors.\n"
                "- Error recovery is not perfect nor guaranteed! It is a feature to ease development.\n"
                "- You not are not supposed to rely on it in the course of a normal application run.\n"
                "- Possible usage: facilitate recovery from errors triggered from a scripting language or after specific exceptions handlers.\n"
                "- Always ensure that on programmers seat you have at minimum Asserts or Tooltips enabled when making direct imgui API call!"
                "Otherwise it would severely hinder your ability to catch and correct mistakes!");
            BBZGUI::Checkbox("io.ConfigErrorRecoveryEnableAssert", &io.ConfigErrorRecoveryEnableAssert);
            BBZGUI::Checkbox("io.ConfigErrorRecoveryEnableDebugLog", &io.ConfigErrorRecoveryEnableDebugLog);
            BBZGUI::Checkbox("io.ConfigErrorRecoveryEnableTooltip", &io.ConfigErrorRecoveryEnableTooltip);
            if (!io.ConfigErrorRecoveryEnableAssert && !io.ConfigErrorRecoveryEnableDebugLog && !io.ConfigErrorRecoveryEnableTooltip)
                io.ConfigErrorRecoveryEnableAssert = io.ConfigErrorRecoveryEnableDebugLog = io.ConfigErrorRecoveryEnableTooltip = true;

            // Also read: https://github.com/ocornut/imgui/wiki/Debug-Tools
            BBZGUI::SeparatorText("Debug");
            BBZGUI::Checkbox("io.ConfigDebugIsDebuggerPresent", &io.ConfigDebugIsDebuggerPresent);
            BBZGUI::SameLine(); HelpMarker("Enable various tools calling IM_DEBUG_BREAK().\n\nRequires a debugger being attached, otherwise IM_DEBUG_BREAK() options will appear to crash your application.");
            BBZGUI::Checkbox("io.ConfigDebugHighlightIdConflicts", &io.ConfigDebugHighlightIdConflicts);
            BBZGUI::SameLine(); HelpMarker("Highlight and show an error message when multiple items have conflicting identifiers.");
            BBZGUI::BeginDisabled();
            BBZGUI::Checkbox("io.ConfigDebugBeginReturnValueOnce", &io.ConfigDebugBeginReturnValueOnce);
            BBZGUI::EndDisabled();
            BBZGUI::SameLine(); HelpMarker("First calls to Begin()/BeginChild() will return false.\n\nTHIS OPTION IS DISABLED because it needs to be set at application boot-time to make sense. Showing the disabled option is a way to make this feature easier to discover.");
            BBZGUI::Checkbox("io.ConfigDebugBeginReturnValueLoop", &io.ConfigDebugBeginReturnValueLoop);
            BBZGUI::SameLine(); HelpMarker("Some calls to Begin()/BeginChild() will return false.\n\nWill cycle through window depths then repeat. Windows should be flickering while running.");
            BBZGUI::Checkbox("io.ConfigDebugIgnoreFocusLoss", &io.ConfigDebugIgnoreFocusLoss);
            BBZGUI::SameLine(); HelpMarker("Option to deactivate io.AddFocusEvent(false) handling. May facilitate interactions with a debugger when focus loss leads to clearing inputs data.");
            BBZGUI::Checkbox("io.ConfigDebugIniSettings", &io.ConfigDebugIniSettings);
            BBZGUI::SameLine(); HelpMarker("Option to save .ini data with extra comments (particularly helpful for Docking, but makes saving slower).");

            BBZGUI::TreePop();
            BBZGUI::Spacing();
        }

        IMGUI_DEMO_MARKER("Configuration/Backend Flags");
        if (BBZGUI::TreeNode("Backend Flags"))
        {
            HelpMarker(
                "Those flags are set by the backends (imgui_impl_xxx files) to specify their capabilities.\n"
                "Here we expose them as read-only fields to avoid breaking interactions with your backend.");

            // FIXME: Maybe we need a BeginReadonly() equivalent to keep label bright?
            BBZGUI::BeginDisabled();
            BBZGUI::CheckboxFlags("io.BackendFlags: HasGamepad",           &io.BackendFlags, BBZGUIBackendFlags_HasGamepad);
            BBZGUI::CheckboxFlags("io.BackendFlags: HasMouseCursors",      &io.BackendFlags, BBZGUIBackendFlags_HasMouseCursors);
            BBZGUI::CheckboxFlags("io.BackendFlags: HasSetMousePos",       &io.BackendFlags, BBZGUIBackendFlags_HasSetMousePos);
            BBZGUI::CheckboxFlags("io.BackendFlags: RendererHasVtxOffset", &io.BackendFlags, BBZGUIBackendFlags_RendererHasVtxOffset);
            BBZGUI::EndDisabled();

            BBZGUI::TreePop();
            BBZGUI::Spacing();
        }

        IMGUI_DEMO_MARKER("Configuration/Style");
        if (BBZGUI::TreeNode("Style"))
        {
            BBZGUI::Checkbox("Style Editor", &demo_data.ShowStyleEditor);
            BBZGUI::SameLine();
            HelpMarker("The same contents can be accessed in 'Tools->Style Editor' or by calling the ShowStyleEditor() function.");
            BBZGUI::TreePop();
            BBZGUI::Spacing();
        }

        IMGUI_DEMO_MARKER("Configuration/Capture, Logging");
        if (BBZGUI::TreeNode("Capture/Logging"))
        {
            HelpMarker(
                "The logging API redirects all text output so you can easily capture the content of "
                "a window or a block. Tree nodes can be automatically expanded.\n"
                "Try opening any of the contents below in this window and then click one of the \"Log To\" button.");
            BBZGUI::LogButtons();

            HelpMarker("You can also call BBZGUI::LogText() to output directly to the log without a visual output.");
            if (BBZGUI::Button("Copy \"Hello, world!\" to clipboard"))
            {
                BBZGUI::LogToClipboard();
                BBZGUI::LogText("Hello, world!");
                BBZGUI::LogFinish();
            }
            BBZGUI::TreePop();
        }
    }

    IMGUI_DEMO_MARKER("Window options");
    if (BBZGUI::CollapsingHeader("Window options"))
    {
        if (BBZGUI::BeginTable("split", 3))
        {
            BBZGUI::TableNextColumn(); BBZGUI::Checkbox("No titlebar", &no_titlebar);
            BBZGUI::TableNextColumn(); BBZGUI::Checkbox("No scrollbar", &no_scrollbar);
            BBZGUI::TableNextColumn(); BBZGUI::Checkbox("No menu", &no_menu);
            BBZGUI::TableNextColumn(); BBZGUI::Checkbox("No move", &no_move);
            BBZGUI::TableNextColumn(); BBZGUI::Checkbox("No resize", &no_resize);
            BBZGUI::TableNextColumn(); BBZGUI::Checkbox("No collapse", &no_collapse);
            BBZGUI::TableNextColumn(); BBZGUI::Checkbox("No close", &no_close);
            BBZGUI::TableNextColumn(); BBZGUI::Checkbox("No nav", &no_nav);
            BBZGUI::TableNextColumn(); BBZGUI::Checkbox("No background", &no_background);
            BBZGUI::TableNextColumn(); BBZGUI::Checkbox("No bring to front", &no_bring_to_front);
            BBZGUI::TableNextColumn(); BBZGUI::Checkbox("Unsaved document", &unsaved_document);
            BBZGUI::EndTable();
        }
    }

    // All demo contents
    ShowDemoWindowWidgets(&demo_data);
    ShowDemoWindowLayout();
    ShowDemoWindowPopups();
    ShowDemoWindowTables();
    ShowDemoWindowInputs();

    // End of ShowDemoWindow()
    BBZGUI::PopItemWidth();
    BBZGUI::End();
}

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowMenuBar()
//-----------------------------------------------------------------------------

static void ShowDemoWindowMenuBar(BBZGUIDemoWindowData* demo_data)
{
    IMGUI_DEMO_MARKER("Menu");
    if (BBZGUI::BeginMenuBar())
    {
        if (BBZGUI::BeginMenu("Menu"))
        {
            IMGUI_DEMO_MARKER("Menu/File");
            ShowExampleMenuFile();
            BBZGUI::EndMenu();
        }
        if (BBZGUI::BeginMenu("Examples"))
        {
            IMGUI_DEMO_MARKER("Menu/Examples");
            BBZGUI::MenuItem("Main menu bar", NULL, &demo_data->ShowMainMenuBar);

            BBZGUI::SeparatorText("Mini apps");
            BBZGUI::MenuItem("Assets Browser", NULL, &demo_data->ShowAppAssetsBrowser);
            BBZGUI::MenuItem("Console", NULL, &demo_data->ShowAppConsole);
            BBZGUI::MenuItem("Custom rendering", NULL, &demo_data->ShowAppCustomRendering);
            BBZGUI::MenuItem("Documents", NULL, &demo_data->ShowAppDocuments);
            BBZGUI::MenuItem("Log", NULL, &demo_data->ShowAppLog);
            BBZGUI::MenuItem("Property editor", NULL, &demo_data->ShowAppPropertyEditor);
            BBZGUI::MenuItem("Simple layout", NULL, &demo_data->ShowAppLayout);
            BBZGUI::MenuItem("Simple overlay", NULL, &demo_data->ShowAppSimpleOverlay);

            BBZGUI::SeparatorText("Concepts");
            BBZGUI::MenuItem("Auto-resizing window", NULL, &demo_data->ShowAppAutoResize);
            BBZGUI::MenuItem("Constrained-resizing window", NULL, &demo_data->ShowAppConstrainedResize);
            BBZGUI::MenuItem("Fullscreen window", NULL, &demo_data->ShowAppFullscreen);
            BBZGUI::MenuItem("Long text display", NULL, &demo_data->ShowAppLongText);
            BBZGUI::MenuItem("Manipulating window titles", NULL, &demo_data->ShowAppWindowTitles);

            BBZGUI::EndMenu();
        }
        //if (BBZGUI::MenuItem("MenuItem")) {} // You can also use MenuItem() inside a menu bar!
        if (BBZGUI::BeginMenu("Tools"))
        {
            IMGUI_DEMO_MARKER("Menu/Tools");
            BBZGUIIO& io = BBZGUI::GetIO();
#ifndef IMGUI_DISABLE_DEBUG_TOOLS
            const bool has_debug_tools = true;
#else
            const bool has_debug_tools = false;
#endif
            BBZGUI::MenuItem("Metrics/Debugger", NULL, &demo_data->ShowMetrics, has_debug_tools);
            BBZGUI::MenuItem("Debug Log", NULL, &demo_data->ShowDebugLog, has_debug_tools);
            BBZGUI::MenuItem("ID Stack Tool", NULL, &demo_data->ShowIDStackTool, has_debug_tools);
            bool is_debugger_present = io.ConfigDebugIsDebuggerPresent;
            if (BBZGUI::MenuItem("Item Picker", NULL, false, has_debug_tools && is_debugger_present))
                BBZGUI::DebugStartItemPicker();
            if (!is_debugger_present)
                BBZGUI::SetItemTooltip("Requires io.ConfigDebugIsDebuggerPresent=true to be set.\n\nWe otherwise disable the menu option to avoid casual users crashing the application.\n\nYou can however always access the Item Picker in Metrics->Tools.");
            BBZGUI::MenuItem("Style Editor", NULL, &demo_data->ShowStyleEditor);
            BBZGUI::MenuItem("About Dear BBZGUI", NULL, &demo_data->ShowAbout);

            BBZGUI::SeparatorText("Debug Options");
            BBZGUI::MenuItem("Highlight ID Conflicts", NULL, &io.ConfigDebugHighlightIdConflicts, has_debug_tools);
            BBZGUI::EndMenu();
        }
        BBZGUI::EndMenuBar();
    }
}

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowWidgets()
//-----------------------------------------------------------------------------

static void ShowDemoWindowWidgets(BBZGUIDemoWindowData* demo_data)
{
    IMGUI_DEMO_MARKER("Widgets");
    //BBZGUI::SetNextItemOpen(true, BBZGUICond_Once);
    if (!BBZGUI::CollapsingHeader("Widgets"))
        return;

    static bool disable_all = false; // The Checkbox for that is inside the "Disabled" section at the bottom
    if (disable_all)
        BBZGUI::BeginDisabled();

    IMGUI_DEMO_MARKER("Widgets/Basic");
    if (BBZGUI::TreeNode("Basic"))
    {
        BBZGUI::SeparatorText("General");

        IMGUI_DEMO_MARKER("Widgets/Basic/Button");
        static int clicked = 0;
        if (BBZGUI::Button("Button"))
            clicked++;
        if (clicked & 1)
        {
            BBZGUI::SameLine();
            BBZGUI::Text("Thanks for clicking me!");
        }

        IMGUI_DEMO_MARKER("Widgets/Basic/Checkbox");
        static bool check = true;
        BBZGUI::Checkbox("checkbox", &check);

        IMGUI_DEMO_MARKER("Widgets/Basic/RadioButton");
        static int e = 0;
        BBZGUI::RadioButton("radio a", &e, 0); BBZGUI::SameLine();
        BBZGUI::RadioButton("radio b", &e, 1); BBZGUI::SameLine();
        BBZGUI::RadioButton("radio c", &e, 2);

        // Color buttons, demonstrate using PushID() to add unique identifier in the ID stack, and changing style.
        IMGUI_DEMO_MARKER("Widgets/Basic/Buttons (Colored)");
        for (int i = 0; i < 7; i++)
        {
            if (i > 0)
                BBZGUI::SameLine();
            BBZGUI::PushID(i);
            BBZGUI::PushStyleColor(BBZGUICol_Button, (ImVec4)ImColor::HSV(i / 7.0f, 0.6f, 0.6f));
            BBZGUI::PushStyleColor(BBZGUICol_ButtonHovered, (ImVec4)ImColor::HSV(i / 7.0f, 0.7f, 0.7f));
            BBZGUI::PushStyleColor(BBZGUICol_ButtonActive, (ImVec4)ImColor::HSV(i / 7.0f, 0.8f, 0.8f));
            BBZGUI::Button("Click");
            BBZGUI::PopStyleColor(3);
            BBZGUI::PopID();
        }

        // Use AlignTextToFramePadding() to align text baseline to the baseline of framed widgets elements
        // (otherwise a Text+SameLine+Button sequence will have the text a little too high by default!)
        // See 'Demo->Layout->Text Baseline Alignment' for details.
        BBZGUI::AlignTextToFramePadding();
        BBZGUI::Text("Hold to repeat:");
        BBZGUI::SameLine();

        // Arrow buttons with Repeater
        IMGUI_DEMO_MARKER("Widgets/Basic/Buttons (Repeating)");
        static int counter = 0;
        float spacing = BBZGUI::GetStyle().ItemInnerSpacing.x;
        BBZGUI::PushItemFlag(BBZGUIItemFlags_ButtonRepeat, true);
        if (BBZGUI::ArrowButton("##left", BBZGUIDir_Left)) { counter--; }
        BBZGUI::SameLine(0.0f, spacing);
        if (BBZGUI::ArrowButton("##right", BBZGUIDir_Right)) { counter++; }
        BBZGUI::PopItemFlag();
        BBZGUI::SameLine();
        BBZGUI::Text("%d", counter);

        BBZGUI::Button("Tooltip");
        BBZGUI::SetItemTooltip("I am a tooltip");

        BBZGUI::LabelText("label", "Value");

        BBZGUI::SeparatorText("Inputs");

        {
            // To wire InputText() with std::string or any other custom string type,
            // see the "Text Input > Resize Callback" section of this demo, and the misc/cpp/imgui_stdlib.h file.
            IMGUI_DEMO_MARKER("Widgets/Basic/InputText");
            static char str0[128] = "Hello, world!";
            BBZGUI::InputText("input text", str0, IM_ARRAYSIZE(str0));
            BBZGUI::SameLine(); HelpMarker(
                "USER:\n"
                "Hold SHIFT or use mouse to select text.\n"
                "CTRL+Left/Right to word jump.\n"
                "CTRL+A or Double-Click to select all.\n"
                "CTRL+X,CTRL+C,CTRL+V clipboard.\n"
                "CTRL+Z,CTRL+Y undo/redo.\n"
                "ESCAPE to revert.\n\n"
                "PROGRAMMER:\n"
                "You can use the BBZGUIInputTextFlags_CallbackResize facility if you need to wire InputText() "
                "to a dynamic string type. See misc/cpp/imgui_stdlib.h for an example (this is not demonstrated "
                "in BBZGui_demo.cpp).");

            static char str1[128] = "";
            BBZGUI::InputTextWithHint("input text (w/ hint)", "enter text here", str1, IM_ARRAYSIZE(str1));

            IMGUI_DEMO_MARKER("Widgets/Basic/InputInt, InputFloat");
            static int i0 = 123;
            BBZGUI::InputInt("input int", &i0);

            static float f0 = 0.001f;
            BBZGUI::InputFloat("input float", &f0, 0.01f, 1.0f, "%.3f");

            static double d0 = 999999.00000001;
            BBZGUI::InputDouble("input double", &d0, 0.01f, 1.0f, "%.8f");

            static float f1 = 1.e10f;
            BBZGUI::InputFloat("input scientific", &f1, 0.0f, 0.0f, "%e");
            BBZGUI::SameLine(); HelpMarker(
                "You can input value using the scientific notation,\n"
                "  e.g. \"1e+8\" becomes \"100000000\".");

            static float vec4a[4] = { 0.10f, 0.20f, 0.30f, 0.44f };
            BBZGUI::InputFloat3("input float3", vec4a);
        }

        BBZGUI::SeparatorText("Drags");

        {
            IMGUI_DEMO_MARKER("Widgets/Basic/DragInt, DragFloat");
            static int i1 = 50, i2 = 42, i3 = 128;
            BBZGUI::DragInt("drag int", &i1, 1);
            BBZGUI::SameLine(); HelpMarker(
                "Click and drag to edit value.\n"
                "Hold SHIFT/ALT for faster/slower edit.\n"
                "Double-click or CTRL+click to input value.");
            BBZGUI::DragInt("drag int 0..100", &i2, 1, 0, 100, "%d%%", BBZGUISliderFlags_AlwaysClamp);
            BBZGUI::DragInt("drag int wrap 100..200", &i3, 1, 100, 200, "%d", BBZGUISliderFlags_WrapAround);

            static float f1 = 1.00f, f2 = 0.0067f;
            BBZGUI::DragFloat("drag float", &f1, 0.005f);
            BBZGUI::DragFloat("drag small float", &f2, 0.0001f, 0.0f, 0.0f, "%.06f ns");
            //BBZGUI::DragFloat("drag wrap -1..1", &f3, 0.005f, -1.0f, 1.0f, NULL, BBZGUISliderFlags_WrapAround);
        }

        BBZGUI::SeparatorText("Sliders");

        {
            IMGUI_DEMO_MARKER("Widgets/Basic/SliderInt, SliderFloat");
            static int i1 = 0;
            BBZGUI::SliderInt("slider int", &i1, -1, 3);
            BBZGUI::SameLine(); HelpMarker("CTRL+click to input value.");

            static float f1 = 0.123f, f2 = 0.0f;
            BBZGUI::SliderFloat("slider float", &f1, 0.0f, 1.0f, "ratio = %.3f");
            BBZGUI::SliderFloat("slider float (log)", &f2, -10.0f, 10.0f, "%.4f", BBZGUISliderFlags_Logarithmic);

            IMGUI_DEMO_MARKER("Widgets/Basic/SliderAngle");
            static float angle = 0.0f;
            BBZGUI::SliderAngle("slider angle", &angle);

            // Using the format string to display a name instead of an integer.
            // Here we completely omit '%d' from the format string, so it'll only display a name.
            // This technique can also be used with DragInt().
            IMGUI_DEMO_MARKER("Widgets/Basic/Slider (enum)");
            enum Element { Element_Fire, Element_Earth, Element_Air, Element_Water, Element_COUNT };
            static int elem = Element_Fire;
            const char* elems_names[Element_COUNT] = { "Fire", "Earth", "Air", "Water" };
            const char* elem_name = (elem >= 0 && elem < Element_COUNT) ? elems_names[elem] : "Unknown";
            BBZGUI::SliderInt("slider enum", &elem, 0, Element_COUNT - 1, elem_name); // Use BBZGUISliderFlags_NoInput flag to disable CTRL+Click here.
            BBZGUI::SameLine(); HelpMarker("Using the format string parameter to display a name instead of the underlying integer.");
        }

        BBZGUI::SeparatorText("Selectors/Pickers");

        {
            IMGUI_DEMO_MARKER("Widgets/Basic/ColorEdit3, ColorEdit4");
            static float col1[3] = { 1.0f, 0.0f, 0.2f };
            static float col2[4] = { 0.4f, 0.7f, 0.0f, 0.5f };
            BBZGUI::ColorEdit3("color 1", col1);
            BBZGUI::SameLine(); HelpMarker(
                "Click on the color square to open a color picker.\n"
                "Click and hold to use drag and drop.\n"
                "Right-click on the color square to show options.\n"
                "CTRL+click on individual component to input value.\n");

            BBZGUI::ColorEdit4("color 2", col2);
        }

        {
            // Using the _simplified_ one-liner Combo() api here
            // See "Combo" section for examples of how to use the more flexible BeginCombo()/EndCombo() api.
            IMGUI_DEMO_MARKER("Widgets/Basic/Combo");
            const char* items[] = { "AAAA", "BBBB", "CCCC", "DDDD", "EEEE", "FFFF", "GGGG", "HHHH", "IIIIIII", "JJJJ", "KKKKKKK" };
            static int item_current = 0;
            BBZGUI::Combo("combo", &item_current, items, IM_ARRAYSIZE(items));
            BBZGUI::SameLine(); HelpMarker(
                "Using the simplified one-liner Combo API here.\n"
                "Refer to the \"Combo\" section below for an explanation of how to use the more flexible and general BeginCombo/EndCombo API.");
        }

        {
            // Using the _simplified_ one-liner ListBox() api here
            // See "List boxes" section for examples of how to use the more flexible BeginListBox()/EndListBox() api.
            IMGUI_DEMO_MARKER("Widgets/Basic/ListBox");
            const char* items[] = { "Apple", "Banana", "Cherry", "Kiwi", "Mango", "Orange", "Pineapple", "Strawberry", "Watermelon" };
            static int item_current = 1;
            BBZGUI::ListBox("listbox", &item_current, items, IM_ARRAYSIZE(items), 4);
            BBZGUI::SameLine(); HelpMarker(
                "Using the simplified one-liner ListBox API here.\n"
                "Refer to the \"List boxes\" section below for an explanation of how to use the more flexible and general BeginListBox/EndListBox API.");
        }

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Tooltips");
    if (BBZGUI::TreeNode("Tooltips"))
    {
        // Tooltips are windows following the mouse. They do not take focus away.
        BBZGUI::SeparatorText("General");

        // Typical use cases:
        // - Short-form (text only):      SetItemTooltip("Hello");
        // - Short-form (any contents):   if (BeginItemTooltip()) { Text("Hello"); EndTooltip(); }

        // - Full-form (text only):       if (IsItemHovered(...)) { SetTooltip("Hello"); }
        // - Full-form (any contents):    if (IsItemHovered(...) && BeginTooltip()) { Text("Hello"); EndTooltip(); }

        HelpMarker(
            "Tooltip are typically created by using a IsItemHovered() + SetTooltip() sequence.\n\n"
            "We provide a helper SetItemTooltip() function to perform the two with standards flags.");

        ImVec2 sz = ImVec2(-FLT_MIN, 0.0f);

        BBZGUI::Button("Basic", sz);
        BBZGUI::SetItemTooltip("I am a tooltip");

        BBZGUI::Button("Fancy", sz);
        if (BBZGUI::BeginItemTooltip())
        {
            BBZGUI::Text("I am a fancy tooltip");
            static float arr[] = { 0.6f, 0.1f, 1.0f, 0.5f, 0.92f, 0.1f, 0.2f };
            BBZGUI::PlotLines("Curve", arr, IM_ARRAYSIZE(arr));
            BBZGUI::Text("Sin(time) = %f", sinf((float)BBZGUI::GetTime()));
            BBZGUI::EndTooltip();
        }

        BBZGUI::SeparatorText("Always On");

        // Showcase NOT relying on a IsItemHovered() to emit a tooltip.
        // Here the tooltip is always emitted when 'always_on == true'.
        static int always_on = 0;
        BBZGUI::RadioButton("Off", &always_on, 0);
        BBZGUI::SameLine();
        BBZGUI::RadioButton("Always On (Simple)", &always_on, 1);
        BBZGUI::SameLine();
        BBZGUI::RadioButton("Always On (Advanced)", &always_on, 2);
        if (always_on == 1)
            BBZGUI::SetTooltip("I am following you around.");
        else if (always_on == 2 && BBZGUI::BeginTooltip())
        {
            BBZGUI::ProgressBar(sinf((float)BBZGUI::GetTime()) * 0.5f + 0.5f, ImVec2(BBZGUI::GetFontSize() * 25, 0.0f));
            BBZGUI::EndTooltip();
        }

        BBZGUI::SeparatorText("Custom");

        HelpMarker(
            "Passing BBZGUIHoveredFlags_ForTooltip to IsItemHovered() is the preferred way to standardize"
            "tooltip activation details across your application. You may however decide to use custom"
            "flags for a specific tooltip instance.");

        // The following examples are passed for documentation purpose but may not be useful to most users.
        // Passing BBZGUIHoveredFlags_ForTooltip to IsItemHovered() will pull BBZGUIHoveredFlags flags values from
        // 'style.HoverFlagsForTooltipMouse' or 'style.HoverFlagsForTooltipNav' depending on whether mouse or keyboard/gamepad is being used.
        // With default settings, BBZGUIHoveredFlags_ForTooltip is equivalent to BBZGUIHoveredFlags_DelayShort + BBZGUIHoveredFlags_Stationary.
        BBZGUI::Button("Manual", sz);
        if (BBZGUI::IsItemHovered(BBZGUIHoveredFlags_ForTooltip))
            BBZGUI::SetTooltip("I am a manually emitted tooltip.");

        BBZGUI::Button("DelayNone", sz);
        if (BBZGUI::IsItemHovered(BBZGUIHoveredFlags_DelayNone))
            BBZGUI::SetTooltip("I am a tooltip with no delay.");

        BBZGUI::Button("DelayShort", sz);
        if (BBZGUI::IsItemHovered(BBZGUIHoveredFlags_DelayShort | BBZGUIHoveredFlags_NoSharedDelay))
            BBZGUI::SetTooltip("I am a tooltip with a short delay (%0.2f sec).", BBZGUI::GetStyle().HoverDelayShort);

        BBZGUI::Button("DelayLong", sz);
        if (BBZGUI::IsItemHovered(BBZGUIHoveredFlags_DelayNormal | BBZGUIHoveredFlags_NoSharedDelay))
            BBZGUI::SetTooltip("I am a tooltip with a long delay (%0.2f sec).", BBZGUI::GetStyle().HoverDelayNormal);

        BBZGUI::Button("Stationary", sz);
        if (BBZGUI::IsItemHovered(BBZGUIHoveredFlags_Stationary))
            BBZGUI::SetTooltip("I am a tooltip requiring mouse to be stationary before activating.");

        // Using BBZGUIHoveredFlags_ForTooltip will pull flags from 'style.HoverFlagsForTooltipMouse' or 'style.HoverFlagsForTooltipNav',
        // which default value include the BBZGUIHoveredFlags_AllowWhenDisabled flag.
        BBZGUI::BeginDisabled();
        BBZGUI::Button("Disabled item", sz);
        if (BBZGUI::IsItemHovered(BBZGUIHoveredFlags_ForTooltip))
            BBZGUI::SetTooltip("I am a a tooltip for a disabled item.");
        BBZGUI::EndDisabled();

        BBZGUI::TreePop();
    }

    // Testing BBZGUIOnceUponAFrame helper.
    //static BBZGUIOnceUponAFrame once;
    //for (int i = 0; i < 5; i++)
    //    if (once)
    //        BBZGUI::Text("This will be displayed only once.");

    IMGUI_DEMO_MARKER("Widgets/Tree Nodes");
    if (BBZGUI::TreeNode("Tree Nodes"))
    {
        IMGUI_DEMO_MARKER("Widgets/Tree Nodes/Basic trees");
        if (BBZGUI::TreeNode("Basic trees"))
        {
            for (int i = 0; i < 5; i++)
            {
                // Use SetNextItemOpen() so set the default state of a node to be open. We could
                // also use TreeNodeEx() with the BBZGUITreeNodeFlags_DefaultOpen flag to achieve the same thing!
                if (i == 0)
                    BBZGUI::SetNextItemOpen(true, BBZGUICond_Once);

                // Here we use PushID() to generate a unique base ID, and then the "" used as TreeNode id won't conflict.
                // An alternative to using 'PushID() + TreeNode("", ...)' to generate a unique ID is to use 'TreeNode((void*)(intptr_t)i, ...)',
                // aka generate a dummy pointer-sized value to be hashed. The demo below uses that technique. Both are fine.
                BBZGUI::PushID(i);
                if (BBZGUI::TreeNode("", "Child %d", i))
                {
                    BBZGUI::Text("blah blah");
                    BBZGUI::SameLine();
                    if (BBZGUI::SmallButton("button")) {}
                    BBZGUI::TreePop();
                }
                BBZGUI::PopID();
            }
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Tree Nodes/Advanced, with Selectable nodes");
        if (BBZGUI::TreeNode("Advanced, with Selectable nodes"))
        {
            HelpMarker(
                "This is a more typical looking tree with selectable nodes.\n"
                "Click to select, CTRL+Click to toggle, click on arrows or double-click to open.");
            static BBZGUITreeNodeFlags base_flags = BBZGUITreeNodeFlags_OpenOnArrow | BBZGUITreeNodeFlags_OpenOnDoubleClick | BBZGUITreeNodeFlags_SpanAvailWidth;
            static bool align_label_with_current_x_position = false;
            static bool test_drag_and_drop = false;
            BBZGUI::CheckboxFlags("BBZGUITreeNodeFlags_OpenOnArrow",       &base_flags, BBZGUITreeNodeFlags_OpenOnArrow);
            BBZGUI::CheckboxFlags("BBZGUITreeNodeFlags_OpenOnDoubleClick", &base_flags, BBZGUITreeNodeFlags_OpenOnDoubleClick);
            BBZGUI::CheckboxFlags("BBZGUITreeNodeFlags_SpanAvailWidth",    &base_flags, BBZGUITreeNodeFlags_SpanAvailWidth); BBZGUI::SameLine(); HelpMarker("Extend hit area to all available width instead of allowing more items to be laid out after the node.");
            BBZGUI::CheckboxFlags("BBZGUITreeNodeFlags_SpanFullWidth",     &base_flags, BBZGUITreeNodeFlags_SpanFullWidth);
            BBZGUI::CheckboxFlags("BBZGUITreeNodeFlags_SpanTextWidth",     &base_flags, BBZGUITreeNodeFlags_SpanTextWidth); BBZGUI::SameLine(); HelpMarker("Reduce hit area to the text label and a bit of margin.");
            BBZGUI::CheckboxFlags("BBZGUITreeNodeFlags_SpanAllColumns",    &base_flags, BBZGUITreeNodeFlags_SpanAllColumns); BBZGUI::SameLine(); HelpMarker("For use in Tables only.");
            BBZGUI::CheckboxFlags("BBZGUITreeNodeFlags_AllowOverlap",      &base_flags, BBZGUITreeNodeFlags_AllowOverlap);
            BBZGUI::CheckboxFlags("BBZGUITreeNodeFlags_Framed",            &base_flags, BBZGUITreeNodeFlags_Framed); BBZGUI::SameLine(); HelpMarker("Draw frame with background (e.g. for CollapsingHeader)");
            BBZGUI::CheckboxFlags("BBZGUITreeNodeFlags_NavLeftJumpsBackHere", &base_flags, BBZGUITreeNodeFlags_NavLeftJumpsBackHere);
            BBZGUI::Checkbox("Align label with current X position", &align_label_with_current_x_position);
            BBZGUI::Checkbox("Test tree node as drag source", &test_drag_and_drop);
            BBZGUI::Text("Hello!");
            if (align_label_with_current_x_position)
                BBZGUI::Unindent(BBZGUI::GetTreeNodeToLabelSpacing());

            // 'selection_mask' is dumb representation of what may be user-side selection state.
            //  You may retain selection state inside or outside your objects in whatever format you see fit.
            // 'node_clicked' is temporary storage of what node we have clicked to process selection at the end
            /// of the loop. May be a pointer to your own node type, etc.
            static int selection_mask = (1 << 2);
            int node_clicked = -1;
            for (int i = 0; i < 6; i++)
            {
                // Disable the default "open on single-click behavior" + set Selected flag according to our selection.
                // To alter selection we use IsItemClicked() && !IsItemToggledOpen(), so clicking on an arrow doesn't alter selection.
                BBZGUITreeNodeFlags node_flags = base_flags;
                const bool is_selected = (selection_mask & (1 << i)) != 0;
                if (is_selected)
                    node_flags |= BBZGUITreeNodeFlags_Selected;
                if (i < 3)
                {
                    // Items 0..2 are Tree Node
                    bool node_open = BBZGUI::TreeNodeEx((void*)(intptr_t)i, node_flags, "Selectable Node %d", i);
                    if (BBZGUI::IsItemClicked() && !BBZGUI::IsItemToggledOpen())
                        node_clicked = i;
                    if (test_drag_and_drop && BBZGUI::BeginDragDropSource())
                    {
                        BBZGUI::SetDragDropPayload("_TREENODE", NULL, 0);
                        BBZGUI::Text("This is a drag and drop source");
                        BBZGUI::EndDragDropSource();
                    }
                    if (i == 2 && (base_flags & BBZGUITreeNodeFlags_SpanTextWidth))
                    {
                        // Item 2 has an additional inline button to help demonstrate SpanTextWidth.
                        BBZGUI::SameLine();
                        if (BBZGUI::SmallButton("button")) {}
                    }
                    if (node_open)
                    {
                        BBZGUI::BulletText("Blah blah\nBlah Blah");
                        BBZGUI::SameLine();
                        BBZGUI::SmallButton("Button");
                        BBZGUI::TreePop();
                    }
                }
                else
                {
                    // Items 3..5 are Tree Leaves
                    // The only reason we use TreeNode at all is to allow selection of the leaf. Otherwise we can
                    // use BulletText() or advance the cursor by GetTreeNodeToLabelSpacing() and call Text().
                    node_flags |= BBZGUITreeNodeFlags_Leaf | BBZGUITreeNodeFlags_NoTreePushOnOpen; // BBZGUITreeNodeFlags_Bullet
                    BBZGUI::TreeNodeEx((void*)(intptr_t)i, node_flags, "Selectable Leaf %d", i);
                    if (BBZGUI::IsItemClicked() && !BBZGUI::IsItemToggledOpen())
                        node_clicked = i;
                    if (test_drag_and_drop && BBZGUI::BeginDragDropSource())
                    {
                        BBZGUI::SetDragDropPayload("_TREENODE", NULL, 0);
                        BBZGUI::Text("This is a drag and drop source");
                        BBZGUI::EndDragDropSource();
                    }
                }
            }
            if (node_clicked != -1)
            {
                // Update selection state
                // (process outside of tree loop to avoid visual inconsistencies during the clicking frame)
                if (BBZGUI::GetIO().KeyCtrl)
                    selection_mask ^= (1 << node_clicked);          // CTRL+click to toggle
                else //if (!(selection_mask & (1 << node_clicked))) // Depending on selection behavior you want, may want to preserve selection when clicking on item that is part of the selection
                    selection_mask = (1 << node_clicked);           // Click to single-select
            }
            if (align_label_with_current_x_position)
                BBZGUI::Indent(BBZGUI::GetTreeNodeToLabelSpacing());
            BBZGUI::TreePop();
        }
        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Collapsing Headers");
    if (BBZGUI::TreeNode("Collapsing Headers"))
    {
        static bool closable_group = true;
        BBZGUI::Checkbox("Show 2nd header", &closable_group);
        if (BBZGUI::CollapsingHeader("Header", BBZGUITreeNodeFlags_None))
        {
            BBZGUI::Text("IsItemHovered: %d", BBZGUI::IsItemHovered());
            for (int i = 0; i < 5; i++)
                BBZGUI::Text("Some content %d", i);
        }
        if (BBZGUI::CollapsingHeader("Header with a close button", &closable_group))
        {
            BBZGUI::Text("IsItemHovered: %d", BBZGUI::IsItemHovered());
            for (int i = 0; i < 5; i++)
                BBZGUI::Text("More content %d", i);
        }
        /*
        if (BBZGUI::CollapsingHeader("Header with a bullet", BBZGUITreeNodeFlags_Bullet))
            BBZGUI::Text("IsItemHovered: %d", BBZGUI::IsItemHovered());
        */
        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Bullets");
    if (BBZGUI::TreeNode("Bullets"))
    {
        BBZGUI::BulletText("Bullet point 1");
        BBZGUI::BulletText("Bullet point 2\nOn multiple lines");
        if (BBZGUI::TreeNode("Tree node"))
        {
            BBZGUI::BulletText("Another bullet point");
            BBZGUI::TreePop();
        }
        BBZGUI::Bullet(); BBZGUI::Text("Bullet point 3 (two calls)");
        BBZGUI::Bullet(); BBZGUI::SmallButton("Button");
        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Text");
    if (BBZGUI::TreeNode("Text"))
    {
        IMGUI_DEMO_MARKER("Widgets/Text/Colored Text");
        if (BBZGUI::TreeNode("Colorful Text"))
        {
            // Using shortcut. You can use PushStyleColor()/PopStyleColor() for more flexibility.
            BBZGUI::TextColored(ImVec4(1.0f, 0.0f, 1.0f, 1.0f), "Pink");
            BBZGUI::TextColored(ImVec4(1.0f, 1.0f, 0.0f, 1.0f), "Yellow");
            BBZGUI::TextDisabled("Disabled");
            BBZGUI::SameLine(); HelpMarker("The TextDisabled color is stored in BBZGUIStyle.");
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text/Word Wrapping");
        if (BBZGUI::TreeNode("Word Wrapping"))
        {
            // Using shortcut. You can use PushTextWrapPos()/PopTextWrapPos() for more flexibility.
            BBZGUI::TextWrapped(
                "This text should automatically wrap on the edge of the window. The current implementation "
                "for text wrapping follows simple rules suitable for English and possibly other languages.");
            BBZGUI::Spacing();

            static float wrap_width = 200.0f;
            BBZGUI::SliderFloat("Wrap width", &wrap_width, -20, 600, "%.0f");

            ImDrawList* draw_list = BBZGUI::GetWindowDrawList();
            for (int n = 0; n < 2; n++)
            {
                BBZGUI::Text("Test paragraph %d:", n);
                ImVec2 pos = BBZGUI::GetCursorScreenPos();
                ImVec2 marker_min = ImVec2(pos.x + wrap_width, pos.y);
                ImVec2 marker_max = ImVec2(pos.x + wrap_width + 10, pos.y + BBZGUI::GetTextLineHeight());
                BBZGUI::PushTextWrapPos(BBZGUI::GetCursorPos().x + wrap_width);
                if (n == 0)
                    BBZGUI::Text("The lazy dog is a good dog. This paragraph should fit within %.0f pixels. Testing a 1 character word. The quick brown fox jumps over the lazy dog.", wrap_width);
                else
                    BBZGUI::Text("aaaaaaaa bbbbbbbb, c cccccccc,dddddddd. d eeeeeeee   ffffffff. gggggggg!hhhhhhhh");

                // Draw actual text bounding box, following by marker of our expected limit (should not overlap!)
                draw_list->AddRect(BBZGUI::GetItemRectMin(), BBZGUI::GetItemRectMax(), IM_COL32(255, 255, 0, 255));
                draw_list->AddRectFilled(marker_min, marker_max, IM_COL32(255, 0, 255, 255));
                BBZGUI::PopTextWrapPos();
            }

            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text/UTF-8 Text");
        if (BBZGUI::TreeNode("UTF-8 Text"))
        {
            // UTF-8 test with Japanese characters
            // (Needs a suitable font? Try "Google Noto" or "Arial Unicode". See docs/FONTS.md for details.)
            // - From C++11 you can use the u8"my text" syntax to encode literal strings as UTF-8
            // - For earlier compiler, you may be able to encode your sources as UTF-8 (e.g. in Visual Studio, you
            //   can save your source files as 'UTF-8 without signature').
            // - FOR THIS DEMO FILE ONLY, BECAUSE WE WANT TO SUPPORT OLD COMPILERS, WE ARE *NOT* INCLUDING RAW UTF-8
            //   CHARACTERS IN THIS SOURCE FILE. Instead we are encoding a few strings with hexadecimal constants.
            //   Don't do this in your application! Please use u8"text in any language" in your application!
            // Note that characters values are preserved even by InputText() if the font cannot be displayed,
            // so you can safely copy & paste garbled characters into another application.
            BBZGUI::TextWrapped(
                "CJK text will only appear if the font was loaded with the appropriate CJK character ranges. "
                "Call io.Fonts->AddFontFromFileTTF() manually to load extra character ranges. "
                "Read docs/FONTS.md for details.");
            BBZGUI::Text("Hiragana: \xe3\x81\x8b\xe3\x81\x8d\xe3\x81\x8f\xe3\x81\x91\xe3\x81\x93 (kakikukeko)");
            BBZGUI::Text("Kanjis: \xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e (nihongo)");
            static char buf[32] = "\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e";
            //static char buf[32] = u8"NIHONGO"; // <- this is how you would write it with C++11, using real kanjis
            BBZGUI::InputText("UTF-8 input", buf, IM_ARRAYSIZE(buf));
            BBZGUI::TreePop();
        }
        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Images");
    if (BBZGUI::TreeNode("Images"))
    {
        BBZGUIIO& io = BBZGUI::GetIO();
        BBZGUI::TextWrapped(
            "Below we are displaying the font texture (which is the only texture we have access to in this demo). "
            "Use the 'ImTextureID' type as storage to pass pointers or identifier to your own texture data. "
            "Hover the texture for a zoomed view!");

        // Below we are displaying the font texture because it is the only texture we have access to inside the demo!
        // Remember that ImTextureID is just storage for whatever you want it to be. It is essentially a value that
        // will be passed to the rendering backend via the ImDrawCmd structure.
        // If you use one of the default imgui_impl_XXXX.cpp rendering backend, they all have comments at the top
        // of their respective source file to specify what they expect to be stored in ImTextureID, for example:
        // - The imgui_impl_dx11.cpp renderer expect a 'ID3D11ShaderResourceView*' pointer
        // - The imgui_impl_opengl3.cpp renderer expect a GLuint OpenGL texture identifier, etc.
        // More:
        // - If you decided that ImTextureID = MyEngineTexture*, then you can pass your MyEngineTexture* pointers
        //   to BBZGUI::Image(), and gather width/height through your own functions, etc.
        // - You can use ShowMetricsWindow() to inspect the draw data that are being passed to your renderer,
        //   it will help you debug issues if you are confused about it.
        // - Consider using the lower-level ImDrawList::AddImage() API, via BBZGUI::GetWindowDrawList()->AddImage().
        // - Read https://github.com/ocornut/imgui/blob/master/docs/FAQ.md
        // - Read https://github.com/ocornut/imgui/wiki/Image-Loading-and-Displaying-Examples
        ImTextureID my_tex_id = io.Fonts->TexID;
        float my_tex_w = (float)io.Fonts->TexWidth;
        float my_tex_h = (float)io.Fonts->TexHeight;
        {
            static bool use_text_color_for_tint = false;
            BBZGUI::Checkbox("Use Text Color for Tint", &use_text_color_for_tint);
            BBZGUI::Text("%.0fx%.0f", my_tex_w, my_tex_h);
            ImVec2 pos = BBZGUI::GetCursorScreenPos();
            ImVec2 uv_min = ImVec2(0.0f, 0.0f);                 // Top-left
            ImVec2 uv_max = ImVec2(1.0f, 1.0f);                 // Lower-right
            ImVec4 tint_col = use_text_color_for_tint ? BBZGUI::GetStyleColorVec4(BBZGUICol_Text) : ImVec4(1.0f, 1.0f, 1.0f, 1.0f); // No tint
            ImVec4 border_col = BBZGUI::GetStyleColorVec4(BBZGUICol_Border);
            BBZGUI::Image(my_tex_id, ImVec2(my_tex_w, my_tex_h), uv_min, uv_max, tint_col, border_col);
            if (BBZGUI::BeginItemTooltip())
            {
                float region_sz = 32.0f;
                float region_x = io.MousePos.x - pos.x - region_sz * 0.5f;
                float region_y = io.MousePos.y - pos.y - region_sz * 0.5f;
                float zoom = 4.0f;
                if (region_x < 0.0f) { region_x = 0.0f; }
                else if (region_x > my_tex_w - region_sz) { region_x = my_tex_w - region_sz; }
                if (region_y < 0.0f) { region_y = 0.0f; }
                else if (region_y > my_tex_h - region_sz) { region_y = my_tex_h - region_sz; }
                BBZGUI::Text("Min: (%.2f, %.2f)", region_x, region_y);
                BBZGUI::Text("Max: (%.2f, %.2f)", region_x + region_sz, region_y + region_sz);
                ImVec2 uv0 = ImVec2((region_x) / my_tex_w, (region_y) / my_tex_h);
                ImVec2 uv1 = ImVec2((region_x + region_sz) / my_tex_w, (region_y + region_sz) / my_tex_h);
                BBZGUI::Image(my_tex_id, ImVec2(region_sz * zoom, region_sz * zoom), uv0, uv1, tint_col, border_col);
                BBZGUI::EndTooltip();
            }
        }

        IMGUI_DEMO_MARKER("Widgets/Images/Textured buttons");
        BBZGUI::TextWrapped("And now some textured buttons..");
        static int pressed_count = 0;
        for (int i = 0; i < 8; i++)
        {
            // UV coordinates are often (0.0f, 0.0f) and (1.0f, 1.0f) to display an entire textures.
            // Here are trying to display only a 32x32 pixels area of the texture, hence the UV computation.
            // Read about UV coordinates here: https://github.com/ocornut/imgui/wiki/Image-Loading-and-Displaying-Examples
            BBZGUI::PushID(i);
            if (i > 0)
                BBZGUI::PushStyleVar(BBZGUIStyleVar_FramePadding, ImVec2(i - 1.0f, i - 1.0f));
            ImVec2 size = ImVec2(32.0f, 32.0f);                         // Size of the image we want to make visible
            ImVec2 uv0 = ImVec2(0.0f, 0.0f);                            // UV coordinates for lower-left
            ImVec2 uv1 = ImVec2(32.0f / my_tex_w, 32.0f / my_tex_h);    // UV coordinates for (32,32) in our texture
            ImVec4 bg_col = ImVec4(0.0f, 0.0f, 0.0f, 1.0f);             // Black background
            ImVec4 tint_col = ImVec4(1.0f, 1.0f, 1.0f, 1.0f);           // No tint
            if (BBZGUI::ImageButton("", my_tex_id, size, uv0, uv1, bg_col, tint_col))
                pressed_count += 1;
            if (i > 0)
                BBZGUI::PopStyleVar();
            BBZGUI::PopID();
            BBZGUI::SameLine();
        }
        BBZGUI::NewLine();
        BBZGUI::Text("Pressed %d times.", pressed_count);
        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Combo");
    if (BBZGUI::TreeNode("Combo"))
    {
        // Combo Boxes are also called "Dropdown" in other systems
        // Expose flags as checkbox for the demo
        static BBZGUIComboFlags flags = 0;
        BBZGUI::CheckboxFlags("BBZGUIComboFlags_PopupAlignLeft", &flags, BBZGUIComboFlags_PopupAlignLeft);
        BBZGUI::SameLine(); HelpMarker("Only makes a difference if the popup is larger than the combo");
        if (BBZGUI::CheckboxFlags("BBZGUIComboFlags_NoArrowButton", &flags, BBZGUIComboFlags_NoArrowButton))
            flags &= ~BBZGUIComboFlags_NoPreview;     // Clear incompatible flags
        if (BBZGUI::CheckboxFlags("BBZGUIComboFlags_NoPreview", &flags, BBZGUIComboFlags_NoPreview))
            flags &= ~(BBZGUIComboFlags_NoArrowButton | BBZGUIComboFlags_WidthFitPreview); // Clear incompatible flags
        if (BBZGUI::CheckboxFlags("BBZGUIComboFlags_WidthFitPreview", &flags, BBZGUIComboFlags_WidthFitPreview))
            flags &= ~BBZGUIComboFlags_NoPreview;

        // Override default popup height
        if (BBZGUI::CheckboxFlags("BBZGUIComboFlags_HeightSmall", &flags, BBZGUIComboFlags_HeightSmall))
            flags &= ~(BBZGUIComboFlags_HeightMask_ & ~BBZGUIComboFlags_HeightSmall);
        if (BBZGUI::CheckboxFlags("BBZGUIComboFlags_HeightRegular", &flags, BBZGUIComboFlags_HeightRegular))
            flags &= ~(BBZGUIComboFlags_HeightMask_ & ~BBZGUIComboFlags_HeightRegular);
        if (BBZGUI::CheckboxFlags("BBZGUIComboFlags_HeightLargest", &flags, BBZGUIComboFlags_HeightLargest))
            flags &= ~(BBZGUIComboFlags_HeightMask_ & ~BBZGUIComboFlags_HeightLargest);

        // Using the generic BeginCombo() API, you have full control over how to display the combo contents.
        // (your selection data could be an index, a pointer to the object, an id for the object, a flag intrusively
        // stored in the object itself, etc.)
        const char* items[] = { "AAAA", "BBBB", "CCCC", "DDDD", "EEEE", "FFFF", "GGGG", "HHHH", "IIII", "JJJJ", "KKKK", "LLLLLLL", "MMMM", "OOOOOOO" };
        static int item_selected_idx = 0; // Here we store our selection data as an index.

        // Pass in the preview value visible before opening the combo (it could technically be different contents or not pulled from items[])
        const char* combo_preview_value = items[item_selected_idx];

        if (BBZGUI::BeginCombo("combo 1", combo_preview_value, flags))
        {
            for (int n = 0; n < IM_ARRAYSIZE(items); n++)
            {
                const bool is_selected = (item_selected_idx == n);
                if (BBZGUI::Selectable(items[n], is_selected))
                    item_selected_idx = n;

                // Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                if (is_selected)
                    BBZGUI::SetItemDefaultFocus();
            }
            BBZGUI::EndCombo();
        }

        BBZGUI::Spacing();
        BBZGUI::SeparatorText("One-liner variants");
        HelpMarker("Flags above don't apply to this section.");

        // Simplified one-liner Combo() API, using values packed in a single constant string
        // This is a convenience for when the selection set is small and known at compile-time.
        static int item_current_2 = 0;
        BBZGUI::Combo("combo 2 (one-liner)", &item_current_2, "aaaa\0bbbb\0cccc\0dddd\0eeee\0\0");

        // Simplified one-liner Combo() using an array of const char*
        // This is not very useful (may obsolete): prefer using BeginCombo()/EndCombo() for full control.
        static int item_current_3 = -1; // If the selection isn't within 0..count, Combo won't display a preview
        BBZGUI::Combo("combo 3 (array)", &item_current_3, items, IM_ARRAYSIZE(items));

        // Simplified one-liner Combo() using an accessor function
        static int item_current_4 = 0;
        BBZGUI::Combo("combo 4 (function)", &item_current_4, [](void* data, int n) { return ((const char**)data)[n]; }, items, IM_ARRAYSIZE(items));

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/List Boxes");
    if (BBZGUI::TreeNode("List boxes"))
    {
        // BeginListBox() is essentially a thin wrapper to using BeginChild()/EndChild()
        // using the BBZGUIChildFlags_FrameStyle flag for stylistic changes + displaying a label.
        // You may be tempted to simply use BeginChild() directly. However note that BeginChild() requires EndChild()
        // to always be called (inconsistent with BeginListBox()/EndListBox()).

        // Using the generic BeginListBox() API, you have full control over how to display the combo contents.
        // (your selection data could be an index, a pointer to the object, an id for the object, a flag intrusively
        // stored in the object itself, etc.)
        const char* items[] = { "AAAA", "BBBB", "CCCC", "DDDD", "EEEE", "FFFF", "GGGG", "HHHH", "IIII", "JJJJ", "KKKK", "LLLLLLL", "MMMM", "OOOOOOO" };
        static int item_selected_idx = 0; // Here we store our selected data as an index.

        static bool item_highlight = false;
        int item_highlighted_idx = -1; // Here we store our highlighted data as an index.
        BBZGUI::Checkbox("Highlight hovered item in second listbox", &item_highlight);

        if (BBZGUI::BeginListBox("listbox 1"))
        {
            for (int n = 0; n < IM_ARRAYSIZE(items); n++)
            {
                const bool is_selected = (item_selected_idx == n);
                if (BBZGUI::Selectable(items[n], is_selected))
                    item_selected_idx = n;

                if (item_highlight && BBZGUI::IsItemHovered())
                    item_highlighted_idx = n;

                // Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                if (is_selected)
                    BBZGUI::SetItemDefaultFocus();
            }
            BBZGUI::EndListBox();
        }
        BBZGUI::SameLine(); HelpMarker("Here we are sharing selection state between both boxes.");

        // Custom size: use all width, 5 items tall
        BBZGUI::Text("Full-width:");
        if (BBZGUI::BeginListBox("##listbox 2", ImVec2(-FLT_MIN, 5 * BBZGUI::GetTextLineHeightWithSpacing())))
        {
            for (int n = 0; n < IM_ARRAYSIZE(items); n++)
            {
                bool is_selected = (item_selected_idx == n);
                BBZGUISelectableFlags flags = (item_highlighted_idx == n) ? BBZGUISelectableFlags_Highlight : 0;
                if (BBZGUI::Selectable(items[n], is_selected, flags))
                    item_selected_idx = n;

                // Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                if (is_selected)
                    BBZGUI::SetItemDefaultFocus();
            }
            BBZGUI::EndListBox();
        }

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Selectables");
    //BBZGUI::SetNextItemOpen(true, BBZGUICond_Once);
    if (BBZGUI::TreeNode("Selectables"))
    {
        // Selectable() has 2 overloads:
        // - The one taking "bool selected" as a read-only selection information.
        //   When Selectable() has been clicked it returns true and you can alter selection state accordingly.
        // - The one taking "bool* p_selected" as a read-write selection information (convenient in some cases)
        // The earlier is more flexible, as in real application your selection may be stored in many different ways
        // and not necessarily inside a bool value (e.g. in flags within objects, as an external list, etc).
        IMGUI_DEMO_MARKER("Widgets/Selectables/Basic");
        if (BBZGUI::TreeNode("Basic"))
        {
            static bool selection[5] = { false, true, false, false };
            BBZGUI::Selectable("1. I am selectable", &selection[0]);
            BBZGUI::Selectable("2. I am selectable", &selection[1]);
            BBZGUI::Selectable("3. I am selectable", &selection[2]);
            if (BBZGUI::Selectable("4. I am double clickable", selection[3], BBZGUISelectableFlags_AllowDoubleClick))
                if (BBZGUI::IsMouseDoubleClicked(0))
                    selection[3] = !selection[3];
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Selectables/Rendering more items on the same line");
        if (BBZGUI::TreeNode("Rendering more items on the same line"))
        {
            // (1) Using SetNextItemAllowOverlap()
            // (2) Using the Selectable() override that takes "bool* p_selected" parameter, the bool value is toggled automatically.
            static bool selected[3] = { false, false, false };
            BBZGUI::SetNextItemAllowOverlap(); BBZGUI::Selectable("main.c",    &selected[0]); BBZGUI::SameLine(); BBZGUI::SmallButton("Link 1");
            BBZGUI::SetNextItemAllowOverlap(); BBZGUI::Selectable("Hello.cpp", &selected[1]); BBZGUI::SameLine(); BBZGUI::SmallButton("Link 2");
            BBZGUI::SetNextItemAllowOverlap(); BBZGUI::Selectable("Hello.h",   &selected[2]); BBZGUI::SameLine(); BBZGUI::SmallButton("Link 3");
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Selectables/In Tables");
        if (BBZGUI::TreeNode("In Tables"))
        {
            static bool selected[10] = {};

            if (BBZGUI::BeginTable("split1", 3, BBZGUITableFlags_Resizable | BBZGUITableFlags_NoSavedSettings | BBZGUITableFlags_Borders))
            {
                for (int i = 0; i < 10; i++)
                {
                    char label[32];
                    sprintf(label, "Item %d", i);
                    BBZGUI::TableNextColumn();
                    BBZGUI::Selectable(label, &selected[i]); // FIXME-TABLE: Selection overlap
                }
                BBZGUI::EndTable();
            }
            BBZGUI::Spacing();
            if (BBZGUI::BeginTable("split2", 3, BBZGUITableFlags_Resizable | BBZGUITableFlags_NoSavedSettings | BBZGUITableFlags_Borders))
            {
                for (int i = 0; i < 10; i++)
                {
                    char label[32];
                    sprintf(label, "Item %d", i);
                    BBZGUI::TableNextRow();
                    BBZGUI::TableNextColumn();
                    BBZGUI::Selectable(label, &selected[i], BBZGUISelectableFlags_SpanAllColumns);
                    BBZGUI::TableNextColumn();
                    BBZGUI::Text("Some other contents");
                    BBZGUI::TableNextColumn();
                    BBZGUI::Text("123456");
                }
                BBZGUI::EndTable();
            }
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Selectables/Grid");
        if (BBZGUI::TreeNode("Grid"))
        {
            static char selected[4][4] = { { 1, 0, 0, 0 }, { 0, 1, 0, 0 }, { 0, 0, 1, 0 }, { 0, 0, 0, 1 } };

            // Add in a bit of silly fun...
            const float time = (float)BBZGUI::GetTime();
            const bool winning_state = memchr(selected, 0, sizeof(selected)) == NULL; // If all cells are selected...
            if (winning_state)
                BBZGUI::PushStyleVar(BBZGUIStyleVar_SelectableTextAlign, ImVec2(0.5f + 0.5f * cosf(time * 2.0f), 0.5f + 0.5f * sinf(time * 3.0f)));

            for (int y = 0; y < 4; y++)
                for (int x = 0; x < 4; x++)
                {
                    if (x > 0)
                        BBZGUI::SameLine();
                    BBZGUI::PushID(y * 4 + x);
                    if (BBZGUI::Selectable("Sailor", selected[y][x] != 0, 0, ImVec2(50, 50)))
                    {
                        // Toggle clicked cell + toggle neighbors
                        selected[y][x] ^= 1;
                        if (x > 0) { selected[y][x - 1] ^= 1; }
                        if (x < 3) { selected[y][x + 1] ^= 1; }
                        if (y > 0) { selected[y - 1][x] ^= 1; }
                        if (y < 3) { selected[y + 1][x] ^= 1; }
                    }
                    BBZGUI::PopID();
                }

            if (winning_state)
                BBZGUI::PopStyleVar();
            BBZGUI::TreePop();
        }
        IMGUI_DEMO_MARKER("Widgets/Selectables/Alignment");
        if (BBZGUI::TreeNode("Alignment"))
        {
            HelpMarker(
                "By default, Selectables uses style.SelectableTextAlign but it can be overridden on a per-item "
                "basis using PushStyleVar(). You'll probably want to always keep your default situation to "
                "left-align otherwise it becomes difficult to layout multiple items on a same line");
            static bool selected[3 * 3] = { true, false, true, false, true, false, true, false, true };
            for (int y = 0; y < 3; y++)
            {
                for (int x = 0; x < 3; x++)
                {
                    ImVec2 alignment = ImVec2((float)x / 2.0f, (float)y / 2.0f);
                    char name[32];
                    sprintf(name, "(%.1f,%.1f)", alignment.x, alignment.y);
                    if (x > 0) BBZGUI::SameLine();
                    BBZGUI::PushStyleVar(BBZGUIStyleVar_SelectableTextAlign, alignment);
                    BBZGUI::Selectable(name, &selected[3 * y + x], BBZGUISelectableFlags_None, ImVec2(80, 80));
                    BBZGUI::PopStyleVar();
                }
            }
            BBZGUI::TreePop();
        }
        BBZGUI::TreePop();
    }

    ShowDemoWindowMultiSelect(demo_data);

    // To wire InputText() with std::string or any other custom string type,
    // see the "Text Input > Resize Callback" section of this demo, and the misc/cpp/imgui_stdlib.h file.
    IMGUI_DEMO_MARKER("Widgets/Text Input");
    if (BBZGUI::TreeNode("Text Input"))
    {
        IMGUI_DEMO_MARKER("Widgets/Text Input/Multi-line Text Input");
        if (BBZGUI::TreeNode("Multi-line Text Input"))
        {
            // Note: we are using a fixed-sized buffer for simplicity here. See BBZGUIInputTextFlags_CallbackResize
            // and the code in misc/cpp/imgui_stdlib.h for how to setup InputText() for dynamically resizing strings.
            static char text[1024 * 16] =
                "/*\n"
                " The Pentium F00F bug, shorthand for F0 0F C7 C8,\n"
                " the hexadecimal encoding of one offending instruction,\n"
                " more formally, the invalid operand with locked CMPXCHG8B\n"
                " instruction bug, is a design flaw in the majority of\n"
                " Intel Pentium, Pentium MMX, and Pentium OverDrive\n"
                " processors (all in the P5 microarchitecture).\n"
                "*/\n\n"
                "label:\n"
                "\tlock cmpxchg8b eax\n";

            static BBZGUIInputTextFlags flags = BBZGUIInputTextFlags_AllowTabInput;
            HelpMarker("You can use the BBZGUIInputTextFlags_CallbackResize facility if you need to wire InputTextMultiline() to a dynamic string type. See misc/cpp/imgui_stdlib.h for an example. (This is not demonstrated in BBZGui_demo.cpp because we don't want to include <string> in here)");
            BBZGUI::CheckboxFlags("BBZGUIInputTextFlags_ReadOnly", &flags, BBZGUIInputTextFlags_ReadOnly);
            BBZGUI::CheckboxFlags("BBZGUIInputTextFlags_AllowTabInput", &flags, BBZGUIInputTextFlags_AllowTabInput);
            BBZGUI::SameLine(); HelpMarker("When _AllowTabInput is set, passing through the widget with Tabbing doesn't automatically activate it, in order to also cycling through subsequent widgets.");
            BBZGUI::CheckboxFlags("BBZGUIInputTextFlags_CtrlEnterForNewLine", &flags, BBZGUIInputTextFlags_CtrlEnterForNewLine);
            BBZGUI::InputTextMultiline("##source", text, IM_ARRAYSIZE(text), ImVec2(-FLT_MIN, BBZGUI::GetTextLineHeight() * 16), flags);
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text Input/Filtered Text Input");
        if (BBZGUI::TreeNode("Filtered Text Input"))
        {
            struct TextFilters
            {
                // Modify character input by altering 'data->Eventchar' (BBZGUIInputTextFlags_CallbackCharFilter callback)
                static int FilterCasingSwap(BBZGUIInputTextCallbackData* data)
                {
                    if (data->EventChar >= 'a' && data->EventChar <= 'z')       { data->EventChar -= 'a' - 'A'; } // Lowercase becomes uppercase
                    else if (data->EventChar >= 'A' && data->EventChar <= 'Z')  { data->EventChar += 'a' - 'A'; } // Uppercase becomes lowercase
                    return 0;
                }

                // Return 0 (pass) if the character is 'i' or 'm' or 'g' or 'u' or 'i', otherwise return 1 (filter out)
                static int FilterBBZGUILetters(BBZGUIInputTextCallbackData* data)
                {
                    if (data->EventChar < 256 && strchr("imgui", (char)data->EventChar))
                        return 0;
                    return 1;
                }
            };

            static char buf1[32] = ""; BBZGUI::InputText("default",     buf1, 32);
            static char buf2[32] = ""; BBZGUI::InputText("decimal",     buf2, 32, BBZGUIInputTextFlags_CharsDecimal);
            static char buf3[32] = ""; BBZGUI::InputText("hexadecimal", buf3, 32, BBZGUIInputTextFlags_CharsHexadecimal | BBZGUIInputTextFlags_CharsUppercase);
            static char buf4[32] = ""; BBZGUI::InputText("uppercase",   buf4, 32, BBZGUIInputTextFlags_CharsUppercase);
            static char buf5[32] = ""; BBZGUI::InputText("no blank",    buf5, 32, BBZGUIInputTextFlags_CharsNoBlank);
            static char buf6[32] = ""; BBZGUI::InputText("casing swap", buf6, 32, BBZGUIInputTextFlags_CallbackCharFilter, TextFilters::FilterCasingSwap); // Use CharFilter callback to replace characters.
            static char buf7[32] = ""; BBZGUI::InputText("\"imgui\"",   buf7, 32, BBZGUIInputTextFlags_CallbackCharFilter, TextFilters::FilterBBZGUILetters); // Use CharFilter callback to disable some characters.
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text Input/Password input");
        if (BBZGUI::TreeNode("Password Input"))
        {
            static char password[64] = "password123";
            BBZGUI::InputText("password", password, IM_ARRAYSIZE(password), BBZGUIInputTextFlags_Password);
            BBZGUI::SameLine(); HelpMarker("Display all characters as '*'.\nDisable clipboard cut and copy.\nDisable logging.\n");
            BBZGUI::InputTextWithHint("password (w/ hint)", "<password>", password, IM_ARRAYSIZE(password), BBZGUIInputTextFlags_Password);
            BBZGUI::InputText("password (clear)", password, IM_ARRAYSIZE(password));
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text Input/Completion, History, Edit Callbacks");
        if (BBZGUI::TreeNode("Completion, History, Edit Callbacks"))
        {
            struct Funcs
            {
                static int MyCallback(BBZGUIInputTextCallbackData* data)
                {
                    if (data->EventFlag == BBZGUIInputTextFlags_CallbackCompletion)
                    {
                        data->InsertChars(data->CursorPos, "..");
                    }
                    else if (data->EventFlag == BBZGUIInputTextFlags_CallbackHistory)
                    {
                        if (data->EventKey == BBZGUIKey_UpArrow)
                        {
                            data->DeleteChars(0, data->BufTextLen);
                            data->InsertChars(0, "Pressed Up!");
                            data->SelectAll();
                        }
                        else if (data->EventKey == BBZGUIKey_DownArrow)
                        {
                            data->DeleteChars(0, data->BufTextLen);
                            data->InsertChars(0, "Pressed Down!");
                            data->SelectAll();
                        }
                    }
                    else if (data->EventFlag == BBZGUIInputTextFlags_CallbackEdit)
                    {
                        // Toggle casing of first character
                        char c = data->Buf[0];
                        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) data->Buf[0] ^= 32;
                        data->BufDirty = true;

                        // Increment a counter
                        int* p_int = (int*)data->UserData;
                        *p_int = *p_int + 1;
                    }
                    return 0;
                }
            };
            static char buf1[64];
            BBZGUI::InputText("Completion", buf1, 64, BBZGUIInputTextFlags_CallbackCompletion, Funcs::MyCallback);
            BBZGUI::SameLine(); HelpMarker(
                "Here we append \"..\" each time Tab is pressed. "
                "See 'Examples>Console' for a more meaningful demonstration of using this callback.");

            static char buf2[64];
            BBZGUI::InputText("History", buf2, 64, BBZGUIInputTextFlags_CallbackHistory, Funcs::MyCallback);
            BBZGUI::SameLine(); HelpMarker(
                "Here we replace and select text each time Up/Down are pressed. "
                "See 'Examples>Console' for a more meaningful demonstration of using this callback.");

            static char buf3[64];
            static int edit_count = 0;
            BBZGUI::InputText("Edit", buf3, 64, BBZGUIInputTextFlags_CallbackEdit, Funcs::MyCallback, (void*)&edit_count);
            BBZGUI::SameLine(); HelpMarker(
                "Here we toggle the casing of the first character on every edit + count edits.");
            BBZGUI::SameLine(); BBZGUI::Text("(%d)", edit_count);

            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text Input/Resize Callback");
        if (BBZGUI::TreeNode("Resize Callback"))
        {
            // To wire InputText() with std::string or any other custom string type,
            // you can use the BBZGUIInputTextFlags_CallbackResize flag + create a custom BBZGUI::InputText() wrapper
            // using your preferred type. See misc/cpp/imgui_stdlib.h for an implementation of this using std::string.
            HelpMarker(
                "Using BBZGUIInputTextFlags_CallbackResize to wire your custom string type to InputText().\n\n"
                "See misc/cpp/imgui_stdlib.h for an implementation of this for std::string.");
            struct Funcs
            {
                static int MyResizeCallback(BBZGUIInputTextCallbackData* data)
                {
                    if (data->EventFlag == BBZGUIInputTextFlags_CallbackResize)
                    {
                        ImVector<char>* my_str = (ImVector<char>*)data->UserData;
                        IM_ASSERT(my_str->begin() == data->Buf);
                        my_str->resize(data->BufSize); // NB: On resizing calls, generally data->BufSize == data->BufTextLen + 1
                        data->Buf = my_str->begin();
                    }
                    return 0;
                }

                // Note: Because BBZGUI:: is a namespace you would typically add your own function into the namespace.
                // For example, you code may declare a function 'BBZGUI::InputText(const char* label, MyString* my_str)'
                static bool MyInputTextMultiline(const char* label, ImVector<char>* my_str, const ImVec2& size = ImVec2(0, 0), BBZGUIInputTextFlags flags = 0)
                {
                    IM_ASSERT((flags & BBZGUIInputTextFlags_CallbackResize) == 0);
                    return BBZGUI::InputTextMultiline(label, my_str->begin(), (size_t)my_str->size(), size, flags | BBZGUIInputTextFlags_CallbackResize, Funcs::MyResizeCallback, (void*)my_str);
                }
            };

            // For this demo we are using ImVector as a string container.
            // Note that because we need to store a terminating zero character, our size/capacity are 1 more
            // than usually reported by a typical string class.
            static ImVector<char> my_str;
            if (my_str.empty())
                my_str.push_back(0);
            Funcs::MyInputTextMultiline("##MyStr", &my_str, ImVec2(-FLT_MIN, BBZGUI::GetTextLineHeight() * 16));
            BBZGUI::Text("Data: %p\nSize: %d\nCapacity: %d", (void*)my_str.begin(), my_str.size(), my_str.capacity());
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Text Input/Miscellaneous");
        if (BBZGUI::TreeNode("Miscellaneous"))
        {
            static char buf1[16];
            static BBZGUIInputTextFlags flags = BBZGUIInputTextFlags_EscapeClearsAll;
            BBZGUI::CheckboxFlags("BBZGUIInputTextFlags_EscapeClearsAll", &flags, BBZGUIInputTextFlags_EscapeClearsAll);
            BBZGUI::CheckboxFlags("BBZGUIInputTextFlags_ReadOnly", &flags, BBZGUIInputTextFlags_ReadOnly);
            BBZGUI::CheckboxFlags("BBZGUIInputTextFlags_NoUndoRedo", &flags, BBZGUIInputTextFlags_NoUndoRedo);
            BBZGUI::InputText("Hello", buf1, IM_ARRAYSIZE(buf1), flags);
            BBZGUI::TreePop();
        }

        BBZGUI::TreePop();
    }

    // Tabs
    IMGUI_DEMO_MARKER("Widgets/Tabs");
    if (BBZGUI::TreeNode("Tabs"))
    {
        IMGUI_DEMO_MARKER("Widgets/Tabs/Basic");
        if (BBZGUI::TreeNode("Basic"))
        {
            BBZGUITabBarFlags tab_bar_flags = BBZGUITabBarFlags_None;
            if (BBZGUI::BeginTabBar("MyTabBar", tab_bar_flags))
            {
                if (BBZGUI::BeginTabItem("Avocado"))
                {
                    BBZGUI::Text("This is the Avocado tab!\nblah blah blah blah blah");
                    BBZGUI::EndTabItem();
                }
                if (BBZGUI::BeginTabItem("Broccoli"))
                {
                    BBZGUI::Text("This is the Broccoli tab!\nblah blah blah blah blah");
                    BBZGUI::EndTabItem();
                }
                if (BBZGUI::BeginTabItem("Cucumber"))
                {
                    BBZGUI::Text("This is the Cucumber tab!\nblah blah blah blah blah");
                    BBZGUI::EndTabItem();
                }
                BBZGUI::EndTabBar();
            }
            BBZGUI::Separator();
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Tabs/Advanced & Close Button");
        if (BBZGUI::TreeNode("Advanced & Close Button"))
        {
            // Expose a couple of the available flags. In most cases you may just call BeginTabBar() with no flags (0).
            static BBZGUITabBarFlags tab_bar_flags = BBZGUITabBarFlags_Reorderable;
            BBZGUI::CheckboxFlags("BBZGUITabBarFlags_Reorderable", &tab_bar_flags, BBZGUITabBarFlags_Reorderable);
            BBZGUI::CheckboxFlags("BBZGUITabBarFlags_AutoSelectNewTabs", &tab_bar_flags, BBZGUITabBarFlags_AutoSelectNewTabs);
            BBZGUI::CheckboxFlags("BBZGUITabBarFlags_TabListPopupButton", &tab_bar_flags, BBZGUITabBarFlags_TabListPopupButton);
            BBZGUI::CheckboxFlags("BBZGUITabBarFlags_NoCloseWithMiddleMouseButton", &tab_bar_flags, BBZGUITabBarFlags_NoCloseWithMiddleMouseButton);
            BBZGUI::CheckboxFlags("BBZGUITabBarFlags_DrawSelectedOverline", &tab_bar_flags, BBZGUITabBarFlags_DrawSelectedOverline);
            if ((tab_bar_flags & BBZGUITabBarFlags_FittingPolicyMask_) == 0)
                tab_bar_flags |= BBZGUITabBarFlags_FittingPolicyDefault_;
            if (BBZGUI::CheckboxFlags("BBZGUITabBarFlags_FittingPolicyResizeDown", &tab_bar_flags, BBZGUITabBarFlags_FittingPolicyResizeDown))
                tab_bar_flags &= ~(BBZGUITabBarFlags_FittingPolicyMask_ ^ BBZGUITabBarFlags_FittingPolicyResizeDown);
            if (BBZGUI::CheckboxFlags("BBZGUITabBarFlags_FittingPolicyScroll", &tab_bar_flags, BBZGUITabBarFlags_FittingPolicyScroll))
                tab_bar_flags &= ~(BBZGUITabBarFlags_FittingPolicyMask_ ^ BBZGUITabBarFlags_FittingPolicyScroll);

            // Tab Bar
            BBZGUI::AlignTextToFramePadding();
            BBZGUI::Text("Opened:");
            const char* names[4] = { "Artichoke", "Beetroot", "Celery", "Daikon" };
            static bool opened[4] = { true, true, true, true }; // Persistent user state
            for (int n = 0; n < IM_ARRAYSIZE(opened); n++)
            {
                BBZGUI::SameLine();
                BBZGUI::Checkbox(names[n], &opened[n]);
            }

            // Passing a bool* to BeginTabItem() is similar to passing one to Begin():
            // the underlying bool will be set to false when the tab is closed.
            if (BBZGUI::BeginTabBar("MyTabBar", tab_bar_flags))
            {
                for (int n = 0; n < IM_ARRAYSIZE(opened); n++)
                    if (opened[n] && BBZGUI::BeginTabItem(names[n], &opened[n], BBZGUITabItemFlags_None))
                    {
                        BBZGUI::Text("This is the %s tab!", names[n]);
                        if (n & 1)
                            BBZGUI::Text("I am an odd tab.");
                        BBZGUI::EndTabItem();
                    }
                BBZGUI::EndTabBar();
            }
            BBZGUI::Separator();
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Tabs/TabItemButton & Leading-Trailing flags");
        if (BBZGUI::TreeNode("TabItemButton & Leading/Trailing flags"))
        {
            static ImVector<int> active_tabs;
            static int next_tab_id = 0;
            if (next_tab_id == 0) // Initialize with some default tabs
                for (int i = 0; i < 3; i++)
                    active_tabs.push_back(next_tab_id++);

            // TabItemButton() and Leading/Trailing flags are distinct features which we will demo together.
            // (It is possible to submit regular tabs with Leading/Trailing flags, or TabItemButton tabs without Leading/Trailing flags...
            // but they tend to make more sense together)
            static bool show_leading_button = true;
            static bool show_trailing_button = true;
            BBZGUI::Checkbox("Show Leading TabItemButton()", &show_leading_button);
            BBZGUI::Checkbox("Show Trailing TabItemButton()", &show_trailing_button);

            // Expose some other flags which are useful to showcase how they interact with Leading/Trailing tabs
            static BBZGUITabBarFlags tab_bar_flags = BBZGUITabBarFlags_AutoSelectNewTabs | BBZGUITabBarFlags_Reorderable | BBZGUITabBarFlags_FittingPolicyResizeDown;
            BBZGUI::CheckboxFlags("BBZGUITabBarFlags_TabListPopupButton", &tab_bar_flags, BBZGUITabBarFlags_TabListPopupButton);
            if (BBZGUI::CheckboxFlags("BBZGUITabBarFlags_FittingPolicyResizeDown", &tab_bar_flags, BBZGUITabBarFlags_FittingPolicyResizeDown))
                tab_bar_flags &= ~(BBZGUITabBarFlags_FittingPolicyMask_ ^ BBZGUITabBarFlags_FittingPolicyResizeDown);
            if (BBZGUI::CheckboxFlags("BBZGUITabBarFlags_FittingPolicyScroll", &tab_bar_flags, BBZGUITabBarFlags_FittingPolicyScroll))
                tab_bar_flags &= ~(BBZGUITabBarFlags_FittingPolicyMask_ ^ BBZGUITabBarFlags_FittingPolicyScroll);

            if (BBZGUI::BeginTabBar("MyTabBar", tab_bar_flags))
            {
                // Demo a Leading TabItemButton(): click the "?" button to open a menu
                if (show_leading_button)
                    if (BBZGUI::TabItemButton("?", BBZGUITabItemFlags_Leading | BBZGUITabItemFlags_NoTooltip))
                        BBZGUI::OpenPopup("MyHelpMenu");
                if (BBZGUI::BeginPopup("MyHelpMenu"))
                {
                    BBZGUI::Selectable("Hello!");
                    BBZGUI::EndPopup();
                }

                // Demo Trailing Tabs: click the "+" button to add a new tab.
                // (In your app you may want to use a font icon instead of the "+")
                // We submit it before the regular tabs, but thanks to the BBZGUITabItemFlags_Trailing flag it will always appear at the end.
                if (show_trailing_button)
                    if (BBZGUI::TabItemButton("+", BBZGUITabItemFlags_Trailing | BBZGUITabItemFlags_NoTooltip))
                        active_tabs.push_back(next_tab_id++); // Add new tab

                // Submit our regular tabs
                for (int n = 0; n < active_tabs.Size; )
                {
                    bool open = true;
                    char name[16];
                    snprintf(name, IM_ARRAYSIZE(name), "%04d", active_tabs[n]);
                    if (BBZGUI::BeginTabItem(name, &open, BBZGUITabItemFlags_None))
                    {
                        BBZGUI::Text("This is the %s tab!", name);
                        BBZGUI::EndTabItem();
                    }

                    if (!open)
                        active_tabs.erase(active_tabs.Data + n);
                    else
                        n++;
                }

                BBZGUI::EndTabBar();
            }
            BBZGUI::Separator();
            BBZGUI::TreePop();
        }
        BBZGUI::TreePop();
    }

    // Plot/Graph widgets are not very good.
    // Consider using a third-party library such as ImPlot: https://github.com/epezent/implot
    // (see others https://github.com/ocornut/imgui/wiki/Useful-Extensions)
    IMGUI_DEMO_MARKER("Widgets/Plotting");
    if (BBZGUI::TreeNode("Plotting"))
    {
        static bool animate = true;
        BBZGUI::Checkbox("Animate", &animate);

        // Plot as lines and plot as histogram
        static float arr[] = { 0.6f, 0.1f, 1.0f, 0.5f, 0.92f, 0.1f, 0.2f };
        BBZGUI::PlotLines("Frame Times", arr, IM_ARRAYSIZE(arr));
        BBZGUI::PlotHistogram("Histogram", arr, IM_ARRAYSIZE(arr), 0, NULL, 0.0f, 1.0f, ImVec2(0, 80.0f));
        //BBZGUI::SameLine(); HelpMarker("Consider using ImPlot instead!");

        // Fill an array of contiguous float values to plot
        // Tip: If your float aren't contiguous but part of a structure, you can pass a pointer to your first float
        // and the sizeof() of your structure in the "stride" parameter.
        static float values[90] = {};
        static int values_offset = 0;
        static double refresh_time = 0.0;
        if (!animate || refresh_time == 0.0)
            refresh_time = BBZGUI::GetTime();
        while (refresh_time < BBZGUI::GetTime()) // Create data at fixed 60 Hz rate for the demo
        {
            static float phase = 0.0f;
            values[values_offset] = cosf(phase);
            values_offset = (values_offset + 1) % IM_ARRAYSIZE(values);
            phase += 0.10f * values_offset;
            refresh_time += 1.0f / 60.0f;
        }

        // Plots can display overlay texts
        // (in this example, we will display an average value)
        {
            float average = 0.0f;
            for (int n = 0; n < IM_ARRAYSIZE(values); n++)
                average += values[n];
            average /= (float)IM_ARRAYSIZE(values);
            char overlay[32];
            sprintf(overlay, "avg %f", average);
            BBZGUI::PlotLines("Lines", values, IM_ARRAYSIZE(values), values_offset, overlay, -1.0f, 1.0f, ImVec2(0, 80.0f));
        }

        // Use functions to generate output
        // FIXME: This is actually VERY awkward because current plot API only pass in indices.
        // We probably want an API passing floats and user provide sample rate/count.
        struct Funcs
        {
            static float Sin(void*, int i) { return sinf(i * 0.1f); }
            static float Saw(void*, int i) { return (i & 1) ? 1.0f : -1.0f; }
        };
        static int func_type = 0, display_count = 70;
        BBZGUI::SeparatorText("Functions");
        BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 8);
        BBZGUI::Combo("func", &func_type, "Sin\0Saw\0");
        BBZGUI::SameLine();
        BBZGUI::SliderInt("Sample count", &display_count, 1, 400);
        float (*func)(void*, int) = (func_type == 0) ? Funcs::Sin : Funcs::Saw;
        BBZGUI::PlotLines("Lines##2", func, NULL, display_count, 0, NULL, -1.0f, 1.0f, ImVec2(0, 80));
        BBZGUI::PlotHistogram("Histogram##2", func, NULL, display_count, 0, NULL, -1.0f, 1.0f, ImVec2(0, 80));
        BBZGUI::Separator();

        BBZGUI::Text("Need better plotting and graphing? Consider using ImPlot:");
        BBZGUI::TextLinkOpenURL("https://github.com/epezent/implot");
        BBZGUI::Separator();

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Progress Bars");
    if (BBZGUI::TreeNode("Progress Bars"))
    {
        // Animate a simple progress bar
        static float progress = 0.0f, progress_dir = 1.0f;
        progress += progress_dir * 0.4f * BBZGUI::GetIO().DeltaTime;
        if (progress >= +1.1f) { progress = +1.1f; progress_dir *= -1.0f; }
        if (progress <= -0.1f) { progress = -0.1f; progress_dir *= -1.0f; }

        // Typically we would use ImVec2(-1.0f,0.0f) or ImVec2(-FLT_MIN,0.0f) to use all available width,
        // or ImVec2(width,0.0f) for a specified width. ImVec2(0.0f,0.0f) uses ItemWidth.
        BBZGUI::ProgressBar(progress, ImVec2(0.0f, 0.0f));
        BBZGUI::SameLine(0.0f, BBZGUI::GetStyle().ItemInnerSpacing.x);
        BBZGUI::Text("Progress Bar");

        float progress_saturated = IM_CLAMP(progress, 0.0f, 1.0f);
        char buf[32];
        sprintf(buf, "%d/%d", (int)(progress_saturated * 1753), 1753);
        BBZGUI::ProgressBar(progress, ImVec2(0.f, 0.f), buf);

        // Pass an animated negative value, e.g. -1.0f * (float)BBZGUI::GetTime() is the recommended value.
        // Adjust the factor if you want to adjust the animation speed.
        BBZGUI::ProgressBar(-1.0f * (float)BBZGUI::GetTime(), ImVec2(0.0f, 0.0f), "Searching..");
        BBZGUI::SameLine(0.0f, BBZGUI::GetStyle().ItemInnerSpacing.x);
        BBZGUI::Text("Indeterminate");

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Color");
    if (BBZGUI::TreeNode("Color/Picker Widgets"))
    {
        static ImVec4 color = ImVec4(114.0f / 255.0f, 144.0f / 255.0f, 154.0f / 255.0f, 200.0f / 255.0f);

        static bool alpha_preview = true;
        static bool alpha_half_preview = false;
        static bool drag_and_drop = true;
        static bool options_menu = true;
        static bool hdr = false;
        BBZGUI::SeparatorText("Options");
        BBZGUI::Checkbox("With Alpha Preview", &alpha_preview);
        BBZGUI::Checkbox("With Half Alpha Preview", &alpha_half_preview);
        BBZGUI::Checkbox("With Drag and Drop", &drag_and_drop);
        BBZGUI::Checkbox("With Options Menu", &options_menu); BBZGUI::SameLine(); HelpMarker("Right-click on the individual color widget to show options.");
        BBZGUI::Checkbox("With HDR", &hdr); BBZGUI::SameLine(); HelpMarker("Currently all this does is to lift the 0..1 limits on dragging widgets.");
        BBZGUIColorEditFlags misc_flags = (hdr ? BBZGUIColorEditFlags_HDR : 0) | (drag_and_drop ? 0 : BBZGUIColorEditFlags_NoDragDrop) | (alpha_half_preview ? BBZGUIColorEditFlags_AlphaPreviewHalf : (alpha_preview ? BBZGUIColorEditFlags_AlphaPreview : 0)) | (options_menu ? 0 : BBZGUIColorEditFlags_NoOptions);

        IMGUI_DEMO_MARKER("Widgets/Color/ColorEdit");
        BBZGUI::SeparatorText("Inline color editor");
        BBZGUI::Text("Color widget:");
        BBZGUI::SameLine(); HelpMarker(
            "Click on the color square to open a color picker.\n"
            "CTRL+click on individual component to input value.\n");
        BBZGUI::ColorEdit3("MyColor##1", (float*)&color, misc_flags);

        IMGUI_DEMO_MARKER("Widgets/Color/ColorEdit (HSV, with Alpha)");
        BBZGUI::Text("Color widget HSV with Alpha:");
        BBZGUI::ColorEdit4("MyColor##2", (float*)&color, BBZGUIColorEditFlags_DisplayHSV | misc_flags);

        IMGUI_DEMO_MARKER("Widgets/Color/ColorEdit (float display)");
        BBZGUI::Text("Color widget with Float Display:");
        BBZGUI::ColorEdit4("MyColor##2f", (float*)&color, BBZGUIColorEditFlags_Float | misc_flags);

        IMGUI_DEMO_MARKER("Widgets/Color/ColorButton (with Picker)");
        BBZGUI::Text("Color button with Picker:");
        BBZGUI::SameLine(); HelpMarker(
            "With the BBZGUIColorEditFlags_NoInputs flag you can hide all the slider/text inputs.\n"
            "With the BBZGUIColorEditFlags_NoLabel flag you can pass a non-empty label which will only "
            "be used for the tooltip and picker popup.");
        BBZGUI::ColorEdit4("MyColor##3", (float*)&color, BBZGUIColorEditFlags_NoInputs | BBZGUIColorEditFlags_NoLabel | misc_flags);

        IMGUI_DEMO_MARKER("Widgets/Color/ColorButton (with custom Picker popup)");
        BBZGUI::Text("Color button with Custom Picker Popup:");

        // Generate a default palette. The palette will persist and can be edited.
        static bool saved_palette_init = true;
        static ImVec4 saved_palette[32] = {};
        if (saved_palette_init)
        {
            for (int n = 0; n < IM_ARRAYSIZE(saved_palette); n++)
            {
                BBZGUI::ColorConvertHSVtoRGB(n / 31.0f, 0.8f, 0.8f,
                    saved_palette[n].x, saved_palette[n].y, saved_palette[n].z);
                saved_palette[n].w = 1.0f; // Alpha
            }
            saved_palette_init = false;
        }

        static ImVec4 backup_color;
        bool open_popup = BBZGUI::ColorButton("MyColor##3b", color, misc_flags);
        BBZGUI::SameLine(0, BBZGUI::GetStyle().ItemInnerSpacing.x);
        open_popup |= BBZGUI::Button("Palette");
        if (open_popup)
        {
            BBZGUI::OpenPopup("mypicker");
            backup_color = color;
        }
        if (BBZGUI::BeginPopup("mypicker"))
        {
            BBZGUI::Text("MY CUSTOM COLOR PICKER WITH AN AMAZING PALETTE!");
            BBZGUI::Separator();
            BBZGUI::ColorPicker4("##picker", (float*)&color, misc_flags | BBZGUIColorEditFlags_NoSidePreview | BBZGUIColorEditFlags_NoSmallPreview);
            BBZGUI::SameLine();

            BBZGUI::BeginGroup(); // Lock X position
            BBZGUI::Text("Current");
            BBZGUI::ColorButton("##current", color, BBZGUIColorEditFlags_NoPicker | BBZGUIColorEditFlags_AlphaPreviewHalf, ImVec2(60, 40));
            BBZGUI::Text("Previous");
            if (BBZGUI::ColorButton("##previous", backup_color, BBZGUIColorEditFlags_NoPicker | BBZGUIColorEditFlags_AlphaPreviewHalf, ImVec2(60, 40)))
                color = backup_color;
            BBZGUI::Separator();
            BBZGUI::Text("Palette");
            for (int n = 0; n < IM_ARRAYSIZE(saved_palette); n++)
            {
                BBZGUI::PushID(n);
                if ((n % 8) != 0)
                    BBZGUI::SameLine(0.0f, BBZGUI::GetStyle().ItemSpacing.y);

                BBZGUIColorEditFlags palette_button_flags = BBZGUIColorEditFlags_NoAlpha | BBZGUIColorEditFlags_NoPicker | BBZGUIColorEditFlags_NoTooltip;
                if (BBZGUI::ColorButton("##palette", saved_palette[n], palette_button_flags, ImVec2(20, 20)))
                    color = ImVec4(saved_palette[n].x, saved_palette[n].y, saved_palette[n].z, color.w); // Preserve alpha!

                // Allow user to drop colors into each palette entry. Note that ColorButton() is already a
                // drag source by default, unless specifying the BBZGUIColorEditFlags_NoDragDrop flag.
                if (BBZGUI::BeginDragDropTarget())
                {
                    if (const BBZGUIPayload* payload = BBZGUI::AcceptDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_3F))
                        memcpy((float*)&saved_palette[n], payload->Data, sizeof(float) * 3);
                    if (const BBZGUIPayload* payload = BBZGUI::AcceptDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_4F))
                        memcpy((float*)&saved_palette[n], payload->Data, sizeof(float) * 4);
                    BBZGUI::EndDragDropTarget();
                }

                BBZGUI::PopID();
            }
            BBZGUI::EndGroup();
            BBZGUI::EndPopup();
        }

        IMGUI_DEMO_MARKER("Widgets/Color/ColorButton (simple)");
        BBZGUI::Text("Color button only:");
        static bool no_border = false;
        BBZGUI::Checkbox("BBZGUIColorEditFlags_NoBorder", &no_border);
        BBZGUI::ColorButton("MyColor##3c", *(ImVec4*)&color, misc_flags | (no_border ? BBZGUIColorEditFlags_NoBorder : 0), ImVec2(80, 80));

        IMGUI_DEMO_MARKER("Widgets/Color/ColorPicker");
        BBZGUI::SeparatorText("Color picker");
        static bool alpha = true;
        static bool alpha_bar = true;
        static bool side_preview = true;
        static bool ref_color = false;
        static ImVec4 ref_color_v(1.0f, 0.0f, 1.0f, 0.5f);
        static int display_mode = 0;
        static int picker_mode = 0;
        BBZGUI::Checkbox("With Alpha", &alpha);
        BBZGUI::Checkbox("With Alpha Bar", &alpha_bar);
        BBZGUI::Checkbox("With Side Preview", &side_preview);
        if (side_preview)
        {
            BBZGUI::SameLine();
            BBZGUI::Checkbox("With Ref Color", &ref_color);
            if (ref_color)
            {
                BBZGUI::SameLine();
                BBZGUI::ColorEdit4("##RefColor", &ref_color_v.x, BBZGUIColorEditFlags_NoInputs | misc_flags);
            }
        }
        BBZGUI::Combo("Display Mode", &display_mode, "Auto/Current\0None\0RGB Only\0HSV Only\0Hex Only\0");
        BBZGUI::SameLine(); HelpMarker(
            "ColorEdit defaults to displaying RGB inputs if you don't specify a display mode, "
            "but the user can change it with a right-click on those inputs.\n\nColorPicker defaults to displaying RGB+HSV+Hex "
            "if you don't specify a display mode.\n\nYou can change the defaults using SetColorEditOptions().");
        BBZGUI::SameLine(); HelpMarker("When not specified explicitly (Auto/Current mode), user can right-click the picker to change mode.");
        BBZGUIColorEditFlags flags = misc_flags;
        if (!alpha)            flags |= BBZGUIColorEditFlags_NoAlpha;        // This is by default if you call ColorPicker3() instead of ColorPicker4()
        if (alpha_bar)         flags |= BBZGUIColorEditFlags_AlphaBar;
        if (!side_preview)     flags |= BBZGUIColorEditFlags_NoSidePreview;
        if (picker_mode == 1)  flags |= BBZGUIColorEditFlags_PickerHueBar;
        if (picker_mode == 2)  flags |= BBZGUIColorEditFlags_PickerHueWheel;
        if (display_mode == 1) flags |= BBZGUIColorEditFlags_NoInputs;       // Disable all RGB/HSV/Hex displays
        if (display_mode == 2) flags |= BBZGUIColorEditFlags_DisplayRGB;     // Override display mode
        if (display_mode == 3) flags |= BBZGUIColorEditFlags_DisplayHSV;
        if (display_mode == 4) flags |= BBZGUIColorEditFlags_DisplayHex;
        BBZGUI::ColorPicker4("MyColor##4", (float*)&color, flags, ref_color ? &ref_color_v.x : NULL);

        BBZGUI::Text("Set defaults in code:");
        BBZGUI::SameLine(); HelpMarker(
            "SetColorEditOptions() is designed to allow you to set boot-time default.\n"
            "We don't have Push/Pop functions because you can force options on a per-widget basis if needed,"
            "and the user can change non-forced ones with the options menu.\nWe don't have a getter to avoid"
            "encouraging you to persistently save values that aren't forward-compatible.");
        if (BBZGUI::Button("Default: Uint8 + HSV + Hue Bar"))
            BBZGUI::SetColorEditOptions(BBZGUIColorEditFlags_Uint8 | BBZGUIColorEditFlags_DisplayHSV | BBZGUIColorEditFlags_PickerHueBar);
        if (BBZGUI::Button("Default: Float + HDR + Hue Wheel"))
            BBZGUI::SetColorEditOptions(BBZGUIColorEditFlags_Float | BBZGUIColorEditFlags_HDR | BBZGUIColorEditFlags_PickerHueWheel);

        // Always display a small version of both types of pickers
        // (that's in order to make it more visible in the demo to people who are skimming quickly through it)
        BBZGUI::Text("Both types:");
        float w = (BBZGUI::GetContentRegionAvail().x - BBZGUI::GetStyle().ItemSpacing.y) * 0.40f;
        BBZGUI::SetNextItemWidth(w);
        BBZGUI::ColorPicker3("##MyColor##5", (float*)&color, BBZGUIColorEditFlags_PickerHueBar | BBZGUIColorEditFlags_NoSidePreview | BBZGUIColorEditFlags_NoInputs | BBZGUIColorEditFlags_NoAlpha);
        BBZGUI::SameLine();
        BBZGUI::SetNextItemWidth(w);
        BBZGUI::ColorPicker3("##MyColor##6", (float*)&color, BBZGUIColorEditFlags_PickerHueWheel | BBZGUIColorEditFlags_NoSidePreview | BBZGUIColorEditFlags_NoInputs | BBZGUIColorEditFlags_NoAlpha);

        // HSV encoded support (to avoid RGB<>HSV round trips and singularities when S==0 or V==0)
        static ImVec4 color_hsv(0.23f, 1.0f, 1.0f, 1.0f); // Stored as HSV!
        BBZGUI::Spacing();
        BBZGUI::Text("HSV encoded colors");
        BBZGUI::SameLine(); HelpMarker(
            "By default, colors are given to ColorEdit and ColorPicker in RGB, but BBZGUIColorEditFlags_InputHSV"
            "allows you to store colors as HSV and pass them to ColorEdit and ColorPicker as HSV. This comes with the"
            "added benefit that you can manipulate hue values with the picker even when saturation or value are zero.");
        BBZGUI::Text("Color widget with InputHSV:");
        BBZGUI::ColorEdit4("HSV shown as RGB##1", (float*)&color_hsv, BBZGUIColorEditFlags_DisplayRGB | BBZGUIColorEditFlags_InputHSV | BBZGUIColorEditFlags_Float);
        BBZGUI::ColorEdit4("HSV shown as HSV##1", (float*)&color_hsv, BBZGUIColorEditFlags_DisplayHSV | BBZGUIColorEditFlags_InputHSV | BBZGUIColorEditFlags_Float);
        BBZGUI::DragFloat4("Raw HSV values", (float*)&color_hsv, 0.01f, 0.0f, 1.0f);

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Drag and Slider Flags");
    if (BBZGUI::TreeNode("Drag/Slider Flags"))
    {
        // Demonstrate using advanced flags for DragXXX and SliderXXX functions. Note that the flags are the same!
        static BBZGUISliderFlags flags = BBZGUISliderFlags_None;
        BBZGUI::CheckboxFlags("BBZGUISliderFlags_AlwaysClamp", &flags, BBZGUISliderFlags_AlwaysClamp);
        BBZGUI::CheckboxFlags("BBZGUISliderFlags_ClampOnInput", &flags, BBZGUISliderFlags_ClampOnInput);
        BBZGUI::SameLine(); HelpMarker("Clamp value to min/max bounds when input manually with CTRL+Click. By default CTRL+Click allows going out of bounds.");
        BBZGUI::CheckboxFlags("BBZGUISliderFlags_ClampZeroRange", &flags, BBZGUISliderFlags_ClampZeroRange);
        BBZGUI::SameLine(); HelpMarker("Clamp even if min==max==0.0f. Otherwise DragXXX functions don't clamp.");
        BBZGUI::CheckboxFlags("BBZGUISliderFlags_Logarithmic", &flags, BBZGUISliderFlags_Logarithmic);
        BBZGUI::SameLine(); HelpMarker("Enable logarithmic editing (more precision for small values).");
        BBZGUI::CheckboxFlags("BBZGUISliderFlags_NoRoundToFormat", &flags, BBZGUISliderFlags_NoRoundToFormat);
        BBZGUI::SameLine(); HelpMarker("Disable rounding underlying value to match precision of the format string (e.g. %.3f values are rounded to those 3 digits).");
        BBZGUI::CheckboxFlags("BBZGUISliderFlags_NoInput", &flags, BBZGUISliderFlags_NoInput);
        BBZGUI::SameLine(); HelpMarker("Disable CTRL+Click or Enter key allowing to input text directly into the widget.");
        BBZGUI::CheckboxFlags("BBZGUISliderFlags_WrapAround", &flags, BBZGUISliderFlags_WrapAround);
        BBZGUI::SameLine(); HelpMarker("Enable wrapping around from max to min and from min to max (only supported by DragXXX() functions)");

        // Drags
        static float drag_f = 0.5f;
        static int drag_i = 50;
        BBZGUI::Text("Underlying float value: %f", drag_f);
        BBZGUI::DragFloat("DragFloat (0 -> 1)", &drag_f, 0.005f, 0.0f, 1.0f, "%.3f", flags);
        BBZGUI::DragFloat("DragFloat (0 -> +inf)", &drag_f, 0.005f, 0.0f, FLT_MAX, "%.3f", flags);
        BBZGUI::DragFloat("DragFloat (-inf -> 1)", &drag_f, 0.005f, -FLT_MAX, 1.0f, "%.3f", flags);
        BBZGUI::DragFloat("DragFloat (-inf -> +inf)", &drag_f, 0.005f, -FLT_MAX, +FLT_MAX, "%.3f", flags);
        //BBZGUI::DragFloat("DragFloat (0 -> 0)", &drag_f, 0.005f, 0.0f, 0.0f, "%.3f", flags);           // To test ClampZeroRange
        //BBZGUI::DragFloat("DragFloat (100 -> 100)", &drag_f, 0.005f, 100.0f, 100.0f, "%.3f", flags);
        BBZGUI::DragInt("DragInt (0 -> 100)", &drag_i, 0.5f, 0, 100, "%d", flags);

        // Sliders
        static float slider_f = 0.5f;
        static int slider_i = 50;
        const BBZGUISliderFlags flags_for_sliders = flags & ~BBZGUISliderFlags_WrapAround;
        BBZGUI::Text("Underlying float value: %f", slider_f);
        BBZGUI::SliderFloat("SliderFloat (0 -> 1)", &slider_f, 0.0f, 1.0f, "%.3f", flags_for_sliders);
        BBZGUI::SliderInt("SliderInt (0 -> 100)", &slider_i, 0, 100, "%d", flags_for_sliders);

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Range Widgets");
    if (BBZGUI::TreeNode("Range Widgets"))
    {
        static float begin = 10, end = 90;
        static int begin_i = 100, end_i = 1000;
        BBZGUI::DragFloatRange2("range float", &begin, &end, 0.25f, 0.0f, 100.0f, "Min: %.1f %%", "Max: %.1f %%", BBZGUISliderFlags_AlwaysClamp);
        BBZGUI::DragIntRange2("range int", &begin_i, &end_i, 5, 0, 1000, "Min: %d units", "Max: %d units");
        BBZGUI::DragIntRange2("range int (no bounds)", &begin_i, &end_i, 5, 0, 0, "Min: %d units", "Max: %d units");
        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Data Types");
    if (BBZGUI::TreeNode("Data Types"))
    {
        // DragScalar/InputScalar/SliderScalar functions allow various data types
        // - signed/unsigned
        // - 8/16/32/64-bits
        // - integer/float/double
        // To avoid polluting the public API with all possible combinations, we use the BBZGUIDataType enum
        // to pass the type, and passing all arguments by pointer.
        // This is the reason the test code below creates local variables to hold "zero" "one" etc. for each type.
        // In practice, if you frequently use a given type that is not covered by the normal API entry points,
        // you can wrap it yourself inside a 1 line function which can take typed argument as value instead of void*,
        // and then pass their address to the generic function. For example:
        //   bool MySliderU64(const char *label, u64* value, u64 min = 0, u64 max = 0, const char* format = "%lld")
        //   {
        //      return SliderScalar(label, BBZGUIDataType_U64, value, &min, &max, format);
        //   }

        // Setup limits (as helper variables so we can take their address, as explained above)
        // Note: SliderScalar() functions have a maximum usable range of half the natural type maximum, hence the /2.
        #ifndef LLONG_MIN
        ImS64 LLONG_MIN = -9223372036854775807LL - 1;
        ImS64 LLONG_MAX = 9223372036854775807LL;
        ImU64 ULLONG_MAX = (2ULL * 9223372036854775807LL + 1);
        #endif
        const char    s8_zero  = 0,   s8_one  = 1,   s8_fifty  = 50, s8_min  = -128,        s8_max = 127;
        const ImU8    u8_zero  = 0,   u8_one  = 1,   u8_fifty  = 50, u8_min  = 0,           u8_max = 255;
        const short   s16_zero = 0,   s16_one = 1,   s16_fifty = 50, s16_min = -32768,      s16_max = 32767;
        const ImU16   u16_zero = 0,   u16_one = 1,   u16_fifty = 50, u16_min = 0,           u16_max = 65535;
        const ImS32   s32_zero = 0,   s32_one = 1,   s32_fifty = 50, s32_min = INT_MIN/2,   s32_max = INT_MAX/2,    s32_hi_a = INT_MAX/2 - 100,    s32_hi_b = INT_MAX/2;
        const ImU32   u32_zero = 0,   u32_one = 1,   u32_fifty = 50, u32_min = 0,           u32_max = UINT_MAX/2,   u32_hi_a = UINT_MAX/2 - 100,   u32_hi_b = UINT_MAX/2;
        const ImS64   s64_zero = 0,   s64_one = 1,   s64_fifty = 50, s64_min = LLONG_MIN/2, s64_max = LLONG_MAX/2,  s64_hi_a = LLONG_MAX/2 - 100,  s64_hi_b = LLONG_MAX/2;
        const ImU64   u64_zero = 0,   u64_one = 1,   u64_fifty = 50, u64_min = 0,           u64_max = ULLONG_MAX/2, u64_hi_a = ULLONG_MAX/2 - 100, u64_hi_b = ULLONG_MAX/2;
        const float   f32_zero = 0.f, f32_one = 1.f, f32_lo_a = -10000000000.0f, f32_hi_a = +10000000000.0f;
        const double  f64_zero = 0.,  f64_one = 1.,  f64_lo_a = -1000000000000000.0, f64_hi_a = +1000000000000000.0;

        // State
        static char   s8_v  = 127;
        static ImU8   u8_v  = 255;
        static short  s16_v = 32767;
        static ImU16  u16_v = 65535;
        static ImS32  s32_v = -1;
        static ImU32  u32_v = (ImU32)-1;
        static ImS64  s64_v = -1;
        static ImU64  u64_v = (ImU64)-1;
        static float  f32_v = 0.123f;
        static double f64_v = 90000.01234567890123456789;

        const float drag_speed = 0.2f;
        static bool drag_clamp = false;
        IMGUI_DEMO_MARKER("Widgets/Data Types/Drags");
        BBZGUI::SeparatorText("Drags");
        BBZGUI::Checkbox("Clamp integers to 0..50", &drag_clamp);
        BBZGUI::SameLine(); HelpMarker(
            "As with every widget in dear imgui, we never modify values unless there is a user interaction.\n"
            "You can override the clamping limits by using CTRL+Click to input a value.");
        BBZGUI::DragScalar("drag s8",        BBZGUIDataType_S8,     &s8_v,  drag_speed, drag_clamp ? &s8_zero  : NULL, drag_clamp ? &s8_fifty  : NULL);
        BBZGUI::DragScalar("drag u8",        BBZGUIDataType_U8,     &u8_v,  drag_speed, drag_clamp ? &u8_zero  : NULL, drag_clamp ? &u8_fifty  : NULL, "%u ms");
        BBZGUI::DragScalar("drag s16",       BBZGUIDataType_S16,    &s16_v, drag_speed, drag_clamp ? &s16_zero : NULL, drag_clamp ? &s16_fifty : NULL);
        BBZGUI::DragScalar("drag u16",       BBZGUIDataType_U16,    &u16_v, drag_speed, drag_clamp ? &u16_zero : NULL, drag_clamp ? &u16_fifty : NULL, "%u ms");
        BBZGUI::DragScalar("drag s32",       BBZGUIDataType_S32,    &s32_v, drag_speed, drag_clamp ? &s32_zero : NULL, drag_clamp ? &s32_fifty : NULL);
        BBZGUI::DragScalar("drag s32 hex",   BBZGUIDataType_S32,    &s32_v, drag_speed, drag_clamp ? &s32_zero : NULL, drag_clamp ? &s32_fifty : NULL, "0x%08X");
        BBZGUI::DragScalar("drag u32",       BBZGUIDataType_U32,    &u32_v, drag_speed, drag_clamp ? &u32_zero : NULL, drag_clamp ? &u32_fifty : NULL, "%u ms");
        BBZGUI::DragScalar("drag s64",       BBZGUIDataType_S64,    &s64_v, drag_speed, drag_clamp ? &s64_zero : NULL, drag_clamp ? &s64_fifty : NULL);
        BBZGUI::DragScalar("drag u64",       BBZGUIDataType_U64,    &u64_v, drag_speed, drag_clamp ? &u64_zero : NULL, drag_clamp ? &u64_fifty : NULL);
        BBZGUI::DragScalar("drag float",     BBZGUIDataType_Float,  &f32_v, 0.005f,  &f32_zero, &f32_one, "%f");
        BBZGUI::DragScalar("drag float log", BBZGUIDataType_Float,  &f32_v, 0.005f,  &f32_zero, &f32_one, "%f", BBZGUISliderFlags_Logarithmic);
        BBZGUI::DragScalar("drag double",    BBZGUIDataType_Double, &f64_v, 0.0005f, &f64_zero, NULL,     "%.10f grams");
        BBZGUI::DragScalar("drag double log",BBZGUIDataType_Double, &f64_v, 0.0005f, &f64_zero, &f64_one, "0 < %.10f < 1", BBZGUISliderFlags_Logarithmic);

        IMGUI_DEMO_MARKER("Widgets/Data Types/Sliders");
        BBZGUI::SeparatorText("Sliders");
        BBZGUI::SliderScalar("slider s8 full",       BBZGUIDataType_S8,     &s8_v,  &s8_min,   &s8_max,   "%d");
        BBZGUI::SliderScalar("slider u8 full",       BBZGUIDataType_U8,     &u8_v,  &u8_min,   &u8_max,   "%u");
        BBZGUI::SliderScalar("slider s16 full",      BBZGUIDataType_S16,    &s16_v, &s16_min,  &s16_max,  "%d");
        BBZGUI::SliderScalar("slider u16 full",      BBZGUIDataType_U16,    &u16_v, &u16_min,  &u16_max,  "%u");
        BBZGUI::SliderScalar("slider s32 low",       BBZGUIDataType_S32,    &s32_v, &s32_zero, &s32_fifty,"%d");
        BBZGUI::SliderScalar("slider s32 high",      BBZGUIDataType_S32,    &s32_v, &s32_hi_a, &s32_hi_b, "%d");
        BBZGUI::SliderScalar("slider s32 full",      BBZGUIDataType_S32,    &s32_v, &s32_min,  &s32_max,  "%d");
        BBZGUI::SliderScalar("slider s32 hex",       BBZGUIDataType_S32,    &s32_v, &s32_zero, &s32_fifty, "0x%04X");
        BBZGUI::SliderScalar("slider u32 low",       BBZGUIDataType_U32,    &u32_v, &u32_zero, &u32_fifty,"%u");
        BBZGUI::SliderScalar("slider u32 high",      BBZGUIDataType_U32,    &u32_v, &u32_hi_a, &u32_hi_b, "%u");
        BBZGUI::SliderScalar("slider u32 full",      BBZGUIDataType_U32,    &u32_v, &u32_min,  &u32_max,  "%u");
        BBZGUI::SliderScalar("slider s64 low",       BBZGUIDataType_S64,    &s64_v, &s64_zero, &s64_fifty,"%" PRId64);
        BBZGUI::SliderScalar("slider s64 high",      BBZGUIDataType_S64,    &s64_v, &s64_hi_a, &s64_hi_b, "%" PRId64);
        BBZGUI::SliderScalar("slider s64 full",      BBZGUIDataType_S64,    &s64_v, &s64_min,  &s64_max,  "%" PRId64);
        BBZGUI::SliderScalar("slider u64 low",       BBZGUIDataType_U64,    &u64_v, &u64_zero, &u64_fifty,"%" PRIu64 " ms");
        BBZGUI::SliderScalar("slider u64 high",      BBZGUIDataType_U64,    &u64_v, &u64_hi_a, &u64_hi_b, "%" PRIu64 " ms");
        BBZGUI::SliderScalar("slider u64 full",      BBZGUIDataType_U64,    &u64_v, &u64_min,  &u64_max,  "%" PRIu64 " ms");
        BBZGUI::SliderScalar("slider float low",     BBZGUIDataType_Float,  &f32_v, &f32_zero, &f32_one);
        BBZGUI::SliderScalar("slider float low log", BBZGUIDataType_Float,  &f32_v, &f32_zero, &f32_one,  "%.10f", BBZGUISliderFlags_Logarithmic);
        BBZGUI::SliderScalar("slider float high",    BBZGUIDataType_Float,  &f32_v, &f32_lo_a, &f32_hi_a, "%e");
        BBZGUI::SliderScalar("slider double low",    BBZGUIDataType_Double, &f64_v, &f64_zero, &f64_one,  "%.10f grams");
        BBZGUI::SliderScalar("slider double low log",BBZGUIDataType_Double, &f64_v, &f64_zero, &f64_one,  "%.10f", BBZGUISliderFlags_Logarithmic);
        BBZGUI::SliderScalar("slider double high",   BBZGUIDataType_Double, &f64_v, &f64_lo_a, &f64_hi_a, "%e grams");

        BBZGUI::SeparatorText("Sliders (reverse)");
        BBZGUI::SliderScalar("slider s8 reverse",    BBZGUIDataType_S8,   &s8_v,  &s8_max,    &s8_min,   "%d");
        BBZGUI::SliderScalar("slider u8 reverse",    BBZGUIDataType_U8,   &u8_v,  &u8_max,    &u8_min,   "%u");
        BBZGUI::SliderScalar("slider s32 reverse",   BBZGUIDataType_S32,  &s32_v, &s32_fifty, &s32_zero, "%d");
        BBZGUI::SliderScalar("slider u32 reverse",   BBZGUIDataType_U32,  &u32_v, &u32_fifty, &u32_zero, "%u");
        BBZGUI::SliderScalar("slider s64 reverse",   BBZGUIDataType_S64,  &s64_v, &s64_fifty, &s64_zero, "%" PRId64);
        BBZGUI::SliderScalar("slider u64 reverse",   BBZGUIDataType_U64,  &u64_v, &u64_fifty, &u64_zero, "%" PRIu64 " ms");

        IMGUI_DEMO_MARKER("Widgets/Data Types/Inputs");
        static bool inputs_step = true;
        static BBZGUIInputTextFlags flags = BBZGUIInputTextFlags_None;
        BBZGUI::SeparatorText("Inputs");
        BBZGUI::Checkbox("Show step buttons", &inputs_step);
        BBZGUI::CheckboxFlags("BBZGUIInputTextFlags_ReadOnly", &flags, BBZGUIInputTextFlags_ReadOnly);
        BBZGUI::CheckboxFlags("BBZGUIInputTextFlags_ParseEmptyRefVal", &flags, BBZGUIInputTextFlags_ParseEmptyRefVal);
        BBZGUI::CheckboxFlags("BBZGUIInputTextFlags_DisplayEmptyRefVal", &flags, BBZGUIInputTextFlags_DisplayEmptyRefVal);
        BBZGUI::InputScalar("input s8",      BBZGUIDataType_S8,     &s8_v,  inputs_step ? &s8_one  : NULL, NULL, "%d", flags);
        BBZGUI::InputScalar("input u8",      BBZGUIDataType_U8,     &u8_v,  inputs_step ? &u8_one  : NULL, NULL, "%u", flags);
        BBZGUI::InputScalar("input s16",     BBZGUIDataType_S16,    &s16_v, inputs_step ? &s16_one : NULL, NULL, "%d", flags);
        BBZGUI::InputScalar("input u16",     BBZGUIDataType_U16,    &u16_v, inputs_step ? &u16_one : NULL, NULL, "%u", flags);
        BBZGUI::InputScalar("input s32",     BBZGUIDataType_S32,    &s32_v, inputs_step ? &s32_one : NULL, NULL, "%d", flags);
        BBZGUI::InputScalar("input s32 hex", BBZGUIDataType_S32,    &s32_v, inputs_step ? &s32_one : NULL, NULL, "%04X", flags);
        BBZGUI::InputScalar("input u32",     BBZGUIDataType_U32,    &u32_v, inputs_step ? &u32_one : NULL, NULL, "%u", flags);
        BBZGUI::InputScalar("input u32 hex", BBZGUIDataType_U32,    &u32_v, inputs_step ? &u32_one : NULL, NULL, "%08X", flags);
        BBZGUI::InputScalar("input s64",     BBZGUIDataType_S64,    &s64_v, inputs_step ? &s64_one : NULL, NULL, NULL, flags);
        BBZGUI::InputScalar("input u64",     BBZGUIDataType_U64,    &u64_v, inputs_step ? &u64_one : NULL, NULL, NULL, flags);
        BBZGUI::InputScalar("input float",   BBZGUIDataType_Float,  &f32_v, inputs_step ? &f32_one : NULL, NULL, NULL, flags);
        BBZGUI::InputScalar("input double",  BBZGUIDataType_Double, &f64_v, inputs_step ? &f64_one : NULL, NULL, NULL, flags);

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Multi-component Widgets");
    if (BBZGUI::TreeNode("Multi-component Widgets"))
    {
        static float vec4f[4] = { 0.10f, 0.20f, 0.30f, 0.44f };
        static int vec4i[4] = { 1, 5, 100, 255 };

        BBZGUI::SeparatorText("2-wide");
        BBZGUI::InputFloat2("input float2", vec4f);
        BBZGUI::DragFloat2("drag float2", vec4f, 0.01f, 0.0f, 1.0f);
        BBZGUI::SliderFloat2("slider float2", vec4f, 0.0f, 1.0f);
        BBZGUI::InputInt2("input int2", vec4i);
        BBZGUI::DragInt2("drag int2", vec4i, 1, 0, 255);
        BBZGUI::SliderInt2("slider int2", vec4i, 0, 255);

        BBZGUI::SeparatorText("3-wide");
        BBZGUI::InputFloat3("input float3", vec4f);
        BBZGUI::DragFloat3("drag float3", vec4f, 0.01f, 0.0f, 1.0f);
        BBZGUI::SliderFloat3("slider float3", vec4f, 0.0f, 1.0f);
        BBZGUI::InputInt3("input int3", vec4i);
        BBZGUI::DragInt3("drag int3", vec4i, 1, 0, 255);
        BBZGUI::SliderInt3("slider int3", vec4i, 0, 255);

        BBZGUI::SeparatorText("4-wide");
        BBZGUI::InputFloat4("input float4", vec4f);
        BBZGUI::DragFloat4("drag float4", vec4f, 0.01f, 0.0f, 1.0f);
        BBZGUI::SliderFloat4("slider float4", vec4f, 0.0f, 1.0f);
        BBZGUI::InputInt4("input int4", vec4i);
        BBZGUI::DragInt4("drag int4", vec4i, 1, 0, 255);
        BBZGUI::SliderInt4("slider int4", vec4i, 0, 255);

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Vertical Sliders");
    if (BBZGUI::TreeNode("Vertical Sliders"))
    {
        const float spacing = 4;
        BBZGUI::PushStyleVar(BBZGUIStyleVar_ItemSpacing, ImVec2(spacing, spacing));

        static int int_value = 0;
        BBZGUI::VSliderInt("##int", ImVec2(18, 160), &int_value, 0, 5);
        BBZGUI::SameLine();

        static float values[7] = { 0.0f, 0.60f, 0.35f, 0.9f, 0.70f, 0.20f, 0.0f };
        BBZGUI::PushID("set1");
        for (int i = 0; i < 7; i++)
        {
            if (i > 0) BBZGUI::SameLine();
            BBZGUI::PushID(i);
            BBZGUI::PushStyleColor(BBZGUICol_FrameBg, (ImVec4)ImColor::HSV(i / 7.0f, 0.5f, 0.5f));
            BBZGUI::PushStyleColor(BBZGUICol_FrameBgHovered, (ImVec4)ImColor::HSV(i / 7.0f, 0.6f, 0.5f));
            BBZGUI::PushStyleColor(BBZGUICol_FrameBgActive, (ImVec4)ImColor::HSV(i / 7.0f, 0.7f, 0.5f));
            BBZGUI::PushStyleColor(BBZGUICol_SliderGrab, (ImVec4)ImColor::HSV(i / 7.0f, 0.9f, 0.9f));
            BBZGUI::VSliderFloat("##v", ImVec2(18, 160), &values[i], 0.0f, 1.0f, "");
            if (BBZGUI::IsItemActive() || BBZGUI::IsItemHovered())
                BBZGUI::SetTooltip("%.3f", values[i]);
            BBZGUI::PopStyleColor(4);
            BBZGUI::PopID();
        }
        BBZGUI::PopID();

        BBZGUI::SameLine();
        BBZGUI::PushID("set2");
        static float values2[4] = { 0.20f, 0.80f, 0.40f, 0.25f };
        const int rows = 3;
        const ImVec2 small_slider_size(18, (float)(int)((160.0f - (rows - 1) * spacing) / rows));
        for (int nx = 0; nx < 4; nx++)
        {
            if (nx > 0) BBZGUI::SameLine();
            BBZGUI::BeginGroup();
            for (int ny = 0; ny < rows; ny++)
            {
                BBZGUI::PushID(nx * rows + ny);
                BBZGUI::VSliderFloat("##v", small_slider_size, &values2[nx], 0.0f, 1.0f, "");
                if (BBZGUI::IsItemActive() || BBZGUI::IsItemHovered())
                    BBZGUI::SetTooltip("%.3f", values2[nx]);
                BBZGUI::PopID();
            }
            BBZGUI::EndGroup();
        }
        BBZGUI::PopID();

        BBZGUI::SameLine();
        BBZGUI::PushID("set3");
        for (int i = 0; i < 4; i++)
        {
            if (i > 0) BBZGUI::SameLine();
            BBZGUI::PushID(i);
            BBZGUI::PushStyleVar(BBZGUIStyleVar_GrabMinSize, 40);
            BBZGUI::VSliderFloat("##v", ImVec2(40, 160), &values[i], 0.0f, 1.0f, "%.2f\nsec");
            BBZGUI::PopStyleVar();
            BBZGUI::PopID();
        }
        BBZGUI::PopID();
        BBZGUI::PopStyleVar();
        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Drag and drop");
    if (BBZGUI::TreeNode("Drag and Drop"))
    {
        IMGUI_DEMO_MARKER("Widgets/Drag and drop/Standard widgets");
        if (BBZGUI::TreeNode("Drag and drop in standard widgets"))
        {
            // ColorEdit widgets automatically act as drag source and drag target.
            // They are using standardized payload strings IMGUI_PAYLOAD_TYPE_COLOR_3F and IMGUI_PAYLOAD_TYPE_COLOR_4F
            // to allow your own widgets to use colors in their drag and drop interaction.
            // Also see 'Demo->Widgets->Color/Picker Widgets->Palette' demo.
            HelpMarker("You can drag from the color squares.");
            static float col1[3] = { 1.0f, 0.0f, 0.2f };
            static float col2[4] = { 0.4f, 0.7f, 0.0f, 0.5f };
            BBZGUI::ColorEdit3("color 1", col1);
            BBZGUI::ColorEdit4("color 2", col2);
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Drag and drop/Copy-swap items");
        if (BBZGUI::TreeNode("Drag and drop to copy/swap items"))
        {
            enum Mode
            {
                Mode_Copy,
                Mode_Move,
                Mode_Swap
            };
            static int mode = 0;
            if (BBZGUI::RadioButton("Copy", mode == Mode_Copy)) { mode = Mode_Copy; } BBZGUI::SameLine();
            if (BBZGUI::RadioButton("Move", mode == Mode_Move)) { mode = Mode_Move; } BBZGUI::SameLine();
            if (BBZGUI::RadioButton("Swap", mode == Mode_Swap)) { mode = Mode_Swap; }
            static const char* names[9] =
            {
                "Bobby", "Beatrice", "Betty",
                "Brianna", "Barry", "Bernard",
                "Bibi", "Blaine", "Bryn"
            };
            for (int n = 0; n < IM_ARRAYSIZE(names); n++)
            {
                BBZGUI::PushID(n);
                if ((n % 3) != 0)
                    BBZGUI::SameLine();
                BBZGUI::Button(names[n], ImVec2(60, 60));

                // Our buttons are both drag sources and drag targets here!
                if (BBZGUI::BeginDragDropSource(BBZGUIDragDropFlags_None))
                {
                    // Set payload to carry the index of our item (could be anything)
                    BBZGUI::SetDragDropPayload("DND_DEMO_CELL", &n, sizeof(int));

                    // Display preview (could be anything, e.g. when dragging an image we could decide to display
                    // the filename and a small preview of the image, etc.)
                    if (mode == Mode_Copy) { BBZGUI::Text("Copy %s", names[n]); }
                    if (mode == Mode_Move) { BBZGUI::Text("Move %s", names[n]); }
                    if (mode == Mode_Swap) { BBZGUI::Text("Swap %s", names[n]); }
                    BBZGUI::EndDragDropSource();
                }
                if (BBZGUI::BeginDragDropTarget())
                {
                    if (const BBZGUIPayload* payload = BBZGUI::AcceptDragDropPayload("DND_DEMO_CELL"))
                    {
                        IM_ASSERT(payload->DataSize == sizeof(int));
                        int payload_n = *(const int*)payload->Data;
                        if (mode == Mode_Copy)
                        {
                            names[n] = names[payload_n];
                        }
                        if (mode == Mode_Move)
                        {
                            names[n] = names[payload_n];
                            names[payload_n] = "";
                        }
                        if (mode == Mode_Swap)
                        {
                            const char* tmp = names[n];
                            names[n] = names[payload_n];
                            names[payload_n] = tmp;
                        }
                    }
                    BBZGUI::EndDragDropTarget();
                }
                BBZGUI::PopID();
            }
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Drag and Drop/Drag to reorder items (simple)");
        if (BBZGUI::TreeNode("Drag to reorder items (simple)"))
        {
            // FIXME: there is temporary (usually single-frame) ID Conflict during reordering as a same item may be submitting twice.
            // This code was always slightly faulty but in a way which was not easily noticeable.
            // Until we fix this, enable BBZGUIItemFlags_AllowDuplicateId to disable detecting the issue.
            BBZGUI::PushItemFlag(BBZGUIItemFlags_AllowDuplicateId, true);

            // Simple reordering
            HelpMarker(
                "We don't use the drag and drop api at all here! "
                "Instead we query when the item is held but not hovered, and order items accordingly.");
            static const char* item_names[] = { "Item One", "Item Two", "Item Three", "Item Four", "Item Five" };
            for (int n = 0; n < IM_ARRAYSIZE(item_names); n++)
            {
                const char* item = item_names[n];
                BBZGUI::Selectable(item);

                if (BBZGUI::IsItemActive() && !BBZGUI::IsItemHovered())
                {
                    int n_next = n + (BBZGUI::GetMouseDragDelta(0).y < 0.f ? -1 : 1);
                    if (n_next >= 0 && n_next < IM_ARRAYSIZE(item_names))
                    {
                        item_names[n] = item_names[n_next];
                        item_names[n_next] = item;
                        BBZGUI::ResetMouseDragDelta();
                    }
                }
            }

            BBZGUI::PopItemFlag();
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Drag and Drop/Tooltip at target location");
        if (BBZGUI::TreeNode("Tooltip at target location"))
        {
            for (int n = 0; n < 2; n++)
            {
                // Drop targets
                BBZGUI::Button(n ? "drop here##1" : "drop here##0");
                if (BBZGUI::BeginDragDropTarget())
                {
                    BBZGUIDragDropFlags drop_target_flags = BBZGUIDragDropFlags_AcceptBeforeDelivery | BBZGUIDragDropFlags_AcceptNoPreviewTooltip;
                    if (const BBZGUIPayload* payload = BBZGUI::AcceptDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_4F, drop_target_flags))
                    {
                        IM_UNUSED(payload);
                        BBZGUI::SetMouseCursor(BBZGUIMouseCursor_NotAllowed);
                        BBZGUI::SetTooltip("Cannot drop here!");
                    }
                    BBZGUI::EndDragDropTarget();
                }

                // Drop source
                static ImVec4 col4 = { 1.0f, 0.0f, 0.2f, 1.0f };
                if (n == 0)
                    BBZGUI::ColorButton("drag me", col4);

            }
            BBZGUI::TreePop();
        }

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Querying Item Status (Edited,Active,Hovered etc.)");
    if (BBZGUI::TreeNode("Querying Item Status (Edited/Active/Hovered etc.)"))
    {
        // Select an item type
        const char* item_names[] =
        {
            "Text", "Button", "Button (w/ repeat)", "Checkbox", "SliderFloat", "InputText", "InputTextMultiline", "InputFloat",
            "InputFloat3", "ColorEdit4", "Selectable", "MenuItem", "TreeNode", "TreeNode (w/ double-click)", "Combo", "ListBox"
        };
        static int item_type = 4;
        static bool item_disabled = false;
        BBZGUI::Combo("Item Type", &item_type, item_names, IM_ARRAYSIZE(item_names), IM_ARRAYSIZE(item_names));
        BBZGUI::SameLine();
        HelpMarker("Testing how various types of items are interacting with the IsItemXXX functions. Note that the bool return value of most BBZGUI function is generally equivalent to calling BBZGUI::IsItemHovered().");
        BBZGUI::Checkbox("Item Disabled",  &item_disabled);

        // Submit selected items so we can query their status in the code following it.
        bool ret = false;
        static bool b = false;
        static float col4f[4] = { 1.0f, 0.5, 0.0f, 1.0f };
        static char str[16] = {};
        if (item_disabled)
            BBZGUI::BeginDisabled(true);
        if (item_type == 0) { BBZGUI::Text("ITEM: Text"); }                                              // Testing text items with no identifier/interaction
        if (item_type == 1) { ret = BBZGUI::Button("ITEM: Button"); }                                    // Testing button
        if (item_type == 2) { BBZGUI::PushItemFlag(BBZGUIItemFlags_ButtonRepeat, true); ret = BBZGUI::Button("ITEM: Button"); BBZGUI::PopItemFlag(); } // Testing button (with repeater)
        if (item_type == 3) { ret = BBZGUI::Checkbox("ITEM: Checkbox", &b); }                            // Testing checkbox
        if (item_type == 4) { ret = BBZGUI::SliderFloat("ITEM: SliderFloat", &col4f[0], 0.0f, 1.0f); }   // Testing basic item
        if (item_type == 5) { ret = BBZGUI::InputText("ITEM: InputText", &str[0], IM_ARRAYSIZE(str)); }  // Testing input text (which handles tabbing)
        if (item_type == 6) { ret = BBZGUI::InputTextMultiline("ITEM: InputTextMultiline", &str[0], IM_ARRAYSIZE(str)); } // Testing input text (which uses a child window)
        if (item_type == 7) { ret = BBZGUI::InputFloat("ITEM: InputFloat", col4f, 1.0f); }               // Testing +/- buttons on scalar input
        if (item_type == 8) { ret = BBZGUI::InputFloat3("ITEM: InputFloat3", col4f); }                   // Testing multi-component items (IsItemXXX flags are reported merged)
        if (item_type == 9) { ret = BBZGUI::ColorEdit4("ITEM: ColorEdit4", col4f); }                     // Testing multi-component items (IsItemXXX flags are reported merged)
        if (item_type == 10){ ret = BBZGUI::Selectable("ITEM: Selectable"); }                            // Testing selectable item
        if (item_type == 11){ ret = BBZGUI::MenuItem("ITEM: MenuItem"); }                                // Testing menu item (they use BBZGUIButtonFlags_PressedOnRelease button policy)
        if (item_type == 12){ ret = BBZGUI::TreeNode("ITEM: TreeNode"); if (ret) BBZGUI::TreePop(); }     // Testing tree node
        if (item_type == 13){ ret = BBZGUI::TreeNodeEx("ITEM: TreeNode w/ BBZGUITreeNodeFlags_OpenOnDoubleClick", BBZGUITreeNodeFlags_OpenOnDoubleClick | BBZGUITreeNodeFlags_NoTreePushOnOpen); } // Testing tree node with BBZGUIButtonFlags_PressedOnDoubleClick button policy.
        if (item_type == 14){ const char* items[] = { "Apple", "Banana", "Cherry", "Kiwi" }; static int current = 1; ret = BBZGUI::Combo("ITEM: Combo", &current, items, IM_ARRAYSIZE(items)); }
        if (item_type == 15){ const char* items[] = { "Apple", "Banana", "Cherry", "Kiwi" }; static int current = 1; ret = BBZGUI::ListBox("ITEM: ListBox", &current, items, IM_ARRAYSIZE(items), IM_ARRAYSIZE(items)); }

        bool hovered_delay_none = BBZGUI::IsItemHovered();
        bool hovered_delay_stationary = BBZGUI::IsItemHovered(BBZGUIHoveredFlags_Stationary);
        bool hovered_delay_short = BBZGUI::IsItemHovered(BBZGUIHoveredFlags_DelayShort);
        bool hovered_delay_normal = BBZGUI::IsItemHovered(BBZGUIHoveredFlags_DelayNormal);
        bool hovered_delay_tooltip = BBZGUI::IsItemHovered(BBZGUIHoveredFlags_ForTooltip); // = Normal + Stationary

        // Display the values of IsItemHovered() and other common item state functions.
        // Note that the BBZGUIHoveredFlags_XXX flags can be combined.
        // Because BulletText is an item itself and that would affect the output of IsItemXXX functions,
        // we query every state in a single call to avoid storing them and to simplify the code.
        BBZGUI::BulletText(
            "Return value = %d\n"
            "IsItemFocused() = %d\n"
            "IsItemHovered() = %d\n"
            "IsItemHovered(_AllowWhenBlockedByPopup) = %d\n"
            "IsItemHovered(_AllowWhenBlockedByActiveItem) = %d\n"
            "IsItemHovered(_AllowWhenOverlappedByItem) = %d\n"
            "IsItemHovered(_AllowWhenOverlappedByWindow) = %d\n"
            "IsItemHovered(_AllowWhenDisabled) = %d\n"
            "IsItemHovered(_RectOnly) = %d\n"
            "IsItemActive() = %d\n"
            "IsItemEdited() = %d\n"
            "IsItemActivated() = %d\n"
            "IsItemDeactivated() = %d\n"
            "IsItemDeactivatedAfterEdit() = %d\n"
            "IsItemVisible() = %d\n"
            "IsItemClicked() = %d\n"
            "IsItemToggledOpen() = %d\n"
            "GetItemRectMin() = (%.1f, %.1f)\n"
            "GetItemRectMax() = (%.1f, %.1f)\n"
            "GetItemRectSize() = (%.1f, %.1f)",
            ret,
            BBZGUI::IsItemFocused(),
            BBZGUI::IsItemHovered(),
            BBZGUI::IsItemHovered(BBZGUIHoveredFlags_AllowWhenBlockedByPopup),
            BBZGUI::IsItemHovered(BBZGUIHoveredFlags_AllowWhenBlockedByActiveItem),
            BBZGUI::IsItemHovered(BBZGUIHoveredFlags_AllowWhenOverlappedByItem),
            BBZGUI::IsItemHovered(BBZGUIHoveredFlags_AllowWhenOverlappedByWindow),
            BBZGUI::IsItemHovered(BBZGUIHoveredFlags_AllowWhenDisabled),
            BBZGUI::IsItemHovered(BBZGUIHoveredFlags_RectOnly),
            BBZGUI::IsItemActive(),
            BBZGUI::IsItemEdited(),
            BBZGUI::IsItemActivated(),
            BBZGUI::IsItemDeactivated(),
            BBZGUI::IsItemDeactivatedAfterEdit(),
            BBZGUI::IsItemVisible(),
            BBZGUI::IsItemClicked(),
            BBZGUI::IsItemToggledOpen(),
            BBZGUI::GetItemRectMin().x, BBZGUI::GetItemRectMin().y,
            BBZGUI::GetItemRectMax().x, BBZGUI::GetItemRectMax().y,
            BBZGUI::GetItemRectSize().x, BBZGUI::GetItemRectSize().y
        );
        BBZGUI::BulletText(
            "with Hovering Delay or Stationary test:\n"
            "IsItemHovered() = = %d\n"
            "IsItemHovered(_Stationary) = %d\n"
            "IsItemHovered(_DelayShort) = %d\n"
            "IsItemHovered(_DelayNormal) = %d\n"
            "IsItemHovered(_Tooltip) = %d",
            hovered_delay_none, hovered_delay_stationary, hovered_delay_short, hovered_delay_normal, hovered_delay_tooltip);

        if (item_disabled)
            BBZGUI::EndDisabled();

        char buf[1] = "";
        BBZGUI::InputText("unused", buf, IM_ARRAYSIZE(buf), BBZGUIInputTextFlags_ReadOnly);
        BBZGUI::SameLine();
        HelpMarker("This widget is only here to be able to tab-out of the widgets above and see e.g. Deactivated() status.");

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Querying Window Status (Focused,Hovered etc.)");
    if (BBZGUI::TreeNode("Querying Window Status (Focused/Hovered etc.)"))
    {
        static bool embed_all_inside_a_child_window = false;
        BBZGUI::Checkbox("Embed everything inside a child window for testing _RootWindow flag.", &embed_all_inside_a_child_window);
        if (embed_all_inside_a_child_window)
            BBZGUI::BeginChild("outer_child", ImVec2(0, BBZGUI::GetFontSize() * 20.0f), BBZGUIChildFlags_Borders);

        // Testing IsWindowFocused() function with its various flags.
        BBZGUI::BulletText(
            "IsWindowFocused() = %d\n"
            "IsWindowFocused(_ChildWindows) = %d\n"
            "IsWindowFocused(_ChildWindows|_NoPopupHierarchy) = %d\n"
            "IsWindowFocused(_ChildWindows|_RootWindow) = %d\n"
            "IsWindowFocused(_ChildWindows|_RootWindow|_NoPopupHierarchy) = %d\n"
            "IsWindowFocused(_RootWindow) = %d\n"
            "IsWindowFocused(_RootWindow|_NoPopupHierarchy) = %d\n"
            "IsWindowFocused(_AnyWindow) = %d\n",
            BBZGUI::IsWindowFocused(),
            BBZGUI::IsWindowFocused(BBZGUIFocusedFlags_ChildWindows),
            BBZGUI::IsWindowFocused(BBZGUIFocusedFlags_ChildWindows | BBZGUIFocusedFlags_NoPopupHierarchy),
            BBZGUI::IsWindowFocused(BBZGUIFocusedFlags_ChildWindows | BBZGUIFocusedFlags_RootWindow),
            BBZGUI::IsWindowFocused(BBZGUIFocusedFlags_ChildWindows | BBZGUIFocusedFlags_RootWindow | BBZGUIFocusedFlags_NoPopupHierarchy),
            BBZGUI::IsWindowFocused(BBZGUIFocusedFlags_RootWindow),
            BBZGUI::IsWindowFocused(BBZGUIFocusedFlags_RootWindow | BBZGUIFocusedFlags_NoPopupHierarchy),
            BBZGUI::IsWindowFocused(BBZGUIFocusedFlags_AnyWindow));

        // Testing IsWindowHovered() function with its various flags.
        BBZGUI::BulletText(
            "IsWindowHovered() = %d\n"
            "IsWindowHovered(_AllowWhenBlockedByPopup) = %d\n"
            "IsWindowHovered(_AllowWhenBlockedByActiveItem) = %d\n"
            "IsWindowHovered(_ChildWindows) = %d\n"
            "IsWindowHovered(_ChildWindows|_NoPopupHierarchy) = %d\n"
            "IsWindowHovered(_ChildWindows|_RootWindow) = %d\n"
            "IsWindowHovered(_ChildWindows|_RootWindow|_NoPopupHierarchy) = %d\n"
            "IsWindowHovered(_RootWindow) = %d\n"
            "IsWindowHovered(_RootWindow|_NoPopupHierarchy) = %d\n"
            "IsWindowHovered(_ChildWindows|_AllowWhenBlockedByPopup) = %d\n"
            "IsWindowHovered(_AnyWindow) = %d\n"
            "IsWindowHovered(_Stationary) = %d\n",
            BBZGUI::IsWindowHovered(),
            BBZGUI::IsWindowHovered(BBZGUIHoveredFlags_AllowWhenBlockedByPopup),
            BBZGUI::IsWindowHovered(BBZGUIHoveredFlags_AllowWhenBlockedByActiveItem),
            BBZGUI::IsWindowHovered(BBZGUIHoveredFlags_ChildWindows),
            BBZGUI::IsWindowHovered(BBZGUIHoveredFlags_ChildWindows | BBZGUIHoveredFlags_NoPopupHierarchy),
            BBZGUI::IsWindowHovered(BBZGUIHoveredFlags_ChildWindows | BBZGUIHoveredFlags_RootWindow),
            BBZGUI::IsWindowHovered(BBZGUIHoveredFlags_ChildWindows | BBZGUIHoveredFlags_RootWindow | BBZGUIHoveredFlags_NoPopupHierarchy),
            BBZGUI::IsWindowHovered(BBZGUIHoveredFlags_RootWindow),
            BBZGUI::IsWindowHovered(BBZGUIHoveredFlags_RootWindow | BBZGUIHoveredFlags_NoPopupHierarchy),
            BBZGUI::IsWindowHovered(BBZGUIHoveredFlags_ChildWindows | BBZGUIHoveredFlags_AllowWhenBlockedByPopup),
            BBZGUI::IsWindowHovered(BBZGUIHoveredFlags_AnyWindow),
            BBZGUI::IsWindowHovered(BBZGUIHoveredFlags_Stationary));

        BBZGUI::BeginChild("child", ImVec2(0, 50), BBZGUIChildFlags_Borders);
        BBZGUI::Text("This is another child window for testing the _ChildWindows flag.");
        BBZGUI::EndChild();
        if (embed_all_inside_a_child_window)
            BBZGUI::EndChild();

        // Calling IsItemHovered() after begin returns the hovered status of the title bar.
        // This is useful in particular if you want to create a context menu associated to the title bar of a window.
        static bool test_window = false;
        BBZGUI::Checkbox("Hovered/Active tests after Begin() for title bar testing", &test_window);
        if (test_window)
        {
            BBZGUI::Begin("Title bar Hovered/Active tests", &test_window);
            if (BBZGUI::BeginPopupContextItem()) // <-- This is using IsItemHovered()
            {
                if (BBZGUI::MenuItem("Close")) { test_window = false; }
                BBZGUI::EndPopup();
            }
            BBZGUI::Text(
                "IsItemHovered() after begin = %d (== is title bar hovered)\n"
                "IsItemActive() after begin = %d (== is window being clicked/moved)\n",
                BBZGUI::IsItemHovered(), BBZGUI::IsItemActive());
            BBZGUI::End();
        }

        BBZGUI::TreePop();
    }

    // Demonstrate BeginDisabled/EndDisabled using a checkbox located at the bottom of the section (which is a bit odd:
    // logically we'd have this checkbox at the top of the section, but we don't want this feature to steal that space)
    if (disable_all)
        BBZGUI::EndDisabled();

    IMGUI_DEMO_MARKER("Widgets/Disable Block");
    if (BBZGUI::TreeNode("Disable block"))
    {
        BBZGUI::Checkbox("Disable entire section above", &disable_all);
        BBZGUI::SameLine(); HelpMarker("Demonstrate using BeginDisabled()/EndDisabled() across this section.");
        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Widgets/Text Filter");
    if (BBZGUI::TreeNode("Text Filter"))
    {
        // Helper class to easy setup a text filter.
        // You may want to implement a more feature-full filtering scheme in your own application.
        HelpMarker("Not a widget per-se, but BBZGUITextFilter is a helper to perform simple filtering on text strings.");
        static BBZGUITextFilter filter;
        BBZGUI::Text("Filter usage:\n"
            "  \"\"         display all lines\n"
            "  \"xxx\"      display lines containing \"xxx\"\n"
            "  \"xxx,yyy\"  display lines containing \"xxx\" or \"yyy\"\n"
            "  \"-xxx\"     hide lines containing \"xxx\"");
        filter.Draw();
        const char* lines[] = { "aaa1.c", "bbb1.c", "ccc1.c", "aaa2.cpp", "bbb2.cpp", "ccc2.cpp", "abc.h", "hello, world" };
        for (int i = 0; i < IM_ARRAYSIZE(lines); i++)
            if (filter.PassFilter(lines[i]))
                BBZGUI::BulletText("%s", lines[i]);
        BBZGUI::TreePop();
    }
}

static const char* ExampleNames[] =
{
    "Artichoke", "Arugula", "Asparagus", "Avocado", "Bamboo Shoots", "Bean Sprouts", "Beans", "Beet", "Belgian Endive", "Bell Pepper",
    "Bitter Gourd", "Bok Choy", "Broccoli", "Brussels Sprouts", "Burdock Root", "Cabbage", "Calabash", "Capers", "Carrot", "Cassava",
    "Cauliflower", "Celery", "Celery Root", "Celcuce", "Chayote", "Chinese Broccoli", "Corn", "Cucumber"
};

// Extra functions to add deletion support to BBZGUISelectionBasicStorage
struct ExampleSelectionWithDeletion : BBZGUISelectionBasicStorage
{
    // Find which item should be Focused after deletion.
    // Call _before_ item submission. Retunr an index in the before-deletion item list, your item loop should call SetKeyboardFocusHere() on it.
    // The subsequent ApplyDeletionPostLoop() code will use it to apply Selection.
    // - We cannot provide this logic in core Dear BBZGUI because we don't have access to selection data.
    // - We don't actually manipulate the ImVector<> here, only in ApplyDeletionPostLoop(), but using similar API for consistency and flexibility.
    // - Important: Deletion only works if the underlying BBZGUIID for your items are stable: aka not depend on their index, but on e.g. item id/ptr.
    // FIXME-MULTISELECT: Doesn't take account of the possibility focus target will be moved during deletion. Need refocus or scroll offset.
    int ApplyDeletionPreLoop(BBZGUIMultiSelectIO* ms_io, int items_count)
    {
        if (Size == 0)
            return -1;

        // If focused item is not selected...
        const int focused_idx = (int)ms_io->NavIdItem;  // Index of currently focused item
        if (ms_io->NavIdSelected == false)  // This is merely a shortcut, == Contains(adapter->IndexToStorage(items, focused_idx))
        {
            ms_io->RangeSrcReset = true;    // Request to recover RangeSrc from NavId next frame. Would be ok to reset even when NavIdSelected==true, but it would take an extra frame to recover RangeSrc when deleting a selected item.
            return focused_idx;             // Request to focus same item after deletion.
        }

        // If focused item is selected: land on first unselected item after focused item.
        for (int idx = focused_idx + 1; idx < items_count; idx++)
            if (!Contains(GetStorageIdFromIndex(idx)))
                return idx;

        // If focused item is selected: otherwise return last unselected item before focused item.
        for (int idx = IM_MIN(focused_idx, items_count) - 1; idx >= 0; idx--)
            if (!Contains(GetStorageIdFromIndex(idx)))
                return idx;

        return -1;
    }

    // Rewrite item list (delete items) + update selection.
    // - Call after EndMultiSelect()
    // - We cannot provide this logic in core Dear BBZGUI because we don't have access to your items, nor to selection data.
    template<typename ITEM_TYPE>
    void ApplyDeletionPostLoop(BBZGUIMultiSelectIO* ms_io, ImVector<ITEM_TYPE>& items, int item_curr_idx_to_select)
    {
        // Rewrite item list (delete items) + convert old selection index (before deletion) to new selection index (after selection).
        // If NavId was not part of selection, we will stay on same item.
        ImVector<ITEM_TYPE> new_items;
        new_items.reserve(items.Size - Size);
        int item_next_idx_to_select = -1;
        for (int idx = 0; idx < items.Size; idx++)
        {
            if (!Contains(GetStorageIdFromIndex(idx)))
                new_items.push_back(items[idx]);
            if (item_curr_idx_to_select == idx)
                item_next_idx_to_select = new_items.Size - 1;
        }
        items.swap(new_items);

        // Update selection
        Clear();
        if (item_next_idx_to_select != -1 && ms_io->NavIdSelected)
            SetItemSelected(GetStorageIdFromIndex(item_next_idx_to_select), true);
    }
};

// Example: Implement dual list box storage and interface
struct ExampleDualListBox
{
    ImVector<BBZGUIID>           Items[2];               // ID is index into ExampleName[]
    BBZGUISelectionBasicStorage  Selections[2];          // Store ExampleItemId into selection
    bool                        OptKeepSorted = true;

    void MoveAll(int src, int dst)
    {
        IM_ASSERT((src == 0 && dst == 1) || (src == 1 && dst == 0));
        for (BBZGUIID item_id : Items[src])
            Items[dst].push_back(item_id);
        Items[src].clear();
        SortItems(dst);
        Selections[src].Swap(Selections[dst]);
        Selections[src].Clear();
    }
    void MoveSelected(int src, int dst)
    {
        for (int src_n = 0; src_n < Items[src].Size; src_n++)
        {
            BBZGUIID item_id = Items[src][src_n];
            if (!Selections[src].Contains(item_id))
                continue;
            Items[src].erase(&Items[src][src_n]); // FIXME-OPT: Could be implemented more optimally (rebuild src items and swap)
            Items[dst].push_back(item_id);
            src_n--;
        }
        if (OptKeepSorted)
            SortItems(dst);
        Selections[src].Swap(Selections[dst]);
        Selections[src].Clear();
    }
    void ApplySelectionRequests(BBZGUIMultiSelectIO* ms_io, int side)
    {
        // In this example we store item id in selection (instead of item index)
        Selections[side].UserData = Items[side].Data;
        Selections[side].AdapterIndexToStorageId = [](BBZGUISelectionBasicStorage* self, int idx) { BBZGUIID* items = (BBZGUIID*)self->UserData; return items[idx]; };
        Selections[side].ApplyRequests(ms_io);
    }
    static int IMGUI_CDECL CompareItemsByValue(const void* lhs, const void* rhs)
    {
        const int* a = (const int*)lhs;
        const int* b = (const int*)rhs;
        return (*a - *b) > 0 ? +1 : -1;
    }
    void SortItems(int n)
    {
        qsort(Items[n].Data, (size_t)Items[n].Size, sizeof(Items[n][0]), CompareItemsByValue);
    }
    void Show()
    {
        //BBZGUI::Checkbox("Sorted", &OptKeepSorted);
        if (BBZGUI::BeginTable("split", 3, BBZGUITableFlags_None))
        {
            BBZGUI::TableSetupColumn("", BBZGUITableColumnFlags_WidthStretch);    // Left side
            BBZGUI::TableSetupColumn("", BBZGUITableColumnFlags_WidthFixed);      // Buttons
            BBZGUI::TableSetupColumn("", BBZGUITableColumnFlags_WidthStretch);    // Right side
            BBZGUI::TableNextRow();

            int request_move_selected = -1;
            int request_move_all = -1;
            float child_height_0 = 0.0f;
            for (int side = 0; side < 2; side++)
            {
                // FIXME-MULTISELECT: Dual List Box: Add context menus
                // FIXME-NAV: Using BBZGUIWindowFlags_NavFlattened exhibit many issues.
                ImVector<BBZGUIID>& items = Items[side];
                BBZGUISelectionBasicStorage& selection = Selections[side];

                BBZGUI::TableSetColumnIndex((side == 0) ? 0 : 2);
                BBZGUI::Text("%s (%d)", (side == 0) ? "Available" : "Basket", items.Size);

                // Submit scrolling range to avoid glitches on moving/deletion
                const float items_height = BBZGUI::GetTextLineHeightWithSpacing();
                BBZGUI::SetNextWindowContentSize(ImVec2(0.0f, items.Size * items_height));

                bool child_visible;
                if (side == 0)
                {
                    // Left child is resizable
                    BBZGUI::SetNextWindowSizeConstraints(ImVec2(0.0f, BBZGUI::GetFrameHeightWithSpacing() * 4), ImVec2(FLT_MAX, FLT_MAX));
                    child_visible = BBZGUI::BeginChild("0", ImVec2(-FLT_MIN, BBZGUI::GetFontSize() * 20), BBZGUIChildFlags_FrameStyle | BBZGUIChildFlags_ResizeY);
                    child_height_0 = BBZGUI::GetWindowSize().y;
                }
                else
                {
                    // Right child use same height as left one
                    child_visible = BBZGUI::BeginChild("1", ImVec2(-FLT_MIN, child_height_0), BBZGUIChildFlags_FrameStyle);
                }
                if (child_visible)
                {
                    BBZGUIMultiSelectFlags flags = BBZGUIMultiSelectFlags_None;
                    BBZGUIMultiSelectIO* ms_io = BBZGUI::BeginMultiSelect(flags, selection.Size, items.Size);
                    ApplySelectionRequests(ms_io, side);

                    for (int item_n = 0; item_n < items.Size; item_n++)
                    {
                        BBZGUIID item_id = items[item_n];
                        bool item_is_selected = selection.Contains(item_id);
                        BBZGUI::SetNextItemSelectionUserData(item_n);
                        BBZGUI::Selectable(ExampleNames[item_id], item_is_selected, BBZGUISelectableFlags_AllowDoubleClick);
                        if (BBZGUI::IsItemFocused())
                        {
                            // FIXME-MULTISELECT: Dual List Box: Transfer focus
                            if (BBZGUI::IsKeyPressed(BBZGUIKey_Enter) || BBZGUI::IsKeyPressed(BBZGUIKey_KeypadEnter))
                                request_move_selected = side;
                            if (BBZGUI::IsMouseDoubleClicked(0)) // FIXME-MULTISELECT: Double-click on multi-selection?
                                request_move_selected = side;
                        }
                    }

                    ms_io = BBZGUI::EndMultiSelect();
                    ApplySelectionRequests(ms_io, side);
                }
                BBZGUI::EndChild();
            }

            // Buttons columns
            BBZGUI::TableSetColumnIndex(1);
            BBZGUI::NewLine();
            //ImVec2 button_sz = { BBZGUI::CalcTextSize(">>").x + BBZGUI::GetStyle().FramePadding.x * 2.0f, BBZGUI::GetFrameHeight() + padding.y * 2.0f };
            ImVec2 button_sz = { BBZGUI::GetFrameHeight(), BBZGUI::GetFrameHeight() };

            // (Using BeginDisabled()/EndDisabled() works but feels distracting given how it is currently visualized)
            if (BBZGUI::Button(">>", button_sz))
                request_move_all = 0;
            if (BBZGUI::Button(">", button_sz))
                request_move_selected = 0;
            if (BBZGUI::Button("<", button_sz))
                request_move_selected = 1;
            if (BBZGUI::Button("<<", button_sz))
                request_move_all = 1;

            // Process requests
            if (request_move_all != -1)
                MoveAll(request_move_all, request_move_all ^ 1);
            if (request_move_selected != -1)
                MoveSelected(request_move_selected, request_move_selected ^ 1);

            // FIXME-MULTISELECT: Support action from outside
            /*
            if (OptKeepSorted == false)
            {
                BBZGUI::NewLine();
                if (BBZGUI::ArrowButton("MoveUp", BBZGUIDir_Up)) {}
                if (BBZGUI::ArrowButton("MoveDown", BBZGUIDir_Down)) {}
            }
            */

            BBZGUI::EndTable();
        }
    }
};

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowMultiSelect()
//-----------------------------------------------------------------------------
// Multi-selection demos
// Also read: https://github.com/ocornut/imgui/wiki/Multi-Select
//-----------------------------------------------------------------------------

static void ShowDemoWindowMultiSelect(BBZGUIDemoWindowData* demo_data)
{
    IMGUI_DEMO_MARKER("Widgets/Selection State & Multi-Select");
    if (BBZGUI::TreeNode("Selection State & Multi-Select"))
    {
        HelpMarker("Selections can be built using Selectable(), TreeNode() or other widgets. Selection state is owned by application code/data.");

        // Without any fancy API: manage single-selection yourself.
        IMGUI_DEMO_MARKER("Widgets/Selection State/Single-Select");
        if (BBZGUI::TreeNode("Single-Select"))
        {
            static int selected = -1;
            for (int n = 0; n < 5; n++)
            {
                char buf[32];
                sprintf(buf, "Object %d", n);
                if (BBZGUI::Selectable(buf, selected == n))
                    selected = n;
            }
            BBZGUI::TreePop();
        }

        // Demonstrate implementation a most-basic form of multi-selection manually
        // This doesn't support the SHIFT modifier which requires BeginMultiSelect()!
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (manual/simplified, without BeginMultiSelect)");
        if (BBZGUI::TreeNode("Multi-Select (manual/simplified, without BeginMultiSelect)"))
        {
            HelpMarker("Hold CTRL and click to select multiple items.");
            static bool selection[5] = { false, false, false, false, false };
            for (int n = 0; n < 5; n++)
            {
                char buf[32];
                sprintf(buf, "Object %d", n);
                if (BBZGUI::Selectable(buf, selection[n]))
                {
                    if (!BBZGUI::GetIO().KeyCtrl) // Clear selection when CTRL is not held
                        memset(selection, 0, sizeof(selection));
                    selection[n] ^= 1; // Toggle current item
                }
            }
            BBZGUI::TreePop();
        }

        // Demonstrate handling proper multi-selection using the BeginMultiSelect/EndMultiSelect API.
        // SHIFT+Click w/ CTRL and other standard features are supported.
        // We use the BBZGUISelectionBasicStorage helper which you may freely reimplement.
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select");
        if (BBZGUI::TreeNode("Multi-Select"))
        {
            BBZGUI::Text("Supported features:");
            BBZGUI::BulletText("Keyboard navigation (arrows, page up/down, home/end, space).");
            BBZGUI::BulletText("Ctrl modifier to preserve and toggle selection.");
            BBZGUI::BulletText("Shift modifier for range selection.");
            BBZGUI::BulletText("CTRL+A to select all.");
            BBZGUI::BulletText("Escape to clear selection.");
            BBZGUI::BulletText("Click and drag to box-select.");
            BBZGUI::Text("Tip: Use 'Demo->Tools->Debug Log->Selection' to see selection requests as they happen.");

            // Use default selection.Adapter: Pass index to SetNextItemSelectionUserData(), store index in Selection
            const int ITEMS_COUNT = 50;
            static BBZGUISelectionBasicStorage selection;
            BBZGUI::Text("Selection: %d/%d", selection.Size, ITEMS_COUNT);

            // The BeginChild() has no purpose for selection logic, other that offering a scrolling region.
            if (BBZGUI::BeginChild("##Basket", ImVec2(-FLT_MIN, BBZGUI::GetFontSize() * 20), BBZGUIChildFlags_FrameStyle | BBZGUIChildFlags_ResizeY))
            {
                BBZGUIMultiSelectFlags flags = BBZGUIMultiSelectFlags_ClearOnEscape | BBZGUIMultiSelectFlags_BoxSelect1d;
                BBZGUIMultiSelectIO* ms_io = BBZGUI::BeginMultiSelect(flags, selection.Size, ITEMS_COUNT);
                selection.ApplyRequests(ms_io);

                for (int n = 0; n < ITEMS_COUNT; n++)
                {
                    char label[64];
                    sprintf(label, "Object %05d: %s", n, ExampleNames[n % IM_ARRAYSIZE(ExampleNames)]);
                    bool item_is_selected = selection.Contains((BBZGUIID)n);
                    BBZGUI::SetNextItemSelectionUserData(n);
                    BBZGUI::Selectable(label, item_is_selected);
                }

                ms_io = BBZGUI::EndMultiSelect();
                selection.ApplyRequests(ms_io);
            }
            BBZGUI::EndChild();
            BBZGUI::TreePop();
        }

        // Demonstrate using the clipper with BeginMultiSelect()/EndMultiSelect()
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (with clipper)");
        if (BBZGUI::TreeNode("Multi-Select (with clipper)"))
        {
            // Use default selection.Adapter: Pass index to SetNextItemSelectionUserData(), store index in Selection
            static BBZGUISelectionBasicStorage selection;

            BBZGUI::Text("Added features:");
            BBZGUI::BulletText("Using BBZGUIListClipper.");

            const int ITEMS_COUNT = 10000;
            BBZGUI::Text("Selection: %d/%d", selection.Size, ITEMS_COUNT);
            if (BBZGUI::BeginChild("##Basket", ImVec2(-FLT_MIN, BBZGUI::GetFontSize() * 20), BBZGUIChildFlags_FrameStyle | BBZGUIChildFlags_ResizeY))
            {
                BBZGUIMultiSelectFlags flags = BBZGUIMultiSelectFlags_ClearOnEscape | BBZGUIMultiSelectFlags_BoxSelect1d;
                BBZGUIMultiSelectIO* ms_io = BBZGUI::BeginMultiSelect(flags, selection.Size, ITEMS_COUNT);
                selection.ApplyRequests(ms_io);

                BBZGUIListClipper clipper;
                clipper.Begin(ITEMS_COUNT);
                if (ms_io->RangeSrcItem != -1)
                    clipper.IncludeItemByIndex((int)ms_io->RangeSrcItem); // Ensure RangeSrc item is not clipped.
                while (clipper.Step())
                {
                    for (int n = clipper.DisplayStart; n < clipper.DisplayEnd; n++)
                    {
                        char label[64];
                        sprintf(label, "Object %05d: %s", n, ExampleNames[n % IM_ARRAYSIZE(ExampleNames)]);
                        bool item_is_selected = selection.Contains((BBZGUIID)n);
                        BBZGUI::SetNextItemSelectionUserData(n);
                        BBZGUI::Selectable(label, item_is_selected);
                    }
                }

                ms_io = BBZGUI::EndMultiSelect();
                selection.ApplyRequests(ms_io);
            }
            BBZGUI::EndChild();
            BBZGUI::TreePop();
        }

        // Demonstrate dynamic item list + deletion support using the BeginMultiSelect/EndMultiSelect API.
        // In order to support Deletion without any glitches you need to:
        // - (1) If items are submitted in their own scrolling area, submit contents size SetNextWindowContentSize() ahead of time to prevent one-frame readjustment of scrolling.
        // - (2) Items needs to have persistent ID Stack identifier = ID needs to not depends on their index. PushID(index) = KO. PushID(item_id) = OK. This is in order to focus items reliably after a selection.
        // - (3) BeginXXXX process
        // - (4) Focus process
        // - (5) EndXXXX process
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (with deletion)");
        if (BBZGUI::TreeNode("Multi-Select (with deletion)"))
        {
            // Storing items data separately from selection data.
            // (you may decide to store selection data inside your item (aka intrusive storage) if you don't need multiple views over same items)
            // Use a custom selection.Adapter: store item identifier in Selection (instead of index)
            static ImVector<BBZGUIID> items;
            static ExampleSelectionWithDeletion selection;
            selection.UserData = (void*)&items;
            selection.AdapterIndexToStorageId = [](BBZGUISelectionBasicStorage* self, int idx) { ImVector<BBZGUIID>* p_items = (ImVector<BBZGUIID>*)self->UserData; return (*p_items)[idx]; }; // Index -> ID

            BBZGUI::Text("Added features:");
            BBZGUI::BulletText("Dynamic list with Delete key support.");
            BBZGUI::Text("Selection size: %d/%d", selection.Size, items.Size);

            // Initialize default list with 50 items + button to add/remove items.
            static BBZGUIID items_next_id = 0;
            if (items_next_id == 0)
                for (BBZGUIID n = 0; n < 50; n++)
                    items.push_back(items_next_id++);
            if (BBZGUI::SmallButton("Add 20 items"))     { for (int n = 0; n < 20; n++) { items.push_back(items_next_id++); } }
            BBZGUI::SameLine();
            if (BBZGUI::SmallButton("Remove 20 items"))  { for (int n = IM_MIN(20, items.Size); n > 0; n--) { selection.SetItemSelected(items.back(), false); items.pop_back(); } }

            // (1) Extra to support deletion: Submit scrolling range to avoid glitches on deletion
            const float items_height = BBZGUI::GetTextLineHeightWithSpacing();
            BBZGUI::SetNextWindowContentSize(ImVec2(0.0f, items.Size * items_height));

            if (BBZGUI::BeginChild("##Basket", ImVec2(-FLT_MIN, BBZGUI::GetFontSize() * 20), BBZGUIChildFlags_FrameStyle | BBZGUIChildFlags_ResizeY))
            {
                BBZGUIMultiSelectFlags flags = BBZGUIMultiSelectFlags_ClearOnEscape | BBZGUIMultiSelectFlags_BoxSelect1d;
                BBZGUIMultiSelectIO* ms_io = BBZGUI::BeginMultiSelect(flags, selection.Size, items.Size);
                selection.ApplyRequests(ms_io);

                const bool want_delete = BBZGUI::Shortcut(BBZGUIKey_Delete, BBZGUIInputFlags_Repeat) && (selection.Size > 0);
                const int item_curr_idx_to_focus = want_delete ? selection.ApplyDeletionPreLoop(ms_io, items.Size) : -1;

                for (int n = 0; n < items.Size; n++)
                {
                    const BBZGUIID item_id = items[n];
                    char label[64];
                    sprintf(label, "Object %05u: %s", item_id, ExampleNames[item_id % IM_ARRAYSIZE(ExampleNames)]);

                    bool item_is_selected = selection.Contains(item_id);
                    BBZGUI::SetNextItemSelectionUserData(n);
                    BBZGUI::Selectable(label, item_is_selected);
                    if (item_curr_idx_to_focus == n)
                        BBZGUI::SetKeyboardFocusHere(-1);
                }

                // Apply multi-select requests
                ms_io = BBZGUI::EndMultiSelect();
                selection.ApplyRequests(ms_io);
                if (want_delete)
                    selection.ApplyDeletionPostLoop(ms_io, items, item_curr_idx_to_focus);
            }
            BBZGUI::EndChild();
            BBZGUI::TreePop();
        }

        // Implement a Dual List Box (#6648)
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (dual list box)");
        if (BBZGUI::TreeNode("Multi-Select (dual list box)"))
        {
            // Init default state
            static ExampleDualListBox dlb;
            if (dlb.Items[0].Size == 0 && dlb.Items[1].Size == 0)
                for (int item_id = 0; item_id < IM_ARRAYSIZE(ExampleNames); item_id++)
                    dlb.Items[0].push_back((BBZGUIID)item_id);

            // Show
            dlb.Show();

            BBZGUI::TreePop();
        }

        // Demonstrate using the clipper with BeginMultiSelect()/EndMultiSelect()
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (in a table)");
        if (BBZGUI::TreeNode("Multi-Select (in a table)"))
        {
            static BBZGUISelectionBasicStorage selection;

            const int ITEMS_COUNT = 10000;
            BBZGUI::Text("Selection: %d/%d", selection.Size, ITEMS_COUNT);
            if (BBZGUI::BeginTable("##Basket", 2, BBZGUITableFlags_ScrollY | BBZGUITableFlags_RowBg | BBZGUITableFlags_BordersOuter))
            {
                BBZGUI::TableSetupColumn("Object");
                BBZGUI::TableSetupColumn("Action");
                BBZGUI::TableSetupScrollFreeze(0, 1);
                BBZGUI::TableHeadersRow();

                BBZGUIMultiSelectFlags flags = BBZGUIMultiSelectFlags_ClearOnEscape | BBZGUIMultiSelectFlags_BoxSelect1d;
                BBZGUIMultiSelectIO* ms_io = BBZGUI::BeginMultiSelect(flags, selection.Size, ITEMS_COUNT);
                selection.ApplyRequests(ms_io);

                BBZGUIListClipper clipper;
                clipper.Begin(ITEMS_COUNT);
                if (ms_io->RangeSrcItem != -1)
                    clipper.IncludeItemByIndex((int)ms_io->RangeSrcItem); // Ensure RangeSrc item is not clipped.
                while (clipper.Step())
                {
                    for (int n = clipper.DisplayStart; n < clipper.DisplayEnd; n++)
                    {
                        BBZGUI::TableNextRow();
                        BBZGUI::TableNextColumn();
                        char label[64];
                        sprintf(label, "Object %05d: %s", n, ExampleNames[n % IM_ARRAYSIZE(ExampleNames)]);
                        bool item_is_selected = selection.Contains((BBZGUIID)n);
                        BBZGUI::SetNextItemSelectionUserData(n);
                        BBZGUI::Selectable(label, item_is_selected, BBZGUISelectableFlags_SpanAllColumns | BBZGUISelectableFlags_AllowOverlap);
                        BBZGUI::TableNextColumn();
                        BBZGUI::SmallButton("hello");
                    }
                }

                ms_io = BBZGUI::EndMultiSelect();
                selection.ApplyRequests(ms_io);
                BBZGUI::EndTable();
            }
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (checkboxes)");
        if (BBZGUI::TreeNode("Multi-Select (checkboxes)"))
        {
            BBZGUI::Text("In a list of checkboxes (not selectable):");
            BBZGUI::BulletText("Using _NoAutoSelect + _NoAutoClear flags.");
            BBZGUI::BulletText("Shift+Click to check multiple boxes.");
            BBZGUI::BulletText("Shift+Keyboard to copy current value to other boxes.");

            // If you have an array of checkboxes, you may want to use NoAutoSelect + NoAutoClear and the BBZGUISelectionExternalStorage helper.
            static bool items[20] = {};
            static BBZGUIMultiSelectFlags flags = BBZGUIMultiSelectFlags_NoAutoSelect | BBZGUIMultiSelectFlags_NoAutoClear | BBZGUIMultiSelectFlags_ClearOnEscape;
            BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_NoAutoSelect", &flags, BBZGUIMultiSelectFlags_NoAutoSelect);
            BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_NoAutoClear", &flags, BBZGUIMultiSelectFlags_NoAutoClear);
            BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_BoxSelect2d", &flags, BBZGUIMultiSelectFlags_BoxSelect2d); // Cannot use BBZGUIMultiSelectFlags_BoxSelect1d as checkboxes are varying width.

            if (BBZGUI::BeginChild("##Basket", ImVec2(-FLT_MIN, BBZGUI::GetFontSize() * 20), BBZGUIChildFlags_Borders | BBZGUIChildFlags_ResizeY))
            {
                BBZGUIMultiSelectIO* ms_io = BBZGUI::BeginMultiSelect(flags, -1, IM_ARRAYSIZE(items));
                BBZGUISelectionExternalStorage storage_wrapper;
                storage_wrapper.UserData = (void*)items;
                storage_wrapper.AdapterSetItemSelected = [](BBZGUISelectionExternalStorage* self, int n, bool selected) { bool* array = (bool*)self->UserData; array[n] = selected; };
                storage_wrapper.ApplyRequests(ms_io);
                for (int n = 0; n < 20; n++)
                {
                    char label[32];
                    sprintf(label, "Item %d", n);
                    BBZGUI::SetNextItemSelectionUserData(n);
                    BBZGUI::Checkbox(label, &items[n]);
                }
                ms_io = BBZGUI::EndMultiSelect();
                storage_wrapper.ApplyRequests(ms_io);
            }
            BBZGUI::EndChild();

            BBZGUI::TreePop();
        }

        // Demonstrate individual selection scopes in same window
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (multiple scopes)");
        if (BBZGUI::TreeNode("Multi-Select (multiple scopes)"))
        {
            // Use default select: Pass index to SetNextItemSelectionUserData(), store index in Selection
            const int SCOPES_COUNT = 3;
            const int ITEMS_COUNT = 8; // Per scope
            static BBZGUISelectionBasicStorage selections_data[SCOPES_COUNT];

            // Use BBZGUIMultiSelectFlags_ScopeRect to not affect other selections in same window.
            static BBZGUIMultiSelectFlags flags = BBZGUIMultiSelectFlags_ScopeRect | BBZGUIMultiSelectFlags_ClearOnEscape;// | BBZGUIMultiSelectFlags_ClearOnClickVoid;
            if (BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_ScopeWindow", &flags, BBZGUIMultiSelectFlags_ScopeWindow) && (flags & BBZGUIMultiSelectFlags_ScopeWindow))
                flags &= ~BBZGUIMultiSelectFlags_ScopeRect;
            if (BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_ScopeRect", &flags, BBZGUIMultiSelectFlags_ScopeRect) && (flags & BBZGUIMultiSelectFlags_ScopeRect))
                flags &= ~BBZGUIMultiSelectFlags_ScopeWindow;
            BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_ClearOnClickVoid", &flags, BBZGUIMultiSelectFlags_ClearOnClickVoid);
            BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_BoxSelect1d", &flags, BBZGUIMultiSelectFlags_BoxSelect1d);

            for (int selection_scope_n = 0; selection_scope_n < SCOPES_COUNT; selection_scope_n++)
            {
                BBZGUI::PushID(selection_scope_n);
                BBZGUISelectionBasicStorage* selection = &selections_data[selection_scope_n];
                BBZGUIMultiSelectIO* ms_io = BBZGUI::BeginMultiSelect(flags, selection->Size, ITEMS_COUNT);
                selection->ApplyRequests(ms_io);

                BBZGUI::SeparatorText("Selection scope");
                BBZGUI::Text("Selection size: %d/%d", selection->Size, ITEMS_COUNT);

                for (int n = 0; n < ITEMS_COUNT; n++)
                {
                    char label[64];
                    sprintf(label, "Object %05d: %s", n, ExampleNames[n % IM_ARRAYSIZE(ExampleNames)]);
                    bool item_is_selected = selection->Contains((BBZGUIID)n);
                    BBZGUI::SetNextItemSelectionUserData(n);
                    BBZGUI::Selectable(label, item_is_selected);
                }

                // Apply multi-select requests
                ms_io = BBZGUI::EndMultiSelect();
                selection->ApplyRequests(ms_io);
                BBZGUI::PopID();
            }
            BBZGUI::TreePop();
        }

        // See ShowExampleAppAssetsBrowser()
        if (BBZGUI::TreeNode("Multi-Select (tiled assets browser)"))
        {
            BBZGUI::Checkbox("Assets Browser", &demo_data->ShowAppAssetsBrowser);
            BBZGUI::Text("(also access from 'Examples->Assets Browser' in menu)");
            BBZGUI::TreePop();
        }

        // Demonstrate supporting multiple-selection in a tree.
        // - We don't use linear indices for selection user data, but our ExampleTreeNode* pointer directly!
        //   This showcase how SetNextItemSelectionUserData() never assume indices!
        // - The difficulty here is to "interpolate" from RangeSrcItem to RangeDstItem in the SetAll/SetRange request.
        //   We want this interpolation to match what the user sees: in visible order, skipping closed nodes.
        //   This is implemented by our TreeGetNextNodeInVisibleOrder() user-space helper.
        // - Important: In a real codebase aiming to implement full-featured selectable tree with custom filtering, you
        //   are more likely to build an array mapping sequential indices to visible tree nodes, since your
        //   filtering/search + clipping process will benefit from it. Having this will make this interpolation much easier.
        // - Consider this a prototype: we are working toward simplifying some of it.
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (trees)");
        if (BBZGUI::TreeNode("Multi-Select (trees)"))
        {
            HelpMarker(
                "This is rather advanced and experimental. If you are getting started with multi-select,"
                "please don't start by looking at how to use it for a tree!\n\n"
                "Future versions will try to simplify and formalize some of this.");

            struct ExampleTreeFuncs
            {
                static void DrawNode(ExampleTreeNode* node, BBZGUISelectionBasicStorage* selection)
                {
                    BBZGUITreeNodeFlags tree_node_flags = BBZGUITreeNodeFlags_SpanAvailWidth | BBZGUITreeNodeFlags_OpenOnArrow | BBZGUITreeNodeFlags_OpenOnDoubleClick;
                    tree_node_flags |= BBZGUITreeNodeFlags_NavLeftJumpsBackHere; // Enable pressing left to jump to parent
                    if (node->Childs.Size == 0)
                        tree_node_flags |= BBZGUITreeNodeFlags_Bullet | BBZGUITreeNodeFlags_Leaf;
                    if (selection->Contains((BBZGUIID)node->UID))
                        tree_node_flags |= BBZGUITreeNodeFlags_Selected;

                    // Using SetNextItemStorageID() to specify storage id, so we can easily peek into
                    // the storage holding open/close stage, using our TreeNodeGetOpen/TreeNodeSetOpen() functions.
                    BBZGUI::SetNextItemSelectionUserData((BBZGUISelectionUserData)(intptr_t)node);
                    BBZGUI::SetNextItemStorageID((BBZGUIID)node->UID);
                    if (BBZGUI::TreeNodeEx(node->Name, tree_node_flags))
                    {
                        for (ExampleTreeNode* child : node->Childs)
                            DrawNode(child, selection);
                        BBZGUI::TreePop();
                    }
                    else if (BBZGUI::IsItemToggledOpen())
                    {
                        TreeCloseAndUnselectChildNodes(node, selection);
                    }
                }

                static bool TreeNodeGetOpen(ExampleTreeNode* node)
                {
                    return BBZGUI::GetStateStorage()->GetBool((BBZGUIID)node->UID);
                }

                static void TreeNodeSetOpen(ExampleTreeNode* node, bool open)
                {
                    BBZGUI::GetStateStorage()->SetBool((BBZGUIID)node->UID, open);
                }

                // When closing a node: 1) close and unselect all child nodes, 2) select parent if any child was selected.
                // FIXME: This is currently handled by user logic but I'm hoping to eventually provide tree node
                // features to do this automatically, e.g. a BBZGUITreeNodeFlags_AutoCloseChildNodes etc.
                static int TreeCloseAndUnselectChildNodes(ExampleTreeNode* node, BBZGUISelectionBasicStorage* selection, int depth = 0)
                {
                    // Recursive close (the test for depth == 0 is because we call this on a node that was just closed!)
                    int unselected_count = selection->Contains((BBZGUIID)node->UID) ? 1 : 0;
                    if (depth == 0 || TreeNodeGetOpen(node))
                    {
                        for (ExampleTreeNode* child : node->Childs)
                            unselected_count += TreeCloseAndUnselectChildNodes(child, selection, depth + 1);
                        TreeNodeSetOpen(node, false);
                    }

                    // Select root node if any of its child was selected, otherwise unselect
                    selection->SetItemSelected((BBZGUIID)node->UID, (depth == 0 && unselected_count > 0));
                    return unselected_count;
                }

                // Apply multi-selection requests
                static void ApplySelectionRequests(BBZGUIMultiSelectIO* ms_io, ExampleTreeNode* tree, BBZGUISelectionBasicStorage* selection)
                {
                    for (BBZGUISelectionRequest& req : ms_io->Requests)
                    {
                        if (req.Type == BBZGUISelectionRequestType_SetAll)
                        {
                            if (req.Selected)
                                TreeSetAllInOpenNodes(tree, selection, req.Selected);
                            else
                                selection->Clear();
                        }
                        else if (req.Type == BBZGUISelectionRequestType_SetRange)
                        {
                            ExampleTreeNode* first_node = (ExampleTreeNode*)(intptr_t)req.RangeFirstItem;
                            ExampleTreeNode* last_node = (ExampleTreeNode*)(intptr_t)req.RangeLastItem;
                            for (ExampleTreeNode* node = first_node; node != NULL; node = TreeGetNextNodeInVisibleOrder(node, last_node))
                                selection->SetItemSelected((BBZGUIID)node->UID, req.Selected);
                        }
                    }
                }

                static void TreeSetAllInOpenNodes(ExampleTreeNode* node, BBZGUISelectionBasicStorage* selection, bool selected)
                {
                    if (node->Parent != NULL) // Root node isn't visible nor selectable in our scheme
                        selection->SetItemSelected((BBZGUIID)node->UID, selected);
                    if (node->Parent == NULL || TreeNodeGetOpen(node))
                        for (ExampleTreeNode* child : node->Childs)
                            TreeSetAllInOpenNodes(child, selection, selected);
                }

                // Interpolate in *user-visible order* AND only *over opened nodes*.
                // If you have a sequential mapping tables (e.g. generated after a filter/search pass) this would be simpler.
                // Here the tricks are that:
                // - we store/maintain ExampleTreeNode::IndexInParent which allows implementing a linear iterator easily, without searches, without recursion.
                //   this could be replaced by a search in parent, aka 'int index_in_parent = curr_node->Parent->Childs.find_index(curr_node)'
                //   which would only be called when crossing from child to a parent, aka not too much.
                // - we call SetNextItemStorageID() before our TreeNode() calls with an ID which doesn't relate to UI stack,
                //   making it easier to call TreeNodeGetOpen()/TreeNodeSetOpen() from any location.
                static ExampleTreeNode* TreeGetNextNodeInVisibleOrder(ExampleTreeNode* curr_node, ExampleTreeNode* last_node)
                {
                    // Reached last node
                    if (curr_node == last_node)
                        return NULL;

                    // Recurse into childs. Query storage to tell if the node is open.
                    if (curr_node->Childs.Size > 0 && TreeNodeGetOpen(curr_node))
                        return curr_node->Childs[0];

                    // Next sibling, then into our own parent
                    while (curr_node->Parent != NULL)
                    {
                        if (curr_node->IndexInParent + 1 < curr_node->Parent->Childs.Size)
                            return curr_node->Parent->Childs[curr_node->IndexInParent + 1];
                        curr_node = curr_node->Parent;
                    }
                    return NULL;
                }

            }; // ExampleTreeFuncs

            static BBZGUISelectionBasicStorage selection;
            if (demo_data->DemoTree == NULL)
                demo_data->DemoTree = ExampleTree_CreateDemoTree(); // Create tree once
            BBZGUI::Text("Selection size: %d", selection.Size);

            if (BBZGUI::BeginChild("##Tree", ImVec2(-FLT_MIN, BBZGUI::GetFontSize() * 20), BBZGUIChildFlags_FrameStyle | BBZGUIChildFlags_ResizeY))
            {
                ExampleTreeNode* tree = demo_data->DemoTree;
                BBZGUIMultiSelectFlags ms_flags = BBZGUIMultiSelectFlags_ClearOnEscape | BBZGUIMultiSelectFlags_BoxSelect2d;
                BBZGUIMultiSelectIO* ms_io = BBZGUI::BeginMultiSelect(ms_flags, selection.Size, -1);
                ExampleTreeFuncs::ApplySelectionRequests(ms_io, tree, &selection);
                for (ExampleTreeNode* node : tree->Childs)
                    ExampleTreeFuncs::DrawNode(node, &selection);
                ms_io = BBZGUI::EndMultiSelect();
                ExampleTreeFuncs::ApplySelectionRequests(ms_io, tree, &selection);
            }
            BBZGUI::EndChild();

            BBZGUI::TreePop();
        }

        // Advanced demonstration of BeginMultiSelect()
        // - Showcase clipping.
        // - Showcase deletion.
        // - Showcase basic drag and drop.
        // - Showcase TreeNode variant (note that tree node don't expand in the demo: supporting expanding tree nodes + clipping a separate thing).
        // - Showcase using inside a table.
        IMGUI_DEMO_MARKER("Widgets/Selection State/Multi-Select (advanced)");
        //BBZGUI::SetNextItemOpen(true, BBZGUICond_Once);
        if (BBZGUI::TreeNode("Multi-Select (advanced)"))
        {
            // Options
            enum WidgetType { WidgetType_Selectable, WidgetType_TreeNode };
            static bool use_clipper = true;
            static bool use_deletion = true;
            static bool use_drag_drop = true;
            static bool show_in_table = false;
            static bool show_color_button = true;
            static BBZGUIMultiSelectFlags flags = BBZGUIMultiSelectFlags_ClearOnEscape | BBZGUIMultiSelectFlags_BoxSelect1d;
            static WidgetType widget_type = WidgetType_Selectable;

            if (BBZGUI::TreeNode("Options"))
            {
                if (BBZGUI::RadioButton("Selectables", widget_type == WidgetType_Selectable)) { widget_type = WidgetType_Selectable; }
                BBZGUI::SameLine();
                if (BBZGUI::RadioButton("Tree nodes", widget_type == WidgetType_TreeNode)) { widget_type = WidgetType_TreeNode; }
                BBZGUI::SameLine();
                HelpMarker("TreeNode() is technically supported but... using this correctly is more complicated (you need some sort of linear/random access to your tree, which is suited to advanced trees setups already implementing filters and clipper. We will work toward simplifying and demoing this.\n\nFor now the tree demo is actually a little bit meaningless because it is an empty tree with only root nodes.");
                BBZGUI::Checkbox("Enable clipper", &use_clipper);
                BBZGUI::Checkbox("Enable deletion", &use_deletion);
                BBZGUI::Checkbox("Enable drag & drop", &use_drag_drop);
                BBZGUI::Checkbox("Show in a table", &show_in_table);
                BBZGUI::Checkbox("Show color button", &show_color_button);
                BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_SingleSelect", &flags, BBZGUIMultiSelectFlags_SingleSelect);
                BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_NoSelectAll", &flags, BBZGUIMultiSelectFlags_NoSelectAll);
                BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_NoRangeSelect", &flags, BBZGUIMultiSelectFlags_NoRangeSelect);
                BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_NoAutoSelect", &flags, BBZGUIMultiSelectFlags_NoAutoSelect);
                BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_NoAutoClear", &flags, BBZGUIMultiSelectFlags_NoAutoClear);
                BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_NoAutoClearOnReselect", &flags, BBZGUIMultiSelectFlags_NoAutoClearOnReselect);
                BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_BoxSelect1d", &flags, BBZGUIMultiSelectFlags_BoxSelect1d);
                BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_BoxSelect2d", &flags, BBZGUIMultiSelectFlags_BoxSelect2d);
                BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_BoxSelectNoScroll", &flags, BBZGUIMultiSelectFlags_BoxSelectNoScroll);
                BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_ClearOnEscape", &flags, BBZGUIMultiSelectFlags_ClearOnEscape);
                BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_ClearOnClickVoid", &flags, BBZGUIMultiSelectFlags_ClearOnClickVoid);
                if (BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_ScopeWindow", &flags, BBZGUIMultiSelectFlags_ScopeWindow) && (flags & BBZGUIMultiSelectFlags_ScopeWindow))
                    flags &= ~BBZGUIMultiSelectFlags_ScopeRect;
                if (BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_ScopeRect", &flags, BBZGUIMultiSelectFlags_ScopeRect) && (flags & BBZGUIMultiSelectFlags_ScopeRect))
                    flags &= ~BBZGUIMultiSelectFlags_ScopeWindow;
                if (BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_SelectOnClick", &flags, BBZGUIMultiSelectFlags_SelectOnClick) && (flags & BBZGUIMultiSelectFlags_SelectOnClick))
                    flags &= ~BBZGUIMultiSelectFlags_SelectOnClickRelease;
                if (BBZGUI::CheckboxFlags("BBZGUIMultiSelectFlags_SelectOnClickRelease", &flags, BBZGUIMultiSelectFlags_SelectOnClickRelease) && (flags & BBZGUIMultiSelectFlags_SelectOnClickRelease))
                    flags &= ~BBZGUIMultiSelectFlags_SelectOnClick;
                BBZGUI::SameLine(); HelpMarker("Allow dragging an unselected item without altering selection.");
                BBZGUI::TreePop();
            }

            // Initialize default list with 1000 items.
            // Use default selection.Adapter: Pass index to SetNextItemSelectionUserData(), store index in Selection
            static ImVector<int> items;
            static int items_next_id = 0;
            if (items_next_id == 0) { for (int n = 0; n < 1000; n++) { items.push_back(items_next_id++); } }
            static ExampleSelectionWithDeletion selection;
            static bool request_deletion_from_menu = false; // Queue deletion triggered from context menu

            BBZGUI::Text("Selection size: %d/%d", selection.Size, items.Size);

            const float items_height = (widget_type == WidgetType_TreeNode) ? BBZGUI::GetTextLineHeight() : BBZGUI::GetTextLineHeightWithSpacing();
            BBZGUI::SetNextWindowContentSize(ImVec2(0.0f, items.Size * items_height));
            if (BBZGUI::BeginChild("##Basket", ImVec2(-FLT_MIN, BBZGUI::GetFontSize() * 20), BBZGUIChildFlags_FrameStyle | BBZGUIChildFlags_ResizeY))
            {
                ImVec2 color_button_sz(BBZGUI::GetFontSize(), BBZGUI::GetFontSize());
                if (widget_type == WidgetType_TreeNode)
                    BBZGUI::PushStyleVarY(BBZGUIStyleVar_ItemSpacing, 0.0f);

                BBZGUIMultiSelectIO* ms_io = BBZGUI::BeginMultiSelect(flags, selection.Size, items.Size);
                selection.ApplyRequests(ms_io);

                const bool want_delete = (BBZGUI::Shortcut(BBZGUIKey_Delete, BBZGUIInputFlags_Repeat) && (selection.Size > 0)) || request_deletion_from_menu;
                const int item_curr_idx_to_focus = want_delete ? selection.ApplyDeletionPreLoop(ms_io, items.Size) : -1;
                request_deletion_from_menu = false;

                if (show_in_table)
                {
                    if (widget_type == WidgetType_TreeNode)
                        BBZGUI::PushStyleVar(BBZGUIStyleVar_CellPadding, ImVec2(0.0f, 0.0f));
                    BBZGUI::BeginTable("##Split", 2, BBZGUITableFlags_Resizable | BBZGUITableFlags_NoSavedSettings | BBZGUITableFlags_NoPadOuterX);
                    BBZGUI::TableSetupColumn("", BBZGUITableColumnFlags_WidthStretch, 0.70f);
                    BBZGUI::TableSetupColumn("", BBZGUITableColumnFlags_WidthStretch, 0.30f);
                    //BBZGUI::PushStyleVar(BBZGUIStyleVar_ItemSpacingY, 0.0f);
                }

                BBZGUIListClipper clipper;
                if (use_clipper)
                {
                    clipper.Begin(items.Size);
                    if (item_curr_idx_to_focus != -1)
                        clipper.IncludeItemByIndex(item_curr_idx_to_focus); // Ensure focused item is not clipped.
                    if (ms_io->RangeSrcItem != -1)
                        clipper.IncludeItemByIndex((int)ms_io->RangeSrcItem); // Ensure RangeSrc item is not clipped.
                }

                while (!use_clipper || clipper.Step())
                {
                    const int item_begin = use_clipper ? clipper.DisplayStart : 0;
                    const int item_end = use_clipper ? clipper.DisplayEnd : items.Size;
                    for (int n = item_begin; n < item_end; n++)
                    {
                        if (show_in_table)
                            BBZGUI::TableNextColumn();

                        const int item_id = items[n];
                        const char* item_category = ExampleNames[item_id % IM_ARRAYSIZE(ExampleNames)];
                        char label[64];
                        sprintf(label, "Object %05d: %s", item_id, item_category);

                        // IMPORTANT: for deletion refocus to work we need object ID to be stable,
                        // aka not depend on their index in the list. Here we use our persistent item_id
                        // instead of index to build a unique ID that will persist.
                        // (If we used PushID(index) instead, focus wouldn't be restored correctly after deletion).
                        BBZGUI::PushID(item_id);

                        // Emit a color button, to test that Shift+LeftArrow landing on an item that is not part
                        // of the selection scope doesn't erroneously alter our selection.
                        if (show_color_button)
                        {
                            ImU32 dummy_col = (ImU32)((unsigned int)n * 0xC250B74B) | IM_COL32_A_MASK;
                            BBZGUI::ColorButton("##", ImColor(dummy_col), BBZGUIColorEditFlags_NoTooltip, color_button_sz);
                            BBZGUI::SameLine();
                        }

                        // Submit item
                        bool item_is_selected = selection.Contains((BBZGUIID)n);
                        bool item_is_open = false;
                        BBZGUI::SetNextItemSelectionUserData(n);
                        if (widget_type == WidgetType_Selectable)
                        {
                            BBZGUI::Selectable(label, item_is_selected, BBZGUISelectableFlags_None);
                        }
                        else if (widget_type == WidgetType_TreeNode)
                        {
                            BBZGUITreeNodeFlags tree_node_flags = BBZGUITreeNodeFlags_SpanAvailWidth | BBZGUITreeNodeFlags_OpenOnArrow | BBZGUITreeNodeFlags_OpenOnDoubleClick;
                            if (item_is_selected)
                                tree_node_flags |= BBZGUITreeNodeFlags_Selected;
                            item_is_open = BBZGUI::TreeNodeEx(label, tree_node_flags);
                        }

                        // Focus (for after deletion)
                        if (item_curr_idx_to_focus == n)
                            BBZGUI::SetKeyboardFocusHere(-1);

                        // Drag and Drop
                        if (use_drag_drop && BBZGUI::BeginDragDropSource())
                        {
                            // Create payload with full selection OR single unselected item.
                            // (the later is only possible when using BBZGUIMultiSelectFlags_SelectOnClickRelease)
                            if (BBZGUI::GetDragDropPayload() == NULL)
                            {
                                ImVector<int> payload_items;
                                void* it = NULL;
                                BBZGUIID id = 0;
                                if (!item_is_selected)
                                    payload_items.push_back(item_id);
                                else
                                    while (selection.GetNextSelectedItem(&it, &id))
                                        payload_items.push_back((int)id);
                                BBZGUI::SetDragDropPayload("MULTISELECT_DEMO_ITEMS", payload_items.Data, (size_t)payload_items.size_in_bytes());
                            }

                            // Display payload content in tooltip
                            const BBZGUIPayload* payload = BBZGUI::GetDragDropPayload();
                            const int* payload_items = (int*)payload->Data;
                            const int payload_count = (int)payload->DataSize / (int)sizeof(int);
                            if (payload_count == 1)
                                BBZGUI::Text("Object %05d: %s", payload_items[0], ExampleNames[payload_items[0] % IM_ARRAYSIZE(ExampleNames)]);
                            else
                                BBZGUI::Text("Dragging %d objects", payload_count);

                            BBZGUI::EndDragDropSource();
                        }

                        if (widget_type == WidgetType_TreeNode && item_is_open)
                            BBZGUI::TreePop();

                        // Right-click: context menu
                        if (BBZGUI::BeginPopupContextItem())
                        {
                            BBZGUI::BeginDisabled(!use_deletion || selection.Size == 0);
                            sprintf(label, "Delete %d item(s)###DeleteSelected", selection.Size);
                            if (BBZGUI::Selectable(label))
                                request_deletion_from_menu = true;
                            BBZGUI::EndDisabled();
                            BBZGUI::Selectable("Close");
                            BBZGUI::EndPopup();
                        }

                        // Demo content within a table
                        if (show_in_table)
                        {
                            BBZGUI::TableNextColumn();
                            BBZGUI::SetNextItemWidth(-FLT_MIN);
                            BBZGUI::PushStyleVar(BBZGUIStyleVar_FramePadding, ImVec2(0, 0));
                            BBZGUI::InputText("###NoLabel", (char*)(void*)item_category, strlen(item_category), BBZGUIInputTextFlags_ReadOnly);
                            BBZGUI::PopStyleVar();
                        }

                        BBZGUI::PopID();
                    }
                    if (!use_clipper)
                        break;
                }

                if (show_in_table)
                {
                    BBZGUI::EndTable();
                    if (widget_type == WidgetType_TreeNode)
                        BBZGUI::PopStyleVar();
                }

                // Apply multi-select requests
                ms_io = BBZGUI::EndMultiSelect();
                selection.ApplyRequests(ms_io);
                if (want_delete)
                    selection.ApplyDeletionPostLoop(ms_io, items, item_curr_idx_to_focus);

                if (widget_type == WidgetType_TreeNode)
                    BBZGUI::PopStyleVar();
            }
            BBZGUI::EndChild();
            BBZGUI::TreePop();
        }
        BBZGUI::TreePop();
    }
}

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowLayout()
//-----------------------------------------------------------------------------

static void ShowDemoWindowLayout()
{
    IMGUI_DEMO_MARKER("Layout");
    if (!BBZGUI::CollapsingHeader("Layout & Scrolling"))
        return;

    IMGUI_DEMO_MARKER("Layout/Child windows");
    if (BBZGUI::TreeNode("Child windows"))
    {
        BBZGUI::SeparatorText("Child windows");

        HelpMarker("Use child windows to begin into a self-contained independent scrolling/clipping regions within a host window.");
        static bool disable_mouse_wheel = false;
        static bool disable_menu = false;
        BBZGUI::Checkbox("Disable Mouse Wheel", &disable_mouse_wheel);
        BBZGUI::Checkbox("Disable Menu", &disable_menu);

        // Child 1: no border, enable horizontal scrollbar
        {
            BBZGUIWindowFlags window_flags = BBZGUIWindowFlags_HorizontalScrollbar;
            if (disable_mouse_wheel)
                window_flags |= BBZGUIWindowFlags_NoScrollWithMouse;
            BBZGUI::BeginChild("ChildL", ImVec2(BBZGUI::GetContentRegionAvail().x * 0.5f, 260), BBZGUIChildFlags_None, window_flags);
            for (int i = 0; i < 100; i++)
                BBZGUI::Text("%04d: scrollable region", i);
            BBZGUI::EndChild();
        }

        BBZGUI::SameLine();

        // Child 2: rounded border
        {
            BBZGUIWindowFlags window_flags = BBZGUIWindowFlags_None;
            if (disable_mouse_wheel)
                window_flags |= BBZGUIWindowFlags_NoScrollWithMouse;
            if (!disable_menu)
                window_flags |= BBZGUIWindowFlags_MenuBar;
            BBZGUI::PushStyleVar(BBZGUIStyleVar_ChildRounding, 5.0f);
            BBZGUI::BeginChild("ChildR", ImVec2(0, 260), BBZGUIChildFlags_Borders, window_flags);
            if (!disable_menu && BBZGUI::BeginMenuBar())
            {
                if (BBZGUI::BeginMenu("Menu"))
                {
                    ShowExampleMenuFile();
                    BBZGUI::EndMenu();
                }
                BBZGUI::EndMenuBar();
            }
            if (BBZGUI::BeginTable("split", 2, BBZGUITableFlags_Resizable | BBZGUITableFlags_NoSavedSettings))
            {
                for (int i = 0; i < 100; i++)
                {
                    char buf[32];
                    sprintf(buf, "%03d", i);
                    BBZGUI::TableNextColumn();
                    BBZGUI::Button(buf, ImVec2(-FLT_MIN, 0.0f));
                }
                BBZGUI::EndTable();
            }
            BBZGUI::EndChild();
            BBZGUI::PopStyleVar();
        }

        // Child 3: manual-resize
        BBZGUI::SeparatorText("Manual-resize");
        {
            HelpMarker("Drag bottom border to resize. Double-click bottom border to auto-fit to vertical contents.");
            //if (BBZGUI::Button("Set Height to 200"))
            //    BBZGUI::SetNextWindowSize(ImVec2(-FLT_MIN, 200.0f));

            BBZGUI::PushStyleColor(BBZGUICol_ChildBg, BBZGUI::GetStyleColorVec4(BBZGUICol_FrameBg));
            if (BBZGUI::BeginChild("ResizableChild", ImVec2(-FLT_MIN, BBZGUI::GetTextLineHeightWithSpacing() * 8), BBZGUIChildFlags_Borders | BBZGUIChildFlags_ResizeY))
                for (int n = 0; n < 10; n++)
                    BBZGUI::Text("Line %04d", n);
            BBZGUI::PopStyleColor();
            BBZGUI::EndChild();
        }

        // Child 4: auto-resizing height with a limit
        BBZGUI::SeparatorText("Auto-resize with constraints");
        {
            static int draw_lines = 3;
            static int max_height_in_lines = 10;
            BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 8);
            BBZGUI::DragInt("Lines Count", &draw_lines, 0.2f);
            BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 8);
            BBZGUI::DragInt("Max Height (in Lines)", &max_height_in_lines, 0.2f);

            BBZGUI::SetNextWindowSizeConstraints(ImVec2(0.0f, BBZGUI::GetTextLineHeightWithSpacing() * 1), ImVec2(FLT_MAX, BBZGUI::GetTextLineHeightWithSpacing() * max_height_in_lines));
            if (BBZGUI::BeginChild("ConstrainedChild", ImVec2(-FLT_MIN, 0.0f), BBZGUIChildFlags_Borders | BBZGUIChildFlags_AutoResizeY))
                for (int n = 0; n < draw_lines; n++)
                    BBZGUI::Text("Line %04d", n);
            BBZGUI::EndChild();
        }

        BBZGUI::SeparatorText("Misc/Advanced");

        // Demonstrate a few extra things
        // - Changing BBZGUICol_ChildBg (which is transparent black in default styles)
        // - Using SetCursorPos() to position child window (the child window is an item from the POV of parent window)
        //   You can also call SetNextWindowPos() to position the child window. The parent window will effectively
        //   layout from this position.
        // - Using BBZGUI::GetItemRectMin/Max() to query the "item" state (because the child window is an item from
        //   the POV of the parent window). See 'Demo->Querying Status (Edited/Active/Hovered etc.)' for details.
        {
            static int offset_x = 0;
            static bool override_bg_color = true;
            static BBZGUIChildFlags child_flags = BBZGUIChildFlags_Borders | BBZGUIChildFlags_ResizeX | BBZGUIChildFlags_ResizeY;
            BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 8);
            BBZGUI::DragInt("Offset X", &offset_x, 1.0f, -1000, 1000);
            BBZGUI::Checkbox("Override ChildBg color", &override_bg_color);
            BBZGUI::CheckboxFlags("BBZGUIChildFlags_Borders", &child_flags, BBZGUIChildFlags_Borders);
            BBZGUI::CheckboxFlags("BBZGUIChildFlags_AlwaysUseWindowPadding", &child_flags, BBZGUIChildFlags_AlwaysUseWindowPadding);
            BBZGUI::CheckboxFlags("BBZGUIChildFlags_ResizeX", &child_flags, BBZGUIChildFlags_ResizeX);
            BBZGUI::CheckboxFlags("BBZGUIChildFlags_ResizeY", &child_flags, BBZGUIChildFlags_ResizeY);
            BBZGUI::CheckboxFlags("BBZGUIChildFlags_FrameStyle", &child_flags, BBZGUIChildFlags_FrameStyle);
            BBZGUI::SameLine(); HelpMarker("Style the child window like a framed item: use FrameBg, FrameRounding, FrameBorderSize, FramePadding instead of ChildBg, ChildRounding, ChildBorderSize, WindowPadding.");
            if (child_flags & BBZGUIChildFlags_FrameStyle)
                override_bg_color = false;

            BBZGUI::SetCursorPosX(BBZGUI::GetCursorPosX() + (float)offset_x);
            if (override_bg_color)
                BBZGUI::PushStyleColor(BBZGUICol_ChildBg, IM_COL32(255, 0, 0, 100));
            BBZGUI::BeginChild("Red", ImVec2(200, 100), child_flags, BBZGUIWindowFlags_None);
            if (override_bg_color)
                BBZGUI::PopStyleColor();

            for (int n = 0; n < 50; n++)
                BBZGUI::Text("Some test %d", n);
            BBZGUI::EndChild();
            bool child_is_hovered = BBZGUI::IsItemHovered();
            ImVec2 child_rect_min = BBZGUI::GetItemRectMin();
            ImVec2 child_rect_max = BBZGUI::GetItemRectMax();
            BBZGUI::Text("Hovered: %d", child_is_hovered);
            BBZGUI::Text("Rect of child window is: (%.0f,%.0f) (%.0f,%.0f)", child_rect_min.x, child_rect_min.y, child_rect_max.x, child_rect_max.y);
        }

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Widgets Width");
    if (BBZGUI::TreeNode("Widgets Width"))
    {
        static float f = 0.0f;
        static bool show_indented_items = true;
        BBZGUI::Checkbox("Show indented items", &show_indented_items);

        // Use SetNextItemWidth() to set the width of a single upcoming item.
        // Use PushItemWidth()/PopItemWidth() to set the width of a group of items.
        // In real code use you'll probably want to choose width values that are proportional to your font size
        // e.g. Using '20.0f * GetFontSize()' as width instead of '200.0f', etc.

        BBZGUI::Text("SetNextItemWidth/PushItemWidth(100)");
        BBZGUI::SameLine(); HelpMarker("Fixed width.");
        BBZGUI::PushItemWidth(100);
        BBZGUI::DragFloat("float##1b", &f);
        if (show_indented_items)
        {
            BBZGUI::Indent();
            BBZGUI::DragFloat("float (indented)##1b", &f);
            BBZGUI::Unindent();
        }
        BBZGUI::PopItemWidth();

        BBZGUI::Text("SetNextItemWidth/PushItemWidth(-100)");
        BBZGUI::SameLine(); HelpMarker("Align to right edge minus 100");
        BBZGUI::PushItemWidth(-100);
        BBZGUI::DragFloat("float##2a", &f);
        if (show_indented_items)
        {
            BBZGUI::Indent();
            BBZGUI::DragFloat("float (indented)##2b", &f);
            BBZGUI::Unindent();
        }
        BBZGUI::PopItemWidth();

        BBZGUI::Text("SetNextItemWidth/PushItemWidth(GetContentRegionAvail().x * 0.5f)");
        BBZGUI::SameLine(); HelpMarker("Half of available width.\n(~ right-cursor_pos)\n(works within a column set)");
        BBZGUI::PushItemWidth(BBZGUI::GetContentRegionAvail().x * 0.5f);
        BBZGUI::DragFloat("float##3a", &f);
        if (show_indented_items)
        {
            BBZGUI::Indent();
            BBZGUI::DragFloat("float (indented)##3b", &f);
            BBZGUI::Unindent();
        }
        BBZGUI::PopItemWidth();

        BBZGUI::Text("SetNextItemWidth/PushItemWidth(-GetContentRegionAvail().x * 0.5f)");
        BBZGUI::SameLine(); HelpMarker("Align to right edge minus half");
        BBZGUI::PushItemWidth(-BBZGUI::GetContentRegionAvail().x * 0.5f);
        BBZGUI::DragFloat("float##4a", &f);
        if (show_indented_items)
        {
            BBZGUI::Indent();
            BBZGUI::DragFloat("float (indented)##4b", &f);
            BBZGUI::Unindent();
        }
        BBZGUI::PopItemWidth();

        // Demonstrate using PushItemWidth to surround three items.
        // Calling SetNextItemWidth() before each of them would have the same effect.
        BBZGUI::Text("SetNextItemWidth/PushItemWidth(-FLT_MIN)");
        BBZGUI::SameLine(); HelpMarker("Align to right edge");
        BBZGUI::PushItemWidth(-FLT_MIN);
        BBZGUI::DragFloat("##float5a", &f);
        if (show_indented_items)
        {
            BBZGUI::Indent();
            BBZGUI::DragFloat("float (indented)##5b", &f);
            BBZGUI::Unindent();
        }
        BBZGUI::PopItemWidth();

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Basic Horizontal Layout");
    if (BBZGUI::TreeNode("Basic Horizontal Layout"))
    {
        BBZGUI::TextWrapped("(Use BBZGUI::SameLine() to keep adding items to the right of the preceding item)");

        // Text
        IMGUI_DEMO_MARKER("Layout/Basic Horizontal Layout/SameLine");
        BBZGUI::Text("Two items: Hello"); BBZGUI::SameLine();
        BBZGUI::TextColored(ImVec4(1, 1, 0, 1), "Sailor");

        // Adjust spacing
        BBZGUI::Text("More spacing: Hello"); BBZGUI::SameLine(0, 20);
        BBZGUI::TextColored(ImVec4(1, 1, 0, 1), "Sailor");

        // Button
        BBZGUI::AlignTextToFramePadding();
        BBZGUI::Text("Normal buttons"); BBZGUI::SameLine();
        BBZGUI::Button("Banana"); BBZGUI::SameLine();
        BBZGUI::Button("Apple"); BBZGUI::SameLine();
        BBZGUI::Button("Corniflower");

        // Button
        BBZGUI::Text("Small buttons"); BBZGUI::SameLine();
        BBZGUI::SmallButton("Like this one"); BBZGUI::SameLine();
        BBZGUI::Text("can fit within a text block.");

        // Aligned to arbitrary position. Easy/cheap column.
        IMGUI_DEMO_MARKER("Layout/Basic Horizontal Layout/SameLine (with offset)");
        BBZGUI::Text("Aligned");
        BBZGUI::SameLine(150); BBZGUI::Text("x=150");
        BBZGUI::SameLine(300); BBZGUI::Text("x=300");
        BBZGUI::Text("Aligned");
        BBZGUI::SameLine(150); BBZGUI::SmallButton("x=150");
        BBZGUI::SameLine(300); BBZGUI::SmallButton("x=300");

        // Checkbox
        IMGUI_DEMO_MARKER("Layout/Basic Horizontal Layout/SameLine (more)");
        static bool c1 = false, c2 = false, c3 = false, c4 = false;
        BBZGUI::Checkbox("My", &c1); BBZGUI::SameLine();
        BBZGUI::Checkbox("Tailor", &c2); BBZGUI::SameLine();
        BBZGUI::Checkbox("Is", &c3); BBZGUI::SameLine();
        BBZGUI::Checkbox("Rich", &c4);

        // Various
        static float f0 = 1.0f, f1 = 2.0f, f2 = 3.0f;
        BBZGUI::PushItemWidth(80);
        const char* items[] = { "AAAA", "BBBB", "CCCC", "DDDD" };
        static int item = -1;
        BBZGUI::Combo("Combo", &item, items, IM_ARRAYSIZE(items)); BBZGUI::SameLine();
        BBZGUI::SliderFloat("X", &f0, 0.0f, 5.0f); BBZGUI::SameLine();
        BBZGUI::SliderFloat("Y", &f1, 0.0f, 5.0f); BBZGUI::SameLine();
        BBZGUI::SliderFloat("Z", &f2, 0.0f, 5.0f);
        BBZGUI::PopItemWidth();

        BBZGUI::PushItemWidth(80);
        BBZGUI::Text("Lists:");
        static int selection[4] = { 0, 1, 2, 3 };
        for (int i = 0; i < 4; i++)
        {
            if (i > 0) BBZGUI::SameLine();
            BBZGUI::PushID(i);
            BBZGUI::ListBox("", &selection[i], items, IM_ARRAYSIZE(items));
            BBZGUI::PopID();
            //BBZGUI::SetItemTooltip("ListBox %d hovered", i);
        }
        BBZGUI::PopItemWidth();

        // Dummy
        IMGUI_DEMO_MARKER("Layout/Basic Horizontal Layout/Dummy");
        ImVec2 button_sz(40, 40);
        BBZGUI::Button("A", button_sz); BBZGUI::SameLine();
        BBZGUI::Dummy(button_sz); BBZGUI::SameLine();
        BBZGUI::Button("B", button_sz);

        // Manually wrapping
        // (we should eventually provide this as an automatic layout feature, but for now you can do it manually)
        IMGUI_DEMO_MARKER("Layout/Basic Horizontal Layout/Manual wrapping");
        BBZGUI::Text("Manual wrapping:");
        BBZGUIStyle& style = BBZGUI::GetStyle();
        int buttons_count = 20;
        float window_visible_x2 = BBZGUI::GetCursorScreenPos().x + BBZGUI::GetContentRegionAvail().x;
        for (int n = 0; n < buttons_count; n++)
        {
            BBZGUI::PushID(n);
            BBZGUI::Button("Box", button_sz);
            float last_button_x2 = BBZGUI::GetItemRectMax().x;
            float next_button_x2 = last_button_x2 + style.ItemSpacing.x + button_sz.x; // Expected position if next button was on same line
            if (n + 1 < buttons_count && next_button_x2 < window_visible_x2)
                BBZGUI::SameLine();
            BBZGUI::PopID();
        }

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Groups");
    if (BBZGUI::TreeNode("Groups"))
    {
        HelpMarker(
            "BeginGroup() basically locks the horizontal position for new line. "
            "EndGroup() bundles the whole group so that you can use \"item\" functions such as "
            "IsItemHovered()/IsItemActive() or SameLine() etc. on the whole group.");
        BBZGUI::BeginGroup();
        {
            BBZGUI::BeginGroup();
            BBZGUI::Button("AAA");
            BBZGUI::SameLine();
            BBZGUI::Button("BBB");
            BBZGUI::SameLine();
            BBZGUI::BeginGroup();
            BBZGUI::Button("CCC");
            BBZGUI::Button("DDD");
            BBZGUI::EndGroup();
            BBZGUI::SameLine();
            BBZGUI::Button("EEE");
            BBZGUI::EndGroup();
            BBZGUI::SetItemTooltip("First group hovered");
        }
        // Capture the group size and create widgets using the same size
        ImVec2 size = BBZGUI::GetItemRectSize();
        const float values[5] = { 0.5f, 0.20f, 0.80f, 0.60f, 0.25f };
        BBZGUI::PlotHistogram("##values", values, IM_ARRAYSIZE(values), 0, NULL, 0.0f, 1.0f, size);

        BBZGUI::Button("ACTION", ImVec2((size.x - BBZGUI::GetStyle().ItemSpacing.x) * 0.5f, size.y));
        BBZGUI::SameLine();
        BBZGUI::Button("REACTION", ImVec2((size.x - BBZGUI::GetStyle().ItemSpacing.x) * 0.5f, size.y));
        BBZGUI::EndGroup();
        BBZGUI::SameLine();

        BBZGUI::Button("LEVERAGE\nBUZZWORD", size);
        BBZGUI::SameLine();

        if (BBZGUI::BeginListBox("List", size))
        {
            BBZGUI::Selectable("Selected", true);
            BBZGUI::Selectable("Not Selected", false);
            BBZGUI::EndListBox();
        }

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Text Baseline Alignment");
    if (BBZGUI::TreeNode("Text Baseline Alignment"))
    {
        {
            BBZGUI::BulletText("Text baseline:");
            BBZGUI::SameLine(); HelpMarker(
                "This is testing the vertical alignment that gets applied on text to keep it aligned with widgets. "
                "Lines only composed of text or \"small\" widgets use less vertical space than lines with framed widgets.");
            BBZGUI::Indent();

            BBZGUI::Text("KO Blahblah"); BBZGUI::SameLine();
            BBZGUI::Button("Some framed item"); BBZGUI::SameLine();
            HelpMarker("Baseline of button will look misaligned with text..");

            // If your line starts with text, call AlignTextToFramePadding() to align text to upcoming widgets.
            // (because we don't know what's coming after the Text() statement, we need to move the text baseline
            // down by FramePadding.y ahead of time)
            BBZGUI::AlignTextToFramePadding();
            BBZGUI::Text("OK Blahblah"); BBZGUI::SameLine();
            BBZGUI::Button("Some framed item##2"); BBZGUI::SameLine();
            HelpMarker("We call AlignTextToFramePadding() to vertically align the text baseline by +FramePadding.y");

            // SmallButton() uses the same vertical padding as Text
            BBZGUI::Button("TEST##1"); BBZGUI::SameLine();
            BBZGUI::Text("TEST"); BBZGUI::SameLine();
            BBZGUI::SmallButton("TEST##2");

            // If your line starts with text, call AlignTextToFramePadding() to align text to upcoming widgets.
            BBZGUI::AlignTextToFramePadding();
            BBZGUI::Text("Text aligned to framed item"); BBZGUI::SameLine();
            BBZGUI::Button("Item##1"); BBZGUI::SameLine();
            BBZGUI::Text("Item"); BBZGUI::SameLine();
            BBZGUI::SmallButton("Item##2"); BBZGUI::SameLine();
            BBZGUI::Button("Item##3");

            BBZGUI::Unindent();
        }

        BBZGUI::Spacing();

        {
            BBZGUI::BulletText("Multi-line text:");
            BBZGUI::Indent();
            BBZGUI::Text("One\nTwo\nThree"); BBZGUI::SameLine();
            BBZGUI::Text("Hello\nWorld"); BBZGUI::SameLine();
            BBZGUI::Text("Banana");

            BBZGUI::Text("Banana"); BBZGUI::SameLine();
            BBZGUI::Text("Hello\nWorld"); BBZGUI::SameLine();
            BBZGUI::Text("One\nTwo\nThree");

            BBZGUI::Button("HOP##1"); BBZGUI::SameLine();
            BBZGUI::Text("Banana"); BBZGUI::SameLine();
            BBZGUI::Text("Hello\nWorld"); BBZGUI::SameLine();
            BBZGUI::Text("Banana");

            BBZGUI::Button("HOP##2"); BBZGUI::SameLine();
            BBZGUI::Text("Hello\nWorld"); BBZGUI::SameLine();
            BBZGUI::Text("Banana");
            BBZGUI::Unindent();
        }

        BBZGUI::Spacing();

        {
            BBZGUI::BulletText("Misc items:");
            BBZGUI::Indent();

            // SmallButton() sets FramePadding to zero. Text baseline is aligned to match baseline of previous Button.
            BBZGUI::Button("80x80", ImVec2(80, 80));
            BBZGUI::SameLine();
            BBZGUI::Button("50x50", ImVec2(50, 50));
            BBZGUI::SameLine();
            BBZGUI::Button("Button()");
            BBZGUI::SameLine();
            BBZGUI::SmallButton("SmallButton()");

            // Tree
            const float spacing = BBZGUI::GetStyle().ItemInnerSpacing.x;
            BBZGUI::Button("Button##1");
            BBZGUI::SameLine(0.0f, spacing);
            if (BBZGUI::TreeNode("Node##1"))
            {
                // Placeholder tree data
                for (int i = 0; i < 6; i++)
                    BBZGUI::BulletText("Item %d..", i);
                BBZGUI::TreePop();
            }

            // Vertically align text node a bit lower so it'll be vertically centered with upcoming widget.
            // Otherwise you can use SmallButton() (smaller fit).
            BBZGUI::AlignTextToFramePadding();

            // Common mistake to avoid: if we want to SameLine after TreeNode we need to do it before we add
            // other contents below the node.
            bool node_open = BBZGUI::TreeNode("Node##2");
            BBZGUI::SameLine(0.0f, spacing); BBZGUI::Button("Button##2");
            if (node_open)
            {
                // Placeholder tree data
                for (int i = 0; i < 6; i++)
                    BBZGUI::BulletText("Item %d..", i);
                BBZGUI::TreePop();
            }

            // Bullet
            BBZGUI::Button("Button##3");
            BBZGUI::SameLine(0.0f, spacing);
            BBZGUI::BulletText("Bullet text");

            BBZGUI::AlignTextToFramePadding();
            BBZGUI::BulletText("Node");
            BBZGUI::SameLine(0.0f, spacing); BBZGUI::Button("Button##4");
            BBZGUI::Unindent();
        }

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Scrolling");
    if (BBZGUI::TreeNode("Scrolling"))
    {
        // Vertical scroll functions
        IMGUI_DEMO_MARKER("Layout/Scrolling/Vertical");
        HelpMarker("Use SetScrollHereY() or SetScrollFromPosY() to scroll to a given vertical position.");

        static int track_item = 50;
        static bool enable_track = true;
        static bool enable_extra_decorations = false;
        static float scroll_to_off_px = 0.0f;
        static float scroll_to_pos_px = 200.0f;

        BBZGUI::Checkbox("Decoration", &enable_extra_decorations);

        BBZGUI::Checkbox("Track", &enable_track);
        BBZGUI::PushItemWidth(100);
        BBZGUI::SameLine(140); enable_track |= BBZGUI::DragInt("##item", &track_item, 0.25f, 0, 99, "Item = %d");

        bool scroll_to_off = BBZGUI::Button("Scroll Offset");
        BBZGUI::SameLine(140); scroll_to_off |= BBZGUI::DragFloat("##off", &scroll_to_off_px, 1.00f, 0, FLT_MAX, "+%.0f px");

        bool scroll_to_pos = BBZGUI::Button("Scroll To Pos");
        BBZGUI::SameLine(140); scroll_to_pos |= BBZGUI::DragFloat("##pos", &scroll_to_pos_px, 1.00f, -10, FLT_MAX, "X/Y = %.0f px");
        BBZGUI::PopItemWidth();

        if (scroll_to_off || scroll_to_pos)
            enable_track = false;

        BBZGUIStyle& style = BBZGUI::GetStyle();
        float child_w = (BBZGUI::GetContentRegionAvail().x - 4 * style.ItemSpacing.x) / 5;
        if (child_w < 1.0f)
            child_w = 1.0f;
        BBZGUI::PushID("##VerticalScrolling");
        for (int i = 0; i < 5; i++)
        {
            if (i > 0) BBZGUI::SameLine();
            BBZGUI::BeginGroup();
            const char* names[] = { "Top", "25%", "Center", "75%", "Bottom" };
            BBZGUI::TextUnformatted(names[i]);

            const BBZGUIWindowFlags child_flags = enable_extra_decorations ? BBZGUIWindowFlags_MenuBar : 0;
            const BBZGUIID child_id = BBZGUI::GetID((void*)(intptr_t)i);
            const bool child_is_visible = BBZGUI::BeginChild(child_id, ImVec2(child_w, 200.0f), BBZGUIChildFlags_Borders, child_flags);
            if (BBZGUI::BeginMenuBar())
            {
                BBZGUI::TextUnformatted("abc");
                BBZGUI::EndMenuBar();
            }
            if (scroll_to_off)
                BBZGUI::SetScrollY(scroll_to_off_px);
            if (scroll_to_pos)
                BBZGUI::SetScrollFromPosY(BBZGUI::GetCursorStartPos().y + scroll_to_pos_px, i * 0.25f);
            if (child_is_visible) // Avoid calling SetScrollHereY when running with culled items
            {
                for (int item = 0; item < 100; item++)
                {
                    if (enable_track && item == track_item)
                    {
                        BBZGUI::TextColored(ImVec4(1, 1, 0, 1), "Item %d", item);
                        BBZGUI::SetScrollHereY(i * 0.25f); // 0.0f:top, 0.5f:center, 1.0f:bottom
                    }
                    else
                    {
                        BBZGUI::Text("Item %d", item);
                    }
                }
            }
            float scroll_y = BBZGUI::GetScrollY();
            float scroll_max_y = BBZGUI::GetScrollMaxY();
            BBZGUI::EndChild();
            BBZGUI::Text("%.0f/%.0f", scroll_y, scroll_max_y);
            BBZGUI::EndGroup();
        }
        BBZGUI::PopID();

        // Horizontal scroll functions
        IMGUI_DEMO_MARKER("Layout/Scrolling/Horizontal");
        BBZGUI::Spacing();
        HelpMarker(
            "Use SetScrollHereX() or SetScrollFromPosX() to scroll to a given horizontal position.\n\n"
            "Because the clipping rectangle of most window hides half worth of WindowPadding on the "
            "left/right, using SetScrollFromPosX(+1) will usually result in clipped text whereas the "
            "equivalent SetScrollFromPosY(+1) wouldn't.");
        BBZGUI::PushID("##HorizontalScrolling");
        for (int i = 0; i < 5; i++)
        {
            float child_height = BBZGUI::GetTextLineHeight() + style.ScrollbarSize + style.WindowPadding.y * 2.0f;
            BBZGUIWindowFlags child_flags = BBZGUIWindowFlags_HorizontalScrollbar | (enable_extra_decorations ? BBZGUIWindowFlags_AlwaysVerticalScrollbar : 0);
            BBZGUIID child_id = BBZGUI::GetID((void*)(intptr_t)i);
            bool child_is_visible = BBZGUI::BeginChild(child_id, ImVec2(-100, child_height), BBZGUIChildFlags_Borders, child_flags);
            if (scroll_to_off)
                BBZGUI::SetScrollX(scroll_to_off_px);
            if (scroll_to_pos)
                BBZGUI::SetScrollFromPosX(BBZGUI::GetCursorStartPos().x + scroll_to_pos_px, i * 0.25f);
            if (child_is_visible) // Avoid calling SetScrollHereY when running with culled items
            {
                for (int item = 0; item < 100; item++)
                {
                    if (item > 0)
                        BBZGUI::SameLine();
                    if (enable_track && item == track_item)
                    {
                        BBZGUI::TextColored(ImVec4(1, 1, 0, 1), "Item %d", item);
                        BBZGUI::SetScrollHereX(i * 0.25f); // 0.0f:left, 0.5f:center, 1.0f:right
                    }
                    else
                    {
                        BBZGUI::Text("Item %d", item);
                    }
                }
            }
            float scroll_x = BBZGUI::GetScrollX();
            float scroll_max_x = BBZGUI::GetScrollMaxX();
            BBZGUI::EndChild();
            BBZGUI::SameLine();
            const char* names[] = { "Left", "25%", "Center", "75%", "Right" };
            BBZGUI::Text("%s\n%.0f/%.0f", names[i], scroll_x, scroll_max_x);
            BBZGUI::Spacing();
        }
        BBZGUI::PopID();

        // Miscellaneous Horizontal Scrolling Demo
        IMGUI_DEMO_MARKER("Layout/Scrolling/Horizontal (more)");
        HelpMarker(
            "Horizontal scrolling for a window is enabled via the BBZGUIWindowFlags_HorizontalScrollbar flag.\n\n"
            "You may want to also explicitly specify content width by using SetNextWindowContentWidth() before Begin().");
        static int lines = 7;
        BBZGUI::SliderInt("Lines", &lines, 1, 15);
        BBZGUI::PushStyleVar(BBZGUIStyleVar_FrameRounding, 3.0f);
        BBZGUI::PushStyleVar(BBZGUIStyleVar_FramePadding, ImVec2(2.0f, 1.0f));
        ImVec2 scrolling_child_size = ImVec2(0, BBZGUI::GetFrameHeightWithSpacing() * 7 + 30);
        BBZGUI::BeginChild("scrolling", scrolling_child_size, BBZGUIChildFlags_Borders, BBZGUIWindowFlags_HorizontalScrollbar);
        for (int line = 0; line < lines; line++)
        {
            // Display random stuff. For the sake of this trivial demo we are using basic Button() + SameLine()
            // If you want to create your own time line for a real application you may be better off manipulating
            // the cursor position yourself, aka using SetCursorPos/SetCursorScreenPos to position the widgets
            // yourself. You may also want to use the lower-level ImDrawList API.
            int num_buttons = 10 + ((line & 1) ? line * 9 : line * 3);
            for (int n = 0; n < num_buttons; n++)
            {
                if (n > 0) BBZGUI::SameLine();
                BBZGUI::PushID(n + line * 1000);
                char num_buf[16];
                sprintf(num_buf, "%d", n);
                const char* label = (!(n % 15)) ? "FizzBuzz" : (!(n % 3)) ? "Fizz" : (!(n % 5)) ? "Buzz" : num_buf;
                float hue = n * 0.05f;
                BBZGUI::PushStyleColor(BBZGUICol_Button, (ImVec4)ImColor::HSV(hue, 0.6f, 0.6f));
                BBZGUI::PushStyleColor(BBZGUICol_ButtonHovered, (ImVec4)ImColor::HSV(hue, 0.7f, 0.7f));
                BBZGUI::PushStyleColor(BBZGUICol_ButtonActive, (ImVec4)ImColor::HSV(hue, 0.8f, 0.8f));
                BBZGUI::Button(label, ImVec2(40.0f + sinf((float)(line + n)) * 20.0f, 0.0f));
                BBZGUI::PopStyleColor(3);
                BBZGUI::PopID();
            }
        }
        float scroll_x = BBZGUI::GetScrollX();
        float scroll_max_x = BBZGUI::GetScrollMaxX();
        BBZGUI::EndChild();
        BBZGUI::PopStyleVar(2);
        float scroll_x_delta = 0.0f;
        BBZGUI::SmallButton("<<");
        if (BBZGUI::IsItemActive())
            scroll_x_delta = -BBZGUI::GetIO().DeltaTime * 1000.0f;
        BBZGUI::SameLine();
        BBZGUI::Text("Scroll from code"); BBZGUI::SameLine();
        BBZGUI::SmallButton(">>");
        if (BBZGUI::IsItemActive())
            scroll_x_delta = +BBZGUI::GetIO().DeltaTime * 1000.0f;
        BBZGUI::SameLine();
        BBZGUI::Text("%.0f/%.0f", scroll_x, scroll_max_x);
        if (scroll_x_delta != 0.0f)
        {
            // Demonstrate a trick: you can use Begin to set yourself in the context of another window
            // (here we are already out of your child window)
            BBZGUI::BeginChild("scrolling");
            BBZGUI::SetScrollX(BBZGUI::GetScrollX() + scroll_x_delta);
            BBZGUI::EndChild();
        }
        BBZGUI::Spacing();

        static bool show_horizontal_contents_size_demo_window = false;
        BBZGUI::Checkbox("Show Horizontal contents size demo window", &show_horizontal_contents_size_demo_window);

        if (show_horizontal_contents_size_demo_window)
        {
            static bool show_h_scrollbar = true;
            static bool show_button = true;
            static bool show_tree_nodes = true;
            static bool show_text_wrapped = false;
            static bool show_columns = true;
            static bool show_tab_bar = true;
            static bool show_child = false;
            static bool explicit_content_size = false;
            static float contents_size_x = 300.0f;
            if (explicit_content_size)
                BBZGUI::SetNextWindowContentSize(ImVec2(contents_size_x, 0.0f));
            BBZGUI::Begin("Horizontal contents size demo window", &show_horizontal_contents_size_demo_window, show_h_scrollbar ? BBZGUIWindowFlags_HorizontalScrollbar : 0);
            IMGUI_DEMO_MARKER("Layout/Scrolling/Horizontal contents size demo window");
            BBZGUI::PushStyleVar(BBZGUIStyleVar_ItemSpacing, ImVec2(2, 0));
            BBZGUI::PushStyleVar(BBZGUIStyleVar_FramePadding, ImVec2(2, 0));
            HelpMarker(
                "Test how different widgets react and impact the work rectangle growing when horizontal scrolling is enabled.\n\n"
                "Use 'Metrics->Tools->Show windows rectangles' to visualize rectangles.");
            BBZGUI::Checkbox("H-scrollbar", &show_h_scrollbar);
            BBZGUI::Checkbox("Button", &show_button);            // Will grow contents size (unless explicitly overwritten)
            BBZGUI::Checkbox("Tree nodes", &show_tree_nodes);    // Will grow contents size and display highlight over full width
            BBZGUI::Checkbox("Text wrapped", &show_text_wrapped);// Will grow and use contents size
            BBZGUI::Checkbox("Columns", &show_columns);          // Will use contents size
            BBZGUI::Checkbox("Tab bar", &show_tab_bar);          // Will use contents size
            BBZGUI::Checkbox("Child", &show_child);              // Will grow and use contents size
            BBZGUI::Checkbox("Explicit content size", &explicit_content_size);
            BBZGUI::Text("Scroll %.1f/%.1f %.1f/%.1f", BBZGUI::GetScrollX(), BBZGUI::GetScrollMaxX(), BBZGUI::GetScrollY(), BBZGUI::GetScrollMaxY());
            if (explicit_content_size)
            {
                BBZGUI::SameLine();
                BBZGUI::SetNextItemWidth(100);
                BBZGUI::DragFloat("##csx", &contents_size_x);
                ImVec2 p = BBZGUI::GetCursorScreenPos();
                BBZGUI::GetWindowDrawList()->AddRectFilled(p, ImVec2(p.x + 10, p.y + 10), IM_COL32_WHITE);
                BBZGUI::GetWindowDrawList()->AddRectFilled(ImVec2(p.x + contents_size_x - 10, p.y), ImVec2(p.x + contents_size_x, p.y + 10), IM_COL32_WHITE);
                BBZGUI::Dummy(ImVec2(0, 10));
            }
            BBZGUI::PopStyleVar(2);
            BBZGUI::Separator();
            if (show_button)
            {
                BBZGUI::Button("this is a 300-wide button", ImVec2(300, 0));
            }
            if (show_tree_nodes)
            {
                bool open = true;
                if (BBZGUI::TreeNode("this is a tree node"))
                {
                    if (BBZGUI::TreeNode("another one of those tree node..."))
                    {
                        BBZGUI::Text("Some tree contents");
                        BBZGUI::TreePop();
                    }
                    BBZGUI::TreePop();
                }
                BBZGUI::CollapsingHeader("CollapsingHeader", &open);
            }
            if (show_text_wrapped)
            {
                BBZGUI::TextWrapped("This text should automatically wrap on the edge of the work rectangle.");
            }
            if (show_columns)
            {
                BBZGUI::Text("Tables:");
                if (BBZGUI::BeginTable("table", 4, BBZGUITableFlags_Borders))
                {
                    for (int n = 0; n < 4; n++)
                    {
                        BBZGUI::TableNextColumn();
                        BBZGUI::Text("Width %.2f", BBZGUI::GetContentRegionAvail().x);
                    }
                    BBZGUI::EndTable();
                }
                BBZGUI::Text("Columns:");
                BBZGUI::Columns(4);
                for (int n = 0; n < 4; n++)
                {
                    BBZGUI::Text("Width %.2f", BBZGUI::GetColumnWidth());
                    BBZGUI::NextColumn();
                }
                BBZGUI::Columns(1);
            }
            if (show_tab_bar && BBZGUI::BeginTabBar("Hello"))
            {
                if (BBZGUI::BeginTabItem("OneOneOne")) { BBZGUI::EndTabItem(); }
                if (BBZGUI::BeginTabItem("TwoTwoTwo")) { BBZGUI::EndTabItem(); }
                if (BBZGUI::BeginTabItem("ThreeThreeThree")) { BBZGUI::EndTabItem(); }
                if (BBZGUI::BeginTabItem("FourFourFour")) { BBZGUI::EndTabItem(); }
                BBZGUI::EndTabBar();
            }
            if (show_child)
            {
                BBZGUI::BeginChild("child", ImVec2(0, 0), BBZGUIChildFlags_Borders);
                BBZGUI::EndChild();
            }
            BBZGUI::End();
        }

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Text Clipping");
    if (BBZGUI::TreeNode("Text Clipping"))
    {
        static ImVec2 size(100.0f, 100.0f);
        static ImVec2 offset(30.0f, 30.0f);
        BBZGUI::DragFloat2("size", (float*)&size, 0.5f, 1.0f, 200.0f, "%.0f");
        BBZGUI::TextWrapped("(Click and drag to scroll)");

        HelpMarker(
            "(Left) Using BBZGUI::PushClipRect():\n"
            "Will alter BBZGUI hit-testing logic + ImDrawList rendering.\n"
            "(use this if you want your clipping rectangle to affect interactions)\n\n"
            "(Center) Using ImDrawList::PushClipRect():\n"
            "Will alter ImDrawList rendering only.\n"
            "(use this as a shortcut if you are only using ImDrawList calls)\n\n"
            "(Right) Using ImDrawList::AddText() with a fine ClipRect:\n"
            "Will alter only this specific ImDrawList::AddText() rendering.\n"
            "This is often used internally to avoid altering the clipping rectangle and minimize draw calls.");

        for (int n = 0; n < 3; n++)
        {
            if (n > 0)
                BBZGUI::SameLine();

            BBZGUI::PushID(n);
            BBZGUI::InvisibleButton("##canvas", size);
            if (BBZGUI::IsItemActive() && BBZGUI::IsMouseDragging(BBZGUIMouseButton_Left))
            {
                offset.x += BBZGUI::GetIO().MouseDelta.x;
                offset.y += BBZGUI::GetIO().MouseDelta.y;
            }
            BBZGUI::PopID();
            if (!BBZGUI::IsItemVisible()) // Skip rendering as ImDrawList elements are not clipped.
                continue;

            const ImVec2 p0 = BBZGUI::GetItemRectMin();
            const ImVec2 p1 = BBZGUI::GetItemRectMax();
            const char* text_str = "Line 1 hello\nLine 2 clip me!";
            const ImVec2 text_pos = ImVec2(p0.x + offset.x, p0.y + offset.y);
            ImDrawList* draw_list = BBZGUI::GetWindowDrawList();
            switch (n)
            {
            case 0:
                BBZGUI::PushClipRect(p0, p1, true);
                draw_list->AddRectFilled(p0, p1, IM_COL32(90, 90, 120, 255));
                draw_list->AddText(text_pos, IM_COL32_WHITE, text_str);
                BBZGUI::PopClipRect();
                break;
            case 1:
                draw_list->PushClipRect(p0, p1, true);
                draw_list->AddRectFilled(p0, p1, IM_COL32(90, 90, 120, 255));
                draw_list->AddText(text_pos, IM_COL32_WHITE, text_str);
                draw_list->PopClipRect();
                break;
            case 2:
                ImVec4 clip_rect(p0.x, p0.y, p1.x, p1.y); // AddText() takes a ImVec4* here so let's convert.
                draw_list->AddRectFilled(p0, p1, IM_COL32(90, 90, 120, 255));
                draw_list->AddText(BBZGUI::GetFont(), BBZGUI::GetFontSize(), text_pos, IM_COL32_WHITE, text_str, NULL, 0.0f, &clip_rect);
                break;
            }
        }

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Layout/Overlap Mode");
    if (BBZGUI::TreeNode("Overlap Mode"))
    {
        static bool enable_allow_overlap = true;

        HelpMarker(
            "Hit-testing is by default performed in item submission order, which generally is perceived as 'back-to-front'.\n\n"
            "By using SetNextItemAllowOverlap() you can notify that an item may be overlapped by another. "
            "Doing so alters the hovering logic: items using AllowOverlap mode requires an extra frame to accept hovered state.");
        BBZGUI::Checkbox("Enable AllowOverlap", &enable_allow_overlap);

        ImVec2 button1_pos = BBZGUI::GetCursorScreenPos();
        ImVec2 button2_pos = ImVec2(button1_pos.x + 50.0f, button1_pos.y + 50.0f);
        if (enable_allow_overlap)
            BBZGUI::SetNextItemAllowOverlap();
        BBZGUI::Button("Button 1", ImVec2(80, 80));
        BBZGUI::SetCursorScreenPos(button2_pos);
        BBZGUI::Button("Button 2", ImVec2(80, 80));

        // This is typically used with width-spanning items.
        // (note that Selectable() has a dedicated flag BBZGUISelectableFlags_AllowOverlap, which is a shortcut
        // for using SetNextItemAllowOverlap(). For demo purpose we use SetNextItemAllowOverlap() here.)
        if (enable_allow_overlap)
            BBZGUI::SetNextItemAllowOverlap();
        BBZGUI::Selectable("Some Selectable", false);
        BBZGUI::SameLine();
        BBZGUI::SmallButton("++");

        BBZGUI::TreePop();
    }
}

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowPopups()
//-----------------------------------------------------------------------------

static void ShowDemoWindowPopups()
{
    IMGUI_DEMO_MARKER("Popups");
    if (!BBZGUI::CollapsingHeader("Popups & Modal windows"))
        return;

    // The properties of popups windows are:
    // - They block normal mouse hovering detection outside them. (*)
    // - Unless modal, they can be closed by clicking anywhere outside them, or by pressing ESCAPE.
    // - Their visibility state (~bool) is held internally by Dear BBZGUI instead of being held by the programmer as
    //   we are used to with regular Begin() calls. User can manipulate the visibility state by calling OpenPopup().
    // (*) One can use IsItemHovered(BBZGUIHoveredFlags_AllowWhenBlockedByPopup) to bypass it and detect hovering even
    //     when normally blocked by a popup.
    // Those three properties are connected. The library needs to hold their visibility state BECAUSE it can close
    // popups at any time.

    // Typical use for regular windows:
    //   bool my_tool_is_active = false; if (BBZGUI::Button("Open")) my_tool_is_active = true; [...] if (my_tool_is_active) Begin("My Tool", &my_tool_is_active) { [...] } End();
    // Typical use for popups:
    //   if (BBZGUI::Button("Open")) BBZGUI::OpenPopup("MyPopup"); if (BBZGUI::BeginPopup("MyPopup") { [...] EndPopup(); }

    // With popups we have to go through a library call (here OpenPopup) to manipulate the visibility state.
    // This may be a bit confusing at first but it should quickly make sense. Follow on the examples below.

    IMGUI_DEMO_MARKER("Popups/Popups");
    if (BBZGUI::TreeNode("Popups"))
    {
        BBZGUI::TextWrapped(
            "When a popup is active, it inhibits interacting with windows that are behind the popup. "
            "Clicking outside the popup closes it.");

        static int selected_fish = -1;
        const char* names[] = { "Bream", "Haddock", "Mackerel", "Pollock", "Tilefish" };
        static bool toggles[] = { true, false, false, false, false };

        // Simple selection popup (if you want to show the current selection inside the Button itself,
        // you may want to build a string using the "###" operator to preserve a constant ID with a variable label)
        if (BBZGUI::Button("Select.."))
            BBZGUI::OpenPopup("my_select_popup");
        BBZGUI::SameLine();
        BBZGUI::TextUnformatted(selected_fish == -1 ? "<None>" : names[selected_fish]);
        if (BBZGUI::BeginPopup("my_select_popup"))
        {
            BBZGUI::SeparatorText("Aquarium");
            for (int i = 0; i < IM_ARRAYSIZE(names); i++)
                if (BBZGUI::Selectable(names[i]))
                    selected_fish = i;
            BBZGUI::EndPopup();
        }

        // Showing a menu with toggles
        if (BBZGUI::Button("Toggle.."))
            BBZGUI::OpenPopup("my_toggle_popup");
        if (BBZGUI::BeginPopup("my_toggle_popup"))
        {
            for (int i = 0; i < IM_ARRAYSIZE(names); i++)
                BBZGUI::MenuItem(names[i], "", &toggles[i]);
            if (BBZGUI::BeginMenu("Sub-menu"))
            {
                BBZGUI::MenuItem("Click me");
                BBZGUI::EndMenu();
            }

            BBZGUI::Separator();
            BBZGUI::Text("Tooltip here");
            BBZGUI::SetItemTooltip("I am a tooltip over a popup");

            if (BBZGUI::Button("Stacked Popup"))
                BBZGUI::OpenPopup("another popup");
            if (BBZGUI::BeginPopup("another popup"))
            {
                for (int i = 0; i < IM_ARRAYSIZE(names); i++)
                    BBZGUI::MenuItem(names[i], "", &toggles[i]);
                if (BBZGUI::BeginMenu("Sub-menu"))
                {
                    BBZGUI::MenuItem("Click me");
                    if (BBZGUI::Button("Stacked Popup"))
                        BBZGUI::OpenPopup("another popup");
                    if (BBZGUI::BeginPopup("another popup"))
                    {
                        BBZGUI::Text("I am the last one here.");
                        BBZGUI::EndPopup();
                    }
                    BBZGUI::EndMenu();
                }
                BBZGUI::EndPopup();
            }
            BBZGUI::EndPopup();
        }

        // Call the more complete ShowExampleMenuFile which we use in various places of this demo
        if (BBZGUI::Button("With a menu.."))
            BBZGUI::OpenPopup("my_file_popup");
        if (BBZGUI::BeginPopup("my_file_popup", BBZGUIWindowFlags_MenuBar))
        {
            if (BBZGUI::BeginMenuBar())
            {
                if (BBZGUI::BeginMenu("File"))
                {
                    ShowExampleMenuFile();
                    BBZGUI::EndMenu();
                }
                if (BBZGUI::BeginMenu("Edit"))
                {
                    BBZGUI::MenuItem("Dummy");
                    BBZGUI::EndMenu();
                }
                BBZGUI::EndMenuBar();
            }
            BBZGUI::Text("Hello from popup!");
            BBZGUI::Button("This is a dummy button..");
            BBZGUI::EndPopup();
        }

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Popups/Context menus");
    if (BBZGUI::TreeNode("Context menus"))
    {
        HelpMarker("\"Context\" functions are simple helpers to associate a Popup to a given Item or Window identifier.");

        // BeginPopupContextItem() is a helper to provide common/simple popup behavior of essentially doing:
        //     if (id == 0)
        //         id = GetItemID(); // Use last item id
        //     if (IsItemHovered() && IsMouseReleased(BBZGUIMouseButton_Right))
        //         OpenPopup(id);
        //     return BeginPopup(id);
        // For advanced uses you may want to replicate and customize this code.
        // See more details in BeginPopupContextItem().

        // Example 1
        // When used after an item that has an ID (e.g. Button), we can skip providing an ID to BeginPopupContextItem(),
        // and BeginPopupContextItem() will use the last item ID as the popup ID.
        {
            const char* names[5] = { "Label1", "Label2", "Label3", "Label4", "Label5" };
            static int selected = -1;
            for (int n = 0; n < 5; n++)
            {
                if (BBZGUI::Selectable(names[n], selected == n))
                    selected = n;
                if (BBZGUI::BeginPopupContextItem()) // <-- use last item id as popup id
                {
                    selected = n;
                    BBZGUI::Text("This a popup for \"%s\"!", names[n]);
                    if (BBZGUI::Button("Close"))
                        BBZGUI::CloseCurrentPopup();
                    BBZGUI::EndPopup();
                }
                BBZGUI::SetItemTooltip("Right-click to open popup");
            }
        }

        // Example 2
        // Popup on a Text() element which doesn't have an identifier: we need to provide an identifier to BeginPopupContextItem().
        // Using an explicit identifier is also convenient if you want to activate the popups from different locations.
        {
            HelpMarker("Text() elements don't have stable identifiers so we need to provide one.");
            static float value = 0.5f;
            BBZGUI::Text("Value = %.3f <-- (1) right-click this text", value);
            if (BBZGUI::BeginPopupContextItem("my popup"))
            {
                if (BBZGUI::Selectable("Set to zero")) value = 0.0f;
                if (BBZGUI::Selectable("Set to PI")) value = 3.1415f;
                BBZGUI::SetNextItemWidth(-FLT_MIN);
                BBZGUI::DragFloat("##Value", &value, 0.1f, 0.0f, 0.0f);
                BBZGUI::EndPopup();
            }

            // We can also use OpenPopupOnItemClick() to toggle the visibility of a given popup.
            // Here we make it that right-clicking this other text element opens the same popup as above.
            // The popup itself will be submitted by the code above.
            BBZGUI::Text("(2) Or right-click this text");
            BBZGUI::OpenPopupOnItemClick("my popup", BBZGUIPopupFlags_MouseButtonRight);

            // Back to square one: manually open the same popup.
            if (BBZGUI::Button("(3) Or click this button"))
                BBZGUI::OpenPopup("my popup");
        }

        // Example 3
        // When using BeginPopupContextItem() with an implicit identifier (NULL == use last item ID),
        // we need to make sure your item identifier is stable.
        // In this example we showcase altering the item label while preserving its identifier, using the ### operator (see FAQ).
        {
            HelpMarker("Showcase using a popup ID linked to item ID, with the item having a changing label + stable ID using the ### operator.");
            static char name[32] = "Label1";
            char buf[64];
            sprintf(buf, "Button: %s###Button", name); // ### operator override ID ignoring the preceding label
            BBZGUI::Button(buf);
            if (BBZGUI::BeginPopupContextItem())
            {
                BBZGUI::Text("Edit name:");
                BBZGUI::InputText("##edit", name, IM_ARRAYSIZE(name));
                if (BBZGUI::Button("Close"))
                    BBZGUI::CloseCurrentPopup();
                BBZGUI::EndPopup();
            }
            BBZGUI::SameLine(); BBZGUI::Text("(<-- right-click here)");
        }

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Popups/Modals");
    if (BBZGUI::TreeNode("Modals"))
    {
        BBZGUI::TextWrapped("Modal windows are like popups but the user cannot close them by clicking outside.");

        if (BBZGUI::Button("Delete.."))
            BBZGUI::OpenPopup("Delete?");

        // Always center this window when appearing
        ImVec2 center = BBZGUI::GetMainViewport()->GetCenter();
        BBZGUI::SetNextWindowPos(center, BBZGUICond_Appearing, ImVec2(0.5f, 0.5f));

        if (BBZGUI::BeginPopupModal("Delete?", NULL, BBZGUIWindowFlags_AlwaysAutoResize))
        {
            BBZGUI::Text("All those beautiful files will be deleted.\nThis operation cannot be undone!");
            BBZGUI::Separator();

            //static int unused_i = 0;
            //BBZGUI::Combo("Combo", &unused_i, "Delete\0Delete harder\0");

            static bool dont_ask_me_next_time = false;
            BBZGUI::PushStyleVar(BBZGUIStyleVar_FramePadding, ImVec2(0, 0));
            BBZGUI::Checkbox("Don't ask me next time", &dont_ask_me_next_time);
            BBZGUI::PopStyleVar();

            if (BBZGUI::Button("OK", ImVec2(120, 0))) { BBZGUI::CloseCurrentPopup(); }
            BBZGUI::SetItemDefaultFocus();
            BBZGUI::SameLine();
            if (BBZGUI::Button("Cancel", ImVec2(120, 0))) { BBZGUI::CloseCurrentPopup(); }
            BBZGUI::EndPopup();
        }

        if (BBZGUI::Button("Stacked modals.."))
            BBZGUI::OpenPopup("Stacked 1");
        if (BBZGUI::BeginPopupModal("Stacked 1", NULL, BBZGUIWindowFlags_MenuBar))
        {
            if (BBZGUI::BeginMenuBar())
            {
                if (BBZGUI::BeginMenu("File"))
                {
                    if (BBZGUI::MenuItem("Some menu item")) {}
                    BBZGUI::EndMenu();
                }
                BBZGUI::EndMenuBar();
            }
            BBZGUI::Text("Hello from Stacked The First\nUsing style.Colors[BBZGUICol_ModalWindowDimBg] behind it.");

            // Testing behavior of widgets stacking their own regular popups over the modal.
            static int item = 1;
            static float color[4] = { 0.4f, 0.7f, 0.0f, 0.5f };
            BBZGUI::Combo("Combo", &item, "aaaa\0bbbb\0cccc\0dddd\0eeee\0\0");
            BBZGUI::ColorEdit4("Color", color);

            if (BBZGUI::Button("Add another modal.."))
                BBZGUI::OpenPopup("Stacked 2");

            // Also demonstrate passing a bool* to BeginPopupModal(), this will create a regular close button which
            // will close the popup. Note that the visibility state of popups is owned by imgui, so the input value
            // of the bool actually doesn't matter here.
            bool unused_open = true;
            if (BBZGUI::BeginPopupModal("Stacked 2", &unused_open))
            {
                BBZGUI::Text("Hello from Stacked The Second!");
                BBZGUI::ColorEdit4("Color", color); // Allow opening another nested popup
                if (BBZGUI::Button("Close"))
                    BBZGUI::CloseCurrentPopup();
                BBZGUI::EndPopup();
            }

            if (BBZGUI::Button("Close"))
                BBZGUI::CloseCurrentPopup();
            BBZGUI::EndPopup();
        }

        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Popups/Menus inside a regular window");
    if (BBZGUI::TreeNode("Menus inside a regular window"))
    {
        BBZGUI::TextWrapped("Below we are testing adding menu items to a regular window. It's rather unusual but should work!");
        BBZGUI::Separator();

        BBZGUI::MenuItem("Menu item", "CTRL+M");
        if (BBZGUI::BeginMenu("Menu inside a regular window"))
        {
            ShowExampleMenuFile();
            BBZGUI::EndMenu();
        }
        BBZGUI::Separator();
        BBZGUI::TreePop();
    }
}

// Dummy data structure that we use for the Table demo.
// (pre-C++11 doesn't allow us to instantiate ImVector<MyItem> template if this structure is defined inside the demo function)
namespace
{
// We are passing our own identifier to TableSetupColumn() to facilitate identifying columns in the sorting code.
// This identifier will be passed down into BBZGUITableSortSpec::ColumnUserID.
// But it is possible to omit the user id parameter of TableSetupColumn() and just use the column index instead! (BBZGUITableSortSpec::ColumnIndex)
// If you don't use sorting, you will generally never care about giving column an ID!
enum MyItemColumnID
{
    MyItemColumnID_ID,
    MyItemColumnID_Name,
    MyItemColumnID_Action,
    MyItemColumnID_Quantity,
    MyItemColumnID_Description
};

struct MyItem
{
    int         ID;
    const char* Name;
    int         Quantity;

    // We have a problem which is affecting _only this demo_ and should not affect your code:
    // As we don't rely on std:: or other third-party library to compile dear imgui, we only have reliable access to qsort(),
    // however qsort doesn't allow passing user data to comparing function.
    // As a workaround, we are storing the sort specs in a static/global for the comparing function to access.
    // In your own use case you would probably pass the sort specs to your sorting/comparing functions directly and not use a global.
    // We could technically call BBZGUI::TableGetSortSpecs() in CompareWithSortSpecs(), but considering that this function is called
    // very often by the sorting algorithm it would be a little wasteful.
    static const BBZGUITableSortSpecs* s_current_sort_specs;

    static void SortWithSortSpecs(BBZGUITableSortSpecs* sort_specs, MyItem* items, int items_count)
    {
        s_current_sort_specs = sort_specs; // Store in variable accessible by the sort function.
        if (items_count > 1)
            qsort(items, (size_t)items_count, sizeof(items[0]), MyItem::CompareWithSortSpecs);
        s_current_sort_specs = NULL;
    }

    // Compare function to be used by qsort()
    static int IMGUI_CDECL CompareWithSortSpecs(const void* lhs, const void* rhs)
    {
        const MyItem* a = (const MyItem*)lhs;
        const MyItem* b = (const MyItem*)rhs;
        for (int n = 0; n < s_current_sort_specs->SpecsCount; n++)
        {
            // Here we identify columns using the ColumnUserID value that we ourselves passed to TableSetupColumn()
            // We could also choose to identify columns based on their index (sort_spec->ColumnIndex), which is simpler!
            const BBZGUITableColumnSortSpecs* sort_spec = &s_current_sort_specs->Specs[n];
            int delta = 0;
            switch (sort_spec->ColumnUserID)
            {
            case MyItemColumnID_ID:             delta = (a->ID - b->ID);                break;
            case MyItemColumnID_Name:           delta = (strcmp(a->Name, b->Name));     break;
            case MyItemColumnID_Quantity:       delta = (a->Quantity - b->Quantity);    break;
            case MyItemColumnID_Description:    delta = (strcmp(a->Name, b->Name));     break;
            default: IM_ASSERT(0); break;
            }
            if (delta > 0)
                return (sort_spec->SortDirection == BBZGUISortDirection_Ascending) ? +1 : -1;
            if (delta < 0)
                return (sort_spec->SortDirection == BBZGUISortDirection_Ascending) ? -1 : +1;
        }

        // qsort() is instable so always return a way to differenciate items.
        // Your own compare function may want to avoid fallback on implicit sort specs.
        // e.g. a Name compare if it wasn't already part of the sort specs.
        return (a->ID - b->ID);
    }
};
const BBZGUITableSortSpecs* MyItem::s_current_sort_specs = NULL;
}

// Make the UI compact because there are so many fields
static void PushStyleCompact()
{
    BBZGUIStyle& style = BBZGUI::GetStyle();
    BBZGUI::PushStyleVarY(BBZGUIStyleVar_FramePadding, (float)(int)(style.FramePadding.y * 0.60f));
    BBZGUI::PushStyleVarY(BBZGUIStyleVar_ItemSpacing, (float)(int)(style.ItemSpacing.y * 0.60f));
}

static void PopStyleCompact()
{
    BBZGUI::PopStyleVar(2);
}

// Show a combo box with a choice of sizing policies
static void EditTableSizingFlags(BBZGUITableFlags* p_flags)
{
    struct EnumDesc { BBZGUITableFlags Value; const char* Name; const char* Tooltip; };
    static const EnumDesc policies[] =
    {
        { BBZGUITableFlags_None,               "Default",                            "Use default sizing policy:\n- BBZGUITableFlags_SizingFixedFit if ScrollX is on or if host window has BBZGUIWindowFlags_AlwaysAutoResize.\n- BBZGUITableFlags_SizingStretchSame otherwise." },
        { BBZGUITableFlags_SizingFixedFit,     "BBZGUITableFlags_SizingFixedFit",     "Columns default to _WidthFixed (if resizable) or _WidthAuto (if not resizable), matching contents width." },
        { BBZGUITableFlags_SizingFixedSame,    "BBZGUITableFlags_SizingFixedSame",    "Columns are all the same width, matching the maximum contents width.\nImplicitly disable BBZGUITableFlags_Resizable and enable BBZGUITableFlags_NoKeepColumnsVisible." },
        { BBZGUITableFlags_SizingStretchProp,  "BBZGUITableFlags_SizingStretchProp",  "Columns default to _WidthStretch with weights proportional to their widths." },
        { BBZGUITableFlags_SizingStretchSame,  "BBZGUITableFlags_SizingStretchSame",  "Columns default to _WidthStretch with same weights." }
    };
    int idx;
    for (idx = 0; idx < IM_ARRAYSIZE(policies); idx++)
        if (policies[idx].Value == (*p_flags & BBZGUITableFlags_SizingMask_))
            break;
    const char* preview_text = (idx < IM_ARRAYSIZE(policies)) ? policies[idx].Name + (idx > 0 ? strlen("BBZGUITableFlags") : 0) : "";
    if (BBZGUI::BeginCombo("Sizing Policy", preview_text))
    {
        for (int n = 0; n < IM_ARRAYSIZE(policies); n++)
            if (BBZGUI::Selectable(policies[n].Name, idx == n))
                *p_flags = (*p_flags & ~BBZGUITableFlags_SizingMask_) | policies[n].Value;
        BBZGUI::EndCombo();
    }
    BBZGUI::SameLine();
    BBZGUI::TextDisabled("(?)");
    if (BBZGUI::BeginItemTooltip())
    {
        BBZGUI::PushTextWrapPos(BBZGUI::GetFontSize() * 50.0f);
        for (int m = 0; m < IM_ARRAYSIZE(policies); m++)
        {
            BBZGUI::Separator();
            BBZGUI::Text("%s:", policies[m].Name);
            BBZGUI::Separator();
            BBZGUI::SetCursorPosX(BBZGUI::GetCursorPosX() + BBZGUI::GetStyle().IndentSpacing * 0.5f);
            BBZGUI::TextUnformatted(policies[m].Tooltip);
        }
        BBZGUI::PopTextWrapPos();
        BBZGUI::EndTooltip();
    }
}

static void EditTableColumnsFlags(BBZGUITableColumnFlags* p_flags)
{
    BBZGUI::CheckboxFlags("_Disabled", p_flags, BBZGUITableColumnFlags_Disabled); BBZGUI::SameLine(); HelpMarker("Master disable flag (also hide from context menu)");
    BBZGUI::CheckboxFlags("_DefaultHide", p_flags, BBZGUITableColumnFlags_DefaultHide);
    BBZGUI::CheckboxFlags("_DefaultSort", p_flags, BBZGUITableColumnFlags_DefaultSort);
    if (BBZGUI::CheckboxFlags("_WidthStretch", p_flags, BBZGUITableColumnFlags_WidthStretch))
        *p_flags &= ~(BBZGUITableColumnFlags_WidthMask_ ^ BBZGUITableColumnFlags_WidthStretch);
    if (BBZGUI::CheckboxFlags("_WidthFixed", p_flags, BBZGUITableColumnFlags_WidthFixed))
        *p_flags &= ~(BBZGUITableColumnFlags_WidthMask_ ^ BBZGUITableColumnFlags_WidthFixed);
    BBZGUI::CheckboxFlags("_NoResize", p_flags, BBZGUITableColumnFlags_NoResize);
    BBZGUI::CheckboxFlags("_NoReorder", p_flags, BBZGUITableColumnFlags_NoReorder);
    BBZGUI::CheckboxFlags("_NoHide", p_flags, BBZGUITableColumnFlags_NoHide);
    BBZGUI::CheckboxFlags("_NoClip", p_flags, BBZGUITableColumnFlags_NoClip);
    BBZGUI::CheckboxFlags("_NoSort", p_flags, BBZGUITableColumnFlags_NoSort);
    BBZGUI::CheckboxFlags("_NoSortAscending", p_flags, BBZGUITableColumnFlags_NoSortAscending);
    BBZGUI::CheckboxFlags("_NoSortDescending", p_flags, BBZGUITableColumnFlags_NoSortDescending);
    BBZGUI::CheckboxFlags("_NoHeaderLabel", p_flags, BBZGUITableColumnFlags_NoHeaderLabel);
    BBZGUI::CheckboxFlags("_NoHeaderWidth", p_flags, BBZGUITableColumnFlags_NoHeaderWidth);
    BBZGUI::CheckboxFlags("_PreferSortAscending", p_flags, BBZGUITableColumnFlags_PreferSortAscending);
    BBZGUI::CheckboxFlags("_PreferSortDescending", p_flags, BBZGUITableColumnFlags_PreferSortDescending);
    BBZGUI::CheckboxFlags("_IndentEnable", p_flags, BBZGUITableColumnFlags_IndentEnable); BBZGUI::SameLine(); HelpMarker("Default for column 0");
    BBZGUI::CheckboxFlags("_IndentDisable", p_flags, BBZGUITableColumnFlags_IndentDisable); BBZGUI::SameLine(); HelpMarker("Default for column >0");
    BBZGUI::CheckboxFlags("_AngledHeader", p_flags, BBZGUITableColumnFlags_AngledHeader);
}

static void ShowTableColumnsStatusFlags(BBZGUITableColumnFlags flags)
{
    BBZGUI::CheckboxFlags("_IsEnabled", &flags, BBZGUITableColumnFlags_IsEnabled);
    BBZGUI::CheckboxFlags("_IsVisible", &flags, BBZGUITableColumnFlags_IsVisible);
    BBZGUI::CheckboxFlags("_IsSorted", &flags, BBZGUITableColumnFlags_IsSorted);
    BBZGUI::CheckboxFlags("_IsHovered", &flags, BBZGUITableColumnFlags_IsHovered);
}

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowTables()
//-----------------------------------------------------------------------------

static void ShowDemoWindowTables()
{
    //BBZGUI::SetNextItemOpen(true, BBZGUICond_Once);
    IMGUI_DEMO_MARKER("Tables");
    if (!BBZGUI::CollapsingHeader("Tables & Columns"))
        return;

    // Using those as a base value to create width/height that are factor of the size of our font
    const float TEXT_BASE_WIDTH = BBZGUI::CalcTextSize("A").x;
    const float TEXT_BASE_HEIGHT = BBZGUI::GetTextLineHeightWithSpacing();

    BBZGUI::PushID("Tables");

    int open_action = -1;
    if (BBZGUI::Button("Expand all"))
        open_action = 1;
    BBZGUI::SameLine();
    if (BBZGUI::Button("Collapse all"))
        open_action = 0;
    BBZGUI::SameLine();

    // Options
    static bool disable_indent = false;
    BBZGUI::Checkbox("Disable tree indentation", &disable_indent);
    BBZGUI::SameLine();
    HelpMarker("Disable the indenting of tree nodes so demo tables can use the full window width.");
    BBZGUI::Separator();
    if (disable_indent)
        BBZGUI::PushStyleVar(BBZGUIStyleVar_IndentSpacing, 0.0f);

    // About Styling of tables
    // Most settings are configured on a per-table basis via the flags passed to BeginTable() and TableSetupColumns APIs.
    // There are however a few settings that a shared and part of the BBZGUIStyle structure:
    //   style.CellPadding                          // Padding within each cell
    //   style.Colors[BBZGUICol_TableHeaderBg]       // Table header background
    //   style.Colors[BBZGUICol_TableBorderStrong]   // Table outer and header borders
    //   style.Colors[BBZGUICol_TableBorderLight]    // Table inner borders
    //   style.Colors[BBZGUICol_TableRowBg]          // Table row background when BBZGUITableFlags_RowBg is enabled (even rows)
    //   style.Colors[BBZGUICol_TableRowBgAlt]       // Table row background when BBZGUITableFlags_RowBg is enabled (odds rows)

    // Demos
    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Basic");
    if (BBZGUI::TreeNode("Basic"))
    {
        // Here we will showcase three different ways to output a table.
        // They are very simple variations of a same thing!

        // [Method 1] Using TableNextRow() to create a new row, and TableSetColumnIndex() to select the column.
        // In many situations, this is the most flexible and easy to use pattern.
        HelpMarker("Using TableNextRow() + calling TableSetColumnIndex() _before_ each cell, in a loop.");
        if (BBZGUI::BeginTable("table1", 3))
        {
            for (int row = 0; row < 4; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 3; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    BBZGUI::Text("Row %d Column %d", row, column);
                }
            }
            BBZGUI::EndTable();
        }

        // [Method 2] Using TableNextColumn() called multiple times, instead of using a for loop + TableSetColumnIndex().
        // This is generally more convenient when you have code manually submitting the contents of each column.
        HelpMarker("Using TableNextRow() + calling TableNextColumn() _before_ each cell, manually.");
        if (BBZGUI::BeginTable("table2", 3))
        {
            for (int row = 0; row < 4; row++)
            {
                BBZGUI::TableNextRow();
                BBZGUI::TableNextColumn();
                BBZGUI::Text("Row %d", row);
                BBZGUI::TableNextColumn();
                BBZGUI::Text("Some contents");
                BBZGUI::TableNextColumn();
                BBZGUI::Text("123.456");
            }
            BBZGUI::EndTable();
        }

        // [Method 3] We call TableNextColumn() _before_ each cell. We never call TableNextRow(),
        // as TableNextColumn() will automatically wrap around and create new rows as needed.
        // This is generally more convenient when your cells all contains the same type of data.
        HelpMarker(
            "Only using TableNextColumn(), which tends to be convenient for tables where every cell contains "
            "the same type of contents.\n This is also more similar to the old NextColumn() function of the "
            "Columns API, and provided to facilitate the Columns->Tables API transition.");
        if (BBZGUI::BeginTable("table3", 3))
        {
            for (int item = 0; item < 14; item++)
            {
                BBZGUI::TableNextColumn();
                BBZGUI::Text("Item %d", item);
            }
            BBZGUI::EndTable();
        }

        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Borders, background");
    if (BBZGUI::TreeNode("Borders, background"))
    {
        // Expose a few Borders related flags interactively
        enum ContentsType { CT_Text, CT_FillButton };
        static BBZGUITableFlags flags = BBZGUITableFlags_Borders | BBZGUITableFlags_RowBg;
        static bool display_headers = false;
        static int contents_type = CT_Text;

        PushStyleCompact();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_RowBg", &flags, BBZGUITableFlags_RowBg);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_Borders", &flags, BBZGUITableFlags_Borders);
        BBZGUI::SameLine(); HelpMarker("BBZGUITableFlags_Borders\n = BBZGUITableFlags_BordersInnerV\n | BBZGUITableFlags_BordersOuterV\n | BBZGUITableFlags_BordersInnerH\n | BBZGUITableFlags_BordersOuterH");
        BBZGUI::Indent();

        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersH", &flags, BBZGUITableFlags_BordersH);
        BBZGUI::Indent();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersOuterH", &flags, BBZGUITableFlags_BordersOuterH);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersInnerH", &flags, BBZGUITableFlags_BordersInnerH);
        BBZGUI::Unindent();

        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersV", &flags, BBZGUITableFlags_BordersV);
        BBZGUI::Indent();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersOuterV", &flags, BBZGUITableFlags_BordersOuterV);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersInnerV", &flags, BBZGUITableFlags_BordersInnerV);
        BBZGUI::Unindent();

        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersOuter", &flags, BBZGUITableFlags_BordersOuter);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersInner", &flags, BBZGUITableFlags_BordersInner);
        BBZGUI::Unindent();

        BBZGUI::AlignTextToFramePadding(); BBZGUI::Text("Cell contents:");
        BBZGUI::SameLine(); BBZGUI::RadioButton("Text", &contents_type, CT_Text);
        BBZGUI::SameLine(); BBZGUI::RadioButton("FillButton", &contents_type, CT_FillButton);
        BBZGUI::Checkbox("Display headers", &display_headers);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_NoBordersInBody", &flags, BBZGUITableFlags_NoBordersInBody); BBZGUI::SameLine(); HelpMarker("Disable vertical borders in columns Body (borders will always appear in Headers");
        PopStyleCompact();

        if (BBZGUI::BeginTable("table1", 3, flags))
        {
            // Display headers so we can inspect their interaction with borders
            // (Headers are not the main purpose of this section of the demo, so we are not elaborating on them now. See other sections for details)
            if (display_headers)
            {
                BBZGUI::TableSetupColumn("One");
                BBZGUI::TableSetupColumn("Two");
                BBZGUI::TableSetupColumn("Three");
                BBZGUI::TableHeadersRow();
            }

            for (int row = 0; row < 5; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 3; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    char buf[32];
                    sprintf(buf, "Hello %d,%d", column, row);
                    if (contents_type == CT_Text)
                        BBZGUI::TextUnformatted(buf);
                    else if (contents_type == CT_FillButton)
                        BBZGUI::Button(buf, ImVec2(-FLT_MIN, 0.0f));
                }
            }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Resizable, stretch");
    if (BBZGUI::TreeNode("Resizable, stretch"))
    {
        // By default, if we don't enable ScrollX the sizing policy for each column is "Stretch"
        // All columns maintain a sizing weight, and they will occupy all available width.
        static BBZGUITableFlags flags = BBZGUITableFlags_SizingStretchSame | BBZGUITableFlags_Resizable | BBZGUITableFlags_BordersOuter | BBZGUITableFlags_BordersV | BBZGUITableFlags_ContextMenuInBody;
        PushStyleCompact();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_Resizable", &flags, BBZGUITableFlags_Resizable);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersV", &flags, BBZGUITableFlags_BordersV);
        BBZGUI::SameLine(); HelpMarker(
            "Using the _Resizable flag automatically enables the _BordersInnerV flag as well, "
            "this is why the resize borders are still showing when unchecking this.");
        PopStyleCompact();

        if (BBZGUI::BeginTable("table1", 3, flags))
        {
            for (int row = 0; row < 5; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 3; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    BBZGUI::Text("Hello %d,%d", column, row);
                }
            }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Resizable, fixed");
    if (BBZGUI::TreeNode("Resizable, fixed"))
    {
        // Here we use BBZGUITableFlags_SizingFixedFit (even though _ScrollX is not set)
        // So columns will adopt the "Fixed" policy and will maintain a fixed width regardless of the whole available width (unless table is small)
        // If there is not enough available width to fit all columns, they will however be resized down.
        // FIXME-TABLE: Providing a stretch-on-init would make sense especially for tables which don't have saved settings
        HelpMarker(
            "Using _Resizable + _SizingFixedFit flags.\n"
            "Fixed-width columns generally makes more sense if you want to use horizontal scrolling.\n\n"
            "Double-click a column border to auto-fit the column to its contents.");
        PushStyleCompact();
        static BBZGUITableFlags flags = BBZGUITableFlags_SizingFixedFit | BBZGUITableFlags_Resizable | BBZGUITableFlags_BordersOuter | BBZGUITableFlags_BordersV | BBZGUITableFlags_ContextMenuInBody;
        BBZGUI::CheckboxFlags("BBZGUITableFlags_NoHostExtendX", &flags, BBZGUITableFlags_NoHostExtendX);
        PopStyleCompact();

        if (BBZGUI::BeginTable("table1", 3, flags))
        {
            for (int row = 0; row < 5; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 3; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    BBZGUI::Text("Hello %d,%d", column, row);
                }
            }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Resizable, mixed");
    if (BBZGUI::TreeNode("Resizable, mixed"))
    {
        HelpMarker(
            "Using TableSetupColumn() to alter resizing policy on a per-column basis.\n\n"
            "When combining Fixed and Stretch columns, generally you only want one, maybe two trailing columns to use _WidthStretch.");
        static BBZGUITableFlags flags = BBZGUITableFlags_SizingFixedFit | BBZGUITableFlags_RowBg | BBZGUITableFlags_Borders | BBZGUITableFlags_Resizable | BBZGUITableFlags_Reorderable | BBZGUITableFlags_Hideable;

        if (BBZGUI::BeginTable("table1", 3, flags))
        {
            BBZGUI::TableSetupColumn("AAA", BBZGUITableColumnFlags_WidthFixed);
            BBZGUI::TableSetupColumn("BBB", BBZGUITableColumnFlags_WidthFixed);
            BBZGUI::TableSetupColumn("CCC", BBZGUITableColumnFlags_WidthStretch);
            BBZGUI::TableHeadersRow();
            for (int row = 0; row < 5; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 3; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    BBZGUI::Text("%s %d,%d", (column == 2) ? "Stretch" : "Fixed", column, row);
                }
            }
            BBZGUI::EndTable();
        }
        if (BBZGUI::BeginTable("table2", 6, flags))
        {
            BBZGUI::TableSetupColumn("AAA", BBZGUITableColumnFlags_WidthFixed);
            BBZGUI::TableSetupColumn("BBB", BBZGUITableColumnFlags_WidthFixed);
            BBZGUI::TableSetupColumn("CCC", BBZGUITableColumnFlags_WidthFixed | BBZGUITableColumnFlags_DefaultHide);
            BBZGUI::TableSetupColumn("DDD", BBZGUITableColumnFlags_WidthStretch);
            BBZGUI::TableSetupColumn("EEE", BBZGUITableColumnFlags_WidthStretch);
            BBZGUI::TableSetupColumn("FFF", BBZGUITableColumnFlags_WidthStretch | BBZGUITableColumnFlags_DefaultHide);
            BBZGUI::TableHeadersRow();
            for (int row = 0; row < 5; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 6; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    BBZGUI::Text("%s %d,%d", (column >= 3) ? "Stretch" : "Fixed", column, row);
                }
            }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Reorderable, hideable, with headers");
    if (BBZGUI::TreeNode("Reorderable, hideable, with headers"))
    {
        HelpMarker(
            "Click and drag column headers to reorder columns.\n\n"
            "Right-click on a header to open a context menu.");
        static BBZGUITableFlags flags = BBZGUITableFlags_Resizable | BBZGUITableFlags_Reorderable | BBZGUITableFlags_Hideable | BBZGUITableFlags_BordersOuter | BBZGUITableFlags_BordersV;
        PushStyleCompact();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_Resizable", &flags, BBZGUITableFlags_Resizable);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_Reorderable", &flags, BBZGUITableFlags_Reorderable);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_Hideable", &flags, BBZGUITableFlags_Hideable);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_NoBordersInBody", &flags, BBZGUITableFlags_NoBordersInBody);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_NoBordersInBodyUntilResize", &flags, BBZGUITableFlags_NoBordersInBodyUntilResize); BBZGUI::SameLine(); HelpMarker("Disable vertical borders in columns Body until hovered for resize (borders will always appear in Headers)");
        BBZGUI::CheckboxFlags("BBZGUITableFlags_HighlightHoveredColumn", &flags, BBZGUITableFlags_HighlightHoveredColumn);
        PopStyleCompact();

        if (BBZGUI::BeginTable("table1", 3, flags))
        {
            // Submit columns name with TableSetupColumn() and call TableHeadersRow() to create a row with a header in each column.
            // (Later we will show how TableSetupColumn() has other uses, optional flags, sizing weight etc.)
            BBZGUI::TableSetupColumn("One");
            BBZGUI::TableSetupColumn("Two");
            BBZGUI::TableSetupColumn("Three");
            BBZGUI::TableHeadersRow();
            for (int row = 0; row < 6; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 3; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    BBZGUI::Text("Hello %d,%d", column, row);
                }
            }
            BBZGUI::EndTable();
        }

        // Use outer_size.x == 0.0f instead of default to make the table as tight as possible
        // (only valid when no scrolling and no stretch column)
        if (BBZGUI::BeginTable("table2", 3, flags | BBZGUITableFlags_SizingFixedFit, ImVec2(0.0f, 0.0f)))
        {
            BBZGUI::TableSetupColumn("One");
            BBZGUI::TableSetupColumn("Two");
            BBZGUI::TableSetupColumn("Three");
            BBZGUI::TableHeadersRow();
            for (int row = 0; row < 6; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 3; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    BBZGUI::Text("Fixed %d,%d", column, row);
                }
            }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Padding");
    if (BBZGUI::TreeNode("Padding"))
    {
        // First example: showcase use of padding flags and effect of BorderOuterV/BorderInnerV on X padding.
        // We don't expose BorderOuterH/BorderInnerH here because they have no effect on X padding.
        HelpMarker(
            "We often want outer padding activated when any using features which makes the edges of a column visible:\n"
            "e.g.:\n"
            "- BorderOuterV\n"
            "- any form of row selection\n"
            "Because of this, activating BorderOuterV sets the default to PadOuterX. "
            "Using PadOuterX or NoPadOuterX you can override the default.\n\n"
            "Actual padding values are using style.CellPadding.\n\n"
            "In this demo we don't show horizontal borders to emphasize how they don't affect default horizontal padding.");

        static BBZGUITableFlags flags1 = BBZGUITableFlags_BordersV;
        PushStyleCompact();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_PadOuterX", &flags1, BBZGUITableFlags_PadOuterX);
        BBZGUI::SameLine(); HelpMarker("Enable outer-most padding (default if BBZGUITableFlags_BordersOuterV is set)");
        BBZGUI::CheckboxFlags("BBZGUITableFlags_NoPadOuterX", &flags1, BBZGUITableFlags_NoPadOuterX);
        BBZGUI::SameLine(); HelpMarker("Disable outer-most padding (default if BBZGUITableFlags_BordersOuterV is not set)");
        BBZGUI::CheckboxFlags("BBZGUITableFlags_NoPadInnerX", &flags1, BBZGUITableFlags_NoPadInnerX);
        BBZGUI::SameLine(); HelpMarker("Disable inner padding between columns (double inner padding if BordersOuterV is on, single inner padding if BordersOuterV is off)");
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersOuterV", &flags1, BBZGUITableFlags_BordersOuterV);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersInnerV", &flags1, BBZGUITableFlags_BordersInnerV);
        static bool show_headers = false;
        BBZGUI::Checkbox("show_headers", &show_headers);
        PopStyleCompact();

        if (BBZGUI::BeginTable("table_padding", 3, flags1))
        {
            if (show_headers)
            {
                BBZGUI::TableSetupColumn("One");
                BBZGUI::TableSetupColumn("Two");
                BBZGUI::TableSetupColumn("Three");
                BBZGUI::TableHeadersRow();
            }

            for (int row = 0; row < 5; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 3; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    if (row == 0)
                    {
                        BBZGUI::Text("Avail %.2f", BBZGUI::GetContentRegionAvail().x);
                    }
                    else
                    {
                        char buf[32];
                        sprintf(buf, "Hello %d,%d", column, row);
                        BBZGUI::Button(buf, ImVec2(-FLT_MIN, 0.0f));
                    }
                    //if (BBZGUI::TableGetColumnFlags() & BBZGUITableColumnFlags_IsHovered)
                    //    BBZGUI::TableSetBgColor(BBZGUITableBgTarget_CellBg, IM_COL32(0, 100, 0, 255));
                }
            }
            BBZGUI::EndTable();
        }

        // Second example: set style.CellPadding to (0.0) or a custom value.
        // FIXME-TABLE: Vertical border effectively not displayed the same way as horizontal one...
        HelpMarker("Setting style.CellPadding to (0,0) or a custom value.");
        static BBZGUITableFlags flags2 = BBZGUITableFlags_Borders | BBZGUITableFlags_RowBg;
        static ImVec2 cell_padding(0.0f, 0.0f);
        static bool show_widget_frame_bg = true;

        PushStyleCompact();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_Borders", &flags2, BBZGUITableFlags_Borders);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersH", &flags2, BBZGUITableFlags_BordersH);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersV", &flags2, BBZGUITableFlags_BordersV);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersInner", &flags2, BBZGUITableFlags_BordersInner);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersOuter", &flags2, BBZGUITableFlags_BordersOuter);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_RowBg", &flags2, BBZGUITableFlags_RowBg);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_Resizable", &flags2, BBZGUITableFlags_Resizable);
        BBZGUI::Checkbox("show_widget_frame_bg", &show_widget_frame_bg);
        BBZGUI::SliderFloat2("CellPadding", &cell_padding.x, 0.0f, 10.0f, "%.0f");
        PopStyleCompact();

        BBZGUI::PushStyleVar(BBZGUIStyleVar_CellPadding, cell_padding);
        if (BBZGUI::BeginTable("table_padding_2", 3, flags2))
        {
            static char text_bufs[3 * 5][16]; // Mini text storage for 3x5 cells
            static bool init = true;
            if (!show_widget_frame_bg)
                BBZGUI::PushStyleColor(BBZGUICol_FrameBg, 0);
            for (int cell = 0; cell < 3 * 5; cell++)
            {
                BBZGUI::TableNextColumn();
                if (init)
                    strcpy(text_bufs[cell], "edit me");
                BBZGUI::SetNextItemWidth(-FLT_MIN);
                BBZGUI::PushID(cell);
                BBZGUI::InputText("##cell", text_bufs[cell], IM_ARRAYSIZE(text_bufs[cell]));
                BBZGUI::PopID();
            }
            if (!show_widget_frame_bg)
                BBZGUI::PopStyleColor();
            init = false;
            BBZGUI::EndTable();
        }
        BBZGUI::PopStyleVar();

        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Explicit widths");
    if (BBZGUI::TreeNode("Sizing policies"))
    {
        static BBZGUITableFlags flags1 = BBZGUITableFlags_BordersV | BBZGUITableFlags_BordersOuterH | BBZGUITableFlags_RowBg | BBZGUITableFlags_ContextMenuInBody;
        PushStyleCompact();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_Resizable", &flags1, BBZGUITableFlags_Resizable);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_NoHostExtendX", &flags1, BBZGUITableFlags_NoHostExtendX);
        PopStyleCompact();

        static BBZGUITableFlags sizing_policy_flags[4] = { BBZGUITableFlags_SizingFixedFit, BBZGUITableFlags_SizingFixedSame, BBZGUITableFlags_SizingStretchProp, BBZGUITableFlags_SizingStretchSame };
        for (int table_n = 0; table_n < 4; table_n++)
        {
            BBZGUI::PushID(table_n);
            BBZGUI::SetNextItemWidth(TEXT_BASE_WIDTH * 30);
            EditTableSizingFlags(&sizing_policy_flags[table_n]);

            // To make it easier to understand the different sizing policy,
            // For each policy: we display one table where the columns have equal contents width,
            // and one where the columns have different contents width.
            if (BBZGUI::BeginTable("table1", 3, sizing_policy_flags[table_n] | flags1))
            {
                for (int row = 0; row < 3; row++)
                {
                    BBZGUI::TableNextRow();
                    BBZGUI::TableNextColumn(); BBZGUI::Text("Oh dear");
                    BBZGUI::TableNextColumn(); BBZGUI::Text("Oh dear");
                    BBZGUI::TableNextColumn(); BBZGUI::Text("Oh dear");
                }
                BBZGUI::EndTable();
            }
            if (BBZGUI::BeginTable("table2", 3, sizing_policy_flags[table_n] | flags1))
            {
                for (int row = 0; row < 3; row++)
                {
                    BBZGUI::TableNextRow();
                    BBZGUI::TableNextColumn(); BBZGUI::Text("AAAA");
                    BBZGUI::TableNextColumn(); BBZGUI::Text("BBBBBBBB");
                    BBZGUI::TableNextColumn(); BBZGUI::Text("CCCCCCCCCCCC");
                }
                BBZGUI::EndTable();
            }
            BBZGUI::PopID();
        }

        BBZGUI::Spacing();
        BBZGUI::TextUnformatted("Advanced");
        BBZGUI::SameLine();
        HelpMarker(
            "This section allows you to interact and see the effect of various sizing policies "
            "depending on whether Scroll is enabled and the contents of your columns.");

        enum ContentsType { CT_ShowWidth, CT_ShortText, CT_LongText, CT_Button, CT_FillButton, CT_InputText };
        static BBZGUITableFlags flags = BBZGUITableFlags_ScrollY | BBZGUITableFlags_Borders | BBZGUITableFlags_RowBg | BBZGUITableFlags_Resizable;
        static int contents_type = CT_ShowWidth;
        static int column_count = 3;

        PushStyleCompact();
        BBZGUI::PushID("Advanced");
        BBZGUI::PushItemWidth(TEXT_BASE_WIDTH * 30);
        EditTableSizingFlags(&flags);
        BBZGUI::Combo("Contents", &contents_type, "Show width\0Short Text\0Long Text\0Button\0Fill Button\0InputText\0");
        if (contents_type == CT_FillButton)
        {
            BBZGUI::SameLine();
            HelpMarker(
                "Be mindful that using right-alignment (e.g. size.x = -FLT_MIN) creates a feedback loop "
                "where contents width can feed into auto-column width can feed into contents width.");
        }
        BBZGUI::DragInt("Columns", &column_count, 0.1f, 1, 64, "%d", BBZGUISliderFlags_AlwaysClamp);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_Resizable", &flags, BBZGUITableFlags_Resizable);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_PreciseWidths", &flags, BBZGUITableFlags_PreciseWidths);
        BBZGUI::SameLine(); HelpMarker("Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.");
        BBZGUI::CheckboxFlags("BBZGUITableFlags_ScrollX", &flags, BBZGUITableFlags_ScrollX);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_ScrollY", &flags, BBZGUITableFlags_ScrollY);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_NoClip", &flags, BBZGUITableFlags_NoClip);
        BBZGUI::PopItemWidth();
        BBZGUI::PopID();
        PopStyleCompact();

        if (BBZGUI::BeginTable("table2", column_count, flags, ImVec2(0.0f, TEXT_BASE_HEIGHT * 7)))
        {
            for (int cell = 0; cell < 10 * column_count; cell++)
            {
                BBZGUI::TableNextColumn();
                int column = BBZGUI::TableGetColumnIndex();
                int row = BBZGUI::TableGetRowIndex();

                BBZGUI::PushID(cell);
                char label[32];
                static char text_buf[32] = "";
                sprintf(label, "Hello %d,%d", column, row);
                switch (contents_type)
                {
                case CT_ShortText:  BBZGUI::TextUnformatted(label); break;
                case CT_LongText:   BBZGUI::Text("Some %s text %d,%d\nOver two lines..", column == 0 ? "long" : "longeeer", column, row); break;
                case CT_ShowWidth:  BBZGUI::Text("W: %.1f", BBZGUI::GetContentRegionAvail().x); break;
                case CT_Button:     BBZGUI::Button(label); break;
                case CT_FillButton: BBZGUI::Button(label, ImVec2(-FLT_MIN, 0.0f)); break;
                case CT_InputText:  BBZGUI::SetNextItemWidth(-FLT_MIN); BBZGUI::InputText("##", text_buf, IM_ARRAYSIZE(text_buf)); break;
                }
                BBZGUI::PopID();
            }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Vertical scrolling, with clipping");
    if (BBZGUI::TreeNode("Vertical scrolling, with clipping"))
    {
        HelpMarker(
            "Here we activate ScrollY, which will create a child window container to allow hosting scrollable contents.\n\n"
            "We also demonstrate using BBZGUIListClipper to virtualize the submission of many items.");
        static BBZGUITableFlags flags = BBZGUITableFlags_ScrollY | BBZGUITableFlags_RowBg | BBZGUITableFlags_BordersOuter | BBZGUITableFlags_BordersV | BBZGUITableFlags_Resizable | BBZGUITableFlags_Reorderable | BBZGUITableFlags_Hideable;

        PushStyleCompact();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_ScrollY", &flags, BBZGUITableFlags_ScrollY);
        PopStyleCompact();

        // When using ScrollX or ScrollY we need to specify a size for our table container!
        // Otherwise by default the table will fit all available space, like a BeginChild() call.
        ImVec2 outer_size = ImVec2(0.0f, TEXT_BASE_HEIGHT * 8);
        if (BBZGUI::BeginTable("table_scrolly", 3, flags, outer_size))
        {
            BBZGUI::TableSetupScrollFreeze(0, 1); // Make top row always visible
            BBZGUI::TableSetupColumn("One", BBZGUITableColumnFlags_None);
            BBZGUI::TableSetupColumn("Two", BBZGUITableColumnFlags_None);
            BBZGUI::TableSetupColumn("Three", BBZGUITableColumnFlags_None);
            BBZGUI::TableHeadersRow();

            // Demonstrate using clipper for large vertical lists
            BBZGUIListClipper clipper;
            clipper.Begin(1000);
            while (clipper.Step())
            {
                for (int row = clipper.DisplayStart; row < clipper.DisplayEnd; row++)
                {
                    BBZGUI::TableNextRow();
                    for (int column = 0; column < 3; column++)
                    {
                        BBZGUI::TableSetColumnIndex(column);
                        BBZGUI::Text("Hello %d,%d", column, row);
                    }
                }
            }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Horizontal scrolling");
    if (BBZGUI::TreeNode("Horizontal scrolling"))
    {
        HelpMarker(
            "When ScrollX is enabled, the default sizing policy becomes BBZGUITableFlags_SizingFixedFit, "
            "as automatically stretching columns doesn't make much sense with horizontal scrolling.\n\n"
            "Also note that as of the current version, you will almost always want to enable ScrollY along with ScrollX, "
            "because the container window won't automatically extend vertically to fix contents "
            "(this may be improved in future versions).");
        static BBZGUITableFlags flags = BBZGUITableFlags_ScrollX | BBZGUITableFlags_ScrollY | BBZGUITableFlags_RowBg | BBZGUITableFlags_BordersOuter | BBZGUITableFlags_BordersV | BBZGUITableFlags_Resizable | BBZGUITableFlags_Reorderable | BBZGUITableFlags_Hideable;
        static int freeze_cols = 1;
        static int freeze_rows = 1;

        PushStyleCompact();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_Resizable", &flags, BBZGUITableFlags_Resizable);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_ScrollX", &flags, BBZGUITableFlags_ScrollX);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_ScrollY", &flags, BBZGUITableFlags_ScrollY);
        BBZGUI::SetNextItemWidth(BBZGUI::GetFrameHeight());
        BBZGUI::DragInt("freeze_cols", &freeze_cols, 0.2f, 0, 9, NULL, BBZGUISliderFlags_NoInput);
        BBZGUI::SetNextItemWidth(BBZGUI::GetFrameHeight());
        BBZGUI::DragInt("freeze_rows", &freeze_rows, 0.2f, 0, 9, NULL, BBZGUISliderFlags_NoInput);
        PopStyleCompact();

        // When using ScrollX or ScrollY we need to specify a size for our table container!
        // Otherwise by default the table will fit all available space, like a BeginChild() call.
        ImVec2 outer_size = ImVec2(0.0f, TEXT_BASE_HEIGHT * 8);
        if (BBZGUI::BeginTable("table_scrollx", 7, flags, outer_size))
        {
            BBZGUI::TableSetupScrollFreeze(freeze_cols, freeze_rows);
            BBZGUI::TableSetupColumn("Line #", BBZGUITableColumnFlags_NoHide); // Make the first column not hideable to match our use of TableSetupScrollFreeze()
            BBZGUI::TableSetupColumn("One");
            BBZGUI::TableSetupColumn("Two");
            BBZGUI::TableSetupColumn("Three");
            BBZGUI::TableSetupColumn("Four");
            BBZGUI::TableSetupColumn("Five");
            BBZGUI::TableSetupColumn("Six");
            BBZGUI::TableHeadersRow();
            for (int row = 0; row < 20; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 7; column++)
                {
                    // Both TableNextColumn() and TableSetColumnIndex() return true when a column is visible or performing width measurement.
                    // Because here we know that:
                    // - A) all our columns are contributing the same to row height
                    // - B) column 0 is always visible,
                    // We only always submit this one column and can skip others.
                    // More advanced per-column clipping behaviors may benefit from polling the status flags via TableGetColumnFlags().
                    if (!BBZGUI::TableSetColumnIndex(column) && column > 0)
                        continue;
                    if (column == 0)
                        BBZGUI::Text("Line %d", row);
                    else
                        BBZGUI::Text("Hello world %d,%d", column, row);
                }
            }
            BBZGUI::EndTable();
        }

        BBZGUI::Spacing();
        BBZGUI::TextUnformatted("Stretch + ScrollX");
        BBZGUI::SameLine();
        HelpMarker(
            "Showcase using Stretch columns + ScrollX together: "
            "this is rather unusual and only makes sense when specifying an 'inner_width' for the table!\n"
            "Without an explicit value, inner_width is == outer_size.x and therefore using Stretch columns "
            "along with ScrollX doesn't make sense.");
        static BBZGUITableFlags flags2 = BBZGUITableFlags_SizingStretchSame | BBZGUITableFlags_ScrollX | BBZGUITableFlags_ScrollY | BBZGUITableFlags_BordersOuter | BBZGUITableFlags_RowBg | BBZGUITableFlags_ContextMenuInBody;
        static float inner_width = 1000.0f;
        PushStyleCompact();
        BBZGUI::PushID("flags3");
        BBZGUI::PushItemWidth(TEXT_BASE_WIDTH * 30);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_ScrollX", &flags2, BBZGUITableFlags_ScrollX);
        BBZGUI::DragFloat("inner_width", &inner_width, 1.0f, 0.0f, FLT_MAX, "%.1f");
        BBZGUI::PopItemWidth();
        BBZGUI::PopID();
        PopStyleCompact();
        if (BBZGUI::BeginTable("table2", 7, flags2, outer_size, inner_width))
        {
            for (int cell = 0; cell < 20 * 7; cell++)
            {
                BBZGUI::TableNextColumn();
                BBZGUI::Text("Hello world %d,%d", BBZGUI::TableGetColumnIndex(), BBZGUI::TableGetRowIndex());
            }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Columns flags");
    if (BBZGUI::TreeNode("Columns flags"))
    {
        // Create a first table just to show all the options/flags we want to make visible in our example!
        const int column_count = 3;
        const char* column_names[column_count] = { "One", "Two", "Three" };
        static BBZGUITableColumnFlags column_flags[column_count] = { BBZGUITableColumnFlags_DefaultSort, BBZGUITableColumnFlags_None, BBZGUITableColumnFlags_DefaultHide };
        static BBZGUITableColumnFlags column_flags_out[column_count] = { 0, 0, 0 }; // Output from TableGetColumnFlags()

        if (BBZGUI::BeginTable("table_columns_flags_checkboxes", column_count, BBZGUITableFlags_None))
        {
            PushStyleCompact();
            for (int column = 0; column < column_count; column++)
            {
                BBZGUI::TableNextColumn();
                BBZGUI::PushID(column);
                BBZGUI::AlignTextToFramePadding(); // FIXME-TABLE: Workaround for wrong text baseline propagation across columns
                BBZGUI::Text("'%s'", column_names[column]);
                BBZGUI::Spacing();
                BBZGUI::Text("Input flags:");
                EditTableColumnsFlags(&column_flags[column]);
                BBZGUI::Spacing();
                BBZGUI::Text("Output flags:");
                BBZGUI::BeginDisabled();
                ShowTableColumnsStatusFlags(column_flags_out[column]);
                BBZGUI::EndDisabled();
                BBZGUI::PopID();
            }
            PopStyleCompact();
            BBZGUI::EndTable();
        }

        // Create the real table we care about for the example!
        // We use a scrolling table to be able to showcase the difference between the _IsEnabled and _IsVisible flags above,
        // otherwise in a non-scrolling table columns are always visible (unless using BBZGUITableFlags_NoKeepColumnsVisible
        // + resizing the parent window down).
        const BBZGUITableFlags flags
            = BBZGUITableFlags_SizingFixedFit | BBZGUITableFlags_ScrollX | BBZGUITableFlags_ScrollY
            | BBZGUITableFlags_RowBg | BBZGUITableFlags_BordersOuter | BBZGUITableFlags_BordersV
            | BBZGUITableFlags_Resizable | BBZGUITableFlags_Reorderable | BBZGUITableFlags_Hideable | BBZGUITableFlags_Sortable;
        ImVec2 outer_size = ImVec2(0.0f, TEXT_BASE_HEIGHT * 9);
        if (BBZGUI::BeginTable("table_columns_flags", column_count, flags, outer_size))
        {
            bool has_angled_header = false;
            for (int column = 0; column < column_count; column++)
            {
                has_angled_header |= (column_flags[column] & BBZGUITableColumnFlags_AngledHeader) != 0;
                BBZGUI::TableSetupColumn(column_names[column], column_flags[column]);
            }
            if (has_angled_header)
                BBZGUI::TableAngledHeadersRow();
            BBZGUI::TableHeadersRow();
            for (int column = 0; column < column_count; column++)
                column_flags_out[column] = BBZGUI::TableGetColumnFlags(column);
            float indent_step = (float)((int)TEXT_BASE_WIDTH / 2);
            for (int row = 0; row < 8; row++)
            {
                // Add some indentation to demonstrate usage of per-column IndentEnable/IndentDisable flags.
                BBZGUI::Indent(indent_step);
                BBZGUI::TableNextRow();
                for (int column = 0; column < column_count; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    BBZGUI::Text("%s %s", (column == 0) ? "Indented" : "Hello", BBZGUI::TableGetColumnName(column));
                }
            }
            BBZGUI::Unindent(indent_step * 8.0f);

            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Columns widths");
    if (BBZGUI::TreeNode("Columns widths"))
    {
        HelpMarker("Using TableSetupColumn() to setup default width.");

        static BBZGUITableFlags flags1 = BBZGUITableFlags_Borders | BBZGUITableFlags_NoBordersInBodyUntilResize;
        PushStyleCompact();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_Resizable", &flags1, BBZGUITableFlags_Resizable);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_NoBordersInBodyUntilResize", &flags1, BBZGUITableFlags_NoBordersInBodyUntilResize);
        PopStyleCompact();
        if (BBZGUI::BeginTable("table1", 3, flags1))
        {
            // We could also set BBZGUITableFlags_SizingFixedFit on the table and all columns will default to BBZGUITableColumnFlags_WidthFixed.
            BBZGUI::TableSetupColumn("one", BBZGUITableColumnFlags_WidthFixed, 100.0f); // Default to 100.0f
            BBZGUI::TableSetupColumn("two", BBZGUITableColumnFlags_WidthFixed, 200.0f); // Default to 200.0f
            BBZGUI::TableSetupColumn("three", BBZGUITableColumnFlags_WidthFixed);       // Default to auto
            BBZGUI::TableHeadersRow();
            for (int row = 0; row < 4; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 3; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    if (row == 0)
                        BBZGUI::Text("(w: %5.1f)", BBZGUI::GetContentRegionAvail().x);
                    else
                        BBZGUI::Text("Hello %d,%d", column, row);
                }
            }
            BBZGUI::EndTable();
        }

        HelpMarker(
            "Using TableSetupColumn() to setup explicit width.\n\nUnless _NoKeepColumnsVisible is set, "
            "fixed columns with set width may still be shrunk down if there's not enough space in the host.");

        static BBZGUITableFlags flags2 = BBZGUITableFlags_None;
        PushStyleCompact();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_NoKeepColumnsVisible", &flags2, BBZGUITableFlags_NoKeepColumnsVisible);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersInnerV", &flags2, BBZGUITableFlags_BordersInnerV);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersOuterV", &flags2, BBZGUITableFlags_BordersOuterV);
        PopStyleCompact();
        if (BBZGUI::BeginTable("table2", 4, flags2))
        {
            // We could also set BBZGUITableFlags_SizingFixedFit on the table and then all columns
            // will default to BBZGUITableColumnFlags_WidthFixed.
            BBZGUI::TableSetupColumn("", BBZGUITableColumnFlags_WidthFixed, 100.0f);
            BBZGUI::TableSetupColumn("", BBZGUITableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 15.0f);
            BBZGUI::TableSetupColumn("", BBZGUITableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 30.0f);
            BBZGUI::TableSetupColumn("", BBZGUITableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 15.0f);
            for (int row = 0; row < 5; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 4; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    if (row == 0)
                        BBZGUI::Text("(w: %5.1f)", BBZGUI::GetContentRegionAvail().x);
                    else
                        BBZGUI::Text("Hello %d,%d", column, row);
                }
            }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Nested tables");
    if (BBZGUI::TreeNode("Nested tables"))
    {
        HelpMarker("This demonstrates embedding a table into another table cell.");

        if (BBZGUI::BeginTable("table_nested1", 2, BBZGUITableFlags_Borders | BBZGUITableFlags_Resizable | BBZGUITableFlags_Reorderable | BBZGUITableFlags_Hideable))
        {
            BBZGUI::TableSetupColumn("A0");
            BBZGUI::TableSetupColumn("A1");
            BBZGUI::TableHeadersRow();

            BBZGUI::TableNextColumn();
            BBZGUI::Text("A0 Row 0");
            {
                float rows_height = TEXT_BASE_HEIGHT * 2;
                if (BBZGUI::BeginTable("table_nested2", 2, BBZGUITableFlags_Borders | BBZGUITableFlags_Resizable | BBZGUITableFlags_Reorderable | BBZGUITableFlags_Hideable))
                {
                    BBZGUI::TableSetupColumn("B0");
                    BBZGUI::TableSetupColumn("B1");
                    BBZGUI::TableHeadersRow();

                    BBZGUI::TableNextRow(BBZGUITableRowFlags_None, rows_height);
                    BBZGUI::TableNextColumn();
                    BBZGUI::Text("B0 Row 0");
                    BBZGUI::TableNextColumn();
                    BBZGUI::Text("B1 Row 0");
                    BBZGUI::TableNextRow(BBZGUITableRowFlags_None, rows_height);
                    BBZGUI::TableNextColumn();
                    BBZGUI::Text("B0 Row 1");
                    BBZGUI::TableNextColumn();
                    BBZGUI::Text("B1 Row 1");

                    BBZGUI::EndTable();
                }
            }
            BBZGUI::TableNextColumn(); BBZGUI::Text("A1 Row 0");
            BBZGUI::TableNextColumn(); BBZGUI::Text("A0 Row 1");
            BBZGUI::TableNextColumn(); BBZGUI::Text("A1 Row 1");
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Row height");
    if (BBZGUI::TreeNode("Row height"))
    {
        HelpMarker(
            "You can pass a 'min_row_height' to TableNextRow().\n\nRows are padded with 'style.CellPadding.y' on top and bottom, "
            "so effectively the minimum row height will always be >= 'style.CellPadding.y * 2.0f'.\n\n"
            "We cannot honor a _maximum_ row height as that would require a unique clipping rectangle per row.");
        if (BBZGUI::BeginTable("table_row_height", 1, BBZGUITableFlags_Borders))
        {
            for (int row = 0; row < 8; row++)
            {
                float min_row_height = (float)(int)(TEXT_BASE_HEIGHT * 0.30f * row);
                BBZGUI::TableNextRow(BBZGUITableRowFlags_None, min_row_height);
                BBZGUI::TableNextColumn();
                BBZGUI::Text("min_row_height = %.2f", min_row_height);
            }
            BBZGUI::EndTable();
        }

        HelpMarker(
            "Showcase using SameLine(0,0) to share Current Line Height between cells.\n\n"
            "Please note that Tables Row Height is not the same thing as Current Line Height, "
            "as a table cell may contains multiple lines.");
        if (BBZGUI::BeginTable("table_share_lineheight", 2, BBZGUITableFlags_Borders))
        {
            BBZGUI::TableNextRow();
            BBZGUI::TableNextColumn();
            BBZGUI::ColorButton("##1", ImVec4(0.13f, 0.26f, 0.40f, 1.0f), BBZGUIColorEditFlags_None, ImVec2(40, 40));
            BBZGUI::TableNextColumn();
            BBZGUI::Text("Line 1");
            BBZGUI::Text("Line 2");

            BBZGUI::TableNextRow();
            BBZGUI::TableNextColumn();
            BBZGUI::ColorButton("##2", ImVec4(0.13f, 0.26f, 0.40f, 1.0f), BBZGUIColorEditFlags_None, ImVec2(40, 40));
            BBZGUI::TableNextColumn();
            BBZGUI::SameLine(0.0f, 0.0f); // Reuse line height from previous column
            BBZGUI::Text("Line 1, with SameLine(0,0)");
            BBZGUI::Text("Line 2");

            BBZGUI::EndTable();
        }

        HelpMarker("Showcase altering CellPadding.y between rows. Note that CellPadding.x is locked for the entire table.");
        if (BBZGUI::BeginTable("table_changing_cellpadding_y", 1, BBZGUITableFlags_Borders))
        {
            BBZGUIStyle& style = BBZGUI::GetStyle();
            for (int row = 0; row < 8; row++)
            {
                if ((row % 3) == 2)
                    BBZGUI::PushStyleVarY(BBZGUIStyleVar_CellPadding, 20.0f);
                BBZGUI::TableNextRow(BBZGUITableRowFlags_None);
                BBZGUI::TableNextColumn();
                BBZGUI::Text("CellPadding.y = %.2f", style.CellPadding.y);
                if ((row % 3) == 2)
                    BBZGUI::PopStyleVar();
            }
            BBZGUI::EndTable();
        }

        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Outer size");
    if (BBZGUI::TreeNode("Outer size"))
    {
        // Showcasing use of BBZGUITableFlags_NoHostExtendX and BBZGUITableFlags_NoHostExtendY
        // Important to that note how the two flags have slightly different behaviors!
        BBZGUI::Text("Using NoHostExtendX and NoHostExtendY:");
        PushStyleCompact();
        static BBZGUITableFlags flags = BBZGUITableFlags_Borders | BBZGUITableFlags_Resizable | BBZGUITableFlags_ContextMenuInBody | BBZGUITableFlags_RowBg | BBZGUITableFlags_SizingFixedFit | BBZGUITableFlags_NoHostExtendX;
        BBZGUI::CheckboxFlags("BBZGUITableFlags_NoHostExtendX", &flags, BBZGUITableFlags_NoHostExtendX);
        BBZGUI::SameLine(); HelpMarker("Make outer width auto-fit to columns, overriding outer_size.x value.\n\nOnly available when ScrollX/ScrollY are disabled and Stretch columns are not used.");
        BBZGUI::CheckboxFlags("BBZGUITableFlags_NoHostExtendY", &flags, BBZGUITableFlags_NoHostExtendY);
        BBZGUI::SameLine(); HelpMarker("Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit).\n\nOnly available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.");
        PopStyleCompact();

        ImVec2 outer_size = ImVec2(0.0f, TEXT_BASE_HEIGHT * 5.5f);
        if (BBZGUI::BeginTable("table1", 3, flags, outer_size))
        {
            for (int row = 0; row < 10; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 3; column++)
                {
                    BBZGUI::TableNextColumn();
                    BBZGUI::Text("Cell %d,%d", column, row);
                }
            }
            BBZGUI::EndTable();
        }
        BBZGUI::SameLine();
        BBZGUI::Text("Hello!");

        BBZGUI::Spacing();

        BBZGUI::Text("Using explicit size:");
        if (BBZGUI::BeginTable("table2", 3, BBZGUITableFlags_Borders | BBZGUITableFlags_RowBg, ImVec2(TEXT_BASE_WIDTH * 30, 0.0f)))
        {
            for (int row = 0; row < 5; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 3; column++)
                {
                    BBZGUI::TableNextColumn();
                    BBZGUI::Text("Cell %d,%d", column, row);
                }
            }
            BBZGUI::EndTable();
        }
        BBZGUI::SameLine();
        if (BBZGUI::BeginTable("table3", 3, BBZGUITableFlags_Borders | BBZGUITableFlags_RowBg, ImVec2(TEXT_BASE_WIDTH * 30, 0.0f)))
        {
            for (int row = 0; row < 3; row++)
            {
                BBZGUI::TableNextRow(0, TEXT_BASE_HEIGHT * 1.5f);
                for (int column = 0; column < 3; column++)
                {
                    BBZGUI::TableNextColumn();
                    BBZGUI::Text("Cell %d,%d", column, row);
                }
            }
            BBZGUI::EndTable();
        }

        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Background color");
    if (BBZGUI::TreeNode("Background color"))
    {
        static BBZGUITableFlags flags = BBZGUITableFlags_RowBg;
        static int row_bg_type = 1;
        static int row_bg_target = 1;
        static int cell_bg_type = 1;

        PushStyleCompact();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_Borders", &flags, BBZGUITableFlags_Borders);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_RowBg", &flags, BBZGUITableFlags_RowBg);
        BBZGUI::SameLine(); HelpMarker("BBZGUITableFlags_RowBg automatically sets RowBg0 to alternative colors pulled from the Style.");
        BBZGUI::Combo("row bg type", (int*)&row_bg_type, "None\0Red\0Gradient\0");
        BBZGUI::Combo("row bg target", (int*)&row_bg_target, "RowBg0\0RowBg1\0"); BBZGUI::SameLine(); HelpMarker("Target RowBg0 to override the alternating odd/even colors,\nTarget RowBg1 to blend with them.");
        BBZGUI::Combo("cell bg type", (int*)&cell_bg_type, "None\0Blue\0"); BBZGUI::SameLine(); HelpMarker("We are colorizing cells to B1->C2 here.");
        IM_ASSERT(row_bg_type >= 0 && row_bg_type <= 2);
        IM_ASSERT(row_bg_target >= 0 && row_bg_target <= 1);
        IM_ASSERT(cell_bg_type >= 0 && cell_bg_type <= 1);
        PopStyleCompact();

        if (BBZGUI::BeginTable("table1", 5, flags))
        {
            for (int row = 0; row < 6; row++)
            {
                BBZGUI::TableNextRow();

                // Demonstrate setting a row background color with 'BBZGUI::TableSetBgColor(BBZGUITableBgTarget_RowBgX, ...)'
                // We use a transparent color so we can see the one behind in case our target is RowBg1 and RowBg0 was already targeted by the BBZGUITableFlags_RowBg flag.
                if (row_bg_type != 0)
                {
                    ImU32 row_bg_color = BBZGUI::GetColorU32(row_bg_type == 1 ? ImVec4(0.7f, 0.3f, 0.3f, 0.65f) : ImVec4(0.2f + row * 0.1f, 0.2f, 0.2f, 0.65f)); // Flat or Gradient?
                    BBZGUI::TableSetBgColor(BBZGUITableBgTarget_RowBg0 + row_bg_target, row_bg_color);
                }

                // Fill cells
                for (int column = 0; column < 5; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    BBZGUI::Text("%c%c", 'A' + row, '0' + column);

                    // Change background of Cells B1->C2
                    // Demonstrate setting a cell background color with 'BBZGUI::TableSetBgColor(BBZGUITableBgTarget_CellBg, ...)'
                    // (the CellBg color will be blended over the RowBg and ColumnBg colors)
                    // We can also pass a column number as a third parameter to TableSetBgColor() and do this outside the column loop.
                    if (row >= 1 && row <= 2 && column >= 1 && column <= 2 && cell_bg_type == 1)
                    {
                        ImU32 cell_bg_color = BBZGUI::GetColorU32(ImVec4(0.3f, 0.3f, 0.7f, 0.65f));
                        BBZGUI::TableSetBgColor(BBZGUITableBgTarget_CellBg, cell_bg_color);
                    }
                }
            }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Tree view");
    if (BBZGUI::TreeNode("Tree view"))
    {
        static BBZGUITableFlags flags = BBZGUITableFlags_BordersV | BBZGUITableFlags_BordersOuterH | BBZGUITableFlags_Resizable | BBZGUITableFlags_RowBg | BBZGUITableFlags_NoBordersInBody;

        static BBZGUITreeNodeFlags tree_node_flags = BBZGUITreeNodeFlags_SpanAllColumns;
        BBZGUI::CheckboxFlags("BBZGUITreeNodeFlags_SpanFullWidth",  &tree_node_flags, BBZGUITreeNodeFlags_SpanFullWidth);
        BBZGUI::CheckboxFlags("BBZGUITreeNodeFlags_SpanTextWidth",  &tree_node_flags, BBZGUITreeNodeFlags_SpanTextWidth);
        BBZGUI::CheckboxFlags("BBZGUITreeNodeFlags_SpanAllColumns", &tree_node_flags, BBZGUITreeNodeFlags_SpanAllColumns);

        HelpMarker("See \"Columns flags\" section to configure how indentation is applied to individual columns.");
        if (BBZGUI::BeginTable("3ways", 3, flags))
        {
            // The first column will use the default _WidthStretch when ScrollX is Off and _WidthFixed when ScrollX is On
            BBZGUI::TableSetupColumn("Name", BBZGUITableColumnFlags_NoHide);
            BBZGUI::TableSetupColumn("Size", BBZGUITableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 12.0f);
            BBZGUI::TableSetupColumn("Type", BBZGUITableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 18.0f);
            BBZGUI::TableHeadersRow();

            // Simple storage to output a dummy file-system.
            struct MyTreeNode
            {
                const char*     Name;
                const char*     Type;
                int             Size;
                int             ChildIdx;
                int             ChildCount;
                static void DisplayNode(const MyTreeNode* node, const MyTreeNode* all_nodes)
                {
                    BBZGUI::TableNextRow();
                    BBZGUI::TableNextColumn();
                    const bool is_folder = (node->ChildCount > 0);
                    if (is_folder)
                    {
                        bool open = BBZGUI::TreeNodeEx(node->Name, tree_node_flags);
                        BBZGUI::TableNextColumn();
                        BBZGUI::TextDisabled("--");
                        BBZGUI::TableNextColumn();
                        BBZGUI::TextUnformatted(node->Type);
                        if (open)
                        {
                            for (int child_n = 0; child_n < node->ChildCount; child_n++)
                                DisplayNode(&all_nodes[node->ChildIdx + child_n], all_nodes);
                            BBZGUI::TreePop();
                        }
                    }
                    else
                    {
                        BBZGUI::TreeNodeEx(node->Name, tree_node_flags | BBZGUITreeNodeFlags_Leaf | BBZGUITreeNodeFlags_Bullet | BBZGUITreeNodeFlags_NoTreePushOnOpen);
                        BBZGUI::TableNextColumn();
                        BBZGUI::Text("%d", node->Size);
                        BBZGUI::TableNextColumn();
                        BBZGUI::TextUnformatted(node->Type);
                    }
                }
            };
            static const MyTreeNode nodes[] =
            {
                { "Root",                         "Folder",       -1,       1, 3    }, // 0
                { "Music",                        "Folder",       -1,       4, 2    }, // 1
                { "Textures",                     "Folder",       -1,       6, 3    }, // 2
                { "desktop.ini",                  "System file",  1024,    -1,-1    }, // 3
                { "File1_a.wav",                  "Audio file",   123000,  -1,-1    }, // 4
                { "File1_b.wav",                  "Audio file",   456000,  -1,-1    }, // 5
                { "Image001.png",                 "Image file",   203128,  -1,-1    }, // 6
                { "Copy of Image001.png",         "Image file",   203256,  -1,-1    }, // 7
                { "Copy of Image001 (Final2).png","Image file",   203512,  -1,-1    }, // 8
            };

            MyTreeNode::DisplayNode(&nodes[0], nodes);

            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Item width");
    if (BBZGUI::TreeNode("Item width"))
    {
        HelpMarker(
            "Showcase using PushItemWidth() and how it is preserved on a per-column basis.\n\n"
            "Note that on auto-resizing non-resizable fixed columns, querying the content width for "
            "e.g. right-alignment doesn't make sense.");
        if (BBZGUI::BeginTable("table_item_width", 3, BBZGUITableFlags_Borders))
        {
            BBZGUI::TableSetupColumn("small");
            BBZGUI::TableSetupColumn("half");
            BBZGUI::TableSetupColumn("right-align");
            BBZGUI::TableHeadersRow();

            for (int row = 0; row < 3; row++)
            {
                BBZGUI::TableNextRow();
                if (row == 0)
                {
                    // Setup ItemWidth once (instead of setting up every time, which is also possible but less efficient)
                    BBZGUI::TableSetColumnIndex(0);
                    BBZGUI::PushItemWidth(TEXT_BASE_WIDTH * 3.0f); // Small
                    BBZGUI::TableSetColumnIndex(1);
                    BBZGUI::PushItemWidth(-BBZGUI::GetContentRegionAvail().x * 0.5f);
                    BBZGUI::TableSetColumnIndex(2);
                    BBZGUI::PushItemWidth(-FLT_MIN); // Right-aligned
                }

                // Draw our contents
                static float dummy_f = 0.0f;
                BBZGUI::PushID(row);
                BBZGUI::TableSetColumnIndex(0);
                BBZGUI::SliderFloat("float0", &dummy_f, 0.0f, 1.0f);
                BBZGUI::TableSetColumnIndex(1);
                BBZGUI::SliderFloat("float1", &dummy_f, 0.0f, 1.0f);
                BBZGUI::TableSetColumnIndex(2);
                BBZGUI::SliderFloat("##float2", &dummy_f, 0.0f, 1.0f); // No visible label since right-aligned
                BBZGUI::PopID();
            }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    // Demonstrate using TableHeader() calls instead of TableHeadersRow()
    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Custom headers");
    if (BBZGUI::TreeNode("Custom headers"))
    {
        const int COLUMNS_COUNT = 3;
        if (BBZGUI::BeginTable("table_custom_headers", COLUMNS_COUNT, BBZGUITableFlags_Borders | BBZGUITableFlags_Reorderable | BBZGUITableFlags_Hideable))
        {
            BBZGUI::TableSetupColumn("Apricot");
            BBZGUI::TableSetupColumn("Banana");
            BBZGUI::TableSetupColumn("Cherry");

            // Dummy entire-column selection storage
            // FIXME: It would be nice to actually demonstrate full-featured selection using those checkbox.
            static bool column_selected[3] = {};

            // Instead of calling TableHeadersRow() we'll submit custom headers ourselves.
            // (A different approach is also possible:
            //    - Specify BBZGUITableColumnFlags_NoHeaderLabel in some TableSetupColumn() call.
            //    - Call TableHeadersRow() normally. This will submit TableHeader() with no name.
            //    - Then call TableSetColumnIndex() to position yourself in the column and submit your stuff e.g. Checkbox().)
            BBZGUI::TableNextRow(BBZGUITableRowFlags_Headers);
            for (int column = 0; column < COLUMNS_COUNT; column++)
            {
                BBZGUI::TableSetColumnIndex(column);
                const char* column_name = BBZGUI::TableGetColumnName(column); // Retrieve name passed to TableSetupColumn()
                BBZGUI::PushID(column);
                BBZGUI::PushStyleVar(BBZGUIStyleVar_FramePadding, ImVec2(0, 0));
                BBZGUI::Checkbox("##checkall", &column_selected[column]);
                BBZGUI::PopStyleVar();
                BBZGUI::SameLine(0.0f, BBZGUI::GetStyle().ItemInnerSpacing.x);
                BBZGUI::TableHeader(column_name);
                BBZGUI::PopID();
            }

            // Submit table contents
            for (int row = 0; row < 5; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < 3; column++)
                {
                    char buf[32];
                    sprintf(buf, "Cell %d,%d", column, row);
                    BBZGUI::TableSetColumnIndex(column);
                    BBZGUI::Selectable(buf, column_selected[column]);
                }
            }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    // Demonstrate using BBZGUITableColumnFlags_AngledHeader flag to create angled headers
    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Angled headers");
    if (BBZGUI::TreeNode("Angled headers"))
    {
        const char* column_names[] = { "Track", "cabasa", "ride", "smash", "tom-hi", "tom-mid", "tom-low", "hihat-o", "hihat-c", "snare-s", "snare-c", "clap", "rim", "kick" };
        const int columns_count = IM_ARRAYSIZE(column_names);
        const int rows_count = 12;

        static BBZGUITableFlags table_flags = BBZGUITableFlags_SizingFixedFit | BBZGUITableFlags_ScrollX | BBZGUITableFlags_ScrollY | BBZGUITableFlags_BordersOuter | BBZGUITableFlags_BordersInnerH | BBZGUITableFlags_Hideable | BBZGUITableFlags_Resizable | BBZGUITableFlags_Reorderable | BBZGUITableFlags_HighlightHoveredColumn;
        static BBZGUITableColumnFlags column_flags = BBZGUITableColumnFlags_AngledHeader | BBZGUITableColumnFlags_WidthFixed;
        static bool bools[columns_count * rows_count] = {}; // Dummy storage selection storage
        static int frozen_cols = 1;
        static int frozen_rows = 2;
        BBZGUI::CheckboxFlags("_ScrollX", &table_flags, BBZGUITableFlags_ScrollX);
        BBZGUI::CheckboxFlags("_ScrollY", &table_flags, BBZGUITableFlags_ScrollY);
        BBZGUI::CheckboxFlags("_Resizable", &table_flags, BBZGUITableFlags_Resizable);
        BBZGUI::CheckboxFlags("_Sortable", &table_flags, BBZGUITableFlags_Sortable);
        BBZGUI::CheckboxFlags("_NoBordersInBody", &table_flags, BBZGUITableFlags_NoBordersInBody);
        BBZGUI::CheckboxFlags("_HighlightHoveredColumn", &table_flags, BBZGUITableFlags_HighlightHoveredColumn);
        BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 8);
        BBZGUI::SliderInt("Frozen columns", &frozen_cols, 0, 2);
        BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 8);
        BBZGUI::SliderInt("Frozen rows", &frozen_rows, 0, 2);
        BBZGUI::CheckboxFlags("Disable header contributing to column width", &column_flags, BBZGUITableColumnFlags_NoHeaderWidth);

        if (BBZGUI::TreeNode("Style settings"))
        {
            BBZGUI::SameLine();
            HelpMarker("Giving access to some BBZGUIStyle value in this demo for convenience.");
            BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 8);
            BBZGUI::SliderAngle("style.TableAngledHeadersAngle", &BBZGUI::GetStyle().TableAngledHeadersAngle, -50.0f, +50.0f);
            BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 8);
            BBZGUI::SliderFloat2("style.TableAngledHeadersTextAlign", (float*)&BBZGUI::GetStyle().TableAngledHeadersTextAlign, 0.0f, 1.0f, "%.2f");
            BBZGUI::TreePop();
        }

        if (BBZGUI::BeginTable("table_angled_headers", columns_count, table_flags, ImVec2(0.0f, TEXT_BASE_HEIGHT * 12)))
        {
            BBZGUI::TableSetupColumn(column_names[0], BBZGUITableColumnFlags_NoHide | BBZGUITableColumnFlags_NoReorder);
            for (int n = 1; n < columns_count; n++)
                BBZGUI::TableSetupColumn(column_names[n], column_flags);
            BBZGUI::TableSetupScrollFreeze(frozen_cols, frozen_rows);

            BBZGUI::TableAngledHeadersRow(); // Draw angled headers for all columns with the BBZGUITableColumnFlags_AngledHeader flag.
            BBZGUI::TableHeadersRow();       // Draw remaining headers and allow access to context-menu and other functions.
            for (int row = 0; row < rows_count; row++)
            {
                BBZGUI::PushID(row);
                BBZGUI::TableNextRow();
                BBZGUI::TableSetColumnIndex(0);
                BBZGUI::AlignTextToFramePadding();
                BBZGUI::Text("Track %d", row);
                for (int column = 1; column < columns_count; column++)
                    if (BBZGUI::TableSetColumnIndex(column))
                    {
                        BBZGUI::PushID(column);
                        BBZGUI::Checkbox("", &bools[row * columns_count + column]);
                        BBZGUI::PopID();
                    }
                BBZGUI::PopID();
            }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    // Demonstrate creating custom context menus inside columns,
    // while playing it nice with context menus provided by TableHeadersRow()/TableHeader()
    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Context menus");
    if (BBZGUI::TreeNode("Context menus"))
    {
        HelpMarker(
            "By default, right-clicking over a TableHeadersRow()/TableHeader() line will open the default context-menu.\n"
            "Using BBZGUITableFlags_ContextMenuInBody we also allow right-clicking over columns body.");
        static BBZGUITableFlags flags1 = BBZGUITableFlags_Resizable | BBZGUITableFlags_Reorderable | BBZGUITableFlags_Hideable | BBZGUITableFlags_Borders | BBZGUITableFlags_ContextMenuInBody;

        PushStyleCompact();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_ContextMenuInBody", &flags1, BBZGUITableFlags_ContextMenuInBody);
        PopStyleCompact();

        // Context Menus: first example
        // [1.1] Right-click on the TableHeadersRow() line to open the default table context menu.
        // [1.2] Right-click in columns also open the default table context menu (if BBZGUITableFlags_ContextMenuInBody is set)
        const int COLUMNS_COUNT = 3;
        if (BBZGUI::BeginTable("table_context_menu", COLUMNS_COUNT, flags1))
        {
            BBZGUI::TableSetupColumn("One");
            BBZGUI::TableSetupColumn("Two");
            BBZGUI::TableSetupColumn("Three");

            // [1.1]] Right-click on the TableHeadersRow() line to open the default table context menu.
            BBZGUI::TableHeadersRow();

            // Submit dummy contents
            for (int row = 0; row < 4; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < COLUMNS_COUNT; column++)
                {
                    BBZGUI::TableSetColumnIndex(column);
                    BBZGUI::Text("Cell %d,%d", column, row);
                }
            }
            BBZGUI::EndTable();
        }

        // Context Menus: second example
        // [2.1] Right-click on the TableHeadersRow() line to open the default table context menu.
        // [2.2] Right-click on the ".." to open a custom popup
        // [2.3] Right-click in columns to open another custom popup
        HelpMarker(
            "Demonstrate mixing table context menu (over header), item context button (over button) "
            "and custom per-colunm context menu (over column body).");
        BBZGUITableFlags flags2 = BBZGUITableFlags_Resizable | BBZGUITableFlags_SizingFixedFit | BBZGUITableFlags_Reorderable | BBZGUITableFlags_Hideable | BBZGUITableFlags_Borders;
        if (BBZGUI::BeginTable("table_context_menu_2", COLUMNS_COUNT, flags2))
        {
            BBZGUI::TableSetupColumn("One");
            BBZGUI::TableSetupColumn("Two");
            BBZGUI::TableSetupColumn("Three");

            // [2.1] Right-click on the TableHeadersRow() line to open the default table context menu.
            BBZGUI::TableHeadersRow();
            for (int row = 0; row < 4; row++)
            {
                BBZGUI::TableNextRow();
                for (int column = 0; column < COLUMNS_COUNT; column++)
                {
                    // Submit dummy contents
                    BBZGUI::TableSetColumnIndex(column);
                    BBZGUI::Text("Cell %d,%d", column, row);
                    BBZGUI::SameLine();

                    // [2.2] Right-click on the ".." to open a custom popup
                    BBZGUI::PushID(row * COLUMNS_COUNT + column);
                    BBZGUI::SmallButton("..");
                    if (BBZGUI::BeginPopupContextItem())
                    {
                        BBZGUI::Text("This is the popup for Button(\"..\") in Cell %d,%d", column, row);
                        if (BBZGUI::Button("Close"))
                            BBZGUI::CloseCurrentPopup();
                        BBZGUI::EndPopup();
                    }
                    BBZGUI::PopID();
                }
            }

            // [2.3] Right-click anywhere in columns to open another custom popup
            // (instead of testing for !IsAnyItemHovered() we could also call OpenPopup() with BBZGUIPopupFlags_NoOpenOverExistingPopup
            // to manage popup priority as the popups triggers, here "are we hovering a column" are overlapping)
            int hovered_column = -1;
            for (int column = 0; column < COLUMNS_COUNT + 1; column++)
            {
                BBZGUI::PushID(column);
                if (BBZGUI::TableGetColumnFlags(column) & BBZGUITableColumnFlags_IsHovered)
                    hovered_column = column;
                if (hovered_column == column && !BBZGUI::IsAnyItemHovered() && BBZGUI::IsMouseReleased(1))
                    BBZGUI::OpenPopup("MyPopup");
                if (BBZGUI::BeginPopup("MyPopup"))
                {
                    if (column == COLUMNS_COUNT)
                        BBZGUI::Text("This is a custom popup for unused space after the last column.");
                    else
                        BBZGUI::Text("This is a custom popup for Column %d", column);
                    if (BBZGUI::Button("Close"))
                        BBZGUI::CloseCurrentPopup();
                    BBZGUI::EndPopup();
                }
                BBZGUI::PopID();
            }

            BBZGUI::EndTable();
            BBZGUI::Text("Hovered column: %d", hovered_column);
        }
        BBZGUI::TreePop();
    }

    // Demonstrate creating multiple tables with the same ID
    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Synced instances");
    if (BBZGUI::TreeNode("Synced instances"))
    {
        HelpMarker("Multiple tables with the same identifier will share their settings, width, visibility, order etc.");

        static BBZGUITableFlags flags = BBZGUITableFlags_Resizable | BBZGUITableFlags_Reorderable | BBZGUITableFlags_Hideable | BBZGUITableFlags_Borders | BBZGUITableFlags_SizingFixedFit | BBZGUITableFlags_NoSavedSettings;
        BBZGUI::CheckboxFlags("BBZGUITableFlags_Resizable", &flags, BBZGUITableFlags_Resizable);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_ScrollY", &flags, BBZGUITableFlags_ScrollY);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_SizingFixedFit", &flags, BBZGUITableFlags_SizingFixedFit);
        BBZGUI::CheckboxFlags("BBZGUITableFlags_HighlightHoveredColumn", &flags, BBZGUITableFlags_HighlightHoveredColumn);
        for (int n = 0; n < 3; n++)
        {
            char buf[32];
            sprintf(buf, "Synced Table %d", n);
            bool open = BBZGUI::CollapsingHeader(buf, BBZGUITreeNodeFlags_DefaultOpen);
            if (open && BBZGUI::BeginTable("Table", 3, flags, ImVec2(0.0f, BBZGUI::GetTextLineHeightWithSpacing() * 5)))
            {
                BBZGUI::TableSetupColumn("One");
                BBZGUI::TableSetupColumn("Two");
                BBZGUI::TableSetupColumn("Three");
                BBZGUI::TableHeadersRow();
                const int cell_count = (n == 1) ? 27 : 9; // Make second table have a scrollbar to verify that additional decoration is not affecting column positions.
                for (int cell = 0; cell < cell_count; cell++)
                {
                    BBZGUI::TableNextColumn();
                    BBZGUI::Text("this cell %d", cell);
                }
                BBZGUI::EndTable();
            }
        }
        BBZGUI::TreePop();
    }

    // Demonstrate using Sorting facilities
    // This is a simplified version of the "Advanced" example, where we mostly focus on the code necessary to handle sorting.
    // Note that the "Advanced" example also showcase manually triggering a sort (e.g. if item quantities have been modified)
    static const char* template_items_names[] =
    {
        "Banana", "Apple", "Cherry", "Watermelon", "Grapefruit", "Strawberry", "Mango",
        "Kiwi", "Orange", "Pineapple", "Blueberry", "Plum", "Coconut", "Pear", "Apricot"
    };
    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Sorting");
    if (BBZGUI::TreeNode("Sorting"))
    {
        // Create item list
        static ImVector<MyItem> items;
        if (items.Size == 0)
        {
            items.resize(50, MyItem());
            for (int n = 0; n < items.Size; n++)
            {
                const int template_n = n % IM_ARRAYSIZE(template_items_names);
                MyItem& item = items[n];
                item.ID = n;
                item.Name = template_items_names[template_n];
                item.Quantity = (n * n - n) % 20; // Assign default quantities
            }
        }

        // Options
        static BBZGUITableFlags flags =
            BBZGUITableFlags_Resizable | BBZGUITableFlags_Reorderable | BBZGUITableFlags_Hideable | BBZGUITableFlags_Sortable | BBZGUITableFlags_SortMulti
            | BBZGUITableFlags_RowBg | BBZGUITableFlags_BordersOuter | BBZGUITableFlags_BordersV | BBZGUITableFlags_NoBordersInBody
            | BBZGUITableFlags_ScrollY;
        PushStyleCompact();
        BBZGUI::CheckboxFlags("BBZGUITableFlags_SortMulti", &flags, BBZGUITableFlags_SortMulti);
        BBZGUI::SameLine(); HelpMarker("When sorting is enabled: hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).");
        BBZGUI::CheckboxFlags("BBZGUITableFlags_SortTristate", &flags, BBZGUITableFlags_SortTristate);
        BBZGUI::SameLine(); HelpMarker("When sorting is enabled: allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).");
        PopStyleCompact();

        if (BBZGUI::BeginTable("table_sorting", 4, flags, ImVec2(0.0f, TEXT_BASE_HEIGHT * 15), 0.0f))
        {
            // Declare columns
            // We use the "user_id" parameter of TableSetupColumn() to specify a user id that will be stored in the sort specifications.
            // This is so our sort function can identify a column given our own identifier. We could also identify them based on their index!
            // Demonstrate using a mixture of flags among available sort-related flags:
            // - BBZGUITableColumnFlags_DefaultSort
            // - BBZGUITableColumnFlags_NoSort / BBZGUITableColumnFlags_NoSortAscending / BBZGUITableColumnFlags_NoSortDescending
            // - BBZGUITableColumnFlags_PreferSortAscending / BBZGUITableColumnFlags_PreferSortDescending
            BBZGUI::TableSetupColumn("ID",       BBZGUITableColumnFlags_DefaultSort          | BBZGUITableColumnFlags_WidthFixed,   0.0f, MyItemColumnID_ID);
            BBZGUI::TableSetupColumn("Name",                                                  BBZGUITableColumnFlags_WidthFixed,   0.0f, MyItemColumnID_Name);
            BBZGUI::TableSetupColumn("Action",   BBZGUITableColumnFlags_NoSort               | BBZGUITableColumnFlags_WidthFixed,   0.0f, MyItemColumnID_Action);
            BBZGUI::TableSetupColumn("Quantity", BBZGUITableColumnFlags_PreferSortDescending | BBZGUITableColumnFlags_WidthStretch, 0.0f, MyItemColumnID_Quantity);
            BBZGUI::TableSetupScrollFreeze(0, 1); // Make row always visible
            BBZGUI::TableHeadersRow();

            // Sort our data if sort specs have been changed!
            if (BBZGUITableSortSpecs* sort_specs = BBZGUI::TableGetSortSpecs())
                if (sort_specs->SpecsDirty)
                {
                    MyItem::SortWithSortSpecs(sort_specs, items.Data, items.Size);
                    sort_specs->SpecsDirty = false;
                }

            // Demonstrate using clipper for large vertical lists
            BBZGUIListClipper clipper;
            clipper.Begin(items.Size);
            while (clipper.Step())
                for (int row_n = clipper.DisplayStart; row_n < clipper.DisplayEnd; row_n++)
                {
                    // Display a data item
                    MyItem* item = &items[row_n];
                    BBZGUI::PushID(item->ID);
                    BBZGUI::TableNextRow();
                    BBZGUI::TableNextColumn();
                    BBZGUI::Text("%04d", item->ID);
                    BBZGUI::TableNextColumn();
                    BBZGUI::TextUnformatted(item->Name);
                    BBZGUI::TableNextColumn();
                    BBZGUI::SmallButton("None");
                    BBZGUI::TableNextColumn();
                    BBZGUI::Text("%d", item->Quantity);
                    BBZGUI::PopID();
                }
            BBZGUI::EndTable();
        }
        BBZGUI::TreePop();
    }

    // In this example we'll expose most table flags and settings.
    // For specific flags and settings refer to the corresponding section for more detailed explanation.
    // This section is mostly useful to experiment with combining certain flags or settings with each others.
    //BBZGUI::SetNextItemOpen(true, BBZGUICond_Once); // [DEBUG]
    if (open_action != -1)
        BBZGUI::SetNextItemOpen(open_action != 0);
    IMGUI_DEMO_MARKER("Tables/Advanced");
    if (BBZGUI::TreeNode("Advanced"))
    {
        static BBZGUITableFlags flags =
            BBZGUITableFlags_Resizable | BBZGUITableFlags_Reorderable | BBZGUITableFlags_Hideable
            | BBZGUITableFlags_Sortable | BBZGUITableFlags_SortMulti
            | BBZGUITableFlags_RowBg | BBZGUITableFlags_Borders | BBZGUITableFlags_NoBordersInBody
            | BBZGUITableFlags_ScrollX | BBZGUITableFlags_ScrollY
            | BBZGUITableFlags_SizingFixedFit;
        static BBZGUITableColumnFlags columns_base_flags = BBZGUITableColumnFlags_None;

        enum ContentsType { CT_Text, CT_Button, CT_SmallButton, CT_FillButton, CT_Selectable, CT_SelectableSpanRow };
        static int contents_type = CT_SelectableSpanRow;
        const char* contents_type_names[] = { "Text", "Button", "SmallButton", "FillButton", "Selectable", "Selectable (span row)" };
        static int freeze_cols = 1;
        static int freeze_rows = 1;
        static int items_count = IM_ARRAYSIZE(template_items_names) * 2;
        static ImVec2 outer_size_value = ImVec2(0.0f, TEXT_BASE_HEIGHT * 12);
        static float row_min_height = 0.0f; // Auto
        static float inner_width_with_scroll = 0.0f; // Auto-extend
        static bool outer_size_enabled = true;
        static bool show_headers = true;
        static bool show_wrapped_text = false;
        //static BBZGUITextFilter filter;
        //BBZGUI::SetNextItemOpen(true, BBZGUICond_Once); // FIXME-TABLE: Enabling this results in initial clipped first pass on table which tend to affect column sizing
        if (BBZGUI::TreeNode("Options"))
        {
            // Make the UI compact because there are so many fields
            PushStyleCompact();
            BBZGUI::PushItemWidth(TEXT_BASE_WIDTH * 28.0f);

            if (BBZGUI::TreeNodeEx("Features:", BBZGUITreeNodeFlags_DefaultOpen))
            {
                BBZGUI::CheckboxFlags("BBZGUITableFlags_Resizable", &flags, BBZGUITableFlags_Resizable);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_Reorderable", &flags, BBZGUITableFlags_Reorderable);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_Hideable", &flags, BBZGUITableFlags_Hideable);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_Sortable", &flags, BBZGUITableFlags_Sortable);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_NoSavedSettings", &flags, BBZGUITableFlags_NoSavedSettings);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_ContextMenuInBody", &flags, BBZGUITableFlags_ContextMenuInBody);
                BBZGUI::TreePop();
            }

            if (BBZGUI::TreeNodeEx("Decorations:", BBZGUITreeNodeFlags_DefaultOpen))
            {
                BBZGUI::CheckboxFlags("BBZGUITableFlags_RowBg", &flags, BBZGUITableFlags_RowBg);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersV", &flags, BBZGUITableFlags_BordersV);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersOuterV", &flags, BBZGUITableFlags_BordersOuterV);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersInnerV", &flags, BBZGUITableFlags_BordersInnerV);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersH", &flags, BBZGUITableFlags_BordersH);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersOuterH", &flags, BBZGUITableFlags_BordersOuterH);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_BordersInnerH", &flags, BBZGUITableFlags_BordersInnerH);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_NoBordersInBody", &flags, BBZGUITableFlags_NoBordersInBody); BBZGUI::SameLine(); HelpMarker("Disable vertical borders in columns Body (borders will always appear in Headers");
                BBZGUI::CheckboxFlags("BBZGUITableFlags_NoBordersInBodyUntilResize", &flags, BBZGUITableFlags_NoBordersInBodyUntilResize); BBZGUI::SameLine(); HelpMarker("Disable vertical borders in columns Body until hovered for resize (borders will always appear in Headers)");
                BBZGUI::TreePop();
            }

            if (BBZGUI::TreeNodeEx("Sizing:", BBZGUITreeNodeFlags_DefaultOpen))
            {
                EditTableSizingFlags(&flags);
                BBZGUI::SameLine(); HelpMarker("In the Advanced demo we override the policy of each column so those table-wide settings have less effect that typical.");
                BBZGUI::CheckboxFlags("BBZGUITableFlags_NoHostExtendX", &flags, BBZGUITableFlags_NoHostExtendX);
                BBZGUI::SameLine(); HelpMarker("Make outer width auto-fit to columns, overriding outer_size.x value.\n\nOnly available when ScrollX/ScrollY are disabled and Stretch columns are not used.");
                BBZGUI::CheckboxFlags("BBZGUITableFlags_NoHostExtendY", &flags, BBZGUITableFlags_NoHostExtendY);
                BBZGUI::SameLine(); HelpMarker("Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit).\n\nOnly available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.");
                BBZGUI::CheckboxFlags("BBZGUITableFlags_NoKeepColumnsVisible", &flags, BBZGUITableFlags_NoKeepColumnsVisible);
                BBZGUI::SameLine(); HelpMarker("Only available if ScrollX is disabled.");
                BBZGUI::CheckboxFlags("BBZGUITableFlags_PreciseWidths", &flags, BBZGUITableFlags_PreciseWidths);
                BBZGUI::SameLine(); HelpMarker("Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.");
                BBZGUI::CheckboxFlags("BBZGUITableFlags_NoClip", &flags, BBZGUITableFlags_NoClip);
                BBZGUI::SameLine(); HelpMarker("Disable clipping rectangle for every individual columns (reduce draw command count, items will be able to overflow into other columns). Generally incompatible with ScrollFreeze options.");
                BBZGUI::TreePop();
            }

            if (BBZGUI::TreeNodeEx("Padding:", BBZGUITreeNodeFlags_DefaultOpen))
            {
                BBZGUI::CheckboxFlags("BBZGUITableFlags_PadOuterX", &flags, BBZGUITableFlags_PadOuterX);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_NoPadOuterX", &flags, BBZGUITableFlags_NoPadOuterX);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_NoPadInnerX", &flags, BBZGUITableFlags_NoPadInnerX);
                BBZGUI::TreePop();
            }

            if (BBZGUI::TreeNodeEx("Scrolling:", BBZGUITreeNodeFlags_DefaultOpen))
            {
                BBZGUI::CheckboxFlags("BBZGUITableFlags_ScrollX", &flags, BBZGUITableFlags_ScrollX);
                BBZGUI::SameLine();
                BBZGUI::SetNextItemWidth(BBZGUI::GetFrameHeight());
                BBZGUI::DragInt("freeze_cols", &freeze_cols, 0.2f, 0, 9, NULL, BBZGUISliderFlags_NoInput);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_ScrollY", &flags, BBZGUITableFlags_ScrollY);
                BBZGUI::SameLine();
                BBZGUI::SetNextItemWidth(BBZGUI::GetFrameHeight());
                BBZGUI::DragInt("freeze_rows", &freeze_rows, 0.2f, 0, 9, NULL, BBZGUISliderFlags_NoInput);
                BBZGUI::TreePop();
            }

            if (BBZGUI::TreeNodeEx("Sorting:", BBZGUITreeNodeFlags_DefaultOpen))
            {
                BBZGUI::CheckboxFlags("BBZGUITableFlags_SortMulti", &flags, BBZGUITableFlags_SortMulti);
                BBZGUI::SameLine(); HelpMarker("When sorting is enabled: hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).");
                BBZGUI::CheckboxFlags("BBZGUITableFlags_SortTristate", &flags, BBZGUITableFlags_SortTristate);
                BBZGUI::SameLine(); HelpMarker("When sorting is enabled: allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).");
                BBZGUI::TreePop();
            }

            if (BBZGUI::TreeNodeEx("Headers:", BBZGUITreeNodeFlags_DefaultOpen))
            {
                BBZGUI::Checkbox("show_headers", &show_headers);
                BBZGUI::CheckboxFlags("BBZGUITableFlags_HighlightHoveredColumn", &flags, BBZGUITableFlags_HighlightHoveredColumn);
                BBZGUI::CheckboxFlags("BBZGUITableColumnFlags_AngledHeader", &columns_base_flags, BBZGUITableColumnFlags_AngledHeader);
                BBZGUI::SameLine(); HelpMarker("Enable AngledHeader on all columns. Best enabled on selected narrow columns (see \"Angled headers\" section of the demo).");
                BBZGUI::TreePop();
            }

            if (BBZGUI::TreeNodeEx("Other:", BBZGUITreeNodeFlags_DefaultOpen))
            {
                BBZGUI::Checkbox("show_wrapped_text", &show_wrapped_text);

                BBZGUI::DragFloat2("##OuterSize", &outer_size_value.x);
                BBZGUI::SameLine(0.0f, BBZGUI::GetStyle().ItemInnerSpacing.x);
                BBZGUI::Checkbox("outer_size", &outer_size_enabled);
                BBZGUI::SameLine();
                HelpMarker("If scrolling is disabled (ScrollX and ScrollY not set):\n"
                    "- The table is output directly in the parent window.\n"
                    "- OuterSize.x < 0.0f will right-align the table.\n"
                    "- OuterSize.x = 0.0f will narrow fit the table unless there are any Stretch columns.\n"
                    "- OuterSize.y then becomes the minimum size for the table, which will extend vertically if there are more rows (unless NoHostExtendY is set).");

                // From a user point of view we will tend to use 'inner_width' differently depending on whether our table is embedding scrolling.
                // To facilitate toying with this demo we will actually pass 0.0f to the BeginTable() when ScrollX is disabled.
                BBZGUI::DragFloat("inner_width (when ScrollX active)", &inner_width_with_scroll, 1.0f, 0.0f, FLT_MAX);

                BBZGUI::DragFloat("row_min_height", &row_min_height, 1.0f, 0.0f, FLT_MAX);
                BBZGUI::SameLine(); HelpMarker("Specify height of the Selectable item.");

                BBZGUI::DragInt("items_count", &items_count, 0.1f, 0, 9999);
                BBZGUI::Combo("items_type (first column)", &contents_type, contents_type_names, IM_ARRAYSIZE(contents_type_names));
                //filter.Draw("filter");
                BBZGUI::TreePop();
            }

            BBZGUI::PopItemWidth();
            PopStyleCompact();
            BBZGUI::Spacing();
            BBZGUI::TreePop();
        }

        // Update item list if we changed the number of items
        static ImVector<MyItem> items;
        static ImVector<int> selection;
        static bool items_need_sort = false;
        if (items.Size != items_count)
        {
            items.resize(items_count, MyItem());
            for (int n = 0; n < items_count; n++)
            {
                const int template_n = n % IM_ARRAYSIZE(template_items_names);
                MyItem& item = items[n];
                item.ID = n;
                item.Name = template_items_names[template_n];
                item.Quantity = (template_n == 3) ? 10 : (template_n == 4) ? 20 : 0; // Assign default quantities
            }
        }

        const ImDrawList* parent_draw_list = BBZGUI::GetWindowDrawList();
        const int parent_draw_list_draw_cmd_count = parent_draw_list->CmdBuffer.Size;
        ImVec2 table_scroll_cur, table_scroll_max; // For debug display
        const ImDrawList* table_draw_list = NULL;  // "

        // Submit table
        const float inner_width_to_use = (flags & BBZGUITableFlags_ScrollX) ? inner_width_with_scroll : 0.0f;
        if (BBZGUI::BeginTable("table_advanced", 6, flags, outer_size_enabled ? outer_size_value : ImVec2(0, 0), inner_width_to_use))
        {
            // Declare columns
            // We use the "user_id" parameter of TableSetupColumn() to specify a user id that will be stored in the sort specifications.
            // This is so our sort function can identify a column given our own identifier. We could also identify them based on their index!
            BBZGUI::TableSetupColumn("ID",           columns_base_flags | BBZGUITableColumnFlags_DefaultSort | BBZGUITableColumnFlags_WidthFixed | BBZGUITableColumnFlags_NoHide, 0.0f, MyItemColumnID_ID);
            BBZGUI::TableSetupColumn("Name",         columns_base_flags | BBZGUITableColumnFlags_WidthFixed, 0.0f, MyItemColumnID_Name);
            BBZGUI::TableSetupColumn("Action",       columns_base_flags | BBZGUITableColumnFlags_NoSort | BBZGUITableColumnFlags_WidthFixed, 0.0f, MyItemColumnID_Action);
            BBZGUI::TableSetupColumn("Quantity",     columns_base_flags | BBZGUITableColumnFlags_PreferSortDescending, 0.0f, MyItemColumnID_Quantity);
            BBZGUI::TableSetupColumn("Description",  columns_base_flags | ((flags & BBZGUITableFlags_NoHostExtendX) ? 0 : BBZGUITableColumnFlags_WidthStretch), 0.0f, MyItemColumnID_Description);
            BBZGUI::TableSetupColumn("Hidden",       columns_base_flags |  BBZGUITableColumnFlags_DefaultHide | BBZGUITableColumnFlags_NoSort);
            BBZGUI::TableSetupScrollFreeze(freeze_cols, freeze_rows);

            // Sort our data if sort specs have been changed!
            BBZGUITableSortSpecs* sort_specs = BBZGUI::TableGetSortSpecs();
            if (sort_specs && sort_specs->SpecsDirty)
                items_need_sort = true;
            if (sort_specs && items_need_sort && items.Size > 1)
            {
                MyItem::SortWithSortSpecs(sort_specs, items.Data, items.Size);
                sort_specs->SpecsDirty = false;
            }
            items_need_sort = false;

            // Take note of whether we are currently sorting based on the Quantity field,
            // we will use this to trigger sorting when we know the data of this column has been modified.
            const bool sorts_specs_using_quantity = (BBZGUI::TableGetColumnFlags(3) & BBZGUITableColumnFlags_IsSorted) != 0;

            // Show headers
            if (show_headers && (columns_base_flags & BBZGUITableColumnFlags_AngledHeader) != 0)
                BBZGUI::TableAngledHeadersRow();
            if (show_headers)
                BBZGUI::TableHeadersRow();

            // Show data
            // FIXME-TABLE FIXME-NAV: How we can get decent up/down even though we have the buttons here?
#if 1
            // Demonstrate using clipper for large vertical lists
            BBZGUIListClipper clipper;
            clipper.Begin(items.Size);
            while (clipper.Step())
            {
                for (int row_n = clipper.DisplayStart; row_n < clipper.DisplayEnd; row_n++)
#else
            // Without clipper
            {
                for (int row_n = 0; row_n < items.Size; row_n++)
#endif
                {
                    MyItem* item = &items[row_n];
                    //if (!filter.PassFilter(item->Name))
                    //    continue;

                    const bool item_is_selected = selection.contains(item->ID);
                    BBZGUI::PushID(item->ID);
                    BBZGUI::TableNextRow(BBZGUITableRowFlags_None, row_min_height);

                    // For the demo purpose we can select among different type of items submitted in the first column
                    BBZGUI::TableSetColumnIndex(0);
                    char label[32];
                    sprintf(label, "%04d", item->ID);
                    if (contents_type == CT_Text)
                        BBZGUI::TextUnformatted(label);
                    else if (contents_type == CT_Button)
                        BBZGUI::Button(label);
                    else if (contents_type == CT_SmallButton)
                        BBZGUI::SmallButton(label);
                    else if (contents_type == CT_FillButton)
                        BBZGUI::Button(label, ImVec2(-FLT_MIN, 0.0f));
                    else if (contents_type == CT_Selectable || contents_type == CT_SelectableSpanRow)
                    {
                        BBZGUISelectableFlags selectable_flags = (contents_type == CT_SelectableSpanRow) ? BBZGUISelectableFlags_SpanAllColumns | BBZGUISelectableFlags_AllowOverlap : BBZGUISelectableFlags_None;
                        if (BBZGUI::Selectable(label, item_is_selected, selectable_flags, ImVec2(0, row_min_height)))
                        {
                            if (BBZGUI::GetIO().KeyCtrl)
                            {
                                if (item_is_selected)
                                    selection.find_erase_unsorted(item->ID);
                                else
                                    selection.push_back(item->ID);
                            }
                            else
                            {
                                selection.clear();
                                selection.push_back(item->ID);
                            }
                        }
                    }

                    if (BBZGUI::TableSetColumnIndex(1))
                        BBZGUI::TextUnformatted(item->Name);

                    // Here we demonstrate marking our data set as needing to be sorted again if we modified a quantity,
                    // and we are currently sorting on the column showing the Quantity.
                    // To avoid triggering a sort while holding the button, we only trigger it when the button has been released.
                    // You will probably need some extra logic if you want to automatically sort when a specific entry changes.
                    if (BBZGUI::TableSetColumnIndex(2))
                    {
                        if (BBZGUI::SmallButton("Chop")) { item->Quantity += 1; }
                        if (sorts_specs_using_quantity && BBZGUI::IsItemDeactivated()) { items_need_sort = true; }
                        BBZGUI::SameLine();
                        if (BBZGUI::SmallButton("Eat")) { item->Quantity -= 1; }
                        if (sorts_specs_using_quantity && BBZGUI::IsItemDeactivated()) { items_need_sort = true; }
                    }

                    if (BBZGUI::TableSetColumnIndex(3))
                        BBZGUI::Text("%d", item->Quantity);

                    BBZGUI::TableSetColumnIndex(4);
                    if (show_wrapped_text)
                        BBZGUI::TextWrapped("Lorem ipsum dolor sit amet");
                    else
                        BBZGUI::Text("Lorem ipsum dolor sit amet");

                    if (BBZGUI::TableSetColumnIndex(5))
                        BBZGUI::Text("1234");

                    BBZGUI::PopID();
                }
            }

            // Store some info to display debug details below
            table_scroll_cur = ImVec2(BBZGUI::GetScrollX(), BBZGUI::GetScrollY());
            table_scroll_max = ImVec2(BBZGUI::GetScrollMaxX(), BBZGUI::GetScrollMaxY());
            table_draw_list = BBZGUI::GetWindowDrawList();
            BBZGUI::EndTable();
        }
        static bool show_debug_details = false;
        BBZGUI::Checkbox("Debug details", &show_debug_details);
        if (show_debug_details && table_draw_list)
        {
            BBZGUI::SameLine(0.0f, 0.0f);
            const int table_draw_list_draw_cmd_count = table_draw_list->CmdBuffer.Size;
            if (table_draw_list == parent_draw_list)
                BBZGUI::Text(": DrawCmd: +%d (in same window)",
                    table_draw_list_draw_cmd_count - parent_draw_list_draw_cmd_count);
            else
                BBZGUI::Text(": DrawCmd: +%d (in child window), Scroll: (%.f/%.f) (%.f/%.f)",
                    table_draw_list_draw_cmd_count - 1, table_scroll_cur.x, table_scroll_max.x, table_scroll_cur.y, table_scroll_max.y);
        }
        BBZGUI::TreePop();
    }

    BBZGUI::PopID();

    ShowDemoWindowColumns();

    if (disable_indent)
        BBZGUI::PopStyleVar();
}

// Demonstrate old/legacy Columns API!
// [2020: Columns are under-featured and not maintained. Prefer using the more flexible and powerful BeginTable() API!]
static void ShowDemoWindowColumns()
{
    IMGUI_DEMO_MARKER("Columns (legacy API)");
    bool open = BBZGUI::TreeNode("Legacy Columns API");
    BBZGUI::SameLine();
    HelpMarker("Columns() is an old API! Prefer using the more flexible and powerful BeginTable() API!");
    if (!open)
        return;

    // Basic columns
    IMGUI_DEMO_MARKER("Columns (legacy API)/Basic");
    if (BBZGUI::TreeNode("Basic"))
    {
        BBZGUI::Text("Without border:");
        BBZGUI::Columns(3, "mycolumns3", false);  // 3-ways, no border
        BBZGUI::Separator();
        for (int n = 0; n < 14; n++)
        {
            char label[32];
            sprintf(label, "Item %d", n);
            if (BBZGUI::Selectable(label)) {}
            //if (BBZGUI::Button(label, ImVec2(-FLT_MIN,0.0f))) {}
            BBZGUI::NextColumn();
        }
        BBZGUI::Columns(1);
        BBZGUI::Separator();

        BBZGUI::Text("With border:");
        BBZGUI::Columns(4, "mycolumns"); // 4-ways, with border
        BBZGUI::Separator();
        BBZGUI::Text("ID"); BBZGUI::NextColumn();
        BBZGUI::Text("Name"); BBZGUI::NextColumn();
        BBZGUI::Text("Path"); BBZGUI::NextColumn();
        BBZGUI::Text("Hovered"); BBZGUI::NextColumn();
        BBZGUI::Separator();
        const char* names[3] = { "One", "Two", "Three" };
        const char* paths[3] = { "/path/one", "/path/two", "/path/three" };
        static int selected = -1;
        for (int i = 0; i < 3; i++)
        {
            char label[32];
            sprintf(label, "%04d", i);
            if (BBZGUI::Selectable(label, selected == i, BBZGUISelectableFlags_SpanAllColumns))
                selected = i;
            bool hovered = BBZGUI::IsItemHovered();
            BBZGUI::NextColumn();
            BBZGUI::Text(names[i]); BBZGUI::NextColumn();
            BBZGUI::Text(paths[i]); BBZGUI::NextColumn();
            BBZGUI::Text("%d", hovered); BBZGUI::NextColumn();
        }
        BBZGUI::Columns(1);
        BBZGUI::Separator();
        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Columns (legacy API)/Borders");
    if (BBZGUI::TreeNode("Borders"))
    {
        // NB: Future columns API should allow automatic horizontal borders.
        static bool h_borders = true;
        static bool v_borders = true;
        static int columns_count = 4;
        const int lines_count = 3;
        BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 8);
        BBZGUI::DragInt("##columns_count", &columns_count, 0.1f, 2, 10, "%d columns");
        if (columns_count < 2)
            columns_count = 2;
        BBZGUI::SameLine();
        BBZGUI::Checkbox("horizontal", &h_borders);
        BBZGUI::SameLine();
        BBZGUI::Checkbox("vertical", &v_borders);
        BBZGUI::Columns(columns_count, NULL, v_borders);
        for (int i = 0; i < columns_count * lines_count; i++)
        {
            if (h_borders && BBZGUI::GetColumnIndex() == 0)
                BBZGUI::Separator();
            BBZGUI::PushID(i);
            BBZGUI::Text("%c%c%c", 'a' + i, 'a' + i, 'a' + i);
            BBZGUI::Text("Width %.2f", BBZGUI::GetColumnWidth());
            BBZGUI::Text("Avail %.2f", BBZGUI::GetContentRegionAvail().x);
            BBZGUI::Text("Offset %.2f", BBZGUI::GetColumnOffset());
            BBZGUI::Text("Long text that is likely to clip");
            BBZGUI::Button("Button", ImVec2(-FLT_MIN, 0.0f));
            BBZGUI::PopID();
            BBZGUI::NextColumn();
        }
        BBZGUI::Columns(1);
        if (h_borders)
            BBZGUI::Separator();
        BBZGUI::TreePop();
    }

    // Create multiple items in a same cell before switching to next column
    IMGUI_DEMO_MARKER("Columns (legacy API)/Mixed items");
    if (BBZGUI::TreeNode("Mixed items"))
    {
        BBZGUI::Columns(3, "mixed");
        BBZGUI::Separator();

        BBZGUI::Text("Hello");
        BBZGUI::Button("Banana");
        BBZGUI::NextColumn();

        BBZGUI::Text("BBZGUI");
        BBZGUI::Button("Apple");
        static float foo = 1.0f;
        BBZGUI::InputFloat("red", &foo, 0.05f, 0, "%.3f");
        BBZGUI::Text("An extra line here.");
        BBZGUI::NextColumn();

        BBZGUI::Text("Sailor");
        BBZGUI::Button("Corniflower");
        static float bar = 1.0f;
        BBZGUI::InputFloat("blue", &bar, 0.05f, 0, "%.3f");
        BBZGUI::NextColumn();

        if (BBZGUI::CollapsingHeader("Category A")) { BBZGUI::Text("Blah blah blah"); } BBZGUI::NextColumn();
        if (BBZGUI::CollapsingHeader("Category B")) { BBZGUI::Text("Blah blah blah"); } BBZGUI::NextColumn();
        if (BBZGUI::CollapsingHeader("Category C")) { BBZGUI::Text("Blah blah blah"); } BBZGUI::NextColumn();
        BBZGUI::Columns(1);
        BBZGUI::Separator();
        BBZGUI::TreePop();
    }

    // Word wrapping
    IMGUI_DEMO_MARKER("Columns (legacy API)/Word-wrapping");
    if (BBZGUI::TreeNode("Word-wrapping"))
    {
        BBZGUI::Columns(2, "word-wrapping");
        BBZGUI::Separator();
        BBZGUI::TextWrapped("The quick brown fox jumps over the lazy dog.");
        BBZGUI::TextWrapped("Hello Left");
        BBZGUI::NextColumn();
        BBZGUI::TextWrapped("The quick brown fox jumps over the lazy dog.");
        BBZGUI::TextWrapped("Hello Right");
        BBZGUI::Columns(1);
        BBZGUI::Separator();
        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Columns (legacy API)/Horizontal Scrolling");
    if (BBZGUI::TreeNode("Horizontal Scrolling"))
    {
        BBZGUI::SetNextWindowContentSize(ImVec2(1500.0f, 0.0f));
        ImVec2 child_size = ImVec2(0, BBZGUI::GetFontSize() * 20.0f);
        BBZGUI::BeginChild("##ScrollingRegion", child_size, BBZGUIChildFlags_None, BBZGUIWindowFlags_HorizontalScrollbar);
        BBZGUI::Columns(10);

        // Also demonstrate using clipper for large vertical lists
        int ITEMS_COUNT = 2000;
        BBZGUIListClipper clipper;
        clipper.Begin(ITEMS_COUNT);
        while (clipper.Step())
        {
            for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                for (int j = 0; j < 10; j++)
                {
                    BBZGUI::Text("Line %d Column %d...", i, j);
                    BBZGUI::NextColumn();
                }
        }
        BBZGUI::Columns(1);
        BBZGUI::EndChild();
        BBZGUI::TreePop();
    }

    IMGUI_DEMO_MARKER("Columns (legacy API)/Tree");
    if (BBZGUI::TreeNode("Tree"))
    {
        BBZGUI::Columns(2, "tree", true);
        for (int x = 0; x < 3; x++)
        {
            bool open1 = BBZGUI::TreeNode((void*)(intptr_t)x, "Node%d", x);
            BBZGUI::NextColumn();
            BBZGUI::Text("Node contents");
            BBZGUI::NextColumn();
            if (open1)
            {
                for (int y = 0; y < 3; y++)
                {
                    bool open2 = BBZGUI::TreeNode((void*)(intptr_t)y, "Node%d.%d", x, y);
                    BBZGUI::NextColumn();
                    BBZGUI::Text("Node contents");
                    if (open2)
                    {
                        BBZGUI::Text("Even more contents");
                        if (BBZGUI::TreeNode("Tree in column"))
                        {
                            BBZGUI::Text("The quick brown fox jumps over the lazy dog");
                            BBZGUI::TreePop();
                        }
                    }
                    BBZGUI::NextColumn();
                    if (open2)
                        BBZGUI::TreePop();
                }
                BBZGUI::TreePop();
            }
        }
        BBZGUI::Columns(1);
        BBZGUI::TreePop();
    }

    BBZGUI::TreePop();
}

//-----------------------------------------------------------------------------
// [SECTION] ShowDemoWindowInputs()
//-----------------------------------------------------------------------------

static void ShowDemoWindowInputs()
{
    IMGUI_DEMO_MARKER("Inputs & Focus");
    if (BBZGUI::CollapsingHeader("Inputs & Focus"))
    {
        BBZGUIIO& io = BBZGUI::GetIO();

        // Display inputs submitted to BBZGUIIO
        IMGUI_DEMO_MARKER("Inputs & Focus/Inputs");
        BBZGUI::SetNextItemOpen(true, BBZGUICond_Once);
        bool inputs_opened = BBZGUI::TreeNode("Inputs");
        BBZGUI::SameLine();
        HelpMarker(
            "This is a simplified view. See more detailed input state:\n"
            "- in 'Tools->Metrics/Debugger->Inputs'.\n"
            "- in 'Tools->Debug Log->IO'.");
        if (inputs_opened)
        {
            if (BBZGUI::IsMousePosValid())
                BBZGUI::Text("Mouse pos: (%g, %g)", io.MousePos.x, io.MousePos.y);
            else
                BBZGUI::Text("Mouse pos: <INVALID>");
            BBZGUI::Text("Mouse delta: (%g, %g)", io.MouseDelta.x, io.MouseDelta.y);
            BBZGUI::Text("Mouse down:");
            for (int i = 0; i < IM_ARRAYSIZE(io.MouseDown); i++) if (BBZGUI::IsMouseDown(i)) { BBZGUI::SameLine(); BBZGUI::Text("b%d (%.02f secs)", i, io.MouseDownDuration[i]); }
            BBZGUI::Text("Mouse wheel: %.1f", io.MouseWheel);

            // We iterate both legacy native range and named BBZGUIKey ranges. This is a little unusual/odd but this allows
            // displaying the data for old/new backends.
            // User code should never have to go through such hoops!
            // You can generally iterate between BBZGUIKey_NamedKey_BEGIN and BBZGUIKey_NamedKey_END.
            struct funcs { static bool IsLegacyNativeDupe(BBZGUIKey) { return false; } };
            BBZGUIKey start_key = BBZGUIKey_NamedKey_BEGIN;
            BBZGUI::Text("Keys down:");         for (BBZGUIKey key = start_key; key < BBZGUIKey_NamedKey_END; key = (BBZGUIKey)(key + 1)) { if (funcs::IsLegacyNativeDupe(key) || !BBZGUI::IsKeyDown(key)) continue; BBZGUI::SameLine(); BBZGUI::Text((key < BBZGUIKey_NamedKey_BEGIN) ? "\"%s\"" : "\"%s\" %d", BBZGUI::GetKeyName(key), key); }
            BBZGUI::Text("Keys mods: %s%s%s%s", io.KeyCtrl ? "CTRL " : "", io.KeyShift ? "SHIFT " : "", io.KeyAlt ? "ALT " : "", io.KeySuper ? "SUPER " : "");
            BBZGUI::Text("Chars queue:");       for (int i = 0; i < io.InputQueueCharacters.Size; i++) { ImWchar c = io.InputQueueCharacters[i]; BBZGUI::SameLine();  BBZGUI::Text("\'%c\' (0x%04X)", (c > ' ' && c <= 255) ? (char)c : '?', c); } // FIXME: We should convert 'c' to UTF-8 here but the functions are not public.

            BBZGUI::TreePop();
        }

        // Display BBZGUIIO output flags
        IMGUI_DEMO_MARKER("Inputs & Focus/Outputs");
        BBZGUI::SetNextItemOpen(true, BBZGUICond_Once);
        bool outputs_opened = BBZGUI::TreeNode("Outputs");
        BBZGUI::SameLine();
        HelpMarker(
            "The value of io.WantCaptureMouse and io.WantCaptureKeyboard are normally set by Dear BBZGUI "
            "to instruct your application of how to route inputs. Typically, when a value is true, it means "
            "Dear BBZGUI wants the corresponding inputs and we expect the underlying application to ignore them.\n\n"
            "The most typical case is: when hovering a window, Dear BBZGUI set io.WantCaptureMouse to true, "
            "and underlying application should ignore mouse inputs (in practice there are many and more subtle "
            "rules leading to how those flags are set).");
        if (outputs_opened)
        {
            BBZGUI::Text("io.WantCaptureMouse: %d", io.WantCaptureMouse);
            BBZGUI::Text("io.WantCaptureMouseUnlessPopupClose: %d", io.WantCaptureMouseUnlessPopupClose);
            BBZGUI::Text("io.WantCaptureKeyboard: %d", io.WantCaptureKeyboard);
            BBZGUI::Text("io.WantTextInput: %d", io.WantTextInput);
            BBZGUI::Text("io.WantSetMousePos: %d", io.WantSetMousePos);
            BBZGUI::Text("io.NavActive: %d, io.NavVisible: %d", io.NavActive, io.NavVisible);

            IMGUI_DEMO_MARKER("Inputs & Focus/Outputs/WantCapture override");
            if (BBZGUI::TreeNode("WantCapture override"))
            {
                HelpMarker(
                    "Hovering the colored canvas will override io.WantCaptureXXX fields.\n"
                    "Notice how normally (when set to none), the value of io.WantCaptureKeyboard would be false when hovering "
                    "and true when clicking.");
                static int capture_override_mouse = -1;
                static int capture_override_keyboard = -1;
                const char* capture_override_desc[] = { "None", "Set to false", "Set to true" };
                BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 15);
                BBZGUI::SliderInt("SetNextFrameWantCaptureMouse() on hover", &capture_override_mouse, -1, +1, capture_override_desc[capture_override_mouse + 1], BBZGUISliderFlags_AlwaysClamp);
                BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 15);
                BBZGUI::SliderInt("SetNextFrameWantCaptureKeyboard() on hover", &capture_override_keyboard, -1, +1, capture_override_desc[capture_override_keyboard + 1], BBZGUISliderFlags_AlwaysClamp);

                BBZGUI::ColorButton("##panel", ImVec4(0.7f, 0.1f, 0.7f, 1.0f), BBZGUIColorEditFlags_NoTooltip | BBZGUIColorEditFlags_NoDragDrop, ImVec2(128.0f, 96.0f)); // Dummy item
                if (BBZGUI::IsItemHovered() && capture_override_mouse != -1)
                    BBZGUI::SetNextFrameWantCaptureMouse(capture_override_mouse == 1);
                if (BBZGUI::IsItemHovered() && capture_override_keyboard != -1)
                    BBZGUI::SetNextFrameWantCaptureKeyboard(capture_override_keyboard == 1);

                BBZGUI::TreePop();
            }
            BBZGUI::TreePop();
        }

        // Demonstrate using Shortcut() and Routing Policies.
        // The general flow is:
        // - Code interested in a chord (e.g. "Ctrl+A") declares their intent.
        // - Multiple locations may be interested in same chord! Routing helps find a winner.
        // - Every frame, we resolve all claims and assign one owner if the modifiers are matching.
        // - The lower-level function is 'bool SetShortcutRouting()', returns true when caller got the route.
        // - Most of the times, SetShortcutRouting() is not called directly. User mostly calls Shortcut() with routing flags.
        // - If you call Shortcut() WITHOUT any routing option, it uses BBZGUIInputFlags_RouteFocused.
        // TL;DR: Most uses will simply be:
        // - Shortcut(BBZGUIMod_Ctrl | BBZGUIKey_A); // Use BBZGUIInputFlags_RouteFocused policy.
        IMGUI_DEMO_MARKER("Inputs & Focus/Shortcuts");
        if (BBZGUI::TreeNode("Shortcuts"))
        {
            static BBZGUIInputFlags route_options = BBZGUIInputFlags_Repeat;
            static BBZGUIInputFlags route_type = BBZGUIInputFlags_RouteFocused;
            BBZGUI::CheckboxFlags("BBZGUIInputFlags_Repeat", &route_options, BBZGUIInputFlags_Repeat);
            BBZGUI::RadioButton("BBZGUIInputFlags_RouteActive", &route_type, BBZGUIInputFlags_RouteActive);
            BBZGUI::RadioButton("BBZGUIInputFlags_RouteFocused (default)", &route_type, BBZGUIInputFlags_RouteFocused);
            BBZGUI::RadioButton("BBZGUIInputFlags_RouteGlobal", &route_type, BBZGUIInputFlags_RouteGlobal);
            BBZGUI::Indent();
            BBZGUI::BeginDisabled(route_type != BBZGUIInputFlags_RouteGlobal);
            BBZGUI::CheckboxFlags("BBZGUIInputFlags_RouteOverFocused", &route_options, BBZGUIInputFlags_RouteOverFocused);
            BBZGUI::CheckboxFlags("BBZGUIInputFlags_RouteOverActive", &route_options, BBZGUIInputFlags_RouteOverActive);
            BBZGUI::CheckboxFlags("BBZGUIInputFlags_RouteUnlessBgFocused", &route_options, BBZGUIInputFlags_RouteUnlessBgFocused);
            BBZGUI::EndDisabled();
            BBZGUI::Unindent();
            BBZGUI::RadioButton("BBZGUIInputFlags_RouteAlways", &route_type, BBZGUIInputFlags_RouteAlways);
            BBZGUIInputFlags flags = route_type | route_options; // Merged flags
            if (route_type != BBZGUIInputFlags_RouteGlobal)
                flags &= ~(BBZGUIInputFlags_RouteOverFocused | BBZGUIInputFlags_RouteOverActive | BBZGUIInputFlags_RouteUnlessBgFocused);

            BBZGUI::SeparatorText("Using SetNextItemShortcut()");
            BBZGUI::Text("Ctrl+S");
            BBZGUI::SetNextItemShortcut(BBZGUIMod_Ctrl | BBZGUIKey_S, flags | BBZGUIInputFlags_Tooltip);
            BBZGUI::Button("Save");
            BBZGUI::Text("Alt+F");
            BBZGUI::SetNextItemShortcut(BBZGUIMod_Alt | BBZGUIKey_F, flags | BBZGUIInputFlags_Tooltip);
            static float f = 0.5f;
            BBZGUI::SliderFloat("Factor", &f, 0.0f, 1.0f);

            BBZGUI::SeparatorText("Using Shortcut()");
            const float line_height = BBZGUI::GetTextLineHeightWithSpacing();
            const BBZGUIKeyChord key_chord = BBZGUIMod_Ctrl | BBZGUIKey_A;

            BBZGUI::Text("Ctrl+A");
            BBZGUI::Text("IsWindowFocused: %d, Shortcut: %s", BBZGUI::IsWindowFocused(), BBZGUI::Shortcut(key_chord, flags) ? "PRESSED" : "...");

            BBZGUI::PushStyleColor(BBZGUICol_ChildBg, ImVec4(1.0f, 0.0f, 1.0f, 0.1f));

            BBZGUI::BeginChild("WindowA", ImVec2(-FLT_MIN, line_height * 14), true);
            BBZGUI::Text("Press CTRL+A and see who receives it!");
            BBZGUI::Separator();

            // 1: Window polling for CTRL+A
            BBZGUI::Text("(in WindowA)");
            BBZGUI::Text("IsWindowFocused: %d, Shortcut: %s", BBZGUI::IsWindowFocused(), BBZGUI::Shortcut(key_chord, flags) ? "PRESSED" : "...");

            // 2: InputText also polling for CTRL+A: it always uses _RouteFocused internally (gets priority when active)
            // (Commmented because the owner-aware version of Shortcut() is still in BBZGui_internal.h)
            //char str[16] = "Press CTRL+A";
            //BBZGUI::Spacing();
            //BBZGUI::InputText("InputTextB", str, IM_ARRAYSIZE(str), BBZGUIInputTextFlags_ReadOnly);
            //BBZGUIID item_id = BBZGUI::GetItemID();
            //BBZGUI::SameLine(); HelpMarker("Internal widgets always use _RouteFocused");
            //BBZGUI::Text("IsWindowFocused: %d, Shortcut: %s", BBZGUI::IsWindowFocused(), BBZGUI::Shortcut(key_chord, flags, item_id) ? "PRESSED" : "...");

            // 3: Dummy child is not claiming the route: focusing them shouldn't steal route away from WindowA
            BBZGUI::BeginChild("ChildD", ImVec2(-FLT_MIN, line_height * 4), true);
            BBZGUI::Text("(in ChildD: not using same Shortcut)");
            BBZGUI::Text("IsWindowFocused: %d", BBZGUI::IsWindowFocused());
            BBZGUI::EndChild();

            // 4: Child window polling for CTRL+A. It is deeper than WindowA and gets priority when focused.
            BBZGUI::BeginChild("ChildE", ImVec2(-FLT_MIN, line_height * 4), true);
            BBZGUI::Text("(in ChildE: using same Shortcut)");
            BBZGUI::Text("IsWindowFocused: %d, Shortcut: %s", BBZGUI::IsWindowFocused(), BBZGUI::Shortcut(key_chord, flags) ? "PRESSED" : "...");
            BBZGUI::EndChild();

            // 5: In a popup
            if (BBZGUI::Button("Open Popup"))
                BBZGUI::OpenPopup("PopupF");
            if (BBZGUI::BeginPopup("PopupF"))
            {
                BBZGUI::Text("(in PopupF)");
                BBZGUI::Text("IsWindowFocused: %d, Shortcut: %s", BBZGUI::IsWindowFocused(), BBZGUI::Shortcut(key_chord, flags) ? "PRESSED" : "...");
                // (Commmented because the owner-aware version of Shortcut() is still in BBZGui_internal.h)
                //BBZGUI::InputText("InputTextG", str, IM_ARRAYSIZE(str), BBZGUIInputTextFlags_ReadOnly);
                //BBZGUI::Text("IsWindowFocused: %d, Shortcut: %s", BBZGUI::IsWindowFocused(), BBZGUI::Shortcut(key_chord, flags, BBZGUI::GetItemID()) ? "PRESSED" : "...");
                BBZGUI::EndPopup();
            }
            BBZGUI::EndChild();
            BBZGUI::PopStyleColor();

            BBZGUI::TreePop();
        }

        // Display mouse cursors
        IMGUI_DEMO_MARKER("Inputs & Focus/Mouse Cursors");
        if (BBZGUI::TreeNode("Mouse Cursors"))
        {
            const char* mouse_cursors_names[] = { "Arrow", "TextInput", "ResizeAll", "ResizeNS", "ResizeEW", "ResizeNESW", "ResizeNWSE", "Hand", "NotAllowed" };
            IM_ASSERT(IM_ARRAYSIZE(mouse_cursors_names) == BBZGUIMouseCursor_COUNT);

            BBZGUIMouseCursor current = BBZGUI::GetMouseCursor();
            const char* cursor_name = (current >= BBZGUIMouseCursor_Arrow) && (current < BBZGUIMouseCursor_COUNT) ? mouse_cursors_names[current] : "N/A";
            BBZGUI::Text("Current mouse cursor = %d: %s", current, cursor_name);
            BBZGUI::BeginDisabled(true);
            BBZGUI::CheckboxFlags("io.BackendFlags: HasMouseCursors", &io.BackendFlags, BBZGUIBackendFlags_HasMouseCursors);
            BBZGUI::EndDisabled();

            BBZGUI::Text("Hover to see mouse cursors:");
            BBZGUI::SameLine(); HelpMarker(
                "Your application can render a different mouse cursor based on what BBZGUI::GetMouseCursor() returns. "
                "If software cursor rendering (io.MouseDrawCursor) is set BBZGUI will draw the right cursor for you, "
                "otherwise your backend needs to handle it.");
            for (int i = 0; i < BBZGUIMouseCursor_COUNT; i++)
            {
                char label[32];
                sprintf(label, "Mouse cursor %d: %s", i, mouse_cursors_names[i]);
                BBZGUI::Bullet(); BBZGUI::Selectable(label, false);
                if (BBZGUI::IsItemHovered())
                    BBZGUI::SetMouseCursor(i);
            }
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Inputs & Focus/Tabbing");
        if (BBZGUI::TreeNode("Tabbing"))
        {
            BBZGUI::Text("Use TAB/SHIFT+TAB to cycle through keyboard editable fields.");
            static char buf[32] = "hello";
            BBZGUI::InputText("1", buf, IM_ARRAYSIZE(buf));
            BBZGUI::InputText("2", buf, IM_ARRAYSIZE(buf));
            BBZGUI::InputText("3", buf, IM_ARRAYSIZE(buf));
            BBZGUI::PushItemFlag(BBZGUIItemFlags_NoTabStop, true);
            BBZGUI::InputText("4 (tab skip)", buf, IM_ARRAYSIZE(buf));
            BBZGUI::SameLine(); HelpMarker("Item won't be cycled through when using TAB or Shift+Tab.");
            BBZGUI::PopItemFlag();
            BBZGUI::InputText("5", buf, IM_ARRAYSIZE(buf));
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Inputs & Focus/Focus from code");
        if (BBZGUI::TreeNode("Focus from code"))
        {
            bool focus_1 = BBZGUI::Button("Focus on 1"); BBZGUI::SameLine();
            bool focus_2 = BBZGUI::Button("Focus on 2"); BBZGUI::SameLine();
            bool focus_3 = BBZGUI::Button("Focus on 3");
            int has_focus = 0;
            static char buf[128] = "click on a button to set focus";

            if (focus_1) BBZGUI::SetKeyboardFocusHere();
            BBZGUI::InputText("1", buf, IM_ARRAYSIZE(buf));
            if (BBZGUI::IsItemActive()) has_focus = 1;

            if (focus_2) BBZGUI::SetKeyboardFocusHere();
            BBZGUI::InputText("2", buf, IM_ARRAYSIZE(buf));
            if (BBZGUI::IsItemActive()) has_focus = 2;

            BBZGUI::PushItemFlag(BBZGUIItemFlags_NoTabStop, true);
            if (focus_3) BBZGUI::SetKeyboardFocusHere();
            BBZGUI::InputText("3 (tab skip)", buf, IM_ARRAYSIZE(buf));
            if (BBZGUI::IsItemActive()) has_focus = 3;
            BBZGUI::SameLine(); HelpMarker("Item won't be cycled through when using TAB or Shift+Tab.");
            BBZGUI::PopItemFlag();

            if (has_focus)
                BBZGUI::Text("Item with focus: %d", has_focus);
            else
                BBZGUI::Text("Item with focus: <none>");

            // Use >= 0 parameter to SetKeyboardFocusHere() to focus an upcoming item
            static float f3[3] = { 0.0f, 0.0f, 0.0f };
            int focus_ahead = -1;
            if (BBZGUI::Button("Focus on X")) { focus_ahead = 0; } BBZGUI::SameLine();
            if (BBZGUI::Button("Focus on Y")) { focus_ahead = 1; } BBZGUI::SameLine();
            if (BBZGUI::Button("Focus on Z")) { focus_ahead = 2; }
            if (focus_ahead != -1) BBZGUI::SetKeyboardFocusHere(focus_ahead);
            BBZGUI::SliderFloat3("Float3", &f3[0], 0.0f, 1.0f);

            BBZGUI::TextWrapped("NB: Cursor & selection are preserved when refocusing last used item in code.");
            BBZGUI::TreePop();
        }

        IMGUI_DEMO_MARKER("Inputs & Focus/Dragging");
        if (BBZGUI::TreeNode("Dragging"))
        {
            BBZGUI::TextWrapped("You can use BBZGUI::GetMouseDragDelta(0) to query for the dragged amount on any widget.");
            for (int button = 0; button < 3; button++)
            {
                BBZGUI::Text("IsMouseDragging(%d):", button);
                BBZGUI::Text("  w/ default threshold: %d,", BBZGUI::IsMouseDragging(button));
                BBZGUI::Text("  w/ zero threshold: %d,", BBZGUI::IsMouseDragging(button, 0.0f));
                BBZGUI::Text("  w/ large threshold: %d,", BBZGUI::IsMouseDragging(button, 20.0f));
            }

            BBZGUI::Button("Drag Me");
            if (BBZGUI::IsItemActive())
                BBZGUI::GetForegroundDrawList()->AddLine(io.MouseClickedPos[0], io.MousePos, BBZGUI::GetColorU32(BBZGUICol_Button), 4.0f); // Draw a line between the button and the mouse cursor

            // Drag operations gets "unlocked" when the mouse has moved past a certain threshold
            // (the default threshold is stored in io.MouseDragThreshold). You can request a lower or higher
            // threshold using the second parameter of IsMouseDragging() and GetMouseDragDelta().
            ImVec2 value_raw = BBZGUI::GetMouseDragDelta(0, 0.0f);
            ImVec2 value_with_lock_threshold = BBZGUI::GetMouseDragDelta(0);
            ImVec2 mouse_delta = io.MouseDelta;
            BBZGUI::Text("GetMouseDragDelta(0):");
            BBZGUI::Text("  w/ default threshold: (%.1f, %.1f)", value_with_lock_threshold.x, value_with_lock_threshold.y);
            BBZGUI::Text("  w/ zero threshold: (%.1f, %.1f)", value_raw.x, value_raw.y);
            BBZGUI::Text("io.MouseDelta: (%.1f, %.1f)", mouse_delta.x, mouse_delta.y);
            BBZGUI::TreePop();
        }
    }
}

//-----------------------------------------------------------------------------
// [SECTION] About Window / ShowAboutWindow()
// Access from Dear BBZGUI Demo -> Tools -> About
//-----------------------------------------------------------------------------

void BBZGUI::ShowAboutWindow(bool* p_open)
{
    if (!BBZGUI::Begin("About Dear BBZGUI", p_open, BBZGUIWindowFlags_AlwaysAutoResize))
    {
        BBZGUI::End();
        return;
    }
    IMGUI_DEMO_MARKER("Tools/About Dear BBZGUI");
    BBZGUI::Text("Dear BBZGUI %s (%d)", IMGUI_VERSION, IMGUI_VERSION_NUM);

    BBZGUI::TextLinkOpenURL("Homepage", "https://github.com/ocornut/imgui");
    BBZGUI::SameLine();
    BBZGUI::TextLinkOpenURL("FAQ", "https://github.com/ocornut/imgui/blob/master/docs/FAQ.md");
    BBZGUI::SameLine();
    BBZGUI::TextLinkOpenURL("Wiki", "https://github.com/ocornut/imgui/wiki");
    BBZGUI::SameLine();
    BBZGUI::TextLinkOpenURL("Releases", "https://github.com/ocornut/imgui/releases");
    BBZGUI::SameLine();
    BBZGUI::TextLinkOpenURL("Funding", "https://github.com/ocornut/imgui/wiki/Funding");

    BBZGUI::Separator();
    BBZGUI::Text("By Omar Cornut and all Dear BBZGUI contributors.");
    BBZGUI::Text("Dear BBZGUI is licensed under the MIT License, see LICENSE for more information.");
    BBZGUI::Text("If your company uses this, please consider funding the project.");

    static bool show_config_info = false;
    BBZGUI::Checkbox("Config/Build Information", &show_config_info);
    if (show_config_info)
    {
        BBZGUIIO& io = BBZGUI::GetIO();
        BBZGUIStyle& style = BBZGUI::GetStyle();

        bool copy_to_clipboard = BBZGUI::Button("Copy to clipboard");
        ImVec2 child_size = ImVec2(0, BBZGUI::GetTextLineHeightWithSpacing() * 18);
        BBZGUI::BeginChild(BBZGUI::GetID("cfg_infos"), child_size, BBZGUIChildFlags_FrameStyle);
        if (copy_to_clipboard)
        {
            BBZGUI::LogToClipboard();
            BBZGUI::LogText("```\n"); // Back quotes will make text appears without formatting when pasting on GitHub
        }

        BBZGUI::Text("Dear BBZGUI %s (%d)", IMGUI_VERSION, IMGUI_VERSION_NUM);
        BBZGUI::Separator();
        BBZGUI::Text("sizeof(size_t): %d, sizeof(ImDrawIdx): %d, sizeof(ImDrawVert): %d", (int)sizeof(size_t), (int)sizeof(ImDrawIdx), (int)sizeof(ImDrawVert));
        BBZGUI::Text("define: __cplusplus=%d", (int)__cplusplus);
#ifdef IMGUI_DISABLE_OBSOLETE_FUNCTIONS
        BBZGUI::Text("define: IMGUI_DISABLE_OBSOLETE_FUNCTIONS");
#endif
#ifdef IMGUI_DISABLE_WIN32_DEFAULT_CLIPBOARD_FUNCTIONS
        BBZGUI::Text("define: IMGUI_DISABLE_WIN32_DEFAULT_CLIPBOARD_FUNCTIONS");
#endif
#ifdef IMGUI_DISABLE_WIN32_DEFAULT_IME_FUNCTIONS
        BBZGUI::Text("define: IMGUI_DISABLE_WIN32_DEFAULT_IME_FUNCTIONS");
#endif
#ifdef IMGUI_DISABLE_WIN32_FUNCTIONS
        BBZGUI::Text("define: IMGUI_DISABLE_WIN32_FUNCTIONS");
#endif
#ifdef IMGUI_DISABLE_DEFAULT_FORMAT_FUNCTIONS
        BBZGUI::Text("define: IMGUI_DISABLE_DEFAULT_FORMAT_FUNCTIONS");
#endif
#ifdef IMGUI_DISABLE_DEFAULT_MATH_FUNCTIONS
        BBZGUI::Text("define: IMGUI_DISABLE_DEFAULT_MATH_FUNCTIONS");
#endif
#ifdef IMGUI_DISABLE_DEFAULT_FILE_FUNCTIONS
        BBZGUI::Text("define: IMGUI_DISABLE_DEFAULT_FILE_FUNCTIONS");
#endif
#ifdef IMGUI_DISABLE_FILE_FUNCTIONS
        BBZGUI::Text("define: IMGUI_DISABLE_FILE_FUNCTIONS");
#endif
#ifdef IMGUI_DISABLE_DEFAULT_ALLOCATORS
        BBZGUI::Text("define: IMGUI_DISABLE_DEFAULT_ALLOCATORS");
#endif
#ifdef IMGUI_USE_BGRA_PACKED_COLOR
        BBZGUI::Text("define: IMGUI_USE_BGRA_PACKED_COLOR");
#endif
#ifdef _WIN32
        BBZGUI::Text("define: _WIN32");
#endif
#ifdef _WIN64
        BBZGUI::Text("define: _WIN64");
#endif
#ifdef __linux__
        BBZGUI::Text("define: __linux__");
#endif
#ifdef __APPLE__
        BBZGUI::Text("define: __APPLE__");
#endif
#ifdef _MSC_VER
        BBZGUI::Text("define: _MSC_VER=%d", _MSC_VER);
#endif
#ifdef _MSVC_LANG
        BBZGUI::Text("define: _MSVC_LANG=%d", (int)_MSVC_LANG);
#endif
#ifdef __MINGW32__
        BBZGUI::Text("define: __MINGW32__");
#endif
#ifdef __MINGW64__
        BBZGUI::Text("define: __MINGW64__");
#endif
#ifdef __GNUC__
        BBZGUI::Text("define: __GNUC__=%d", (int)__GNUC__);
#endif
#ifdef __clang_version__
        BBZGUI::Text("define: __clang_version__=%s", __clang_version__);
#endif
#ifdef __EMSCRIPTEN__
        BBZGUI::Text("define: __EMSCRIPTEN__");
        BBZGUI::Text("Emscripten: %d.%d.%d", __EMSCRIPTEN_major__, __EMSCRIPTEN_minor__, __EMSCRIPTEN_tiny__);
#endif
        BBZGUI::Separator();
        BBZGUI::Text("io.BackendPlatformName: %s", io.BackendPlatformName ? io.BackendPlatformName : "NULL");
        BBZGUI::Text("io.BackendRendererName: %s", io.BackendRendererName ? io.BackendRendererName : "NULL");
        BBZGUI::Text("io.ConfigFlags: 0x%08X", io.ConfigFlags);
        if (io.ConfigFlags & BBZGUIConfigFlags_NavEnableKeyboard)        BBZGUI::Text(" NavEnableKeyboard");
        if (io.ConfigFlags & BBZGUIConfigFlags_NavEnableGamepad)         BBZGUI::Text(" NavEnableGamepad");
        if (io.ConfigFlags & BBZGUIConfigFlags_NoMouse)                  BBZGUI::Text(" NoMouse");
        if (io.ConfigFlags & BBZGUIConfigFlags_NoMouseCursorChange)      BBZGUI::Text(" NoMouseCursorChange");
        if (io.ConfigFlags & BBZGUIConfigFlags_NoKeyboard)               BBZGUI::Text(" NoKeyboard");
        if (io.MouseDrawCursor)                                         BBZGUI::Text("io.MouseDrawCursor");
        if (io.ConfigMacOSXBehaviors)                                   BBZGUI::Text("io.ConfigMacOSXBehaviors");
        if (io.ConfigNavMoveSetMousePos)                                BBZGUI::Text("io.ConfigNavMoveSetMousePos");
        if (io.ConfigNavCaptureKeyboard)                                BBZGUI::Text("io.ConfigNavCaptureKeyboard");
        if (io.ConfigInputTextCursorBlink)                              BBZGUI::Text("io.ConfigInputTextCursorBlink");
        if (io.ConfigWindowsResizeFromEdges)                            BBZGUI::Text("io.ConfigWindowsResizeFromEdges");
        if (io.ConfigWindowsMoveFromTitleBarOnly)                       BBZGUI::Text("io.ConfigWindowsMoveFromTitleBarOnly");
        if (io.ConfigMemoryCompactTimer >= 0.0f)                        BBZGUI::Text("io.ConfigMemoryCompactTimer = %.1f", io.ConfigMemoryCompactTimer);
        BBZGUI::Text("io.BackendFlags: 0x%08X", io.BackendFlags);
        if (io.BackendFlags & BBZGUIBackendFlags_HasGamepad)             BBZGUI::Text(" HasGamepad");
        if (io.BackendFlags & BBZGUIBackendFlags_HasMouseCursors)        BBZGUI::Text(" HasMouseCursors");
        if (io.BackendFlags & BBZGUIBackendFlags_HasSetMousePos)         BBZGUI::Text(" HasSetMousePos");
        if (io.BackendFlags & BBZGUIBackendFlags_RendererHasVtxOffset)   BBZGUI::Text(" RendererHasVtxOffset");
        BBZGUI::Separator();
        BBZGUI::Text("io.Fonts: %d fonts, Flags: 0x%08X, TexSize: %d,%d", io.Fonts->Fonts.Size, io.Fonts->Flags, io.Fonts->TexWidth, io.Fonts->TexHeight);
        BBZGUI::Text("io.DisplaySize: %.2f,%.2f", io.DisplaySize.x, io.DisplaySize.y);
        BBZGUI::Text("io.DisplayFramebufferScale: %.2f,%.2f", io.DisplayFramebufferScale.x, io.DisplayFramebufferScale.y);
        BBZGUI::Separator();
        BBZGUI::Text("style.WindowPadding: %.2f,%.2f", style.WindowPadding.x, style.WindowPadding.y);
        BBZGUI::Text("style.WindowBorderSize: %.2f", style.WindowBorderSize);
        BBZGUI::Text("style.FramePadding: %.2f,%.2f", style.FramePadding.x, style.FramePadding.y);
        BBZGUI::Text("style.FrameRounding: %.2f", style.FrameRounding);
        BBZGUI::Text("style.FrameBorderSize: %.2f", style.FrameBorderSize);
        BBZGUI::Text("style.ItemSpacing: %.2f,%.2f", style.ItemSpacing.x, style.ItemSpacing.y);
        BBZGUI::Text("style.ItemInnerSpacing: %.2f,%.2f", style.ItemInnerSpacing.x, style.ItemInnerSpacing.y);

        if (copy_to_clipboard)
        {
            BBZGUI::LogText("\n```\n");
            BBZGUI::LogFinish();
        }
        BBZGUI::EndChild();
    }
    BBZGUI::End();
}

//-----------------------------------------------------------------------------
// [SECTION] Style Editor / ShowStyleEditor()
//-----------------------------------------------------------------------------
// - ShowFontSelector()
// - ShowStyleSelector()
// - ShowStyleEditor()
//-----------------------------------------------------------------------------

// Forward declare ShowFontAtlas() which isn't worth putting in public API yet
namespace BBZGUI { IMGUI_API void ShowFontAtlas(ImFontAtlas* atlas); }

// Demo helper function to select among loaded fonts.
// Here we use the regular BeginCombo()/EndCombo() api which is the more flexible one.
void BBZGUI::ShowFontSelector(const char* label)
{
    BBZGUIIO& io = BBZGUI::GetIO();
    ImFont* font_current = BBZGUI::GetFont();
    if (BBZGUI::BeginCombo(label, font_current->GetDebugName()))
    {
        for (ImFont* font : io.Fonts->Fonts)
        {
            BBZGUI::PushID((void*)font);
            if (BBZGUI::Selectable(font->GetDebugName(), font == font_current))
                io.FontDefault = font;
            BBZGUI::PopID();
        }
        BBZGUI::EndCombo();
    }
    BBZGUI::SameLine();
    HelpMarker(
        "- Load additional fonts with io.Fonts->AddFontFromFileTTF().\n"
        "- The font atlas is built when calling io.Fonts->GetTexDataAsXXXX() or io.Fonts->Build().\n"
        "- Read FAQ and docs/FONTS.md for more details.\n"
        "- If you need to add/remove fonts at runtime (e.g. for DPI change), do it before calling NewFrame().");
}

// Demo helper function to select among default colors. See ShowStyleEditor() for more advanced options.
// Here we use the simplified Combo() api that packs items into a single literal string.
// Useful for quick combo boxes where the choices are known locally.
bool BBZGUI::ShowStyleSelector(const char* label)
{
    static int style_idx = -1;
    if (BBZGUI::Combo(label, &style_idx, "Dark\0Light\0Classic\0"))
    {
        switch (style_idx)
        {
        case 0: BBZGUI::StyleColorsDark(); break;
        case 1: BBZGUI::StyleColorsLight(); break;
        case 2: BBZGUI::StyleColorsClassic(); break;
        }
        return true;
    }
    return false;
}

void BBZGUI::ShowStyleEditor(BBZGUIStyle* ref)
{
    IMGUI_DEMO_MARKER("Tools/Style Editor");
    // You can pass in a reference BBZGUIStyle structure to compare to, revert to and save to
    // (without a reference style pointer, we will use one compared locally as a reference)
    BBZGUIStyle& style = BBZGUI::GetStyle();
    static BBZGUIStyle ref_saved_style;

    // Default to using internal storage as reference
    static bool init = true;
    if (init && ref == NULL)
        ref_saved_style = style;
    init = false;
    if (ref == NULL)
        ref = &ref_saved_style;

    BBZGUI::PushItemWidth(BBZGUI::GetWindowWidth() * 0.50f);

    if (BBZGUI::ShowStyleSelector("Colors##Selector"))
        ref_saved_style = style;
    BBZGUI::ShowFontSelector("Fonts##Selector");

    // Simplified Settings (expose floating-pointer border sizes as boolean representing 0.0f or 1.0f)
    if (BBZGUI::SliderFloat("FrameRounding", &style.FrameRounding, 0.0f, 12.0f, "%.0f"))
        style.GrabRounding = style.FrameRounding; // Make GrabRounding always the same value as FrameRounding
    { bool border = (style.WindowBorderSize > 0.0f); if (BBZGUI::Checkbox("WindowBorder", &border)) { style.WindowBorderSize = border ? 1.0f : 0.0f; } }
    BBZGUI::SameLine();
    { bool border = (style.FrameBorderSize > 0.0f);  if (BBZGUI::Checkbox("FrameBorder",  &border)) { style.FrameBorderSize  = border ? 1.0f : 0.0f; } }
    BBZGUI::SameLine();
    { bool border = (style.PopupBorderSize > 0.0f);  if (BBZGUI::Checkbox("PopupBorder",  &border)) { style.PopupBorderSize  = border ? 1.0f : 0.0f; } }

    // Save/Revert button
    if (BBZGUI::Button("Save Ref"))
        *ref = ref_saved_style = style;
    BBZGUI::SameLine();
    if (BBZGUI::Button("Revert Ref"))
        style = *ref;
    BBZGUI::SameLine();
    HelpMarker(
        "Save/Revert in local non-persistent storage. Default Colors definition are not affected. "
        "Use \"Export\" below to save them somewhere.");

    BBZGUI::Separator();

    if (BBZGUI::BeginTabBar("##tabs", BBZGUITabBarFlags_None))
    {
        if (BBZGUI::BeginTabItem("Sizes"))
        {
            BBZGUI::SeparatorText("Main");
            BBZGUI::SliderFloat2("WindowPadding", (float*)&style.WindowPadding, 0.0f, 20.0f, "%.0f");
            BBZGUI::SliderFloat2("FramePadding", (float*)&style.FramePadding, 0.0f, 20.0f, "%.0f");
            BBZGUI::SliderFloat2("ItemSpacing", (float*)&style.ItemSpacing, 0.0f, 20.0f, "%.0f");
            BBZGUI::SliderFloat2("ItemInnerSpacing", (float*)&style.ItemInnerSpacing, 0.0f, 20.0f, "%.0f");
            BBZGUI::SliderFloat2("TouchExtraPadding", (float*)&style.TouchExtraPadding, 0.0f, 10.0f, "%.0f");
            BBZGUI::SliderFloat("IndentSpacing", &style.IndentSpacing, 0.0f, 30.0f, "%.0f");
            BBZGUI::SliderFloat("ScrollbarSize", &style.ScrollbarSize, 1.0f, 20.0f, "%.0f");
            BBZGUI::SliderFloat("GrabMinSize", &style.GrabMinSize, 1.0f, 20.0f, "%.0f");

            BBZGUI::SeparatorText("Borders");
            BBZGUI::SliderFloat("WindowBorderSize", &style.WindowBorderSize, 0.0f, 1.0f, "%.0f");
            BBZGUI::SliderFloat("ChildBorderSize", &style.ChildBorderSize, 0.0f, 1.0f, "%.0f");
            BBZGUI::SliderFloat("PopupBorderSize", &style.PopupBorderSize, 0.0f, 1.0f, "%.0f");
            BBZGUI::SliderFloat("FrameBorderSize", &style.FrameBorderSize, 0.0f, 1.0f, "%.0f");
            BBZGUI::SliderFloat("TabBorderSize", &style.TabBorderSize, 0.0f, 1.0f, "%.0f");
            BBZGUI::SliderFloat("TabBarBorderSize", &style.TabBarBorderSize, 0.0f, 2.0f, "%.0f");
            BBZGUI::SliderFloat("TabBarOverlineSize", &style.TabBarOverlineSize, 0.0f, 2.0f, "%.0f");
            BBZGUI::SameLine(); HelpMarker("Overline is only drawn over the selected tab when BBZGUITabBarFlags_DrawSelectedOverline is set.");

            BBZGUI::SeparatorText("Rounding");
            BBZGUI::SliderFloat("WindowRounding", &style.WindowRounding, 0.0f, 12.0f, "%.0f");
            BBZGUI::SliderFloat("ChildRounding", &style.ChildRounding, 0.0f, 12.0f, "%.0f");
            BBZGUI::SliderFloat("FrameRounding", &style.FrameRounding, 0.0f, 12.0f, "%.0f");
            BBZGUI::SliderFloat("PopupRounding", &style.PopupRounding, 0.0f, 12.0f, "%.0f");
            BBZGUI::SliderFloat("ScrollbarRounding", &style.ScrollbarRounding, 0.0f, 12.0f, "%.0f");
            BBZGUI::SliderFloat("GrabRounding", &style.GrabRounding, 0.0f, 12.0f, "%.0f");
            BBZGUI::SliderFloat("TabRounding", &style.TabRounding, 0.0f, 12.0f, "%.0f");

            BBZGUI::SeparatorText("Tables");
            BBZGUI::SliderFloat2("CellPadding", (float*)&style.CellPadding, 0.0f, 20.0f, "%.0f");
            BBZGUI::SliderAngle("TableAngledHeadersAngle", &style.TableAngledHeadersAngle, -50.0f, +50.0f);
            BBZGUI::SliderFloat2("TableAngledHeadersTextAlign", (float*)&style.TableAngledHeadersTextAlign, 0.0f, 1.0f, "%.2f");

            BBZGUI::SeparatorText("Widgets");
            BBZGUI::SliderFloat2("WindowTitleAlign", (float*)&style.WindowTitleAlign, 0.0f, 1.0f, "%.2f");
            int window_menu_button_position = style.WindowMenuButtonPosition + 1;
            if (BBZGUI::Combo("WindowMenuButtonPosition", (int*)&window_menu_button_position, "None\0Left\0Right\0"))
                style.WindowMenuButtonPosition = (BBZGUIDir)(window_menu_button_position - 1);
            BBZGUI::Combo("ColorButtonPosition", (int*)&style.ColorButtonPosition, "Left\0Right\0");
            BBZGUI::SliderFloat2("ButtonTextAlign", (float*)&style.ButtonTextAlign, 0.0f, 1.0f, "%.2f");
            BBZGUI::SameLine(); HelpMarker("Alignment applies when a button is larger than its text content.");
            BBZGUI::SliderFloat2("SelectableTextAlign", (float*)&style.SelectableTextAlign, 0.0f, 1.0f, "%.2f");
            BBZGUI::SameLine(); HelpMarker("Alignment applies when a selectable is larger than its text content.");
            BBZGUI::SliderFloat("SeparatorTextBorderSize", &style.SeparatorTextBorderSize, 0.0f, 10.0f, "%.0f");
            BBZGUI::SliderFloat2("SeparatorTextAlign", (float*)&style.SeparatorTextAlign, 0.0f, 1.0f, "%.2f");
            BBZGUI::SliderFloat2("SeparatorTextPadding", (float*)&style.SeparatorTextPadding, 0.0f, 40.0f, "%.0f");
            BBZGUI::SliderFloat("LogSliderDeadzone", &style.LogSliderDeadzone, 0.0f, 12.0f, "%.0f");

            BBZGUI::SeparatorText("Tooltips");
            for (int n = 0; n < 2; n++)
                if (BBZGUI::TreeNodeEx(n == 0 ? "HoverFlagsForTooltipMouse" : "HoverFlagsForTooltipNav"))
                {
                    BBZGUIHoveredFlags* p = (n == 0) ? &style.HoverFlagsForTooltipMouse : &style.HoverFlagsForTooltipNav;
                    BBZGUI::CheckboxFlags("BBZGUIHoveredFlags_DelayNone", p, BBZGUIHoveredFlags_DelayNone);
                    BBZGUI::CheckboxFlags("BBZGUIHoveredFlags_DelayShort", p, BBZGUIHoveredFlags_DelayShort);
                    BBZGUI::CheckboxFlags("BBZGUIHoveredFlags_DelayNormal", p, BBZGUIHoveredFlags_DelayNormal);
                    BBZGUI::CheckboxFlags("BBZGUIHoveredFlags_Stationary", p, BBZGUIHoveredFlags_Stationary);
                    BBZGUI::CheckboxFlags("BBZGUIHoveredFlags_NoSharedDelay", p, BBZGUIHoveredFlags_NoSharedDelay);
                    BBZGUI::TreePop();
                }

            BBZGUI::SeparatorText("Misc");
            BBZGUI::SliderFloat2("DisplayWindowPadding", (float*)&style.DisplayWindowPadding, 0.0f, 30.0f, "%.0f"); BBZGUI::SameLine(); HelpMarker("Apply to regular windows: amount which we enforce to keep visible when moving near edges of your screen.");
            BBZGUI::SliderFloat2("DisplaySafeAreaPadding", (float*)&style.DisplaySafeAreaPadding, 0.0f, 30.0f, "%.0f"); BBZGUI::SameLine(); HelpMarker("Apply to every windows, menus, popups, tooltips: amount where we avoid displaying contents. Adjust if you cannot see the edges of your screen (e.g. on a TV where scaling has not been configured).");

            BBZGUI::EndTabItem();
        }

        if (BBZGUI::BeginTabItem("Colors"))
        {
            static int output_dest = 0;
            static bool output_only_modified = true;
            if (BBZGUI::Button("Export"))
            {
                if (output_dest == 0)
                    BBZGUI::LogToClipboard();
                else
                    BBZGUI::LogToTTY();
                BBZGUI::LogText("ImVec4* colors = BBZGUI::GetStyle().Colors;" IM_NEWLINE);
                for (int i = 0; i < BBZGUICol_COUNT; i++)
                {
                    const ImVec4& col = style.Colors[i];
                    const char* name = BBZGUI::GetStyleColorName(i);
                    if (!output_only_modified || memcmp(&col, &ref->Colors[i], sizeof(ImVec4)) != 0)
                        BBZGUI::LogText("colors[BBZGUICol_%s]%*s= ImVec4(%.2ff, %.2ff, %.2ff, %.2ff);" IM_NEWLINE,
                            name, 23 - (int)strlen(name), "", col.x, col.y, col.z, col.w);
                }
                BBZGUI::LogFinish();
            }
            BBZGUI::SameLine(); BBZGUI::SetNextItemWidth(120); BBZGUI::Combo("##output_type", &output_dest, "To Clipboard\0To TTY\0");
            BBZGUI::SameLine(); BBZGUI::Checkbox("Only Modified Colors", &output_only_modified);

            static BBZGUITextFilter filter;
            filter.Draw("Filter colors", BBZGUI::GetFontSize() * 16);

            static BBZGUIColorEditFlags alpha_flags = 0;
            if (BBZGUI::RadioButton("Opaque", alpha_flags == BBZGUIColorEditFlags_None))             { alpha_flags = BBZGUIColorEditFlags_None; } BBZGUI::SameLine();
            if (BBZGUI::RadioButton("Alpha",  alpha_flags == BBZGUIColorEditFlags_AlphaPreview))     { alpha_flags = BBZGUIColorEditFlags_AlphaPreview; } BBZGUI::SameLine();
            if (BBZGUI::RadioButton("Both",   alpha_flags == BBZGUIColorEditFlags_AlphaPreviewHalf)) { alpha_flags = BBZGUIColorEditFlags_AlphaPreviewHalf; } BBZGUI::SameLine();
            HelpMarker(
                "In the color list:\n"
                "Left-click on color square to open color picker,\n"
                "Right-click to open edit options menu.");

            BBZGUI::SetNextWindowSizeConstraints(ImVec2(0.0f, BBZGUI::GetTextLineHeightWithSpacing() * 10), ImVec2(FLT_MAX, FLT_MAX));
            BBZGUI::BeginChild("##colors", ImVec2(0, 0), BBZGUIChildFlags_Borders | BBZGUIChildFlags_NavFlattened, BBZGUIWindowFlags_AlwaysVerticalScrollbar | BBZGUIWindowFlags_AlwaysHorizontalScrollbar);
            BBZGUI::PushItemWidth(BBZGUI::GetFontSize() * -12);
            for (int i = 0; i < BBZGUICol_COUNT; i++)
            {
                const char* name = BBZGUI::GetStyleColorName(i);
                if (!filter.PassFilter(name))
                    continue;
                BBZGUI::PushID(i);
#ifndef IMGUI_DISABLE_DEBUG_TOOLS
                if (BBZGUI::Button("?"))
                    BBZGUI::DebugFlashStyleColor((BBZGUICol)i);
                BBZGUI::SetItemTooltip("Flash given color to identify places where it is used.");
                BBZGUI::SameLine();
#endif
                BBZGUI::ColorEdit4("##color", (float*)&style.Colors[i], BBZGUIColorEditFlags_AlphaBar | alpha_flags);
                if (memcmp(&style.Colors[i], &ref->Colors[i], sizeof(ImVec4)) != 0)
                {
                    // Tips: in a real user application, you may want to merge and use an icon font into the main font,
                    // so instead of "Save"/"Revert" you'd use icons!
                    // Read the FAQ and docs/FONTS.md about using icon fonts. It's really easy and super convenient!
                    BBZGUI::SameLine(0.0f, style.ItemInnerSpacing.x); if (BBZGUI::Button("Save")) { ref->Colors[i] = style.Colors[i]; }
                    BBZGUI::SameLine(0.0f, style.ItemInnerSpacing.x); if (BBZGUI::Button("Revert")) { style.Colors[i] = ref->Colors[i]; }
                }
                BBZGUI::SameLine(0.0f, style.ItemInnerSpacing.x);
                BBZGUI::TextUnformatted(name);
                BBZGUI::PopID();
            }
            BBZGUI::PopItemWidth();
            BBZGUI::EndChild();

            BBZGUI::EndTabItem();
        }

        if (BBZGUI::BeginTabItem("Fonts"))
        {
            BBZGUIIO& io = BBZGUI::GetIO();
            ImFontAtlas* atlas = io.Fonts;
            HelpMarker("Read FAQ and docs/FONTS.md for details on font loading.");
            BBZGUI::ShowFontAtlas(atlas);

            // Post-baking font scaling. Note that this is NOT the nice way of scaling fonts, read below.
            // (we enforce hard clamping manually as by default DragFloat/SliderFloat allows CTRL+Click text to get out of bounds).
            const float MIN_SCALE = 0.3f;
            const float MAX_SCALE = 2.0f;
            HelpMarker(
                "Those are old settings provided for convenience.\n"
                "However, the _correct_ way of scaling your UI is currently to reload your font at the designed size, "
                "rebuild the font atlas, and call style.ScaleAllSizes() on a reference BBZGUIStyle structure.\n"
                "Using those settings here will give you poor quality results.");
            static float window_scale = 1.0f;
            BBZGUI::PushItemWidth(BBZGUI::GetFontSize() * 8);
            if (BBZGUI::DragFloat("window scale", &window_scale, 0.005f, MIN_SCALE, MAX_SCALE, "%.2f", BBZGUISliderFlags_AlwaysClamp)) // Scale only this window
                BBZGUI::SetWindowFontScale(window_scale);
            BBZGUI::DragFloat("global scale", &io.FontGlobalScale, 0.005f, MIN_SCALE, MAX_SCALE, "%.2f", BBZGUISliderFlags_AlwaysClamp); // Scale everything
            BBZGUI::PopItemWidth();

            BBZGUI::EndTabItem();
        }

        if (BBZGUI::BeginTabItem("Rendering"))
        {
            BBZGUI::Checkbox("Anti-aliased lines", &style.AntiAliasedLines);
            BBZGUI::SameLine();
            HelpMarker("When disabling anti-aliasing lines, you'll probably want to disable borders in your style as well.");

            BBZGUI::Checkbox("Anti-aliased lines use texture", &style.AntiAliasedLinesUseTex);
            BBZGUI::SameLine();
            HelpMarker("Faster lines using texture data. Require backend to render with bilinear filtering (not point/nearest filtering).");

            BBZGUI::Checkbox("Anti-aliased fill", &style.AntiAliasedFill);
            BBZGUI::PushItemWidth(BBZGUI::GetFontSize() * 8);
            BBZGUI::DragFloat("Curve Tessellation Tolerance", &style.CurveTessellationTol, 0.02f, 0.10f, 10.0f, "%.2f");
            if (style.CurveTessellationTol < 0.10f) style.CurveTessellationTol = 0.10f;

            // When editing the "Circle Segment Max Error" value, draw a preview of its effect on auto-tessellated circles.
            BBZGUI::DragFloat("Circle Tessellation Max Error", &style.CircleTessellationMaxError , 0.005f, 0.10f, 5.0f, "%.2f", BBZGUISliderFlags_AlwaysClamp);
            const bool show_samples = BBZGUI::IsItemActive();
            if (show_samples)
                BBZGUI::SetNextWindowPos(BBZGUI::GetCursorScreenPos());
            if (show_samples && BBZGUI::BeginTooltip())
            {
                BBZGUI::TextUnformatted("(R = radius, N = approx number of segments)");
                BBZGUI::Spacing();
                ImDrawList* draw_list = BBZGUI::GetWindowDrawList();
                const float min_widget_width = BBZGUI::CalcTextSize("R: MMM\nN: MMM").x;
                for (int n = 0; n < 8; n++)
                {
                    const float RAD_MIN = 5.0f;
                    const float RAD_MAX = 70.0f;
                    const float rad = RAD_MIN + (RAD_MAX - RAD_MIN) * (float)n / (8.0f - 1.0f);

                    BBZGUI::BeginGroup();

                    // N is not always exact here due to how PathArcTo() function work internally
                    BBZGUI::Text("R: %.f\nN: %d", rad, draw_list->_CalcCircleAutoSegmentCount(rad));

                    const float canvas_width = IM_MAX(min_widget_width, rad * 2.0f);
                    const float offset_x     = floorf(canvas_width * 0.5f);
                    const float offset_y     = floorf(RAD_MAX);

                    const ImVec2 p1 = BBZGUI::GetCursorScreenPos();
                    draw_list->AddCircle(ImVec2(p1.x + offset_x, p1.y + offset_y), rad, BBZGUI::GetColorU32(BBZGUICol_Text));
                    BBZGUI::Dummy(ImVec2(canvas_width, RAD_MAX * 2));

                    /*
                    const ImVec2 p2 = BBZGUI::GetCursorScreenPos();
                    draw_list->AddCircleFilled(ImVec2(p2.x + offset_x, p2.y + offset_y), rad, BBZGUI::GetColorU32(BBZGUICol_Text));
                    BBZGUI::Dummy(ImVec2(canvas_width, RAD_MAX * 2));
                    */

                    BBZGUI::EndGroup();
                    BBZGUI::SameLine();
                }
                BBZGUI::EndTooltip();
            }
            BBZGUI::SameLine();
            HelpMarker("When drawing circle primitives with \"num_segments == 0\" tesselation will be calculated automatically.");

            BBZGUI::DragFloat("Global Alpha", &style.Alpha, 0.005f, 0.20f, 1.0f, "%.2f"); // Not exposing zero here so user doesn't "lose" the UI (zero alpha clips all widgets). But application code could have a toggle to switch between zero and non-zero.
            BBZGUI::DragFloat("Disabled Alpha", &style.DisabledAlpha, 0.005f, 0.0f, 1.0f, "%.2f"); BBZGUI::SameLine(); HelpMarker("Additional alpha multiplier for disabled items (multiply over current value of Alpha).");
            BBZGUI::PopItemWidth();

            BBZGUI::EndTabItem();
        }

        BBZGUI::EndTabBar();
    }

    BBZGUI::PopItemWidth();
}

//-----------------------------------------------------------------------------
// [SECTION] User Guide / ShowUserGuide()
//-----------------------------------------------------------------------------

void BBZGUI::ShowUserGuide()
{
    BBZGUIIO& io = BBZGUI::GetIO();
    BBZGUI::BulletText("Double-click on title bar to collapse window.");
    BBZGUI::BulletText(
        "Click and drag on lower corner to resize window\n"
        "(double-click to auto fit window to its contents).");
    BBZGUI::BulletText("CTRL+Click on a slider or drag box to input value as text.");
    BBZGUI::BulletText("TAB/SHIFT+TAB to cycle through keyboard editable fields.");
    BBZGUI::BulletText("CTRL+Tab to select a window.");
    if (io.FontAllowUserScaling)
        BBZGUI::BulletText("CTRL+Mouse Wheel to zoom window contents.");
    BBZGUI::BulletText("While inputing text:\n");
    BBZGUI::Indent();
    BBZGUI::BulletText("CTRL+Left/Right to word jump.");
    BBZGUI::BulletText("CTRL+A or double-click to select all.");
    BBZGUI::BulletText("CTRL+X/C/V to use clipboard cut/copy/paste.");
    BBZGUI::BulletText("CTRL+Z,CTRL+Y to undo/redo.");
    BBZGUI::BulletText("ESCAPE to revert.");
    BBZGUI::Unindent();
    BBZGUI::BulletText("With keyboard navigation enabled:");
    BBZGUI::Indent();
    BBZGUI::BulletText("Arrow keys to navigate.");
    BBZGUI::BulletText("Space to activate a widget.");
    BBZGUI::BulletText("Return to input text into a widget.");
    BBZGUI::BulletText("Escape to deactivate a widget, close popup, exit child window.");
    BBZGUI::BulletText("Alt to jump to the menu layer of a window.");
    BBZGUI::Unindent();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Main Menu Bar / ShowExampleAppMainMenuBar()
//-----------------------------------------------------------------------------
// - ShowExampleAppMainMenuBar()
// - ShowExampleMenuFile()
//-----------------------------------------------------------------------------

// Demonstrate creating a "main" fullscreen menu bar and populating it.
// Note the difference between BeginMainMenuBar() and BeginMenuBar():
// - BeginMenuBar() = menu-bar inside current window (which needs the BBZGUIWindowFlags_MenuBar flag!)
// - BeginMainMenuBar() = helper to create menu-bar-sized window at the top of the main viewport + call BeginMenuBar() into it.
static void ShowExampleAppMainMenuBar()
{
    if (BBZGUI::BeginMainMenuBar())
    {
        if (BBZGUI::BeginMenu("File"))
        {
            ShowExampleMenuFile();
            BBZGUI::EndMenu();
        }
        if (BBZGUI::BeginMenu("Edit"))
        {
            if (BBZGUI::MenuItem("Undo", "CTRL+Z")) {}
            if (BBZGUI::MenuItem("Redo", "CTRL+Y", false, false)) {}  // Disabled item
            BBZGUI::Separator();
            if (BBZGUI::MenuItem("Cut", "CTRL+X")) {}
            if (BBZGUI::MenuItem("Copy", "CTRL+C")) {}
            if (BBZGUI::MenuItem("Paste", "CTRL+V")) {}
            BBZGUI::EndMenu();
        }
        BBZGUI::EndMainMenuBar();
    }
}

// Note that shortcuts are currently provided for display only
// (future version will add explicit flags to BeginMenu() to request processing shortcuts)
static void ShowExampleMenuFile()
{
    IMGUI_DEMO_MARKER("Examples/Menu");
    BBZGUI::MenuItem("(demo menu)", NULL, false, false);
    if (BBZGUI::MenuItem("New")) {}
    if (BBZGUI::MenuItem("Open", "Ctrl+O")) {}
    if (BBZGUI::BeginMenu("Open Recent"))
    {
        BBZGUI::MenuItem("fish_hat.c");
        BBZGUI::MenuItem("fish_hat.inl");
        BBZGUI::MenuItem("fish_hat.h");
        if (BBZGUI::BeginMenu("More.."))
        {
            BBZGUI::MenuItem("Hello");
            BBZGUI::MenuItem("Sailor");
            if (BBZGUI::BeginMenu("Recurse.."))
            {
                ShowExampleMenuFile();
                BBZGUI::EndMenu();
            }
            BBZGUI::EndMenu();
        }
        BBZGUI::EndMenu();
    }
    if (BBZGUI::MenuItem("Save", "Ctrl+S")) {}
    if (BBZGUI::MenuItem("Save As..")) {}

    BBZGUI::Separator();
    IMGUI_DEMO_MARKER("Examples/Menu/Options");
    if (BBZGUI::BeginMenu("Options"))
    {
        static bool enabled = true;
        BBZGUI::MenuItem("Enabled", "", &enabled);
        BBZGUI::BeginChild("child", ImVec2(0, 60), BBZGUIChildFlags_Borders);
        for (int i = 0; i < 10; i++)
            BBZGUI::Text("Scrolling Text %d", i);
        BBZGUI::EndChild();
        static float f = 0.5f;
        static int n = 0;
        BBZGUI::SliderFloat("Value", &f, 0.0f, 1.0f);
        BBZGUI::InputFloat("Input", &f, 0.1f);
        BBZGUI::Combo("Combo", &n, "Yes\0No\0Maybe\0\0");
        BBZGUI::EndMenu();
    }

    IMGUI_DEMO_MARKER("Examples/Menu/Colors");
    if (BBZGUI::BeginMenu("Colors"))
    {
        float sz = BBZGUI::GetTextLineHeight();
        for (int i = 0; i < BBZGUICol_COUNT; i++)
        {
            const char* name = BBZGUI::GetStyleColorName((BBZGUICol)i);
            ImVec2 p = BBZGUI::GetCursorScreenPos();
            BBZGUI::GetWindowDrawList()->AddRectFilled(p, ImVec2(p.x + sz, p.y + sz), BBZGUI::GetColorU32((BBZGUICol)i));
            BBZGUI::Dummy(ImVec2(sz, sz));
            BBZGUI::SameLine();
            BBZGUI::MenuItem(name);
        }
        BBZGUI::EndMenu();
    }

    // Here we demonstrate appending again to the "Options" menu (which we already created above)
    // Of course in this demo it is a little bit silly that this function calls BeginMenu("Options") twice.
    // In a real code-base using it would make senses to use this feature from very different code locations.
    if (BBZGUI::BeginMenu("Options")) // <-- Append!
    {
        IMGUI_DEMO_MARKER("Examples/Menu/Append to an existing menu");
        static bool b = true;
        BBZGUI::Checkbox("SomeOption", &b);
        BBZGUI::EndMenu();
    }

    if (BBZGUI::BeginMenu("Disabled", false)) // Disabled
    {
        IM_ASSERT(0);
    }
    if (BBZGUI::MenuItem("Checked", NULL, true)) {}
    BBZGUI::Separator();
    if (BBZGUI::MenuItem("Quit", "Alt+F4")) {}
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Debug Console / ShowExampleAppConsole()
//-----------------------------------------------------------------------------

// Demonstrate creating a simple console window, with scrolling, filtering, completion and history.
// For the console example, we are using a more C++ like approach of declaring a class to hold both data and functions.
struct ExampleAppConsole
{
    char                  InputBuf[256];
    ImVector<char*>       Items;
    ImVector<const char*> Commands;
    ImVector<char*>       History;
    int                   HistoryPos;    // -1: new line, 0..History.Size-1 browsing history.
    BBZGUITextFilter       Filter;
    bool                  AutoScroll;
    bool                  ScrollToBottom;

    ExampleAppConsole()
    {
        IMGUI_DEMO_MARKER("Examples/Console");
        ClearLog();
        memset(InputBuf, 0, sizeof(InputBuf));
        HistoryPos = -1;

        // "CLASSIFY" is here to provide the test case where "C"+[tab] completes to "CL" and display multiple matches.
        Commands.push_back("HELP");
        Commands.push_back("HISTORY");
        Commands.push_back("CLEAR");
        Commands.push_back("CLASSIFY");
        AutoScroll = true;
        ScrollToBottom = false;
        AddLog("Welcome to Dear BBZGUI!");
    }
    ~ExampleAppConsole()
    {
        ClearLog();
        for (int i = 0; i < History.Size; i++)
            BBZGUI::MemFree(History[i]);
    }

    // Portable helpers
    static int   Stricmp(const char* s1, const char* s2)         { int d; while ((d = toupper(*s2) - toupper(*s1)) == 0 && *s1) { s1++; s2++; } return d; }
    static int   Strnicmp(const char* s1, const char* s2, int n) { int d = 0; while (n > 0 && (d = toupper(*s2) - toupper(*s1)) == 0 && *s1) { s1++; s2++; n--; } return d; }
    static char* Strdup(const char* s)                           { IM_ASSERT(s); size_t len = strlen(s) + 1; void* buf = BBZGUI::MemAlloc(len); IM_ASSERT(buf); return (char*)memcpy(buf, (const void*)s, len); }
    static void  Strtrim(char* s)                                { char* str_end = s + strlen(s); while (str_end > s && str_end[-1] == ' ') str_end--; *str_end = 0; }

    void    ClearLog()
    {
        for (int i = 0; i < Items.Size; i++)
            BBZGUI::MemFree(Items[i]);
        Items.clear();
    }

    void    AddLog(const char* fmt, ...) IM_FMTARGS(2)
    {
        // FIXME-OPT
        char buf[1024];
        va_list args;
        va_start(args, fmt);
        vsnprintf(buf, IM_ARRAYSIZE(buf), fmt, args);
        buf[IM_ARRAYSIZE(buf)-1] = 0;
        va_end(args);
        Items.push_back(Strdup(buf));
    }

    void    Draw(const char* title, bool* p_open)
    {
        BBZGUI::SetNextWindowSize(ImVec2(520, 600), BBZGUICond_FirstUseEver);
        if (!BBZGUI::Begin(title, p_open))
        {
            BBZGUI::End();
            return;
        }

        // As a specific feature guaranteed by the library, after calling Begin() the last Item represent the title bar.
        // So e.g. IsItemHovered() will return true when hovering the title bar.
        // Here we create a context menu only available from the title bar.
        if (BBZGUI::BeginPopupContextItem())
        {
            if (BBZGUI::MenuItem("Close Console"))
                *p_open = false;
            BBZGUI::EndPopup();
        }

        BBZGUI::TextWrapped(
            "This example implements a console with basic coloring, completion (TAB key) and history (Up/Down keys). A more elaborate "
            "implementation may want to store entries along with extra data such as timestamp, emitter, etc.");
        BBZGUI::TextWrapped("Enter 'HELP' for help.");

        // TODO: display items starting from the bottom

        if (BBZGUI::SmallButton("Add Debug Text"))  { AddLog("%d some text", Items.Size); AddLog("some more text"); AddLog("display very important message here!"); }
        BBZGUI::SameLine();
        if (BBZGUI::SmallButton("Add Debug Error")) { AddLog("[error] something went wrong"); }
        BBZGUI::SameLine();
        if (BBZGUI::SmallButton("Clear"))           { ClearLog(); }
        BBZGUI::SameLine();
        bool copy_to_clipboard = BBZGUI::SmallButton("Copy");
        //static float t = 0.0f; if (BBZGUI::GetTime() - t > 0.02f) { t = BBZGUI::GetTime(); AddLog("Spam %f", t); }

        BBZGUI::Separator();

        // Options menu
        if (BBZGUI::BeginPopup("Options"))
        {
            BBZGUI::Checkbox("Auto-scroll", &AutoScroll);
            BBZGUI::EndPopup();
        }

        // Options, Filter
        BBZGUI::SetNextItemShortcut(BBZGUIMod_Ctrl | BBZGUIKey_O, BBZGUIInputFlags_Tooltip);
        if (BBZGUI::Button("Options"))
            BBZGUI::OpenPopup("Options");
        BBZGUI::SameLine();
        Filter.Draw("Filter (\"incl,-excl\") (\"error\")", 180);
        BBZGUI::Separator();

        // Reserve enough left-over height for 1 separator + 1 input text
        const float footer_height_to_reserve = BBZGUI::GetStyle().ItemSpacing.y + BBZGUI::GetFrameHeightWithSpacing();
        if (BBZGUI::BeginChild("ScrollingRegion", ImVec2(0, -footer_height_to_reserve), BBZGUIChildFlags_NavFlattened, BBZGUIWindowFlags_HorizontalScrollbar))
        {
            if (BBZGUI::BeginPopupContextWindow())
            {
                if (BBZGUI::Selectable("Clear")) ClearLog();
                BBZGUI::EndPopup();
            }

            // Display every line as a separate entry so we can change their color or add custom widgets.
            // If you only want raw text you can use BBZGUI::TextUnformatted(log.begin(), log.end());
            // NB- if you have thousands of entries this approach may be too inefficient and may require user-side clipping
            // to only process visible items. The clipper will automatically measure the height of your first item and then
            // "seek" to display only items in the visible area.
            // To use the clipper we can replace your standard loop:
            //      for (int i = 0; i < Items.Size; i++)
            //   With:
            //      BBZGUIListClipper clipper;
            //      clipper.Begin(Items.Size);
            //      while (clipper.Step())
            //         for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
            // - That your items are evenly spaced (same height)
            // - That you have cheap random access to your elements (you can access them given their index,
            //   without processing all the ones before)
            // You cannot this code as-is if a filter is active because it breaks the 'cheap random-access' property.
            // We would need random-access on the post-filtered list.
            // A typical application wanting coarse clipping and filtering may want to pre-compute an array of indices
            // or offsets of items that passed the filtering test, recomputing this array when user changes the filter,
            // and appending newly elements as they are inserted. This is left as a task to the user until we can manage
            // to improve this example code!
            // If your items are of variable height:
            // - Split them into same height items would be simpler and facilitate random-seeking into your list.
            // - Consider using manual call to IsRectVisible() and skipping extraneous decoration from your items.
            BBZGUI::PushStyleVar(BBZGUIStyleVar_ItemSpacing, ImVec2(4, 1)); // Tighten spacing
            if (copy_to_clipboard)
                BBZGUI::LogToClipboard();
            for (const char* item : Items)
            {
                if (!Filter.PassFilter(item))
                    continue;

                // Normally you would store more information in your item than just a string.
                // (e.g. make Items[] an array of structure, store color/type etc.)
                ImVec4 color;
                bool has_color = false;
                if (strstr(item, "[error]")) { color = ImVec4(1.0f, 0.4f, 0.4f, 1.0f); has_color = true; }
                else if (strncmp(item, "# ", 2) == 0) { color = ImVec4(1.0f, 0.8f, 0.6f, 1.0f); has_color = true; }
                if (has_color)
                    BBZGUI::PushStyleColor(BBZGUICol_Text, color);
                BBZGUI::TextUnformatted(item);
                if (has_color)
                    BBZGUI::PopStyleColor();
            }
            if (copy_to_clipboard)
                BBZGUI::LogFinish();

            // Keep up at the bottom of the scroll region if we were already at the bottom at the beginning of the frame.
            // Using a scrollbar or mouse-wheel will take away from the bottom edge.
            if (ScrollToBottom || (AutoScroll && BBZGUI::GetScrollY() >= BBZGUI::GetScrollMaxY()))
                BBZGUI::SetScrollHereY(1.0f);
            ScrollToBottom = false;

            BBZGUI::PopStyleVar();
        }
        BBZGUI::EndChild();
        BBZGUI::Separator();

        // Command-line
        bool reclaim_focus = false;
        BBZGUIInputTextFlags input_text_flags = BBZGUIInputTextFlags_EnterReturnsTrue | BBZGUIInputTextFlags_EscapeClearsAll | BBZGUIInputTextFlags_CallbackCompletion | BBZGUIInputTextFlags_CallbackHistory;
        if (BBZGUI::InputText("Input", InputBuf, IM_ARRAYSIZE(InputBuf), input_text_flags, &TextEditCallbackStub, (void*)this))
        {
            char* s = InputBuf;
            Strtrim(s);
            if (s[0])
                ExecCommand(s);
            strcpy(s, "");
            reclaim_focus = true;
        }

        // Auto-focus on window apparition
        BBZGUI::SetItemDefaultFocus();
        if (reclaim_focus)
            BBZGUI::SetKeyboardFocusHere(-1); // Auto focus previous widget

        BBZGUI::End();
    }

    void    ExecCommand(const char* command_line)
    {
        AddLog("# %s\n", command_line);

        // Insert into history. First find match and delete it so it can be pushed to the back.
        // This isn't trying to be smart or optimal.
        HistoryPos = -1;
        for (int i = History.Size - 1; i >= 0; i--)
            if (Stricmp(History[i], command_line) == 0)
            {
                BBZGUI::MemFree(History[i]);
                History.erase(History.begin() + i);
                break;
            }
        History.push_back(Strdup(command_line));

        // Process command
        if (Stricmp(command_line, "CLEAR") == 0)
        {
            ClearLog();
        }
        else if (Stricmp(command_line, "HELP") == 0)
        {
            AddLog("Commands:");
            for (int i = 0; i < Commands.Size; i++)
                AddLog("- %s", Commands[i]);
        }
        else if (Stricmp(command_line, "HISTORY") == 0)
        {
            int first = History.Size - 10;
            for (int i = first > 0 ? first : 0; i < History.Size; i++)
                AddLog("%3d: %s\n", i, History[i]);
        }
        else
        {
            AddLog("Unknown command: '%s'\n", command_line);
        }

        // On command input, we scroll to bottom even if AutoScroll==false
        ScrollToBottom = true;
    }

    // In C++11 you'd be better off using lambdas for this sort of forwarding callbacks
    static int TextEditCallbackStub(BBZGUIInputTextCallbackData* data)
    {
        ExampleAppConsole* console = (ExampleAppConsole*)data->UserData;
        return console->TextEditCallback(data);
    }

    int     TextEditCallback(BBZGUIInputTextCallbackData* data)
    {
        //AddLog("cursor: %d, selection: %d-%d", data->CursorPos, data->SelectionStart, data->SelectionEnd);
        switch (data->EventFlag)
        {
        case BBZGUIInputTextFlags_CallbackCompletion:
            {
                // Example of TEXT COMPLETION

                // Locate beginning of current word
                const char* word_end = data->Buf + data->CursorPos;
                const char* word_start = word_end;
                while (word_start > data->Buf)
                {
                    const char c = word_start[-1];
                    if (c == ' ' || c == '\t' || c == ',' || c == ';')
                        break;
                    word_start--;
                }

                // Build a list of candidates
                ImVector<const char*> candidates;
                for (int i = 0; i < Commands.Size; i++)
                    if (Strnicmp(Commands[i], word_start, (int)(word_end - word_start)) == 0)
                        candidates.push_back(Commands[i]);

                if (candidates.Size == 0)
                {
                    // No match
                    AddLog("No match for \"%.*s\"!\n", (int)(word_end - word_start), word_start);
                }
                else if (candidates.Size == 1)
                {
                    // Single match. Delete the beginning of the word and replace it entirely so we've got nice casing.
                    data->DeleteChars((int)(word_start - data->Buf), (int)(word_end - word_start));
                    data->InsertChars(data->CursorPos, candidates[0]);
                    data->InsertChars(data->CursorPos, " ");
                }
                else
                {
                    // Multiple matches. Complete as much as we can..
                    // So inputing "C"+Tab will complete to "CL" then display "CLEAR" and "CLASSIFY" as matches.
                    int match_len = (int)(word_end - word_start);
                    for (;;)
                    {
                        int c = 0;
                        bool all_candidates_matches = true;
                        for (int i = 0; i < candidates.Size && all_candidates_matches; i++)
                            if (i == 0)
                                c = toupper(candidates[i][match_len]);
                            else if (c == 0 || c != toupper(candidates[i][match_len]))
                                all_candidates_matches = false;
                        if (!all_candidates_matches)
                            break;
                        match_len++;
                    }

                    if (match_len > 0)
                    {
                        data->DeleteChars((int)(word_start - data->Buf), (int)(word_end - word_start));
                        data->InsertChars(data->CursorPos, candidates[0], candidates[0] + match_len);
                    }

                    // List matches
                    AddLog("Possible matches:\n");
                    for (int i = 0; i < candidates.Size; i++)
                        AddLog("- %s\n", candidates[i]);
                }

                break;
            }
        case BBZGUIInputTextFlags_CallbackHistory:
            {
                // Example of HISTORY
                const int prev_history_pos = HistoryPos;
                if (data->EventKey == BBZGUIKey_UpArrow)
                {
                    if (HistoryPos == -1)
                        HistoryPos = History.Size - 1;
                    else if (HistoryPos > 0)
                        HistoryPos--;
                }
                else if (data->EventKey == BBZGUIKey_DownArrow)
                {
                    if (HistoryPos != -1)
                        if (++HistoryPos >= History.Size)
                            HistoryPos = -1;
                }

                // A better implementation would preserve the data on the current input line along with cursor position.
                if (prev_history_pos != HistoryPos)
                {
                    const char* history_str = (HistoryPos >= 0) ? History[HistoryPos] : "";
                    data->DeleteChars(0, data->BufTextLen);
                    data->InsertChars(0, history_str);
                }
            }
        }
        return 0;
    }
};

static void ShowExampleAppConsole(bool* p_open)
{
    static ExampleAppConsole console;
    console.Draw("Example: Console", p_open);
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Debug Log / ShowExampleAppLog()
//-----------------------------------------------------------------------------

// Usage:
//  static ExampleAppLog my_log;
//  my_log.AddLog("Hello %d world\n", 123);
//  my_log.Draw("title");
struct ExampleAppLog
{
    BBZGUITextBuffer     Buf;
    BBZGUITextFilter     Filter;
    ImVector<int>       LineOffsets; // Index to lines offset. We maintain this with AddLog() calls.
    bool                AutoScroll;  // Keep scrolling if already at the bottom.

    ExampleAppLog()
    {
        AutoScroll = true;
        Clear();
    }

    void    Clear()
    {
        Buf.clear();
        LineOffsets.clear();
        LineOffsets.push_back(0);
    }

    void    AddLog(const char* fmt, ...) IM_FMTARGS(2)
    {
        int old_size = Buf.size();
        va_list args;
        va_start(args, fmt);
        Buf.appendfv(fmt, args);
        va_end(args);
        for (int new_size = Buf.size(); old_size < new_size; old_size++)
            if (Buf[old_size] == '\n')
                LineOffsets.push_back(old_size + 1);
    }

    void    Draw(const char* title, bool* p_open = NULL)
    {
        if (!BBZGUI::Begin(title, p_open))
        {
            BBZGUI::End();
            return;
        }

        // Options menu
        if (BBZGUI::BeginPopup("Options"))
        {
            BBZGUI::Checkbox("Auto-scroll", &AutoScroll);
            BBZGUI::EndPopup();
        }

        // Main window
        if (BBZGUI::Button("Options"))
            BBZGUI::OpenPopup("Options");
        BBZGUI::SameLine();
        bool clear = BBZGUI::Button("Clear");
        BBZGUI::SameLine();
        bool copy = BBZGUI::Button("Copy");
        BBZGUI::SameLine();
        Filter.Draw("Filter", -100.0f);

        BBZGUI::Separator();

        if (BBZGUI::BeginChild("scrolling", ImVec2(0, 0), BBZGUIChildFlags_None, BBZGUIWindowFlags_HorizontalScrollbar))
        {
            if (clear)
                Clear();
            if (copy)
                BBZGUI::LogToClipboard();

            BBZGUI::PushStyleVar(BBZGUIStyleVar_ItemSpacing, ImVec2(0, 0));
            const char* buf = Buf.begin();
            const char* buf_end = Buf.end();
            if (Filter.IsActive())
            {
                // In this example we don't use the clipper when Filter is enabled.
                // This is because we don't have random access to the result of our filter.
                // A real application processing logs with ten of thousands of entries may want to store the result of
                // search/filter.. especially if the filtering function is not trivial (e.g. reg-exp).
                for (int line_no = 0; line_no < LineOffsets.Size; line_no++)
                {
                    const char* line_start = buf + LineOffsets[line_no];
                    const char* line_end = (line_no + 1 < LineOffsets.Size) ? (buf + LineOffsets[line_no + 1] - 1) : buf_end;
                    if (Filter.PassFilter(line_start, line_end))
                        BBZGUI::TextUnformatted(line_start, line_end);
                }
            }
            else
            {
                // The simplest and easy way to display the entire buffer:
                //   BBZGUI::TextUnformatted(buf_begin, buf_end);
                // And it'll just work. TextUnformatted() has specialization for large blob of text and will fast-forward
                // to skip non-visible lines. Here we instead demonstrate using the clipper to only process lines that are
                // within the visible area.
                // If you have tens of thousands of items and their processing cost is non-negligible, coarse clipping them
                // on your side is recommended. Using BBZGUIListClipper requires
                // - A) random access into your data
                // - B) items all being the  same height,
                // both of which we can handle since we have an array pointing to the beginning of each line of text.
                // When using the filter (in the block of code above) we don't have random access into the data to display
                // anymore, which is why we don't use the clipper. Storing or skimming through the search result would make
                // it possible (and would be recommended if you want to search through tens of thousands of entries).
                BBZGUIListClipper clipper;
                clipper.Begin(LineOffsets.Size);
                while (clipper.Step())
                {
                    for (int line_no = clipper.DisplayStart; line_no < clipper.DisplayEnd; line_no++)
                    {
                        const char* line_start = buf + LineOffsets[line_no];
                        const char* line_end = (line_no + 1 < LineOffsets.Size) ? (buf + LineOffsets[line_no + 1] - 1) : buf_end;
                        BBZGUI::TextUnformatted(line_start, line_end);
                    }
                }
                clipper.End();
            }
            BBZGUI::PopStyleVar();

            // Keep up at the bottom of the scroll region if we were already at the bottom at the beginning of the frame.
            // Using a scrollbar or mouse-wheel will take away from the bottom edge.
            if (AutoScroll && BBZGUI::GetScrollY() >= BBZGUI::GetScrollMaxY())
                BBZGUI::SetScrollHereY(1.0f);
        }
        BBZGUI::EndChild();
        BBZGUI::End();
    }
};

// Demonstrate creating a simple log window with basic filtering.
static void ShowExampleAppLog(bool* p_open)
{
    static ExampleAppLog log;

    // For the demo: add a debug button _BEFORE_ the normal log window contents
    // We take advantage of a rarely used feature: multiple calls to Begin()/End() are appending to the _same_ window.
    // Most of the contents of the window will be added by the log.Draw() call.
    BBZGUI::SetNextWindowSize(ImVec2(500, 400), BBZGUICond_FirstUseEver);
    BBZGUI::Begin("Example: Log", p_open);
    IMGUI_DEMO_MARKER("Examples/Log");
    if (BBZGUI::SmallButton("[Debug] Add 5 entries"))
    {
        static int counter = 0;
        const char* categories[3] = { "info", "warn", "error" };
        const char* words[] = { "Bumfuzzled", "Cattywampus", "Snickersnee", "Abibliophobia", "Absquatulate", "Nincompoop", "Pauciloquent" };
        for (int n = 0; n < 5; n++)
        {
            const char* category = categories[counter % IM_ARRAYSIZE(categories)];
            const char* word = words[counter % IM_ARRAYSIZE(words)];
            log.AddLog("[%05d] [%s] Hello, current time is %.1f, here's a word: '%s'\n",
                BBZGUI::GetFrameCount(), category, BBZGUI::GetTime(), word);
            counter++;
        }
    }
    BBZGUI::End();

    // Actually call in the regular Log helper (which will Begin() into the same window as we just did)
    log.Draw("Example: Log", p_open);
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Simple Layout / ShowExampleAppLayout()
//-----------------------------------------------------------------------------

// Demonstrate create a window with multiple child windows.
static void ShowExampleAppLayout(bool* p_open)
{
    BBZGUI::SetNextWindowSize(ImVec2(500, 440), BBZGUICond_FirstUseEver);
    if (BBZGUI::Begin("Example: Simple layout", p_open, BBZGUIWindowFlags_MenuBar))
    {
        IMGUI_DEMO_MARKER("Examples/Simple layout");
        if (BBZGUI::BeginMenuBar())
        {
            if (BBZGUI::BeginMenu("File"))
            {
                if (BBZGUI::MenuItem("Close", "Ctrl+W")) { *p_open = false; }
                BBZGUI::EndMenu();
            }
            BBZGUI::EndMenuBar();
        }

        // Left
        static int selected = 0;
        {
            BBZGUI::BeginChild("left pane", ImVec2(150, 0), BBZGUIChildFlags_Borders | BBZGUIChildFlags_ResizeX);
            for (int i = 0; i < 100; i++)
            {
                // FIXME: Good candidate to use BBZGUISelectableFlags_SelectOnNav
                char label[128];
                sprintf(label, "MyObject %d", i);
                if (BBZGUI::Selectable(label, selected == i))
                    selected = i;
            }
            BBZGUI::EndChild();
        }
        BBZGUI::SameLine();

        // Right
        {
            BBZGUI::BeginGroup();
            BBZGUI::BeginChild("item view", ImVec2(0, -BBZGUI::GetFrameHeightWithSpacing())); // Leave room for 1 line below us
            BBZGUI::Text("MyObject: %d", selected);
            BBZGUI::Separator();
            if (BBZGUI::BeginTabBar("##Tabs", BBZGUITabBarFlags_None))
            {
                if (BBZGUI::BeginTabItem("Description"))
                {
                    BBZGUI::TextWrapped("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ");
                    BBZGUI::EndTabItem();
                }
                if (BBZGUI::BeginTabItem("Details"))
                {
                    BBZGUI::Text("ID: 0123456789");
                    BBZGUI::EndTabItem();
                }
                BBZGUI::EndTabBar();
            }
            BBZGUI::EndChild();
            if (BBZGUI::Button("Revert")) {}
            BBZGUI::SameLine();
            if (BBZGUI::Button("Save")) {}
            BBZGUI::EndGroup();
        }
    }
    BBZGUI::End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Property Editor / ShowExampleAppPropertyEditor()
//-----------------------------------------------------------------------------
// Some of the interactions are a bit lack-luster:
// - We would want pressing validating or leaving the filter to somehow restore focus.
// - We may want more advanced filtering (child nodes) and clipper support: both will need extra work.
// - We would want to customize some keyboard interactions to easily keyboard navigate between the tree and the properties.
//-----------------------------------------------------------------------------

struct ExampleAppPropertyEditor
{
    BBZGUITextFilter     Filter;
    ExampleTreeNode*    VisibleNode = NULL;

    void Draw(ExampleTreeNode* root_node)
    {
        // Left side: draw tree
        // - Currently using a table to benefit from RowBg feature
        if (BBZGUI::BeginChild("##tree", ImVec2(300, 0), BBZGUIChildFlags_ResizeX | BBZGUIChildFlags_Borders | BBZGUIChildFlags_NavFlattened))
        {
            BBZGUI::SetNextItemWidth(-FLT_MIN);
            BBZGUI::SetNextItemShortcut(BBZGUIMod_Ctrl | BBZGUIKey_F, BBZGUIInputFlags_Tooltip);
            BBZGUI::PushItemFlag(BBZGUIItemFlags_NoNavDefaultFocus, true);
            if (BBZGUI::InputTextWithHint("##Filter", "incl,-excl", Filter.InputBuf, IM_ARRAYSIZE(Filter.InputBuf), BBZGUIInputTextFlags_EscapeClearsAll))
                Filter.Build();
            BBZGUI::PopItemFlag();

            if (BBZGUI::BeginTable("##bg", 1, BBZGUITableFlags_RowBg))
            {
                for (ExampleTreeNode* node : root_node->Childs)
                    if (Filter.PassFilter(node->Name)) // Filter root node
                        DrawTreeNode(node);
                BBZGUI::EndTable();
            }
        }
        BBZGUI::EndChild();

        // Right side: draw properties
        BBZGUI::SameLine();

        BBZGUI::BeginGroup(); // Lock X position
        if (ExampleTreeNode* node = VisibleNode)
        {
            BBZGUI::Text("%s", node->Name);
            BBZGUI::TextDisabled("UID: 0x%08X", node->UID);
            BBZGUI::Separator();
            if (BBZGUI::BeginTable("##properties", 2, BBZGUITableFlags_Resizable | BBZGUITableFlags_ScrollY))
            {
                BBZGUI::TableSetupColumn("", BBZGUITableColumnFlags_WidthFixed);
                BBZGUI::TableSetupColumn("", BBZGUITableColumnFlags_WidthStretch, 2.0f); // Default twice larger
                if (node->HasData)
                {
                    // In a typical application, the structure description would be derived from a data-driven system.
                    // - We try to mimic this with our ExampleMemberInfo structure and the ExampleTreeNodeMemberInfos[] array.
                    // - Limits and some details are hard-coded to simplify the demo.
                    for (const ExampleMemberInfo& field_desc : ExampleTreeNodeMemberInfos)
                    {
                        BBZGUI::TableNextRow();
                        BBZGUI::PushID(field_desc.Name);
                        BBZGUI::TableNextColumn();
                        BBZGUI::AlignTextToFramePadding();
                        BBZGUI::TextUnformatted(field_desc.Name);
                        BBZGUI::TableNextColumn();
                        void* field_ptr = (void*)(((unsigned char*)node) + field_desc.Offset);
                        switch (field_desc.DataType)
                        {
                        case BBZGUIDataType_Bool:
                        {
                            IM_ASSERT(field_desc.DataCount == 1);
                            BBZGUI::Checkbox("##Editor", (bool*)field_ptr);
                            break;
                        }
                        case BBZGUIDataType_S32:
                        {
                            int v_min = INT_MIN, v_max = INT_MAX;
                            BBZGUI::SetNextItemWidth(-FLT_MIN);
                            BBZGUI::DragScalarN("##Editor", field_desc.DataType, field_ptr, field_desc.DataCount, 1.0f, &v_min, &v_max);
                            break;
                        }
                        case BBZGUIDataType_Float:
                        {
                            float v_min = 0.0f, v_max = 1.0f;
                            BBZGUI::SetNextItemWidth(-FLT_MIN);
                            BBZGUI::SliderScalarN("##Editor", field_desc.DataType, field_ptr, field_desc.DataCount, &v_min, &v_max);
                            break;
                        }
                        }
                        BBZGUI::PopID();
                    }
                }
                BBZGUI::EndTable();
            }
        }
        BBZGUI::EndGroup();
    }

    void DrawTreeNode(ExampleTreeNode* node)
    {
        BBZGUI::TableNextRow();
        BBZGUI::TableNextColumn();
        BBZGUI::PushID(node->UID);
        BBZGUITreeNodeFlags tree_flags = BBZGUITreeNodeFlags_None;
        tree_flags |= BBZGUITreeNodeFlags_OpenOnArrow | BBZGUITreeNodeFlags_OpenOnDoubleClick;    // Standard opening mode as we are likely to want to add selection afterwards
        tree_flags |= BBZGUITreeNodeFlags_NavLeftJumpsBackHere;                                  // Left arrow support
        if (node == VisibleNode)
            tree_flags |= BBZGUITreeNodeFlags_Selected;
        if (node->Childs.Size == 0)
            tree_flags |= BBZGUITreeNodeFlags_Leaf | BBZGUITreeNodeFlags_Bullet;
        if (node->DataMyBool == false)
            BBZGUI::PushStyleColor(BBZGUICol_Text, BBZGUI::GetStyle().Colors[BBZGUICol_TextDisabled]);
        bool node_open = BBZGUI::TreeNodeEx("", tree_flags, "%s", node->Name);
        if (node->DataMyBool == false)
            BBZGUI::PopStyleColor();
        if (BBZGUI::IsItemFocused())
            VisibleNode = node;
        if (node_open)
        {
            for (ExampleTreeNode* child : node->Childs)
                DrawTreeNode(child);
            BBZGUI::TreePop();
        }
        BBZGUI::PopID();
    }
};

// Demonstrate creating a simple property editor.
static void ShowExampleAppPropertyEditor(bool* p_open, BBZGUIDemoWindowData* demo_data)
{
    BBZGUI::SetNextWindowSize(ImVec2(430, 450), BBZGUICond_FirstUseEver);
    if (!BBZGUI::Begin("Example: Property editor", p_open))
    {
        BBZGUI::End();
        return;
    }

    IMGUI_DEMO_MARKER("Examples/Property Editor");
    static ExampleAppPropertyEditor property_editor;
    if (demo_data->DemoTree == NULL)
        demo_data->DemoTree = ExampleTree_CreateDemoTree();
    property_editor.Draw(demo_data->DemoTree);

    BBZGUI::End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Long Text / ShowExampleAppLongText()
//-----------------------------------------------------------------------------

// Demonstrate/test rendering huge amount of text, and the incidence of clipping.
static void ShowExampleAppLongText(bool* p_open)
{
    BBZGUI::SetNextWindowSize(ImVec2(520, 600), BBZGUICond_FirstUseEver);
    if (!BBZGUI::Begin("Example: Long text display", p_open))
    {
        BBZGUI::End();
        return;
    }
    IMGUI_DEMO_MARKER("Examples/Long text display");

    static int test_type = 0;
    static BBZGUITextBuffer log;
    static int lines = 0;
    BBZGUI::Text("Printing unusually long amount of text.");
    BBZGUI::Combo("Test type", &test_type,
        "Single call to TextUnformatted()\0"
        "Multiple calls to Text(), clipped\0"
        "Multiple calls to Text(), not clipped (slow)\0");
    BBZGUI::Text("Buffer contents: %d lines, %d bytes", lines, log.size());
    if (BBZGUI::Button("Clear")) { log.clear(); lines = 0; }
    BBZGUI::SameLine();
    if (BBZGUI::Button("Add 1000 lines"))
    {
        for (int i = 0; i < 1000; i++)
            log.appendf("%i The quick brown fox jumps over the lazy dog\n", lines + i);
        lines += 1000;
    }
    BBZGUI::BeginChild("Log");
    switch (test_type)
    {
    case 0:
        // Single call to TextUnformatted() with a big buffer
        BBZGUI::TextUnformatted(log.begin(), log.end());
        break;
    case 1:
        {
            // Multiple calls to Text(), manually coarsely clipped - demonstrate how to use the BBZGUIListClipper helper.
            BBZGUI::PushStyleVar(BBZGUIStyleVar_ItemSpacing, ImVec2(0, 0));
            BBZGUIListClipper clipper;
            clipper.Begin(lines);
            while (clipper.Step())
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                    BBZGUI::Text("%i The quick brown fox jumps over the lazy dog", i);
            BBZGUI::PopStyleVar();
            break;
        }
    case 2:
        // Multiple calls to Text(), not clipped (slow)
        BBZGUI::PushStyleVar(BBZGUIStyleVar_ItemSpacing, ImVec2(0, 0));
        for (int i = 0; i < lines; i++)
            BBZGUI::Text("%i The quick brown fox jumps over the lazy dog", i);
        BBZGUI::PopStyleVar();
        break;
    }
    BBZGUI::EndChild();
    BBZGUI::End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Auto Resize / ShowExampleAppAutoResize()
//-----------------------------------------------------------------------------

// Demonstrate creating a window which gets auto-resized according to its content.
static void ShowExampleAppAutoResize(bool* p_open)
{
    if (!BBZGUI::Begin("Example: Auto-resizing window", p_open, BBZGUIWindowFlags_AlwaysAutoResize))
    {
        BBZGUI::End();
        return;
    }
    IMGUI_DEMO_MARKER("Examples/Auto-resizing window");

    static int lines = 10;
    BBZGUI::TextUnformatted(
        "Window will resize every-frame to the size of its content.\n"
        "Note that you probably don't want to query the window size to\n"
        "output your content because that would create a feedback loop.");
    BBZGUI::SliderInt("Number of lines", &lines, 1, 20);
    for (int i = 0; i < lines; i++)
        BBZGUI::Text("%*sThis is line %d", i * 4, "", i); // Pad with space to extend size horizontally
    BBZGUI::End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Constrained Resize / ShowExampleAppConstrainedResize()
//-----------------------------------------------------------------------------

// Demonstrate creating a window with custom resize constraints.
// Note that size constraints currently don't work on a docked window (when in 'docking' branch)
static void ShowExampleAppConstrainedResize(bool* p_open)
{
    struct CustomConstraints
    {
        // Helper functions to demonstrate programmatic constraints
        // FIXME: This doesn't take account of decoration size (e.g. title bar), library should make this easier.
        // FIXME: None of the three demos works consistently when resizing from borders.
        static void AspectRatio(BBZGUISizeCallbackData* data)
        {
            float aspect_ratio = *(float*)data->UserData;
            data->DesiredSize.y = (float)(int)(data->DesiredSize.x / aspect_ratio);
        }
        static void Square(BBZGUISizeCallbackData* data)
        {
            data->DesiredSize.x = data->DesiredSize.y = IM_MAX(data->DesiredSize.x, data->DesiredSize.y);
        }
        static void Step(BBZGUISizeCallbackData* data)
        {
            float step = *(float*)data->UserData;
            data->DesiredSize = ImVec2((int)(data->DesiredSize.x / step + 0.5f) * step, (int)(data->DesiredSize.y / step + 0.5f) * step);
        }
    };

    const char* test_desc[] =
    {
        "Between 100x100 and 500x500",
        "At least 100x100",
        "Resize vertical + lock current width",
        "Resize horizontal + lock current height",
        "Width Between 400 and 500",
        "Height at least 400",
        "Custom: Aspect Ratio 16:9",
        "Custom: Always Square",
        "Custom: Fixed Steps (100)",
    };

    // Options
    static bool auto_resize = false;
    static bool window_padding = true;
    static int type = 6; // Aspect Ratio
    static int display_lines = 10;

    // Submit constraint
    float aspect_ratio = 16.0f / 9.0f;
    float fixed_step = 100.0f;
    if (type == 0) BBZGUI::SetNextWindowSizeConstraints(ImVec2(100, 100), ImVec2(500, 500));         // Between 100x100 and 500x500
    if (type == 1) BBZGUI::SetNextWindowSizeConstraints(ImVec2(100, 100), ImVec2(FLT_MAX, FLT_MAX)); // Width > 100, Height > 100
    if (type == 2) BBZGUI::SetNextWindowSizeConstraints(ImVec2(-1, 0),    ImVec2(-1, FLT_MAX));      // Resize vertical + lock current width
    if (type == 3) BBZGUI::SetNextWindowSizeConstraints(ImVec2(0, -1),    ImVec2(FLT_MAX, -1));      // Resize horizontal + lock current height
    if (type == 4) BBZGUI::SetNextWindowSizeConstraints(ImVec2(400, -1),  ImVec2(500, -1));          // Width Between and 400 and 500
    if (type == 5) BBZGUI::SetNextWindowSizeConstraints(ImVec2(-1, 400),  ImVec2(-1, FLT_MAX));      // Height at least 400
    if (type == 6) BBZGUI::SetNextWindowSizeConstraints(ImVec2(0, 0),     ImVec2(FLT_MAX, FLT_MAX), CustomConstraints::AspectRatio, (void*)&aspect_ratio);   // Aspect ratio
    if (type == 7) BBZGUI::SetNextWindowSizeConstraints(ImVec2(0, 0),     ImVec2(FLT_MAX, FLT_MAX), CustomConstraints::Square);                              // Always Square
    if (type == 8) BBZGUI::SetNextWindowSizeConstraints(ImVec2(0, 0),     ImVec2(FLT_MAX, FLT_MAX), CustomConstraints::Step, (void*)&fixed_step);            // Fixed Step

    // Submit window
    if (!window_padding)
        BBZGUI::PushStyleVar(BBZGUIStyleVar_WindowPadding, ImVec2(0.0f, 0.0f));
    const BBZGUIWindowFlags window_flags = auto_resize ? BBZGUIWindowFlags_AlwaysAutoResize : 0;
    const bool window_open = BBZGUI::Begin("Example: Constrained Resize", p_open, window_flags);
    if (!window_padding)
        BBZGUI::PopStyleVar();
    if (window_open)
    {
        IMGUI_DEMO_MARKER("Examples/Constrained Resizing window");
        if (BBZGUI::GetIO().KeyShift)
        {
            // Display a dummy viewport (in your real app you would likely use ImageButton() to display a texture.
            ImVec2 avail_size = BBZGUI::GetContentRegionAvail();
            ImVec2 pos = BBZGUI::GetCursorScreenPos();
            BBZGUI::ColorButton("viewport", ImVec4(0.5f, 0.2f, 0.5f, 1.0f), BBZGUIColorEditFlags_NoTooltip | BBZGUIColorEditFlags_NoDragDrop, avail_size);
            BBZGUI::SetCursorScreenPos(ImVec2(pos.x + 10, pos.y + 10));
            BBZGUI::Text("%.2f x %.2f", avail_size.x, avail_size.y);
        }
        else
        {
            BBZGUI::Text("(Hold SHIFT to display a dummy viewport)");
            if (BBZGUI::Button("Set 200x200")) { BBZGUI::SetWindowSize(ImVec2(200, 200)); } BBZGUI::SameLine();
            if (BBZGUI::Button("Set 500x500")) { BBZGUI::SetWindowSize(ImVec2(500, 500)); } BBZGUI::SameLine();
            if (BBZGUI::Button("Set 800x200")) { BBZGUI::SetWindowSize(ImVec2(800, 200)); }
            BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 20);
            BBZGUI::Combo("Constraint", &type, test_desc, IM_ARRAYSIZE(test_desc));
            BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 20);
            BBZGUI::DragInt("Lines", &display_lines, 0.2f, 1, 100);
            BBZGUI::Checkbox("Auto-resize", &auto_resize);
            BBZGUI::Checkbox("Window padding", &window_padding);
            for (int i = 0; i < display_lines; i++)
                BBZGUI::Text("%*sHello, sailor! Making this line long enough for the example.", i * 4, "");
        }
    }
    BBZGUI::End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Simple overlay / ShowExampleAppSimpleOverlay()
//-----------------------------------------------------------------------------

// Demonstrate creating a simple static window with no decoration
// + a context-menu to choose which corner of the screen to use.
static void ShowExampleAppSimpleOverlay(bool* p_open)
{
    static int location = 0;
    BBZGUIIO& io = BBZGUI::GetIO();
    BBZGUIWindowFlags window_flags = BBZGUIWindowFlags_NoDecoration | BBZGUIWindowFlags_AlwaysAutoResize | BBZGUIWindowFlags_NoSavedSettings | BBZGUIWindowFlags_NoFocusOnAppearing | BBZGUIWindowFlags_NoNav;
    if (location >= 0)
    {
        const float PAD = 10.0f;
        const BBZGUIViewport* viewport = BBZGUI::GetMainViewport();
        ImVec2 work_pos = viewport->WorkPos; // Use work area to avoid menu-bar/task-bar, if any!
        ImVec2 work_size = viewport->WorkSize;
        ImVec2 window_pos, window_pos_pivot;
        window_pos.x = (location & 1) ? (work_pos.x + work_size.x - PAD) : (work_pos.x + PAD);
        window_pos.y = (location & 2) ? (work_pos.y + work_size.y - PAD) : (work_pos.y + PAD);
        window_pos_pivot.x = (location & 1) ? 1.0f : 0.0f;
        window_pos_pivot.y = (location & 2) ? 1.0f : 0.0f;
        BBZGUI::SetNextWindowPos(window_pos, BBZGUICond_Always, window_pos_pivot);
        window_flags |= BBZGUIWindowFlags_NoMove;
    }
    else if (location == -2)
    {
        // Center window
        BBZGUI::SetNextWindowPos(BBZGUI::GetMainViewport()->GetCenter(), BBZGUICond_Always, ImVec2(0.5f, 0.5f));
        window_flags |= BBZGUIWindowFlags_NoMove;
    }
    BBZGUI::SetNextWindowBgAlpha(0.35f); // Transparent background
    if (BBZGUI::Begin("Example: Simple overlay", p_open, window_flags))
    {
        IMGUI_DEMO_MARKER("Examples/Simple Overlay");
        BBZGUI::Text("Simple overlay\n" "(right-click to change position)");
        BBZGUI::Separator();
        if (BBZGUI::IsMousePosValid())
            BBZGUI::Text("Mouse Position: (%.1f,%.1f)", io.MousePos.x, io.MousePos.y);
        else
            BBZGUI::Text("Mouse Position: <invalid>");
        if (BBZGUI::BeginPopupContextWindow())
        {
            if (BBZGUI::MenuItem("Custom",       NULL, location == -1)) location = -1;
            if (BBZGUI::MenuItem("Center",       NULL, location == -2)) location = -2;
            if (BBZGUI::MenuItem("Top-left",     NULL, location == 0)) location = 0;
            if (BBZGUI::MenuItem("Top-right",    NULL, location == 1)) location = 1;
            if (BBZGUI::MenuItem("Bottom-left",  NULL, location == 2)) location = 2;
            if (BBZGUI::MenuItem("Bottom-right", NULL, location == 3)) location = 3;
            if (p_open && BBZGUI::MenuItem("Close")) *p_open = false;
            BBZGUI::EndPopup();
        }
    }
    BBZGUI::End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Fullscreen window / ShowExampleAppFullscreen()
//-----------------------------------------------------------------------------

// Demonstrate creating a window covering the entire screen/viewport
static void ShowExampleAppFullscreen(bool* p_open)
{
    static bool use_work_area = true;
    static BBZGUIWindowFlags flags = BBZGUIWindowFlags_NoDecoration | BBZGUIWindowFlags_NoMove | BBZGUIWindowFlags_NoSavedSettings;

    // We demonstrate using the full viewport area or the work area (without menu-bars, task-bars etc.)
    // Based on your use case you may want one or the other.
    const BBZGUIViewport* viewport = BBZGUI::GetMainViewport();
    BBZGUI::SetNextWindowPos(use_work_area ? viewport->WorkPos : viewport->Pos);
    BBZGUI::SetNextWindowSize(use_work_area ? viewport->WorkSize : viewport->Size);

    if (BBZGUI::Begin("Example: Fullscreen window", p_open, flags))
    {
        BBZGUI::Checkbox("Use work area instead of main area", &use_work_area);
        BBZGUI::SameLine();
        HelpMarker("Main Area = entire viewport,\nWork Area = entire viewport minus sections used by the main menu bars, task bars etc.\n\nEnable the main-menu bar in Examples menu to see the difference.");

        BBZGUI::CheckboxFlags("BBZGUIWindowFlags_NoBackground", &flags, BBZGUIWindowFlags_NoBackground);
        BBZGUI::CheckboxFlags("BBZGUIWindowFlags_NoDecoration", &flags, BBZGUIWindowFlags_NoDecoration);
        BBZGUI::Indent();
        BBZGUI::CheckboxFlags("BBZGUIWindowFlags_NoTitleBar", &flags, BBZGUIWindowFlags_NoTitleBar);
        BBZGUI::CheckboxFlags("BBZGUIWindowFlags_NoCollapse", &flags, BBZGUIWindowFlags_NoCollapse);
        BBZGUI::CheckboxFlags("BBZGUIWindowFlags_NoScrollbar", &flags, BBZGUIWindowFlags_NoScrollbar);
        BBZGUI::Unindent();

        if (p_open && BBZGUI::Button("Close this window"))
            *p_open = false;
    }
    BBZGUI::End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Manipulating Window Titles / ShowExampleAppWindowTitles()
//-----------------------------------------------------------------------------

// Demonstrate the use of "##" and "###" in identifiers to manipulate ID generation.
// This applies to all regular items as well.
// Read FAQ section "How can I have multiple widgets with the same label?" for details.
static void ShowExampleAppWindowTitles(bool*)
{
    const BBZGUIViewport* viewport = BBZGUI::GetMainViewport();
    const ImVec2 base_pos = viewport->Pos;

    // By default, Windows are uniquely identified by their title.
    // You can use the "##" and "###" markers to manipulate the display/ID.

    // Using "##" to display same title but have unique identifier.
    BBZGUI::SetNextWindowPos(ImVec2(base_pos.x + 100, base_pos.y + 100), BBZGUICond_FirstUseEver);
    BBZGUI::Begin("Same title as another window##1");
    IMGUI_DEMO_MARKER("Examples/Manipulating window titles");
    BBZGUI::Text("This is window 1.\nMy title is the same as window 2, but my identifier is unique.");
    BBZGUI::End();

    BBZGUI::SetNextWindowPos(ImVec2(base_pos.x + 100, base_pos.y + 200), BBZGUICond_FirstUseEver);
    BBZGUI::Begin("Same title as another window##2");
    BBZGUI::Text("This is window 2.\nMy title is the same as window 1, but my identifier is unique.");
    BBZGUI::End();

    // Using "###" to display a changing title but keep a static identifier "AnimatedTitle"
    char buf[128];
    sprintf(buf, "Animated title %c %d###AnimatedTitle", "|/-\\"[(int)(BBZGUI::GetTime() / 0.25f) & 3], BBZGUI::GetFrameCount());
    BBZGUI::SetNextWindowPos(ImVec2(base_pos.x + 100, base_pos.y + 300), BBZGUICond_FirstUseEver);
    BBZGUI::Begin(buf);
    BBZGUI::Text("This window has a changing title.");
    BBZGUI::End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Custom Rendering using ImDrawList API / ShowExampleAppCustomRendering()
//-----------------------------------------------------------------------------

// Add a |_| looking shape
static void PathConcaveShape(ImDrawList* draw_list, float x, float y, float sz)
{
    const ImVec2 pos_norms[] = { { 0.0f, 0.0f }, { 0.3f, 0.0f }, { 0.3f, 0.7f }, { 0.7f, 0.7f }, { 0.7f, 0.0f }, { 1.0f, 0.0f }, { 1.0f, 1.0f }, { 0.0f, 1.0f } };
    for (const ImVec2& p : pos_norms)
        draw_list->PathLineTo(ImVec2(x + 0.5f + (int)(sz * p.x), y + 0.5f + (int)(sz * p.y)));
}

// Demonstrate using the low-level ImDrawList to draw custom shapes.
static void ShowExampleAppCustomRendering(bool* p_open)
{
    if (!BBZGUI::Begin("Example: Custom rendering", p_open))
    {
        BBZGUI::End();
        return;
    }
    IMGUI_DEMO_MARKER("Examples/Custom Rendering");

    // Tip: If you do a lot of custom rendering, you probably want to use your own geometrical types and benefit of
    // overloaded operators, etc. Define IM_VEC2_CLASS_EXTRA in imconfig.h to create implicit conversions between your
    // types and ImVec2/ImVec4. Dear BBZGUI defines overloaded operators but they are internal to BBZGui.cpp and not
    // exposed outside (to avoid messing with your types) In this example we are not using the maths operators!

    if (BBZGUI::BeginTabBar("##TabBar"))
    {
        if (BBZGUI::BeginTabItem("Primitives"))
        {
            BBZGUI::PushItemWidth(-BBZGUI::GetFontSize() * 15);
            ImDrawList* draw_list = BBZGUI::GetWindowDrawList();

            // Draw gradients
            // (note that those are currently exacerbating our sRGB/Linear issues)
            // Calling BBZGUI::GetColorU32() multiplies the given colors by the current Style Alpha, but you may pass the IM_COL32() directly as well..
            BBZGUI::Text("Gradients");
            ImVec2 gradient_size = ImVec2(BBZGUI::CalcItemWidth(), BBZGUI::GetFrameHeight());
            {
                ImVec2 p0 = BBZGUI::GetCursorScreenPos();
                ImVec2 p1 = ImVec2(p0.x + gradient_size.x, p0.y + gradient_size.y);
                ImU32 col_a = BBZGUI::GetColorU32(IM_COL32(0, 0, 0, 255));
                ImU32 col_b = BBZGUI::GetColorU32(IM_COL32(255, 255, 255, 255));
                draw_list->AddRectFilledMultiColor(p0, p1, col_a, col_b, col_b, col_a);
                BBZGUI::InvisibleButton("##gradient1", gradient_size);
            }
            {
                ImVec2 p0 = BBZGUI::GetCursorScreenPos();
                ImVec2 p1 = ImVec2(p0.x + gradient_size.x, p0.y + gradient_size.y);
                ImU32 col_a = BBZGUI::GetColorU32(IM_COL32(0, 255, 0, 255));
                ImU32 col_b = BBZGUI::GetColorU32(IM_COL32(255, 0, 0, 255));
                draw_list->AddRectFilledMultiColor(p0, p1, col_a, col_b, col_b, col_a);
                BBZGUI::InvisibleButton("##gradient2", gradient_size);
            }

            // Draw a bunch of primitives
            BBZGUI::Text("All primitives");
            static float sz = 36.0f;
            static float thickness = 3.0f;
            static int ngon_sides = 6;
            static bool circle_segments_override = false;
            static int circle_segments_override_v = 12;
            static bool curve_segments_override = false;
            static int curve_segments_override_v = 8;
            static ImVec4 colf = ImVec4(1.0f, 1.0f, 0.4f, 1.0f);
            BBZGUI::DragFloat("Size", &sz, 0.2f, 2.0f, 100.0f, "%.0f");
            BBZGUI::DragFloat("Thickness", &thickness, 0.05f, 1.0f, 8.0f, "%.02f");
            BBZGUI::SliderInt("N-gon sides", &ngon_sides, 3, 12);
            BBZGUI::Checkbox("##circlesegmentoverride", &circle_segments_override);
            BBZGUI::SameLine(0.0f, BBZGUI::GetStyle().ItemInnerSpacing.x);
            circle_segments_override |= BBZGUI::SliderInt("Circle segments override", &circle_segments_override_v, 3, 40);
            BBZGUI::Checkbox("##curvessegmentoverride", &curve_segments_override);
            BBZGUI::SameLine(0.0f, BBZGUI::GetStyle().ItemInnerSpacing.x);
            curve_segments_override |= BBZGUI::SliderInt("Curves segments override", &curve_segments_override_v, 3, 40);
            BBZGUI::ColorEdit4("Color", &colf.x);

            const ImVec2 p = BBZGUI::GetCursorScreenPos();
            const ImU32 col = ImColor(colf);
            const float spacing = 10.0f;
            const ImDrawFlags corners_tl_br = ImDrawFlags_RoundCornersTopLeft | ImDrawFlags_RoundCornersBottomRight;
            const float rounding = sz / 5.0f;
            const int circle_segments = circle_segments_override ? circle_segments_override_v : 0;
            const int curve_segments = curve_segments_override ? curve_segments_override_v : 0;
            const ImVec2 cp3[3] = { ImVec2(0.0f, sz * 0.6f), ImVec2(sz * 0.5f, -sz * 0.4f), ImVec2(sz, sz) }; // Control points for curves
            const ImVec2 cp4[4] = { ImVec2(0.0f, 0.0f), ImVec2(sz * 1.3f, sz * 0.3f), ImVec2(sz - sz * 1.3f, sz - sz * 0.3f), ImVec2(sz, sz) };

            float x = p.x + 4.0f;
            float y = p.y + 4.0f;
            for (int n = 0; n < 2; n++)
            {
                // First line uses a thickness of 1.0f, second line uses the configurable thickness
                float th = (n == 0) ? 1.0f : thickness;
                draw_list->AddNgon(ImVec2(x + sz*0.5f, y + sz*0.5f), sz*0.5f, col, ngon_sides, th);                 x += sz + spacing;  // N-gon
                draw_list->AddCircle(ImVec2(x + sz*0.5f, y + sz*0.5f), sz*0.5f, col, circle_segments, th);          x += sz + spacing;  // Circle
                draw_list->AddEllipse(ImVec2(x + sz*0.5f, y + sz*0.5f), ImVec2(sz*0.5f, sz*0.3f), col, -0.3f, circle_segments, th); x += sz + spacing;	// Ellipse
                draw_list->AddRect(ImVec2(x, y), ImVec2(x + sz, y + sz), col, 0.0f, ImDrawFlags_None, th);          x += sz + spacing;  // Square
                draw_list->AddRect(ImVec2(x, y), ImVec2(x + sz, y + sz), col, rounding, ImDrawFlags_None, th);      x += sz + spacing;  // Square with all rounded corners
                draw_list->AddRect(ImVec2(x, y), ImVec2(x + sz, y + sz), col, rounding, corners_tl_br, th);         x += sz + spacing;  // Square with two rounded corners
                draw_list->AddTriangle(ImVec2(x+sz*0.5f,y), ImVec2(x+sz, y+sz-0.5f), ImVec2(x, y+sz-0.5f), col, th);x += sz + spacing;  // Triangle
                //draw_list->AddTriangle(ImVec2(x+sz*0.2f,y), ImVec2(x, y+sz-0.5f), ImVec2(x+sz*0.4f, y+sz-0.5f), col, th);x+= sz*0.4f + spacing; // Thin triangle
                PathConcaveShape(draw_list, x, y, sz); draw_list->PathStroke(col, ImDrawFlags_Closed, th);          x += sz + spacing;  // Concave Shape
                //draw_list->AddPolyline(concave_shape, IM_ARRAYSIZE(concave_shape), col, ImDrawFlags_Closed, th);
                draw_list->AddLine(ImVec2(x, y), ImVec2(x + sz, y), col, th);                                       x += sz + spacing;  // Horizontal line (note: drawing a filled rectangle will be faster!)
                draw_list->AddLine(ImVec2(x, y), ImVec2(x, y + sz), col, th);                                       x += spacing;       // Vertical line (note: drawing a filled rectangle will be faster!)
                draw_list->AddLine(ImVec2(x, y), ImVec2(x + sz, y + sz), col, th);                                  x += sz + spacing;  // Diagonal line

                // Path
                draw_list->PathArcTo(ImVec2(x + sz*0.5f, y + sz*0.5f), sz*0.5f, 3.141592f, 3.141592f * -0.5f);
                draw_list->PathStroke(col, ImDrawFlags_None, th);
                x += sz + spacing;

                // Quadratic Bezier Curve (3 control points)
                draw_list->AddBezierQuadratic(ImVec2(x + cp3[0].x, y + cp3[0].y), ImVec2(x + cp3[1].x, y + cp3[1].y), ImVec2(x + cp3[2].x, y + cp3[2].y), col, th, curve_segments);
                x += sz + spacing;

                // Cubic Bezier Curve (4 control points)
                draw_list->AddBezierCubic(ImVec2(x + cp4[0].x, y + cp4[0].y), ImVec2(x + cp4[1].x, y + cp4[1].y), ImVec2(x + cp4[2].x, y + cp4[2].y), ImVec2(x + cp4[3].x, y + cp4[3].y), col, th, curve_segments);

                x = p.x + 4;
                y += sz + spacing;
            }

            // Filled shapes
            draw_list->AddNgonFilled(ImVec2(x + sz * 0.5f, y + sz * 0.5f), sz * 0.5f, col, ngon_sides);             x += sz + spacing;  // N-gon
            draw_list->AddCircleFilled(ImVec2(x + sz * 0.5f, y + sz * 0.5f), sz * 0.5f, col, circle_segments);      x += sz + spacing;  // Circle
            draw_list->AddEllipseFilled(ImVec2(x + sz * 0.5f, y + sz * 0.5f), ImVec2(sz * 0.5f, sz * 0.3f), col, -0.3f, circle_segments); x += sz + spacing;// Ellipse
            draw_list->AddRectFilled(ImVec2(x, y), ImVec2(x + sz, y + sz), col);                                    x += sz + spacing;  // Square
            draw_list->AddRectFilled(ImVec2(x, y), ImVec2(x + sz, y + sz), col, 10.0f);                             x += sz + spacing;  // Square with all rounded corners
            draw_list->AddRectFilled(ImVec2(x, y), ImVec2(x + sz, y + sz), col, 10.0f, corners_tl_br);              x += sz + spacing;  // Square with two rounded corners
            draw_list->AddTriangleFilled(ImVec2(x+sz*0.5f,y), ImVec2(x+sz, y+sz-0.5f), ImVec2(x, y+sz-0.5f), col);  x += sz + spacing;  // Triangle
            //draw_list->AddTriangleFilled(ImVec2(x+sz*0.2f,y), ImVec2(x, y+sz-0.5f), ImVec2(x+sz*0.4f, y+sz-0.5f), col); x += sz*0.4f + spacing; // Thin triangle
            PathConcaveShape(draw_list, x, y, sz); draw_list->PathFillConcave(col);                                 x += sz + spacing;  // Concave shape
            draw_list->AddRectFilled(ImVec2(x, y), ImVec2(x + sz, y + thickness), col);                             x += sz + spacing;  // Horizontal line (faster than AddLine, but only handle integer thickness)
            draw_list->AddRectFilled(ImVec2(x, y), ImVec2(x + thickness, y + sz), col);                             x += spacing * 2.0f;// Vertical line (faster than AddLine, but only handle integer thickness)
            draw_list->AddRectFilled(ImVec2(x, y), ImVec2(x + 1, y + 1), col);                                      x += sz;            // Pixel (faster than AddLine)

            // Path
            draw_list->PathArcTo(ImVec2(x + sz * 0.5f, y + sz * 0.5f), sz * 0.5f, 3.141592f * -0.5f, 3.141592f);
            draw_list->PathFillConvex(col);
            x += sz + spacing;

            // Quadratic Bezier Curve (3 control points)
            draw_list->PathLineTo(ImVec2(x + cp3[0].x, y + cp3[0].y));
            draw_list->PathBezierQuadraticCurveTo(ImVec2(x + cp3[1].x, y + cp3[1].y), ImVec2(x + cp3[2].x, y + cp3[2].y), curve_segments);
            draw_list->PathFillConvex(col);
            x += sz + spacing;

            draw_list->AddRectFilledMultiColor(ImVec2(x, y), ImVec2(x + sz, y + sz), IM_COL32(0, 0, 0, 255), IM_COL32(255, 0, 0, 255), IM_COL32(255, 255, 0, 255), IM_COL32(0, 255, 0, 255));
            x += sz + spacing;

            BBZGUI::Dummy(ImVec2((sz + spacing) * 13.2f, (sz + spacing) * 3.0f));
            BBZGUI::PopItemWidth();
            BBZGUI::EndTabItem();
        }

        if (BBZGUI::BeginTabItem("Canvas"))
        {
            static ImVector<ImVec2> points;
            static ImVec2 scrolling(0.0f, 0.0f);
            static bool opt_enable_grid = true;
            static bool opt_enable_context_menu = true;
            static bool adding_line = false;

            BBZGUI::Checkbox("Enable grid", &opt_enable_grid);
            BBZGUI::Checkbox("Enable context menu", &opt_enable_context_menu);
            BBZGUI::Text("Mouse Left: drag to add lines,\nMouse Right: drag to scroll, click for context menu.");

            // Typically you would use a BeginChild()/EndChild() pair to benefit from a clipping region + own scrolling.
            // Here we demonstrate that this can be replaced by simple offsetting + custom drawing + PushClipRect/PopClipRect() calls.
            // To use a child window instead we could use, e.g:
            //      BBZGUI::PushStyleVar(BBZGUIStyleVar_WindowPadding, ImVec2(0, 0));      // Disable padding
            //      BBZGUI::PushStyleColor(BBZGUICol_ChildBg, IM_COL32(50, 50, 50, 255));  // Set a background color
            //      BBZGUI::BeginChild("canvas", ImVec2(0.0f, 0.0f), BBZGUIChildFlags_Borders, BBZGUIWindowFlags_NoMove);
            //      BBZGUI::PopStyleColor();
            //      BBZGUI::PopStyleVar();
            //      [...]
            //      BBZGUI::EndChild();

            // Using InvisibleButton() as a convenience 1) it will advance the layout cursor and 2) allows us to use IsItemHovered()/IsItemActive()
            ImVec2 canvas_p0 = BBZGUI::GetCursorScreenPos();      // ImDrawList API uses screen coordinates!
            ImVec2 canvas_sz = BBZGUI::GetContentRegionAvail();   // Resize canvas to what's available
            if (canvas_sz.x < 50.0f) canvas_sz.x = 50.0f;
            if (canvas_sz.y < 50.0f) canvas_sz.y = 50.0f;
            ImVec2 canvas_p1 = ImVec2(canvas_p0.x + canvas_sz.x, canvas_p0.y + canvas_sz.y);

            // Draw border and background color
            BBZGUIIO& io = BBZGUI::GetIO();
            ImDrawList* draw_list = BBZGUI::GetWindowDrawList();
            draw_list->AddRectFilled(canvas_p0, canvas_p1, IM_COL32(50, 50, 50, 255));
            draw_list->AddRect(canvas_p0, canvas_p1, IM_COL32(255, 255, 255, 255));

            // This will catch our interactions
            BBZGUI::InvisibleButton("canvas", canvas_sz, BBZGUIButtonFlags_MouseButtonLeft | BBZGUIButtonFlags_MouseButtonRight);
            const bool is_hovered = BBZGUI::IsItemHovered(); // Hovered
            const bool is_active = BBZGUI::IsItemActive();   // Held
            const ImVec2 origin(canvas_p0.x + scrolling.x, canvas_p0.y + scrolling.y); // Lock scrolled origin
            const ImVec2 mouse_pos_in_canvas(io.MousePos.x - origin.x, io.MousePos.y - origin.y);

            // Add first and second point
            if (is_hovered && !adding_line && BBZGUI::IsMouseClicked(BBZGUIMouseButton_Left))
            {
                points.push_back(mouse_pos_in_canvas);
                points.push_back(mouse_pos_in_canvas);
                adding_line = true;
            }
            if (adding_line)
            {
                points.back() = mouse_pos_in_canvas;
                if (!BBZGUI::IsMouseDown(BBZGUIMouseButton_Left))
                    adding_line = false;
            }

            // Pan (we use a zero mouse threshold when there's no context menu)
            // You may decide to make that threshold dynamic based on whether the mouse is hovering something etc.
            const float mouse_threshold_for_pan = opt_enable_context_menu ? -1.0f : 0.0f;
            if (is_active && BBZGUI::IsMouseDragging(BBZGUIMouseButton_Right, mouse_threshold_for_pan))
            {
                scrolling.x += io.MouseDelta.x;
                scrolling.y += io.MouseDelta.y;
            }

            // Context menu (under default mouse threshold)
            ImVec2 drag_delta = BBZGUI::GetMouseDragDelta(BBZGUIMouseButton_Right);
            if (opt_enable_context_menu && drag_delta.x == 0.0f && drag_delta.y == 0.0f)
                BBZGUI::OpenPopupOnItemClick("context", BBZGUIPopupFlags_MouseButtonRight);
            if (BBZGUI::BeginPopup("context"))
            {
                if (adding_line)
                    points.resize(points.size() - 2);
                adding_line = false;
                if (BBZGUI::MenuItem("Remove one", NULL, false, points.Size > 0)) { points.resize(points.size() - 2); }
                if (BBZGUI::MenuItem("Remove all", NULL, false, points.Size > 0)) { points.clear(); }
                BBZGUI::EndPopup();
            }

            // Draw grid + all lines in the canvas
            draw_list->PushClipRect(canvas_p0, canvas_p1, true);
            if (opt_enable_grid)
            {
                const float GRID_STEP = 64.0f;
                for (float x = fmodf(scrolling.x, GRID_STEP); x < canvas_sz.x; x += GRID_STEP)
                    draw_list->AddLine(ImVec2(canvas_p0.x + x, canvas_p0.y), ImVec2(canvas_p0.x + x, canvas_p1.y), IM_COL32(200, 200, 200, 40));
                for (float y = fmodf(scrolling.y, GRID_STEP); y < canvas_sz.y; y += GRID_STEP)
                    draw_list->AddLine(ImVec2(canvas_p0.x, canvas_p0.y + y), ImVec2(canvas_p1.x, canvas_p0.y + y), IM_COL32(200, 200, 200, 40));
            }
            for (int n = 0; n < points.Size; n += 2)
                draw_list->AddLine(ImVec2(origin.x + points[n].x, origin.y + points[n].y), ImVec2(origin.x + points[n + 1].x, origin.y + points[n + 1].y), IM_COL32(255, 255, 0, 255), 2.0f);
            draw_list->PopClipRect();

            BBZGUI::EndTabItem();
        }

        if (BBZGUI::BeginTabItem("BG/FG draw lists"))
        {
            static bool draw_bg = true;
            static bool draw_fg = true;
            BBZGUI::Checkbox("Draw in Background draw list", &draw_bg);
            BBZGUI::SameLine(); HelpMarker("The Background draw list will be rendered below every Dear BBZGUI windows.");
            BBZGUI::Checkbox("Draw in Foreground draw list", &draw_fg);
            BBZGUI::SameLine(); HelpMarker("The Foreground draw list will be rendered over every Dear BBZGUI windows.");
            ImVec2 window_pos = BBZGUI::GetWindowPos();
            ImVec2 window_size = BBZGUI::GetWindowSize();
            ImVec2 window_center = ImVec2(window_pos.x + window_size.x * 0.5f, window_pos.y + window_size.y * 0.5f);
            if (draw_bg)
                BBZGUI::GetBackgroundDrawList()->AddCircle(window_center, window_size.x * 0.6f, IM_COL32(255, 0, 0, 200), 0, 10 + 4);
            if (draw_fg)
                BBZGUI::GetForegroundDrawList()->AddCircle(window_center, window_size.y * 0.6f, IM_COL32(0, 255, 0, 200), 0, 10);
            BBZGUI::EndTabItem();
        }

        // Demonstrate out-of-order rendering via channels splitting
        // We use functions in ImDrawList as each draw list contains a convenience splitter,
        // but you can also instantiate your own ImDrawListSplitter if you need to nest them.
        if (BBZGUI::BeginTabItem("Draw Channels"))
        {
            ImDrawList* draw_list = BBZGUI::GetWindowDrawList();
            {
                BBZGUI::Text("Blue shape is drawn first: appears in back");
                BBZGUI::Text("Red shape is drawn after: appears in front");
                ImVec2 p0 = BBZGUI::GetCursorScreenPos();
                draw_list->AddRectFilled(ImVec2(p0.x, p0.y), ImVec2(p0.x + 50, p0.y + 50), IM_COL32(0, 0, 255, 255)); // Blue
                draw_list->AddRectFilled(ImVec2(p0.x + 25, p0.y + 25), ImVec2(p0.x + 75, p0.y + 75), IM_COL32(255, 0, 0, 255)); // Red
                BBZGUI::Dummy(ImVec2(75, 75));
            }
            BBZGUI::Separator();
            {
                BBZGUI::Text("Blue shape is drawn first, into channel 1: appears in front");
                BBZGUI::Text("Red shape is drawn after, into channel 0: appears in back");
                ImVec2 p1 = BBZGUI::GetCursorScreenPos();

                // Create 2 channels and draw a Blue shape THEN a Red shape.
                // You can create any number of channels. Tables API use 1 channel per column in order to better batch draw calls.
                draw_list->ChannelsSplit(2);
                draw_list->ChannelsSetCurrent(1);
                draw_list->AddRectFilled(ImVec2(p1.x, p1.y), ImVec2(p1.x + 50, p1.y + 50), IM_COL32(0, 0, 255, 255)); // Blue
                draw_list->ChannelsSetCurrent(0);
                draw_list->AddRectFilled(ImVec2(p1.x + 25, p1.y + 25), ImVec2(p1.x + 75, p1.y + 75), IM_COL32(255, 0, 0, 255)); // Red

                // Flatten/reorder channels. Red shape is in channel 0 and it appears below the Blue shape in channel 1.
                // This works by copying draw indices only (vertices are not copied).
                draw_list->ChannelsMerge();
                BBZGUI::Dummy(ImVec2(75, 75));
                BBZGUI::Text("After reordering, contents of channel 0 appears below channel 1.");
            }
            BBZGUI::EndTabItem();
        }

        BBZGUI::EndTabBar();
    }

    BBZGUI::End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Documents Handling / ShowExampleAppDocuments()
//-----------------------------------------------------------------------------

// Simplified structure to mimic a Document model
struct MyDocument
{
    char        Name[32];   // Document title
    int         UID;        // Unique ID (necessary as we can change title)
    bool        Open;       // Set when open (we keep an array of all available documents to simplify demo code!)
    bool        OpenPrev;   // Copy of Open from last update.
    bool        Dirty;      // Set when the document has been modified
    ImVec4      Color;      // An arbitrary variable associated to the document

    MyDocument(int uid, const char* name, bool open = true, const ImVec4& color = ImVec4(1.0f, 1.0f, 1.0f, 1.0f))
    {
        UID = uid;
        snprintf(Name, sizeof(Name), "%s", name);
        Open = OpenPrev = open;
        Dirty = false;
        Color = color;
    }
    void DoOpen()       { Open = true; }
    void DoForceClose() { Open = false; Dirty = false; }
    void DoSave()       { Dirty = false; }
};

struct ExampleAppDocuments
{
    ImVector<MyDocument>    Documents;
    ImVector<MyDocument*>   CloseQueue;
    MyDocument*             RenamingDoc = NULL;
    bool                    RenamingStarted = false;

    ExampleAppDocuments()
    {
        Documents.push_back(MyDocument(0, "Lettuce",             true,  ImVec4(0.4f, 0.8f, 0.4f, 1.0f)));
        Documents.push_back(MyDocument(1, "Eggplant",            true,  ImVec4(0.8f, 0.5f, 1.0f, 1.0f)));
        Documents.push_back(MyDocument(2, "Carrot",              true,  ImVec4(1.0f, 0.8f, 0.5f, 1.0f)));
        Documents.push_back(MyDocument(3, "Tomato",              false, ImVec4(1.0f, 0.3f, 0.4f, 1.0f)));
        Documents.push_back(MyDocument(4, "A Rather Long Title", false, ImVec4(0.4f, 0.8f, 0.8f, 1.0f)));
        Documents.push_back(MyDocument(5, "Some Document",       false, ImVec4(0.8f, 0.8f, 1.0f, 1.0f)));
    }

    // As we allow to change document name, we append a never-changing document ID so tabs are stable
    void GetTabName(MyDocument* doc, char* out_buf, size_t out_buf_size)
    {
        snprintf(out_buf, out_buf_size, "%s###doc%d", doc->Name, doc->UID);
    }

    // Display placeholder contents for the Document
    void DisplayDocContents(MyDocument* doc)
    {
        BBZGUI::PushID(doc);
        BBZGUI::Text("Document \"%s\"", doc->Name);
        BBZGUI::PushStyleColor(BBZGUICol_Text, doc->Color);
        BBZGUI::TextWrapped("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.");
        BBZGUI::PopStyleColor();

        BBZGUI::SetNextItemShortcut(BBZGUIMod_Ctrl | BBZGUIKey_R, BBZGUIInputFlags_Tooltip);
        if (BBZGUI::Button("Rename.."))
        {
            RenamingDoc = doc;
            RenamingStarted = true;
        }
        BBZGUI::SameLine();

        BBZGUI::SetNextItemShortcut(BBZGUIMod_Ctrl | BBZGUIKey_M, BBZGUIInputFlags_Tooltip);
        if (BBZGUI::Button("Modify"))
            doc->Dirty = true;

        BBZGUI::SameLine();
        BBZGUI::SetNextItemShortcut(BBZGUIMod_Ctrl | BBZGUIKey_S, BBZGUIInputFlags_Tooltip);
        if (BBZGUI::Button("Save"))
            doc->DoSave();

        BBZGUI::SameLine();
        BBZGUI::SetNextItemShortcut(BBZGUIMod_Ctrl | BBZGUIKey_W, BBZGUIInputFlags_Tooltip);
        if (BBZGUI::Button("Close"))
            CloseQueue.push_back(doc);
        BBZGUI::ColorEdit3("color", &doc->Color.x);  // Useful to test drag and drop and hold-dragged-to-open-tab behavior.
        BBZGUI::PopID();
    }

    // Display context menu for the Document
    void DisplayDocContextMenu(MyDocument* doc)
    {
        if (!BBZGUI::BeginPopupContextItem())
            return;

        char buf[256];
        sprintf(buf, "Save %s", doc->Name);
        if (BBZGUI::MenuItem(buf, "Ctrl+S", false, doc->Open))
            doc->DoSave();
        if (BBZGUI::MenuItem("Rename...", "Ctrl+R", false, doc->Open))
            RenamingDoc = doc;
        if (BBZGUI::MenuItem("Close", "Ctrl+W", false, doc->Open))
            CloseQueue.push_back(doc);
        BBZGUI::EndPopup();
    }

    // [Optional] Notify the system of Tabs/Windows closure that happened outside the regular tab interface.
    // If a tab has been closed programmatically (aka closed from another source such as the Checkbox() in the demo,
    // as opposed to clicking on the regular tab closing button) and stops being submitted, it will take a frame for
    // the tab bar to notice its absence. During this frame there will be a gap in the tab bar, and if the tab that has
    // disappeared was the selected one, the tab bar will report no selected tab during the frame. This will effectively
    // give the impression of a flicker for one frame.
    // We call SetTabItemClosed() to manually notify the Tab Bar or Docking system of removed tabs to avoid this glitch.
    // Note that this completely optional, and only affect tab bars with the BBZGUITabBarFlags_Reorderable flag.
    void NotifyOfDocumentsClosedElsewhere()
    {
        for (MyDocument& doc : Documents)
        {
            if (!doc.Open && doc.OpenPrev)
                BBZGUI::SetTabItemClosed(doc.Name);
            doc.OpenPrev = doc.Open;
        }
    }
};

void ShowExampleAppDocuments(bool* p_open)
{
    static ExampleAppDocuments app;

    // Options
    static bool opt_reorderable = true;
    static BBZGUITabBarFlags opt_fitting_flags = BBZGUITabBarFlags_FittingPolicyDefault_;

    bool window_contents_visible = BBZGUI::Begin("Example: Documents", p_open, BBZGUIWindowFlags_MenuBar);
    if (!window_contents_visible)
    {
        BBZGUI::End();
        return;
    }

    // Menu
    if (BBZGUI::BeginMenuBar())
    {
        if (BBZGUI::BeginMenu("File"))
        {
            int open_count = 0;
            for (MyDocument& doc : app.Documents)
                open_count += doc.Open ? 1 : 0;

            if (BBZGUI::BeginMenu("Open", open_count < app.Documents.Size))
            {
                for (MyDocument& doc : app.Documents)
                    if (!doc.Open && BBZGUI::MenuItem(doc.Name))
                        doc.DoOpen();
                BBZGUI::EndMenu();
            }
            if (BBZGUI::MenuItem("Close All Documents", NULL, false, open_count > 0))
                for (MyDocument& doc : app.Documents)
                    app.CloseQueue.push_back(&doc);
            if (BBZGUI::MenuItem("Exit") && p_open)
                *p_open = false;
            BBZGUI::EndMenu();
        }
        BBZGUI::EndMenuBar();
    }

    // [Debug] List documents with one checkbox for each
    for (int doc_n = 0; doc_n < app.Documents.Size; doc_n++)
    {
        MyDocument& doc = app.Documents[doc_n];
        if (doc_n > 0)
            BBZGUI::SameLine();
        BBZGUI::PushID(&doc);
        if (BBZGUI::Checkbox(doc.Name, &doc.Open))
            if (!doc.Open)
                doc.DoForceClose();
        BBZGUI::PopID();
    }

    BBZGUI::Separator();

    // About the BBZGUIWindowFlags_UnsavedDocument / BBZGUITabItemFlags_UnsavedDocument flags.
    // They have multiple effects:
    // - Display a dot next to the title.
    // - Tab is selected when clicking the X close button.
    // - Closure is not assumed (will wait for user to stop submitting the tab).
    //   Otherwise closure is assumed when pressing the X, so if you keep submitting the tab may reappear at end of tab bar.
    //   We need to assume closure by default otherwise waiting for "lack of submission" on the next frame would leave an empty
    //   hole for one-frame, both in the tab-bar and in tab-contents when closing a tab/window.
    //   The rarely used SetTabItemClosed() function is a way to notify of programmatic closure to avoid the one-frame hole.

    // Submit Tab Bar and Tabs
    {
        BBZGUITabBarFlags tab_bar_flags = (opt_fitting_flags) | (opt_reorderable ? BBZGUITabBarFlags_Reorderable : 0);
        tab_bar_flags |= BBZGUITabBarFlags_DrawSelectedOverline;
        if (BBZGUI::BeginTabBar("##tabs", tab_bar_flags))
        {
            if (opt_reorderable)
                app.NotifyOfDocumentsClosedElsewhere();

            // [DEBUG] Stress tests
            //if ((BBZGUI::GetFrameCount() % 30) == 0) docs[1].Open ^= 1;            // [DEBUG] Automatically show/hide a tab. Test various interactions e.g. dragging with this on.
            //if (BBZGUI::GetIO().KeyCtrl) BBZGUI::SetTabItemSelected(docs[1].Name);  // [DEBUG] Test SetTabItemSelected(), probably not very useful as-is anyway..

            // Submit Tabs
            for (MyDocument& doc : app.Documents)
            {
                if (!doc.Open)
                    continue;

                // As we allow to change document name, we append a never-changing document id so tabs are stable
                char doc_name_buf[64];
                app.GetTabName(&doc, doc_name_buf, sizeof(doc_name_buf));
                BBZGUITabItemFlags tab_flags = (doc.Dirty ? BBZGUITabItemFlags_UnsavedDocument : 0);
                bool visible = BBZGUI::BeginTabItem(doc_name_buf, &doc.Open, tab_flags);

                // Cancel attempt to close when unsaved add to save queue so we can display a popup.
                if (!doc.Open && doc.Dirty)
                {
                    doc.Open = true;
                    app.CloseQueue.push_back(&doc);
                }

                app.DisplayDocContextMenu(&doc);
                if (visible)
                {
                    app.DisplayDocContents(&doc);
                    BBZGUI::EndTabItem();
                }
            }

            BBZGUI::EndTabBar();
        }
    }

    // Display renaming UI
    if (app.RenamingDoc != NULL)
    {
        if (app.RenamingStarted)
            BBZGUI::OpenPopup("Rename");
        if (BBZGUI::BeginPopup("Rename"))
        {
            BBZGUI::SetNextItemWidth(BBZGUI::GetFontSize() * 30);
            if (BBZGUI::InputText("###Name", app.RenamingDoc->Name, IM_ARRAYSIZE(app.RenamingDoc->Name), BBZGUIInputTextFlags_EnterReturnsTrue))
            {
                BBZGUI::CloseCurrentPopup();
                app.RenamingDoc = NULL;
            }
            if (app.RenamingStarted)
                BBZGUI::SetKeyboardFocusHere(-1);
            BBZGUI::EndPopup();
        }
        else
        {
            app.RenamingDoc = NULL;
        }
        app.RenamingStarted = false;
    }

    // Display closing confirmation UI
    if (!app.CloseQueue.empty())
    {
        int close_queue_unsaved_documents = 0;
        for (int n = 0; n < app.CloseQueue.Size; n++)
            if (app.CloseQueue[n]->Dirty)
                close_queue_unsaved_documents++;

        if (close_queue_unsaved_documents == 0)
        {
            // Close documents when all are unsaved
            for (int n = 0; n < app.CloseQueue.Size; n++)
                app.CloseQueue[n]->DoForceClose();
            app.CloseQueue.clear();
        }
        else
        {
            if (!BBZGUI::IsPopupOpen("Save?"))
                BBZGUI::OpenPopup("Save?");
            if (BBZGUI::BeginPopupModal("Save?", NULL, BBZGUIWindowFlags_AlwaysAutoResize))
            {
                BBZGUI::Text("Save change to the following items?");
                float item_height = BBZGUI::GetTextLineHeightWithSpacing();
                if (BBZGUI::BeginChild(BBZGUI::GetID("frame"), ImVec2(-FLT_MIN, 6.25f * item_height), BBZGUIChildFlags_FrameStyle))
                    for (MyDocument* doc : app.CloseQueue)
                        if (doc->Dirty)
                            BBZGUI::Text("%s", doc->Name);
                BBZGUI::EndChild();

                ImVec2 button_size(BBZGUI::GetFontSize() * 7.0f, 0.0f);
                if (BBZGUI::Button("Yes", button_size))
                {
                    for (MyDocument* doc : app.CloseQueue)
                    {
                        if (doc->Dirty)
                            doc->DoSave();
                        doc->DoForceClose();
                    }
                    app.CloseQueue.clear();
                    BBZGUI::CloseCurrentPopup();
                }
                BBZGUI::SameLine();
                if (BBZGUI::Button("No", button_size))
                {
                    for (MyDocument* doc : app.CloseQueue)
                        doc->DoForceClose();
                    app.CloseQueue.clear();
                    BBZGUI::CloseCurrentPopup();
                }
                BBZGUI::SameLine();
                if (BBZGUI::Button("Cancel", button_size))
                {
                    app.CloseQueue.clear();
                    BBZGUI::CloseCurrentPopup();
                }
                BBZGUI::EndPopup();
            }
        }
    }

    BBZGUI::End();
}

//-----------------------------------------------------------------------------
// [SECTION] Example App: Assets Browser / ShowExampleAppAssetsBrowser()
//-----------------------------------------------------------------------------

//#include "BBZGui_internal.h" // NavMoveRequestTryWrapping()

struct ExampleAsset
{
    BBZGUIID ID;
    int     Type;

    ExampleAsset(BBZGUIID id, int type) { ID = id; Type = type; }

    static const BBZGUITableSortSpecs* s_current_sort_specs;

    static void SortWithSortSpecs(BBZGUITableSortSpecs* sort_specs, ExampleAsset* items, int items_count)
    {
        s_current_sort_specs = sort_specs; // Store in variable accessible by the sort function.
        if (items_count > 1)
            qsort(items, (size_t)items_count, sizeof(items[0]), ExampleAsset::CompareWithSortSpecs);
        s_current_sort_specs = NULL;
    }

    // Compare function to be used by qsort()
    static int IMGUI_CDECL CompareWithSortSpecs(const void* lhs, const void* rhs)
    {
        const ExampleAsset* a = (const ExampleAsset*)lhs;
        const ExampleAsset* b = (const ExampleAsset*)rhs;
        for (int n = 0; n < s_current_sort_specs->SpecsCount; n++)
        {
            const BBZGUITableColumnSortSpecs* sort_spec = &s_current_sort_specs->Specs[n];
            int delta = 0;
            if (sort_spec->ColumnIndex == 0)
                delta = ((int)a->ID - (int)b->ID);
            else if (sort_spec->ColumnIndex == 1)
                delta = (a->Type - b->Type);
            if (delta > 0)
                return (sort_spec->SortDirection == BBZGUISortDirection_Ascending) ? +1 : -1;
            if (delta < 0)
                return (sort_spec->SortDirection == BBZGUISortDirection_Ascending) ? -1 : +1;
        }
        return ((int)a->ID - (int)b->ID);
    }
};
const BBZGUITableSortSpecs* ExampleAsset::s_current_sort_specs = NULL;

struct ExampleAssetsBrowser
{
    // Options
    bool            ShowTypeOverlay = true;
    bool            AllowSorting = true;
    bool            AllowDragUnselected = false;
    bool            AllowBoxSelect = true;
    float           IconSize = 32.0f;
    int             IconSpacing = 10;
    int             IconHitSpacing = 4;         // Increase hit-spacing if you want to make it possible to clear or box-select from gaps. Some spacing is required to able to amend with Shift+box-select. Value is small in Explorer.
    bool            StretchSpacing = true;

    // State
    ImVector<ExampleAsset> Items;               // Our items
    ExampleSelectionWithDeletion Selection;     // Our selection (BBZGUISelectionBasicStorage + helper funcs to handle deletion)
    BBZGUIID         NextItemId = 0;             // Unique identifier when creating new items
    bool            RequestDelete = false;      // Deferred deletion request
    bool            RequestSort = false;        // Deferred sort request
    float           ZoomWheelAccum = 0.0f;      // Mouse wheel accumulator to handle smooth wheels better

    // Calculated sizes for layout, output of UpdateLayoutSizes(). Could be locals but our code is simpler this way.
    ImVec2          LayoutItemSize;
    ImVec2          LayoutItemStep;             // == LayoutItemSize + LayoutItemSpacing
    float           LayoutItemSpacing = 0.0f;
    float           LayoutSelectableSpacing = 0.0f;
    float           LayoutOuterPadding = 0.0f;
    int             LayoutColumnCount = 0;
    int             LayoutLineCount = 0;

    // Functions
    ExampleAssetsBrowser()
    {
        AddItems(10000);
    }
    void AddItems(int count)
    {
        if (Items.Size == 0)
            NextItemId = 0;
        Items.reserve(Items.Size + count);
        for (int n = 0; n < count; n++, NextItemId++)
            Items.push_back(ExampleAsset(NextItemId, (NextItemId % 20) < 15 ? 0 : (NextItemId % 20) < 18 ? 1 : 2));
        RequestSort = true;
    }
    void ClearItems()
    {
        Items.clear();
        Selection.Clear();
    }

    // Logic would be written in the main code BeginChild() and outputing to local variables.
    // We extracted it into a function so we can call it easily from multiple places.
    void UpdateLayoutSizes(float avail_width)
    {
        // Layout: when not stretching: allow extending into right-most spacing.
        LayoutItemSpacing = (float)IconSpacing;
        if (StretchSpacing == false)
            avail_width += floorf(LayoutItemSpacing * 0.5f);

        // Layout: calculate number of icon per line and number of lines
        LayoutItemSize = ImVec2(floorf(IconSize), floorf(IconSize));
        LayoutColumnCount = IM_MAX((int)(avail_width / (LayoutItemSize.x + LayoutItemSpacing)), 1);
        LayoutLineCount = (Items.Size + LayoutColumnCount - 1) / LayoutColumnCount;

        // Layout: when stretching: allocate remaining space to more spacing. Round before division, so item_spacing may be non-integer.
        if (StretchSpacing && LayoutColumnCount > 1)
            LayoutItemSpacing = floorf(avail_width - LayoutItemSize.x * LayoutColumnCount) / LayoutColumnCount;

        LayoutItemStep = ImVec2(LayoutItemSize.x + LayoutItemSpacing, LayoutItemSize.y + LayoutItemSpacing);
        LayoutSelectableSpacing = IM_MAX(floorf(LayoutItemSpacing) - IconHitSpacing, 0.0f);
        LayoutOuterPadding = floorf(LayoutItemSpacing * 0.5f);
    }

    void Draw(const char* title, bool* p_open)
    {
        BBZGUI::SetNextWindowSize(ImVec2(IconSize * 25, IconSize * 15), BBZGUICond_FirstUseEver);
        if (!BBZGUI::Begin(title, p_open, BBZGUIWindowFlags_MenuBar))
        {
            BBZGUI::End();
            return;
        }

        // Menu bar
        if (BBZGUI::BeginMenuBar())
        {
            if (BBZGUI::BeginMenu("File"))
            {
                if (BBZGUI::MenuItem("Add 10000 items"))
                    AddItems(10000);
                if (BBZGUI::MenuItem("Clear items"))
                    ClearItems();
                BBZGUI::Separator();
                if (BBZGUI::MenuItem("Close", NULL, false, p_open != NULL))
                    *p_open = false;
                BBZGUI::EndMenu();
            }
            if (BBZGUI::BeginMenu("Edit"))
            {
                if (BBZGUI::MenuItem("Delete", "Del", false, Selection.Size > 0))
                    RequestDelete = true;
                BBZGUI::EndMenu();
            }
            if (BBZGUI::BeginMenu("Options"))
            {
                BBZGUI::PushItemWidth(BBZGUI::GetFontSize() * 10);

                BBZGUI::SeparatorText("Contents");
                BBZGUI::Checkbox("Show Type Overlay", &ShowTypeOverlay);
                BBZGUI::Checkbox("Allow Sorting", &AllowSorting);

                BBZGUI::SeparatorText("Selection Behavior");
                BBZGUI::Checkbox("Allow dragging unselected item", &AllowDragUnselected);
                BBZGUI::Checkbox("Allow box-selection", &AllowBoxSelect);

                BBZGUI::SeparatorText("Layout");
                BBZGUI::SliderFloat("Icon Size", &IconSize, 16.0f, 128.0f, "%.0f");
                BBZGUI::SameLine(); HelpMarker("Use CTRL+Wheel to zoom");
                BBZGUI::SliderInt("Icon Spacing", &IconSpacing, 0, 32);
                BBZGUI::SliderInt("Icon Hit Spacing", &IconHitSpacing, 0, 32);
                BBZGUI::Checkbox("Stretch Spacing", &StretchSpacing);
                BBZGUI::PopItemWidth();
                BBZGUI::EndMenu();
            }
            BBZGUI::EndMenuBar();
        }

        // Show a table with ONLY one header row to showcase the idea/possibility of using this to provide a sorting UI
        if (AllowSorting)
        {
            BBZGUI::PushStyleVar(BBZGUIStyleVar_ItemSpacing, ImVec2(0, 0));
            BBZGUITableFlags table_flags_for_sort_specs = BBZGUITableFlags_Sortable | BBZGUITableFlags_SortMulti | BBZGUITableFlags_SizingFixedFit | BBZGUITableFlags_Borders;
            if (BBZGUI::BeginTable("for_sort_specs_only", 2, table_flags_for_sort_specs, ImVec2(0.0f, BBZGUI::GetFrameHeight())))
            {
                BBZGUI::TableSetupColumn("Index");
                BBZGUI::TableSetupColumn("Type");
                BBZGUI::TableHeadersRow();
                if (BBZGUITableSortSpecs* sort_specs = BBZGUI::TableGetSortSpecs())
                    if (sort_specs->SpecsDirty || RequestSort)
                    {
                        ExampleAsset::SortWithSortSpecs(sort_specs, Items.Data, Items.Size);
                        sort_specs->SpecsDirty = RequestSort = false;
                    }
                BBZGUI::EndTable();
            }
            BBZGUI::PopStyleVar();
        }

        BBZGUIIO& io = BBZGUI::GetIO();
        BBZGUI::SetNextWindowContentSize(ImVec2(0.0f, LayoutOuterPadding + LayoutLineCount * (LayoutItemSize.x + LayoutItemSpacing)));
        if (BBZGUI::BeginChild("Assets", ImVec2(0.0f, -BBZGUI::GetTextLineHeightWithSpacing()), BBZGUIChildFlags_Borders, BBZGUIWindowFlags_NoMove))
        {
            ImDrawList* draw_list = BBZGUI::GetWindowDrawList();

            const float avail_width = BBZGUI::GetContentRegionAvail().x;
            UpdateLayoutSizes(avail_width);

            // Calculate and store start position.
            ImVec2 start_pos = BBZGUI::GetCursorScreenPos();
            start_pos = ImVec2(start_pos.x + LayoutOuterPadding, start_pos.y + LayoutOuterPadding);
            BBZGUI::SetCursorScreenPos(start_pos);

            // Multi-select
            BBZGUIMultiSelectFlags ms_flags = BBZGUIMultiSelectFlags_ClearOnEscape | BBZGUIMultiSelectFlags_ClearOnClickVoid;

            // - Enable box-select (in 2D mode, so that changing box-select rectangle X1/X2 boundaries will affect clipped items)
            if (AllowBoxSelect)
                ms_flags |= BBZGUIMultiSelectFlags_BoxSelect2d;

            // - This feature allows dragging an unselected item without selecting it (rarely used)
            if (AllowDragUnselected)
                ms_flags |= BBZGUIMultiSelectFlags_SelectOnClickRelease;

            // - Enable keyboard wrapping on X axis
            // (FIXME-MULTISELECT: We haven't designed/exposed a general nav wrapping api yet, so this flag is provided as a courtesy to avoid doing:
            //    BBZGUI::NavMoveRequestTryWrapping(BBZGUI::GetCurrentWindow(), BBZGUINavMoveFlags_WrapX);
            // When we finish implementing a more general API for this, we will obsolete this flag in favor of the new system)
            ms_flags |= BBZGUIMultiSelectFlags_NavWrapX;

            BBZGUIMultiSelectIO* ms_io = BBZGUI::BeginMultiSelect(ms_flags, Selection.Size, Items.Size);

            // Use custom selection adapter: store ID in selection (recommended)
            Selection.UserData = this;
            Selection.AdapterIndexToStorageId = [](BBZGUISelectionBasicStorage* self_, int idx) { ExampleAssetsBrowser* self = (ExampleAssetsBrowser*)self_->UserData; return self->Items[idx].ID; };
            Selection.ApplyRequests(ms_io);

            const bool want_delete = (BBZGUI::Shortcut(BBZGUIKey_Delete, BBZGUIInputFlags_Repeat) && (Selection.Size > 0)) || RequestDelete;
            const int item_curr_idx_to_focus = want_delete ? Selection.ApplyDeletionPreLoop(ms_io, Items.Size) : -1;
            RequestDelete = false;

            // Push LayoutSelectableSpacing (which is LayoutItemSpacing minus hit-spacing, if we decide to have hit gaps between items)
            // Altering style ItemSpacing may seem unnecessary as we position every items using SetCursorScreenPos()...
            // But it is necessary for two reasons:
            // - Selectables uses it by default to visually fill the space between two items.
            // - The vertical spacing would be measured by Clipper to calculate line height if we didn't provide it explicitly (here we do).
            BBZGUI::PushStyleVar(BBZGUIStyleVar_ItemSpacing, ImVec2(LayoutSelectableSpacing, LayoutSelectableSpacing));

            // Rendering parameters
            const ImU32 icon_type_overlay_colors[3] = { 0, IM_COL32(200, 70, 70, 255), IM_COL32(70, 170, 70, 255) };
            const ImU32 icon_bg_color = BBZGUI::GetColorU32(IM_COL32(35, 35, 35, 220));
            const ImVec2 icon_type_overlay_size = ImVec2(4.0f, 4.0f);
            const bool display_label = (LayoutItemSize.x >= BBZGUI::CalcTextSize("999").x);

            const int column_count = LayoutColumnCount;
            BBZGUIListClipper clipper;
            clipper.Begin(LayoutLineCount, LayoutItemStep.y);
            if (item_curr_idx_to_focus != -1)
                clipper.IncludeItemByIndex(item_curr_idx_to_focus / column_count); // Ensure focused item line is not clipped.
            if (ms_io->RangeSrcItem != -1)
                clipper.IncludeItemByIndex((int)ms_io->RangeSrcItem / column_count); // Ensure RangeSrc item line is not clipped.
            while (clipper.Step())
            {
                for (int line_idx = clipper.DisplayStart; line_idx < clipper.DisplayEnd; line_idx++)
                {
                    const int item_min_idx_for_current_line = line_idx * column_count;
                    const int item_max_idx_for_current_line = IM_MIN((line_idx + 1) * column_count, Items.Size);
                    for (int item_idx = item_min_idx_for_current_line; item_idx < item_max_idx_for_current_line; ++item_idx)
                    {
                        ExampleAsset* item_data = &Items[item_idx];
                        BBZGUI::PushID((int)item_data->ID);

                        // Position item
                        ImVec2 pos = ImVec2(start_pos.x + (item_idx % column_count) * LayoutItemStep.x, start_pos.y + line_idx * LayoutItemStep.y);
                        BBZGUI::SetCursorScreenPos(pos);

                        BBZGUI::SetNextItemSelectionUserData(item_idx);
                        bool item_is_selected = Selection.Contains((BBZGUIID)item_data->ID);
                        bool item_is_visible = BBZGUI::IsRectVisible(LayoutItemSize);
                        BBZGUI::Selectable("", item_is_selected, BBZGUISelectableFlags_None, LayoutItemSize);

                        // Update our selection state immediately (without waiting for EndMultiSelect() requests)
                        // because we use this to alter the color of our text/icon.
                        if (BBZGUI::IsItemToggledSelection())
                            item_is_selected = !item_is_selected;

                        // Focus (for after deletion)
                        if (item_curr_idx_to_focus == item_idx)
                            BBZGUI::SetKeyboardFocusHere(-1);

                        // Drag and drop
                        if (BBZGUI::BeginDragDropSource())
                        {
                            // Create payload with full selection OR single unselected item.
                            // (the later is only possible when using BBZGUIMultiSelectFlags_SelectOnClickRelease)
                            if (BBZGUI::GetDragDropPayload() == NULL)
                            {
                                ImVector<BBZGUIID> payload_items;
                                void* it = NULL;
                                BBZGUIID id = 0;
                                if (!item_is_selected)
                                    payload_items.push_back(item_data->ID);
                                else
                                    while (Selection.GetNextSelectedItem(&it, &id))
                                        payload_items.push_back(id);
                                BBZGUI::SetDragDropPayload("ASSETS_BROWSER_ITEMS", payload_items.Data, (size_t)payload_items.size_in_bytes());
                            }

                            // Display payload content in tooltip, by extracting it from the payload data
                            // (we could read from selection, but it is more correct and reusable to read from payload)
                            const BBZGUIPayload* payload = BBZGUI::GetDragDropPayload();
                            const int payload_count = (int)payload->DataSize / (int)sizeof(BBZGUIID);
                            BBZGUI::Text("%d assets", payload_count);

                            BBZGUI::EndDragDropSource();
                        }

                        // Render icon (a real app would likely display an image/thumbnail here)
                        // Because we use BBZGUIMultiSelectFlags_BoxSelect2d, clipping vertical may occasionally be larger, so we coarse-clip our rendering as well.
                        if (item_is_visible)
                        {
                            ImVec2 box_min(pos.x - 1, pos.y - 1);
                            ImVec2 box_max(box_min.x + LayoutItemSize.x + 2, box_min.y + LayoutItemSize.y + 2); // Dubious
                            draw_list->AddRectFilled(box_min, box_max, icon_bg_color); // Background color
                            if (ShowTypeOverlay && item_data->Type != 0)
                            {
                                ImU32 type_col = icon_type_overlay_colors[item_data->Type % IM_ARRAYSIZE(icon_type_overlay_colors)];
                                draw_list->AddRectFilled(ImVec2(box_max.x - 2 - icon_type_overlay_size.x, box_min.y + 2), ImVec2(box_max.x - 2, box_min.y + 2 + icon_type_overlay_size.y), type_col);
                            }
                            if (display_label)
                            {
                                ImU32 label_col = BBZGUI::GetColorU32(item_is_selected ? BBZGUICol_Text : BBZGUICol_TextDisabled);
                                char label[32];
                                sprintf(label, "%d", item_data->ID);
                                draw_list->AddText(ImVec2(box_min.x, box_max.y - BBZGUI::GetFontSize()), label_col, label);
                            }
                        }

                        BBZGUI::PopID();
                    }
                }
            }
            clipper.End();
            BBZGUI::PopStyleVar(); // BBZGUIStyleVar_ItemSpacing

            // Context menu
            if (BBZGUI::BeginPopupContextWindow())
            {
                BBZGUI::Text("Selection: %d items", Selection.Size);
                BBZGUI::Separator();
                if (BBZGUI::MenuItem("Delete", "Del", false, Selection.Size > 0))
                    RequestDelete = true;
                BBZGUI::EndPopup();
            }

            ms_io = BBZGUI::EndMultiSelect();
            Selection.ApplyRequests(ms_io);
            if (want_delete)
                Selection.ApplyDeletionPostLoop(ms_io, Items, item_curr_idx_to_focus);

            // Zooming with CTRL+Wheel
            if (BBZGUI::IsWindowAppearing())
                ZoomWheelAccum = 0.0f;
            if (BBZGUI::IsWindowHovered() && io.MouseWheel != 0.0f && BBZGUI::IsKeyDown(BBZGUIMod_Ctrl) && BBZGUI::IsAnyItemActive() == false)
            {
                ZoomWheelAccum += io.MouseWheel;
                if (fabsf(ZoomWheelAccum) >= 1.0f)
                {
                    // Calculate hovered item index from mouse location
                    // FIXME: Locking aiming on 'hovered_item_idx' (with a cool-down timer) would ensure zoom keeps on it.
                    const float hovered_item_nx = (io.MousePos.x - start_pos.x + LayoutItemSpacing * 0.5f) / LayoutItemStep.x;
                    const float hovered_item_ny = (io.MousePos.y - start_pos.y + LayoutItemSpacing * 0.5f) / LayoutItemStep.y;
                    const int hovered_item_idx = ((int)hovered_item_ny * LayoutColumnCount) + (int)hovered_item_nx;
                    //BBZGUI::SetTooltip("%f,%f -> item %d", hovered_item_nx, hovered_item_ny, hovered_item_idx); // Move those 4 lines in block above for easy debugging

                    // Zoom
                    IconSize *= powf(1.1f, (float)(int)ZoomWheelAccum);
                    IconSize = IM_CLAMP(IconSize, 16.0f, 128.0f);
                    ZoomWheelAccum -= (int)ZoomWheelAccum;
                    UpdateLayoutSizes(avail_width);

                    // Manipulate scroll to that we will land at the same Y location of currently hovered item.
                    // - Calculate next frame position of item under mouse
                    // - Set new scroll position to be used in next BBZGUI::BeginChild() call.
                    float hovered_item_rel_pos_y = ((float)(hovered_item_idx / LayoutColumnCount) + fmodf(hovered_item_ny, 1.0f)) * LayoutItemStep.y;
                    hovered_item_rel_pos_y += BBZGUI::GetStyle().WindowPadding.y;
                    float mouse_local_y = io.MousePos.y - BBZGUI::GetWindowPos().y;
                    BBZGUI::SetScrollY(hovered_item_rel_pos_y - mouse_local_y);
                }
            }
        }
        BBZGUI::EndChild();

        BBZGUI::Text("Selected: %d/%d items", Selection.Size, Items.Size);
        BBZGUI::End();
    }
};

void ShowExampleAppAssetsBrowser(bool* p_open)
{
    IMGUI_DEMO_MARKER("Examples/Assets Browser");
    static ExampleAssetsBrowser assets_browser;
    assets_browser.Draw("Example: Assets Browser", p_open);
}

// End of Demo code
#else

void BBZGUI::ShowAboutWindow(bool*) {}
void BBZGUI::ShowDemoWindow(bool*) {}
void BBZGUI::ShowUserGuide() {}
void BBZGUI::ShowStyleEditor(BBZGUIStyle*) {}

#endif

#endif // #ifndef IMGUI_DISABLE
