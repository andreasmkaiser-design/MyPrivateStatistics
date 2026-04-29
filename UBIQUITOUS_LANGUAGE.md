# Ubiquitous Language

> Terms are defined in English (the language of the codebase). German equivalents are noted in parentheses where relevant.

---

## Core Domain: Events & Categories

| Term | German | Definition | Aliases to avoid |
|---|---|---|---|
| **Event** | Ereignis | A single occurrence recorded by the user, belonging to exactly one Category, anchored to a Time Point or Time Range | Entry, Record, Log, Incident |
| **Category** | Kategorie | A user-defined classification that groups Events of the same kind; carries a Schema and a Time Model | Type, Tag, Group |
| **Subcategory** | Subkategorie | A Category that has a parent Category; inherits the parent's Schema and extends it | Child category, nested category |
| **Category Hierarchy** | Kategoriehierarchie | The tree of Categories and Subcategories, max 5 levels deep, stored as an adjacency list | Category tree |
| **Root Category** | — | A Category with no parent; sits at the top of the hierarchy | Top-level category |
| **Schema** | Schema | The ordered set of Fields defined on a Category; inherited by all Subcategories | Template (when used for field structure), Form |
| **Field** | Feld | A single typed data attribute within a Schema, with an optional constraint | Attribute, Property, Column |
| **Field Type** | Feldtyp | The data type of a Field: `integer`, `float`, `boolean`, or `enum` | Data type |
| **Constraint** | Schranke | An optional min/max bound applied to numeric Fields (`integer`, `float`) | Validation, Range, Limit |
| **Schema Inheritance** | Schema-Vererbung | The rule that a Subcategory automatically receives all Fields of its parent and may add new ones, but never remove or override inherited Fields | Field propagation |

---

## Core Domain: Time

| Term | German | Definition | Aliases to avoid |
|---|---|---|---|
| **Time Model** | Zeitmodell | The time structure configured on a Category; determines whether Events in this Category use a Time Point or a Time Range | Time type |
| **Time Point** | Zeitpunkt | A moment in time consisting of a date and an optional clock time | Timestamp, Instant, Moment |
| **Time Range** | Zeitraum | A duration with a start and an end; either day-precise or datetime-precise | Period, Interval, Duration, Span |
| **Day-Precise Range** | tagesgenaue Zeitraum | A Time Range where start and end are dates only (no clock time) | Date range |
| **Datetime-Precise Range** | Zeitraum mit Uhrzeit | A Time Range where start and end each include a date and a clock time | — |

---

## Core Domain: Statistical Analysis

| Term | German | Definition | Aliases to avoid |
|---|---|---|---|
| **Analysis** | Analyse | A configured statistical computation run against Events within a selected Analysis Window | Report, Calculation, Query |
| **Analysis Window** | Analysezeitraum | The user-selected date range over which an Analysis is computed (e.g. last 60 days) | Time frame, Period |
| **Correlation** | Korrelation | A measured statistical relationship between two Categories, expressed as one of the defined Correlation Types | Association, Link, Dependency |
| **Correlation Type** | Korrelationstyp | One of the five defined kinds of statistical relationship: Temporal Proximity, Co-Occurrence, Frequency Correlation, Frequency Trend, Numeric Correlation | Correlation mode |
| **Temporal Proximity** | Zeitliche Nähe | Correlation Type B: how often Event of Category B follows an Event of Category A within X hours/days | Lag correlation (different concept — see below) |
| **Co-Occurrence** | Co-Occurrence | Correlation Type E: Categories A and B appear on the same day more often than chance would predict | Coincidence |
| **Frequency Correlation** | Häufigkeits-Korrelation | Correlation Type A (V2): Category A occurs more often when Category B preceded it | — |
| **Frequency Trend** | Frequenz-Trend | Correlation Type C (V2): a Category occurs more often on certain days of the week or times of year | Pattern |
| **Numeric Correlation** | Numerische Korrelation | Correlation Type D (V2): a numeric Field value in Category A correlates with a numeric Field value in Category B | — |
| **Correlation Strength** | Korrelationsstärke | A computed score ranking how strongly two Categories are correlated; used to sort the Analysis results | Score, Weight |
| **Analysis Pair** | Analysepaar | A manually saved pair of Categories for which a fixed Correlation is persisted (V2 feature) | Saved analysis |

---

## Core Domain: External Data

