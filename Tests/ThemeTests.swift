//
//  ThemeTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-03-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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

import XCTest
@testable import CotEditor


final class ThemeTests: XCTestCase {
    
    private let themeDirectoryName = "Themes"
    
    private lazy var bundle = Bundle(for: type(of: self))
    
    
    func testDefaultTheme() throws {
        
        let themeName = "Dendrobates"
        let theme = try self.loadThemeWithName(themeName)!
        
        XCTAssertEqual(theme.name, themeName)
        XCTAssertEqual(theme.text.color, NSColor.black.usingColorSpace(.genericRGB))
        XCTAssertEqual(theme.insertionPoint.color, NSColor.black.usingColorSpace(.genericRGB))
        XCTAssertEqual(theme.invisibles.color.brightnessComponent, 0.72, accuracy: 0.01)
        XCTAssertEqual(theme.background.color, NSColor.white.usingColorSpace(.genericRGB))
        XCTAssertEqual(theme.lineHighlight.color.brightnessComponent, 0.94, accuracy: 0.01)
        XCTAssertNil(theme.secondarySelectionColor)
        
        for type in SyntaxType.allCases {
            XCTAssertGreaterThan(theme.style(for: type)!.color.hueComponent, 0)
        }
        
        XCTAssertFalse(theme.isDarkTheme)
    }
    
    
    func testDarkTheme() throws {
        
        let themeName = "Solarized (Dark)"
        let theme = try self.loadThemeWithName(themeName)!
        
        XCTAssertEqual(theme.name, themeName)
        XCTAssertTrue(theme.isDarkTheme)
    }
    
    
    /// test if all of bundled themes are valid
    func testBundledThemes() throws {
        
        let themeDirectoryURL = self.bundle.url(forResource: themeDirectoryName, withExtension: nil)!
        let enumerator = FileManager.default.enumerator(at: themeDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])!
        
        for case let url as URL in enumerator {
            guard DocumentType.theme.extensions.contains(url.pathExtension) else { continue }
            
            _ = try Theme.theme(contentsOf: url)
        }
    }
    
}



private extension ThemeTests {
    
    func loadThemeWithName(_ name: String) throws -> Theme? {
        
        let url = self.bundle.url(forResource: name, withExtension: DocumentType.theme.extensions[0], subdirectory: themeDirectoryName)
        
        return try Theme.theme(contentsOf: url!)
    }
    
}
