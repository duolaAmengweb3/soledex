import Foundation
import UserNotifications

enum Notifier {
    static func requestAuth() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    static func fireGrailAlert(_ items: [WishItem]) {
        guard !items.isEmpty else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { s in
            guard s.authorizationStatus == .authorized || s.authorizationStatus == .provisional else { return }
            let c = UNMutableNotificationContent()
            if items.count == 1 {
                c.title = "🔥 Grail price drop"
                c.body = "\(items[0].name) is down to \(items[0].currentValue.usd) — at or under your \(items[0].targetPrice.usd) target."
            } else {
                c.title = "🔥 \(items.count) grails hit your target"
                c.body = items.prefix(3).map { $0.name }.joined(separator: ", ")
            }
            c.sound = .default
            let req = UNNotificationRequest(identifier: "grail-\(items.first?.id.uuidString ?? "x")", content: c, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
            center.add(req)
        }
    }
}