| Term | German | Definition | Aliases to avoid |
|---|---|---|---|
| **Health Record** | Health-Datenpunkt | A single data record imported from Health Connect (e.g. step count, activity) and mirrored locally | Health data, Health event |
| **Sync** | Sync | The process of reading new Health Records from Health Connect and writing them into the local database | Import, Fetch |
| **Sync Schedule** | Sync-Zeitplan | The user-configured daily time at which an automatic Sync is triggered via WorkManager | — |

---

## Core Domain: Templates & Portability

| Term | German | Definition | Aliases to avoid |
|---|---|---|---|
| **Template** | Vorlage | An exportable JSON representation of a Category Hierarchy including Schemas and Field definitions, but excluding Events | Export, Backup (Backup includes event data — see below) |
| **UID** | UID | The permanent unique identifier assigned to a Category within this app installation | ID, Key |
| **Source UID** | source_uid | The UID a Category carried in the app instance it was exported from; preserved on import for future update tracking | Original ID, Foreign ID |
| **Backup** | Backup | A full export of the local SQLite database including all Events; distinct from a Template | Export (when used to mean full data export) |

---

## Relationships

- An **Event** belongs to exactly one **Category**.
- A **Category** has exactly one **Schema**; a **Subcategory** extends its parent's **Schema**.
- A **Schema** contains zero or more **Fields**; each **Field** has exactly one **Field Type** and an optional **Constraint**.
- A **Category** has exactly one **Time Model**; all **Events** in that **Category** conform to it.
- An **Analysis** targets one **Source Category** and is computed against all other **Categories** within a chosen **Analysis Window**.
- A **Correlation** is the result of an **Analysis** for a specific pair of **Categories** and a specific **Correlation Type**.
- A **Health Record** is stored locally like an **Event** but originates from an external **Sync** rather than user input.
- A **Template** captures a **Category Hierarchy** (structure only); a **Backup** captures the full database (structure + **Events**).

---

## Example Dialogue

> **Dev:** "When a user taps a day in the calendar, what exactly gets created?"
>
> **Domain expert:** "An **Event**. The user picks a **Category**, fills in the **Fields** defined by that **Category**'s **Schema**, and sets a **Time Point** or **Time Range** — whichever the **Category**'s **Time Model** requires."
>
> **Dev:** "If the **Category** is 'Running' under 'Sport', does the user also see the 'Sport' **Fields**?"
>
> **Domain expert:** "Yes — **Schema Inheritance** means 'Running' shows all **Fields** from 'Sport' first, then its own additions. The user can't see where the boundary is."
>
> **Dev:** "And when I run the **Analysis** for 'Headache', what is the **Analysis Window**?"
>
> **Domain expert:** "Whatever the user selected — e.g. last 60 days. The **Analysis** computes **Co-Occurrence** and **Temporal Proximity** for 'Headache' against every other **Category** that has **Events** in that **Analysis Window**, then ranks them by **Correlation Strength**."
>
> **Dev:** "Is a **Health Record** treated the same as an **Event** in the **Analysis**?"
>
> **Domain expert:** "Effectively yes — after a **Sync**, **Health Records** live in the local database and the **Analysis** engine queries them the same way it queries user-created **Events**."

---

## Flagged Ambiguities

- **"Template" vs "Export"** — "Export" was used loosely in conversation to mean both a **Template** (structure only, for sharing) and a **Backup** (full data export). These are distinct operations. Use **Template** for category structure sharing, **Backup** for full data export.
- **"Correlation" vs "Analysis"** — "Correlation" sometimes referred to the computation process, sometimes to the result. Use **Analysis** for the configured computation and **Correlation** only for the measured relationship that results from it.
- **"Zeitraum" used for both Analysis Window and Time Range** — in German "Zeitraum" covers both concepts. In code and UI strings, use **Analysis Window** (`analysisWindow`) for the date range selected by the user in the statistics view, and **Time Range** (`timeRange`) for the event-level time model.
- **"Event" vs "Ereignis"** — both appear in conversation. The codebase uses `Event`; UI strings in German use `Ereignis`. Never use `Ereignis` in code identifiers.
- **"Schema" vs "Vorlage (Template)"** — "Vorlage" was occasionally used to mean the Field structure of a Category. Reserve **Template** exclusively for the exportable JSON artifact. The Field structure of a Category is its **Schema**.
