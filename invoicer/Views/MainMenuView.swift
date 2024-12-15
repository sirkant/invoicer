import SwiftUI
import SwiftData

struct MainMenuView: View {
    @Query var invoices: [Invoice]
    @Query var companyInfos: [CompanyInfo]

    let backgroundColor = Color(red: 0.0/255, green: 39.0/255, blue: 86.0/255)

    var outstandingInvoices: [Invoice] {
        invoices.filter { !$0.isPaid }
    }

    var totalOutstanding: Double {
        outstandingInvoices.reduce(0) { $0 + $1.totalAmount }
    }

    var overdueInvoices: [Invoice] {
        invoices.filter { !$0.isPaid && $0.dueDate < Date() }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    backgroundColor.ignoresSafeArea()
                    VStack(spacing: 20) {
                        HStack {
                            if let company = companyInfos.first, let logo = company.logoImage {
                                Link(destination: URL(string: "https://bstw.ai")!) {
                                    Image(uiImage: logo)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .padding(.leading)
                                }
                            } else {
                                Link(destination: URL(string: "https://bstw.ai")!) {
                                    Image(systemName: "building")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .padding(.leading)
                                }
                            }
                            Spacer()
                            Image(systemName: "doc.text.fill.viewfinder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .padding(.trailing, geo.size.width/2 - 25)
                        }
                        .padding(.top, 50)

                        // Top stats
                        Text("Outstanding Invoices: \(outstandingInvoices.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(String(format: "$%.2f", totalOutstanding))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        // Middle: inline due calendar, 40% height approx
                        DueCalendarInline(invoices: invoices)
                            .frame(height: geo.size.height * 0.4)

                        Spacer()

                        // Bottom 30% for three buttons
                        let buttonAreaHeight = geo.size.height * 0.3
                        let buttonSide = buttonAreaHeight * 0.8
                        HStack(spacing: 20) {
                            NavigationLink(destination: CreateInvoiceView()) {
                                VStack {
                                    Image(systemName: "square.and.pencil")
                                    Text("New Invoice")
                                }
                                .font(.headline)
                                .frame(width: buttonSide, height: buttonSide)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }

                            NavigationLink(destination: ViewInvoicesView()) {
                                VStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                    Text("Invoices")
                                }
                                .font(.headline)
                                .frame(width: buttonSide, height: buttonSide)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }

                            NavigationLink(destination: EditInfoView()) {
                                VStack {
                                    Image(systemName: "gearshape")
                                    Text("Edit Info")
                                }
                                .font(.headline)
                                .frame(width: buttonSide, height: buttonSide)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}