//
//  ContentView.swift
//  RememberPeople
//
//  Created by Ricardo on 21/05/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        ContactsView()
    }
}

#Preview {
    let dataController = DataController()
    let context = dataController.container.viewContext
    return ContentView()
        .environment(\.managedObjectContext, context)
}



