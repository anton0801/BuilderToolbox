import SwiftUI

// MARK: - Color Palette
extension Color {
    static let btPrimary = Color(hex: "#1A2B4A")       // Deep navy
    static let btAccent = Color(hex: "#F4A623")         // Warm amber
    static let btSecondary = Color(hex: "#2D7DD2")      // Blueprint blue
    static let btSuccess = Color(hex: "#27AE60")        // Construction green
    static let btDanger = Color(hex: "#E74C3C")         // Alert red
    static let btSurface = Color(hex: "#F8F9FB")        // Light surface
    static let btSurfaceDark = Color(hex: "#1C2333")    // Dark surface
    static let btCard = Color(hex: "#FFFFFF")
    static let btCardDark = Color(hex: "#242D40")
    static let btBorder = Color(hex: "#E4E8EF")
    static let btBorderDark = Color(hex: "#2E3A50")
    static let btText = Color(hex: "#0F1923")
    static let btTextSecondary = Color(hex: "#6B7A90")
    static let btTextDark = Color(hex: "#F0F4FF")
    static let btTextSecondaryDark = Color(hex: "#8B99B4")
    static let btGradientStart = Color(hex: "#1A2B4A")
    static let btGradientEnd = Color(hex: "#2D7DD2")
    static let btAmberGradientStart = Color(hex: "#F4A623")
    static let btAmberGradientEnd = Color(hex: "#E8860A")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let btPrimaryGradient = LinearGradient(
        colors: [.btGradientStart, .btGradientEnd],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let btAmberGradient = LinearGradient(
        colors: [.btAmberGradientStart, .btAmberGradientEnd],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let btScanGradient = LinearGradient(
        colors: [Color(hex: "#1A2B4A"), Color(hex: "#162035")],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Typography
struct BTFont {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func headline(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func mono(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Custom Button Styles
struct BTPrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BTFont.headline())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Group {
                    if isDestructive {
                        LinearGradient(colors: [.btDanger, Color(hex: "#C0392B")], startPoint: .leading, endPoint: .trailing)
                    } else {
                        LinearGradient.btPrimaryGradient
                    }
                }
            )
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .shadow(color: (isDestructive ? Color.btDanger : Color.btPrimary).opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct BTSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BTFont.headline())
            .foregroundColor(.btPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.btAccent.opacity(0.12))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.btAccent.opacity(0.3), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct BTIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Card View
struct BTCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    var padding: CGFloat = 16

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(colorScheme == .dark ? Color.btCardDark : Color.btCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Input Field
struct BTTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var icon: String? = nil
    @Environment(\.colorScheme) var colorScheme
    @State private var isFocused = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(BTFont.caption())
                .foregroundColor(.btTextSecondary)

            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isFocused ? .btSecondary : .btTextSecondary)
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 20)
                }
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(BTFont.body())
                        .keyboardType(keyboardType)
                } else {
                    TextField(placeholder, text: $text)
                        .font(BTFont.body())
                        .keyboardType(keyboardType)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(colorScheme == .dark ? Color(hex: "#1E2A3C") : Color(hex: "#F3F5F9"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.btSecondary : Color.clear, lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - Section Header
struct BTSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(BTFont.headline(16))
                .foregroundColor(.btText)
            Spacer()
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(BTFont.caption())
                        .foregroundColor(.btSecondary)
                }
            }
        }
    }
}

// MARK: - Empty State
struct BTEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.btSecondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.btSecondary)
            }
            Text(title)
                .font(BTFont.headline())
                .foregroundColor(.btText)
            Text(message)
                .font(BTFont.body())
                .foregroundColor(.btTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    Text(buttonTitle)
                }
                .buttonStyle(BTSecondaryButtonStyle())
                .padding(.horizontal, 40)
            }
        }
        .padding(32)
    }
}

// MARK: - Stat Card
struct BTStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        BTCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(color)
                    }
                    Spacer()
                }
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.btText)
                    Text(unit)
                        .font(BTFont.caption())
                        .foregroundColor(.btTextSecondary)
                }
                Text(title)
                    .font(BTFont.caption())
                    .foregroundColor(.btTextSecondary)
            }
        }
    }
}
