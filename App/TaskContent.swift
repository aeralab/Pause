import Foundation

struct ReadingPassage {
    let title: String
    let paragraphs: [String]
    static let library: [String: ReadingPassage] = [
        "literature": .init(title: "��һ������������", paragraphs: [
            "�糿����ʱ���Ҿ��������������ֽǵľ�����һ�ڽ�����̧�𣬽���������ײ������������һ���������µ�һ�쿪ʼ�ˡ�",
            "�������˽ҿ�������������ʱ��ס�������������˵�ͷ��Ӳ�ң�һֻ������������ҹ����ˮ��û���ļ��¼��ų�Ϊ���£���ÿ���¶����Լ���λ���Ϸ�����",
            "��ϰ�߰�·���������ص�֮��Ŀ�϶������ſ�������¡��ĵ�ש�����������µ��֣����д�̨��һ�豻�չ˵úܺõı��ɡ�",
            "��ʮ���Ӳ��øϽ��ȡ������ض������ߴ��㵼����顣��һ�룺���죬��ע�⵽����Щ΢Сȴ��ʵ���£�"
        ]),
        "history": .init(title: "һ����ͨ��Ʒ����ʷ", paragraphs: [
            "��ʷ��ֻ���ش��¼���ɡ�һֻ�롢һ��ֽ��һ����·��Ҳ���������������ȥ����Ʒ���µ���״��ĥ��������һ�������жϸ����塣",
            "����һֻ���룬����������������ʲô����Ե��û��ȱ�ڣ��ײ�����ʲô�ۼ�����Щ�۲���֤�ݡ�˭ʹ�ù�������������ʲô�����ǵȴ���֤�Ĳ��롣",
            "���ϴ���������������Ҫʲô���ߣ�˭�������䣿һ������Ʒ�����������๤�������˺ͼ�ͥ�����ļ۸񡢱��淽ʽ��ʹ�ó��ϣ��ֿ��ܳ��ֵ�ʱ�����",
            "������һ����Ʒ��д���������Բ�֤�����⡣����֪�����Ʋ�ͻ���֪���������Ÿ���ȥ����һ�������𰸡�"
        ]),
        "philosophy": .init(title: "Ը����ѡ��֮��", paragraphs: [
            "����һ���£��;���ȥ��һ���£�������ȫ��ͬ�����ǿ���ͬʱ���������Ƶ��Ҳ�������Ϣ������Ը������������ġ�",
            "�����Լ�����ϣ����������ʮ���Ӵ���ʲô������Ϣ����顢���ɣ�������ʱ�������һ�����£�ͬһ���������ڲ�ͬʱ����ܳе���ͬ�����á�",
            "���ʣ��������ʵ���ϴ���������Ҫ�������ﲻ��Ҫ�𱸣�ֻ��Ҫ�۲졣����ϢȴԽ��Խ�ۣ����ȡ��Ϣȴ�ǲ�ס���ݣ����ǿ�����������ѡ���������",
            "������ʱ����Ϊ�嶯���ж�֮���һ������ͣһ���ӣ������ﲹȫ����������Ҫ���ǡ������ؼ��Ÿ�����ȷ�𰸡�"
        ]),
        "science": .init(title: "�ӹ۲쵽��֤", paragraphs: [
            "һ��ˮ�������ϣ����ƾ�ֹ���¶�ȴ���ܱ仯��ˮ�ֻ�������������Ҳ��������Χ������������ѧ���ⳣ����ͨ������ʼ��",
            "������о����������Ƿ�Ӱ������������׼����ͬ���������ˮ�������¶���ʱ�価��һ�£�ֻ�ı�ͨ������������¼ˮ���ı仯��",
            "�������Ԥ�룬Ҳ����ζ���Ѿ�֤���������Ρ��������ܲ�׼���������ܱ仯����������̫�١���¼�������ظ��Ƚϡ�˵����ȷ���ԣ���������������",
            "��ѡ���ߵ�С���󣬷ֱ�д�¹۲졢���ܵĽ��ͣ��Լ�������͵ķ��������Ҿ��û��������֪��������һ�κܺõ���ϰ��"
        ])
    ]
}
struct MovementGuide {
    let steps: [String]
    var spoken: String { steps.joined(separator: "��") }
    static func forTask(_ id: String) -> MovementGuide {
        let steps: [String]
        switch id {
        case "face": steps = ["���ȣ����ɼ�����򢣬������Ȼ������", "����΢Ц��ͣһС�ᣬ����ȫ�����沿��", "�����ʷ�Χ�����ſ��ٺ��ϣ���Ҫҧ�����ػ�����Ƥ����", "���˫����ϢƬ�̣����Լ��Ľ����ظ���"]
        case "eyeCare": steps = ["ϴ��˫�֣����ȣ����ɼ羱��", "���˫�ۣ���Ȼ���������ᴥü����Χ�����ⰴѹ����", "����˫�֣�����Զ������׷��ѹǿ�ȡ�"]
        case "eyes": steps = ["����Ȼգ�ۣ�����ü�䡣", "�������ʾ����Զ�����ٻ�����������", "���˫��Ƭ�̣������١������ת������"]
        case "squats": steps = ["վ���ȹ�����ǰ��˫����Ȼ�ֿ���", "�β������������ϥ�ǳ���ż⣬�ٻ���վ��", "�����ظ�����Ϣ�����������¶�����ӡ�"]
        case "arms": steps = ["���Ȼ�վ�ȣ�˫����Ȼ���¡�", "������������ֱ������̧�۵����ʸ߶ȡ�", "���踺�أ��ظ����κ���ɼ粿��"]
        case "back": steps = ["���ȣ�������Ȼ��չ��", "���ι��������£�����������ɣ������ʼ硣", "������������չ����Ϣ����ǿ�к�����"]
        case "legs": steps = ["�������ػ��α���վ�ڰ�ȫƽ�档", "����̧��Ÿ����ٻ������£�Ҳ��������ϥ��", "�����ظ�����Ϣ������ƽ�ȡ�"]
        default: steps = ["���Ȼ�վ�ȣ�������Ȼ������", "�����ʷ�Χ�����������λ�ã�����������", "������Ť����ǿ�����ۣ��������Ỻ�߶������"]
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
            throw NSError(domain: "Stop", code: 1, userInfo: [NSLocalizedDescriptionKey: "��ѡ��С�� 5 MB �� TXT �ļ���"])
        }
        let data = try Data(contentsOf: url)
        guard data.count <= 5_000_000, let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "Stop", code: 2, userInfo: [NSLocalizedDescriptionKey: "��ʹ�ð������ĵ� UTF-8 �� UTF-16 TXT �ļ���"])
        }
        return .init(name: url.deletingPathExtension().lastPathComponent, text: text)
    }
}
