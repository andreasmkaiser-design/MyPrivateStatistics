# Private Statistics — Design Decisions

## Identität

| | |
|---|---|
| **App-Name** | Private Statistics |
| **GitHub** | MyPrivateStatistics |
| **Package** | `com.akaiser.private_statistics` |
| **Bundle ID** | `com.akaiser.private_statistics` |
| **Lizenz** | GPL v3 |
| **Monetarisierung** | Freemium (Paywall ab V2) |

---

## Technologie-Stack

| Bereich | Entscheidung |
|---|---|
| Framework | Flutter |
| Datenbank | Drift |
| State Management | Riverpod |
| Diagramme | fl_chart |
| Lokalisierung | intl (ARB-Dateien) |
| Hintergrundaufgaben | flutter_workmanager |
| In-App Purchase | in_app_purchase (ab V2) |
| Tests | flutter_test, mocktail, integration_test |
| Pre-commit Hooks | lefthook |
| CI/CD | GitHub Actions |

---

## Plattform

| | |
|---|---|
| **Zielplattform** | Android |
| **Minimum SDK** | Android 10 (API 29) |
| **Target SDK** | Android 15 (API 35) |

---

## Architektur

### Ordnerstruktur
Feature-basiert:
```
lib/
  features/
    events/
      data/          (Drift DAOs, Repositories)
      domain/        (Models, Interfaces)
      presentation/  (Widgets, Riverpod Providers)
    categories/
    statistics/
    health/
  core/              (Datenbankverbindung, Shared Widgets, Theme)
```

### Datenbankmodell (Kategoriehierarchie)
**Adjacency List** — jede Kategorie hat eine `parent_id`. Max. 5 Verschachtelungsebenen. Baum wird in Dart zusammengesetzt, Riverpod cached das Ergebnis.

---

## Kategorien & Schema

### Felddefinitionen
Jede Kategorie definiert ein festes Schema. Folgende Feldtypen werden unterstützt:

| Typ | Beschreibung |
|---|---|
| `integer` | Ganzzahl ohne Einheit, optionale min/max Schranke |
| `float` | Dezimalzahl (1 Nachkommastelle in UI) + Einheit (Freitext), optionale min/max Schranke |
| `boolean` | Ja/Nein |
| `enum` | Auswahl aus konfigurierbaren Freitext-Optionen |

### Schema-Vererbung
Subkategorien **erben alle Felder der Elternkategorie** und können eigene Felder hinzufügen. Elterliche Felder können nicht überschrieben oder entfernt werden.

---

## Ereignisse

### Zeitmodell (pro Kategorie konfiguriert)

| Modus | Format |
|---|---|
| **Zeitpunkt** | Datum + optionale Uhrzeit |
| **Zeitraum (tagesgenau)** | Von-Datum bis Bis-Datum |
| **Zeitraum (mit Uhrzeit)** | Von Datum+Uhrzeit bis Datum+Uhrzeit |

---

## Statistische Analyse

### Unterstützte Korrelationstypen

| ID | Name | Version |
|---|---|---|
| A | Häufigkeits-Korrelation — "Tritt A häufiger auf wenn B vorher auftrat?" | V2 |
| B | Zeitliche Nähe — "Wie oft folgt B innerhalb von X Stunden/Tagen auf A?" | **V1** |
| C | Frequenz-Trends — "A tritt montags häufiger auf als freitags" | V2 |
| D | Numerische Korrelation — "Mehr Schritte → weniger Kopfschmerzen?" | V2 |
| E | Co-Occurrence — "A und B treten am selben Tag überdurchschnittlich oft auf" | **V1** |

### Konfiguration
- **Halbautomatisch** — Nutzer wählt Ausgangskategorie, App berechnet Ranking gegen alle anderen
- Berechnung **on-demand** beim Aufrufen der Statistik-Ansicht
- **Zeitraum wählbar** (z.B. letzte 60 Tage)
- Zukunft: manuell gespeicherte Kategorie-Paare als fixe Berechnungen

### Visualisierung (V1)
- **KPI-Cards** — Kernaussagen (z.B. "73% Koinzidenz")
- **Balkendiagramm** — Kategorie-Ranking nach Korrelationsstärke
- **Kalenderansicht** — Muster visuell entdecken

