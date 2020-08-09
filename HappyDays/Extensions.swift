//
//  Extensions.swift
//  HappyDays
//
//  Created by Philipp on 08.08.20.
//

import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
