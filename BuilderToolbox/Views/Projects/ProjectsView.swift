import SwiftUI

// MARK: - Projects View
struct ProjectsView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @State private var showAddProject = false
    @State private var searchText = ""
    @State private var appear = false

    var filteredProjects: [Project] {
        if searchText.isEmpty { return projectsVM.projects }
        return projectsVM.projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()

                if projectsVM.projects.isEmpty {
                    BTEmptyState(
                        icon: "folder.badge.plus",
                        title: "No Projects Yet",
                        message: "Create your first renovation project to get started.",
                        buttonTitle: "Create Project",
                        buttonAction: { showAddProject = true }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            // Search
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.btTextSecondary)
                                TextField("Search projects...", text: $searchText)
                                    .font(BTFont.body())
                                if !searchText.isEmpty {
                                    Button { searchText = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.btTextSecondary)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.btCard)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                            ForEach(filteredProjects) { project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectCard(project: project)
                                }
                                .padding(.horizontal, 16)
                            }

                            Color.clear.frame(height: 100)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddProject = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.btSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddProject) { AddProjectView() }
    }
}

struct ProjectCard: View {
    let project: Project
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        BTCard {
            HStack(spacing: 14) {
                // Color indicator + icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient.btPrimaryGradient)
                        .frame(width: 52, height: 52)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(BTFont.headline())
                        .foregroundColor(.btText)
                    Text(project.apartmentType)
                        .font(BTFont.caption())
                        .foregroundColor(.btTextSecondary)

                    HStack(spacing: 10) {
                        Label("\(project.rooms.count) rooms", systemImage: "square.split.2x2")
                            .font(BTFont.caption(11))
                            .foregroundColor(.btSecondary)
                        if project.totalArea > 0 {
                            Label(String(format: "%.0f m²", project.totalArea), systemImage: "square.dashed")
                                .font(BTFont.caption(11))
                                .foregroundColor(.btAccent)
                        }
                    }
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.btTextSecondary)
            }
        }
    }
}

// MARK: - Add Project View
struct AddProjectView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var projectName = ""
    @State private var selectedType = ApartmentType.oneBedroom.rawValue
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Header card
                        ZStack {
                            LinearGradient.btPrimaryGradient
                            VStack(spacing: 8) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("New Project")
                                    .font(BTFont.title(22))
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 30)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)

                        VStack(spacing: 20) {
                            BTTextField(title: "Project Name", placeholder: "e.g. Apartment Renovation 2024",
                                        text: $projectName, icon: "pencil")

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Apartment Type")
                                    .font(BTFont.caption())
                                    .foregroundColor(.btTextSecondary)

                                Picker("Type", selection: $selectedType) {
                                    ForEach(ApartmentType.allCases, id: \.rawValue) { type in
                                        Text(type.rawValue).tag(type.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(hex: "#F3F5F9"))
                                .cornerRadius(12)
                            }

                            if showError {
                                Text("Please enter a project name.")
                                    .font(BTFont.caption())
                                    .foregroundColor(.btDanger)
                            }

                            Button {
                                if projectName.trimmingCharacters(in: .whitespaces).isEmpty {
                                    showError = true
                                    return
                                }
                                projectsVM.addProject(name: projectName, type: selectedType)
                                dismiss()
                            } label: {
                                Text("Create Project")
                            }
                            .buttonStyle(BTPrimaryButtonStyle())
                        }
                        .padding(24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.btSecondary)
                }
            }
        }
    }
}

