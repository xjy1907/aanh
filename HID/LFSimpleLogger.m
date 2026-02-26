
#import "LFSimpleLogger.h"
#import <UIKit/UIKit.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

NSNotificationName const LFSimpleLoggerDidAppendNotification = @"LFSimpleLoggerDidAppendNotification";

#pragma mark - 共享日志路径（固定为 /var/tmp/lf_shared.log）

/// 固定共享日志路径；保证文件存在（避免读端首次 open 失败）
/// 读端/写端都约定使用这个路径实现“跨进程共享”
static inline NSString *LFSharedLogResolvedPath(void) {
    NSString *path = @"/var/tmp/lf_shared.log";
    // 创建文件（若不存在），权限 0644
    int fd = open(path.fileSystemRepresentation, O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (fd >= 0) close(fd);
    return path;
}

#pragma mark - LFSimpleLogger

@interface LFSimpleLogger () {
    dispatch_queue_t _q;
    NSMutableArray<NSString *> *_lines;
    NSUInteger _maxLines;

    // tailing（文件）
    int _sharedFD;                     // 只读 FD
    dispatch_source_t _vnodeSrc;       // VNODE 事件源
    dispatch_source_t _pollTimer;      // 兜底轮询定时器
    NSMutableData *_sharedBuf;         // 行缓冲
    NSString *_currentTailedPath;
    off_t _tailOffset;                 // 已读偏移
}
@property (nonatomic, strong) NSDateFormatter *tsFormatter;
@end

@implementation LFSimpleLogger

+ (instancetype)shared {
    static LFSimpleLogger *x;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ x = [self new]; });
    return x;
}

- (instancetype)init {
    if ((self = [super init])) {
        _q = dispatch_queue_create("lf.logger.q", DISPATCH_QUEUE_SERIAL);
        _lines = [NSMutableArray array];
        _maxLines = 2000;

        // 时间戳格式器（主线程创建一次即可）
        _tsFormatter = [NSDateFormatter new];
        _tsFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";

        // 跟随共享日志文件（固定 /var/tmp/lf_shared.log）
        [self startTailingSharedFile];
    }
    return self;
}

- (void)dealloc {
    [self stopTailing];
}

#pragma mark - App 本地日志路径（保留原样，用于本地显示/导出等）

static inline NSString *LFLogFilePath(void) {
    NSString *dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [dir stringByAppendingPathComponent:@"app.log"];
}

#pragma mark - Tail 实现（VNODE + 轮询 + offset）

/// 从当前 _tailOffset 读取新增字节并按行吐出
- (void)_drainNewBytesFromFD:(int)fd buffer:(NSMutableData *)buf {
    if (fd < 0) return;

    struct stat st = {0};
    if (fstat(fd, &st) != 0) return;

    // 文件被截断/替换
    if (st.st_size < _tailOffset) {
        _tailOffset = lseek(fd, 0, SEEK_END);
        return;
    }

    off_t want = st.st_size - _tailOffset;
    if (want <= 0) return;

    const size_t kChunk = 16 * 1024;
    uint8_t tmp[kChunk];
    off_t remaining = want;

    while (remaining > 0) {
        size_t nToRead = (size_t)MIN((off_t)kChunk, remaining);
        ssize_t n = pread(fd, tmp, nToRead, _tailOffset);
        if (n <= 0) break;
        [buf appendBytes:tmp length:(NSUInteger)n];
        _tailOffset += n;
        remaining -= n;

        // 以 '\n' 切行
        while (true) {
            const void *bytes = buf.bytes; NSUInteger len = buf.length;
            const void *nl = memchr(bytes, '\n', len);
            if (!nl) break;
            NSUInteger L = (const uint8_t*)nl - (const uint8_t*)bytes;
            NSData *lineData = [buf subdataWithRange:NSMakeRange(0, L)];
            [buf replaceBytesInRange:NSMakeRange(0, L+1) withBytes:NULL length:0];

            NSString *line = [[NSString alloc] initWithData:lineData encoding:NSUTF8StringEncoding];
            if (!line) line = [[NSString alloc] initWithData:lineData encoding:NSASCIIStringEncoding];
            if (!line) line = @" ";
            [self logLine:line];
        }
    }
}

