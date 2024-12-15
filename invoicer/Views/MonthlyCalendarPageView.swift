import SwiftUI

struct MonthlyCalendarPageView: View {
    let invoices: [Invoice]
    let monthOffset: Int
    let onSelectDay: (Date) -> Void

    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()

    init(invoices: [Invoice], monthOffset: Int, onSelectDay: @escaping (Date) -> Void) {
        self.invoices = invoices
        self.monthOffset = monthOffset
        self.onSelectDay = onSelectDay
        dateFormatter.dateFormat = "MMM yyyy"
    }

    var body: some View {
        let monthStart = startOfMonth(offset: monthOffset)
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!.count
        let firstWeekday = calendar.component(.weekday, from: monthStart) - calendar.firstWeekday
        let offset = firstWeekday < 0 ? firstWeekday + 7 : firstWeekday

        let weekdays = calendar.shortStandaloneWeekdaySymbols
        let totalCells = offset + daysInMonth
        let rows = Int(ceil(Double(totalCells)/7.0))
        let displayedDays = rows * 7

        var daysArray: [Date?] = Array(repeating: nil, count: offset)
        for day in 1...daysInMonth {
            let dayDate = calendar.date(byAdding: .day, value: day-1, to: monthStart)!
            daysArray.append(dayDate)
        }
        while daysArray.count < displayedDays {
            daysArray.append(nil)
        }

        VStack(spacing: 10) {
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
                        CalendarDayCell(date: dayDate, invoices: invoices, onSelect: onSelectDay)
                    } else {
                        Rectangle().fill(Color.clear).frame(minHeight: 30)
                    }
                }
            }
        }
        .padding()
        .background(Color(white: 0.95))
        .cornerRadius(10)
    }

    func startOfMonth(offset: Int) -> Date {
        // current month start
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        let currentMonthStart = calendar.date(from: components)!
        // add offset months
        return calendar.date(byAdding: .month, value: offset, to: currentMonthStart)!
    }
}