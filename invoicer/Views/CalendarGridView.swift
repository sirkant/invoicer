import SwiftUI
import SwiftData

struct CalendarGridView: View {
    var invoices: [Invoice]

    let dayCount = 35 // A 5-week grid
    var days: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        return (0..<dayCount).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: today)
        }
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(days, id: \.self) { day in
                let dueInvoices = invoices.filter { !$0.isPaid && Calendar.current.isDate($0.dueDate, inSameDayAs: day) }

                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.headline)
                    .foregroundColor(dueInvoices.isEmpty ? .primary : .green)
                    .frame(minWidth: 30, minHeight: 30)
                    .background(Color.white)
                    .cornerRadius(5)
            }
        }
        .padding()
        .background(Color(white: 0.95))
        .cornerRadius(10)
    }
}