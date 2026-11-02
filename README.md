# Pause 原生版 · 随机恢复任务

版本 0.2.0，针对 iPhone15 / iOS26.6.1。最低部署 iOS17.4，构建要求 Xcode 的 iOS26.5+ SDK。Windows 上已完成源码更新；尚未执行 Swift 编译、XCTest 或真机验证，不是可安装成品。

## 已实现源码
选定App累计20分钟后，后台监控扩展施加系统限制。先从阅读、身体运动、面部瑜伽3类中随机选择，再抽具体任务；连续两轮不重复大类。每轮固定任务并持久化，暂停、重开不重新抽取。
阅读10分钟；下蹲、手臂、背、腿、腰、眼保健操5分钟；眼部放松10分钟；面部瑜伽10分钟。也可从锁定时开始等待30分钟。
黑白SwiftUI界面、原创短文、TXT书籍导入（UTF8/UTF16，5MB以内）、字号调整、中文朗读、轻柔动作指导和线条动画示意。无视频、无真实动作或阅读检测。
任务仅在前台计时；后台/锁屏暂停，等待期限继续。支持手动确认停用。所有记录和导入书籍仅在本机保存，不接服务器、不添加分析SDK。

## 编译
本ios目录应为GitHub私有仓库根目录（包含.github）。工作流在 main 分支的 Swift 源码或构建配置改变时自动触发，也支持手动触发。使用公开仓库的标准 macOS 运行器，不使用付费大型运行器。
1. 在云端Mac运行 swift test，检查实际Swift随机任务规则。
2. xcodegen generate 生成 Stop、StopMonitor、StopShield、StopShieldAction 四个原生target。
3. 无签名模拟器构建检查所有目标，再执行XCTest。GitHub工作流会保存编译日志与测试结果。
4. 不签名构建不是可安装IPA。签名与TestFlight需要Apple Developer会员，四个Bundle ID的Family Controls能力及对应App Group；分发权限需分别申请。
5. 使用GitHub现有免费额度前，应在账户Billing/Actions预算确认不允许额外付费。本工程不购买构建额度，不自动发布或上传App Store。
6. Mac本机可运行 bash build-mac.sh check 检查编译，open模式打开独立工程；archive模式需TEAM_ID和唯一BUNDLE_PREFIX。脚本不会上传。

## 可靠性范围
共享进度采用App Group原子JSON文件、flock跨进程锁及任务身份校验。损坏状态不静默清空。当前只记录达标/解锁，不提供精确每日总使用时长报表。
一轮最多监控24小时，末尾不足20分钟的使用量不跨窗口结转。系统回调可能延迟；休息结束若未使用设备，回调可能到设备再次使用才执行，主App也会在启动时恢复检查。
系统时间更改影响期限。个人授权可撤销；微信无法区分视频号和聊天。iOS26.5+可从拦截页按钮直接打开Stop，较旧版本需自行打开。
面部/眼部动作仅为轻柔放松，不承诺治疗、美容或改变外观。活动含组间休息，出现不适可停下并等待。
0.1旧版UserDefaults未迁移（此前未安装真机）；不删除其数据。如自行安装过旧版，先停用再更新。

## 待真机验收
首次授权/拒绝、空选择、重复启用、连续多轮20分钟、随机3类任务、暂停/锁屏/杀进程、30分钟等待、午夜、时区变更、权限撤销、类别/网站屏蔽、扩展并发、状态文件损坏、监控注册失败及恢复。
完成任务后新监控失败不得继续锁住已完成任务；stopMonitoring触发的提前intervalDidEnd不得误解锁；旧任务ID不能给新任务计时。
读取书籍时若iOS文件选择器造成前后台切换，任务会暂停，需要用户继续。没有用摄像头验证任务完成。

## 官方依据
https://developer.apple.com/documentation/managedsettings/shieldactionresponse/openparentalcontrolsapp
https://developer.apple.com/documentation/deviceactivity
https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement
https://docs.github.com/en/actions/reference/runners/github-hosted-runners