/// 开始 tail 共享日志文件（只读，不创建）
- (void)startTailingSharedFile {
    if (_vnodeSrc || _pollTimer) return;
    _sharedBuf = [NSMutableData data];

    NSString *sharedPath = LFSharedLogResolvedPath(); // 固定路径，已确保存在
    // 只读打开，避免读端“制造一个没人写的新文件”
    _sharedFD = open(sharedPath.fileSystemRepresentation, O_RDONLY);
    if (_sharedFD < 0) {
        [self logLine:[NSString stringWithFormat:@"[tail] 打开失败(%@)：%s", sharedPath, strerror(errno)]];
        return;
    }
    _currentTailedPath = sharedPath;

    // 只看新增（若想加载历史，把这行改成 _tailOffset = 0; 并立刻 _drainNewBytesFromFD 一次）
    // ===== 预读历史（只取最后 256KB）=====
    struct stat st = {0};
    fstat(_sharedFD, &st);
    const off_t maxPreload = 256 * 1024; // 256KB
    off_t start = 0;
    if (st.st_size > maxPreload) {
        start = st.st_size - maxPreload;
    }
    // 从 start 位置把历史拉进来
    _tailOffset = start;
    [self _drainNewBytesFromFD:_sharedFD buffer:_sharedBuf]; // 这次会把 [start, file_end] 的所有完整行推给 UI

    // ===== 之后进入增量 tail 模式 =====
    _tailOffset = lseek(_sharedFD, 0, SEEK_END);

    dispatch_queue_t q = dispatch_queue_create("lf.shared.tail.q", DISPATCH_QUEUE_SERIAL);

    // VNODE 源：应对日志写入/扩展/删除/重命名/属性变化
    int vfd = open(sharedPath.fileSystemRepresentation, O_EVTONLY);
    if (vfd >= 0) {
        _vnodeSrc = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                           vfd,
                                           DISPATCH_VNODE_DELETE |
                                           DISPATCH_VNODE_RENAME |
                                           DISPATCH_VNODE_WRITE  |
                                           DISPATCH_VNODE_EXTEND |
                                           DISPATCH_VNODE_ATTRIB,
                                           q);
        __weak typeof(self) ws = self;
        dispatch_source_set_event_handler(_vnodeSrc, ^{
            __strong typeof(self) self = ws; if (!self) return;
            unsigned long mask = dispatch_source_get_data(self->_vnodeSrc);

            if (mask & (DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND)) {
                [self _drainNewBytesFromFD:self->_sharedFD buffer:self->_sharedBuf];
            }
            if (mask & (DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME)) {
                [self logLine:@"[tail] 文件被删除/重命名，重连..."];
                [self restartTailing];
            }
        });
        dispatch_source_set_cancel_handler(_vnodeSrc, ^{ close(vfd); });
        dispatch_resume(_vnodeSrc);
    }

    // 兜底轮询：极个别场景 VNODE 不触发，这里每 300ms 拉一次
    _pollTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, q);
    dispatch_source_set_timer(_pollTimer,
                              dispatch_time(DISPATCH_TIME_NOW, 0),
                              (uint64_t)(0.30 * NSEC_PER_SEC),
                              (uint64_t)(0.05 * NSEC_PER_SEC));
    __weak typeof(self) ws2 = self;
    dispatch_source_set_event_handler(_pollTimer, ^{
        __strong typeof(self) self = ws2; if (!self) return;
        [self _drainNewBytesFromFD:self->_sharedFD buffer:self->_sharedBuf];
    });
    dispatch_resume(_pollTimer);

    [self logLine:[NSString stringWithFormat:@"[tail] 正在跟随：%@（offset=%lld）", sharedPath, (long long)_tailOffset]];
}

- (void)stopTailing {
    if (_vnodeSrc)  { dispatch_source_cancel(_vnodeSrc);  _vnodeSrc  = nil; }
    if (_pollTimer) { dispatch_source_cancel(_pollTimer); _pollTimer = nil; }
    if (_sharedFD >= 0) { close(_sharedFD); _sharedFD = -1; }
    _currentTailedPath = nil;
    _tailOffset = 0;
}

- (void)restartTailing {
    [self stopTailing];
    // 小延迟避免与 rotate 写入过程打架
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)),
                   dispatch_get_main_queue(), ^{
        [self startTailingSharedFile];
    });
}

#pragma mark - Public APIs

