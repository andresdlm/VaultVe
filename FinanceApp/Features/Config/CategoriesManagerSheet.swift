import SwiftUI

struct CategoriesManagerSheet: View {
    let engine: VaultEngine

    @Environment(\.dismiss) private var dismiss
    @State private var creatingKind: TransactionKind? = nil
    @State private var editingCategory: Category? = nil
    @State private var confirmDelete: Category? = nil

    var body: some View {
        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    FormHeader(title: "Categorías", subtitle: "ADMINISTRA LAS CATEGORÍAS DE TUS MOVIMIENTOS")
                        .padding(.bottom, 4)

                    CategorySection(
                        title: "GASTOS",
                        items: engine.categories(of: .expense),
                        onCreate: { creatingKind = .expense },
                        onEdit: { editingCategory = $0 },
                        onArchiveToggle: { c in
                            try? engine.setArchived(c, archived: !c.archived)
                        },
                        onDelete: { confirmDelete = $0 }
                    )

                    CategorySection(
                        title: "INGRESOS",
                        items: engine.categories(of: .income),
                        onCreate: { creatingKind = .income },
                        onEdit: { editingCategory = $0 },
                        onArchiveToggle: { c in
                            try? engine.setArchived(c, archived: !c.archived)
                        },
                        onDelete: { confirmDelete = $0 }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.large])
        .presentationBackground(.thinMaterial)
        .presentationDragIndicator(.visible)
        .sheet(item: $creatingKind) { kind in
            EditCategorySheet(engine: engine, kind: kind, category: nil)
        }
        .sheet(item: $editingCategory) { cat in
            EditCategorySheet(engine: engine, kind: cat.kind, category: cat)
        }
        .alert("Borrar categoría", isPresented: Binding(
            get: { confirmDelete != nil },
            set: { if !$0 { confirmDelete = nil } }
        )) {
            Button("Cancelar", role: .cancel) {}
            Button("Borrar", role: .destructive) {
                if let c = confirmDelete {
                    try? engine.deleteCategory(c)
                }
                confirmDelete = nil
            }
        } message: {
            Text("Los movimientos que la usaban quedarán sin categoría.")
        }
    }
}

private struct CategorySection: View {
    let title: String
    let items: [Category]
    let onCreate: () -> Void
    let onEdit: (Category) -> Void
    let onArchiveToggle: (Category) -> Void
    let onDelete: (Category) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).vLabel(color: .vAcc)
                Spacer()
                Button(action: onCreate) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 10, weight: .bold))
                        Text("NUEVA").vLabel(size: 9, color: .vAcc)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4).strokeBorder(Color.vAcc.opacity(0.45), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
            TerminalSeparator(style: .dashed).padding(.vertical, 9)

            if items.isEmpty {
                Text("// SIN CATEGORÍAS").vLabel(size: 9, color: .vTx3)
                    .padding(.vertical, 8)
            } else {
                ForEach(items) { c in
                    CategoryRow(
                        category: c,
                        onEdit: { onEdit(c) },
                        onArchiveToggle: { onArchiveToggle(c) },
                        onDelete: c.isDefault ? nil : { onDelete(c) }
                    )
                    if c != items.last {
                        TerminalSeparator(style: .dashed)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .solidCard()
    }
}

private struct CategoryRow: View {
    let category: Category
    let onEdit: () -> Void
    let onArchiveToggle: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        let color = Color(hex: category.colorHex)

        HStack(spacing: 8) {
            Text(category.glyph)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(category.name)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.vTx1)
                HStack(spacing: 4) {
                    if category.isDefault {
                        Text("DEFAULT").vLabel(size: 8, color: .vAcc)
                    }
                    if category.archived {
                        Text("ARCHIVADA").vLabel(size: 8, color: .vAmber)
                    }
                }
            }
            Spacer()
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.vAcc)
                    .padding(8)
            }
            .buttonStyle(.plain)

            Button(action: onArchiveToggle) {
                Image(systemName: category.archived ? "tray.and.arrow.up" : "tray.and.arrow.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.vAmber)
                    .padding(8)
            }
            .buttonStyle(.plain)

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.vDanger)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 5)
        .opacity(category.archived ? 0.55 : 1)
    }
}

struct EditCategorySheet: View {
    let engine: VaultEngine
    let kind: TransactionKind
    let category: Category?

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var glyph: String = "·"
    @State private var colorHex: String = "5A7A6E"

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    FormHeader(
                        title: category == nil ? "Nueva categoría" : "Editar categoría",
                        subtitle: kind == .expense ? "CATEGORÍA DE GASTO" : "CATEGORÍA DE INGRESO"
                    )
                    .padding(.bottom, 4)

                    VStack(spacing: 12) {
                        TerminalField(label: "NOMBRE", placeholder: "Mercado, Salario, etc.", text: $name)
                        GlyphPicker(label: "GLYPH", selected: $glyph)
                        AccentColorPicker(label: "COLOR", selected: $colorHex)
                    }
                    .padding(14)
                    .solidCard()

                    TerminalActionButton(
                        title: category == nil ? "CREAR CATEGORÍA" : "GUARDAR CAMBIOS",
                        color: .vAcc,
                        disabled: !canSave
                    ) {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        if let existing = category {
                            try? engine.updateCategory(existing, name: trimmed, glyph: glyph, colorHex: colorHex)
                        } else {
                            _ = try? engine.createCategory(name: trimmed, glyph: glyph, colorHex: colorHex, kind: kind)
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        dismiss()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.large])
        .presentationBackground(.thinMaterial)
        .presentationDragIndicator(.visible)
        .onAppear {
            if let c = category {
                name = c.name
                glyph = c.glyph
                colorHex = c.colorHex
            }
        }
    }
}
