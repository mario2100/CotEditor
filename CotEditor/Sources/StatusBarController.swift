//
//  StatusBarController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-07-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2020 1024jp
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

final class StatusBarController: NSViewController {
    
    // MARK: Private Properties
    
    private var defaultsObservers: [UserDefaultsObservation] = []
    private let byteCountFormatter = ByteCountFormatter()
    
    @objc private dynamic var editorStatus: NSAttributedString?
    @objc private dynamic var documentStatus: NSAttributedString?
    @objc private dynamic var showsReadOnly = false
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// setup
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.byteCountFormatter.isAdaptive = false
        
        if NSAppKitVersion.current >= .macOS11 {
            (self.view as? NSVisualEffectView)?.material = .titlebar
        }
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("status bar".localized)
    }
    
    
    /// request analyzer to update editor info
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        assert(self.documentAnalyzer != nil)
        
        self.documentAnalyzer?.shouldUpdateStatusEditorInfo = true
        self.documentAnalyzer?.invalidateEditorInfo()
        
        // observe change in defaults
        self.defaultsObservers.forEach { $0.invalidate() }
        self.defaultsObservers = []
        let editorDefaultKeys: [DefaultKeys] = [
            .showStatusBarLines,
            .showStatusBarChars,
            .showStatusBarWords,
            .showStatusBarLocation,
            .showStatusBarLine,
            .showStatusBarColumn,
        ]
        self.defaultsObservers += UserDefaults.standard.observe(keys: editorDefaultKeys) { [weak self] (_, _) in
            self?.updateEditorStatus()
        }
        let documentDefaultKeys: [DefaultKeys] = [
            .showStatusBarEncoding,
            .showStatusBarLineEndings,
            .showStatusBarFileSize,
        ]
        self.defaultsObservers += UserDefaults.standard.observe(keys: documentDefaultKeys) { [weak self] (_, _) in
            self?.updateDocumentStatus()
        }
    }
    
    
    /// request analyzer to stop updating editor info
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.documentAnalyzer?.shouldUpdateStatusEditorInfo = false
        
        self.defaultsObservers.forEach { $0.invalidate() }
        self.defaultsObservers = []
    }
    
    
    
    // MARK: Public Methods
    
    weak var documentAnalyzer: DocumentAnalyzer? {
        
        willSet {
            guard let analyzer = documentAnalyzer else { return }
            
            analyzer.shouldUpdateStatusEditorInfo = false
            
            NotificationCenter.default.removeObserver(self, name: DocumentAnalyzer.didUpdateEditorInfoNotification, object: analyzer)
            NotificationCenter.default.removeObserver(self, name: DocumentAnalyzer.didUpdateFileInfoNotification, object: analyzer)
            NotificationCenter.default.removeObserver(self, name: DocumentAnalyzer.didUpdateModeInfoNotification, object: analyzer)
        }
        
        didSet {
            guard let analyzer = documentAnalyzer else { return }
            
            analyzer.shouldUpdateStatusEditorInfo = self.isViewShown
            
            NotificationCenter.default.addObserver(self, selector: #selector(updateEditorStatus), name: DocumentAnalyzer.didUpdateEditorInfoNotification, object: analyzer)
            NotificationCenter.default.addObserver(self, selector: #selector(updateDocumentStatus), name: DocumentAnalyzer.didUpdateFileInfoNotification, object: analyzer)
            NotificationCenter.default.addObserver(self, selector: #selector(updateDocumentStatus), name: DocumentAnalyzer.didUpdateModeInfoNotification, object: analyzer)
            
            self.updateEditorStatus()
            self.updateDocumentStatus()
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// update left side text
    @objc private func updateEditorStatus() {
        
        assert(Thread.isMainThread)
        
        guard
            self.isViewShown,
            let info = self.documentAnalyzer?.info.editor
            else { return }
        
        let defaults = UserDefaults.standard
        var status: [NSAttributedString] = []
        
        if defaults[.showStatusBarLines] {
            status.append(.formatted(label: "Lines") + .formatted(state: info.lines))
        }
        if defaults[.showStatusBarChars] {
            status.append(.formatted(label: "Characters") + .formatted(state: info.chars))
        }
        if defaults[.showStatusBarWords] {
            status.append(.formatted(label: "Words") + .formatted(state: info.words))
        }
        if defaults[.showStatusBarLocation] {
            status.append(.formatted(label: "Location") + .formatted(state: info.location))
        }
        if defaults[.showStatusBarLine] {
            status.append(.formatted(label: "Line") + .formatted(state: info.line))
        }
        if defaults[.showStatusBarColumn] {
            status.append(.formatted(label: "Column") + .formatted(state: info.column))
        }
        
        let attrStatus = status.joined(separator: .init(string: "   ")).mutable
        
        // truncate tail
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.lineBreakMode = .byTruncatingTail
        attrStatus.addAttribute(.paragraphStyle, value: paragraphStyle, range: attrStatus.range)
        
        self.editorStatus = attrStatus
    }
    
    
    /// update right side text and readonly icon state
    @objc private func updateDocumentStatus() {
        
        assert(Thread.isMainThread)
        
        guard
            self.isViewShown,
            let info = self.documentAnalyzer?.info
            else { return }
        
        let defaults = UserDefaults.standard
        var status: [NSAttributedString] = []
        
        if defaults[.showStatusBarEncoding] {
            status.append(.formatted(state: info.mode.encoding))
        }
        if defaults[.showStatusBarLineEndings] {
            status.append(.formatted(state: info.mode.lineEndings))
        }
        if defaults[.showStatusBarFileSize] {
            status.append(.formatted(state: self.byteCountFormatter.string(for: info.file.fileSize)))
        }
        
        self.documentStatus = status.joined(separator: .init(string: "   "))
        self.showsReadOnly = info.file.isReadOnly
    }
    
}



// MARK: -

private extension NSAttributedString {
    
    /// Formatted state for status bar.
    static func formatted(state: String?) -> Self {
        
        if let state = state {
            return Self(string: state)
        } else {
            return Self(string: "-", attributes: [.foregroundColor: NSColor.disabledControlTextColor])
        }
    }
    
    
    /// Formatted label for status bar.
    static func formatted(label: String) -> Self {
        
        return Self(string: (label + ": ").localized, attributes: [.foregroundColor: NSColor.secondaryLabelColor])
    }
    
}
