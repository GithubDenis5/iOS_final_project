import SwiftUI

struct TokenInputView: View {
    @State private var token = ""
    @State private var isVerifying = false
    @State private var errorMessage: String?
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("Введите Bearer токен TMDB")
                .font(.title2)
            SecureField("Токен", text: $token)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal)
            
            if isVerifying {
                ProgressView()
            } else {
                Button("Сохранить") {
                    Task { await verifyAndSave() }
                }
                .disabled(token.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }
    
    private func verifyAndSave() async {
        isVerifying = true
        errorMessage = nil
        AuthManager.shared.saveToken(token)
        do {
            _ = try await NetworkService().popular(page: 1)
            authManager.isAuthenticated = true
        } catch {
            errorMessage = "Неверный токен или ошибка сети"
            AuthManager.shared.logout()
        }
        isVerifying = false
    }
}
