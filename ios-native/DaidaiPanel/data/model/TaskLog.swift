import Foundation

struct TaskLog: Codable, Identifiable, Equatable {
    let id: Int
    let taskId: Int
    let content: String
    let status: Int?
    let duration: Double?
    let logPath: String?
    let startedAt: Date
    let endedAt: Date?
    let createdAt: Date
    let taskName: String?
    let taskType: String?
    let labels: [String]?

    enum CodingKeys: String, CodingKey {
        case id, content, status, duration, labels
        case taskId = "task_id"
        case logPath = "log_path"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case createdAt = "created_at"
        case taskName = "task_name"
        case taskType = "task_type"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeInt(forKey: .id)
        taskId = try c.decodeInt(forKey: .taskId)
        content = try c.decodeString(forKey: .content)
        status = try? c.decodeIntIfPresent(forKey: .status)
        duration = try? c.decodeDoubleIfPresent(forKey: .duration)
        logPath = try? c.decodeStringIfPresent(forKey: .logPath)
        startedAt = try c.decodeDate(forKey: .startedAt)
        endedAt = try? c.decodeDateIfPresent(forKey: .endedAt)
        createdAt = try c.decodeDate(forKey: .createdAt)
        taskName = try? c.decodeStringIfPresent(forKey: .taskName)
        taskType = try? c.decodeStringIfPresent(forKey: .taskType)
        labels = (try? c.decode([String].self, forKey: .labels))
    }

    var isSuccess: Bool { status == 0 }
    var isFailed: Bool { status == 1 }
    var isRunning: Bool { status == 2 }

    var statusText: String {
        switch status {
        case 0: return "成功"
        case 1: return "失败"
        case 2: return "运行中"
        default: return "未知"
        }
    }

    var durationText: String {
        guard let duration else { return "-" }
        if duration < 1 { return "\(Int(duration * 1000))ms" }
        if duration < 60 { return String(format: "%.1fs", duration) }
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return "\(minutes)m\(seconds)s"
    }
}

private extension KeyedDecodingContainer {
    func decodeInt(forKey key: Key) throws -> Int {
        if let v = try? decode(Int.self, forKey: key) { return v }
        if let v = try? decode(Double.self, forKey: key) { return Int(v) }
        if let s = try? decode(String.self, forKey: key), let v = Int(s) { return v }
        return 0
    }

    func decodeIntIfPresent(forKey key: Key) throws -> Int? {
        if let v = try decodeIfPresent(Int.self, forKey: key) { return v }
        if let v = try decodeIfPresent(Double.self, forKey: key) { return Int(v) }
        if let s = try decodeIfPresent(String.self, forKey: key), let v = Int(s) { return v }
        return nil
    }

    func decodeDoubleIfPresent(forKey key: Key) throws -> Double? {
        if let v = try decodeIfPresent(Double.self, forKey: key) { return v }
        if let v = try decodeIfPresent(Int.self, forKey: key) { return Double(v) }
        return nil
    }

    func decodeString(forKey key: Key) throws -> String {
        (try? decode(String.self, forKey: key)) ?? ""
    }

    func decodeStringIfPresent(forKey key: Key) throws -> String? {
        try? decode(String?.self, forKey: key)
    }

    func decodeDate(forKey key: Key) throws -> Date {
        guard let s = try? decode(String.self, forKey: key) else { return Date() }
        return DateParser.parse(s) ?? Date()
    }

    func decodeDateIfPresent(forKey key: Key) throws -> Date? {
        guard let s = try decode(String?.self, forKey: key) else { return nil }
        return DateParser.parse(s)
    }
}
