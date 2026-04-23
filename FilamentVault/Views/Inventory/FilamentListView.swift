import SwiftUI
import SwiftData

struct FilamentListView: View {
    @Environment(\.modelContext) private var context
    @Query private var filaments: [Filament]

    @State private var showFilterSheet = false
    @State private var showAddSheet = false
    @State private var filterCriteria = FilterCriteria()
    @State private var pendingDelete: Filament?

    var visible: [Filament] {
        let filtered = filterCriteria.isActive
            ? filaments.filter { filterCriteria.matches($0) }
            : filaments
        return ColorWheelSort.sorted(filtered)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if visible.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(visible) { filament in
                            NavigationLink {
                                FilamentDetailView(filament: filament)
                            } label: {
                                FilamentCardView(filament: filament)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            pendingDelete = filament
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    pendingDelete = filament
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 88)
                }
            }
        }
        .navigationTitle("FilamentVault")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showFilterSheet = true } label: {
                    Image(systemName: filterCriteria.isActive
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                FilamentDetailView(filament: nil)
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(
                criteria: $filterCriteria,
                availableBrands: availableBrands
            )
        }
        .alert("Delete filament?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let f = pendingDelete {
                    ImageStorage.delete(f.imageFilename)
                    if let orig = f.originalImageFilename, orig != f.imageFilename {
                        ImageStorage.delete(orig)
                    }
                    context.delete(f)
                    try? context.save()
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            if let f = pendingDelete {
                Text("\(f.materialType) \(f.colorName ?? f.colorHex)")
            }
        }
    }

    private var availableBrands: [String] {
        Array(Set(filaments.compactMap(\.brand))).sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(filterCriteria.isActive ? "No filaments match your filters" : "No filaments yet")
                .font(.title3)
                .foregroundStyle(.secondary)
            if !filterCriteria.isActive {
                Text("Tap + to add your first spool")
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
