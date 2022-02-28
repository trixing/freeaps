import SwiftUI
import Swinject

extension AddCarbs {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()

        private var formatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter
        }

        var body: some View {
            Form {
                if let carbsReq = state.carbsRequired {
                    Section {
                        HStack {
                            Text("Carbs required")
                            Spacer()
                            Text(formatter.string(from: carbsReq as NSNumber)! + " g")
                        }
                    }
                }
                Section {
                    HStack {
                        Text("Amount")
                        Spacer()
                        DecimalTextField("0", value: $state.carbs, formatter: formatter, autofocus: true, cleanInput: true)
                        Text("grams").foregroundColor(.secondary)
                    }
                    // DatePicker("Date", selection: $state.date)
                    //    .disabled(true)
                    Picker("Date", selection: $state.offset) {
                        Text("15 min ago").tag(TimeInterval(minutes: -15))
                        Text("Now").tag(TimeInterval(0))
                        Text("In 15 min").tag(TimeInterval(minutes: 15))
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Button { state.add() }
                        label: { Text("Add") }
                            // avoid typos like 0.10
                            .disabled(state.carbs < 1 || state.carbs > 99)
                    }
                }
            }
            .onAppear(perform: configureView)
            .navigationTitle("Add Carbs")
            .navigationBarTitleDisplayMode(.automatic)
            .navigationBarItems(leading: Button("Close", action: state.hideModal))
        }
    }
}