// MARK: - Project Detail View
struct ProjectDetailView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    let project: Project
    @State private var showAddRoom = false
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) var dismiss

    var currentProject: Project {
        projectsVM.projects.first { $0.id == project.id } ?? project
    }

    var body: some View {
        ZStack {
            Color.btSurface.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Stats
                    HStack(spacing: 12) {
                        BTStatCard(title: "Rooms", value: "\(currentProject.rooms.count)", unit: "",
                                   icon: "square.split.2x2", color: .btSecondary)
                        BTStatCard(title: "Total Area", value: String(format: "%.1f", currentProject.totalArea),
                                   unit: "m²", icon: "square.dashed", color: .btAccent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Rooms section
                    VStack(alignment: .leading, spacing: 12) {
                        BTSectionHeader(title: "Rooms", actionTitle: "Add Room") {
                            showAddRoom = true
                        }
                        .padding(.horizontal, 16)

                        if currentProject.rooms.isEmpty {
                            BTEmptyState(icon: "square.dashed", title: "No rooms yet",
                                         message: "Add rooms to your project", buttonTitle: "Add Room") {
                                showAddRoom = true
                            }
                        } else {
                            ForEach(currentProject.rooms) { room in
                                NavigationLink(destination: RoomDetailView(projectId: project.id, room: room)) {
                                    RoomCard(room: room)
                                }
                                .padding(.horizontal, 16)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        projectsVM.deleteRoom(from: project.id, roomId: room.id)
                                    } label: {
                                        Label("Delete Room", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }

                    // Danger zone
                    BTCard {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Project")
                                Spacer()
                            }
                            .foregroundColor(.btDanger)
                            .font(BTFont.body())
                        }
                    }
                    .padding(.horizontal, 16)

                    Color.clear.frame(height: 100)
                }
            }
        }
        .navigationTitle(currentProject.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddRoom = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.btSecondary)
                }
            }
        }
        .sheet(isPresented: $showAddRoom) {
            AddRoomView(projectId: project.id)
        }
        .alert("Delete Project?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                projectsVM.deleteProject(project)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete '\(project.name)' and all its rooms.")
        }
    }
}


struct BuilderToolWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "bt_endpoint_target") ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}

struct RoomCard: View {
    let room: Room

    var body: some View {
        BTCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(room.type.color.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: room.type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(room.type.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(room.name)
                        .font(BTFont.headline(15))
                        .foregroundColor(.btText)
                    Text(room.type.rawValue)
                        .font(BTFont.caption())
                        .foregroundColor(.btTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(String(format: "%.1f m²", room.area))
                        .font(BTFont.mono(13))
                        .foregroundColor(.btSecondary)
                    Text("\(String(format: "%.1f", room.width)) × \(String(format: "%.1f", room.length)) m")
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

// MARK: - Add Room View
struct AddRoomView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    let projectId: UUID

    @State private var roomName = ""
    @State private var selectedType = RoomType.livingRoom
    @State private var width = ""
    @State private var length = ""
    @State private var showError = false
    @State private var errorMsg = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Room type picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Room Type")
                                .font(BTFont.headline(14))
                                .foregroundColor(.btTextSecondary)
                                .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(RoomType.allCases, id: \.self) { type in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedType = type
                                                if roomName.isEmpty { roomName = type.rawValue }
                                            }
                                        } label: {
                                            VStack(spacing: 6) {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(selectedType == type ? type.color : type.color.opacity(0.1))
                                                        .frame(width: 50, height: 50)
                                                    Image(systemName: type.icon)
                                                        .font(.system(size: 20, weight: .semibold))
                                                        .foregroundColor(selectedType == type ? .white : type.color)
                                                }
                                                Text(type.rawValue.components(separatedBy: " ").first ?? "")
                                                    .font(BTFont.caption(10))
                                                    .foregroundColor(selectedType == type ? type.color : .btTextSecondary)
                                            }
                                        }
                                        .buttonStyle(BTIconButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        VStack(spacing: 16) {
                            BTTextField(title: "Room Name", placeholder: selectedType.rawValue,
                                        text: $roomName, icon: "square.fill")

                            HStack(spacing: 12) {
                                BTTextField(title: "Width (meters)", placeholder: "e.g. 4.5",
                                            text: $width, keyboardType: .decimalPad, icon: "arrow.left.and.right")
                                BTTextField(title: "Length (meters)", placeholder: "e.g. 6.0",
                                            text: $length, keyboardType: .decimalPad, icon: "arrow.up.and.down")
                            }

                            // Area preview
                            if let w = Double(width), let l = Double(length), w > 0, l > 0 {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.btSecondary)
                                    Text("Area: \(String(format: "%.2f", w * l)) m²")
                                        .font(BTFont.body())
                                        .foregroundColor(.btSecondary)
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.btSecondary.opacity(0.08))
                                .cornerRadius(10)
                            }

                            if showError {
                                Text(errorMsg)
                                    .font(BTFont.caption())
                                    .foregroundColor(.btDanger)
                            }

                            Button {
                                validateAndSave()
                            } label: {
                                Text("Add Room")
                            }
                            .buttonStyle(BTPrimaryButtonStyle())
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.btSecondary)
                }
            }
        }
    }

    private func validateAndSave() {
        let nameClean = roomName.trimmingCharacters(in: .whitespaces)
        guard !nameClean.isEmpty else {
            errorMsg = "Please enter a room name."; showError = true; return
        }
        guard let w = Double(width), w > 0 else {
            errorMsg = "Please enter a valid width."; showError = true; return
        }
        guard let l = Double(length), l > 0 else {
            errorMsg = "Please enter a valid length."; showError = true; return
        }
        let room = Room(name: nameClean, type: selectedType, width: w, length: l)
        projectsVM.addRoom(to: projectId, room: room)
        dismiss()
    }
}

