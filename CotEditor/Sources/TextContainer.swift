//
//  TextContainer.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2019-06-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2019-2020 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Cocoa

final class TextContainer: NSTextContainer {
    
    // MARK: Public Properties
    
    var isHangingIndentEnabled = false  { didSet { self.invalidateLayout() } }
    var hangingIndentWidth = 0  { didSet { self.invalidateLayout() } }
    
    
    // MARK: Private Properties
    
    private var indentWidthCache: [String: CGFloat] = [:]
    private var indentAttributes: [NSAttributedString.Key: Any] = [:]
    private var typingAttributesObserver: NSKeyValueObservation?
    
    
    
    // MARK: -
    // MARK: Text Container Methods
    
    deinit {
        self.typingAttributesObserver?.invalidate()
    }
    
    
    override weak var textView: NSTextView? {
        
        willSet {
            self.typingAttributesObserver?.invalidate()
        }
        
        didSet {
            self.typingAttributesObserver = textView?.observe(\.typingAttributes, options: [.initial, .new]) { [weak self] (_, change) in
                self?.indentAttributes = change.newValue ?? [:]
                self?.indentWidthCache.removeAll()
            }
        }
    }
    
    
    override var isSimpleRectangularTextContainer: Bool {
        
        return !self.isHangingIndentEnabled
    }
    
    
    override func lineFragmentRect(forProposedRect proposedRect: NSRect, at characterIndex: Int, writingDirection baseWritingDirection: NSWritingDirection, remaining remainingRect: UnsafeMutablePointer<NSRect>?) -> NSRect {
        
        assert(self.hangingIndentWidth >= 0)
        
        var rect = super.lineFragmentRect(forProposedRect: proposedRect, at: characterIndex, writingDirection: baseWritingDirection, remaining: remainingRect)
        
        guard
            self.isHangingIndentEnabled,
            let layoutManager = self.layoutManager as? LayoutManager
            else { return rect }
        
        let lineStartIndex = layoutManager.lineStartIndex(at: characterIndex)
        
        // no hanging indent for new line
        guard characterIndex != lineStartIndex else { return rect }
        
        // get base indent
        let string = layoutManager.string
        let indentString = string.indentString(in: lineStartIndex..<characterIndex)
        let baseIndent: CGFloat
        if indentString.isEmpty {
            baseIndent = 0
        } else if let cache = self.indentWidthCache[indentString] {
            baseIndent = cache
        } else {
            baseIndent = (indentString as NSString).size(withAttributes: self.indentAttributes).width
            self.indentWidthCache[indentString] = baseIndent
        }
        
        // calculate hanging indent
        let hangingIndent = CGFloat(self.hangingIndentWidth) * layoutManager.spaceWidth
        let indent = baseIndent + hangingIndent
        
        // remove hanging indent space from rect
        rect.size.width -= indent
        rect.origin.x += (baseWritingDirection != .rightToLeft) ? indent : 0
        
        return rect
    }
    
    
    
    // MARK: Private Methods
    
    /// invalidate layout in layoutManager
    private func invalidateLayout() {
        
        guard let layoutManager = self.layoutManager else { return }
        
        layoutManager.invalidateLayout(forCharacterRange: layoutManager.attributedString().range, actualCharacterRange: nil)
    }
    
}



// MARK: -

private extension NSString {
    
    /// The fast way to find the indent charaters at the beginning of the given range.
    ///
    /// - Parameters:
    ///   - ramge: The UTF1-based character range where the indent is searched.
    /// - Returns: The indent part of the string at the beginning of the given range.
    func indentString(in range: Range<Int>) -> String {
        
        let characters: [unichar] = range.lazy
            .map { self.character(at: $0) }
            .prefix { $0 == 0x0020 || $0 == 0x0009 }  // SPACE, HORIONTAL TAB
        
        return String(utf16CodeUnits: characters, count: characters.count)
    }
    
}