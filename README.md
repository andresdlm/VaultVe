# VAULT

App iOS de finanzas personales: trackea tus cuentas en cualquier moneda, registra gastos e ingresos, y mueve dinero entre cuentas — con tasa de cambio explícita cuando las monedas difieren.

> **Aviso legal:** Este software se distribuye tal cual, sin garantías de ningún tipo. No constituye asesoría financiera ni contable. El uso es responsabilidad exclusiva de quien lo emplee. Ver `LICENSE`.

---

## Qué resuelve

Manejar varias cuentas (banco, efectivo, wallets, tarjetas) en distintas monedas se vuelve un dolor cuando querés ver tu patrimonio total o comparar gastos entre meses. VAULT centraliza todo:

- **Múltiples cuentas** con saldo inicial, moneda y tipo (banco, efectivo, wallet, tarjeta, ahorro, inversión).
- **Gastos e ingresos** con comercio, categoría, fecha y nota.
- **Transferencias entre cuentas**, incluyendo cambio de moneda con la tasa que vos especifiques en la operación.
- **Patrimonio total en tu moneda base** (configurable): VAULT convierte cada saldo usando tasas que vos editás manualmente — sin red, sin sorpresas.
- **Reportes**: gasto por categoría, tendencia mensual de 6 meses, top de comercios.

---

## Funcionalidades

- **Cuentas**: crear, editar, archivar y borrar cuentas. La moneda se congela al crear para no romper tus movimientos pasados.
- **Movimientos** unificados: gastos, ingresos y transferencias en una sola lista, con filtros por tipo, fecha, cuenta, categoría y búsqueda libre.
- **Tasas de cambio** editables desde Config (una fila por moneda) — VAULT te avisa cuando una cuenta usa una moneda sin tasa configurada.
- **Categorías** editables para gastos e ingresos, con set por defecto sembrado en el primer arranque.
- **Face ID / Touch ID** para bloquear la app, con re-lock automático al pasar a background.
- **Persistencia local con SwiftData**, respaldo opcional en **iCloud (CloudKit)**.
- **Diseño**: estética High-Tech Brutalism × Terminal-Core (monospace SF Mono, fondo `#080C0E`, acento verde `#00FF88`).

---

## Stack técnico

- **Plataforma:** iOS 26+ (deployment target 26.0)
- **UI:** SwiftUI con efectos liquid glass de iOS 26
- **Lenguaje:** Swift
- **Arquitectura:** MVVM con `@Observable`
- **Persistencia:** SwiftData (local) + CloudKit (opcional)
- **Seguridad:** LocalAuthentication
- **IDE:** Xcode 26.5+

### Estructura

```
FinanceApp/
├── App/                     # entry point + Face ID gate + container
├── Models/                  # @Model SwiftData (Account, Category, Transaction, Transfer, ExchangeRate) + Currency enum
├── Repository/              # VaultRepository — CRUD + agregaciones
├── Store/                   # VaultEngine — @Observable façade
├── Features/
│   ├── Dashboard/           # patrimonio total + lista de cuentas
│   ├── Accounts/            # CRUD de cuentas + detalle
│   ├── Movements/           # listado unificado con filtros
│   ├── Analytics/           # reportes derivados de la data real
│   ├── Config/              # Face ID, iCloud, moneda base, tasas, categorías
│   └── NuevaOperacion/      # forms: gasto, ingreso, transferencia, cuenta
├── Components/              # piezas visuales reutilizables (cards, pickers, badges)
└── DesignSystem/            # tokens de color, fuentes, helpers
```

### Modelo de datos

```
Account (id, name, currency, kind, initialBalance, …)
   ├── transactions   → Transaction (kind: expense/income)
   ├── transfersOut   → Transfer (source)
   └── transfersIn    → Transfer (dest)

Category (id, name, glyph, color, kind: expense/income, isDefault)

Transfer (sourceAccount → destAccount, sourceAmount, destAmount, both currencies)
        ↳ tasa implícita = destAmount / sourceAmount

ExchangeRate (currency, unitsPerBase)
        ↳ una fila por moneda; conversión a la base es saldo / unitsPerBase
```

- El saldo de una cuenta se computa: `initialBalance + Σingresos − Σgastos − Σtransfers_out + Σtransfers_in`.
- Cada transacción y transferencia guarda la moneda al momento del registro, así cambiar la moneda de una cuenta (no permitido en UI) o la base no reescribe el pasado.

---

## Compilar y correr

Requisitos:
- macOS con Xcode 26.5 o superior
- Simulador o dispositivo con iOS 26+

```bash
# Abrir en Xcode
open FinanceApp.xcodeproj

# Build desde línea de comandos
xcodebuild -project FinanceApp.xcodeproj \
           -scheme FinanceApp \
           -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
           build
```

Listar simuladores disponibles: `xcrun simctl list devices available`.

### Activar respaldo en iCloud

Por defecto la app usa almacenamiento local. Para habilitar el sync a CloudKit:

1. En Xcode: target **FinanceApp** → **Signing & Capabilities** → **+ Capability** → **iCloud**.
2. Marca **CloudKit** y agrega un container (ej. `iCloud.com.andresdlm.FinanceApp`).
3. En la app, abrí **Config → ALMACENAMIENTO → RESPALDO iCLOUD** y activa el toggle.
4. Reinicia la app — el `ModelContainer` se reconfigura al arrancar.

Si CloudKit no está habilitado en la cuenta, la app cae automáticamente a modo local sin romper.

### Face ID

El `INFOPLIST_KEY_NSFaceIDUsageDescription` ya está configurado en el pbxproj. En el simulador, usá **Features → Face ID → Matching Face** para simular la autenticación.

---

## Primer uso

1. Abrí la app — empezará vacía con un set de categorías por defecto.
2. Andá a **Cuentas → +** y crea tu primera cuenta (nombre, moneda, saldo inicial).
3. Repetí para cada cuenta que querés trackear.
4. (Opcional) Si manejás más de una moneda, andá a **Config → Tasas de cambio** y poné el equivalente de cada moneda contra tu moneda base.
5. Empezá a registrar movimientos desde el botón **NUEVA OPERACIÓN** del Panel o desde la pestaña Movimientos.

---

## Privacidad

- Toda la información se guarda **localmente** en el dispositivo.
- Si activás iCloud, los datos sincronizan **únicamente** a tu cuenta privada de iCloud (CloudKit `.private`); no se comparten con nadie.
- La app **no** envía datos a ningún servidor externo.
- Las tasas de cambio se ingresan manualmente.

---

## Licencia

[MIT License](LICENSE) © 2026 Andres Linarez.

El software se entrega **"AS IS"**, sin garantía de ningún tipo. El autor no asume responsabilidad por pérdidas, decisiones financieras, errores de cálculo, ni cualquier consecuencia derivada del uso de este código. Usalo bajo tu propio riesgo.
