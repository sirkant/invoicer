import SwiftUI
import SwiftData

struct MonthlyCalendarView: View {
    var invoices: [Invoice]
    @State private var selectedDate: Date? = nil
    @State private var selectedInvoices: [Invoice] = []

    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()

    init(invoices: [Invoice]) {
        self.invoices = invoices
        dateFormatter.dateFormat = "MMM yyyy"
    }

    var body: some View {
        let month = calendar.dateInterval(of: .month, for: Date()) ?? DateInterval()
        let monthStart = month.start
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!.count
        let firstWeekday = calendar.component(.weekday, from: monthStart) - calendar.firstWeekday
        let offset = firstWeekday < 0 ? firstWeekday + 7 : firstWeekday

        // We now have offset empty cells before the first day
        // We'll show 7 columns: Sun through Sat
        let weekdays = calendar.shortStandaloneWeekdaySymbols // ["Sun", "Mon", ...] depending on locale
        
        // Generate all days for this month, plus offset for empty leading days
        let totalCells = offset + daysInMonth
        let rows = Int(ceil(Double(totalCells) / 7.0))
        let displayedDays = rows * 7

        // Create an array of Dates or nil for empty cells
        var daysArray: [Date?] = Array(repeating: nil, count: offset)
        for day in 1...daysInMonth {
            let dayDate = calendar.date(byAdding: .day, value: day-1, to: monthStart)!
            daysArray.append(dayDate)
        }
        // Fill remaining empty cells at the end
        while daysArray.count < displayedDays {
            daysArray.append(nil)
        }

        return VStack(spacing: 10) {
            // Month title
            Text(dateFormatter.string(from: monthStart))
                .font(.headline)
                .padding(.top, 5)

            // Weekday headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(weekdays, id: \.self) { dayName in
                    Text(dayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(minWidth: 20, minHeight: 20)
                        .foregroundColor(.gray)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(0..<daysArray.count, id: \.self) { index in
                    if let dayDate = daysArray[index] {
                        CalendarDayView(date: dayDate, invoices: invoices) { selected in
                            selectedDate = selected
                            selectedInvoices = invoicesDue(on: selected)
                        }
                    } else {
                        // Empty cell
                        Rectangle().fill(Color.clear).frame(minHeight: 30)
                    }
                }
            }
        }
        .padding()
        .background(Color(white: 0.95))
        .cornerRadius(10)
        .sheet(item: $selectedDate) { date in
            // Show invoices due that day
            NavigationStack {
                List(selectedInvoices, id: \.uuid) { inv in
                    VStack(alignment: .leading) {
                        Text("Invoice: \(inv.invoiceNumber)")
                            .font(.headline)
                        Text("Due: \(inv.dueDate, style: .date)")
                    }
                }
                .navigationTitle(Text(date, style: .date))
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    func invoicesDue(on date: Date) -> [Invoice] {
        return invoices.filter { !$0.isPaid && calendar.isDate($0.dueDate, inSameDayAs: date) }
    }
}

struct CalendarDayView: View {
    let date: Date
    let invoices: [Invoice]
    let onSelect: (Date) -> Void

    private let calendar = Calendar.current

    var body: some View {
        let isToday = calendar.isDateInToday(date)
        let dueInvoices = invoices.filter { !$0.isPaid && calendar.isDate($0.dueDate, inSameDayAs: date) }

        Button(action: {
            if !dueInvoices.isEmpty {
                onSelect(date)
            }
        }) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.headline)
                    .foregroundColor(isToday ? .white : (dueInvoices.isEmpty ? .primary : .green))
                    .frame(minWidth: 30, minHeight: 30)
                    .background(isToday ? Color.blue : Color.white)
                    .cornerRadius(5)
                if !dueInvoices.isEmpty {
                    // A small dot or marker
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                }
            }
        }
    }
}