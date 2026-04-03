import SwiftUI

// MARK: - Shopping List View
struct ShoppingListView: View {
    @EnvironmentObject var shoppingVM: ShoppingViewModel
    @State private var showAddItem = false
    @State private var filterCategory = "All"

    var categories: [String] {
        var cats = ["All"]
        cats.append(contentsOf: Array(Set(shoppingVM.items.map { $0.category })).sorted())
        return cats
    }

    var filteredItems: [ShoppingItem] {
        if filterCategory == "All" { return shoppingVM.items }
        return shoppingVM.items.filter { $0.category == filterCategory }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Summary bar
                    if !shoppingVM.items.isEmpty {
                        HStack(spacing: 0) {
                            ShoppingStat(title: "Total", value: "\(shoppingVM.items.count)", color: .btSecondary)
                            Divider().frame(height: 30)
                            ShoppingStat(title: "Done", value: "\(shoppingVM.purchasedCount)", color: .btSuccess)
                            Divider().frame(height: 30)
                            ShoppingStat(title: "Est. Cost",
                                         value: String(format: "€%.0f", shoppingVM.totalEstimated),
                                         color: .btAccent)
                        }
                        .padding(.vertical, 12)
                        .background(Color.btCard)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }

                    // Category filter
                    if categories.count > 2 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { cat in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            filterCategory = cat
                                        }
                                    } label: {
                                        Text(cat)
                                            .font(BTFont.caption())
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(filterCategory == cat ? Color.btSecondary : Color.btCard)
                                            .foregroundColor(filterCategory == cat ? .white : .btTextSecondary)
                                            .cornerRadius(20)
                                    }
                                    .buttonStyle(BTIconButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                    }

                    if shoppingVM.items.isEmpty {
                        BTEmptyState(icon: "cart.badge.plus", title: "Shopping List Empty",
                                     message: "Add items you need to buy for your renovation.",
                                     buttonTitle: "Add Item") { showAddItem = true }
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                // Not purchased
                                let pending = filteredItems.filter { !$0.isPurchased }
                                let done = filteredItems.filter { $0.isPurchased }

                                if !pending.isEmpty {
                                    ForEach(pending) { item in
                                        ShoppingItemCard(item: item)
                                            .padding(.horizontal, 16)
                                    }
                                }

                                if !done.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text("Purchased (\(done.count))")
                                            .font(BTFont.caption())
                                            .foregroundColor(.btTextSecondary)
                                            .padding(.horizontal, 16)
                                            .padding(.top, 12)
                                        ForEach(done) { item in
                                            ShoppingItemCard(item: item)
                                                .padding(.horizontal, 16)
                                                .opacity(0.6)
                                        }
                                    }
                                }

                                Color.clear.frame(height: 100)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddItem = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.btSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddItem) { AddShoppingItemView() }
    }
}

struct ShoppingStat: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(BTFont.headline()).foregroundColor(color)
            Text(title).font(BTFont.caption(10)).foregroundColor(.btTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ShoppingItemCard: View {
    @EnvironmentObject var shoppingVM: ShoppingViewModel
    let item: ShoppingItem

    var body: some View {
        BTCard(padding: 14) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        shoppingVM.togglePurchased(item)
                    }
                } label: {
                    Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(item.isPurchased ? .btSuccess : .btTextSecondary)
                }
                .buttonStyle(BTIconButtonStyle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(BTFont.body())
                        .foregroundColor(.btText)
                        .strikethrough(item.isPurchased, color: .btTextSecondary)
                    Text("\(String(format: "%.0f", item.quantity)) \(item.unit) • \(item.category)")
                        .font(BTFont.caption())
                        .foregroundColor(.btTextSecondary)
                }
                Spacer()
                if item.estimatedPrice > 0 {
                    Text(String(format: "€%.0f", item.estimatedPrice * item.quantity))
                        .font(BTFont.mono(13))
                        .foregroundColor(.btAccent)
                }
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                shoppingVM.deleteItem(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct AddShoppingItemView: View {
    @EnvironmentObject var shoppingVM: ShoppingViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var quantity = "1"
    @State private var unit = "pcs"
    @State private var category = "General"
    @State private var price = ""
    @State private var showError = false

    let unitOptions = ["pcs", "m²", "m", "L", "kg", "boxes", "rolls", "bags"]
    let categoryOptions = ["General", "Paint", "Flooring", "Tiles", "Furniture", "Tools", "Lighting", "Plumbing", "Electrical", "Other"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            BTTextField(title: "Item Name", placeholder: "e.g. Floor Paint",
                                        text: $name, icon: "tag")

                            HStack(spacing: 12) {
                                BTTextField(title: "Quantity", placeholder: "1",
                                            text: $quantity, keyboardType: .decimalPad)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Unit").font(BTFont.caption()).foregroundColor(.btTextSecondary)
                                    Picker("Unit", selection: $unit) {
                                        ForEach(unitOptions, id: \.self) { Text($0).tag($0) }
                                    }
                                    .pickerStyle(.menu)
                                    .padding(14)
                                    .background(Color(hex: "#F3F5F9"))
                                    .cornerRadius(12)
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Category").font(BTFont.caption()).foregroundColor(.btTextSecondary)
                                Picker("Category", selection: $category) {
                                    ForEach(categoryOptions, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(hex: "#F3F5F9"))
                                .cornerRadius(12)
                            }

                            BTTextField(title: "Price per unit (€, optional)", placeholder: "0.00",
                                        text: $price, keyboardType: .decimalPad, icon: "eurosign")

                            if showError {
                                Text("Please enter an item name and valid quantity.")
                                    .font(BTFont.caption()).foregroundColor(.btDanger)
                            }

                            Button {
                                let nClean = name.trimmingCharacters(in: .whitespaces)
                                guard !nClean.isEmpty, let q = Double(quantity), q > 0 else {
                                    showError = true; return
                                }
                                shoppingVM.addItem(
                                    name: nClean, quantity: q, unit: unit,
                                    category: category, price: Double(price) ?? 0
                                )
                                dismiss()
                            } label: { Text("Add to List") }
                            .buttonStyle(BTPrimaryButtonStyle())
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.btSecondary)
                }
            }
        }
    }
}

