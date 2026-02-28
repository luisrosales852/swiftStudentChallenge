//
//  StoryCategory.swift
//  Swift Student Challenge Real
//

import SwiftUI

/// Categories for organizing story prompts and recording themes
enum StoryCategory: String, CaseIterable {
    case childhood = "Childhood"
    case family = "Family"
    case immigration = "Immigration"
    case career = "Career"
    case recipes = "Recipes"
    case traditions = "Traditions"
    
    var icon: String {
        switch self {
        case .childhood: return "figure.and.child.holdinghands"
        case .family: return "person.3.fill"
        case .immigration: return "airplane.departure"
        case .career: return "briefcase.fill"
        case .recipes: return "fork.knife"
        case .traditions: return "gift.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .childhood: return .softTerracotta
        case .family: return .deepTerracotta
        case .immigration: return .warmBrown
        case .career: return .softTerracotta
        case .recipes: return .deepTerracotta
        case .traditions: return .warmBrown
        }
    }
}
