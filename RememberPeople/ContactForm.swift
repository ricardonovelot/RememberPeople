import SwiftUI
import PhotosUI
import CropViewController

// MARK: - ContactForm

struct ContactForm: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var contact: Contact
    
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var image: Image?
    @State private var showImageSourceDialog = false
    @State private var showCropView = false
    @State private var showImagePicker = false
    
    @State private var name: String
    @State private var notes: String
    @State private var dateMet: Date
    @State private var tagInput: String = ""
    @State private var isShowingDeleteActions = false
    @State private var tagToDelete: Tag? = nil
    
    @FocusState private var isNameFocused: Bool
    
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
            dateMetSection
            nameSection
            photoSection
            notesSection
            tagsSection
            existingTagsSection
        }
        .confirmationDialog("Delete tag?", isPresented: $isShowingDeleteActions) {
            Button("Confirm Delete", role: .destructive) {
                if let tag = tagToDelete {
                    deleteTag(tag)
                }
            }
        }
        .navigationTitle(contact.isNew ? "New Contact" : "Edit Contact")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { saveContact() }
    }
    
    // MARK: - View Sections
    
    private var dateMetSection: some View {
        Section {
            DatePicker("Date Met", selection: $dateMet, displayedComponents: .date)
        }
    }
    
    private var nameSection: some View {
        Section {
            TextField("Name", text: $name)
                .focused($isNameFocused)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isNameFocused = true
                    }
                }
        }
    }
    
    private var photoSection: some View {
        Section {
            ZStack {
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
                
                VStack {
                    Spacer()
                    HStack {
                        cropButton
                        Spacer()
                    }
                }
            }
            .onTapGesture { showImageSourceDialog = true }
            .confirmationDialog("Select Image Source", isPresented: $showImageSourceDialog) {
                Button("Gallery") { showImagePicker = true }
                Button("Clipboard") { loadImageFromClipboard() }
            }
            .photosPicker(isPresented: $showImagePicker, selection: $pickerItem, matching: .images)
            .onChange(of: pickerItem) { newItem in
                loadImageFromPicker(newItem: newItem)
            }
            .sheet(isPresented: $showCropView) { cropViewSheet }
        }
        .listRowInsets(EdgeInsets())
    }
    
    private var cropButton: some View {
        Button(action: {
            if selectedImage != nil {
                showCropView = true
            } else {
                showImageSourceDialog = true
            }
        }) {
            Image(systemName: "crop")
                .padding(12)
                .background(.thickMaterial)
                .clipShape(Circle())
        }
        .padding()
    }
    
    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var tagsSection: some View {
        Section("Tags") {
            HStack {
                TextField("Add Tag", text: $tagInput, onCommit: addTag)
            }
        }
    }
    
    private var existingTagsSection: some View {
        Section {
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
                    .swipeActions(edge: .trailing) {
                        Button {
                            tagToDelete = tag
                            isShowingDeleteActions = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Image Handling
    
    private func loadImageFromClipboard() {
        if let clipboardImage = UIPasteboard.general.image {
            selectedImage = clipboardImage
            image = Image(uiImage: clipboardImage)
            showCropView = true
        }
    }
    
    private func loadImageFromPicker(newItem: PhotosPickerItem?) {
        if let newItem = newItem {
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    image = Image(uiImage: uiImage)
                    showCropView = true
                }
            }
        }
    }
    
    private var cropViewSheet: some View {
        if let selectedImage = selectedImage {
            return AnyView(CropView(image: selectedImage) { croppedImage in
                self.selectedImage = croppedImage.image
                self.image = Image(uiImage: croppedImage.image)
                self.showCropView = false
            } didCropToCircularImage: { croppedImage in
                self.selectedImage = croppedImage.image
                self.image = Image(uiImage: croppedImage.image)
                self.showCropView = false
            } didFinishCancelled: { _ in
                self.showCropView = false
            })
        } else {
            return AnyView(EmptyView())
        }
    }
    
    // MARK: - Tag Handling
    
    private func addTag() {
        guard !tagInput.isEmpty else { return }
        
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
    
    private func deleteTag(_ tag: Tag) {
        contact.removeFromTags(tag)
        viewContext.delete(tag)
        saveContext()
    }
    
    // MARK: - Save Context
    
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

// MARK: - Contact Extension

extension Contact {
    var isNew: Bool {
        id == nil
    }
}

// MARK: - Preview

#Preview {
    let dataController = DataController()
    let context = dataController.container.viewContext
    return ContactForm(contact: Contact(context: context))
        .environment(\.managedObjectContext, context)
}
