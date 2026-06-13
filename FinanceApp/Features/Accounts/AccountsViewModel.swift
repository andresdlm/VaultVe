import Foundation
import Observation

@Observable
final class AccountsViewModel {
    let engine: VaultEngine

    var showAddAccount: Bool = false
    var showArchived: Bool = false
    var editingAccount: Account? = nil

    init(engine: VaultEngine) {
        self.engine = engine
    }

    var accounts: [Account] {
        showArchived ? engine.allAccounts : engine.accounts
    }

    func archive(_ account: Account) {
        try? engine.setArchived(account, archived: true)
    }

    func unarchive(_ account: Account) {
        try? engine.setArchived(account, archived: false)
    }

    func delete(_ account: Account) {
        try? engine.deleteAccount(account)
    }
}
