import SwiftUI
import SwiftData

struct MultiMonthCalendarView: View {
    var invoices: [Invoice]

    // Let's say we show from 6 months in the past to 12 months in the future for demo
    private let totalMonths = 6 + 12 + 1 // 6 months past, current month, 12 future
    @State private var currentIndex: Int = 6 // start at current month index (0 would be 6 months in the past)
    @State private var selectedDate: Date? = nil
    @State private var selectedInvoices: [Invoice] = []

    private let calendar = Calendar.current

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(0..<totalMonths, id: \.self) { i in
                let offset = i - 6 // offset relative to current month
                MonthlyCalendarPageView(invoices: invoices, monthOffset: offset) { date in
                    selectedDate = date
                    selectedInvoices = invoicesDue(on: date)
                }
                .tag(i)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .sheet(item: $selectedDate) { date in
            // Show due invoices for selected day
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
        invoices.filter { !$0.isPaid && calendar.isDate($0.dueDate, inSameDayAs: date) }
    }
}