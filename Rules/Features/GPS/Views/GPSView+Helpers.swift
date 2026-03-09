// Features/GPS/Views/GPSView+Helpers.swift
import SwiftUI
import UIKit

// MARK: - Helpers shared across GPS views

func isLightColor(_ color: Color) -> Bool {
    let ui = UIColor(color)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return false }
    let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return luminance > 0.65
}
