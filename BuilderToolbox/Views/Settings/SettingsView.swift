import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: ApplicationMainState
    @State private var showDeleteConfirm = false
    @State private var showLogoutConfirm = false
    @State private var showProfile = false
    @State private var showReports = false
    @State private var showActivity = false
    @State private var showNotifications = false
    @State private var notifPermGranted = false
    @State private var showNotifDenied = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile card
                        Button { showProfile = true } label: {
                            BTCard {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient.btPrimaryGradient)
                                            .frame(width: 56, height: 56)
                                        Text(appState.userName.prefix(1).uppercased())
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(appState.userName.isEmpty ? "User" : appState.userName)
                                            .font(BTFont.headline())
                                            .foregroundColor(.btText)
                                        Text(appState.userEmail)
                                            .font(BTFont.caption())
                                            .foregroundColor(.btTextSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.btTextSecondary)
                                }
                            }
                        }
                        .buttonStyle(BTIconButtonStyle())
                        .padding(.horizontal, 16)

                        // Appearance
                        SettingsSection(title: "Appearance", icon: "paintpalette") {
                            VStack(spacing: 0) {
                                SettingsPicker(
                                    icon: "sun.max.fill",
                                    title: "Theme",
                                    selection: $appState.appTheme,
                                    options: [("Light", "light"), ("Dark", "dark"), ("System", "system")]
                                )
                                Divider().padding(.leading, 52)
                                SettingsPicker(
                                    icon: "ruler",
                                    title: "Measurement Units",
                                    selection: $appState.measurementUnit,
                                    options: [("Meters", "m"), ("Feet", "ft"), ("Centimeters", "cm"), ("Inches", "in")]
                                )
                            }
                        }

                        // Notifications
                        SettingsSection(title: "Notifications", icon: "bell") {
                            VStack(spacing: 0) {
                                SettingsToggle(
                                    icon: "bell.fill",
                                    title: "Enable Notifications",
                                    subtitle: notifPermGranted ? "Reminders are active" : "Tap to enable",
                                    isOn: $appState.notificationsEnabled
                                ) { enabled in
                                    if enabled {
                                        NotificationsManager.shared.requestPermission { granted in
                                            if granted {
                                                notifPermGranted = true
                                                NotificationsManager.shared.scheduleWeeklyReminder(enabled: true)
                                            } else {
                                                appState.notificationsEnabled = false
                                                showNotifDenied = true
                                            }
                                        }
                                    } else {
                                        NotificationsManager.shared.scheduleWeeklyReminder(enabled: false)
                                    }
                                }
                                Divider().padding(.leading, 52)
                                SettingsRowButton(icon: "bell.badge.fill", title: "Notification History", color: .btSecondary) {
                                    showNotifications = true
                                }
                            }
                        }

                        // Data & Analytics
                        SettingsSection(title: "Data & Reports", icon: "chart.bar") {
                            VStack(spacing: 0) {
                                SettingsRowButton(icon: "chart.pie.fill", title: "View Reports", color: .btSecondary) {
                                    showReports = true
                                }
                                Divider().padding(.leading, 52)
                                SettingsRowButton(icon: "clock.fill", title: "Activity History", color: .btAccent) {
                                    showActivity = true
                                }
                            }
                        }

                        // About
                        SettingsSection(title: "About", icon: "info.circle") {
                            VStack(spacing: 0) {
                                SettingsInfoRow(icon: "app.badge", title: "Version", value: "1.0.0")
                                Divider().padding(.leading, 52)
                                SettingsInfoRow(icon: "building.2", title: "Developer", value: "Anthropic")
                                Divider().padding(.leading, 52)
                                SettingsInfoRow(icon: "iphone", title: "Platform", value: "iOS 14+")
                            }
                        }

                        // Account actions
                        SettingsSection(title: "Account", icon: "person.circle") {
                            VStack(spacing: 0) {
                                SettingsRowButton(icon: "rectangle.portrait.and.arrow.right",
                                                  title: "Log Out", color: .btDanger) {
                                    showLogoutConfirm = true
                                }
                                Divider().padding(.leading, 52)
                                SettingsRowButton(icon: "trash.fill",
                                                  title: "Delete Account", color: .btDanger) {
                                    showDeleteConfirm = true
                                }
                            }
                        }

                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Log Out?", isPresented: $showLogoutConfirm) {
            Button("Log Out", role: .destructive) { appState.logout() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("You will need to log in again to access your data.") }

        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
            Button("Delete Account", role: .destructive) { appState.deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will permanently delete your account and all renovation data. This cannot be undone.") }

        .alert("Notifications Disabled", isPresented: $showNotifDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Please enable notifications in iOS Settings for BuilderToolbox.") }

        .sheet(isPresented: $showProfile) { ProfileView() }
        .sheet(isPresented: $showReports) { ReportsView() }
        .sheet(isPresented: $showActivity) { ActivityHistoryView() }
        .sheet(isPresented: $showNotifications) { NotificationsView() }
        .onAppear {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    notifPermGranted = settings.authorizationStatus == .authorized
                }
            }
        }
    }
}