- (void)setMaxLines:(NSUInteger)maxLines {
    if (maxLines == 0) return;
    dispatch_async(_q, ^{
        self->_maxLines = maxLines;
        if (self->_lines.count > maxLines) {
            [self->_lines removeObjectsInRange:NSMakeRange(0, self->_lines.count - self->_maxLines)];
        }
    });
}

- (void)logLine:(NSString *)line {
    if (line.length == 0) return;
    // 生成日志文本
    NSString *full = [NSString stringWithFormat:@"[%@] %@",
                      [self.tsFormatter stringFromDate:[NSDate date]], line];

    // 入队列、裁剪、发通知
    dispatch_async(_q, ^{
        [self->_lines addObject:full];
        if (self->_lines.count > self->_maxLines) {
            [self->_lines removeObjectsInRange:NSMakeRange(0, self->_lines.count - self->_maxLines)];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LFSimpleLoggerDidAppendNotification
                                                                object:nil
                                                              userInfo:@{@"line": full}];
        });
    });
}

- (NSArray<NSString *> *)allLines {
    __block NSArray<NSString *> *snapshot = nil;
    dispatch_sync(_q, ^{
        snapshot = [self->_lines copy];
    });
    return snapshot ?: @[];
}

- (void)clear {
    dispatch_async(_q, ^{
        [self->_lines removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LFSimpleLoggerDidAppendNotification
                                                                object:nil
                                                              userInfo:@{@"clear": @YES}];
        });
    });
}

- (NSURL *)exportToFileWithError:(NSError **)errPtr {
    NSString *txt = [[self allLines] componentsJoinedByString:@"\n"];
    NSDateFormatter *f = [NSDateFormatter new];
    f.dateFormat = @"yyyyMMdd_HHmmss";
    NSString *fn = [NSString stringWithFormat:@"lf_logs_%@.txt", [f stringFromDate:[NSDate date]]];

    NSURL *doc = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                         inDomains:NSUserDomainMask] firstObject];
    NSURL *url = [doc URLByAppendingPathComponent:fn];
    if (![txt writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:errPtr]) {
        return nil;
    }
    return url;
}

@end

// ======================================================================
// ==================  从这里开始是“超好看”的日志 UI  ===================
// ======================================================================

#pragma mark - UI Helpers (colors/fonts/parse)

static inline BOOL LFLineHas(NSString *s, NSString *sub) {
    return [s rangeOfString:sub options:NSCaseInsensitiveSearch].location != NSNotFound;
}

typedef NS_ENUM(NSUInteger, LFLevel) {
    LFLevelAll = 0,
    LFLevelError,
    LFLevelWarn,
    LFLevelInfo,
    LFLevelDebug,
    LFLevelOther
};

static inline LFLevel LFDetectLevel(NSString *line) {
    // 展示行为 "[time] text"
    if (LFLineHas(line, @" ERROR") || LFLineHas(line, @"[ERROR") || LFLineHas(line, @" E ")) return LFLevelError;
    if (LFLineHas(line, @" WARN")  || LFLineHas(line, @"[WARN")  || LFLineHas(line, @" W ")) return LFLevelWarn;
    if (LFLineHas(line, @" INFO")  || LFLineHas(line, @"[INFO")  || LFLineHas(line, @" I ")) return LFLevelInfo;
    if (LFLineHas(line, @" DEBUG") || LFLineHas(line, @"[DEBUG") || LFLineHas(line, @" D ")) return LFLevelDebug;
    return LFLevelOther;
}

static inline UIColor *LFLevelColor(LFLevel lv) {
    switch (lv) {
        case LFLevelError: return [UIColor colorWithRed:0.98 green:0.31 blue:0.31 alpha:1.0]; // 红
        case LFLevelWarn:  return [UIColor colorWithRed:1.00 green:0.73 blue:0.24 alpha:1.0]; // 橙
        case LFLevelInfo:  return [UIColor colorWithRed:0.25 green:0.63 blue:1.00 alpha:1.0]; // 蓝
        case LFLevelDebug: return [UIColor colorWithRed:0.40 green:0.80 blue:0.46 alpha:1.0]; // 绿
        default:           return [UIColor secondaryLabelColor];
    }
}


