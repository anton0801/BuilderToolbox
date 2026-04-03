import SwiftUI
import Combine
import UserNotifications

// MARK: - App State
class AppState: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("appTheme") var appTheme: String = "system"
    @AppStorage("measurementUnit") var measurementUnit: String = "m"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userEmail") var userEmail: String = ""
    @AppStorage("selectedTab") var selectedTab: Int = 0

    var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    func logout() {
        isLoggedIn = false
        userName = ""
        userEmail = ""
    }

    func deleteAccount() {
        isLoggedIn = false
        hasCompletedOnboarding = false
        userName = ""
        userEmail = ""
        // Clear all persisted data
        UserDefaults.standard.removeObject(forKey: "projects_data")
        UserDefaults.standard.removeObject(forKey: "shopping_data")
        UserDefaults.standard.removeObject(forKey: "tasks_data")
        UserDefaults.standard.removeObject(forKey: "activity_data")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - Auth ViewModel
class AuthViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false

    func login(appState: AppState, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            isLoading = false
            completion(false)
            return
        }
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email."
            isLoading = false
            completion(false)
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            isLoading = false
            completion(false)
            return
        }
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            appState.userEmail = self.email
            appState.userName = self.email.components(separatedBy: "@").first?.capitalized ?? "User"
            appState.isLoggedIn = true
            self.isLoading = false
            completion(true)
        }
    }

    func signUp(appState: AppState, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            isLoading = false
            completion(false)
            return
        }
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email."
            isLoading = false
            completion(false)
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            isLoading = false
            completion(false)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            appState.userName = self.name
            appState.userEmail = self.email
            appState.isLoggedIn = true
            self.isLoading = false
            completion(true)
        }
    }
}

// MARK: - Projects ViewModel
class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var activities: [ActivityEntry] = []

    private let projectsKey = "projects_data"
    private let activityKey = "activity_data"

    init() {
        loadProjects()
        loadActivity()
    }

    func addProject(name: String, type: String) {
        let project = Project(name: name, apartmentType: type)
        projects.insert(project, at: 0)
        saveProjects()
        logActivity(title: "Project Created", description: "Created '\(name)'", icon: "folder.fill.badge.plus", category: "Project")
    }

    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        saveProjects()
        logActivity(title: "Project Deleted", description: "Deleted '\(project.name)'", icon: "trash.fill", category: "Project")
    }

    func addRoom(to projectId: UUID, room: Room) {
        guard let idx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[idx].rooms.append(room)
        projects[idx].updatedAt = Date()
        saveProjects()
        logActivity(title: "Room Added", description: "Added '\(room.name)' to project", icon: "square.fill", category: "Room")
    }

    func deleteRoom(from projectId: UUID, roomId: UUID) {
        guard let idx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[idx].rooms.removeAll { $0.id == roomId }
        projects[idx].updatedAt = Date()
        saveProjects()
    }

    func updateRoom(in projectId: UUID, room: Room) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let rIdx = projects[pIdx].rooms.firstIndex(where: { $0.id == room.id }) else { return }
        projects[pIdx].rooms[rIdx] = room
        projects[pIdx].updatedAt = Date()
        saveProjects()
    }

    func addMeasurement(to roomId: UUID, in projectId: UUID, measurement: Measurement) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let rIdx = projects[pIdx].rooms.firstIndex(where: { $0.id == roomId }) else { return }
        projects[pIdx].rooms[rIdx].measurements.append(measurement)
        saveProjects()
        logActivity(title: "Measurement Added", description: "\(measurement.label): \(String(format: "%.2f", measurement.length)) m", icon: "ruler.fill", category: "Measurement")
    }

    func deleteMeasurement(from roomId: UUID, in projectId: UUID, measurementId: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let rIdx = projects[pIdx].rooms.firstIndex(where: { $0.id == roomId }) else { return }
        projects[pIdx].rooms[rIdx].measurements.removeAll { $0.id == measurementId }
        saveProjects()
    }

    func addFurniture(to roomId: UUID, in projectId: UUID, furniture: FurnitureItem) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let rIdx = projects[pIdx].rooms.firstIndex(where: { $0.id == roomId }) else { return }
        projects[pIdx].rooms[rIdx].furniture.append(furniture)
        saveProjects()
        logActivity(title: "Furniture Added", description: "Added \(furniture.name)", icon: "chair.fill", category: "Furniture")
    }

    func deleteFurniture(from roomId: UUID, in projectId: UUID, furnitureId: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let rIdx = projects[pIdx].rooms.firstIndex(where: { $0.id == roomId }) else { return }
        projects[pIdx].rooms[rIdx].furniture.removeAll { $0.id == furnitureId }
        saveProjects()
    }

    func updateFurniturePosition(in roomId: UUID, projectId: UUID, furnitureId: UUID, x: Double, y: Double, rotation: Double) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let rIdx = projects[pIdx].rooms.firstIndex(where: { $0.id == roomId }),
              let fIdx = projects[pIdx].rooms[rIdx].furniture.firstIndex(where: { $0.id == furnitureId }) else { return }
        projects[pIdx].rooms[rIdx].furniture[fIdx].positionX = x
        projects[pIdx].rooms[rIdx].furniture[fIdx].positionY = y
        projects[pIdx].rooms[rIdx].furniture[fIdx].rotation = rotation
        saveProjects()
    }

    func logActivity(title: String, description: String, icon: String, category: String) {
        let entry = ActivityEntry(title: title, description: description, icon: icon, category: category)
        activities.insert(entry, at: 0)
        if activities.count > 50 { activities = Array(activities.prefix(50)) }
        saveActivity()
    }

    var totalArea: Double { projects.reduce(0) { $0 + $1.totalArea } }
    var totalRooms: Int { projects.reduce(0) { $0 + $1.rooms.count } }

    private func saveProjects() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: projectsKey)
        }
    }

    private func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: projectsKey),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
    }

    private func saveActivity() {
        if let data = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(data, forKey: activityKey)
        }
    }

    private func loadActivity() {
        if let data = UserDefaults.standard.data(forKey: activityKey),
           let decoded = try? JSONDecoder().decode([ActivityEntry].self, from: data) {
            activities = decoded
        }
    }
}