// MARK: - Tasks View
struct TasksView: View {
    @EnvironmentObject var tasksVM: TasksViewModel
    @State private var showAddTask = false
    @State private var selectedFilter: TaskFilter = .all
    @State private var showCalendar = false

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Done"
        case overdue = "Overdue"
    }

    var filteredTasks: [RenovationTask] {
        switch selectedFilter {
        case .all: return tasksVM.tasks
        case .pending: return tasksVM.tasks.filter { !$0.isCompleted }
        case .completed: return tasksVM.tasks.filter { $0.isCompleted }
        case .overdue: return tasksVM.tasks.filter { !$0.isCompleted && $0.dueDate < Date() }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Stats
                    if !tasksVM.tasks.isEmpty {
                        HStack(spacing: 0) {
                            ShoppingStat(title: "Total", value: "\(tasksVM.tasks.count)", color: .btSecondary)
                            Divider().frame(height: 30)
                            ShoppingStat(title: "Done", value: "\(tasksVM.completedCount)", color: .btSuccess)
                            Divider().frame(height: 30)
                            ShoppingStat(title: "Overdue", value: "\(tasksVM.overdueCount)", color: .btDanger)
                        }
                        .padding(.vertical, 12)
                        .background(Color.btCard)
                    }

                    // Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TaskFilter.allCases, id: \.self) { filter in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedFilter = filter
                                    }
                                } label: {
                                    Text(filter.rawValue)
                                        .font(BTFont.caption())
                                        .padding(.horizontal, 14).padding(.vertical, 7)
                                        .background(selectedFilter == filter ? Color.btSecondary : Color.btCard)
                                        .foregroundColor(selectedFilter == filter ? .white : .btTextSecondary)
                                        .cornerRadius(20)
                                }
                                .buttonStyle(BTIconButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                    }

                    if tasksVM.tasks.isEmpty {
                        BTEmptyState(icon: "checklist", title: "No Tasks",
                                     message: "Create renovation tasks to stay organized.",
                                     buttonTitle: "Add Task") { showAddTask = true }
                    } else if filteredTasks.isEmpty {
                        BTEmptyState(icon: "checkmark.circle", title: "No \(selectedFilter.rawValue) Tasks",
                                     message: "Nothing here yet.")
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(filteredTasks) { task in
                                    TaskCard(task: task)
                                        .padding(.horizontal, 16)
                                }
                                Color.clear.frame(height: 100)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button { showCalendar = true } label: {
                            Image(systemName: "calendar")
                                .foregroundColor(.btSecondary)
                        }
                        Button { showAddTask = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.btSecondary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddTask) { AddTaskView() }
        .sheet(isPresented: $showCalendar) { CalendarView() }
    }
}

struct TaskCard: View {
    @EnvironmentObject var tasksVM: TasksViewModel
    let task: RenovationTask
    @State private var showDeleteConfirm = false

    var isOverdue: Bool { !task.isCompleted && task.dueDate < Date() }

