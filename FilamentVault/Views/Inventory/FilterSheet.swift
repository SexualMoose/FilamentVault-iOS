import SwiftUI

struct FilterSheet: View {
    @Binding var criteria: FilterCriteria
    let availableBrands: [String]
    @Environment(\.dismiss) private var dismiss

    @State private var working: FilterCriteria = FilterCriteria()

    var body: some View {
        NavigationStack {
            Form {
                Section("Material") {
                    ForEach(MaterialType.allCases) { mat in
                        Toggle(mat.displayName, isOn: Binding(
                            get: { working.materialTypes.contains(mat.rawValue) },
                            set: { on in
                                if on { working.materialTypes.insert(mat.rawValue) }
                                else { working.materialTypes.remove(mat.rawValue) }
                            }
                        ))
                    }
                }

                if !availableBrands.isEmpty {
                    Section("Brand") {
                        ForEach(availableBrands, id: \.self) { brand in
                            Toggle(brand, isOn: Binding(
                                get: { working.brands.contains(brand) },
                                set: { on in
                                    if on { working.brands.insert(brand) }
                                    else { working.brands.remove(brand) }
                                }
                            ))
                        }
                    }
                }

                Section("Diameter") {
                    Picker("Diameter", selection: Binding(
                        get: { working.diameter },
                        set: { working.diameter = $0 }
                    )) {
                        Text("Any").tag(Double?.none)
                        Text("1.75 mm").tag(Double?.some(1.75))
                        Text("2.85 mm").tag(Double?.some(2.85))
                    }
                    .pickerStyle(.segmented)
                }

                Section("Nozzle Temperature (°C)") {
                    HStack {
                        Text("Min")
                        Spacer()
                        TextField("", value: $working.nozzleTempMin, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Max")
                        Spacer()
                        TextField("", value: $working.nozzleTempMax, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { working = FilterCriteria() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        criteria = working
                        dismiss()
                    }
                }
            }
            .onAppear { working = criteria }
        }
    }
}
