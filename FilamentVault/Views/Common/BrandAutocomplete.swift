import SwiftUI

/// Brand field with a live-filtered suggestion list. Tapping a suggestion fills
/// the value and dismisses. Typing a custom brand is always allowed.
struct BrandAutocomplete: View {
    @Binding var value: String
    let availableBrands: [String]

    @State private var showSuggestions = false
    @FocusState private var focused: Bool

    var filtered: [String] {
        if value.isEmpty { return availableBrands }
        return availableBrands.filter {
            $0.range(of: value, options: .caseInsensitive) != nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Brand", text: $value)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .onChange(of: focused) { _, new in
                    showSuggestions = new
                }
                .onChange(of: value) { _, _ in
                    showSuggestions = focused
                }

            if showSuggestions && !filtered.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filtered.prefix(8), id: \.self) { brand in
                            Button {
                                value = brand
                                focused = false
                                showSuggestions = false
                            } label: {
                                HStack {
                                    Text(brand)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(white: 0.12))
                            }
                            .buttonStyle(.plain)
                            Divider().overlay(Color(white: 0.2))
                        }
                    }
                }
                .frame(maxHeight: 240)
                .background(Color(white: 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
