import SwiftUI

enum APIError: LocalizedError {
    case offline, notSneaker, server(String)
    var errorDescription: String? {
        switch self {
        case .offline: return "No connection. Soledex needs the internet to identify and value your sneakers."
        case .notSneaker: return "That doesn't look like a sneaker. Try a clear photo of the shoe."
        case .server(let m): return m
        }
    }
}

enum SoledexAPI {
    static let base = "https://soledex-api.hxu92521.workers.dev"

    struct DTO: Decodable {
        struct Val: Decodable { var median, low, high: Double; var confidence: String; var comps: [Comp]; var note: String? }
        struct Comp: Decodable { var title: String; var price: Double; var date: String; var source: String }
        var name, brand, model, colorway, styleCode, year, condition, edition, confidence, history, rarityNote, query: String
        var legitTips: [String]; var valuation: Val; var tint: UInt?
    }

    static func identify(_ image: Data, back: Data? = nil) async throws -> Sneaker {
        var payload: [String: Any] = ["image": image.base64EncodedString()]
        if let back { payload["back"] = back.base64EncodedString() }
        let d: DTO = try await post("/v1/identify", payload)
        let comps = d.valuation.comps.map { SoldComp(title: $0.title, price: $0.price, date: $0.date, source: $0.source) }
        let val = Valuation(median: d.valuation.median, low: d.valuation.low, high: d.valuation.high,
                            confidence: Confidence(rawValue: d.valuation.confidence) ?? .medium, comps: comps, note: d.valuation.note)
        return Sneaker(name: d.name, brand: d.brand, model: d.model, colorway: d.colorway, styleCode: d.styleCode, year: d.year,
                       condition: d.condition, edition: d.edition, history: d.history, rarityNote: d.rarityNote, legitTips: d.legitTips,
                       query: d.query, valuation: val, tint: d.tint ?? 0x2A2A2E)
    }

    struct ValDTO: Decodable { var median, low, high: Double; var confidence: String; var comps: [DTO.Comp]; var note: String? }
    static func revalue(query: String, size: String) async throws -> Valuation {
        let d: ValDTO = try await post("/v1/revalue", ["query": query, "size": size])
        let comps = d.comps.map { SoldComp(title: $0.title, price: $0.price, date: $0.date, source: $0.source) }
        return Valuation(median: d.median, low: d.low, high: d.high, confidence: Confidence(rawValue: d.confidence) ?? .medium, comps: comps, note: d.note)
    }

    struct SpreadDTO: Decodable { var sizes: [Row]; struct Row: Decodable { var size: String; var median: Double; var count: Int } }
    static func spread(query: String) async throws -> [SizePrice] {
        let d: SpreadDTO = try await post("/v1/spread", ["query": query])
        return d.sizes.map { SizePrice(size: $0.size, median: $0.median, count: $0.count) }
    }

    private static func post<T: Decodable>(_ path: String, _ payload: [String: Any]) async throws -> T {
        let body = try JSONSerialization.data(withJSONObject: payload)
        var req = URLRequest(url: URL(string: base + path)!)
        req.httpMethod = "POST"; req.setValue("application/json", forHTTPHeaderField: "Content-Type"); req.httpBody = body; req.timeoutInterval = 90
        let data: Data, resp: URLResponse
        do { (data, resp) = try await URLSession.shared.data(for: req) } catch { throw APIError.offline }
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        if code == 422 { throw APIError.notSneaker }
        guard code < 300 else {
            let msg = (try? JSONDecoder().decode([String:String].self, from: data))?["error"] ?? "Something went wrong. Try a clearer photo."
            throw APIError.server(msg)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
