import SwiftUI

struct IntroView: View {
    @State private var navigateToMain = false

    var body: some View {
        VStack(spacing: 50) {
            Spacer()
            Image(systemName: "building.2.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            Text("BoringSoftwareThatWorks")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                navigateToMain = true
            }
        }
        .fullScreenCover(isPresented: $navigateToMain) {
            MainMenuView()
        }
    }
}