// MARK: - Shopping ViewModel
class ShoppingViewModel: ObservableObject {
    @Published var items: [ShoppingItem] = []
    private let key = "shopping_data"

    init() { loadItems() }

    func addItem(name: String, quantity: Double, unit: String, category: String, price: Double) {
        let item = ShoppingItem(name: name, quantity: quantity, unit: unit, category: category, estimatedPrice: price)
        items.insert(item, at: 0)
        saveItems()
    }

    func deleteItem(_ item: ShoppingItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }

    func togglePurchased(_ item: ShoppingItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isPurchased.toggle()
        saveItems()
    }

    var totalEstimated: Double { items.reduce(0) { $0 + $1.estimatedPrice * $1.quantity } }
    var purchasedCount: Int { items.filter { $0.isPurchased }.count }

    private func saveItems() {
        if let data = try? JSONEncoder().encode(items) { UserDefaults.standard.set(data, forKey: key) }
    }
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([ShoppingItem].self, from: data) { items = decoded }
    }
}

// MARK: - Tasks ViewModel
class TasksViewModel: ObservableObject {
    @Published var tasks: [RenovationTask] = []
    private let key = "tasks_data"

    init() { loadTasks() }

    func addTask(title: String, notes: String, dueDate: Date, priority: TaskPriority, category: TaskCategory) {
        let task = RenovationTask(title: title, notes: notes, dueDate: dueDate, priority: priority, category: category)
        tasks.insert(task, at: 0)
        saveTasks()
    }

    func deleteTask(_ task: RenovationTask) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    func toggleCompleted(_ task: RenovationTask) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].isCompleted.toggle()
        saveTasks()
    }

    var completedCount: Int { tasks.filter { $0.isCompleted }.count }
    var pendingCount: Int { tasks.filter { !$0.isCompleted }.count }
    var overdueCount: Int { tasks.filter { !$0.isCompleted && $0.dueDate < Date() }.count }

    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) { UserDefaults.standard.set(data, forKey: key) }
    }
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([RenovationTask].self, from: data) { tasks = decoded }
    }
}

// MARK: - Notifications Manager
class NotificationsManager: ObservableObject {
    static let shared = NotificationsManager()

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func scheduleTaskReminder(for task: RenovationTask) {
        let content = UNMutableNotificationContent()
        content.title = "BuilderToolbox Reminder"
        content.body = "Task due: \(task.title)"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(for taskId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [taskId.uuidString])
    }

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func scheduleWeeklyReminder(enabled: Bool) {
        cancelAllReminders()
        guard enabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "BuilderToolbox"
        content.body = "Don't forget to update your renovation progress!"
        content.sound = .default
        var components = DateComponents()
        components.weekday = 2 // Monday
        components.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
