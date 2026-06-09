import UIKit

// Saves the user's actual sneaker photo so the closet shows real pairs, not placeholders.
enum PhotoStore {
    private static var dir: URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("shots", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    static func save(_ image: UIImage) -> String? {
        let name = "sole-\(UUID().uuidString).jpg"
        guard let data = image.jpegForUpload(maxDim: 1200, quality: 0.82) else { return nil }
        do { try data.write(to: dir.appendingPathComponent(name)); return name } catch { return nil }
    }
    private static let cache = NSCache<NSString, UIImage>()
    static func load(_ name: String?) -> UIImage? {
        guard let name else { return nil }
        if let c = cache.object(forKey: name as NSString) { return c }
        guard let img = UIImage(contentsOfFile: dir.appendingPathComponent(name).path) else { return nil }
        cache.setObject(img, forKey: name as NSString); return img
    }
    static func delete(_ name: String?) {
        guard let name else { return }
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(name))
    }
}
