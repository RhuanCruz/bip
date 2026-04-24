import Foundation
import UserNotifications

enum TaskNotificationScheduler {
    static func scheduleIfNeeded(for task: Task) async {
        cancel(for: task)

        guard
            let reminder = task.reminder,
            reminder.enabled,
            let scheduledAt = task.scheduledAt
        else {
            return
        }

        let fireDate = scheduledAt.addingTimeInterval(TimeInterval(-reminder.offsetMinutes * 60))
        guard fireDate > Date() else {
            return
        }

        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = task.title
            content.body = "BIP reminder"
            content.sound = .default

            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: identifier(for: task), content: content, trigger: trigger)
            try await center.add(request)
        } catch {
            print("Failed to schedule task notification: \(error)")
        }
    }

    static func cancel(for task: Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(for: task)])
    }

    private static func identifier(for task: Task) -> String {
        "bip-task-\(task.id.uuidString)"
    }
}
