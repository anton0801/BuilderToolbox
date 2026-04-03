import SwiftUI

// MARK: - Measurements Section
struct MeasurementsSection: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    let projectId: UUID
    let room: Room
    @Binding var showAdd: Bool

    var body: some View {
        VStack(spacing: 12) {
            BTSectionHeader(title: "Measurements (\(room.measurements.count))", actionTitle: "+ Add") {
                showAdd = true
            }

            if room.measurements.isEmpty {
                BTEmptyState(icon: "ruler", title: "No Measurements", message: "Add room measurements to track dimensions.", buttonTitle: "Add Measurement") { showAdd = true }
            } else {
                ForEach(room.measurements) { m in
                    MeasurementCard(measurement: m)
                        .contextMenu {
                            Button(role: .destructive) {
                                projectsVM.deleteMeasurement(from: room.id, in: projectId, measurementId: m.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }

                // Total
                BTCard {
                    HStack {
                        Text("Room Perimeter")
                            .font(BTFont.body())
                            .foregroundColor(.btTextSecondary)
                        Spacer()
                        Text(String(format: "%.1f m", 2 * (room.width + room.length)))
                            .font(BTFont.mono())
                            .foregroundColor(.btSecondary)
                    }
                }
            }
        }
    }
}

struct MeasurementCard: View {
    let measurement: Measurement

    var body: some View {
        BTCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.btSecondary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "ruler")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.btSecondary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(measurement.label)
                        .font(BTFont.body())
                        .foregroundColor(.btText)
                    if !measurement.note.isEmpty {
                        Text(measurement.note)
                            .font(BTFont.caption())
                            .foregroundColor(.btTextSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f m", measurement.length))
                        .font(BTFont.mono())
                        .foregroundColor(.btText)
                    if let w = measurement.width {
                        Text(String(format: "%.2f m", w))
                            .font(BTFont.mono(11))
                            .foregroundColor(.btTextSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Add Measurement View
struct AddMeasurementView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    let projectId: UUID
    let roomId: UUID

    @State private var label = ""
    @State private var length = ""
    @State private var width = ""
    @State private var note = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            BTTextField(title: "Label", placeholder: "e.g. North Wall", text: $label, icon: "tag")
                            HStack(spacing: 12) {
                                BTTextField(title: "Length (m)", placeholder: "0.00", text: $length,
                                            keyboardType: .decimalPad, icon: "arrow.left.and.right")
                                BTTextField(title: "Width (m)", placeholder: "optional", text: $width,
                                            keyboardType: .decimalPad, icon: "arrow.up.and.down")
                            }
                            BTTextField(title: "Note", placeholder: "Optional note", text: $note, icon: "note.text")

                            if showError {
                                Text("Please enter a label and length.")
                                    .font(BTFont.caption()).foregroundColor(.btDanger)
                            }

                            Button {
                                let lClean = label.trimmingCharacters(in: .whitespaces)
                                guard !lClean.isEmpty, let l = Double(length), l > 0 else {
                                    showError = true; return
                                }
                                let m = Measurement(label: lClean, length: l,
                                                    width: Double(width), note: note)
                                projectsVM.addMeasurement(to: roomId, in: projectId, measurement: m)
                                dismiss()
                            } label: { Text("Save Measurement") }
                            .buttonStyle(BTPrimaryButtonStyle())
                        }
                        .padding(24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.btSecondary)
                }
            }
        }
    }
}

// MARK: - Furniture Section
struct FurnitureSection: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    let projectId: UUID
    let room: Room
    @Binding var showAdd: Bool
    @Binding var showPlacement: Bool

    var body: some View {
        VStack(spacing: 12) {
            BTSectionHeader(title: "Furniture (\(room.furniture.count))", actionTitle: "+ Add") {
                showAdd = true
            }

            if !room.furniture.isEmpty {
                Button {
                    showPlacement = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                        Text("Open Placement View")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(BTFont.body())
                    .foregroundColor(.white)
                    .padding(14)
                    .background(LinearGradient.btPrimaryGradient)
                    .cornerRadius(12)
                }
            }

            if room.furniture.isEmpty {
                BTEmptyState(icon: "chair.fill", title: "No Furniture", message: "Add furniture to plan your layout.",
                             buttonTitle: "Add Furniture") { showAdd = true }
            } else {
                ForEach(room.furniture) { item in
                    FurnitureItemCard(item: item)
                        .contextMenu {
                            Button(role: .destructive) {
                                projectsVM.deleteFurniture(from: room.id, in: projectId, furnitureId: item.id)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

struct FurnitureItemCard: View {
    let item: FurnitureItem

    var body: some View {
        BTCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: item.color).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: item.category.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: item.color))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(BTFont.body())
                        .foregroundColor(.btText)
                    Text(item.category.rawValue)
                        .font(BTFont.caption())
                        .foregroundColor(.btTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(String(format: "%.1f", item.width)) × \(String(format: "%.1f", item.depth)) m")
                        .font(BTFont.mono(12))
                        .foregroundColor(.btText)
                    Text("h: \(String(format: "%.2f", item.height)) m")
                        .font(BTFont.caption(10))
                        .foregroundColor(.btTextSecondary)
                }
            }
        }
    }
}

// MARK: - Add Furniture View
struct AddFurnitureView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    let projectId: UUID
    let roomId: UUID

    @State private var selectedPreset: FurnitureItem? = nil
    @State private var name = ""
    @State private var selectedCategory = FurnitureCategory.seating
    @State private var width = ""
    @State private var depth = ""
    @State private var height = ""
    @State private var showError = false

    let presets = FurnitureCategory.presets

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Presets
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Add from Presets")
                                .font(BTFont.headline(14))
                                .foregroundColor(.btTextSecondary)
                                .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(FurnitureCategory.presets) { preset in
                                        Button {
                                            selectedPreset = preset
                                            name = preset.name
                                            selectedCategory = preset.category
                                            width = String(format: "%.1f", preset.width)
                                            depth = String(format: "%.1f", preset.depth)
                                            height = String(format: "%.2f", preset.height)
                                        } label: {
                                            VStack(spacing: 6) {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(selectedPreset?.id == preset.id ?
                                                              Color.btSecondary : Color.btSecondary.opacity(0.08))
                                                        .frame(width: 56, height: 48)
                                                    Image(systemName: preset.category.icon)
                                                        .font(.system(size: 18))
                                                        .foregroundColor(selectedPreset?.id == preset.id ? .white : .btSecondary)
                                                }
                                                Text(preset.name)
                                                    .font(BTFont.caption(9))
                                                    .foregroundColor(.btTextSecondary)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(2)
                                                    .frame(width: 60)
                                            }
                                        }
                                        .buttonStyle(BTIconButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        Divider().padding(.horizontal, 16)

                        // Custom form
                        VStack(spacing: 16) {
                            Text("Custom Furniture")
                                .font(BTFont.headline(14))
                                .foregroundColor(.btTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            BTTextField(title: "Name", placeholder: "Furniture name", text: $name, icon: "tag")

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Category")
                                    .font(BTFont.caption()).foregroundColor(.btTextSecondary)
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(FurnitureCategory.allCases, id: \.self) { cat in
                                        Text(cat.rawValue).tag(cat)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(14)
                                .background(Color(hex: "#F3F5F9"))
                                .cornerRadius(12)
                            }

                            HStack(spacing: 12) {
                                BTTextField(title: "Width (m)", placeholder: "0.0", text: $width,
                                            keyboardType: .decimalPad)
                                BTTextField(title: "Depth (m)", placeholder: "0.0", text: $depth,
                                            keyboardType: .decimalPad)
                                BTTextField(title: "Height (m)", placeholder: "0.0", text: $height,
                                            keyboardType: .decimalPad)
                            }

                            if showError {
                                Text("Please fill in all required fields.")
                                    .font(BTFont.caption()).foregroundColor(.btDanger)
                            }

                            Button {
                                let nClean = name.trimmingCharacters(in: .whitespaces)
                                guard !nClean.isEmpty,
                                      let w = Double(width), w > 0,
                                      let d = Double(depth), d > 0,
                                      let h = Double(height), h > 0 else {
                                    showError = true; return
                                }
                                var item = FurnitureItem(name: nClean, category: selectedCategory,
                                                         width: w, depth: d, height: h)
                                item.color = "#6B7A90"
                                projectsVM.addFurniture(to: roomId, in: projectId, furniture: item)
                                dismiss()
                            } label: { Text("Add Furniture") }
                            .buttonStyle(BTPrimaryButtonStyle())
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Add Furniture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.btSecondary)
                }
            }
        }
    }
}

