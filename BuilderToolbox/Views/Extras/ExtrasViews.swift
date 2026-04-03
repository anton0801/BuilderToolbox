import SwiftUI

// MARK: - Layout Editor View
struct LayoutEditorView: View {
    @Environment(\.dismiss) var dismiss
    var room: Room

    @State private var walls: [EditorWall] = []
    @State private var doors: [EditorDoor] = []
    @State private var windows: [EditorWindow] = []
    @State private var selectedTool: LayoutTool = .select
    @State private var selectedWallIndex: Int? = nil
    @State private var showSaved = false

    enum LayoutTool: String, CaseIterable {
        case select = "cursor.arrow"
        case wall   = "square"
        case door   = "door.left.hand.open"
        case window = "rectangle.split.2x1"
        case erase  = "eraser"

        var label: String {
            switch self {
            case .select: return "Select"
            case .wall:   return "Wall"
            case .door:   return "Door"
            case .window: return "Window"
            case .erase:  return "Erase"
            }
        }
    }

    struct EditorWall: Identifiable {
        let id = UUID()
        var start: CGPoint
        var end: CGPoint
        var thickness: CGFloat = 8
    }

    struct EditorDoor: Identifiable {
        let id = UUID()
        var position: CGPoint
        var width: CGFloat = 40
        var label: String = "Door"
    }

