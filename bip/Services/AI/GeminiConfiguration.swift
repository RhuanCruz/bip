import Foundation

struct GeminiConfiguration {
    let apiKey: String
    let modelName: String

    static var current: GeminiConfiguration? {
        guard let apiKey = resolvedAPIKey() else {
            print("Gemini configuration missing: add a Gemini API key in More > Gemini API Key.")
            return nil
        }

        let modelName = (Bundle.main.object(forInfoDictionaryKey: "BIPGeminiModelName") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedModelName: String
        if let modelName, !modelName.isEmpty {
            resolvedModelName = modelName
        } else {
            resolvedModelName = "gemini-3-flash-preview"
        }

        return GeminiConfiguration(apiKey: apiKey, modelName: resolvedModelName)
    }

    private static func resolvedAPIKey() -> String? {
        if let value = sanitizedAPIKey(GeminiAPIKeyStore.load()) {
            print("Gemini configuration loaded from Keychain.")
            return value
        }

        let bundleKeys = [
            "BIPGeminiAPIKey",
            "GEMINI_API_KEY"
        ]

        for key in bundleKeys {
            if let value = sanitizedAPIKey(Bundle.main.object(forInfoDictionaryKey: key) as? String) {
                print("Gemini configuration loaded from \(key).")
                return value
            }
        }

        return nil
    }

    private static func sanitizedAPIKey(_ value: String?) -> String? {
        guard let value else { return nil }

        let apiKey = value.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"")))
        guard !apiKey.isEmpty, !apiKey.contains("$(") else {
            return nil
        }

        return apiKey
    }
}
