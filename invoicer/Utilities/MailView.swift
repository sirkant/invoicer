import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    let toRecipients: [String]?
    let ccRecipients: [String]?
    let subject: String
    let body: String
    let attachments: [(Data, String)]

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(toRecipients)
        if let cc = ccRecipients, !cc.isEmpty {
            vc.setCcRecipients(cc)
        }
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        for attachment in attachments {
            vc.addAttachmentData(attachment.0, mimeType: "application/pdf", fileName: attachment.1)
        }
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        init(_ parent: MailView) {
            self.parent = parent
        }

        func mailComposeViewController(_ controller: MFMailComposeViewController,
                                       didFinishWith result: MFMailComposeResult,
                                       error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

func presentMailCompose(to: String?, cc: String?, subject: String, body: String, pdfURL: URL) -> some View {
    if MFMailComposeViewController.canSendMail() {
        let pdfData = (try? Data(contentsOf: pdfURL)) ?? Data()
        return AnyView(MailView(toRecipients: to != nil ? [to!] : nil,
                                ccRecipients: cc != nil && !cc!.isEmpty ? [cc!] : nil,
                                subject: subject,
                                body: body,
                                attachments: [(pdfData, "Invoice.pdf")]))
    } else {
        return AnyView(ShareSheet(activityItems: [pdfURL]))
    }
}