static inline UIColor *LFCardBgColor(void) {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
        if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithWhite:1.0 alpha:0.06];
        } else {
            return [UIColor colorWithWhite:0.97 alpha:1.0];
        }
    }];
}
static inline UIColor *LFLevelBgColor(LFLevel lv) {
    // 柔和的淡色底，整行高亮
    switch (lv) {
        case LFLevelError: return [UIColor colorWithRed:0.98 green:0.31 blue:0.31 alpha:0.12]; // 红淡
        case LFLevelWarn:  return [UIColor colorWithRed:1.00 green:0.73 blue:0.24 alpha:0.14]; // 橙淡
        case LFLevelInfo:  return [UIColor colorWithRed:0.25 green:0.63 blue:1.00 alpha:0.12]; // 蓝淡
        case LFLevelDebug: return [UIColor colorWithRed:0.40 green:0.80 blue:0.46 alpha:0.12]; // 绿淡
        default:           return LFCardBgColor(); // 默认卡片底
    }
}

static inline UIColor *LFAccentColorForLine(NSString *line) {
    // ✅/❌ 优先级最高
    if ([line containsString:@"❌"]) return [UIColor colorWithRed:0.98 green:0.31 blue:0.31 alpha:1.0];
    if ([line containsString:@"✅"]) return [UIColor colorWithRed:0.20 green:0.72 blue:0.38 alpha:1.0];

    LFLevel lv = LFDetectLevel(line);
    return LFLevelColor(lv);
}

static inline UIColor *LFBackgroundColorForLine(NSString *line) {
    // ✅/❌ 优先级最高（整行底色）
    if ([line containsString:@"❌"]) return [UIColor colorWithRed:0.98 green:0.31 blue:0.31 alpha:0.12];
    if ([line containsString:@"✅"]) return [UIColor colorWithRed:0.20 green:0.72 blue:0.38 alpha:0.12];

    LFLevel lv = LFDetectLevel(line);
    return LFLevelBgColor(lv);
}
static inline UIFont *LFMono(CGFloat size) {
    return [UIFont monospacedSystemFontOfSize:size weight:UIFontWeightRegular];
}

/// 构造带高亮的富文本：时间戳淡色、级别着色、✅/❌ 着色
static inline NSAttributedString *LFPrettyLine(NSString *line) {
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:line
                                                                             attributes:@{
        NSFontAttributeName: LFMono(12),
        NSForegroundColorAttributeName: [UIColor labelColor]
    }];

    NSRange full = NSMakeRange(0, attr.length);

    // 时间戳上色（匹配首个 [xxx]）
    NSRange l = [line rangeOfString:@"["];
    NSRange r = [line rangeOfString:@"]"];
    if (l.location != NSNotFound && r.location != NSNotFound && r.location > l.location) {
        NSRange tsRange = NSMakeRange(l.location, r.location - l.location + 1);
        [attr addAttributes:@{ NSForegroundColorAttributeName: [UIColor secondaryLabelColor] } range:tsRange];
    }

    
    // 替换掉 LFPrettyLine() 中 “级别高亮” 的那段循环
    NSArray<NSString *> *keys = @[@"ERROR", @"WARN", @"INFO", @"DEBUG"];
    for (NSString *k in keys) {
        NSRange rr = [line rangeOfString:k options:NSCaseInsensitiveSearch];
        if (rr.location != NSNotFound) {
            LFLevel lv =
                [k caseInsensitiveCompare:@"ERROR"] == NSOrderedSame ? LFLevelError :
                [k caseInsensitiveCompare:@"WARN"]  == NSOrderedSame ? LFLevelWarn  :
                [k caseInsensitiveCompare:@"INFO"]  == NSOrderedSame ? LFLevelInfo  :
                                                                        LFLevelDebug;
            [attr addAttributes:@{
                NSForegroundColorAttributeName: LFLevelColor(lv),
                NSFontAttributeName: LFMono(12.5)
            } range:rr];
        }
    }

    // ✅/❌ 着色（全行替换所有出现）
    void (^colorAllOccurrences)(NSString *, UIColor *) = ^(NSString *token, UIColor *color){
        NSRange search = NSMakeRange(0, attr.length);
        while (true) {
            NSRange found = [[attr string] rangeOfString:token options:0 range:search];
            if (found.location == NSNotFound) break;
            [attr addAttribute:NSForegroundColorAttributeName value:color range:found];
            NSUInteger nextLoc = found.location + found.length;
            if (nextLoc >= attr.length) break;
            search = NSMakeRange(nextLoc, attr.length - nextLoc);
        }
    };
    colorAllOccurrences(@"❌", [UIColor colorWithRed:0.98 green:0.31 blue:0.31 alpha:1.0]); // 红
    colorAllOccurrences(@"✅", [UIColor colorWithRed:0.20 green:0.72 blue:0.38 alpha:1.0]); // 绿

    // 段落
    NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new];
    ps.lineBreakMode = NSLineBreakByWordWrapping;
    ps.lineSpacing = 2.0;
    [attr addAttribute:NSParagraphStyleAttributeName value:ps range:full];

    return attr;
}

