import SwiftUI

// Home Quote View with Calendar
struct HomeQuoteView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @ObservedObject private var eventService = EventService.shared
    @State private var quote: Quote
    @State private var showingShareSheet = false
    @State private var showingEventEditor = false
    @State private var editingEvent: Event?
    @State private var selectedDate = Date()
    
    init() {
        // Initialize with today's quote
        _quote = State(initialValue: QuoteService.shared.getTodaysQuote())
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Quote of the day section
                    VStack {
                        Text("QUOTE OF THE DAY")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .tracking(2)
                            .padding(.top, 20)
                        
                        QuoteCardView(
                            quote: quote,
                            isFavorite: quoteService.isFavorite(quote),
                            onFavoriteToggle: {
                                if quoteService.isFavorite(quote) {
                                    quoteService.removeFromFavorites(quote)
                                } else {
                                    quoteService.addToFavorites(quote)
                                }
                            },
                            onShare: {
                                showingShareSheet = true
                            },
                            onRefresh: {
                                // Get a random quote instead of today's quote for more variety
                                quote = quoteService.getRandomQuote()
                            }
                        )
                    }
                    .padding(.bottom, 10)
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal, 40)
                    
                    // Calendar section
                    VStack(spacing: 15) {
                        // Calendar title with add button
                        HStack {
                            Text("IMPORTANT DATES")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .tracking(2)
                            
                            Spacer()
                            
                            Button(action: {
                                editingEvent = nil
                                showingEventEditor = true
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Week calendar
                        CalendarWeekView(selectedDate: $selectedDate)
                            .padding(.vertical, 10)
                        
                        // Selected date title
                        HStack {
                            let formatter: DateFormatter = {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "EEEE, MMMM d"
                                return formatter
                            }()
                            
                            Text(formatter.string(from: selectedDate))
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 5)
                        
                        // Events for selected date
                        VStack(spacing: 10) {
                            let eventsForDay = eventService.getEvents(for: selectedDate)
                            
                            if eventsForDay.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                        .padding(.top, 20)
                                    
                                    Text("No events for this day")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Button(action: {
                                        editingEvent = nil
                                        showingEventEditor = true
                                    }) {
                                        Text("Add Event")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color.white)
                                            .cornerRadius(20)
                                    }
                                    .padding(.top, 10)
                                    .padding(.bottom, 20)
                                }
                                .frame(maxWidth: .infinity)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            } else {
                                ForEach(eventsForDay) { event in
                                    EventListItem(
                                        event: event,
                                        onComplete: {
                                            eventService.toggleCompletionStatus(event)
                                        },
                                        onDelete: {
                                            eventService.deleteEvent(event)
                                        },
                                        onEdit: {
                                            editingEvent = event
                                            showingEventEditor = true
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Upcoming events section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("UPCOMING EVENTS")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .tracking(2)
                                .padding(.top, 10)
                                .padding(.horizontal, 20)
                            
                            let upcomingEvents = eventService.getUpcomingEvents()
                            
                            if upcomingEvents.isEmpty {
                                Text("No upcoming events for the next 7 days")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                ForEach(upcomingEvents) { event in
                                    EventListItem(
                                        event: event,
                                        onComplete: {
                                            eventService.toggleCompletionStatus(event)
                                        },
                                        onDelete: {
                                            eventService.deleteEvent(event)
                                        },
                                        onEdit: {
                                            editingEvent = event
                                            showingEventEditor = true
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                // Add extra padding at the bottom to account for tab bar + banner ad
                // Standard tab bar is 49pt + banner ad is 50pt + some extra space
                .padding(.bottom, 110)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: ["\(quote.text) — \(quote.author)"])
        }
        .sheet(isPresented: $showingEventEditor) {
            if let event = editingEvent {
                EventEditorView(event: event)
            } else {
                EventEditorView(initialDate: selectedDate) // Pass selected date here
            }
        }
    }
}

// SwiftUI Preview
struct HomeQuoteView_Previews: PreviewProvider {
    static var previews: some View {
        HomeQuoteView()
            .preferredColorScheme(.dark)
    }
}
