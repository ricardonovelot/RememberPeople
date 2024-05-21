//
//  ContentView.swift
//  RememberPeople
//
//  Created by Ricardo on 21/05/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @FetchRequest(sortDescriptors: []) var contacts: FetchedResults<Contact>
    @State private var showAddContactSheet = false
    
    var body: some View {
        NavigationView{
            VStack {
                List(contacts){ contact in
                    Text(contact.name ?? "Unknown")
                }
                
            }
            .toolbar{
                ToolbarItem(placement: .topBarTrailing){
                    Button{
                        showAddContactSheet = true
                    }label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddContactSheet){
            AddContact()
        }
    }
}

#Preview {
    let dataController = DataController()
    let context = dataController.container.viewContext
    return ContentView()
        .environment(\.managedObjectContext, context)
}
