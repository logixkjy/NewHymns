//
//  HTMLBuilder.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/2/25.
//

// Utils/HTMLBuilder.swift
import Foundation

enum HTMLBuilder {
    static func styledHTML(body rawHTML: String,
                           fontSize: Double,
                           fontFamily: String? = nil) -> String {
        
        let family = fontFamily ?? "'Apple SD Gothic Neo', -apple-system, Helvetica, Arial, sans-serif"
        
        let head = """
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    <!-- iOS 13 legacy -->
    <meta name="supported-color-schemes" content="light dark">
    <!-- Modern -->
    <meta name="color-scheme" content="light dark">
    <style>
      :root { color-scheme: light dark; }
      html, body { margin:0; padding:0; -webkit-text-size-adjust:100%; }
      body {
        font-family: \(family);
        font-size: \(fontSize)px;
        line-height: 1.6;
        color: #111;                 /* Light 기본 텍스트 */
        background: #FFFFFF;         /* Light 배경 고정 */
        word-break: keep-all;
      }
    
    /* ✅ 인라인 color 무시(상속받게) */
    body, span, p, b, strong, em { color: inherit !important; }
    font, [color], [style*="color"] { color: inherit !important; }
    
    /* 링크 기본 파란색 제거 & 상속 */
    a, a:link, a:visited { color: inherit !important; text-decoration: none; }
    
    img, video { max-width: 100%; height: auto; }
    .container { padding: 16px; }
    
      /* 다크 모드 명시 */
      @media (prefers-color-scheme: dark) {
        body {
          color: #EDEDED;            /* Dark 텍스트 */
          background: #000000;       /* Dark 배경 */
        }
        a, a:link, a:visited { color: inherit; } /* 링크도 텍스트 색 상속 */
      }
    </style>
    """
        return """
    <html><head>\(head)</head><body><div class="container">
    \(rawHTML)
    </div></body></html>
    """
    }
}

