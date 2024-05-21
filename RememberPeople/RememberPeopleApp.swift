//
//  RememberPeopleApp.swift
//  RememberPeople
//
//  Created by Ricardo on 21/05/24.
//

import SwiftUI

@main
struct RememberPeopleApp: App {
    @StateObject private var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
