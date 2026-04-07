import SwiftUI

// MARK: - Welcome View
struct WelcomeView: View {
    @EnvironmentObject var appState: ApplicationMainState
    @State private var showLogin = false
    @State private var showSignUp = false
    @State private var appear = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "#0F1923"), Color(hex: "#1A2B4A")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            BlueprintGridView().opacity(0.08).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#1E3A5F"))
                            .frame(width: 90, height: 90)
                            .shadow(color: Color.btSecondary.opacity(0.4), radius: 20, x: 0, y: 8)
                        RoomLogoShape()
                            .stroke(Color.btAccent, lineWidth: 2.5)
                            .frame(width: 46, height: 42)
                    }
                    VStack(spacing: 6) {
                        Text("BuilderToolbox")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Your renovation companion")
                            .font(BTFont.body())
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 30)

                Spacer()

                // Features list
                VStack(alignment: .leading, spacing: 14) {
                    WelcomeFeatureRow(icon: "camera.viewfinder", text: "Scan rooms with your camera", color: Color(hex: "#2D7DD2"))
                    WelcomeFeatureRow(icon: "square.grid.3x3", text: "Create detailed floor plans", color: Color(hex: "#F4A623"))
                    WelcomeFeatureRow(icon: "chair.fill", text: "Plan furniture placement", color: Color(hex: "#27AE60"))
                    WelcomeFeatureRow(icon: "cart.fill", text: "Calculate materials & costs", color: Color(hex: "#9B59B6"))
                }
                .padding(.horizontal, 32)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)

                Spacer()

                // Auth buttons
                VStack(spacing: 12) {
                    Button { showLogin = true } label: {
                        Text("Log In")
                    }
                    .buttonStyle(BTPrimaryButtonStyle())

                    Button { showSignUp = true } label: {
                        Text("Create Account")
                    }
                    .buttonStyle(BTSecondaryButtonStyle())
                }
                .padding(.horizontal, 24)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)

                Text("By continuing you agree to our Terms of Service")
                    .font(BTFont.caption(11))
                    .foregroundColor(Color.white.opacity(0.25))
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                    .opacity(appear ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) { appear = true }
        }
        .fullScreenCover(isPresented: $showLogin) { LoginView() }
        .fullScreenCover(isPresented: $showSignUp) { SignUpView() }
    }
}

struct WelcomeFeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(text)
                .font(BTFont.body())
                .foregroundColor(Color.white.opacity(0.75))
            Spacer()
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var appState: ApplicationMainState
    @StateObject private var vm = AuthViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var appear = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        ZStack {
                            LinearGradient.btPrimaryGradient.ignoresSafeArea()
                            VStack(spacing: 8) {
                                Text("Welcome Back")
                                    .font(BTFont.title(28))
                                    .foregroundColor(.white)
                                Text("Log in to your account")
                                    .font(BTFont.body())
                                    .foregroundColor(Color.white.opacity(0.65))
                            }
                            .padding(.vertical, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)

                        VStack(spacing: 20) {
                            BTTextField(title: "Email", placeholder: "your@email.com",
                                        text: $vm.email, keyboardType: .emailAddress, icon: "envelope")

                            BTTextField(title: "Password", placeholder: "Min. 6 characters",
                                        text: $vm.password, isSecure: true, icon: "lock")

                            if !vm.errorMessage.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.btDanger)
                                        .font(.system(size: 13))
                                    Text(vm.errorMessage)
                                        .font(BTFont.caption())
                                        .foregroundColor(.btDanger)
                                }
                                .padding(12)
                                .background(Color.btDanger.opacity(0.08))
                                .cornerRadius(8)
                            }

                            Button {
                                vm.login(appState: appState) { success in
                                    if success { dismiss() }
                                }
                            } label: {
                                if vm.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Log In")
                                }
                            }
                            .buttonStyle(BTPrimaryButtonStyle())
                            .disabled(vm.isLoading)
                        }
                        .padding(24)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.btTextSecondary)
                            .font(.system(size: 22))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.2)) { appear = true }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var appState: ApplicationMainState
    @StateObject private var vm = AuthViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var appear = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.btSurface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        ZStack {
                            LinearGradient.btAmberGradient.ignoresSafeArea()
                            VStack(spacing: 8) {
                                Text("Create Account")
                                    .font(BTFont.title(28))
                                    .foregroundColor(.white)
                                Text("Start planning your renovation")
                                    .font(BTFont.body())
                                    .foregroundColor(Color.white.opacity(0.75))
                            }
                            .padding(.vertical, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)

                        VStack(spacing: 20) {
                            BTTextField(title: "Full Name", placeholder: "John Smith",
                                        text: $vm.name, icon: "person")

                            BTTextField(title: "Email", placeholder: "your@email.com",
                                        text: $vm.email, keyboardType: .emailAddress, icon: "envelope")

                            BTTextField(title: "Password", placeholder: "Min. 6 characters",
                                        text: $vm.password, isSecure: true, icon: "lock")

                            if !vm.errorMessage.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.btDanger)
                                        .font(.system(size: 13))
                                    Text(vm.errorMessage)
                                        .font(BTFont.caption())
                                        .foregroundColor(.btDanger)
                                }
                                .padding(12)
                                .background(Color.btDanger.opacity(0.08))
                                .cornerRadius(8)
                            }

                            Button {
                                vm.signUp(appState: appState) { success in
                                    if success { dismiss() }
                                }
                            } label: {
                                if vm.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create Account")
                                }
                            }
                            .buttonStyle(BTPrimaryButtonStyle())
                            .disabled(vm.isLoading)
                        }
                        .padding(24)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.btTextSecondary)
                            .font(.system(size: 22))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.2)) { appear = true }
        }
    }
}