// MARK: - Room Materials Section
struct RoomMaterialsSection: View {
    let room: Room

    var paintArea: Double { 2 * (room.width + room.length) * 2.7 } // assuming 2.7m ceiling
    var floorArea: Double { room.area }
    var tilesArea: Double { room.area * 1.1 } // 10% waste

    var body: some View {
        VStack(spacing: 12) {
            BTSectionHeader(title: "Material Estimates")

            MaterialEstimateCard(
                icon: "paintbrush.fill",
                name: "Wall Paint",
                detail: "2 coats",
                value: String(format: "%.1f m²", paintArea),
                unit: String(format: "≈ %.0f L", paintArea / 10),
                color: Color(hex: "#EC407A")
            )
            MaterialEstimateCard(
                icon: "rectangle.grid.3x2.fill",
                name: "Flooring",
                detail: "with 5% waste",
                value: String(format: "%.2f m²", floorArea * 1.05),
                unit: "",
                color: Color(hex: "#8D6E63")
            )
            MaterialEstimateCard(
                icon: "square.grid.3x3.fill",
                name: "Tiles (if tiled)",
                detail: "with 10% waste",
                value: String(format: "%.2f m²", tilesArea),
                unit: "",
                color: Color(hex: "#26A69A")
            )
            MaterialEstimateCard(
                icon: "square.fill.on.square.fill",
                name: "Ceiling Paint",
                detail: "1 coat",
                value: String(format: "%.2f m²", floorArea),
                unit: String(format: "≈ %.0f L", floorArea / 12),
                color: Color(hex: "#78909C")
            )
        }
    }
}

struct MaterialEstimateCard: View {
    let icon: String
    let name: String
    let detail: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        BTCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(BTFont.body()).foregroundColor(.btText)
                    Text(detail).font(BTFont.caption()).foregroundColor(.btTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(value).font(BTFont.mono(13)).foregroundColor(.btText)
                    if !unit.isEmpty {
                        Text(unit).font(BTFont.caption(11)).foregroundColor(color)
                    }
                }
            }
        }
    }
}
