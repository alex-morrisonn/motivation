import SwiftUI

/// View for creating and editing events
struct EventEditorView: View {
    // MARK: - Environment & Observed Properties
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var eventService: EventService
    
    // MARK: - State Properties
    @State private var title: String
    @State private var date: Date
    @State private var notes: String
    @State private var isCompleted: Bool
    
    // MARK: - Private Properties
    private let isNew: Bool
    private var eventId: UUID
    
    // MARK: - Initialization
    
    /// Initialize with a new event and optional initial date
    /// - Parameters:
    ///   - eventService: The service managing events
    ///   - initialDate: Optional date to pre-populate (defaults to current date/time)
    init(eventService: EventService = EventService.shared, initialDate: Date = Date()) {
        self.eventService = eventService
        _title = State(initialValue: "")
        _date = State(initialValue: initialDate)
        _notes = State(initialValue: "")
        _isCompleted = State(initialValue: false)
        isNew = true
        eventId = UUID() // Generate a new id for the event
    }
    
    /// Initialize for editing an existing event
    /// - Parameters:
    ///   - event: The event to edit
    ///   - eventService: The service managing events
    init(event: Event, eventService: EventService = EventService.shared) {
        self.eventService = eventService
        _title = State(initialValue: event.title)
        _date = State(initialValue: event.date)
        _notes = State(initialValue: event.notes)
        _isCompleted = State(initialValue: event.isCompleted)
        isNew = false
        eventId = event.id // Use the existing event's id
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text(isNew ? "Add New Event" : "Edit Event")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Title Field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Event Title")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter title", text: $title)
                            .padding()
                            .background(Color(UIColor.systemGray6).opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // Date & Time Picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Date & Time")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        DatePicker("", selection: $date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .background(Color(UIColor.systemGray6).opacity(0.2))
                            .cornerRadius(10)
                            .colorScheme(.dark)
                    }
                    .padding(.horizontal)
                    
                    // Notes Field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .padding(5)
                                .background(Color(UIColor.systemGray6).opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .colorScheme(.dark) // Force dark mode for TextEditor
                            
                            if notes.isEmpty {
                                Text("Add notes here...")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                                    .padding(.top, 13)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Completed Toggle
                    Toggle(isOn: $isCompleted) {
                        Text("Completed")
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    HStack {
                        // Cancel Button
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(10)
                        }
                        
                        // Save Button
                        Button(action: {
                            saveEvent()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Save")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal)
                    
                    // Add padding at the bottom to ensure scrolling can reach all content
                    Spacer(minLength: 30)
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Saves the current event to the EventService
    private func saveEvent() {
        let eventToSave = Event(
            id: eventId,
            title: title,
            date: date,
            notes: notes,
            isCompleted: isCompleted
        )
        
        if isNew {
            eventService.addEvent(eventToSave)
        } else {
            eventService.updateEvent(eventToSave)
        }
    }
}

// MARK: - Preview Provider
struct EventEditorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for new event
            EventEditorView(initialDate: Date())
                .preferredColorScheme(.dark)
                .previewDisplayName("New Event")
            
            // Preview for editing existing event
            EventEditorView(event: Event(
                id: UUID(),
                title: "Sample Event",
                date: Date(),
                notes: "This is a sample event note",
                isCompleted: false
            ))
            .preferredColorScheme(.dark)
            .previewDisplayName("Edit Event")
        }
    }
}