#pragma mark - LFLogCell（卡片气泡）

@interface LFLogCell : UITableViewCell <UIContextMenuInteractionDelegate>
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIView *pill;
@property (nonatomic, strong) UIView *accent; // 左侧强调条
- (void)applyLine:(NSString *)line;
@end

@implementation LFLogCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)rid {
    if ((self = [super initWithStyle:style reuseIdentifier:rid])) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];

        _pill = [UIView new];
        _pill.translatesAutoresizingMaskIntoConstraints = NO;
        _pill.backgroundColor = LFCardBgColor();
        _pill.layer.cornerRadius = 14;
        _pill.layer.masksToBounds = NO;
        _pill.layer.shadowColor = [UIColor blackColor].CGColor;
        _pill.layer.shadowOpacity = 0.08;
        _pill.layer.shadowOffset = CGSizeMake(0, 2);
        _pill.layer.shadowRadius = 6;

        _label = [UILabel new];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        _label.numberOfLines = 0;
        _label.font = LFMono(12);

        [_pill addSubview:_label];
        _accent = [UIView new];
        _accent.translatesAutoresizingMaskIntoConstraints = NO;
        _accent.layer.cornerRadius = 2;
        _accent.layer.masksToBounds = YES;
        [_pill addSubview:_accent];

        [self.contentView addSubview:_pill];

        UILayoutGuide *g = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [_pill.topAnchor constraintEqualToAnchor:g.topAnchor constant:4],
            [_pill.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
            [_pill.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
            [_pill.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-4],
            
            [_accent.leadingAnchor constraintEqualToAnchor:_pill.leadingAnchor],
               [_accent.topAnchor constraintEqualToAnchor:_pill.topAnchor],
               [_accent.bottomAnchor constraintEqualToAnchor:_pill.bottomAnchor],
               [_accent.widthAnchor constraintEqualToConstant:4.0], // 4px 侧边条
            
            [_label.topAnchor constraintEqualToAnchor:_pill.topAnchor constant:10],
            [_label.leadingAnchor constraintEqualToAnchor:_pill.leadingAnchor constant:12],
            [_label.trailingAnchor constraintEqualToAnchor:_pill.trailingAnchor constant:-12],
            [_label.bottomAnchor constraintEqualToAnchor:_pill.bottomAnchor constant:-10],
        ]];

        // 长按复制
        if (@available(iOS 13.0, *)) {
            UIContextMenuInteraction *ctx = [[UIContextMenuInteraction alloc] initWithDelegate:self];
            [_pill addInteraction:ctx];
        }
    }
    return self;
}

- (void)applyLine:(NSString *)line {
    // 富文本（保留你已有 token 高亮：时间戳、ERROR/WARN/INFO/DEBUG、❌/✅）
    _label.attributedText = LFPrettyLine(line);

    // 整行底色 & 侧边条颜色
    UIColor *bg = LFBackgroundColorForLine(line);
    UIColor *accent = LFAccentColorForLine(line);

    _pill.backgroundColor = bg;
    _accent.backgroundColor = accent;

    // 可选：给强调色增加一点点内阴影/边框（让对比更明显）
    _pill.layer.borderColor = [accent colorWithAlphaComponent:0.25].CGColor;
    _pill.layer.borderWidth = ([line containsString:@"❌"] || [line containsString:@"✅"]) ? 0.5 : 0.0;
}

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction
                    configurationForMenuAtLocation:(CGPoint)location API_AVAILABLE(ios(13.0)) {
    __weak typeof(self) ws = self;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        UIAction *copyAct = [UIAction actionWithTitle:@"复制"
                                                image:[UIImage systemImageNamed:@"doc.on.doc"]
                                           identifier:nil
                                              handler:^(__kindof UIAction * _Nonnull action) {
            UIPasteboard.generalPasteboard.string = ws.label.text ?: @"";
        }];
        return [UIMenu menuWithTitle:@"" children:@[copyAct]];
    }];
}
@end

