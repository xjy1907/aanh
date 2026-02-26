#import "网页雷达服务器.h"

网页雷达客户端 g_网页雷达;

网页雷达客户端::网页雷达客户端() : 运行中(false) {
    服务器地址 = "http://ld.81fz.com/api.php";
    当前地图 = "db";
    上传队列 = dispatch_queue_create("radar.upload", DISPATCH_QUEUE_SERIAL);
}

网页雷达客户端::~网页雷达客户端() {
    停止();
}

void 网页雷达客户端::设置服务器(const string& url) {
    服务器地址 = url;
}

bool 网页雷达客户端::启动() {
    if (运行中) return true;
    
    // 创建房间
    NSString *urlStr = [NSString stringWithFormat:@"%s?action=create", 服务器地址.c_str()];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    if (data) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([json[@"ok"] boolValue]) {
            房间号 = [json[@"room"] UTF8String];
            NSLog(@"[网页雷达] 房间创建成功: %s", 房间号.c_str());
        }
    }
    
    if (房间号.empty()) {
        NSLog(@"[网页雷达] 创建房间失败");
        return false;
    }
    
    运行中 = true;
    
    // 定时上传 (100ms)
    定时器 = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, 上传队列);
    dispatch_source_set_timer(定时器, DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC, 10 * NSEC_PER_MSEC);
    dispatch_source_set_event_handler(定时器, ^{
        if (运行中) 上传数据();
    });
    dispatch_resume(定时器);
    
    return true;
}

void 网页雷达客户端::停止() {
    if (!运行中) return;
    运行中 = false;
    
    if (定时器) {
        dispatch_source_cancel(定时器);
        定时器 = nil;
    }
    房间号 = "";
}

string 网页雷达客户端::玩家数据转JSON() {
    lock_guard<mutex> lock(数据锁);
    
    string json = "{\"map\":\"" + 当前地图 + "\",\"players\":[";
    bool first = true;
    
    for (const auto& p : 当前玩家数据) {
        if (!first) json += ",";
        first = false;
        
        json += "{";
        json += "\"x\":" + to_string((int)p.x) + ",";
        json += "\"y\":" + to_string((int)p.y) + ",";
        json += "\"teamId\":" + to_string(p.teamId) + ",";
        json += "\"name\":\"" + p.name + "\",";
        json += "\"health\":" + to_string((int)p.health) + ",";
        json += "\"direction\":" + to_string((int)p.direction) + ",";
        json += "\"weapon\":\"" + p.weapon + "\",";
        json += "\"isAI\":" + string(p.isAI ? "true" : "false") + ",";
        json += "\"helmet\":{\"level\":\"" + p.helmetLevel + "\",\"durability\":" + to_string((int)p.helmetDurability) + ",\"maxDurability\":" + to_string((int)p.helmetMaxDurability) + "},";
        json += "\"armor\":{\"level\":\"" + p.armorLevel + "\",\"durability\":" + to_string((int)p.armorDurability) + ",\"maxDurability\":" + to_string((int)p.armorMaxDurability) + "}";
        json += "}";
    }
    json += "],\"items\":[";
    
    first = true;
    for (const auto& item : 当前物资数据) {
        if (!first) json += ",";
        first = false;
        
        json += "{";
        json += "\"x\":" + to_string((int)item.x) + ",";
        json += "\"y\":" + to_string((int)item.y) + ",";
        json += "\"name\":\"" + item.name + "\",";
        json += "\"quality\":" + to_string(item.quality) + ",";
        json += "\"price\":" + to_string(item.price);
        json += "}";
    }
    json += "]}";
    return json;
}

void 网页雷达客户端::上传数据() {
    if (房间号.empty()) return;
    
    NSString *urlStr = [NSString stringWithFormat:@"%s?action=update&room=%s", 
                        服务器地址.c_str(), 房间号.c_str()];
    NSURL *url = [NSURL URLWithString:urlStr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 2;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    string json = 玩家数据转JSON();
    request.HTTPBody = [NSData dataWithBytes:json.c_str() length:json.length()];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request] resume];
}

void 网页雷达客户端::更新玩家数据(const vector<雷达玩家数据>& 玩家) {
    lock_guard<mutex> lock(数据锁);
    当前玩家数据 = 玩家;
}

void 网页雷达客户端::更新物资数据(const vector<雷达物资数据>& 物资) {
    lock_guard<mutex> lock(数据锁);
    当前物资数据 = 物资;
}

void 网页雷达客户端::设置地图(const string& 地图名) {
    当前地图 = 地图名;
}

string 网页雷达客户端::获取访问信息() {
    if (房间号.empty()) return "连接中...";
    return "房间: " + 房间号;
}
