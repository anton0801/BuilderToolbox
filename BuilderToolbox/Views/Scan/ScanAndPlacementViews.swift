import SwiftUI

// MARK: - Blueprint Grid (shared background)
struct BlueprintGridView: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 24
            var x: CGFloat = 0
            while x <= size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(Color.btSecondary.opacity(0.4)), lineWidth: 0.5)
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Color.btSecondary.opacity(0.4)), lineWidth: 0.5)
                y += step
            }
        }
    }
}

// MARK: - Room Scan View
struct RoomScanView: View {
    @Environment(\.dismiss) var dismiss
    @State private var scanState: ScanState = .ready
    @State private var scanProgress: Double = 0
    @State private var scanLineY: CGFloat = -150
    @State private var detectedCorners: [CGPoint] = []
    @State private var showResult = false
    @State private var detectedWidth = 4.8
    @State private var detectedLength = 6.2
    @State private var scanTimer: Timer? = nil

    enum ScanState: Equatable {
        case ready, scanning, processing, done
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0A1628"), Color(hex: "#0F1F38")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if scanState == .scanning || scanState == .processing {
                BlueprintGridView()
                    .opacity(0.1)
                    .ignoresSafeArea()

                if scanState == .scanning {
                    ScanContourView(corners: $detectedCorners, scanLineY: $scanLineY)
                }
            }

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Room Scanner")
                        .font(BTFont.headline())
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "flashlight.on.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                if scanState == .ready {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.btAccent, lineWidth: 2)
                            .frame(width: 260, height: 300)
                        ForEach(0..<4, id: \.self) { i in
                            ScanCornerBracket()
                                .rotationEffect(.degrees(Double(i) * 90))
                                .offset(
                                    x: [CGFloat(-118), CGFloat(118), CGFloat(-118), CGFloat(118)][i],
                                    y: [CGFloat(-138), CGFloat(-138), CGFloat(138), CGFloat(138)][i]
                                )
                        }
                        VStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 40))
                                .foregroundColor(Color.white.opacity(0.4))
                            Text("Point camera at room corner")
                                .font(BTFont.caption())
                                .foregroundColor(Color.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                if scanState == .scanning {
                    VStack(spacing: 8) {
                        Text("Scanning room...")
                            .font(BTFont.headline())
                            .foregroundColor(.white)
                        ProgressView(value: scanProgress)
                            .accentColor(.btAccent)
                            .frame(width: 200)
                        Text("\(Int(scanProgress * 100))%")
                            .font(BTFont.mono())
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .padding(.bottom, 20)
                }

                if scanState == .processing {
                    VStack(spacing: 12) {
                        ProgressView()
                            .accentColor(.btAccent)
                            .scaleEffect(1.5)
                        Text("Processing room data...")
                            .font(BTFont.body())
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .padding(.bottom, 20)
                }

                VStack(spacing: 16) {
                    if scanState == .ready || scanState == .done {
                        Button { startScan() } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 18, weight: .semibold))
                                Text(scanState == .done ? "Scan Again" : "Start Scanning")
                                    .font(BTFont.headline())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(LinearGradient.btPrimaryGradient)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                    }

                    if scanState == .done {
                        Button { showResult = true } label: {
                            Text("View Scan Result")
                        }
                        .buttonStyle(BTSecondaryButtonStyle())
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showResult) {
            ScanResultView(width: detectedWidth, length: detectedLength)
        }
        .onDisappear {
            scanTimer?.invalidate()
            scanTimer = nil
        }
    }

    private func startScan() {
        scanTimer?.invalidate()
        scanTimer = nil

        detectedCorners = []
        scanProgress = 0
        scanState = .scanning
        scanLineY = -150

        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
            scanLineY = 150
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                detectedCorners = [
                    CGPoint(x: 60, y: 100),
                    CGPoint(x: UIScreen.main.bounds.width - 60, y: 100),
                    CGPoint(x: UIScreen.main.bounds.width - 60, y: 400),
                    CGPoint(x: 60, y: 400)
                ]
            }
        }

        let t = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            DispatchQueue.main.async {
                scanProgress += 0.025
                if scanProgress >= 1.0 {
                    timer.invalidate()
                    scanTimer = nil
                    scanState = .processing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        detectedWidth = Double.random(in: 3.5...6.5).rounded(to: 1)
                        detectedLength = Double.random(in: 4.0...8.0).rounded(to: 1)
                        scanState = .done
                    }
                }
            }
        }
        RunLoop.main.add(t, forMode: .common)
        scanTimer = t
    }
}

// MARK: - Scan Corner Bracket
struct ScanCornerBracket: View {
    var body: some View {
        ZStack {
            Rectangle().fill(Color.btAccent).frame(width: 20, height: 3).offset(x: 8.5, y: 0)
            Rectangle().fill(Color.btAccent).frame(width: 3, height: 20).offset(x: 0, y: 8.5)
        }
    }
}

