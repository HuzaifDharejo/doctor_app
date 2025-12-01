# 🔄 Doctor App - Sequence Diagrams

## Overview
This document contains sequence diagrams for the main workflows in the Doctor App.

---

## 1. Patient Creation Flow

```
User              UI              Database         Riverpod
 |                |                   |               |
 |-- Create Patient-->|                |               |
 |                |-- Get DB Instance-->|               |
 |                |<-- DB Handle ------|               |
 |                |-- Insert Patient-->|               |
 |                |<-- Patient ID -----|               |
 |                |-- Notify State ----|--- Update Providers
 |                |<-- State Updated ---|<-- Done
 |-- Show Success |<-- Navigate Back --|               |
 |                |                   |               |
```

---

## 2. Patient Call Functionality

```
User              Patient View      URL Launcher      Phone System
 |                   |                  |                 |
 |-- Tap Call Icon-->|                  |                 |
 |                   |-- Check Phone -->|                 |
 |                   |<-- Valid --------|                 |
 |                   |-- Launch URI --->|                 |
 |                   |<-- App Available--|                 |
 |                   |-- Open Phone ----|--- Dial Phone -->|
 |                   |<-- Calling ---------|<-- Incoming Ring
 |                   |                  |                 |
 |<-- Call Initiated-|                  |                 |
```

---

## 3. Patient Deletion Flow

```
User              Patient View     Dialog            Database        Riverpod
 |                   |              |                   |              |
 |-- Tap Delete----->|              |                   |              |
 |                   |-- Show Confirm-->|                |              |
 |                   |<-- Dialog Display--|               |              |
 |-- Confirm Delete--|-- Cancel Dialog -->|               |              |
 |                   |              |                   |              |
 |                   |-- Delete Patient->|               |              |
 |                   |              |-- Remove DB ----->|              |
 |                   |              |<-- Deleted -------|              |
 |                   |-- Update State---|--- Refresh Providers ---->|
 |                   |              |                   |<-- Done
 |<-- Navigate Back--|              |                   |              |
```

---

## 4. Patient Email Functionality

```
User              Patient View     URL Launcher      Email Client
 |                   |                 |                 |
 |-- Tap Email----->|                 |                 |
 |                   |-- Check Email ->|                 |
 |                   |<-- Valid -------|                 |
 |                   |-- Launch mailto:|                 |
 |                   |<-- App Available|                 |
 |                   |-- Open Email -->|----->  Email App Opens
 |                   |<-- Launched ----|<-- Compose Window Shows
 |                   |                 |   (with pre-filled subject)
 |<-- Email Ready -->|                 |                 |
```

---

## 5. Share Patient Profile Flow

```
User              Patient View     Share Dialog       Other Apps
 |                   |                 |                 |
 |-- Tap Share----->|                 |                 |
 |                   |-- Format Text ->|                 |
 |                   |<-- Share Text --|                 |
 |                   |-- Show Share ->|----->  Share Menu Opens
 |                   |<-- App Selected--|<-- Select App (SMS, Email, etc)
 |                   |-- Share Data -->|----->  App Receives Data
 |                   |<-- Sharing Done-|<-- User Completes
 |                   |                 |                 |
 |<-- Share Complete |                 |                 |
```

---

## 6. Appointment Management Flow

```
User              Appt Screen      Notification     Database      Riverpod
 |                   |                 |               |             |
 |-- Create Appt -->|                 |               |             |
 |                   |-- Get Patient ->|               |             |
 |                   |<-- Patient Info--|               |             |
 |                   |-- Insert Appt-->|               |             |
 |                   |<-- Appt ID -----|               |             |
 |                   |-- Schedule Notify|-- Set Reminder|             |
 |                   |<-- Scheduled ---|               |             |
 |                   |-- Update State --|- Refresh Providers ---->|
 |                   |<-- UI Updated --|               |<-- Done
 |<-- Appt Created-->|                 |               |             |
 |                   |                 |               |             |
 |   [After Duration]|                 |               |             |
 |                   |<-- Notification Fired ----------|             |
 |<-- Alert/Notify--|                 |               |             |
```

---

## 7. Prescription Creation & PDF Export

```
User              Rx Screen        PDF Service      Database      File System
 |                   |                 |               |             |
 |-- Create Rx----->|                 |               |             |
 |                   |-- Get Patient ->|               |             |
 |                   |<-- Patient Info--|               |             |
 |                   |-- Insert Rx --->|               |             |
 |                   |<-- Rx ID -------|               |             |
 |-- Export PDF---->|-- Generate PDF->|               |             |
 |                   |<-- PDF Data ----|               |             |
 |                   |-- Save to File-->|----->  File Created
 |                   |<-- File Path ---|<-- Success
 |                   |-- Share PDF --->|               |             |
 |                   |<-- Shared -------|               |             |
 |<-- PDF Saved --->|                 |               |             |
```

