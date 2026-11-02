import SwiftUI
import Combine
import FamilyControls
import UniformTypeIdentifiers
import AVFoundation

@main
struct StopApp: App {
    var body: some Scene { WindowGroup { HomeView().tint(.primary) } }
}
@MainActor
final class StopViewModel: ObservableObject {
    @Published var snapshot = StopState()
    @Published var error: String?
    @Published var running = false
    @Published var now = Date()
    @Published var authorized = AuthorizationCenter.shared.authorizationStatus == .approved
    @Published var book = PersonalBook.load()
    private var previousTick: TimeInterval?
    private let speaker = AVSpeechSynthesizer()
    func refresh() {
        do { snapshot = try ScreenTime.shared.reconcile(); error = snapshot.lastError }
        catch { self.error = error.localizedDescription }
        authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        now = Date()
        if snapshot.lock == nil { pause() }
    }
    func authorize() async {
        do { try await AuthorizationCenter.shared.requestAuthorization(for: .individual); refresh() }
        catch { self.error = error.localizedDescription }
    }
    func enable(_ selection: FamilyActivitySelection) {
        do { try ScreenTime.shared.enable(selection: selection); refresh() }
        catch { self.error = error.localizedDescription }
    }
    func disable() {
        pause()
        do { try ScreenTime.shared.disable(); refresh() }
        catch { self.error = error.localizedDescription }
    }
    func toggle() {
        if running { pause() } else {
            guard snapshot.lock != nil else { return }
            running = true; previousTick = ProcessInfo.processInfo.systemUptime
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    func pause() {
        running = false; previousTick = nil
        speaker.stopSpeaking(at: .immediate)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    func tick(active: Bool) {
        now = Date()
        guard active else { pause(); return }
        let uptime = ProcessInfo.processInfo.systemUptime
        if running, let lock = snapshot.lock {
            let delta = previousTick.map { uptime - $0 } ?? 0
            previousTick = uptime
            do { snapshot = try ScreenTime.shared.credit(seconds: delta, lockID: lock.id); error = snapshot.lastError }
            catch { self.error = error.localizedDescription; pause() }
            if snapshot.lock == nil { pause(); UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        } else { refresh() }
    }
    func speak(_ text: String) {
        speaker.stopSpeaking(at: .immediate)
        let speech = AVSpeechUtterance(string: text)
        speech.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        speech.rate = 0.43; speaker.speak(speech)
    }
    func importBook(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let newBook = try PersonalBook.read(url: url)
            try newBook.save(); book = newBook
        } catch { self.error = error.localizedDescription }
    }
}
struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = StopViewModel()
    @State private var selection = FamilyActivitySelection()
    @State private var showingPicker = false
    @State private var showingImport = false
    @State private var showingDisable = false
    @State private var showingBook = false
    @AppStorage("readingFontSize") private var fontSize = 19.0
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("pause.").font(.system(size: 34, weight: .bold, design: .rounded))
                        Spacer()
                        Text(model.snapshot.lock == nil ? "留一点空白" : "休息进行时").font(.caption).foregroundStyle(.secondary)
                    }
                    Rectangle().frame(height: 1).foregroundStyle(Color.primary.opacity(0.15))
                    if let lock = model.snapshot.lock { recovery(lock) } else { setup }
                    if let error = model.error {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("需要处理", systemImage: "exclamationmark.circle").font(.headline)
                            Text(error).font(.callout)
                            Button("重试") { model.refresh() }.buttonStyle(.bordered)
                        }.padding(18).background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    }
                    library
                    if !model.snapshot.history.isEmpty { history }
                    if model.snapshot.enabled {
                        Button("停用限制", role: .destructive) { showingDisable = true }.font(.footnote).foregroundStyle(.secondary)
                    }
                    Text("自律练习，留在这部手机。\n不上传阅读、运动或 App 使用记录。")
                        .font(.caption).foregroundStyle(.secondary).lineSpacing(5)
                }.padding(24).frame(maxWidth: 620).frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .familyActivityPicker(isPresented: $showingPicker, selection: $selection)
            .fileImporter(isPresented: $showingImport, allowedContentTypes: [.plainText], allowsMultipleSelection: false, onCompletion: model.importBook)
            .confirmationDialog("停用会立即解除 App 限制并结束当前任务。", isPresented: $showingDisable, titleVisibility: .visible) {
                Button("停用并解除限制", role: .destructive) { model.disable() }
                Button("继续保持", role: .cancel) {}
            }
            .sheet(isPresented: $showingBook) { bookReader }
            .onChange(of: showingBook) { _, visible in
                if visible && model.snapshot.lock?.task?.category != .reading { model.pause() }
            }
            .onAppear { model.refresh(); selection = model.snapshot.selection }
            .onReceive(timer) { _ in model.tick(active: scenePhase == .active) }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { model.pause() } else { model.refresh() }
            }
        }
    }
    private var setup: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("刷一会，\n也停一会。").font(.system(size: 42, weight: .medium)).lineSpacing(5)
            HStack(alignment: .firstTextBaseline) {
                Text("20").font(.system(size: 94, weight: .ultraLight, design: .monospaced))
                Text("分钟 / 每轮").font(.caption).foregroundStyle(.secondary)
            }
            Text("达到使用时长后，随机安排阅读、身体运动或面部瑜伽。完成任务，或者等待 30 分钟，再开始下一轮。")
                .font(.callout).foregroundStyle(.secondary).lineSpacing(6)
            if model.snapshot.enabled {
                Label(model.snapshot.cycleID == nil ? "监控待恢复" : "限制已启用", systemImage: "checkmark.shield").font(.headline)
                Text("直接使用选定的 App 即可，系统在后台计时。这里不会显示未经测量的实时使用倒计时。")
                    .font(.caption).foregroundStyle(.secondary)
            } else if !model.authorized {
                primary("1. 授权屏幕使用时间") { Task { await model.authorize() } }
            } else {
                Button("选择需要限制的 App") { showingPicker = true }.buttonStyle(.bordered)
                Text("已选 \(selection.applicationTokens.count) 个 App · \(selection.categoryTokens.count) 个类别 · \(selection.webDomainTokens.count) 个网站")
                    .font(.caption).foregroundStyle(.secondary)
                primary("启用 Pause") { model.enable(selection) }
            }
            Text("微信会整体受限，无法只限制其中的视频号。个人屏幕时间授权可自行撤销，Stop 不承诺无法绕过。")
                .font(.caption).foregroundStyle(.secondary).lineSpacing(4)
        }
    }
    @ViewBuilder private func recovery(_ lock: LockState) -> some View {
        if let task = lock.task {
            VStack(alignment: .leading, spacing: 20) {
                Text("这一次，\(task.category.title)。").font(.system(size: 34, weight: .medium))
                HStack { Label(task.title, systemImage: task.symbol); Spacer(); Text("随机安排").foregroundStyle(.secondary) }.font(.callout)
                Text(clock(task.seconds - lock.creditedSeconds)).font(.system(size: 74, weight: .ultraLight, design: .monospaced)).minimumScaleFactor(0.6).lineLimit(1)
                ProgressView(value: lock.creditedSeconds, total: task.seconds).tint(.primary)
                primary(model.running ? "暂停" : "开始 / 继续") { model.toggle() }
                Text("也可以不做任务，再等 \(clock(lock.waitEndsAt.timeIntervalSince(model.now))) 自动解锁。")
                    .font(.caption).foregroundStyle(.secondary)
                Text("离开 Pause 或锁屏会暂停任务；等待 30 分钟的时间仍继续。重开应用不会重新抽任务。")
                    .font(.caption).foregroundStyle(.secondary).lineSpacing(4)
                if task.category == .reading {
                    if let passage = ReadingPassage.library[task.id] {
                        Divider()
                        Text(passage.title).font(.title2.weight(.medium))
                        Text("原创短文练习 · 可重读、思考，或读自己导入的书").font(.caption).foregroundStyle(.secondary)
                        ForEach(passage.paragraphs, id: \.self) { Text($0).font(.system(size: fontSize)).lineSpacing(10).textSelection(.enabled) }
                        Button("朗读短文") { model.speak(passage.paragraphs.joined(separator: "。")) }.buttonStyle(.bordered)
                        if model.book != nil { Button("打开我导入的书") { showingBook = true }.buttonStyle(.bordered) }
                    }
                } else {
                    MovementIllustration(task: task, elapsed: lock.creditedSeconds)
                        .frame(height: 180).frame(maxWidth: .infinity)
                        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("轻缓动作示意，具体以文字指导和舒适幅度为准")
                    let guide = MovementGuide.forTask(task.id)
                    ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 14) {
                            Text(String(format: "%02d", index + 1)).monospacedDigit().foregroundStyle(.secondary)
                            Text(step)
                        }.font(.callout)
                    }
                    Button("听动作指导") { model.speak(guide.spoken) }.buttonStyle(.bordered)
                    Text("计时包含休息，无需连续运动。疼痛、头晕或不适时停止；可等待解锁。面部与眼部活动仅作放松，不宣称治疗或改变外观。")
                        .font(.caption).foregroundStyle(.secondary).lineSpacing(4)
                }
            }
        }
    }
    private var library: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Text("我的阅读").font(.headline)
            Text(model.book?.name ?? "文学 / 历史 / 哲学 / 科学，支持导入自己的书。")
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                Button("导入 TXT") { showingImport = true }.buttonStyle(.bordered)
                if model.book != nil { Button("阅读") { showingBook = true }.buttonStyle(.bordered) }
            }
            HStack { Text("字号").font(.caption); Slider(value: $fontSize, in: 16...28, step: 1) }
        }
    }
    private var history: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            Text("最近记录").font(.headline)
            ForEach(model.snapshot.history.prefix(10)) { item in
                HStack(alignment: .top) {
                    Text(item.text).font(.callout); Spacer()
                    Text(item.at.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
    private var bookReader: some View {
        NavigationStack {
            ScrollView {
                if let book = model.book {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        if model.snapshot.lock != nil {
                            Text(model.running ? "阅读计时中" : "阅读计时已暂停；关闭此页后点开始继续").font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(Array(book.text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                            if !line.isEmpty { Text(line).font(.system(size: fontSize)).lineSpacing(9).textSelection(.enabled) }
                        }
                    }.padding(24)
                }
            }.navigationTitle(model.book?.name ?? "阅读")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showingBook = false } } }
        }
    }
    private func primary(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(text).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16) }
            .buttonStyle(.plain).foregroundStyle(Color(uiColor: .systemBackground))
            .background(Color.primary, in: RoundedRectangle(cornerRadius: 10))
    }
    private func clock(_ seconds: TimeInterval) -> String {
        let value = Int(ceil(max(0, seconds)))
        return String(format: "%02d:%02d", value / 60, value % 60)
    }
}
struct MovementIllustration: View {
    let task: RecoveryTask
    let elapsed: TimeInterval
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let phase = CGFloat((sin(elapsed * .pi / 4) + 1) / 2)
            var path = Path()
            if task.category == .face || task.id == "eyes" || task.id == "eyeCare" {
                path.addEllipse(in: CGRect(x: center.x - 48, y: center.y - 65, width: 96, height: 120))
                path.move(to: CGPoint(x: center.x - 28, y: center.y - 20))
                path.addQuadCurve(to: CGPoint(x: center.x - 10, y: center.y - 20), control: CGPoint(x: center.x - 19, y: center.y - 12 - phase * 6))
                path.move(to: CGPoint(x: center.x + 10, y: center.y - 20))
                path.addQuadCurve(to: CGPoint(x: center.x + 28, y: center.y - 20), control: CGPoint(x: center.x + 19, y: center.y - 12 - phase * 6))
                path.move(to: CGPoint(x: center.x - 18, y: center.y + 22))
                path.addQuadCurve(to: CGPoint(x: center.x + 18, y: center.y + 22), control: CGPoint(x: center.x, y: center.y + 22 + phase * 18))
            } else {
                let squat: CGFloat = task.id == "squats" ? phase * 18 : 0
                let neck = CGPoint(x: center.x, y: center.y - 35 + squat)
                path.addEllipse(in: CGRect(x: center.x - 10, y: neck.y - 25, width: 20, height: 20))
                path.move(to: neck); path.addLine(to: CGPoint(x: center.x, y: center.y + 15 + squat))
                for sign in [CGFloat(-1), CGFloat(1)] {
                    path.move(to: CGPoint(x: center.x, y: neck.y + 10))
                    path.addLine(to: CGPoint(x: center.x + sign * 35, y: neck.y + 35 - phase * (task.id == "arms" ? 50 : 8)))
                    path.move(to: CGPoint(x: center.x, y: center.y + 15 + squat))
                    path.addLine(to: CGPoint(x: center.x + sign * (15 + squat), y: center.y + 42))
                    path.addLine(to: CGPoint(x: center.x + sign * 23, y: center.y + 72))
                }
            }
            context.stroke(path, with: .foreground, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
    }
}
