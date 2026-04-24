import Foundation

struct IntentParsingContext {
    var now: Date
    var selectedDate: Date
    var timeZone: TimeZone
    var existingItems: [ExistingScheduleItem]
    var contextTask: ContextTaskItem?
}

struct ExistingScheduleItem: Encodable {
    var title: String
    var scheduledAt: String
    var durationMinutes: Int
}

struct ContextTaskItem: Encodable {
    var title: String
    var scheduledAt: String?
    var durationMinutes: Int
    var categoryName: String?
    var subtasks: [String]
}

enum GeminiIntentParserError: Error {
    case missingConfiguration
    case invalidURL
    case invalidAudioData
    case badResponse(Int, String)
    case missingCandidateText
}

struct GeminiIntentParser {
    private let configuration: GeminiConfiguration
    private let session: URLSession

    init(configuration: GeminiConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    static func live() throws -> GeminiIntentParser {
        guard let configuration = GeminiConfiguration.current else {
            throw GeminiIntentParserError.missingConfiguration
        }

        return GeminiIntentParser(configuration: configuration)
    }

    func parse(input: ParsedIntentInput, context: IntentParsingContext) async throws -> ParsedIntentPlan {
        var request = try URLRequest(url: endpointURL())
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload(for: input, context: context))
        request.timeoutInterval = 24

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiIntentParserError.badResponse(-1, "")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw GeminiIntentParserError.badResponse(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
        }

        let geminiResponse = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)
        guard let text = geminiResponse.candidates.first?.content.parts.first(where: { $0.text != nil })?.text else {
            throw GeminiIntentParserError.missingCandidateText
        }

        return try JSONDecoder().decode(ParsedIntentPlan.self, from: Data(text.utf8))
    }

    private func endpointURL() throws -> URL {
        guard let encodedModel = configuration.modelName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(encodedModel):generateContent")
        else {
            throw GeminiIntentParserError.invalidURL
        }

        return url
    }

    private func payload(for input: ParsedIntentInput, context: IntentParsingContext) throws -> [String: Any] {
        var parts: [[String: Any]] = [
            ["text": prompt(for: context)]
        ]

        switch input {
        case .text(let text):
            parts.append(["text": text])
        case .audio(let fileURL, let mimeType):
            guard let data = try? Data(contentsOf: fileURL) else {
                throw GeminiIntentParserError.invalidAudioData
            }
            parts.append([
                "inline_data": [
                    "mime_type": mimeType,
                    "data": data.base64EncodedString()
                ]
            ])
        }

        return [
            "contents": [
                [
                    "role": "user",
                    "parts": parts
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json",
                "response_schema": Self.responseSchema
            ]
        ]
    }

    private func prompt(for context: IntentParsingContext) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let existingItemsData = (try? encoder.encode(context.existingItems)) ?? Data("[]".utf8)
        let existingItemsText = String(data: existingItemsData, encoding: .utf8) ?? "[]"
        let contextTaskData = (try? encoder.encode(context.contextTask)) ?? Data("null".utf8)
        let contextTaskText = String(data: contextTaskData, encoding: .utf8) ?? "null"

        return """
        You are BIP's scheduling parser. Convert the user's Portuguese or English natural language into structured tasks/events for a SwiftData app.

        Rules:
        - Return only JSON matching the schema.
        - If audio is provided, transcribe the speech first and put the transcript in transcript.
        - Use the user's language for titles.
        - Interpret relative dates using now, selectedDate, and timezone.
        - scheduledAt must be ISO 8601 with timezone offset, or null if the user did not provide enough timing information.
        - durationMinutes defaults: task = 30, event = 60, lunch = 60, meeting = 60.
        - kind "event" is for calendar blocks with a start/end or fixed duration. kind "task" is for todos.
        - For "todo dia", use recurrence.type "daily". For weekly/custom repetition, use Calendar weekday numbers 1...7 where Sunday is 1.
        - If the user asks to find the best time, use existingItems to choose the earliest reasonable free slot on the requested day. If impossible, return an empty items array, set needsConfirmation true, and question with a short Portuguese clarification.
        - Do not invent personal details. If date/time is ambiguous and cannot be inferred, leave scheduledAt null or ask a question.
        - If contextTask is not null, the user is editing that existing task or adding subtasks to it. Return exactly one item representing the updated task. Preserve existing contextTask fields unless the user clearly changes them. Put newly mentioned checklist items in subtasks. Do not create an unrelated new top-level item while contextTask is active.
        - If contextTask is null and the user does not mention a specific date, use selectedDate as the target day.
        - categoryName should be short, like Home, Work, Personal, Fitness, Studies, Errands, Family.
        - categorySymbolName should be an SF Symbol, like house, briefcase, person, figure.run, books.vertical, bag, heart.

        Context:
        now: \(Self.isoFormatter.string(from: context.now))
        selectedDate: \(Self.isoFormatter.string(from: context.selectedDate))
        timezone: \(context.timeZone.identifier)
        existingItems: \(existingItemsText)
        contextTask: \(contextTaskText)
        """
    }

    private static let responseSchema: [String: Any] = [
        "type": "OBJECT",
        "properties": [
            "transcript": ["type": "STRING", "nullable": true],
            "items": [
                "type": "ARRAY",
                "items": [
                    "type": "OBJECT",
                    "properties": [
                        "kind": ["type": "STRING", "enum": ["task", "event"]],
                        "title": ["type": "STRING"],
                        "rawInput": ["type": "STRING", "nullable": true],
                        "scheduledAt": ["type": "STRING", "nullable": true],
                        "durationMinutes": ["type": "INTEGER", "nullable": true],
                        "categoryName": ["type": "STRING", "nullable": true],
                        "categorySymbolName": ["type": "STRING", "nullable": true],
                        "recurrence": [
                            "type": "OBJECT",
                            "nullable": true,
                            "properties": [
                                "type": ["type": "STRING", "enum": ["none", "daily", "weekly", "custom"]],
                                "daysOfWeek": [
                                    "type": "ARRAY",
                                    "items": ["type": "INTEGER"]
                                ]
                            ],
                            "required": ["type", "daysOfWeek"]
                        ],
                        "reminder": [
                            "type": "OBJECT",
                            "nullable": true,
                            "properties": [
                                "enabled": ["type": "BOOLEAN"],
                                "offsetMinutes": ["type": "INTEGER"]
                            ],
                            "required": ["enabled", "offsetMinutes"]
                        ],
                        "subtasks": [
                            "type": "ARRAY",
                            "items": ["type": "STRING"]
                        ]
                    ],
                    "required": ["kind", "title", "subtasks"]
                ]
            ],
            "needsConfirmation": ["type": "BOOLEAN"],
            "question": ["type": "STRING", "nullable": true]
        ],
        "required": ["items", "needsConfirmation"]
    ]

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

private struct GeminiGenerateContentResponse: Decodable {
    var candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Decodable {
    var content: GeminiContent
}

private struct GeminiContent: Decodable {
    var parts: [GeminiPart]
}

private struct GeminiPart: Decodable {
    var text: String?
}