---

## 8. Medical Records & Assessments

```
User              Medical Screen   Suggestion       Database      Storage
 |                   |             Service           |             |
 |-- Create Record-->|              |               |             |
 |                   |-- Get Suggestions-->|         |             |
 |                   |<-- Suggestions -----|         |             |
 |-- Type in Field-->|-- Auto-Complete -->|         |             |
 |                   |<-- Updated Text ---|         |             |
 |-- Upload Files -->|-- Pick File ----->|         |             |
 |                   |<-- File Selected -|         |             |
 |-- Save Record --->|-- Insert Record ->|         |             |
 |                   |<-- Record ID ----|<-- Done
 |                   |-- Store File ----|---------->|  File Saved
 |                   |<-- Path ----------|<-- Success
 |<-- Record Saved -->|              |               |             |
```

---

## 9. Billing & Invoice Workflow

```
User              Invoice Screen   PDF Gen          Database      Report
 |                   |               |               |             |
 |-- Create Invoice->|              |               |             |
 |                   |-- Get Patient -->|             |             |
 |                   |<-- Patient Info---|             |             |
 |-- Add Items----->|-- Calculate Total|             |             |
 |                   |<-- Amount -------|             |             |
 |-- Generate PDF -->|-- Generate -->|               |             |
 |                   |<-- PDF Done --|               |             |
 |                   |-- Insert Inv ->|             |             |
 |                   |<-- Inv ID ----|<-- Created
 |-- Mark Paid----->|-- Update Status>|             |             |
 |                   |<-- Updated ----|<-- Done
 |-- Export Report-->|-- Generate Stats|---------->| Generate Report
 |                   |<-- Stats Done -|<-- Complete
 |<-- Invoice Ready->|               |               |             |
```

---

## 10. Offline Data Synchronization

```
User              App State        Local DB         Network         Server
 |                   |               |               |               |
 |-- Working Offline (No Connection) |               |               |
 |                   |               |               |  X X X        |
 |-- Create Patient--|-- Insert --->|               |  No Link      |
 |                   |<-- Pending ----|               |               |
 |-- Create Appt ----|-- Insert --->|               |               |
 |                   |<-- Pending ----|               |               |
 |                   |               |               |               |
 |    [Connection Restored]          |               |               |
 |                   |<-- Connected -->|      Reconnected          |
 |                   |-- Queue Sync -->|-- Sync Data -->|           |
 |                   |<-- Syncing ----|<-- Processing--|           |
 |                   |<-- Done -------|<-- Synced ----|<-- Success
 |-- Work Continues->|               |               |               |
```

---

## 11. User Authentication Flow

```
User              Login Screen     Local Auth       Shared Prefs    Database
 |                   |                 |               |              |
 |-- Open App------->|                 |               |              |
 |                   |-- Check Prefs -->|               |              |
 |                   |<-- Auth Status --|               |              |
 |                   |                 |               |              |
 |-- Enter Password->|-- Validate ----->|               |              |
 |                   |<-- Valid --------|               |              |
 |                   |-- Save Token --->|               |              |
 |                   |<-- Saved --------|               |              |
 |                   |-- Load User Data>|               |              |
 |                   |<-- User Info ----|               |              |
 |<-- Navigate Home->|                 |               |              |
```

---

## 12. Search & Filter Workflow

```
User              Search Field     Database         UI
 |                   |               |              |
 |-- Type Query ---->|               |              |
 |                   |-- Debounce -->|              |
 |                   |<-- Wait -------|              |
 |-- Continue Type -->|               |              |
 |                   |-- Cancel Old -->|              |
 |                   |-- New Query -->|              |
 |                   |<-- Results ----|              |
 |                   |-- Filter Data-->|-- Update List
 |                   |<-- Filtered ----|<-- Display
 |<-- See Results -->|               |              |
 |                   |               |              |
 |-- Select Item ----|-- Open Patient |              |
 |<-- Detail View --->|               |              |
```

---

## 13. Dashboard Data Loading

```
User              Dashboard        Providers        Database      Cache
 |                   |               |               |             |
 |-- Open App------->|               |               |             |
 |                   |-- Load Data --->|-- Check Cache-->|           |
 |                   |<-- Loading ----|<-- Wait -------|           |
 |                   |-- Query DB -->|               |             |
 |                   |<-- Data -------|               |             |
 |                   |-- Process Stats|               |             |
 |                   |<-- Stats Ready--|               |             |
 |                   |-- Update Cache-|---------->| Cache Updated
 |                   |<-- Done -------|<-- Success
 |<-- Dashboard Ready|-- Render UI -->|             |             |
 |                   |<-- Displayed -->|             |             |
```

---

## 14. Call Patient Feature (Detailed)