    struct EditorWindow: Identifiable {
        let id = UUID()
        var position: CGPoint
        var width: CGFloat = 50
        var label: String = "Window"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                toolBar
                canvasArea
                bottomBar
            }
            .background(Color.btSurface.ignoresSafeArea())
            .navigationTitle("Layout: \(room.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.btSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveLayout() }
                        .foregroundColor(.btAccent)
                        .fontWeight(.semibold)
                }
            }
            .overlay(
                Group {
                    if showSaved {
                        Text("✓ Layout Saved")
                            .font(BTFont.body())
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.btSuccess)
                            .cornerRadius(20)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, 8)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showSaved),
                alignment: .top
            )
        }
        .onAppear { loadLayout() }
    }

    // MARK: - Tool Bar
    private var toolBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LayoutTool.allCases, id: \.self) { tool in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTool = tool
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tool.rawValue)
                                .font(.system(size: 18))
                            Text(tool.label)
                                .font(BTFont.caption(10))
                        }
                        .foregroundColor(selectedTool == tool ? .white : .btText)
                        .frame(width: 64, height: 56)
                        .background(selectedTool == tool ? Color.btAccent : Color.btCard)
                        .cornerRadius(12)
                    }
                }

                Divider().frame(height: 40)

                Button {
                    let newDoor = EditorDoor(position: CGPoint(x: 200, y: 200))
                    withAnimation { doors.append(newDoor) }
                } label: {
                    Label("Add Door", systemImage: "plus")
                        .font(BTFont.caption())
                        .foregroundColor(.btAccent)
                        .padding(.horizontal, 12)
                        .frame(height: 56)
                        .background(Color.btAccent.opacity(0.1))
                        .cornerRadius(12)
                }

                Button {
                    let newWin = EditorWindow(position: CGPoint(x: 250, y: 150))
                    withAnimation { windows.append(newWin) }
                } label: {
                    Label("Add Window", systemImage: "plus")
                        .font(BTFont.caption())
                        .foregroundColor(.btSecondary)
                        .padding(.horizontal, 12)
                        .frame(height: 56)
                        .background(Color.btSecondary.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.btSurface)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Canvas
    private var canvasArea: some View {
        GeometryReader { geo in
            ZStack {
                gridBackground(size: geo.size)

                ForEach(Array(walls.enumerated()), id: \.element.id) { idx, wall in
                    Canvas { context, _ in
                        var path = Path()
                        path.move(to: wall.start)
                        path.addLine(to: wall.end)
                        context.stroke(path,
                            with: .color(selectedWallIndex == idx ? Color.btAccent : Color.btPrimary),
                            style: StrokeStyle(lineWidth: wall.thickness, lineCap: .round))
                    }
                    .onTapGesture {
                        if selectedTool == .select {
                            withAnimation { selectedWallIndex = selectedWallIndex == idx ? nil : idx }
                        } else if selectedTool == .erase {
                            walls.remove(at: idx)
                            selectedWallIndex = nil
                        }
                    }
                }

                ForEach(Array(doors.enumerated()), id: \.element.id) { idx, door in
                    DoorSymbolView(door: door)
                        .position(door.position)
                        .gesture(DragGesture().onChanged { value in
                            if selectedTool == .select || selectedTool == .door {
                                doors[idx].position = value.location
                            }
                        })
                        .onTapGesture {
                            if selectedTool == .erase { doors.remove(at: idx) }
                        }
                }

                ForEach(Array(windows.enumerated()), id: \.element.id) { idx, win in
                    WindowSymbolView(window: win)
                        .position(win.position)
                        .gesture(DragGesture().onChanged { value in
                            if selectedTool == .select || selectedTool == .window {
                                windows[idx].position = value.location
                            }
                        })
                        .onTapGesture {
                            if selectedTool == .erase { windows.remove(at: idx) }
                        }
                }

                if selectedTool == .wall {
                    WallDrawingOverlay { start, end in
                        withAnimation { walls.append(EditorWall(start: start, end: end)) }
                    }
                }
            }
            .background(Color(hex: "#F0F4FF"))
        }
    }

    private func gridBackground(size: CGSize) -> some View {
        Canvas { context, sz in
            let step: CGFloat = 20
            var x: CGFloat = 0
            while x < sz.width {
                var p = Path()
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: sz.height))
                context.stroke(p, with: .color(Color.gray.opacity(0.15)), lineWidth: 0.5)
                x += step
            }
            var y: CGFloat = 0
            while y < sz.height {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: sz.width, y: y))
                context.stroke(p, with: .color(Color.gray.opacity(0.15)), lineWidth: 0.5)
                y += step
            }
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Walls: \(walls.count)")
                    .font(BTFont.caption())
                    .foregroundColor(.btTextSecondary)
                Text("Doors: \(doors.count)  ·  Windows: \(windows.count)")
                    .font(BTFont.caption())
                    .foregroundColor(.btTextSecondary)
            }
            Spacer()
            Button {
                withAnimation { walls = []; doors = []; windows = []; selectedWallIndex = nil }
            } label: {
                Label("Clear", systemImage: "trash")
                    .font(BTFont.body())
                    .foregroundColor(.btDanger)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.btSurface)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: -2)
    }

    // MARK: - Helpers
    private func loadLayout() {
        let w: CGFloat = 200, h: CGFloat = 160
        let cx: CGFloat = 80, cy: CGFloat = 100
        walls = [
            EditorWall(start: CGPoint(x: cx,     y: cy),     end: CGPoint(x: cx + w, y: cy)),
            EditorWall(start: CGPoint(x: cx + w, y: cy),     end: CGPoint(x: cx + w, y: cy + h)),
            EditorWall(start: CGPoint(x: cx + w, y: cy + h), end: CGPoint(x: cx,     y: cy + h)),
            EditorWall(start: CGPoint(x: cx,     y: cy + h), end: CGPoint(x: cx,     y: cy))
        ]
        doors   = [EditorDoor(position: CGPoint(x: cx + 60, y: cy + h))]
        windows = [EditorWindow(position: CGPoint(x: cx + w, y: cy + 60))]
    }

    private func saveLayout() {
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaved = false }
        }
    }
}

// MARK: - Door Symbol
struct DoorSymbolView: View {
    let door: LayoutEditorView.EditorDoor
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.btAccent.opacity(0.2))
                .frame(width: door.width, height: 12)
            Path { p in
                p.move(to: CGPoint(x: -door.width / 2, y: 0))
                p.addArc(center: CGPoint(x: -door.width / 2, y: 0),
                         radius: door.width,
                         startAngle: .degrees(0), endAngle: .degrees(90),
                         clockwise: false)
            }
            .stroke(Color.btAccent, lineWidth: 2)
            .frame(width: door.width, height: door.width)
            Text(door.label)
                .font(.system(size: 8))
                .foregroundColor(.btAccent)
                .offset(y: 20)
        }
    }
}

// MARK: - Window Symbol
struct WindowSymbolView: View {
    let window: LayoutEditorView.EditorWindow
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.btSecondary.opacity(0.2))
                .frame(width: window.width, height: 10)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle().frame(width: 1, height: 10).foregroundColor(.btSecondary)
                }
            }
            Text(window.label)
                .font(.system(size: 8))
                .foregroundColor(.btSecondary)
                .offset(y: 18)
        }
    }
}