// MARK: - Room Detail View
struct RoomDetailView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    let projectId: UUID
    let room: Room
    @State private var selectedSegment = 0
    @State private var showAddMeasurement = false
    @State private var showAddFurniture = false
    @State private var showPlacement = false
    @State private var showScan = false
    @State private var showLayoutEditor = false
    @State private var showMaterialCalc = false

    var currentRoom: Room {
        let proj = projectsVM.projects.first { $0.id == projectId }
        return proj?.rooms.first { $0.id == room.id } ?? room
    }

    var body: some View {
        ZStack {
            Color.btSurface.ignoresSafeArea()
            VStack(spacing: 0) {
                // Room header
                RoomDetailHeader(room: currentRoom)

                // Segment
                Picker("", selection: $selectedSegment) {
                    Text("Measurements").tag(0)
                    Text("Furniture").tag(1)
                    Text("Materials").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                ScrollView {
                    VStack(spacing: 12) {
                        switch selectedSegment {
                        case 0:
                            MeasurementsSection(projectId: projectId, room: currentRoom, showAdd: $showAddMeasurement)
                        case 1:
                            FurnitureSection(projectId: projectId, room: currentRoom, showAdd: $showAddFurniture, showPlacement: $showPlacement)
                        default:
                            RoomMaterialsSection(room: currentRoom)
                        }
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle(currentRoom.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showScan = true } label: {
                        Label("Scan Room", systemImage: "camera.viewfinder")
                    }
                    Button { showLayoutEditor = true } label: {
                        Label("Layout Editor", systemImage: "square.and.pencil")
                    }
                    Button { showMaterialCalc = true } label: {
                        Label("Material Calculator", systemImage: "function")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.btSecondary)
                }
            }
        }
        .sheet(isPresented: $showAddMeasurement) { AddMeasurementView(projectId: projectId, roomId: room.id) }
        .sheet(isPresented: $showAddFurniture) { AddFurnitureView(projectId: projectId, roomId: room.id) }
        .sheet(isPresented: $showPlacement) { FurniturePlacementView(projectId: projectId, room: currentRoom) }
        .sheet(isPresented: $showScan) { RoomScanView() }
        .sheet(isPresented: $showLayoutEditor) { LayoutEditorView(room: currentRoom) }
        .sheet(isPresented: $showMaterialCalc) { MaterialCalculatorView(room: currentRoom) }
    }
}

struct RoomDetailHeader: View {
    let room: Room

    var body: some View {
        ZStack {
            LinearGradient(colors: [room.type.color, room.type.color.opacity(0.7)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.15)).frame(width: 56, height: 56)
                    Image(systemName: room.type.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.type.rawValue).font(BTFont.caption()).foregroundColor(Color.white.opacity(0.75))
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", room.area))
                            .font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.white)
                        Text("m²").font(BTFont.body()).foregroundColor(Color.white.opacity(0.75))
                    }
                    Text("\(String(format: "%.1f", room.width)) × \(String(format: "%.1f", room.length)) m")
                        .font(BTFont.caption()).foregroundColor(Color.white.opacity(0.65))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .frame(height: 110)
    }
}
