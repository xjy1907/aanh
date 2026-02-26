#include <chrono>
#include <thread>
#include <string>
#include <unordered_map>
#include <functional>

class Throttler {
public:
    Throttler() {}

    // 普通节流，不阻塞，只在间隔后才执行
    void executeTask(std::string taskName, std::chrono::duration<double> interval, std::function<void()> task) {
        auto currentTime = std::chrono::steady_clock::now();
        auto lastExecuted = lastExecuted_[taskName];
        auto elapsedTime = std::chrono::duration_cast<std::chrono::duration<double>>(currentTime - lastExecuted);

        if (elapsedTime >= interval) {
            lastExecuted_[taskName] = currentTime;
            task();
        }
    }

    // 阻塞节流：确保每次调用都间隔一定时间
    void executeTaskWithSleep(std::string taskName, std::chrono::microseconds interval, std::function<void()> task) {
        auto currentTime = std::chrono::steady_clock::now();

        // 第一次调用初始化时间
        if (lastExecutedMicro_.find(taskName) == lastExecutedMicro_.end()) {
            lastExecutedMicro_[taskName] = currentTime;
        }

        auto lastExecuted = lastExecutedMicro_[taskName];
        auto elapsedMicroseconds = std::chrono::duration_cast<std::chrono::microseconds>(currentTime - lastExecuted);

        // 如果没到间隔时间，就sleep剩余时间
        if (elapsedMicroseconds < interval) {
            std::this_thread::sleep_for(interval - elapsedMicroseconds);
        }

        // 更新执行时间并执行任务
        lastExecutedMicro_[taskName] = std::chrono::steady_clock::now();
        task();
    }

private:
    std::unordered_map<std::string, std::chrono::steady_clock::time_point> lastExecuted_;
    std::unordered_map<std::string, std::chrono::steady_clock::time_point> lastExecutedMicro_;
};