// MARK: - Settings Components
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    @Environment(\.colorScheme) var colorScheme

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(BTFont.caption())
                .foregroundColor(.btTextSecondary)
                .padding(.horizontal, 16)

            BTCard(padding: 0) {
                content
            }
            .padding(.horizontal, 16)
        }
    }
}

struct SettingsPicker: View {
    let icon: String
    let title: String
    @Binding var selection: String
    let options: [(String, String)]

    var selectedLabel: String {
        options.first { $0.1 == selection }?.0 ?? selection
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.btSecondary)
                .frame(width: 24)
            Text(title).font(BTFont.body()).foregroundColor(.btText)
            Spacer()
            Picker(title, selection: $selection) {
                ForEach(options, id: \.1) { opt in
                    Text(opt.0).tag(opt.1)
                }
            }
            .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

struct SettingsToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var onChange: ((Bool) -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.btSecondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(BTFont.body()).foregroundColor(.btText)
                Text(subtitle).font(BTFont.caption()).foregroundColor(.btTextSecondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .btSecondary))
                .onChange(of: isOn) { newVal in onChange?(newVal) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

struct SettingsRowButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                Text(title).font(BTFont.body()).foregroundColor(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.btTextSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(BTIconButtonStyle())
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.btTextSecondary)
                .frame(width: 24)
            Text(title).font(BTFont.body()).foregroundColor(.btText)
            Spacer()
            Text(value).font(BTFont.body()).foregroundColor(.btTextSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: ApplicationMainState
    @Environment(\.dismiss) var dismiss
    @State private var editedName: String = ""
    @State private var editedEmail: String = ""
    @State private var isEditing = false
    @State private var saved = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(LinearGradient.btPrimaryGradient)
                                .frame(width: 100, height: 100)
                            Text(appState.userName.prefix(1).uppercased())
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 24)
                        .shadow(color: Color.btPrimary.opacity(0.3), radius: 16, x: 0, y: 8)

                        if isEditing {
                            VStack(spacing: 16) {
                                BTTextField(title: "Name", placeholder: "Your name",
                                            text: $editedName, icon: "person")
                                BTTextField(title: "Email", placeholder: "your@email.com",
                                            text: $editedEmail, keyboardType: .emailAddress, icon: "envelope")

                                HStack(spacing: 12) {
                                    Button { isEditing = false } label: { Text("Cancel") }
                                        .buttonStyle(BTSecondaryButtonStyle())
                                    Button {
                                        let n = editedName.trimmingCharacters(in: .whitespaces)
                                        let e = editedEmail.trimmingCharacters(in: .whitespaces)
                                        if !n.isEmpty { appState.userName = n }
                                        if !e.isEmpty { appState.userEmail = e }
                                        isEditing = false
                                        saved = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                                    } label: { Text("Save") }
                                    .buttonStyle(BTPrimaryButtonStyle())
                                }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            VStack(spacing: 8) {
                                Text(appState.userName.isEmpty ? "User" : appState.userName)
                                    .font(BTFont.title(24))
                                    .foregroundColor(.btText)
                                Text(appState.userEmail)
                                    .font(BTFont.body())
                                    .foregroundColor(.btTextSecondary)
                            }

                            Button { isEditing = true; editedName = appState.userName; editedEmail = appState.userEmail } label: {
                                Label("Edit Profile", systemImage: "pencil")
                            }
                            .buttonStyle(BTSecondaryButtonStyle())
                            .padding(.horizontal, 60)
                        }

                        if saved {
                            Label("Profile saved!", systemImage: "checkmark.circle.fill")
                                .font(BTFont.body())
                                .foregroundColor(.btSuccess)
                                .transition(.scale.combined(with: .opacity))
                        }

                        // Stats
                        BTCard {
                            VStack(spacing: 12) {
                                BTSectionHeader(title: "Account Info")
                                HStack {
                                    Text("Member since")
                                        .font(BTFont.body()).foregroundColor(.btTextSecondary)
                                    Spacer()
                                    Text("2024").font(BTFont.body()).foregroundColor(.btText)
                                }
                                HStack {
                                    Text("Measurement unit")
                                        .font(BTFont.body()).foregroundColor(.btTextSecondary)
                                    Spacer()
                                    Text(appState.measurementUnit.uppercased())
                                        .font(BTFont.body()).foregroundColor(.btText)
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        Color.clear.frame(height: 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.btSecondary)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: saved)
    }
}

// MARK: - Reports View
struct ReportsView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var shoppingVM: ShoppingViewModel
    @EnvironmentObject var tasksVM: TasksViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Overview
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            BTStatCard(title: "Projects", value: "\(projectsVM.projects.count)", unit: "",
                                       icon: "folder.fill", color: .btSecondary)
                            BTStatCard(title: "Total Area", value: String(format: "%.0f", projectsVM.totalArea),
                                       unit: "m²", icon: "square.dashed", color: .btAccent)
                            BTStatCard(title: "Rooms", value: "\(projectsVM.totalRooms)", unit: "",
                                       icon: "square.split.2x2", color: .btSuccess)
                            BTStatCard(title: "Tasks Done", value: "\(tasksVM.completedCount)", unit: "",
                                       icon: "checkmark.circle", color: Color(hex: "#9B59B6"))
                        }
                        .padding(.horizontal, 16)

                        // Shopping summary
                        BTCard {
                            VStack(alignment: .leading, spacing: 14) {
                                BTSectionHeader(title: "Shopping Summary")
                                HStack {
                                    Text("Total Items").font(BTFont.body()).foregroundColor(.btTextSecondary)
                                    Spacer()
                                    Text("\(shoppingVM.items.count)").font(BTFont.mono()).foregroundColor(.btText)
                                }
                                HStack {
                                    Text("Purchased").font(BTFont.body()).foregroundColor(.btTextSecondary)
                                    Spacer()
                                    Text("\(shoppingVM.purchasedCount)").font(BTFont.mono()).foregroundColor(.btSuccess)
                                }
                                HStack {
                                    Text("Est. Total Cost").font(BTFont.body()).foregroundColor(.btTextSecondary)
                                    Spacer()
                                    Text(String(format: "€%.2f", shoppingVM.totalEstimated))
                                        .font(BTFont.mono()).foregroundColor(.btAccent)
                                }

                                if shoppingVM.items.count > 0 {
                                    // Progress bar
                                    let progress = Double(shoppingVM.purchasedCount) / Double(shoppingVM.items.count)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Purchase Progress: \(Int(progress * 100))%")
                                            .font(BTFont.caption()).foregroundColor(.btTextSecondary)
                                        GeometryReader { g in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.btSuccess.opacity(0.15))
                                                    .frame(height: 8)
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.btSuccess)
                                                    .frame(width: g.size.width * progress, height: 8)
                                            }
                                        }
                                        .frame(height: 8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Task summary
                        BTCard {
                            VStack(alignment: .leading, spacing: 14) {
                                BTSectionHeader(title: "Task Summary")
                                HStack {
                                    Text("Total Tasks").font(BTFont.body()).foregroundColor(.btTextSecondary)
                                    Spacer()
                                    Text("\(tasksVM.tasks.count)").font(BTFont.mono()).foregroundColor(.btText)
                                }
                                HStack {
                                    Text("Completed").font(BTFont.body()).foregroundColor(.btTextSecondary)
                                    Spacer()
                                    Text("\(tasksVM.completedCount)").font(BTFont.mono()).foregroundColor(.btSuccess)
                                }
                                HStack {
                                    Text("Overdue").font(BTFont.body()).foregroundColor(.btTextSecondary)
                                    Spacer()
                                    Text("\(tasksVM.overdueCount)").font(BTFont.mono()).foregroundColor(.btDanger)
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Room types breakdown
                        if !projectsVM.projects.isEmpty {
                            BTCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    BTSectionHeader(title: "Room Types")
                                    let allRooms = projectsVM.projects.flatMap { $0.rooms }
                                    let byType = Dictionary(grouping: allRooms, by: { $0.type })

                                    ForEach(RoomType.allCases.filter { byType[$0] != nil }, id: \.self) { type in
                                        let rooms = byType[type] ?? []
                                        let totalArea = rooms.reduce(0) { $0 + $1.area }
                                        HStack {
                                            Image(systemName: type.icon)
                                                .foregroundColor(type.color)
                                                .frame(width: 20)
                                            Text(type.rawValue).font(BTFont.body()).foregroundColor(.btText)
                                            Spacer()
                                            Text("\(rooms.count) room\(rooms.count != 1 ? "s" : "")")
                                                .font(BTFont.caption()).foregroundColor(.btTextSecondary)
                                            Text(String(format: "%.1f m²", totalArea))
                                                .font(BTFont.mono(12)).foregroundColor(type.color)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        Color.clear.frame(height: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.btSecondary)
                }
            }
        }
    }
}

// MARK: - Activity History View
struct ActivityHistoryView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                if projectsVM.activities.isEmpty {
                    BTEmptyState(icon: "clock", title: "No Activity", message: "Your actions will appear here.")
                } else {
                    List {
                        ForEach(projectsVM.activities) { activity in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.btSecondary.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: activity.icon)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.btSecondary)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(activity.title)
                                        .font(BTFont.body())
                                        .foregroundColor(.btText)
                                    Text(activity.description)
                                        .font(BTFont.caption())
                                        .foregroundColor(.btTextSecondary)
                                    Text(formatDateTime(activity.timestamp))
                                        .font(BTFont.caption(10))
                                        .foregroundColor(.btTextSecondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Activity History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.btSecondary)
                }
            }
        }
    }

    private func formatDateTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}
