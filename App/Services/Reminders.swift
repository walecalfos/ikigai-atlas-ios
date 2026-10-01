import Foundation
import UserNotifications
import IkigaiCore

/// Local notifications for the daily rhythm and the pulse review. Nothing is sent to a server.
enum Reminders {
    static let morningID = "rhythm.morning"
    static let eveningID = "rhythm.evening"
    static let reviewID = "pulse.review"

    struct Settings: Equatable {
        var morningOn: Bool
        var morningMinutes: Int
        var eveningOn: Bool
        var eveningMinutes: Int
    }

    /// The reminder settings saved on this device.
    static var savedSettings: Settings {
        let d = UserDefaults.standard
        return Settings(morningOn: d.bool(forKey: "morningOn"),
                        morningMinutes: d.object(forKey: "morningMinutes") as? Int ?? 8 * 60,
                        eveningOn: d.bool(forKey: "eveningOn"),
                        eveningMinutes: d.object(forKey: "eveningMinutes") as? Int ?? 21 * 60)
    }

    /// Asks for permission the first time a reminder is switched on.
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let current = await center.notificationSettings()
        switch current.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .denied: return false
        default:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        }
    }

    /// Replaces all scheduled reminders to match the current settings and atlas.
    static func reschedule(_ settings: Settings, atlas: Atlas) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningID, eveningID, reviewID])
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        if settings.morningOn {
            let question = atlas.rhythm.morning.hasText ? atlas.rhythm.morning.trimmed : Framework.defaultMorningQuestion
            await add(center, id: morningID, title: "This morning", body: question, minutes: settings.morningMinutes)
        }
        if settings.eveningOn {
            let question = atlas.rhythm.evening.hasText ? atlas.rhythm.evening.trimmed : Framework.defaultEveningQuestion
            await add(center, id: eveningID, title: "This evening", body: question, minutes: settings.eveningMinutes)
        }
        if let review = atlas.rhythm.review, review > Date() {
            var parts = Calendar.current.dateComponents([.year, .month, .day], from: review)
            parts.hour = 9
            parts.minute = 0
            let content = UNMutableNotificationContent()
            content.title = "Time to retake your pulse"
            content.body = "See how your ikigai has changed since you made your atlas."
            content.sound = .default
            let request = UNNotificationRequest(identifier: reviewID, content: content,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
            try? await center.add(request)
        }
    }

    private static func add(_ center: UNUserNotificationCenter, id: String, title: String, body: String, minutes: Int) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        var parts = DateComponents()
        parts.hour = minutes / 60
        parts.minute = minutes % 60
        let request = UNNotificationRequest(identifier: id, content: content,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: true))
        try? await center.add(request)
    }
}
