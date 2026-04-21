import Foundation
import NaturalLanguage
import SharedCore

public enum LanguageDetector {
    public static func detect(_ text: String, confidenceThreshold: Double = InferenceKit.Config.languageConfidenceThreshold) -> Language? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let hypotheses = recognizer.languageHypotheses(withMaximum: 3)

        guard let (topLanguage, confidence) = hypotheses.max(by: { $0.value < $1.value }),
              confidence >= confidenceThreshold
        else { return nil }

        let mapping: [NLLanguage: Language] = [
            .english: .en,
            .simplifiedChinese: .zh,
            .traditionalChinese: .zh,
            .japanese: .ja,
            .korean: .ko,
            .french: .fr,
            .german: .de,
            .spanish: .es,
            .italian: .it,
            .portuguese: .pt,
            .russian: .ru,
        ]

        return mapping[topLanguage]
    }
}