import SwiftUI
import SwiftData

struct DueCalendarInline: View {
    var invoices: [Invoice]
    var body: some View {
        let today = Calendar.current.startOfDay(for: Date())
        let days = (0..<30).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: today) }

        List(days, id: \.self) { day in
            let dueInvoices = invoices.filter { !$0.isPaid && Calendar.current.isDate($0.dueDate, inSameDayAs: day) }
            HStack {
                Text(DateFormatter.localizedString(from: day, dateStyle: .medium, timeStyle: .none))
                Spacer()
                if !dueInvoices.isEmpty {
                    Text("Due")
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                } else {
                    Text("No due")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}