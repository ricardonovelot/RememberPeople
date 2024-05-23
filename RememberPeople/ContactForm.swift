import SwiftUI
import PhotosUI

struct ContactForm: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var contact: Contact
    
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var image: Image?
    
    @State private var name: String
    @State private var notes: String
    @State private var dateMet: Date
    @State private var tagInput: String = ""
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) private var allTags: FetchedResults<Tag>
    
    init(contact: Contact) {
        _contact = ObservedObject(wrappedValue: contact)
        _name = State(initialValue: contact.name ?? "")
        _notes = State(initialValue: contact.notes ?? "")
        _dateMet = State(initialValue: contact.dateMet ?? Date())
        if let imageData = contact.photo, let uiImage = UIImage(data: imageData) {
            _image = State(initialValue: Image(uiImage: uiImage))
            _selectedImage = State(initialValue: uiImage)
        }
    }
    
    var body: some View {
        Form {
            Section{
                DatePicker("Date Met", selection: $dateMet, displayedComponents: .date)
            }
            
            Section {
                PhotosPicker(selection: $pickerItem) {
                    if let image = image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipped()
                    } else {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                    }
                }
                .onChange(of: pickerItem) {
                    Task {
                        if let data = try? await pickerItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            self.selectedImage = uiImage
                            self.image = Image(uiImage: uiImage)
                        }
                    }
                }
            }
            .listRowInsets(EdgeInsets())
            
            Section("Name") {
                TextField("Name", text: $name)
            }
            
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Section("Tags") {
                TextField("Add Tag", text: $tagInput, onCommit: addTag)
                List {
                    ForEach(allTags) { tag in
                        Button(action: { toggleTag(tag) }) {
                            HStack {
                                Text(tag.name ?? "")
                                Spacer()
                                if contact.tags?.contains(tag) == true {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(contact.isNew ? "New Contact" : "Edit Contact")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            saveContact()
        }
    }
    
    private func addTag() {
        guard !tagInput.isEmpty else { return }
        
        // Check if the tag already exists
        if let existingTag = allTags.first(where: { $0.name == tagInput }) {
            contact.addToTags(existingTag)
        } else {
            let newTag = Tag(context: viewContext)
            newTag.name = tagInput
            contact.addToTags(newTag)
        }
        
        tagInput = ""
        saveContext()
    }
    
    private func toggleTag(_ tag: Tag) {
        if contact.tags?.contains(tag) == true {
            contact.removeFromTags(tag)
        } else {
            contact.addToTags(tag)
        }
        saveContext()
    }
    
    private func saveContact() {
        contact.name = name.isEmpty ? "New Person" : name
        contact.notes = notes
        contact.dateMet = dateMet
        
        if let selectedImage = selectedImage {
            contact.photo = selectedImage.jpegData(compressionQuality: 1.0)
        }
        
        saveContext()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save contact: \(error.localizedDescription)")
        }
    }
}

extension Contact {
    var isNew: Bool {
        id == nil
    }
}

#Preview {
    let dataController = DataController()
    let context = dataController.container.viewContext
    return ContactForm(contact: Contact(context: context))
        .environment(\.managedObjectContext, context)
}


