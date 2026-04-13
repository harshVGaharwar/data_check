# Data Check — Data Orchestration Pipeline Builder

A full-stack application for building and managing data pipeline templates. The frontend is a **Flutter** visual canvas editor; the backend is a lightweight **Dart Frog** REST API.

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Backend](#backend)
  - [Frontend](#frontend)
- [API Reference](#api-reference)
- [Key Features](#key-features)
- [Configuration](#configuration)
- [Development Notes](#development-notes)
- [Class Reference](#class-reference)
  - [Models](#models)
  - [Providers](#providers)
  - [Services](#services)
  - [Controllers](#controllers)
  - [Pages](#pages)
  - [Widgets](#widgets)
  - [Utilities & Theme](#utilities--theme)

---

## Overview

Data Check lets users:

- **Create templates** — define data extraction requirements (department, frequency, volume, approval workflow, output format)
- **Build pipelines visually** — drag source nodes onto a canvas, configure them, then wire them to Join Operation nodes via port connections
- **Configure join mappings** — specify left/inner/right join types, column mappings, and transformation operations
- **Submit configurations** — send the finalized pipeline spec to the backend (and optionally the upstream DataLake API)

The application is designed for data operations teams that need to orchestrate data from multiple sources (databases, manual uploads, Finacle Core, Laser Banking) into consolidated output files.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend UI | Flutter (Dart 3.9.2+) |
| State Management | Provider 6.1.0 |
| HTTP Client (frontend) | Dio 5.7.0 |
| File Uploads | file_picker 6.1.1 |
| Secure Storage | flutter_secure_storage 9.2.2 |
| Backend Framework | Dart Frog 1.1.0 |
| ID Generation | uuid 4.2.1 |
| Crypto | crypto 3.0.3 |
| HTTP Client (backend) | http 1.2.0 |

---

## Project Structure

```
data_check/
├── frontend/                   # Flutter application
│   ├── lib/
│   │   ├── main.dart           # App entry point
│   │   ├── config/
│   │   │   └── api_config.dart # Base URL and endpoint constants
│   │   ├── models/             # Data models (PipelineNode, Template, User, …)
│   │   ├── controllers/        # PipelineController — canvas state
│   │   ├── providers/          # AuthProvider, TemplateProvider
│   │   ├── services/           # API, Auth, Template, Pipeline, MasterData, Storage
│   │   ├── pages/              # Login, Dashboard, Template Creation, Config Upload
│   │   ├── widgets/            # Canvas, nodes (source/join/output), sidebar, panels
│   │   ├── utils/              # JoinEngine — local data transformation logic
│   │   └── theme/              # AppColors, AppTheme
│   ├── assets/                 # Images (logo, icons)
│   ├── test_files/             # Sample CSV / Excel test data
│   └── pubspec.yaml
│
└── backend/                    # Dart Frog REST API
    ├── lib/
    │   ├── config/
    │   │   └── api_config.dart # Upstream API endpoints
    │   ├── models/
    │   │   └── models.dart     # Shared data models
    │   ├── services/
    │   │   ├── database.dart   # In-memory singleton store
    │   │   └── auth_service.dart
    │   └── middleware/
    │       └── middleware.dart # Token authentication
    ├── routes/
    │   └── api/v1/
    │       ├── auth/           # login, logout
    │       ├── master/         # departments, templates, source-type, operations, approval-list
    │       ├── templates/      # CRUD
    │       └── pipeline/       # save-sources, submit-mapping
    └── pubspec.yaml
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x+)
- [Dart SDK](https://dart.dev/get-dart) (3.9.2+)
- [Dart Frog CLI](https://dartfrog.vgv.dev/docs/overview#installation)

```bash
dart pub global activate dart_frog_cli
```

### Backend

```bash
cd backend

# Install dependencies
dart pub get

# Start development server (hot reload on :8080)
dart_frog dev
```

The server starts at `http://localhost:8080`. The in-memory database is seeded automatically with departments, source types, and development users.

**Development credentials:**

| Username | Password |
|---|---|
| admin | admin123 |
| harsh | harsh123 |
| demo | demo123 |

### Frontend

```bash
cd frontend

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run

# Run in Chrome
flutter run -d chrome
```

Make sure the backend is running before launching the frontend. The frontend points to `http://localhost:8080/api/v1` by default (see [Configuration](#configuration)).

---

## API Reference

All endpoints are prefixed with `/api/v1`. Protected routes require an `Authorization: Bearer <token>` header obtained from the login endpoint.

### Auth

| Method | Path | Description |
|---|---|---|
| POST | `/auth/login` | Authenticate user, returns JWT token |
| POST | `/auth/logout` | Invalidate session token |

### Master Data

| Method | Path | Description |
|---|---|---|
| GET | `/master/departments` | List all departments |
| GET | `/master/templates` | Available template definitions |
| GET | `/master/source-type` | Supported data source types |
| GET | `/master/operations` | Supported join/filter operations |
| GET | `/master/approval-list` | Approval workflow options |

### Templates

| Method | Path | Description |
|---|---|---|
| POST | `/templates` | Create a new template (multipart: JSON + files) |
| GET | `/templates` | List all templates |
| GET | `/templates/:id` | Get a single template by ID |

### Pipeline

| Method | Path | Description |
|---|---|---|
| POST | `/pipeline/save-sources` | Save configured source nodes |
| POST | `/pipeline/submit-mapping` | Submit join mappings and finalize pipeline |

**Standard response envelope:**

```json
{
  "status": "success",
  "message": "...",
  "data": { }
}
```

---

## Key Features

### Visual Pipeline Canvas

- Drag source nodes (Database, Manual Upload, Finacle Core, Laser Banking) from the sidebar onto an infinite zoomable/pannable canvas
- Configure each source node via the right-side config panel
- Once a source node is confirmed and a Join Operation node is on the canvas, the blue OUT port pulses to guide the user to click it and draw a connection
- Connect source nodes to a Join Operation node by clicking the pulsing blue OUT port, then tapping the green IN port on the join node
- Connections are rendered as bezier curves; clicking a curve shows a disconnect handle

### Join Operation Node

- Supports LEFT JOIN, INNER JOIN, and RIGHT JOIN
- Inline column mapping rows — select columns from each connected source and an operation (=, !=, >, <, etc.)

### Template Creation

- Multi-step form: name, department, frequency, data volume, expected benefit, SPOC assignment, approval workflow, output format (CSV / Excel / JSON)
- File attachments (column definition file, query file) per source

### Configuration Upload

- Upload a pre-built pipeline configuration file directly (multipart form-data)

---

## Configuration

### Frontend — `frontend/lib/config/api_config.dart`

```dart
static const String baseUrl = 'http://localhost:8080/api/v1';
```

Change `baseUrl` to point to a remote backend or the upstream DataLake API when deploying.

### Backend — `backend/lib/config/api_config.dart`

Contains the upstream external API base URL and individual endpoint paths. When the base URL is the default placeholder, the backend runs in **dev mode** and serves data from the in-memory store instead of proxying to the external API.

### No `.env` files

All configuration is currently inline in the `api_config.dart` files in each sub-project. Extract these to environment variables before production deployment.

---

## Development Notes

- **In-memory database** — all data is lost on server restart. The `database.dart` singleton is intentionally simple; replace with a real database for production.
- **Auth** — tokens are validated against an in-memory map. Production deployments should use proper JWT signing and a persistent session store.
- **Dev mode** — the backend detects the placeholder base URL and bypasses external API calls, returning mock data. Swap in the real base URL to enable live integration.
- **Canvas port overlay** — port dots are rendered outside the `InteractiveViewer` in screen space so tap targets are always accurate regardless of canvas zoom/pan level.
- **JoinEngine** — client-side join/filter logic in `utils/join_engine.dart` is used for local preview before submitting to the backend.

---

## Class Reference

A complete reference for every frontend class — what it owns, and what each method does.

---

### Models

#### `LoginRequest` · `models/login_request.dart`
Builds the JSON payload sent to the login endpoint. Holds every field the DataLake API expects (employee code, location, IP address, etc.). `toJson()` serialises the object into the exact map the API requires.

#### `LoginUser` · `models/login_response.dart`
Represents the authenticated user returned after a successful login. All fields are read-only. `LoginUser.fromJson()` constructs the object from the raw API map.

#### `LoginResponse` · `models/login_response.dart`
Wraps the full login response — `token`, `refreshToken`, and a nested `LoginUser`. `LoginResponse.fromJson()` is the only constructor; used by `StorageService` to restore sessions.

#### `ApiResponse<T>` · `models/api_response.dart`
Generic envelope for every API call. Carries `success`, `message`, `statusCode`, and a typed `data` payload. `ApiResponse.fromJson()` accepts a custom parser function for `T`. `ApiResponse.error()` is a convenience factory for error states.

#### `SubmitMappingResponse` · `models/api_response.dart`
Typed `data` payload returned from `POST /pipeline/submit-mapping`. Contains `templateId` and `configId` assigned by the backend.

#### `CreateTemplateResponse` · `models/api_response.dart`
Typed `data` payload from `POST /templates`. Carries the `reqId` string issued by the backend for the new template request.

#### `TemplateListItem` · `models/api_response.dart`
Represents one row in a template listing. `fromJson()` is flexible — it accepts both `id`/`templateId` and `name`/`templateName` field names to handle minor API variations.

#### `DepartmentItem` · `models/master_models.dart`
A single department record with `id` and `name`. Populated from `GET /master/departments` and used to fill the department dropdown in the sidebar and template form.

#### `ApprovalItem` · `models/master_models.dart`
One approval-workflow option (e.g. "Unit Head", "Manager"). `listFromJson()` parses an array of strings into a typed list for the multi-select approval checklist.

#### `SourceTypeItem` · `models/master_models.dart`
A data-source system entry (Database, Finacle Core, Laser Banking, etc.). `id` maps to the backend's source type ID; `sourceValue` is the code sent to the API; `sourceName` is the display label.

#### `OperationItem` · `models/master_models.dart`
One comparison operator for join conditions (=, !=, >, <, >=, <=, contains, starts with). `operationValue` is sent in the API payload; `operationName` is the label shown in dropdowns.

#### `TemplateInfo` · `models/template_info.dart`
Rich template record fetched from `GET /master/templates`. Includes metrics (volume, source count, output count), benefit info, priority, and output formats. Used in the sidebar template list.

#### `TemplateRequest` · `models/template_request.dart`
Form state model for the full template-creation workflow. Holds every field across all tabs: basic info, output formats, approval selections, SPOC names, and approval file bytes. Key validation getters (`isGeneralInfoValid`, `isOutputFormatValid`, `isApprovalValid`, `isFileUploaded`, `isComplete`) gate tab-by-tab progression. `toJson()` serialises to the multipart form field. `reset()` clears all fields for a fresh form.

#### `PipelineConfig` · `models/pipeline_config.dart`
A static configuration map — department-to-template lists, required source counts per template, join type labels, and hard-coded demo source/data sets used during development. No instances; all access is via static maps.

#### `DragNodeData` · `models/pipeline_models.dart`
The drag payload carried when a user drags a node type from the sidebar onto the canvas. Contains `type`, `sourceValue`, `sourceName`, and `sourceTypeId` — everything `PipelineController.addNode()` needs to create the node.

#### `ColumnMapping` · `models/pipeline_models.dart`
One row in a join condition: left source + column, right source + column, join type, and comparison operator. `isValid` returns true when all four fields are filled. `toJson()` serialises for the API submit-mapping payload.

#### `OutputFilter` · `models/pipeline_models.dart`
A WHERE-clause filter applied to output rows. `matches()` evaluates a single data row against `column`, `operator`, and `value`. Used by `JoinEngine` and `PipelineController.getOutputResult()` for local preview.

#### `OutputSort` · `models/pipeline_models.dart`
An ORDER-BY rule: column name and ascending/descending flag. `isValid` checks that a column is selected. Applied as a Dart comparator in the output result logic.

#### `PipelineNode` · `models/pipeline_models.dart`
The central canvas entity. Every node on the canvas — source, join, or output — is a `PipelineNode`. Key groups of fields:
- **Identity:** `id`, `type` (enum), `name`, `position`
- **Source data:** `cols`, `selectedCols`, `rows`, `fileName`, `separator`, `columnFileBytes`, `queryFileBytes`
- **Source type:** `sourceTypeValue`, `sourceTypeId`, `sourceTypeName`
- **Join:** `mappings`, `leftSrcId`, `rightSrcId`, `joinType`
- **Output:** `outputFormat`, `outputSelectedCols`, `columnAliases`, `filters`, `sortRules`
- **State:** `confirmState` (notConfigured / confirmed / editing), `sourceId`
Computed getters `nodeWidth`, `nodeHeight`, `outPortCenter`, and `inPortCenter` drive layout and port-dot positioning.

#### `PipelineEdge` · `models/pipeline_models.dart`
A directed connection between two nodes. Carries `id`, `fromNodeId`, and `toNodeId`. The `EdgePainter` reads these to draw bezier curves; `PipelineController` enforces source → join direction when adding edges.

---

### Providers

#### `AuthProvider` · `providers/auth_provider.dart`
ChangeNotifier that owns the authentication session. On startup it calls `_tryAutoLogin()` to restore tokens from `StorageService`. `login()` delegates to `AuthService`, stores the result, and notifies listeners. `logout()` clears storage and resets state. Exposes `isLoggedIn`, `user`, `loading`, and `error` for the UI.

#### `TemplateProvider` · `providers/template_provider.dart`
ChangeNotifier for the template-creation form. `saveTemplate()` calls `TemplateService.createTemplate()`, sets `_loading`, and surfaces `_successMessage` or `_error` on completion. `clearMessages()` resets transient feedback so the form can be resubmitted.

#### `PipelineMasterProvider` · `providers/pipeline_master_provider.dart`
ChangeNotifier that loads and caches master-data lists needed by the canvas config panel. On construction it fires parallel requests for source types and operations. `operatorValues` returns a plain string list; `operatorLabel()` maps a value string back to its display name for dropdowns.

---

### Services

#### `ApiService` · `services/api_service.dart`
Core HTTP layer built on Dio. Manages the auth token, adds `Authorization` headers via an interceptor, and handles 401 responses by queueing retries until a token refresh completes (`_performTokenRefresh()`). Public methods `get<T>()`, `post<T>()`, `postMultipart<T>()`, and `uploadMultipart<T>()` all return typed `ApiResponse<T>`. `getRawData()` / `postRawData()` skip typing for endpoints with irregular shapes. `configure()` wires in the refresh function and logout callback after app startup.

#### `AuthService` · `services/auth_service.dart`
Thin wrapper over `ApiService` for the two auth endpoints. `login()` posts credentials and returns a typed `LoginResponse`. `logout()` posts the invalidation request. `setToken()` pushes the current token into `ApiService` so subsequent calls are authenticated. The `isLoggedIn` getter checks whether a token is present.

#### `StorageService` · `services/storage_service.dart`
Wraps `FlutterSecureStorage` for encrypted on-device persistence. `saveSession()` stores the token and user JSON. `loadSession()` reconstitutes a full `LoginResponse`. `clearSession()` wipes all auth keys. `savePageIndex()` / `loadPageIndex()` persist which dashboard tab was last open.

#### `TemplateService` · `services/template_service.dart`
Covers template CRUD. `createTemplate()` builds a multipart form request — it serialises the `TemplateRequest` JSON into one field and attaches each approval file as a named file part. `getTemplates()` returns a typed list. `getTemplateById()` fetches a single `TemplateInfo`.

#### `PipelineService` · `services/pipeline_service.dart`
Submits pipeline configurations. `submitMapping()` sends the join configuration as multipart (JSON body + per-source column CSV files). `saveSourceConfig()` posts just the source list without files. `submitDataFormat()` sends the output-format selection as a separate call.

#### `MasterDataService` · `services/master_data_service.dart`
Fetches all dropdown reference data. `getDepartments()` returns a list of `DepartmentItem`. `getDepartmentMap()` returns a `Map<int, String>` keyed by ID. `getTemplatesByDept()` returns `TemplateInfo` objects for a given department. `getSourceTypes()`, `getOperations()`, and `getApprovalList()` power sidebar and form dropdowns.

---

### Controllers

#### `PipelineController` · `controllers/pipeline_controller.dart`
The single source of truth for everything on the canvas. Extends `ChangeNotifier`. Responsibilities:

| Group | Methods |
|---|---|
| Node lifecycle | `addNode()`, `deleteNode()`, `clearCanvas()`, `moveNode()`, `selectNode()` |
| Edge lifecycle | `addEdge()`, `removeEdge()`, `selectEdge()`, `deselectAll()` |
| Querying | `findNode()`, `findEdge()`, `sourceNodesOnCanvas`, `canAddSource`, `allSourceNodesConfirmed` |
| Sidebar state | `setSidebarDept()`, `setSidebarTemplate()` |
| Port drag | `startPortDrag()`, `updatePortDrag()`, `endPortDrag()`, `cancelPortDrag()` |
| Join mappings | `addMappingToJoin()`, `removeMappingFromJoin()`, `_syncJoinSources()` |
| Data loading | `initFromSources()`, `updateSingleSource()`, `seedDemoData()` |
| Node config | `setNodeColumns()`, `toggleColumn()`, `updateNodeName()`, `updateNodeSourceType()`, `setQueryFile()` |
| Output config | `setOutputFormat()`, `toggleOutputColumn()`, `setColumnAlias()` |
| Filters | `addOutputFilter()`, `updateOutputFilter()`, `removeOutputFilter()` |
| Sorting | `addOutputSort()`, `updateOutputSort()`, `removeOutputSort()` |
| Execution | `getNodeRows()`, `getOutputResult()`, `diagnoseOutputIssue()` |

`getNodeRows()` is recursive — for a join node it resolves both sides, runs `JoinEngine.execute()`, and returns the merged rows. `getOutputResult()` applies column selection, aliasing, filtering, and sorting to produce the final preview table.

---

### Pages

#### `LoginPage` · `pages/login_page.dart`
StatefulWidget. Renders the login card with username/password fields and the HDFC logo. `_submit()` validates non-empty inputs, calls `AuthProvider.login()`, and navigates to the dashboard on success or displays the error inline.

#### `DashboardPage` · `pages/dashboard_page.dart`
StatefulWidget. The main shell after login. Hosts a navigation drawer and switches between three child pages: Template Creation, Template Configuration, and Configuration Upload. `_restorePageIndex()` reloads the last-visited tab from `StorageService` on mount. `_buildDrawer()` / `_drawerItem()` build the side navigation.

#### `TemplateCreationPage` · `pages/template_creation_page.dart`
StatefulWidget with `TickerProviderStateMixin`. Multi-tab form for creating templates. Loads departments from `MasterDataService` on mount. Uses a shake animation (`_shakeCtrl`) to signal validation errors. Holds the live `TemplateRequest` model and all text controllers. Approval files are stored as `Uint8List` in `_approvalFileBytes`.

#### `TemplateConfigurationPage` · `pages/template_configuration_page.dart`
StatelessWidget. A thin composition layer that wraps `PipelineCanvasPage` with a `MultiProvider` — injecting `PipelineController` and `PipelineMasterProvider` so all child widgets have access to canvas state and master data.

#### `ConfigurationUploadPage` · `pages/configuration_upload_page.dart`
StatelessWidget. Placeholder screen for uploading a pre-built configuration file. Renders an icon, description text, and an upload button.

---

### Widgets

#### `PipelineCanvasPage` · `widgets/pipeline_canvas_page.dart`
StatefulWidget with `TickerProviderStateMixin`. The outermost canvas layout widget. Manages the `TransformationController` for pan/zoom and a `_pulseCtrl` animation for the port glow hint. `_buildCanvas()` creates a `DragTarget` → `InteractiveViewer` stack with the grid painter, edge painter, and node widgets inside. Port dots are rendered in a separate `AnimatedBuilder` outside the viewer so screen-space tap targets stay accurate at any zoom level. `_buildPortOverlay()` decides per-node whether the blue OUT dot should pulse (confirmed source + join node exists + not yet connected).

#### `TopBar` · `widgets/top_bar.dart`
StatelessWidget. Fixed header with the app logo, "DataFlow Builder" title, and a "Clear Canvas" button that calls `PipelineController.clearCanvas()`.

#### `Sidebar` · `widgets/sidebar.dart`
StatefulWidget with `TickerProviderStateMixin`. Left panel for pipeline configuration. Loads the department → template map from `MasterDataService` on mount. Displays department and template dropdowns with pulse animations to guide the user through the setup steps. `_buildDragNode()` renders each draggable source type chip — wrapping it in a `Draggable<DragNodeData>` with a styled drag avatar.

#### `ConfigPanel` · `widgets/config_panel.dart`
StatelessWidget. Right-side detail panel for the currently selected node. `_buildConfig()` switches on `node.type` to render the appropriate controls: column CSV upload and selection for source nodes, join type and mapping editor for join nodes, and output column/alias/filter/sort controls for the output node.

#### `SourcePreviewSidebar` · `widgets/source_preview_sidebar.dart`
StatelessWidget. Far-right summary panel showing all source nodes, their row/column counts, and whether they are fully configured. Visible only when at least one source has been confirmed.

#### `StatusBar` · `widgets/status_bar.dart`
StatelessWidget. Bottom strip displaying node count, edge count, and an overall pipeline readiness indicator. Uses small colored dots (`_dot()`) to signal status at a glance.

#### `EdgePainter` · `widgets/edge_painter.dart`
`CustomPainter`. Draws bezier curves between connected nodes. Each curve is color-coded by join type (blue for source edges, violet variants for join types). Renders a glow shadow under each curve and a circular disconnect button at the midpoint. `hitTestEdge()` and `hitTestDisconnect()` provide point-in-path and point-in-circle hit detection for tap handling in the canvas gesture detector.

#### `SourceNodeBody` · `widgets/nodes/source_node_body.dart`
StatelessWidget. Card body for source nodes. Renders the source type icon, node name, a column-count badge, and a row-count stat. Layout helpers `_sourceNameRow()` and `_statBadgeRow()` keep the card compact.

#### `JoinNodeBody` · `widgets/nodes/join_node_body.dart`
StatelessWidget. Card body for join nodes. Shows the connected source badges, a join-type selector (LEFT / INNER / RIGHT), and an editable list of `ColumnMapping` rows. Each mapping row has source/column dropdowns and an operator picker. Rows can be added or removed inline.

#### `OutputNodeBody` · `widgets/nodes/output_node_body.dart`
StatelessWidget. Card body for the output node. Displays output format selection, a column checklist with alias text fields, filter rows (column / operator / value), and sort rules. Also shows a live preview table of the joined result via `PipelineController.getOutputResult()`. Falls back to `_fallbackOperators` if master-data operators have not loaded yet.

---

### Utilities & Theme

#### `JoinEngine` · `utils/join_engine.dart`
Pure utility class (no state). `execute()` is a static method that takes two row-sets, a list of `ColumnMapping` conditions, and a join type string, and returns the merged rows. Supports INNER, LEFT, RIGHT, FULL OUTER, and CROSS joins. The inner `matches()` closure checks all mapping conditions for a given row pair using the `operationValue` string (=, !=, >, <, >=, <=, contains, startsWith).

#### `AppColors` / `AppTextStyles` · `theme/app_theme.dart`
Static constant classes. `AppColors` defines the full color palette: `bg` (canvas background), `surface` (card background), `border`, `blue`, `green`, `amber`, `violet`, `text`, `textDim`, `textMuted`. `AppTextStyles` defines `TextStyle` constants used across all node cards, panels, and the status bar.

#### `ApiConfig` · `config/api_config.dart`
Static constant class. Holds `baseUrl` and every named endpoint path string (login, logout, templates, departments, sourceTypes, operations, pipelineSubmitMapping, etc.). All services reference these constants so URL changes are made in one place.

