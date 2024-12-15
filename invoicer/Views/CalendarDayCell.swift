import SwiftUI

struct CalendarDayCell: View {
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
                    .background(isToday ? Color.red : Color.white)
                    .clipShape(Circle())

                if !dueInvoices.isEmpty {
                    // A small dot or marker below the day
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                }
            }
        }
    }
}