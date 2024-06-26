import SwiftUI
import CoreData

struct ContactsView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.dateMet, order: .reverse)]) var contacts: FetchedResults<Contact>
    @Environment(\.managedObjectContext) var viewContext
    @State private var showAddContactSheet = false
    @State private var showSettingsSheet = false
    @State private var showingGrid = true
    @State private var contactToEdit: Contact?
    @State private var selectedTag: Tag?
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) private var allTags: FetchedResults<Tag>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedContacts.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(dateFormatter.string(from: date))) {
                        ForEach(groupedContacts[date] ?? []) { contact in
                            NavigationLink(destination: ContactForm(contact: contact)) {
                                HStack {
                                    if let imageData = contact.photo, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 30, height: 30)
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                            .padding(.leading, -8)
                                    } else {
                                        Rectangle()
                                            .fill(Color(UIColor.quaternarySystemFill))
                                            .frame(width: 30, height: 30)
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                            .padding(.leading, -8)
                                    }
                                    Text(contact.name ?? "New Person")
                                        .foregroundColor(contact.name == "New Person" ? Color(UIColor.quaternaryLabel) : Color.primary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            deleteContacts(at: indexSet, for: date)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle()) // Ensures the list style is consistent
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let newContact = Contact(context: viewContext)
                        newContact.id = UUID() // Ensure new contacts have a UUID
                        newContact.dateMet = Date() // Set default date
                        contactToEdit = newContact
                        showAddContactSheet = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            selectedTag = nil
                        } label: {
                            Label("All Tags", systemImage: "tag")
                                .foregroundColor(selectedTag == nil ? .accentColor : .primary)
                        }
                        ForEach(sortedTags) { tag in
                            Button {
                                selectedTag = tag
                            } label: {
                                Label("\(tag.name ?? "")", systemImage: "tag")
                                    .foregroundColor(selectedTag == tag ? .accentColor : .primary)
                                    .overlay(
                                        selectedTag == tag ? Image(systemName: "checkmark").foregroundColor(.accentColor) : nil,
                                        alignment: .trailing
                                    )
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: selectedTag != nil ? "line.horizontal.3.decrease.circle.fill" : "line.horizontal.3.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showSettingsSheet = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                        Button {
                            showingGrid.toggle()
                        } label: {
                            Label("Change Layout", systemImage: "square.on.square.intersection.dashed")
                        }
                        
                        Button {
                            selectedTag = nil
                        } label: {
                            Label("Clear Filter", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .navigationTitle("New People")
        }
        .sheet(isPresented: $showAddContactSheet) {
            if let contact = contactToEdit {
                NavigationView {
                    ContactForm(contact: contact)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
        }
    }
    
    private var groupedContacts: [Date: [Contact]] {
        let contactsArray = Array(contacts)
        let filteredContacts = selectedTag == nil ? contactsArray : contactsArray.filter { $0.tags?.contains(selectedTag!) ?? false }
        return Dictionary(grouping: filteredContacts) { (contact: Contact) -> Date in
            Calendar.current.startOfDay(for: contact.dateMet ?? Date())
        }
    }
    
    private func deleteContacts(at offsets: IndexSet, for date: Date) {
        guard let contactsForDate = groupedContacts[date] else { return }
        
        for index in offsets {
            let contact = contactsForDate[index]
            viewContext.delete(contact)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete contact: \(error.localizedDescription)")
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var tagUsageCount: [Tag: Int] {
        var countDict: [Tag: Int] = [:]
        for contact in contacts {
            if let tags = contact.tags as? Set<Tag> {
                for tag in tags {
                    countDict[tag, default: 0] += 1
                }
            }
        }
        return countDict
    }
    
    private var sortedTags: [Tag] {
        allTags.sorted { (tag1, tag2) -> Bool in
            let count1 = tagUsageCount[tag1] ?? 0
            let count2 = tagUsageCount[tag2] ?? 0
            return count1 > count2
        }
    }
}

#Preview {
    let dataController = DataController()
    let context = dataController.container.viewContext
    return ContactsView()
        .environment(\.managedObjectContext, context)
}