#pragma mark - LFLogsViewController（超好看 UI）

@interface LFLogsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating>
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) UISegmentedControl *levelSeg; // 全部/ERROR/WARN/INFO/DEBUG
@property (nonatomic, strong) UIButton *jumpBtn;            // 快速回底部
@property (nonatomic, assign) BOOL pausedAuto;              // 暂停自动滚动

@property (nonatomic, strong) NSArray<NSString *> *all;     // 原始数据
@property (nonatomic, strong) NSArray<NSString *> *filtered;// 过滤后的数据
@end

@implementation LFLogsViewController {
    UITableView *_table;
    BOOL _autoScroll;
    UIView *_headerContainer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"日志";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    _autoScroll = YES;
    self.pausedAuto = NO;

    // 数据
    self.all = [[LFSimpleLogger shared] allLines];
    self.filtered = self.all;

    // 搜索与过滤
    [self buildHeaderControls];

    // 表格
    _table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    _table.translatesAutoresizingMaskIntoConstraints = NO;
    _table.dataSource = self;
    _table.delegate = self;
    _table.estimatedRowHeight = 64;
    _table.rowHeight = UITableViewAutomaticDimension;
    _table.separatorStyle = UITableViewCellSeparatorStyleNone;
    _table.backgroundColor = [UIColor clearColor];
    [_table registerClass:[LFLogCell class] forCellReuseIdentifier:@"logcell"];
    [self.view addSubview:_table];

    // 表头
    _table.tableHeaderView = _headerContainer;

    // 工具条
    UIToolbar *bar = [self buildToolbar];
    bar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:bar];

    // 悬浮回底部按钮
    [self buildJumpButton];

    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [_table.topAnchor constraintEqualToAnchor:g.topAnchor],
        [_table.leadingAnchor constraintEqualToAnchor:g.leadingAnchor],
        [_table.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],
        [_table.bottomAnchor constraintEqualToAnchor:bar.topAnchor],

        [bar.leadingAnchor constraintEqualToAnchor:g.leadingAnchor],
        [bar.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],
        [bar.bottomAnchor constraintEqualToAnchor:g.bottomAnchor],
    ]];

    // 左上角关闭
    self.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"xmark.circle.fill"]
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(close)];

    // 搜索在导航栏
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;

    // 通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLoggerAppend:)
                                                 name:LFSimpleLoggerDidAppendNotification
                                               object:nil];

    [self scrollToBottomIfNeeded:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 确保表头宽度与高度正确（iOS 8+ 推荐带优先级）
    CGFloat width = self.view.bounds.size.width;
    CGSize fitting = [_headerContainer systemLayoutSizeFittingSize:CGSizeMake(width, CGFLOAT_MAX)
                                 withHorizontalFittingPriority:UILayoutPriorityRequired
                                       verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    if (fabs(_headerContainer.frame.size.height - fitting.height) > 0.5) {
        _headerContainer.frame = (CGRect){.origin=CGPointZero, .size=CGSizeMake(width, fitting.height)};
        _table.tableHeaderView = _headerContainer;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UI builders

- (void)buildHeaderControls {
    // 级别过滤
    self.levelSeg = [[UISegmentedControl alloc] initWithItems:@[@"全部", @"ERROR", @"WARN", @"INFO", @"DEBUG"]];
    self.levelSeg.selectedSegmentIndex = 0;
    [self.levelSeg addTarget:self action:@selector(onLevelChanged:) forControlEvents:UIControlEventValueChanged];
    self.levelSeg.translatesAutoresizingMaskIntoConstraints = NO;

    UIVisualEffectView *bg = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]];
    bg.translatesAutoresizingMaskIntoConstraints = NO;
    bg.layer.cornerRadius = 14;
    bg.layer.masksToBounds = YES;

    UIView *container = [UIView new];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:bg];
    [container addSubview:self.levelSeg];

    UILabel *hint = [UILabel new];
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    hint.text = @"搜索支持关键字/时间/级别（❌ 红色，✅ 绿色）";
    hint.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    hint.textColor = [UIColor secondaryLabelColor];
    [container addSubview:hint];

    [NSLayoutConstraint activateConstraints:@[
        [bg.topAnchor constraintEqualToAnchor:container.topAnchor constant:12],
        [bg.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16],
        [bg.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16],

        [self.levelSeg.topAnchor constraintEqualToAnchor:bg.topAnchor constant:10],
        [self.levelSeg.leadingAnchor constraintEqualToAnchor:bg.leadingAnchor constant:12],
        [self.levelSeg.trailingAnchor constraintEqualToAnchor:bg.trailingAnchor constant:-12],
        [self.levelSeg.bottomAnchor constraintEqualToAnchor:bg.bottomAnchor constant:-10],

        [hint.topAnchor constraintEqualToAnchor:bg.bottomAnchor constant:6],
        [hint.leadingAnchor constraintEqualToAnchor:bg.leadingAnchor],
        [hint.trailingAnchor constraintEqualToAnchor:bg.trailingAnchor],
        [hint.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-8],
    ]];

    _headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 1)];
    [_headerContainer addSubview:container];

    [NSLayoutConstraint activateConstraints:@[
        [container.topAnchor constraintEqualToAnchor:_headerContainer.topAnchor],
        [container.leadingAnchor constraintEqualToAnchor:_headerContainer.leadingAnchor],
        [container.trailingAnchor constraintEqualToAnchor:_headerContainer.trailingAnchor],
        [container.bottomAnchor constraintEqualToAnchor:_headerContainer.bottomAnchor]
    ]];
}