// MARK: - Wall Drawing Overlay
struct WallDrawingOverlay: View {
    let onDraw: (CGPoint, CGPoint) -> Void
    @State private var startPoint: CGPoint? = nil
    @State private var currentPoint: CGPoint? = nil

    var body: some View {
        ZStack {
            if let start = startPoint, let cur = currentPoint {
                Canvas { context, _ in
                    var path = Path()
                    path.move(to: start)
                    path.addLine(to: cur)
                    context.stroke(path,
                        with: .color(Color.btAccent.opacity(0.5)),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: [10, 5]))
                }
            }
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            if startPoint == nil { startPoint = value.startLocation }
                            currentPoint = value.location
                        }
                        .onEnded { value in
                            if let start = startPoint { onDraw(start, value.location) }
                            startPoint = nil
                            currentPoint = nil
                        }
                )
        }
    }
}

// MARK: - Material Calculator View
struct MaterialCalculatorView: View {
    @Environment(\.dismiss) var dismiss
    var room: Room?

    @State private var length: String = ""
    @State private var width: String = ""
    @State private var height: String = ""
    @State private var selectedMaterial: CalculatorMaterial = .paint
    @State private var wastePercent: Double = 10
    @State private var result: MaterialResult? = nil

    enum CalculatorMaterial: String, CaseIterable {
        case paint     = "Paint"
        case tiles     = "Tiles"
        case laminate  = "Laminate"
        case wallpaper = "Wallpaper"
        case plaster   = "Plaster"
        case primer    = "Primer"

        var icon: String {
            switch self {
            case .paint:     return "paintbrush.fill"
            case .tiles:     return "square.grid.3x3.fill"
            case .laminate:  return "square.grid.2x2.fill"
            case .wallpaper: return "scroll.fill"
            case .plaster:   return "rectangle.fill"
            case .primer:    return "drop.fill"
            }
        }
        var color: Color {
            switch self {
            case .paint:     return .blue
            case .tiles:     return .orange
            case .laminate:  return Color(hex: "#8B6914")
            case .wallpaper: return .purple
            case .plaster:   return .gray
            case .primer:    return .green
            }
        }
        var unit: String {
            switch self {
            case .paint, .primer: return "liters"
            default:              return "m²"
            }
        }
        var packageSize: Double {
            switch self {
            case .paint, .primer: return 5.0
            case .laminate:       return 2.13
            case .plaster:        return 25.0
            default:              return 1.0
            }
        }
    }

    struct MaterialResult {
        let baseQty: Double
        let withWaste: Double
        let unit: String
        let packages: Int
        let packageSize: Double
        let floorArea: Double
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    dimensionsSection
                    materialSection
                    wasteSection

                    Button { calculate() } label: {
                        HStack {
                            Image(systemName: "function")
                            Text("Calculate Materials").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).frame(height: 54)
                    }
                    .buttonStyle(BTPrimaryButtonStyle())