// MARK: - Scan Contour Overlay
struct ScanContourView: View {
    @Binding var corners: [CGPoint]
    @Binding var scanLineY: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.clear, Color.btSecondary.opacity(0.8), Color.clear],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(height: 2)
                .frame(maxWidth: .infinity)
                .offset(y: scanLineY)
            ForEach(corners.indices, id: \.self) { i in
                Circle()
                    .fill(Color.btAccent)
                    .frame(width: 12, height: 12)
                    .position(corners[i])
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Scan Result View
struct ScanResultView: View {
    @Environment(\.dismiss) var dismiss
    let width: Double
    let length: Double

    private var roomScale: CGFloat {
        min(260 / CGFloat(width), 200 / CGFloat(length))
    }
    private var roomW: CGFloat { CGFloat(width) * roomScale }
    private var roomL: CGFloat { CGFloat(length) * roomScale }

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        ZStack {
                            Color(hex: "#F0F4FF")
                            BlueprintGridView().opacity(0.3)

                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.btSecondary.opacity(0.1))
                                    .frame(width: roomW, height: roomL)
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.btSecondary, lineWidth: 2.5)
                                    .frame(width: roomW, height: roomL)

                                Group {
                                    Rectangle()
                                        .fill(Color.btSurface)
                                        .frame(width: 24, height: 2.5)
                                        .offset(x: -roomW / 2 + 12, y: roomL / 2)
                                    Path { path in
                                        path.addArc(
                                            center: CGPoint(x: -roomW / 2, y: roomL / 2),
                                            radius: 24,
                                            startAngle: .degrees(0),
                                            endAngle: .degrees(90),
                                            clockwise: false
                                        )
                                    }
                                    .stroke(Color.btSecondary.opacity(0.5), lineWidth: 1)
                                }

                                Rectangle()
                                    .fill(Color.btSecondary.opacity(0.4))
                                    .frame(width: 40, height: 4)
                                    .offset(x: roomW / 4, y: -roomL / 2)

                                Text("\(String(format: "%.1f", width)) m")
                                    .font(BTFont.mono(11))
                                    .foregroundColor(.btSecondary)
                                    .offset(y: -roomL / 2 - 16)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)

                        HStack(spacing: 12) {
                            BTStatCard(title: "Width",
                                       value: String(format: "%.1f", width),
                                       unit: "m", icon: "arrow.left.and.right", color: .btSecondary)
                            BTStatCard(title: "Length",
                                       value: String(format: "%.1f", length),
                                       unit: "m", icon: "arrow.up.and.down", color: .btAccent)
                            BTStatCard(title: "Area",
                                       value: String(format: "%.1f", width * length),
                                       unit: "m²", icon: "square.dashed", color: .btSuccess)
                        }
                        .padding(.horizontal, 16)

                        VStack(spacing: 12) {
                            Text("Detected Elements")
                                .font(BTFont.headline(14))
                                .foregroundColor(.btTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            ScanElementRow(icon: "rectangle.3.group", name: "4 Walls", status: "Detected")
                            ScanElementRow(icon: "door.left.hand.open", name: "1 Door", status: "Detected")
                            ScanElementRow(icon: "rectangle", name: "1 Window", status: "Detected")
                        }
                        .padding(.horizontal, 16)

                        Button { dismiss() } label: { Text("Use This Plan") }
                            .buttonStyle(BTPrimaryButtonStyle())
                            .padding(.horizontal, 16)

                        Color.clear.frame(height: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Scan Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.btSecondary)
                }
            }
        }
    }
}

// MARK: - Scan Element Row
struct ScanElementRow: View {
    let icon: String
    let name: String
    let status: String

    var body: some View {
        BTCard(padding: 12) {
            HStack {
                Image(systemName: icon).foregroundColor(.btSecondary).frame(width: 24)
                Text(name).font(BTFont.body()).foregroundColor(.btText)
                Spacer()
                Label(status, systemImage: "checkmark.circle.fill")
                    .font(BTFont.caption())
                    .foregroundColor(.btSuccess)
            }
        }
    }
}

