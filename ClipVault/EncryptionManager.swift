//
//  EncryptionManager.swift
//  ClipVault
//
//  Created by Edd on 09/10/2025.
//

import Foundation
import CryptoKit
import Security

class EncryptionManager {
    static let shared = EncryptionManager()

    private let keyTag = "com.clipvault.encryption.key"
    private var cachedKey: SymmetricKey?

    private init() {}

    // MARK: - Public Methods

    /// Encrypts data using AES-GCM with authenticated encryption
    func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.seal(data, using: key)

        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }

        return combined
    }

    /// Decrypts data that was encrypted with AES-GCM
    func decrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        return decryptedData
    }

    /// Encrypts a string and returns encrypted data
    func encryptString(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidInput
        }
        return try encrypt(data)
    }

    /// Decrypts data and returns a string
    func decryptString(_ data: Data) throws -> String {
        let decryptedData = try decrypt(data)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidOutput
        }
        return string
    }

    // MARK: - Key Management

    /// Retrieves the encryption key from Keychain, or creates a new one if it doesn't exist
    private func getOrCreateKey() throws -> SymmetricKey {
        // Return cached key if available
        if let key = cachedKey {
            return key
        }

        // Try to load existing key from Keychain
        if let keyData = try? loadKeyFromKeychain() {
            let key = SymmetricKey(data: keyData)
            cachedKey = key
            return key
        }

        // Generate new key and store it
        let key = SymmetricKey(size: .bits256)
        try saveKeyToKeychain(key)
        cachedKey = key
        return key
    }

    private func saveKeyToKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: keyData
        ]

        // Try to add the key first
        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Key already exists, update it instead
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: keyTag
            ]
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: keyData
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)

            guard updateStatus == errSecSuccess else {
                throw EncryptionError.keychainError(updateStatus)
            }
        } else if status != errSecSuccess {
            throw EncryptionError.keychainError(status)
        }
    }

    private func loadKeyFromKeychain() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let keyData = result as? Data else {
            throw EncryptionError.keyNotFound
        }

        return keyData
    }

    // MARK: - Errors

    enum EncryptionError: Error, LocalizedError {
        case encryptionFailed
        case decryptionFailed
        case invalidInput
        case invalidOutput
        case keyNotFound
        case keychainError(OSStatus)

        var errorDescription: String? {
            switch self {
            case .encryptionFailed:
                return "Failed to encrypt data"
            case .decryptionFailed:
                return "Failed to decrypt data"
            case .invalidInput:
                return "Invalid input data"
            case .invalidOutput:
                return "Invalid output data"
            case .keyNotFound:
                return "Encryption key not found in Keychain"
            case .keychainError(let status):
                return "Keychain error: \(status)"
            }
        }
    }
}
