import Foundation

struct ReadingPassage {
    let title: String
    let paragraphs: [String]
    static let library: [String: ReadingPassage] = [
        "literature": .init(title: "把一条街慢慢走完", paragraphs: [
            "早晨出门时，我决定不戴耳机。街角的卷帘门一节节向上抬起，金属轻轻碰撞。店铺像伸了一个懒腰，新的一天开始了。",
            "卖早点的人揭开蒸笼，白气暂时挡住了他的脸。有人低头数硬币，一只狗认真闻着昨夜的雨水。没有哪件事急着成为故事，但每件事都在自己的位置上发生。",
            "我习惯把路当成两个地点之间的空隙。今天才看见树根隆起的地砖、旧招牌留下的字，还有窗台上一盆被照顾得很好的薄荷。",
            "这十分钟不用赶进度。慢慢重读，或者打开你导入的书。想一想：今天，你注意到过哪些微小却真实的事？"
        ]),
        "history": .init(title: "一件普通物品的历史", paragraphs: [
            "历史不只由重大事件组成。一只碗、一张纸、一条道路，也能引导我们理解过去。物品留下的形状和磨损，往往比一个宏大的判断更具体。",
            "看到一只旧碗，先描述它：材料是什么，边缘有没有缺口，底部留下什么痕迹？这些观察是证据。谁使用过它、它经历过什么，则是等待验证的猜想。",
            "材料从哪里来？制作需要什么工具？谁负责运输？一件日用品可能连接许多工匠、商人和家庭。它的价格、保存方式与使用场合，又可能呈现当时的生活。",
            "拿身边一件物品，写下三个可以查证的问题。区分知道、推测和还不知道，不急着给过去安排一个完整答案。"
        ]),
        "philosophy": .init(title: "愿望与选择之间", paragraphs: [
            "想做一件事，和决定去做一件事，并不完全相同。我们可以同时想继续看视频，也想早点休息。两个愿望都可能是真的。",
            "先问自己：我希望接下来的十分钟带来什么？是信息、陪伴、放松，还是暂时不必面对一件难事？同一个动作，在不同时候可能承担不同的作用。",
            "再问：这个动作实际上带来了我需要的吗？这里不需要责备，只需要观察。想休息却越来越累，想获取信息却记不住内容，都是可以用来调整选择的线索。",
            "自由有时表现为冲动与行动之间的一点间隔。停一分钟，在心里补全：我现在需要的是……不必急着给出正确答案。"
        ]),
        "science": .init(title: "从观察到验证", paragraphs: [
            "一杯水放在桌上，看似静止，温度却可能变化，水分会逐渐蒸发，杯壁也不断与周围交换能量。科学问题常从普通的现象开始。",
            "如果想研究空气流动是否影响蒸发，可以准备相同容器和相近水量，让温度与时间尽量一致，只改变通风条件，并记录水量的变化。",
            "结果符合预想，也不意味着已经证明所有情形。测量可能不准，环境可能变化，样本可能太少。记录条件、重复比较、说明不确定性，都属于理解结果。",
            "挑选身边的小现象，分别写下观察、可能的解释，以及检验解释的方法。把我觉得换成我如何知道，就是一次很好的练习。"
        ])
    ]
}
struct MovementGuide {
    let steps: [String]
    var spoken: String { steps.joined(separator: "。") }
    static func forTask(_ id: String) -> MovementGuide {
        let steps: [String]
        switch id {
        case "face": steps = ["坐稳，放松肩膀和下颌，保持自然呼吸。", "轻轻微笑，停一小会，再完全放松面部。", "在舒适范围缓慢张口再合上；不要咬紧牙关或拉扯皮肤。", "轻闭双眼休息片刻，按自己的节奏重复。"]
        case "eyeCare": steps = ["洗净双手，坐稳，放松肩颈。", "轻闭双眼，自然呼吸；可轻触眉骨周围，避免按压眼球。", "放松双手，眺望远处，不追求按压强度。"]
        case "eyes": steps = ["先自然眨眼，放松眉间。", "看向舒适距离的远处，再缓慢看近处。", "轻闭双眼片刻，不快速、大幅度转动眼球。"]
        case "squats": steps = ["站在稳固椅子前，双脚自然分开。", "臀部轻轻向后坐，膝盖朝向脚尖，再缓慢站起。", "少量重复后休息，不必连续下蹲五分钟。"]
        case "arms": steps = ["坐稳或站稳，双臂自然垂下。", "缓慢屈肘再伸直，轻轻抬臂到舒适高度。", "不需负重，重复几次后放松肩部。"]
        case "back": steps = ["坐稳，脊柱自然伸展。", "肩胛骨轻轻向后靠拢，再慢慢放松，避免耸肩。", "交替做轻柔伸展与休息，不强行后仰。"]
        case "legs": steps = ["扶稳桌沿或椅背，站在安全平面。", "轻轻抬起脚跟，再缓慢放下；也可坐着伸膝。", "少量重复后休息，保持平稳。"]
        default: steps = ["坐稳或站稳，保持自然呼吸。", "在舒适范围轻轻调整骨盆位置，放松腰背。", "不快速扭腰或强行弯折，可以用轻缓走动替代。"]
        }
        return .init(steps: steps)
    }
}
struct PersonalBook: Codable {
    let name: String
    let text: String
    static var location: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("personal-book.json") }
    static func load() -> PersonalBook? {
        guard let data = try? Data(contentsOf: location) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
    func save() throws { try JSONEncoder().encode(self).write(to: Self.location, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]) }
    static func read(url: URL) throws -> PersonalBook {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        guard (values.fileSize ?? 0) <= 5_000_000 else {
            throw NSError(domain: "Stop", code: 1, userInfo: [NSLocalizedDescriptionKey: "请选择小于 5 MB 的 TXT 文件。"])
        }
        let data = try Data(contentsOf: url)
        guard data.count <= 5_000_000, let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "Stop", code: 2, userInfo: [NSLocalizedDescriptionKey: "请使用包含正文的 UTF-8 或 UTF-16 TXT 文件。"])
        }
        return .init(name: url.deletingPathExtension().lastPathComponent, text: text)
    }
}