    var body: some View {
        BTCard(padding: 14) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        tasksVM.toggleCompleted(task)
                    }
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(task.isCompleted ? .btSuccess : task.priority.color)
                }
                .buttonStyle(BTIconButtonStyle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: task.category.icon)
                            .font(.system(size: 11))
                            .foregroundColor(.btTextSecondary)
                        Text(task.title)
                            .font(BTFont.body())
                            .foregroundColor(.btText)
                            .strikethrough(task.isCompleted, color: .btTextSecondary)
                    }
                    HStack(spacing: 8) {
                        Label(formatDate(task.dueDate), systemImage: "calendar")
                            .font(BTFont.caption())
                            .foregroundColor(isOverdue ? .btDanger : .btTextSecondary)
                        if task.priority != .medium {
                            Text(task.priority.rawValue)
                                .font(BTFont.caption(10))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(task.priority.color.opacity(0.15))
                                .foregroundColor(task.priority.color)
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                tasksVM.deleteTask(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: date)
    }
}

struct AddTaskView: View {
    @EnvironmentObject var tasksVM: TasksViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var priority: TaskPriority = .medium
    @State private var category: TaskCategory = .other
    @State private var showError = false
    @State private var scheduleReminder = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            BTTextField(title: "Task", placeholder: "e.g. Measure bedroom wall",
                                        text: $title, icon: "checklist")
                            BTTextField(title: "Notes", placeholder: "Optional details",
                                        text: $notes, icon: "note.text")

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Due Date").font(BTFont.caption()).foregroundColor(.btTextSecondary)
                                DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(14)
                                    .background(Color(hex: "#F3F5F9"))
                                    .cornerRadius(12)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Priority").font(BTFont.caption()).foregroundColor(.btTextSecondary)
                                HStack(spacing: 8) {
                                    ForEach(TaskPriority.allCases, id: \.self) { p in
                                        Button {
                                            withAnimation { priority = p }
                                        } label: {
                                            Text(p.rawValue)
                                                .font(BTFont.caption())
                                                .padding(.horizontal, 16).padding(.vertical, 8)
                                                .background(priority == p ? p.color : p.color.opacity(0.1))
                                                .foregroundColor(priority == p ? .white : p.color)
                                                .cornerRadius(20)
                                        }
                                        .buttonStyle(BTIconButtonStyle())
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category").font(BTFont.caption()).foregroundColor(.btTextSecondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(TaskCategory.allCases, id: \.self) { cat in
                                            Button { category = cat } label: {
                                                Label(cat.rawValue, systemImage: cat.icon)
                                                    .font(BTFont.caption())
                                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                                    .background(category == cat ? Color.btSecondary : Color.btSecondary.opacity(0.1))
                                                    .foregroundColor(category == cat ? .white : .btSecondary)
                                                    .cornerRadius(20)
                                            }
                                            .buttonStyle(BTIconButtonStyle())
                                        }
                                    }
                                }
                            }

                            Toggle(isOn: $scheduleReminder) {
                                Label("Schedule Reminder", systemImage: "bell.fill")
                                    .font(BTFont.body())
                                    .foregroundColor(.btText)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .btSecondary))
                            .padding(14)
                            .background(Color(hex: "#F3F5F9"))
                            .cornerRadius(12)

                            if showError {
                                Text("Please enter a task title.")
                                    .font(BTFont.caption()).foregroundColor(.btDanger)
                            }

                            Button {
                                let tClean = title.trimmingCharacters(in: .whitespaces)
                                guard !tClean.isEmpty else { showError = true; return }
                                tasksVM.addTask(title: tClean, notes: notes, dueDate: dueDate,
                                                priority: priority, category: category)
                                if scheduleReminder {
                                    let task = tasksVM.tasks.first!
                                    NotificationsManager.shared.scheduleTaskReminder(for: task)
                                }
                                dismiss()
                            } label: { Text("Add Task") }
                            .buttonStyle(BTPrimaryButtonStyle())
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.btSecondary)
                }
            }
        }
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @EnvironmentObject var tasksVM: TasksViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()

    var tasksForSelectedDate: [RenovationTask] {
        tasksVM.tasks.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding(16)
                            .background(Color.btCard)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                            .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tasks on \(formatDate(selectedDate))")
                                .font(BTFont.headline(15))
                                .foregroundColor(.btTextSecondary)
                                .padding(.horizontal, 16)

                            if tasksForSelectedDate.isEmpty {
                                BTEmptyState(icon: "calendar.badge.checkmark",
                                             title: "No Tasks", message: "No tasks scheduled for this day.")
                            } else {
                                ForEach(tasksForSelectedDate) { task in
                                    TaskCard(task: task).padding(.horizontal, 16)
                                }
                            }
                        }

                        Color.clear.frame(height: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.btSecondary)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .long
        return fmt.string(from: date)
    }
}
