//
//  SettingsView.swift
//  RememberPeople
//
//  Created by Ricardo on 29/05/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme: Int = 0
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Appearance")) {
                    NavigationLink(destination: ThemeSelectionView(selectedTheme: $selectedTheme)) {
                        HStack {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.blue)
                            Text("Theme")
                            Spacer()
                            Text(themeName(for: selectedTheme))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section {
                    Button(action: leaveReview) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Leave a Review")
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
        }
    }
    
    private func themeName(for theme: Int) -> String {
        switch theme {
        case 1:
            return "Light"
        case 2:
            return "Dark"
        default:
            return "System"
        }
    }
    
    private func leaveReview() {
        // Placeholder function for leaving a review
        print("Leave a review")
    }
}

struct ThemeSelectionView: View {
    @Binding var selectedTheme: Int
    
    var body: some View {
        List {
            Section {
                Button(action: { selectedTheme = 0 }) {
                    HStack {
                        Image(systemName: "circle.lefthalf.filled")
                            .foregroundColor(Color(UIColor.label))
                        Text("System")
                        Spacer()
                        if selectedTheme == 0 {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                Button(action: { selectedTheme = 1 }) {
                    HStack {
                        Image(systemName: "sun.max")
                            .foregroundColor(Color(UIColor.label))
                        Text("Light")
                        Spacer()
                        if selectedTheme == 1 {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                Button(action: { selectedTheme = 2 }) {
                    HStack {
                        Image(systemName: "moon")
                            .foregroundColor(Color(UIColor.label))
                        Text("Dark")
                        Spacer()
                        if selectedTheme == 2 {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .navigationTitle("Theme")
        .onChange(of: selectedTheme) { newValue in
            updateTheme(newValue)
        }
    }
    
    private func updateTheme(_ theme: Int) {
        switch theme {
        case 1:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
        case 2:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
        default:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .unspecified
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
