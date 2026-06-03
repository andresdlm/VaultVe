# VaultVE

App iOS de contabilidad personal para usuarios venezolanos que cobran en USD y gastan en bolívares. Rastrea el costo real en USD de cada gasto en VES atravesando la cadena completa de conversiones **USD → USDT → VES**, lote por lote, con asignación FIFO.

> **Aviso legal:** Este software se distribuye tal cual, sin garantías de ningún tipo. No constituye asesoría financiera ni contable. El uso es responsabilidad exclusiva de quien lo emplee. Ver `LICENSE`.

---

## El problema que resuelve

Cuando manejas cuentas en USD pero vives en Venezuela, el camino del dinero es:

1. **USD** entran al banco (salario, freelance, etc.)
2. Compras **USDT** por P2P — cada compra tiene una tasa y una comisión distinta.
3. Vendes **USDT por VES** por partes, en distintos días y a distintas tasas P2P.
4. Pagas en **VES**.

El problema: cuando vas a la panadería y gastas Bs 830, **¿cuántos USD de tu sueldo te costó realmente esa transacción?** La respuesta depende de qué lote de VES estabas usando, qué USDT lo alimentó y a qué tasa habías comprado esos USDT semanas antes.

VaultVE registra cada paso, asigna inventario FIFO de forma automática y permite ver el **árbol de trazabilidad completo** de cualquier gasto hasta el USD original.

---

## Funcionalidades

- **Registro de transacciones** con formularios dedicados:
  - Ingreso de USD (depósitos al banco)
  - Compra de USDT (USD → USDT) con captura de comisión
  - Venta de USDT (USDT → VES) con preview FIFO en vivo del inventario que se va a consumir
  - Gasto en VES con preview del costo real en USD antes de confirmar
- **Trazabilidad multi-leg**: un gasto puede haberse pagado desde varios lotes de VES, cada uno alimentado por varios lotes de USDT — la app muestra todas las ramas y el costo prorrateado.
- **Tasas BCV y paralela** editables desde Config; comparación de cada gasto contra la paralela del día.
- **Dashboard con tres layouts**: Consola apilada, Pipeline visual de cadena, Ledger tabular.
- **Persistencia local con SwiftData**, opción de respaldo en **iCloud (CloudKit)**.
- **Face ID / Touch ID** para bloquear la app; se re-bloquea automáticamente al pasar a background.
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
├── App/                     # entry point + Face ID gate
├── Models/                  # @Model SwiftData (lots, allocations, gastos, income, rates)
├── Repository/              # VaultRepository — math + FIFO engine
├── Store/                   # VaultEngine — @Observable façade
├── Features/
│   ├── Dashboard/           # 3 layouts + ViewModel
│   ├── Operaciones/         # registro de lotes
│   ├── Gastos/              # árbol de trazabilidad
│   ├── Analytics/           # reportes
│   ├── Config/              # Face ID, iCloud, tasas
│   └── NuevaOperacion/      # formularios de transacciones
├── Components/              # piezas visuales reutilizables
└── DesignSystem/            # tokens de color, fuentes, helpers
```

### Modelo de trazabilidad FIFO

```
USDIncome
   ↓ (resta inventario USD)
USDTLot ──┐
          ├──> USDTAllocation ──┐
USDTLot ──┘                     │
                                ├──> VESLot ──┐
USDTLot ────> USDTAllocation ───┘             │
                                              ├──> VESAllocation ──> Gasto
VESLot ─────> VESAllocation ──────────────────┘
```

- Un `USDTLot` puede alimentar varios `VESLot`.
- Un `VESLot` puede pagar varios `Gasto`.
- Cada `Allocation` congela el costo USD del momento — los cambios futuros de inventario **no** reescriben el costo histórico de gastos pasados.

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

# Tests
xcodebuild -project FinanceApp.xcodeproj \
           -scheme FinanceApp \
           -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
           test
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

Ya está configurado el `INFOPLIST_KEY_NSFaceIDUsageDescription` en el pbxproj. En el simulador, usá **Features → Face ID → Matching Face** para simular la autenticación.

---

## Privacidad

- Toda la información se guarda **localmente** en el dispositivo.
- Si activas iCloud, los datos sincronizan **únicamente** a tu cuenta privada de iCloud (CloudKit `.private`); no se comparten con nadie.
- La app **no** envía datos a ningún servidor externo.
- Las tasas BCV/paralela se ingresan manualmente.

---

## Estado del proyecto

Proyecto personal en desarrollo activo. La estructura está estable, pero las funcionalidades avanzadas (analytics detalladas, importación CSV, integración con APIs de tasa) son trabajo en curso.

Contribuciones, issues y forks bienvenidos.

---

## Licencia

[MIT License](LICENSE) © 2026 Andres Linarez.

El software se entrega **"AS IS"**, sin garantía de ningún tipo. El autor no asume responsabilidad por pérdidas, decisiones financieras, errores de cálculo, ni cualquier consecuencia derivada del uso de este código. Usalo bajo tu propio riesgo.
