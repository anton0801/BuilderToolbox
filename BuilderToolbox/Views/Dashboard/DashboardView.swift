import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                ProjectsView()
                    .tag(1)
                ShoppingListView()
                    .tag(2)
                TasksView()
                    .tag(3)
                SettingsView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Tab Bar
            BTTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct BTTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme

    let tabs: [(icon: String, selectedIcon: String, label: String)] = [
        ("house", "house.fill", "Home"),
        ("folder", "folder.fill", "Projects"),
        ("cart", "cart.fill", "Shopping"),
        ("checklist", "checklist", "Tasks"),
        ("gearshape", "gearshape.fill", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == i {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.btSecondary.opacity(0.15))
                                    .frame(width: 44, height: 30)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            Image(systemName: selectedTab == i ? tabs[i].selectedIcon : tabs[i].icon)
                                .font(.system(size: 19, weight: selectedTab == i ? .semibold : .regular))
                                .foregroundColor(selectedTab == i ? .btSecondary : .btTextSecondary)
                                .scaleEffect(selectedTab == i ? 1.1 : 1.0)
                        }
                        Text(tabs[i].label)
                            .font(.system(size: 10, weight: selectedTab == i ? .semibold : .regular, design: .rounded))
                            .foregroundColor(selectedTab == i ? .btSecondary : .btTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(BTIconButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color(hex: "#1C2436") : Color.white)
                RoundedRectangle(cornerRadius: 24)
                    .stroke(colorScheme == .dark ? Color(hex: "#2E3A50") : Color(hex: "#E4E8EF"), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.1), radius: 16, x: 0, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var appState: AppState
    @State private var appear = false
    @State private var showQuickAdd = false
    @State private var showScan = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    DashboardHeader(showQuickAdd: $showQuickAdd)

                    VStack(spacing: 20) {
                        // Stats Row
                        HStack(spacing: 12) {
                            BTStatCard(
                                title: "Total Area",
                                value: String(format: "%.1f", projectsVM.totalArea),
                                unit: "m²",
                                icon: "square.dashed",
                                color: .btSecondary
                            )
                            BTStatCard(
                                title: "Projects",
                                value: "\(projectsVM.projects.count)",
                                unit: "",
                                icon: "folder.fill",
                                color: .btAccent
                            )
                            BTStatCard(
                                title: "Rooms",
                                value: "\(projectsVM.totalRooms)",
                                unit: "",
                                icon: "square.split.2x2",
                                color: .btSuccess
                            )
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 16)

                        // Quick Actions
                        BTCard {
                            VStack(alignment: .leading, spacing: 14) {
                                BTSectionHeader(title: "Quick Actions")

                                HStack(spacing: 12) {
                                    QuickActionButton(
                                        icon: "camera.viewfinder",
                                        label: "Scan Room",
                                        color: Color(hex: "#2D7DD2")
                                    ) { showScan = true }

                                    NavigationLink(destination: ProjectsView()) {
                                        QuickActionCard(icon: "folder.badge.plus", label: "New Project", color: Color(hex: "#F4A623"))
                                    }

                                    NavigationLink(destination: ShoppingListView()) {
                                        QuickActionCard(icon: "cart.badge.plus", label: "Shopping", color: Color(hex: "#27AE60"))
                                    }

                                    NavigationLink(destination: TasksView()) {
                                        QuickActionCard(icon: "checklist.checked", label: "Tasks", color: Color(hex: "#9B59B6"))
                                    }
                                }
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 16)

                        // Recent Rooms
                        if !projectsVM.projects.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                BTSectionHeader(title: "Recent Rooms")

                                let recentRooms = projectsVM.projects.flatMap { p in
                                    p.rooms.map { (project: p, room: $0) }
                                }.prefix(4)

                                if recentRooms.isEmpty {
                                    BTEmptyState(icon: "square.dashed", title: "No rooms yet",
                                                 message: "Add rooms to your projects")
                                } else {
                                    ForEach(Array(recentRooms), id: \.room.id) { item in
                                        NavigationLink(destination: RoomDetailView(projectId: item.project.id, room: item.room)) {
                                            RecentRoomCard(room: item.room, projectName: item.project.name)
                                        }
                                    }
                                }
                            }
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 16)
                        }

                        // Activity
                        if !projectsVM.activities.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                BTSectionHeader(title: "Recent Activity")
                                ForEach(projectsVM.activities.prefix(5)) { activity in
                                    ActivityRow(activity: activity)
                                }
                            }
                            .opacity(appear ? 1 : 0)
                        }

                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .background(Color.btSurface.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) { appear = true }
        }
        .sheet(isPresented: $showScan) { RoomScanView() }
        .sheet(isPresented: $showQuickAdd) { AddProjectView() }
    }
}

struct DashboardHeader: View {
    @EnvironmentObject var appState: AppState
    @Binding var showQuickAdd: Bool

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        else if hour < 17 { return "Good afternoon" }
        else { return "Good evening" }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient.btPrimaryGradient
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(BTFont.body())
                    .foregroundColor(Color.white.opacity(0.65))
                Text(appState.userName.isEmpty ? "Builder" : appState.userName)
                    .font(BTFont.title(26))
                    .foregroundColor(.white)
                Text("Plan your perfect space")
                    .font(BTFont.caption())
                    .foregroundColor(Color.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .padding(.top, 56)

            HStack {
                Spacer()
                Button { showQuickAdd = true } label: {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.15)).frame(width: 40, height: 40)
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
        .frame(height: 160)
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            QuickActionCard(icon: icon, label: label, color: color)
        }
        .buttonStyle(BTIconButtonStyle())
    }
}

struct QuickActionCard: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.btTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecentRoomCard: View {
    let room: Room
    let projectName: String

    var body: some View {
        BTCard(padding: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(room.type.color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: room.type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(room.type.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(room.name)
                        .font(BTFont.headline(15))
                        .foregroundColor(.btText)
                    Text(projectName)
                        .font(BTFont.caption())
                        .foregroundColor(.btTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f m²", room.area))
                        .font(BTFont.mono(13))
                        .foregroundColor(.btSecondary)
                    Text("\(room.measurements.count) measures")
                        .font(BTFont.caption(10))
                        .foregroundColor(.btTextSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.btTextSecondary)
            }
        }
    }
}

struct ActivityRow: View {
    let activity: ActivityEntry

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.btSecondary.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: activity.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.btSecondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(BTFont.body(13))
                    .foregroundColor(.btText)
                Text(activity.description)
                    .font(BTFont.caption())
                    .foregroundColor(.btTextSecondary)
            }
            Spacer()
            Text(relativeTime(activity.timestamp))
                .font(BTFont.caption(10))
                .foregroundColor(.btTextSecondary)
        }
        .padding(.vertical, 4)
    }

    func relativeTime(_ date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 60 { return "just now" }
        if diff < 3600 { return "\(diff/60)m ago" }
        if diff < 86400 { return "\(diff/3600)h ago" }
        return "\(diff/86400)d ago"
    }
}