- (UIToolbar *)buildToolbar {
    UIToolbar *bar = [UIToolbar new];

    UIBarButtonItem *pauseItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"pause.fill"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(onToggleAuto)];
    pauseItem.accessibilityLabel = @"暂停/恢复自动滚动";

    UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"trash"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(onClear)];
    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.up"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(onShare)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                             target:nil action:nil];

    [bar setItems:@[pauseItem, flex, clearItem, shareItem]];
    return bar;
}

- (void)buildJumpButton {
    self.jumpBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.jumpBtn.translatesAutoresizingMaskIntoConstraints = NO;
    self.jumpBtn.backgroundColor = [UIColor systemBlueColor];
    [self.jumpBtn setImage:[UIImage systemImageNamed:@"arrow.down.to.line"] forState:UIControlStateNormal];
    self.jumpBtn.tintColor = [UIColor whiteColor];
    self.jumpBtn.layer.cornerRadius = 22;
    self.jumpBtn.contentEdgeInsets = UIEdgeInsetsMake(10, 12, 10, 12);
    self.jumpBtn.alpha = 0.0;
    [self.jumpBtn addTarget:self action:@selector(onJumpBottom) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.jumpBtn];

    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.jumpBtn.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-16],
        [self.jumpBtn.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-72],
        [self.jumpBtn.heightAnchor constraintEqualToConstant:44],
        [self.jumpBtn.widthAnchor constraintEqualToConstant:44],
    ]];
}

#pragma mark - Search

- (UISearchController *)searchController {
    if (_searchController) return _searchController;
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    _searchController.searchBar.placeholder = @"搜索日志（关键字/级别/时间，❌/✅）";
    return _searchController;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self applyFilterAndReload];
}

#pragma mark - Filters

- (void)onLevelChanged:(UISegmentedControl *)seg {
    [self applyFilterAndReload];
}

- (void)applyFilterAndReload {
    NSString *q = self.searchController.searchBar.text ?: @"";
    NSInteger lvIndex = self.levelSeg.selectedSegmentIndex;

    NSArray<NSString *> *src = self.all;
    NSMutableArray<NSString *> *dst = [NSMutableArray arrayWithCapacity:src.count];

    for (NSString *line in src) {
        // 级别过滤
        if (lvIndex != 0) {
            LFLevel need = (LFLevel)lvIndex;
            if (LFDetectLevel(line) != need) continue;
        }
        // 文本搜索（包含 ✅/❌）
        if (q.length) {
            if ([line rangeOfString:q options:NSCaseInsensitiveSearch].location == NSNotFound) continue;
        }
        [dst addObject:line];
    }

    self.filtered = dst;
    [_table reloadData];

    // 若停留在底部且未暂停，保持自动滚动
    [self scrollToBottomIfNeeded:YES];
    [self updateJumpButtonVisibility];
}

#pragma mark - Actions