// MARK: - Furniture Placement View
struct FurniturePlacementView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    let projectId: UUID
    let room: Room

    @State private var furniturePositions: [UUID: CGPoint] = [:]
    @State private var furnitureRotations: [UUID: Double] = [:]
    @State private var selectedFurnitureId: UUID? = nil

    let canvasSize: CGFloat = 320

    var roomScale: CGFloat {
        let maxDim = max(room.width, room.length)
        guard maxDim > 0 else { return 40 }
        return min(canvasSize / CGFloat(maxDim), 50)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                VStack(spacing: 0) {

                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 13))
                            .foregroundColor(.btSecondary)
                        Text("Tap to select  •  Drag to move  •  Use rotate button")
                            .font(BTFont.caption())
                            .foregroundColor(.btTextSecondary)
                    }
                    .padding(10)
                    .background(Color.btSecondary.opacity(0.08))

                    GeometryReader { geo in
                        let roomW = CGFloat(room.width) * roomScale
                        let roomL = CGFloat(room.length) * roomScale
                        let originX = (geo.size.width - roomW) / 2
                        let originY = (geo.size.height - roomL) / 2

                        ZStack {
                            Color(hex: "#F0F4FF")
                            BlueprintGridView().opacity(0.25)

                            Rectangle()
                                .stroke(Color.btSecondary, lineWidth: 3)
                                .background(Rectangle().fill(Color.white.opacity(0.3)))
                                .frame(width: roomW, height: roomL)
                                .position(x: geo.size.width / 2, y: geo.size.height / 2)

                            ForEach(room.furniture) { item in
                                furniturePiece(
                                    item: item,
                                    originX: originX, originY: originY,
                                    roomW: roomW, roomL: roomL
                                )
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedFurnitureId = nil
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)

                    if let selectedId = selectedFurnitureId,
                       let item = room.furniture.first(where: { $0.id == selectedId }) {
                        selectedItemBar(item: item, selectedId: selectedId)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Furniture Layout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.btSecondary)
                }
            }
            .onAppear { loadSavedPositions() }
        }
    }

    @ViewBuilder
    private func furniturePiece(
        item: FurnitureItem,
        originX: CGFloat, originY: CGFloat,
        roomW: CGFloat, roomL: CGFloat
    ) -> some View {
        let defaultPos = CGPoint(x: originX + roomW / 2, y: originY + roomL / 2)
        let pos = furniturePositions[item.id] ?? defaultPos
        let rotation = furnitureRotations[item.id] ?? 0

        FurniturePieceView(
            item: item,
            isSelected: selectedFurnitureId == item.id,
            roomScale: roomScale
        )
        .rotationEffect(.degrees(rotation))
        .position(pos)
        .gesture(
            DragGesture()
                .onChanged { value in
                    selectedFurnitureId = item.id
                    let halfW = CGFloat(item.width) * roomScale / 2
                    let halfD = CGFloat(item.depth) * roomScale / 2
                    let cx = min(max(value.location.x, originX + halfW), originX + roomW - halfW)
                    let cy = min(max(value.location.y, originY + halfD), originY + roomL - halfD)
                    furniturePositions[item.id] = CGPoint(x: cx, y: cy)
                }
                .onEnded { _ in
                    let finalPos = furniturePositions[item.id] ?? defaultPos
                    let relX = Double((finalPos.x - originX) / roomScale)
                    let relY = Double((finalPos.y - originY) / roomScale)
                    projectsVM.updateFurniturePosition(
                        in: room.id, projectId: projectId,
                        furnitureId: item.id, x: relX, y: relY,
                        rotation: furnitureRotations[item.id] ?? 0
                    )
                }
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFurnitureId = (selectedFurnitureId == item.id) ? nil : item.id
            }
        }
    }

    @ViewBuilder
    private func selectedItemBar(item: FurnitureItem, selectedId: UUID) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(item.name)
                    .font(BTFont.headline())
                    .foregroundColor(.btText)
                Spacer()
                Button {
                    let current = furnitureRotations[selectedId] ?? 0
                    let newRot = current + 90
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        furnitureRotations[selectedId] = newRot
                    }
                    if let p = furniturePositions[selectedId] {
                        projectsVM.updateFurniturePosition(
                            in: room.id, projectId: projectId,
                            furnitureId: selectedId,
                            x: Double(p.x), y: Double(p.y), rotation: newRot
                        )
                    }
                } label: {
                    Label("Rotate 90°", systemImage: "rotate.right")
                        .font(BTFont.body(13))
                        .foregroundColor(.btSecondary)
                        .padding(10)
                        .background(Color.btSecondary.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            HStack {
                Text("Size: \(String(format: "%.1f × %.1f m", item.width, item.depth))")
                    .font(BTFont.caption())
                    .foregroundColor(.btTextSecondary)
                Spacer()
                Text("Tap elsewhere to deselect")
                    .font(BTFont.caption(10))
                    .foregroundColor(.btTextSecondary)
            }
        }
        .padding(16)
        .background(Color.btCard)
    }

    private func loadSavedPositions() {
        for item in room.furniture {
            if item.positionX > 0 || item.positionY > 0 {
                furniturePositions[item.id] = CGPoint(
                    x: CGFloat(item.positionX) * roomScale,
                    y: CGFloat(item.positionY) * roomScale
                )
                furnitureRotations[item.id] = item.rotation
            }
        }
    }
}

// MARK: - Furniture Piece View
struct FurniturePieceView: View {
    let item: FurnitureItem
    let isSelected: Bool
    let roomScale: CGFloat

    private var pieceW: CGFloat { CGFloat(item.width) * roomScale }
    private var pieceH: CGFloat { CGFloat(item.depth) * roomScale }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: item.color).opacity(0.7))
                .frame(width: pieceW, height: pieceH)
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? Color.btAccent : Color(hex: item.color), lineWidth: isSelected ? 2 : 1)
                .frame(width: pieceW, height: pieceH)
            if pieceW > 30 {
                Text(item.name.prefix(6))
                    .font(.system(size: min(10, pieceW / 5), weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
        .shadow(color: Color.black.opacity(0.15), radius: isSelected ? 8 : 3, x: 0, y: 2)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Double rounding helper
extension Double {
    func rounded(to places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}
