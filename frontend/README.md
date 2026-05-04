# Data Fusion — Frontend

A Flutter-based enterprise data pipeline orchestration and configuration tool built for HDFC Bank's data management workflows.

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Screens & Pages](#screens--pages)
- [State Management](#state-management)
- [Services & API Layer](#services--api-layer)
- [Data Models](#data-models)
- [Widgets](#widgets)
- [Authentication Flow](#authentication-flow)
- [API Endpoints](#api-endpoints)
- [Configuration](#configuration)
- [Running the App](#running-the-app)
- [Dependencies](#dependencies)

---

## Overview

Data Fusion is a Flutter application that enables users to:

- Create and configure data templates with approval workflows
- Build visual node-based data pipelines (drag-and-drop)
- Manage data sources (DB, Manual, QRS, FC, Laser, etc.)
- Upload manual data files per template slot
- Run a QA/checker approval workflow on processed data
- View data processing reports

The app targets both **web** and **mobile** platforms and is backed by a REST API running at `localhost:8080`.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart ^3.9.2) |
| State Management | Provider ^6.1.0 |
| HTTP Client | Dio ^5.7.0 |
| Secure Storage | flutter_secure_storage ^9.2.2 |
| File Picker | file_picker ^6.1.1 |
| Connectivity | connectivity_plus ^6.1.4 |
| Web Support | web ^1.1.1 |

---

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart                       # App entry point, routing, provider setup
│   ├── config/
│   │   └── api_config.dart             # Base URL and all API endpoint constants
│   ├── models/                         # Data classes / serialization
│   │   ├── api_response.dart
│   │   ├── login_request.dart
│   │   ├── login_response.dart
│   │   ├── master_models.dart
│   │   ├── pipeline_config.dart
│   │   ├── pipeline_models.dart
│   │   ├── template_info.dart
│   │   └── template_request.dart
│   ├── services/                       # HTTP & business-logic services
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   ├── master_data_service.dart
│   │   ├── pipeline_service.dart
│   │   ├── storage_service.dart
│   │   └── template_service.dart
│   ├── providers/                      # ChangeNotifier state providers
│   │   ├── auth_provider.dart
│   │   ├── pipeline_master_provider.dart
│   │   └── template_provider.dart
│   ├── pages/                          # Full screens
│   │   ├── login_page.dart
│   │   ├── dashboard_page.dart
│   │   ├── welcome_page.dart
│   │   ├── template_creation_page.dart
│   │   ├── template_configuration_page.dart
│   │   ├── source_configuration_page.dart
│   │   ├── manual_upload_page.dart
│   │   ├── checker_page.dart
│   │   └── report_page.dart
│   ├── widgets/                        # Reusable UI components
│   │   ├── pipeline_canvas_page.dart
│   │   ├── nodes/
│   │   │   ├── source_node_body.dart
│   │   │   ├── join_node_body.dart
│   │   │   └── output_node_body.dart
│   │   ├── config_panel.dart
│   │   ├── source_preview_sidebar.dart
│   │   ├── mapping_preview_dialog.dart
│   │   ├── top_bar.dart
│   │   ├── sidebar.dart
│   │   ├── status_bar.dart
│   │   ├── searchable_dropdown.dart
│   │   ├── shimmer_button.dart
│   │   └── edge_painter.dart
│   ├── theme/                          # App-wide design tokens and colors
│   ├── controllers/                    # Business logic separated from UI
│   └── utils/                         # Helper functions, platform-specific code
├── assets/
│   └── images/                         # HDFC Bank logo and branding assets
├── web/                                # Web platform entry point and config
├── test/                               # Widget / unit tests
└── pubspec.yaml
```

---

## Architecture

The app follows a **Provider + Service** architecture:

```
UI (Pages / Widgets)
        │
        ▼
  Providers (ChangeNotifier)   ←→   Services (business logic / HTTP)
        │                                   │
        │                                   ▼
        └──────────────────────────   ApiService (Dio + token refresh)
                                            │
                                            ▼
                                      REST API (localhost:8080)
```

- **Providers** hold observable state and call Services to fetch/mutate data.
- **Services** are pure Dart classes that talk to the API or local storage.
- **ApiService** is the single HTTP client; all other services call it.
- **StorageService** wraps `FlutterSecureStorage` for token/session persistence.

---

## Screens & Pages

### Navigation Flow

```
LoginPage
    └── DashboardPage
            ├── WelcomePage            (index 0 — home)
            ├── TemplateCreationPage   (index 1)
            ├── TemplateConfigPage     (index 2)
            ├── SourceConfigPage       (index 3)
            ├── ManualUploadPage       (index 4)
            ├── CheckerPage            (index 5)
            └── ReportPage             (index 6)
```

The last visited page index is persisted to secure storage and restored on next app launch.

---

### LoginPage

Standard credential login form. On success the `AuthProvider` stores the JWT + refresh token via `StorageService` and pushes the user to `DashboardPage`.

---

### DashboardPage

Shell page that hosts the sidebar, top bar, status bar, and renders the currently selected page widget. Not a data-fetching page itself.

---

### WelcomePage

Home screen shown after login. Displays the authenticated user's name, department, and employee code. Contains quick-navigation cards to the other features.

---

### TemplateCreationPage

Multi-section form for registering a new data template. Sections:

| Section | Fields |
|---|---|
| Basic Info | Template name, department, frequency, volumes |
| Benefit | Benefit type, amount, TAT |
| SPOC | SPOC person, manager, unit head |
| Scheduling | Priority, go-live date, deactivate date |
| Sources | Multi-select from `SourceMasterList` |
| Output | Output format |
| Approval Files | File picker — one file per approval type |

Submits via multipart form-data to `template/AddTemplate`. On success, returns a `reqId` used by the next step (pipeline configuration).

---

### TemplateConfigurationPage

Visual drag-and-drop pipeline builder. Wraps `PipelineCanvasPage` with its own `PipelineController` and `PipelineMasterProvider`.

Node types available on the canvas:

| Node | Purpose |
|---|---|
| Source | Represents a data source (DB, Manual, QRS, FC, Laser) |
| Join | Joins two source streams with configurable column mappings |
| Output | Final sink / output of the pipeline |

Edges between nodes are drawn with a custom `EdgePainter`. Configuration panels open as sidebars when a node is selected.

---

### SourceConfigurationPage

Form to register a new data source into the source master list. Fields:

- Source Type (DB / Manual / QRS / FC / Laser — searchable dropdown)
- Department (searchable dropdown)
- Source Name, App Name, ITGRC, DB Vault

Calls `MasterDataService.addSourceMaster()`.

---

### ManualUploadPage

Three-step upload flow:

1. Select **Department**
2. Select **Template** (filtered by department)
3. For each slot in the template, pick a file and upload

Each file upload is an independent multipart POST to `template/UploadManualData`.

---

### CheckerPage

QA / approval workflow page. Displays a paginated table (10 rows/page) of checker tasks. Supports:

- Filter by department, template, and request ID
- Download the output file for a task (`template/DownloadFile`)
- Submit approval or rejection with a remarks text field (`template/UploadManualDataChecker`)

---

### ReportPage

Read-only report viewer. Filter by department and template to load processed data metrics and pipeline status from `template/GetReportList`.

---

## State Management

Three `ChangeNotifier` providers registered at the root via `MultiProvider`:

### AuthProvider

```
State:  initialized, loading, error, LoginUser? user
Key methods:
  login(name, password)   → calls AuthService.login(), saves session
  logout()                → calls AuthService.logout(), clears session
  _tryAutoLogin()         → loads stored session on app start
```

### TemplateProvider

```
State:  loading, error, successMessage, reqId
Key methods:
  saveTemplate(TemplateRequest)  → calls TemplateService.createTemplate()
  clearMessages()                → resets error/success state
```

### PipelineMasterProvider

```
State:  sourceTypes[], operations[], loading
Loaded once on init from MasterDataService.
Exposes operatorValues list and operatorLabel(id) helper.
```

---

## Services & API Layer

### ApiService

The base HTTP client (Dio). All other services depend on it.

- Automatically attaches Bearer token to every request
- On **401**: pauses in-flight requests, calls `AuthService.refreshToken()`, retries
- Supports: `get`, `post`, `put`, `delete`, `postMultipart`, `uploadMultipart`, `getFileBytes`
- Guards against offline state via `connectivity_plus`
- Timeouts: 60 s (debug) / 120 s (release)

### AuthService

| Method | Endpoint | Purpose |
|---|---|---|
| `login()` | `POST account/login` | Authenticate user |
| `logout()` | `POST auth/logout` | Invalidate session |
| `refreshToken()` | `POST account/refresh` | Rotate access token |

### StorageService

Wraps `FlutterSecureStorage`. Keys stored:

- `auth_token` — JWT access token
- `auth_refresh_token` — JWT refresh token
- `auth_user` — JSON-encoded `LoginUser`
- Current page navigation index

### MasterDataService

Central service for all dropdown/list data and transactional operations (checker, manual upload, reports).

### TemplateService

Handles `createTemplate()` which sends a multipart request combining form fields and multiple approval files.

### PipelineService

Handles `submitMapping()` which serialises the pipeline node graph and column mappings into a multipart request.

---

## Data Models

| File | Models |
|---|---|
| `api_response.dart` | `ApiResponse<T>`, `CreateTemplateResponse`, `SubmitMappingResponse`, `AddSourceMasterResponse`, `TemplateListItem` |
| `login_request.dart` | `LoginRequest` |
| `login_response.dart` | `LoginUser`, `LoginResponse` |
| `master_models.dart` | `SourceListItem`, `DepartmentItem`, `ApprovalItem`, `SourceTypeItem`, `SourceMasterItem`, `OperationItem` |
| `pipeline_models.dart` | `NodeType` (enum), `NodeConfirmState` (enum), `DragNodeData`, `ColumnMapping` |
| `template_request.dart` | `TemplateRequest` |
| `template_info.dart` | `TemplateInfo`, `ManualTemplateInfo` |
| `pipeline_config.dart` | `PipelineConfig` |

---

## Widgets

| Widget | Purpose |
|---|---|
| `PipelineCanvasPage` | Interactive canvas for building node graphs |
| `SourceNodeBody` | UI for a source node on the canvas |
| `JoinNodeBody` | UI for a join node with column-mapping config |
| `OutputNodeBody` | UI for the output/sink node |
| `ConfigPanel` | Slide-in configuration panel for selected node |
| `SourcePreviewSidebar` | Shows a preview of the selected source's columns |
| `MappingPreviewDialog` | Dialog showing the configured column mappings |
| `TopBar` | App header with user info and actions |
| `Sidebar` | Navigation rail / drawer |
| `StatusBar` | Pipeline status indicator |
| `SearchableDropdown` | Dropdown with in-place text filter and overlay |
| `ShimmerButton` | Animated submit button with loading state |
| `EdgePainter` | `CustomPainter` that draws directed edges between nodes |

---

## Authentication Flow

```
App Launch
    │
    ├── StorageService.loadSession()
    │       │
    │       ├── Session found + token valid → DashboardPage
    │       │
    │       └── No session / invalid → LoginPage
    │
LoginPage.submit()
    │
    └── AuthService.login()
            │
            └── Save tokens + user → DashboardPage


Any API call → 401 response
    │
    └── ApiService pauses queue
            │
            └── AuthService.refreshToken()
                    │
                    ├── Success → update tokens → retry all queued requests
                    │
                    └── Failure → logout → LoginPage
```

---

## API Endpoints

Base URL: `http://localhost:8080/api/v1/`

| Category | Method | Path | Description |
|---|---|---|---|
| Auth | POST | `account/login` | Login |
| Auth | POST | `auth/logout` | Logout |
| Auth | POST | `account/refresh` | Refresh token |
| Master | GET | `template/GetDepartment` | List departments |
| Master | GET | `template/GetApprovalList` | List approval types |
| Master | GET | `template/GetSourceType` | List source types |
| Master | GET | `template/GetOperations` | List join operators |
| Master | GET | `template/GetSourceMasterList` | All sources |
| Master | GET | `template/GetSourceMasterListFilterwise` | Filtered sources |
| Master | GET | `template/GetSourceList` | Sources by dept+template |
| Master | POST | `template/AddSourceMasterList` | Register new source |
| Template | POST | `template/AddTemplate` | Create template (multipart) |
| Template | GET | `template/GetTemplates` | Templates by department |
| Pipeline | POST | `template/AddTemplateConfig` | Submit pipeline mapping |
| Manual | GET | `template/GetManualTemplateDetails` | Manual template slots |
| Manual | POST | `template/UploadManualData` | Upload file to slot |
| Checker | GET | `template/GetCheckerTayList` | QA task list |
| Checker | POST | `template/UploadManualDataChecker` | Approve/reject task |
| Checker | GET | `template/DownloadFile` | Download checker file |
| Reports | GET | `template/GetReportList` | Processed data reports |

---

## Configuration

API base URL is defined in [lib/config/api_config.dart](lib/config/api_config.dart). Change the `baseUrl` constant there to point to a different environment.

App-level timeouts (60 s debug / 120 s release) are configured inside [lib/services/api_service.dart](lib/services/api_service.dart).

---

## Running the App

```bash
# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on a connected device
flutter run

# Build for web
flutter build web
```

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.0 | State management |
| `dio` | ^5.7.0 | HTTP client |
| `flutter_secure_storage` | ^9.2.2 | Secure token storage |
| `file_picker` | ^6.1.1 | Native file picker |
| `connectivity_plus` | ^6.1.4 | Network connectivity detection |
| `web` | ^1.1.1 | Web platform utilities |
| `flutter_lints` | ^5.0.0 | Static analysis rules |
