//
//  String+AddText.swift
//  Bubble
//
//  Created by Sinbane on 11/1/15.
//  Copyright © 2015 Sinbane. All rights reserved.
//

import Foundation

extension String {
    mutating func addText(text: String?, withSeparator separator:String = "") {//default parameter value
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}