import SwiftUI

// MARK: - Calendar Month View

struct CalendarMonthGridView: View {
    let month: Date
    let selectedDate: Date
    let showWeekends: Bool
    @ObservedObject var eventService: EventService
    let onSelectDate: (Date) -> Void

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 14) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(weekdayHeaders, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Color.themeSecondaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(monthGridDates, id: \.self) { date in
                    CalendarMonthDayCell(
                        date: date,
                        isInDisplayedMonth: calendar.isDate(date, equalTo: month, toGranularity: .month),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        eventCount: eventService.eventCount(on: date)
                    )
                    .onTapGesture {
                        Haptics.selection()
                        onSelectDate(date)
                    }
                }
            }
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: weekdayHeaders.count)
    }

    private var weekdayHeaders: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let prefix = Array(symbols[(calendar.firstWeekday - 1)...])
        let suffix = Array(symbols[..<(calendar.firstWeekday - 1)])
        let reordered = prefix + suffix

        if showWeekends {
            return reordered
        }

        return reordered.enumerated().compactMap { offset, symbol in
            let weekday = normalizedWeekday(forOffset: offset)
            return isWeekend(weekday) ? nil : symbol
        }
    }

    private var monthGridDates: [Date] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: month),
            let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
            let lastMonthDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
            let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: lastMonthDay)
        else {
            return []
        }

        var dates: [Date] = []
        var cursor = firstWeek.start

        while cursor < lastWeek.end {
            if showWeekends || !calendar.isDateInWeekend(cursor) {
                dates.append(cursor)
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = nextDate
        }

        return dates
    }

    private func normalizedWeekday(forOffset offset: Int) -> Int {
        ((calendar.firstWeekday - 1 + offset) % 7) + 1
    }

    private func isWeekend(_ weekday: Int) -> Bool {
        let weekendDays = (1...7).filter { day in
            var components = DateComponents()
            components.weekday = day
            let date = calendar.nextDate(after: .now, matching: components, matchingPolicy: .nextTimePreservingSmallerComponents) ?? .now
            return calendar.isDateInWeekend(date)
        }

        return weekendDays.contains(weekday)
    }
}

struct CalendarMonthDayCell: View {
    let date: Date
    let isInDisplayedMonth: Bool
    let isSelected: Bool
    let isToday: Bool
    let eventCount: Int

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 8) {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline.weight(isSelected || isToday ? .bold : .medium))
                .foregroundColor(dayForeground)
                .frame(maxWidth: .infinity)

            if eventCount > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.95) : Color.themePrimary.opacity(0.9))
                        .frame(width: 6, height: 6)

                    Text(eventCount > 3 ? "3+" : "\(eventCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(dayForeground.opacity(0.9))
                }
            } else {
                Spacer()
                    .frame(height: 10)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 62)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(border, lineWidth: isSelected || isToday ? 1.2 : 0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(isInDisplayedMonth ? 1 : 0.35)
    }

    private var background: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.themePrimary.opacity(0.95), Color.themeSecondary.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        if isToday {
            return AnyShapeStyle(Color.themeCardBackground.opacity(0.95))
        }

        return AnyShapeStyle(Color.themeCardBackground.opacity(0.55))
    }

    private var border: Color {
        isSelected ? Color.white.opacity(0.25) : Color.themePrimary.opacity(0.4)
    }

    private var dayForeground: Color {
        if isSelected {
            return .white
        }

        return isToday ? Color.themeText : Color.themeText.opacity(isInDisplayedMonth ? 0.92 : 0.55)
    }
}

// MARK: - Week Strip

struct CalendarWeekStripView: View {
    let selectedDate: Date
    let anchorDate: Date
    let showWeekends: Bool
    @ObservedObject var eventService: EventService
    let onSelectDate: (Date) -> Void

    private let calendar = Calendar.current

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(weekDates, id: \.self) { date in
                    CalendarWeekPill(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        eventCount: eventService.eventCount(on: date)
                    )
                    .onTapGesture {
                        Haptics.selection()
                        onSelectDate(date)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var weekDates: [Date] {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: anchorDate)?.start else {
            return []
        }

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            if showWeekends || !calendar.isDateInWeekend(date) {
                return date
            }
            return nil
        }
    }
}

struct CalendarWeekPill: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let eventCount: Int

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 8) {
            Text(shortWeekday)
                .font(.caption2.weight(.semibold))
                .foregroundColor(isSelected ? .white.opacity(0.8) : Color.themeSecondaryText)

            Text("\(calendar.component(.day, from: date))")
                .font(.headline.weight(.bold))
                .foregroundColor(isSelected ? .white : Color.themeText)

            if eventCount > 0 {
                Text("\(eventCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(isSelected ? .white : Color.themePrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isSelected ? Color.white.opacity(0.16) : Color.themePrimary.opacity(0.12)))
                    .clipShape(Capsule())
            } else {
                Circle()
                    .fill((isSelected ? Color.white.opacity(0.18) : Color.themeDivider.opacity(0.8)))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isToday ? Color.themePrimary.opacity(0.5) : Color.clear, lineWidth: 1.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private var background: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.themePrimary, Color.themeSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(Color.themeCardBackground.opacity(0.8))
    }
}

// MARK: - Event Cards

struct CalendarEventCard: View {
    let event: Event
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(event.tintColor.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: event.iconName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(event.tintColor)
                }

                RoundedRectangle(cornerRadius: 999)
                    .fill(event.tintColor.opacity(0.4))
                    .frame(width: 3)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.title)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Color.themeText)
                            .strikethrough(event.isCompleted)

                        HStack(spacing: 8) {
                            Label(event.formattedTime, systemImage: event.isAllDay ? "sun.max" : "clock")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.themeSecondaryText)

                            if event.isCompleted {
                                Text("Done")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(Color.themeSuccess)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.themeSuccess.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Spacer()

                    Button(action: onComplete) {
                        Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(event.isCompleted ? Color.themeSuccess : Color.themeSecondaryText)
                    }
                    .buttonStyle(.plain)
                }

                if !event.notes.isEmpty {
                    Text(event.notes)
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondaryText)
                        .lineLimit(3)
                }

                HStack(spacing: 10) {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "slider.horizontal.3")
                    }

                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.themeSecondaryText)
            }
        }
        .padding(18)
        .background(Color.themeCardBackground.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct CalendarEmptyStateCard: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.themePrimary.opacity(0.14))
                    .frame(width: 64, height: 64)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(Color.themePrimary)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color.themeText)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondaryText)
                    .multilineTextAlignment(.center)
            }

            Button(action: action) {
                Text(actionTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.themePrimary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(Color.themeCardBackground.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct CalendarQuickActionChip: View {
    let title: String
    let subtitle: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.themePrimary.opacity(0.14))
                        .frame(width: 34, height: 34)

                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.themePrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.themeCardBackground.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct CalendarInsightCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(tint)

                Spacer()

                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(tint.opacity(0.25), lineWidth: 1)
                    )
            }

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(Color.themeText)

            Text(title)
                .font(.caption)
                .foregroundColor(Color.themeSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.themeCardBackground.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
