import Foundation
import SwiftUI
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private let tokenKey = "tmdb_bearer_token"
    
    @Published var isAuthenticated = false
    
    private init() {
        isAuthenticated = getToken() != nil
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        isAuthenticated = true
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        isAuthenticated = false
    }
}
