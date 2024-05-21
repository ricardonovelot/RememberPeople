//
//  AddContact.swift
//  RememberPeople
//
//  Created by Ricardo on 21/05/24.
//

import SwiftUI
import PhotosUI

struct AddContact: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.dismiss) var dismiss
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    
    @State private var name: String = ""
    
    var body: some View {
        NavigationView{
            Form{
                Section{
                    if selectedImage != nil{
                        Image("default")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                    } else {
                        PhotosPicker(selection: $pickerItem){
                            EmptyView()
                                .frame(height: 200)
                        }
                    }
                    
                }.listRowInsets(EdgeInsets())
                
                Section{
                    TextField("Name", text: $name)
                }
            }
            .navigationTitle("New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarLeading){
                    Button{
                        dismiss()
                    }label: {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing
                ){
                    Button{
                        let contact = Contact(context: moc)
                        
                        contact.id = UUID()
                        contact.name = name
                        
                        try? moc.save()
                    }label: {
                        Text("Save")
                    }
                }
            }
        }
    }
}

#Preview {
    let context = CoreDataManager.shared.context
    
    AddContact()
}