```
Sequence: Calling a Patient

Actor: Doctor
Participant: PatientViewScreen
Participant: Phone Service
Participant: URL Launcher
Participant: Device Phone System

1. Doctor taps "Call" button in patient view
2. PatientViewScreen validates phone number
3. If phone empty -> Show SnackBar error
4. If phone valid -> Launch phone call
5. URL Launcher creates tel:// URI
6. System checks if phone dialer available
7. If available -> Opens phone dialer
8. System dials the number
9. Device connects call
10. Haptic feedback triggered
```

---

## 15. Delete Patient Confirmation Flow

```
Sequence: Deleting a Patient

Actor: Doctor
Participant: PatientViewScreen
Participant: ConfirmationDialog
Participant: Database
Participant: State Management

1. Doctor taps "Delete" in options menu
2. ConfirmationDialog appears with warning
3. Dialog shows: "Are you sure? This cannot be undone"
4. Doctor confirms deletion
5. Database transaction begins
6. Patient record removed from SQLite
7. All related records cleaned up (optional)
8. State providers notified of change
9. UI updates automatically
10. Screen navigates back
11. Success message shown
```

---

## 16. Vital Signs Tracking

```
User              VitalSigns       Database         Charts           Stats
 |                   |               |               |               |
 |-- Add Vital----->|               |               |               |
 |                   |-- Record Data->|               |               |
 |                   |<-- Stored -----|               |               |
 |                   |-- Fetch History|               |               |
 |                   |<-- Data -------|               |               |
 |-- View Charts --->|-- Process Data>|               |               |
 |                   |<-- Ready ------|-- Render Chart->|             |
 |                   |<-- Chart Done--|<-- Displayed
 |-- View Stats ---->|-- Calculate --->|----------- Generate Stats ->|
 |                   |<-- Stats Done -|<-- Complete
 |<-- Data Visualized|               |               |               |
```

---

## 17. Backup & Restore

```
User              Settings         Database         File System     Cloud(Optional)
 |                   |               |               |               |
 |-- Backup App---->|               |               |               |
 |                   |-- Export DB -->|               |               |
 |                   |<-- DB File ----|               |               |
 |                   |-- Compress --->|               |               |
 |                   |<-- Archive ----|-- Save ----->| File Saved   |
 |                   |<-- Success ----|<-- Complete
 |<-- Backup Done -->|               |               |               |
 |                   |               |               |               |
 |-- Restore App --->|               |               |               |
 |                   |-- Pick File -->|               |               |
 |                   |<-- File Selected|               |               |
 |                   |-- Import ----->|               |               |
 |                   |<-- Loaded -----|               |               |
 |                   |-- Validate --->|               |               |
 |                   |<-- Valid ------|               |               |
 |                   |-- Replace DB ->|               |               |
 |                   |<-- Restored ----|               |               |
 |<-- Restore Done -->|               |               |               |
```

---

## Key Components Communication

```
┌─────────────────────────────────────────────────────────────┐
│                        Doctor App                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐         ┌──────────────┐                │
│  │ UI Screens   │◄────────►│   Riverpod   │                │
│  └──────────────┘         │   Providers  │                │
│        │                  └──────────────┘                │
│        │                         │                         │
│        │                         │                         │
│  ┌─────▼──────────┐         ┌───▼────────┐                │
│  │ Drift Database │◄────────┤ Repository │                │
│  │ (SQLite)       │         │  Pattern   │                │
│  └────────────────┘         └────────────┘                │
│        │                                                  │
│        ├─ Offline Storage                                │
│        ├─ CRUD Operations                                │
│        └─ Query Execution                                │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │         External Services                          │  │
│  ├────────────────────────────────────────────────────┤  │
│  │ • URL Launcher (Phone/Email)                       │  │
│  │ • Share Plus (Sharing)                             │  │
│  │ • File Picker (File Selection)                     │  │
│  │ • Image Picker (Photos)                            │  │
│  │ • Notifications (Reminders)                        │  │
│  │ • Local Auth (Biometric)                           │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│ ┌──────────────────────────────────────────────────────┐   │
│ │  Dashboard │ Patients │ Appointments │ Billing │... │   │
│ └──────────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│               State Management (Riverpod)                   │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ Providers │ Families │ State Notifiers │ Selectors   │   │
│ └──────────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│              Repository/Service Layer                       │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ Database Service │ File Service │ Suggestion Service│   │
│ └──────────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                 Data Layer (Drift ORM)                      │
│ ┌──────────────────────────────────────────────────────┐   │
│ │          SQLite Database (Offline Storage)           │   │
│ └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

---

## Notes

- All diagrams follow standard sequence diagram notation
- Solid arrows (→) represent synchronous calls
- Dashed arrows (-->) represent asynchronous operations
- Box diagrams show component relationships and dependencies
- This architecture supports full offline-first functionality
- State changes propagate through Riverpod providers
- All data persists in local SQLite database

