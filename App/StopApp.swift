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
                        Text(model.snapshot.lock == nil ? "��һ��հ�" : "��Ϣ����ʱ").font(.caption).foregroundStyle(.secondary)
                    }
                    Rectangle().frame(height: 1).foregroundStyle(Color.primary.opacity(0.15))
                    if let lock = model.snapshot.lock { recovery(lock) } else { setup }
                    if let error = model.error {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("��Ҫ����", systemImage: "exclamationmark.circle").font(.headline)
                            Text(error).font(.callout)
                            Button("����") { model.refresh() }.buttonStyle(.bordered)
                        }.padding(18).background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    }
                    library
                    if !model.snapshot.history.isEmpty { history }
                    if model.snapshot.enabled {
                        Button("ͣ������", role: .destructive) { showingDisable = true }.font(.footnote).foregroundStyle(.secondary)
                    }
                    Text("������ϰ�������ⲿ�ֻ���\n���ϴ��Ķ����˶��� App ʹ�ü�¼��")
                        .font(.caption).foregroundStyle(.secondary).lineSpacing(5)
                }.padding(24).frame(maxWidth: 620).frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .familyActivityPicker(isPresented: $showingPicker, selection: $selection)
            .fileImporter(isPresented: $showingImport, allowedContentTypes: [.plainText], allowsMultipleSelection: false, onCompletion: model.importBook)
            .confirmationDialog("ͣ�û�������� App ���Ʋ�������ǰ����", isPresented: $showingDisable, titleVisibility: .visible) {
                Button("ͣ�ò��������", role: .destructive) { model.disable() }
                Button("��������", role: .cancel) {}
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
            Text("ˢһ�ᣬ\nҲͣһ�ᡣ").font(.system(size: 42, weight: .medium)).lineSpacing(5)
            HStack(alignment: .firstTextBaseline) {
                Text("20").font(.system(size: 94, weight: .ultraLight, design: .monospaced))
                Text("���� / ÿ��").font(.caption).foregroundStyle(.secondary)
            }
            Text("�ﵽʹ��ʱ������������Ķ��������˶����沿�٤��������񣬻��ߵȴ� 30 ���ӣ��ٿ�ʼ��һ�֡�")
                .font(.callout).foregroundStyle(.secondary).lineSpacing(6)
            if model.snapshot.enabled {
                Label(model.snapshot.cycleID == nil ? "��ش��ָ�" : "����������", systemImage: "checkmark.shield").font(.headline)
                Text("ֱ��ʹ��ѡ���� App ���ɣ�ϵͳ�ں�̨��ʱ�����ﲻ����ʾδ��������ʵʱʹ�õ���ʱ��")
                    .font(.caption).foregroundStyle(.secondary)
            } else if !model.authorized {
                primary("1. ��Ȩ��Ļʹ��ʱ��") { Task { await model.authorize() } }
            } else {
                Button("ѡ����Ҫ���Ƶ� App") { showingPicker = true }.buttonStyle(.bordered)
                Text("��ѡ \(selection.applicationTokens.count) �� App �� \(selection.categoryTokens.count) ����� �� \(selection.webDomainTokens.count) ����վ")
                    .font(.caption).foregroundStyle(.secondary)
                primary("���� Pause") { model.enable(selection) }
            }
            Text("΢�Ż��������ޣ��޷�ֻ�������е���Ƶ�š�������Ļʱ����Ȩ�����г�����Stop ����ŵ�޷��ƹ���")
                .font(.caption).foregroundStyle(.secondary).lineSpacing(4)
        }
    }
    @ViewBuilder private func recovery(_ lock: LockState) -> some View {
        if let task = lock.task {
            VStack(alignment: .leading, spacing: 20) {
                Text("��һ�Σ�\(task.category.title)��").font(.system(size: 34, weight: .medium))
                HStack { Label(task.title, systemImage: task.symbol); Spacer(); Text("�������").foregroundStyle(.secondary) }.font(.callout)
                Text(clock(task.seconds - lock.creditedSeconds)).font(.system(size: 74, weight: .ultraLight, design: .monospaced)).minimumScaleFactor(0.6).lineLimit(1)
                ProgressView(value: lock.creditedSeconds, total: task.seconds).tint(.primary)
                primary(model.running ? "��ͣ" : "��ʼ / ����") { model.toggle() }
                Text("Ҳ���Բ��������ٵ� \(clock(lock.waitEndsAt.timeIntervalSince(model.now))) �Զ�������")
                    .font(.caption).foregroundStyle(.secondary)
                Text("�뿪 Pause ����������ͣ���񣻵ȴ� 30 ���ӵ�ʱ���Լ������ؿ�Ӧ�ò������³�����")
                    .font(.caption).foregroundStyle(.secondary).lineSpacing(4)
                if task.category == .reading {
                    if let passage = ReadingPassage.library[task.id] {
                        Divider()
                        Text(passage.title).font(.title2.weight(.medium))
                        Text("ԭ��������ϰ �� ���ض���˼��������Լ��������").font(.caption).foregroundStyle(.secondary)
                        ForEach(passage.paragraphs, id: \.self) { Text($0).font(.system(size: fontSize)).lineSpacing(10).textSelection(.enabled) }
                        Button("�ʶ�����") { model.speak(passage.paragraphs.joined(separator: "��")) }.buttonStyle(.bordered)
                        if model.book != nil { Button("���ҵ������") { showingBook = true }.buttonStyle(.bordered) }
                    }
                } else {
                    MovementIllustration(task: task, elapsed: lock.creditedSeconds)
                        .frame(height: 180).frame(maxWidth: .infinity)
                        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("�Ỻ����ʾ�⣬����������ָ�������ʷ���Ϊ׼")
                    let guide = MovementGuide.forTask(task.id)
                    ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 14) {
                            Text(String(format: "%02d", index + 1)).monospacedDigit().foregroundStyle(.secondary)
                            Text(step)
                        }.font(.callout)
                    }
                    Button("������ָ��") { model.speak(guide.spoken) }.buttonStyle(.bordered)
                    Text("��ʱ������Ϣ�����������˶�����ʹ��ͷ�λ���ʱֹͣ���ɵȴ��������沿���۲���������ɣ����������ƻ�ı���ۡ�")
                        .font(.caption).foregroundStyle(.secondary).lineSpacing(4)
                }
            }
        }
    }
    private var library: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Text("�ҵ��Ķ�").font(.headline)
            Text(model.book?.name ?? "��ѧ / ��ʷ / ��ѧ / ��ѧ��֧�ֵ����Լ����顣")
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                Button("���� TXT") { showingImport = true }.buttonStyle(.bordered)
                if model.book != nil { Button("�Ķ�") { showingBook = true }.buttonStyle(.bordered) }
            }
            HStack { Text("�ֺ�").font(.caption); Slider(value: $fontSize, in: 16...28, step: 1) }
        }
    }
    private var history: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            Text("�����¼").font(.headline)
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
                            Text(model.running ? "�Ķ���ʱ��" : "�Ķ���ʱ����ͣ���رմ�ҳ��㿪ʼ����").font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(Array(book.text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                            if !line.isEmpty { Text(line).font(.system(size: fontSize)).lineSpacing(9).textSelection(.enabled) }
                        }
                    }.padding(24)
                }
            }.navigationTitle(model.book?.name ?? "�Ķ�")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("���") { showingBook = false } } }
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
