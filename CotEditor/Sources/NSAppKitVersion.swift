//
//  NSAppKitVersion.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2019-11-17.
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

import struct AppKit.NSAppKitVersion

extension NSAppKitVersion {
    
    static var macOS10_15 = NSAppKitVersion(rawValue: 1894)
    static var macOS11 = NSAppKitVersion(rawValue: 1997)
}