- (void)close {
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)onToggleAuto {
    self.pausedAuto = !self.pausedAuto;
    _autoScroll = !self.pausedAuto;

    // 轻提示
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [gen impactOccurred];

    NSString *tip = self.pausedAuto ? @"已暂停自动滚动" : @"已恢复自动滚动";
    [self showToast:tip];
}

- (void)onClear {
    [[LFSimpleLogger shared] clear];
}

- (void)onShare {
    NSError *err = nil;
    NSURL *url = [[LFSimpleLogger shared] exportToFileWithError:&err];
    if (!url) {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"导出失败"
                                                                    message:err.localizedDescription ?: @"未知错误"
                                                             preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:ac animated:YES completion:nil];
        return;
    }
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                                                      applicationActivities:nil];
    [self presentViewController:avc animated:YES completion:nil];
}

- (void)onJumpBottom {
    _autoScroll = YES;
    self.pausedAuto = NO;
    [self scrollToBottomIfNeeded:YES];
    [self updateJumpButtonVisibility];
}

#pragma mark - Notifications

- (void)onLoggerAppend:(NSNotification *)n {
    self.all = [[LFSimpleLogger shared] allLines];
    [self applyFilterAndReload]; // 内部会 reload + 保持底部
}

#pragma mark - Auto scroll

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _autoScroll = NO;
    self.pausedAuto = YES;
    [self updateJumpButtonVisibility];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateJumpButtonVisibility];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateJumpButtonVisibility];
}

- (void)scrollToBottomIfNeeded:(BOOL)animated {
    if (!self.filtered.count || !_autoScroll) return;
    NSInteger last = self.filtered.count - 1;
    if ([_table numberOfRowsInSection:0] > last) {
        [_table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:last inSection:0]
                      atScrollPosition:UITableViewScrollPositionBottom
                              animated:animated];
    }
}

- (void)updateJumpButtonVisibility {
    CGFloat contentHeight = _table.contentSize.height;
    CGFloat visibleHeight = _table.bounds.size.height;
    CGFloat offsetY = _table.contentOffset.y;
    BOOL nearBottom = (contentHeight - visibleHeight - offsetY) < 32.0;

    CGFloat targetAlpha = (nearBottom && !_table.isDragging) ? 0.0 : 1.0;
    if (self.jumpBtn.alpha != targetAlpha) {
        [UIView animateWithDuration:0.15 animations:^{
            self.jumpBtn.alpha = targetAlpha;
        }];
    }
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filtered.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LFLogCell *c = [tv dequeueReusableCellWithIdentifier:@"logcell" forIndexPath:indexPath];
    [c applyLine:self.filtered[indexPath.row]];
    return c;
}

#pragma mark - 小提示 Toast

- (void)showToast:(NSString *)text {
    UILabel *lab = [UILabel new];
    lab.text = text;
    lab.textColor = UIColor.whiteColor;
    lab.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    lab.numberOfLines = 0;
    lab.textAlignment = NSTextAlignmentCenter;
    lab.translatesAutoresizingMaskIntoConstraints = NO;

    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark]];
    blur.translatesAutoresizingMaskIntoConstraints = NO;
    blur.layer.cornerRadius = 12;
    blur.layer.masksToBounds = YES;

    [blur.contentView addSubview:lab];
    [NSLayoutConstraint activateConstraints:@[
        [lab.topAnchor constraintEqualToAnchor:blur.contentView.topAnchor constant:8],
        [lab.bottomAnchor constraintEqualToAnchor:blur.contentView.bottomAnchor constant:-8],
        [lab.leadingAnchor constraintEqualToAnchor:blur.contentView.leadingAnchor constant:12],
        [lab.trailingAnchor constraintEqualToAnchor:blur.contentView.trailingAnchor constant:-12],
    ]];

    [self.view addSubview:blur];
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [blur.centerXAnchor constraintEqualToAnchor:g.centerXAnchor],
        [blur.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-80]
    ]];

    blur.alpha = 0.0;
    [UIView animateWithDuration:0.15 animations:^{ blur.alpha = 1.0; } completion:^(__unused BOOL finished) {
        [UIView animateWithDuration:0.25 delay:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            blur.alpha = 0.0;
        } completion:^(__unused BOOL finished2) {
            [blur removeFromSuperview];
        }];
    }];
}

@end