                    if let r = result {
                        resultCard(r)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(16)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: result != nil)
            }
            .background(Color.btSurface.ignoresSafeArea())
            .navigationTitle("Material Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }.foregroundColor(.btSecondary)
                }
            }
            .onAppear {
                if let r = room {
                    let side = sqrt(r.area)
                    length = String(format: "%.1f", side)
                    width  = String(format: "%.1f", side)
                    height = "2.7"
                }
            }
        }
    }

    // MARK: Sections

    private var dimensionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BTSectionHeader(title: "Room Dimensions")
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    dimField("Length (m)", $length, "5.0")
                    dimField("Width (m)",  $width,  "4.0")
                }
                dimField("Ceiling Height (m)", $height, "2.7")
            }
            .padding(16)
            .background(Color.btCard)
            .cornerRadius(16)
        }
    }

    private var materialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BTSectionHeader(title: "Material Type")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CalculatorMaterial.allCases, id: \.self) { mat in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMaterial = mat
                                result = nil
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: mat.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(selectedMaterial == mat ? .white : mat.color)
                                Text(mat.rawValue)
                                    .font(BTFont.caption(11))
                                    .foregroundColor(selectedMaterial == mat ? .white : .btText)
                            }
                            .frame(width: 76, height: 70)
                            .background(selectedMaterial == mat ? mat.color : Color.btCard)
                            .cornerRadius(12)
                            .scaleEffect(selectedMaterial == mat ? 1.05 : 1.0)
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }

    private var wasteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BTSectionHeader(title: "Waste Allowance")
            VStack(spacing: 8) {
                HStack {
                    Text("Extra material for waste/cuts")
                        .font(BTFont.body())
                        .foregroundColor(.btText)
                    Spacer()
                    Text("\(Int(wastePercent))%")
                        .font(BTFont.headline())
                        .foregroundColor(.btAccent)
                        .frame(width: 44)
                }
                Slider(value: $wastePercent, in: 5...30, step: 5)
                    .accentColor(.btAccent)
                HStack {
                    Text("5%").font(BTFont.caption()).foregroundColor(.btTextSecondary)
                    Spacer()
                    Text("30%").font(BTFont.caption()).foregroundColor(.btTextSecondary)
                }
            }
            .padding(16)
            .background(Color.btCard)
            .cornerRadius(16)
        }
    }

    // MARK: Result Card

    private func resultCard(_ r: MaterialResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.seal.fill").foregroundColor(.btSuccess)
                Text("Calculation Complete").font(BTFont.headline()).foregroundColor(.btText)
                Spacer()
            }
            Divider()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                resultItem("Floor Area",    String(format: "%.2f m²", r.floorArea),      "square.fill",      .blue)
                resultItem("Base Quantity", String(format: "%.1f %@", r.baseQty, r.unit), selectedMaterial.icon, selectedMaterial.color)
                resultItem("With \(Int(wastePercent))% Waste", String(format: "%.1f %@", r.withWaste, r.unit), "plus.circle.fill", .orange)
                resultItem("Packages", "\(r.packages) × \(String(format: "%.2g", r.packageSize)) \(r.unit)", "shippingbox.fill", .btPrimary)
            }
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill").foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendation")
                        .font(BTFont.body())
                        .fontWeight(.semibold)
                        .foregroundColor(.btText)
                    Text("Buy \(r.packages) \(r.packages == 1 ? "pack" : "packs") of \(selectedMaterial.rawValue.lowercased()) (\(String(format: "%.2g", r.packageSize)) \(r.unit) each). Includes \(Int(wastePercent))% extra for cuts and waste.")
                        .font(BTFont.caption())
                        .foregroundColor(.btTextSecondary)
                }
            }
            .padding(12)
            .background(Color.btAccent.opacity(0.08))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.btCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
    }

    private func resultItem(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12)).foregroundColor(color)
                Text(title).font(BTFont.caption(11)).foregroundColor(.btTextSecondary)
            }
            Text(value).font(BTFont.headline(15)).foregroundColor(.btText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.btSurface)
        .cornerRadius(10)
    }

    private func dimField(_ label: String, _ value: Binding<String>, _ placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(BTFont.caption()).foregroundColor(.btTextSecondary)
            TextField(placeholder, text: value)
                .keyboardType(.decimalPad)
                .font(BTFont.body())
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(Color.btSurface)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.btBorder, lineWidth: 1))
        }
    }

    // MARK: Calculation
    private func calculate() {
        guard let l = Double(length), let w = Double(width), let h = Double(height),
              l > 0, w > 0, h > 0 else { return }

        let floor    = l * w
        let walls    = 2 * (l + w) * h
        let ceiling  = floor
        let mat      = selectedMaterial

        let base: Double
        switch mat {
        case .paint:     base = (walls + ceiling) / 5   // 5 m² per litre (2 coats)
        case .primer:    base = (walls + ceiling) / 12
        case .tiles:     base = floor
        case .laminate:  base = floor
        case .wallpaper: base = walls / 5               // ~5 m² per roll
        case .plaster:   base = walls
        }

        let withWaste = base * (1 + wastePercent / 100)
        let pkgs      = Int(ceil(withWaste / mat.packageSize))

        withAnimation {
            result = MaterialResult(
                baseQty: base,
                withWaste: withWaste,
                unit: mat.unit,
                packages: pkgs,
                packageSize: mat.packageSize,
                floorArea: floor
            )
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var notifications: [BTNotification] = BTNotification.samples
    @State private var showClearConfirm = false

    struct BTNotification: Identifiable {
        let id = UUID()
        let title: String
        let body: String
        let date: Date
        let type: NotifType
        var isRead: Bool = false

        enum NotifType {
            case task, reminder, tip, system
            var icon: String {
                switch self {
                case .task:     return "checkmark.circle.fill"
                case .reminder: return "bell.fill"
                case .tip:      return "lightbulb.fill"
                case .system:   return "gear.fill"
                }
            }
            var color: Color {
                switch self {
                case .task:     return .btSuccess
                case .reminder: return .btAccent
                case .tip:      return Color.yellow
                case .system:   return .btSecondary
                }
            }
        }

        static var samples: [BTNotification] { [
            BTNotification(title: "Task Reminder",   body: "Don't forget to measure the bedroom walls today.",            date: Date().addingTimeInterval(-3600),   type: .task),
            BTNotification(title: "Weekly Summary",  body: "You've completed 3 tasks this week. Great progress!",        date: Date().addingTimeInterval(-86400),  type: .reminder, isRead: true),
            BTNotification(title: "Pro Tip",         body: "Use diagonal measurements to check if your room is square.", date: Date().addingTimeInterval(-172800), type: .tip,      isRead: true),
            BTNotification(title: "Shopping Reminder", body: "You have 5 items pending in your shopping list.",          date: Date().addingTimeInterval(-259200), type: .reminder),
            BTNotification(title: "New Feature",     body: "Layout Editor now supports door and window symbols.",        date: Date().addingTimeInterval(-432000), type: .system,   isRead: true)
        ] }
    }

    private var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    var body: some View {
        NavigationView {
            Group {
                if notifications.isEmpty {
                    BTEmptyState(
                        icon: "bell.slash.fill",
                        title: "No Notifications",
                        message: "You're all caught up! Notifications about tasks and reminders will appear here."
                    )
                } else {
                    List {
                        ForEach(Array(notifications.enumerated())) { idx, notif in
                            NotificationRow(notification: notif)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .onTapGesture {
                                    withAnimation { notifications[idx].isRead = true }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation { notifications.remove(at: idx) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        withAnimation { notifications[idx].isRead.toggle() }
                                    } label: {
                                        Label(notifications[idx].isRead ? "Unread" : "Read",
                                              systemImage: notifications[idx].isRead ? "envelope.badge.fill" : "envelope.open.fill")
                                    }
                                    .tint(.btSecondary)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.btSurface)
                }
            }
            .background(Color.btSurface.ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if unreadCount > 0 {
                        Text("\(unreadCount) unread")
                            .font(BTFont.caption())
                            .foregroundColor(.btTextSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { markAllRead() } label: {
                            Label("Mark All as Read", systemImage: "envelope.open")
                        }
                        Button(role: .destructive) { showClearConfirm = true } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle").foregroundColor(.btAccent)
                    }
                }
            }
            .alert("Clear All Notifications?", isPresented: $showClearConfirm) {
                Button("Clear", role: .destructive) {
                    withAnimation { notifications = [] }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all notifications.")
            }
        }
    }

    private func markAllRead() {
        withAnimation {
            for i in notifications.indices { notifications[i].isRead = true }
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: NotificationsView.BTNotification

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(notification.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: notification.type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(notification.type.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(BTFont.body())
                        .fontWeight(notification.isRead ? .regular : .semibold)
                        .foregroundColor(.btText)
                    Spacer()
                    if !notification.isRead {
                        Circle().fill(Color.btAccent).frame(width: 8, height: 8)
                    }
                }
                Text(notification.body)
                    .font(BTFont.caption())
                    .foregroundColor(.btTextSecondary)
                    .lineLimit(2)
                Text(timeAgo(notification.date))
                    .font(BTFont.caption(11))
                    .foregroundColor(.btTextSecondary)
            }
        }
        .padding(14)
        .background(notification.isRead ? Color.btCard : Color.btAccent.opacity(0.05))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(notification.isRead ? Color.clear : Color.btAccent.opacity(0.2), lineWidth: 1)
        )
    }

    private func timeAgo(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        if s < 3600  { return "\(s / 60)m ago" }
        if s < 86400 { return "\(s / 3600)h ago" }
        return "\(s / 86400)d ago"
    }
}
