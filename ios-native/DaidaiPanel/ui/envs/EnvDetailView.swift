import SwiftUI

struct EnvDetailView: View {
    let env: EnvVar
    @ObservedObject var viewModel: EnvViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var value: String = ""
    @State private var remarks: String = ""
    @State private var group: String = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var showDeleteConfirm = false

    var body: some View {
        GlassScaffold {
            ScrollView {
                VStack(spacing: 16) {
                    formCard
                    actionCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("环境变量详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    Task { await save() }
                }
                .disabled(name.isEmpty || value.isEmpty || isLoading)
            }
        }
        .onAppear {
            name = env.name
            value = env.value
            remarks = env.remarks
            group = env.group
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                Task {
                    try? await viewModel.deleteEnv(env.id)
                    dismiss()
                }
            }
        } message: {
            Text("确定要删除环境变量「\(env.name)」吗？")
        }
    }

    private var formCard: some View {
        GlassCard(padding: 16) {
            VStack(spacing: 14) {
                formField(label: "变量名", text: $name, placeholder: "变量名")
                formSecureField(label: "变量值", text: $value, placeholder: "变量值")
                formField(label: "分组", text: $group, placeholder: "分组（可选）")
                formField(label: "备注", text: $remarks, placeholder: "备注（可选）")

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(AppColors.error)
                }
            }
        }
    }

    private var actionCard: some View {
        GlassCard(padding: 16) {
            VStack(spacing: 12) {
                Button {
                    Task { try? await viewModel.toggleEnv(env) }
                } label: {
                    HStack {
                        Image(systemName: env.enabled ? "pause.circle" : "checkmark.circle")
                        Text(env.enabled ? "禁用" : "启用")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.blue500.opacity(0.1))
                    .foregroundColor(AppColors.blue500)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("删除")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.error.opacity(0.1))
                    .foregroundColor(AppColors.error)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func formField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(10)
                .background(AppColors.glassBg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func formSecureField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            SecureField(placeholder, text: text)
                .textFieldStyle(.plain)
                .padding(10)
                .background(AppColors.glassBg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func save() async {
        isLoading = true
        error = nil

        let body: [String: Any] = [
            "name": name,
            "value": value,
            "remarks": remarks,
            "group": group
        ]

        do {
            try await viewModel.updateEnv(env.id, body: body)
            dismiss()
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }
}