Erweiterte Diagrammtypen (Scatter Plot, Heatmap) in V2.

---

## Health Connect Integration

| | |
|---|---|
| **API** | Google Health Connect |
| **Richtung** | Nur lesen (kein Zurückschreiben) |
| **Sync** | Täglich automatisch (Uhrzeit in Einstellungen konfigurierbar) + manuell |
| **Mechanismus** | WorkManager via flutter_workmanager |
| **Datenhaltung** | Lokal in Drift gespiegelt |
| **Version** | V1 |

---

## JSON Export / Import

- **Was:** Nur Kategorie-Struktur + Felddefinitionen (keine Ereignis-Daten) — "Vorlagen"
- **Format:** Flache JSON-Struktur
- **IDs:** UIDs pro Kategorie; beim Import werden **neue UIDs generiert**, die ursprüngliche UID wird in einem `source_uid`-Feld erhalten (für zukünftige Update-Mechanismen)
- **Konfliktbehandlung:** Bei gleichem Namen fragt die App ob beide Versionen behalten oder eine verworfen werden soll

---

## Navigation & UI

- **Navigation:** Bottom Navigation Bar
- **Startbildschirm:** Kalenderansicht (Ereignisse werden über den Kalender erfasst)
- **Tabs (V1):** Kalender / Ereignisse / Statistiken / Kategorien
- **Einstellungen:** Zahnrad-Icon in der AppBar

### Theming
- Material Design 3
- Dark/Light Mode automatisch nach Android-Systemeinstellung (`ThemeMode.system`)
- Manuelle Auswahl in V2

---

## Lokalisierung

- Bibliothek: `intl` + ARB-Dateien
- **V1:** Englisch + Deutsch
- Systemsprache wird automatisch verwendet

---

## Backup

- **Manuelles Backup** — Export der gesamten SQLite-Datei in vom Nutzer gewählten Speicherort (Google Drive, lokaler Speicher)
- Android Auto-Backup als Sicherheitsnetz aktiviert
- Cloud-Sync in V2

---

## Onboarding (Erster App-Start)

1. Kurzer Wizard (2–3 Screens)
2. Konzept-Erklärung
3. Health Connect Permission anfragen
4. Angebot: "Mit Beispielkategorien starten oder leer beginnen?"

---

## Benachrichtigungen

- V1: keine Notifications
- V2: Sync-Fehler-Notification, optionale Erinnerungs-Notification

---

## Testing

### Strategie
Vollständige Test-Pyramide von Anfang an:

| Ebene | Scope | Tool |
|---|---|---|
| Unit Tests | Statistik-Algorithmen, Repositories, Providers | flutter_test, mocktail |
| Widget Tests | Kernkomponenten (Kalender, Kategorie-Baum, KPI-Cards) | flutter_test |
| Integration Tests | End-to-End-Flows | integration_test |

### Pre-commit (lefthook)
- Unit + Widget Tests laufen automatisch vor jedem Commit
- Integration Tests nur in CI

---

## CI/CD (GitHub Actions)

Bei jedem Push:
1. `flutter test` (Unit + Widget Tests)
2. Integration Tests
3. `flutter build apk` + `flutter build appbundle`
4. APK / AAB als Release-Artifact bereitstellen

---

## Freemium-Modell (ab V2)

| | Free | Premium |
|---|---|---|
| Kategorien | max. 10 | unbegrenzt |
| Ereignisse | max. 100/Monat | unbegrenzt |
| Statistiken | Zeitliche Nähe + Co-Occurrence | + alle erweiterten Typen (A, C, D) |
| Diagramme | KPI-Cards, Balken, Kalender | + erweiterte Typen |
| Health Connect | — | ✓ |
| Zahlungsmodell | — | Einmaliger Kauf (in_app_purchase) |

V1: alle Features kostenlos, keine Paywall.

---

## Versionierung

| Version | Schwerpunkt |
|---|---|
| **V1** | Basis-Erfassung, Kategorien, Kalender, Zeitliche Nähe + Co-Occurrence, Health Connect, Export/Import, Onboarding, EN+DE |
| **V2** | Erweiterte Statistiken (A/C/D), erweiterte Diagramme, Freemium/IAP, Lag-Korrelation, gespeicherte Analyse-Paare, Notifications, Cloud-Sync |
