//
//  KoreanSearch.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/1/25.
//

import Foundation

enum KoreanSearch {
    private static let choseongTable: [Character] = [
        "ㄱ","ㄲ","ㄴ","ㄷ","ㄸ","ㄹ","ㅁ","ㅂ","ㅃ","ㅅ","ㅆ","ㅇ","ㅈ","ㅉ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"
    ]
    
    /// 한글 문자열 -> 초성 문자열 (공백은 그대로 보존)
    static func initialsWithSpaces(of text: String) -> String {
        var out = ""
        for scalar in text.precomposedStringWithCanonicalMapping.unicodeScalars {
            let v = Int(scalar.value)
            if (0xAC00...0xD7A3).contains(v) {
                let idx = (v - 0xAC00) / (21 * 28)
                out.append(choseongTable[idx])
            } else if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                out.append(" ")
            } else {
                out.append(Character(scalar))
            }
        }
        // 연속 공백 압축
        return squeezeSpaces(out)
    }
    
    /// 초성 문자열(공백 포함 가능)에서 모든 공백 제거 버전
    static func compactInitials(of text: String) -> String {
        let s = initialsWithSpaces(of: text)
        return removeAllSpaces(s)
    }
    
    /// 쿼리가 초성으로만 이루어졌는지 (공백 허용)
    static func isInitialsQuery(_ q: String) -> Bool {
        let trimmed = q.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let set = Set(choseongTable)
        return trimmed.allSatisfy { set.contains($0) || $0.isWhitespace }
    }
    
    static func isNumeric(_ q: String) -> Bool {
        let t = q.trimmingCharacters(in: .whitespacesAndNewlines)
        return !t.isEmpty && t.allSatisfy(\.isNumber)
    }
    
    // MARK: - Space helpers
    
    /// 모든 종류의 공백 제거 (일반/줄바꿈/넓은공백 포함)
    static func removeAllSpaces(_ s: String) -> String {
        let extras: [UnicodeScalar] = ["\u{00A0}", "\u{2002}", "\u{2003}", "\u{2009}", "\u{3000}"]
        var filtered = s.unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) && !extras.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }
    
    /// 연속 공백 1칸으로 압축 & 앞뒤 트림
    static func squeezeSpaces(_ s: String) -> String {
        let comps = s.split(whereSeparator: { $0.isWhitespace })
        return comps.joined(separator: " ")
    }
    
    /// 단어 경계 매칭: 쿼리 초성 토큰들(공백 기준)이 haystack 초성 단어 시퀀스에 **연속**으로 등장하는지
    static func matchesInitialTokens(query: String, inWords words: String) -> Bool {
        let qTokens = squeezeSpaces(initialsWithSpaces(of: query)).split(separator: " ").map(String.init)
        guard !qTokens.isEmpty else { return false }
        
        let hayTokens = squeezeSpaces(initialsWithSpaces(of: words)).split(separator: " ").map(String.init)
        guard qTokens.count <= hayTokens.count else { return false }
        
        // 연속 부분 시퀀스 검사 (슬라이딩 윈도우)
        let n = hayTokens.count
        let m = qTokens.count
        if m == 1 { return hayTokens.contains(qTokens[0]) }
        
        for start in 0...(n - m) {
            var ok = true
            for j in 0..<m {
                if hayTokens[start + j].localizedCaseInsensitiveContains(qTokens[j]) == false {
                    ok = false; break
                }
            }
            if ok { return true }
        }
        return false
    }
}
