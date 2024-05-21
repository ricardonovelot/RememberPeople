//
//  DataController.swift
//  RememberPeople
//
//  Created by Ricardo on 21/05/24.
//

import CoreData
import Foundation

class DataController: ObservableObject{
    let container = NSPersistentContainer(name: "People")
    
    init(){
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Code Data failed to load \(error.localizedDescription)")
            }
        }
    }
}
