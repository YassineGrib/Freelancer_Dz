# FreeLancer Mobile 📱

![FreeLancer Mobile Banner](assets/images/briefcase-logo.png)

A comprehensive freelance management mobile application built with Flutter, specifically designed for Algerian freelancers to manage their business efficiently with local tax compliance, offline support, and Arabic language support.

---

## 📑 Table of Contents
- [Features](#-features)
- [Demo](#-demo)
- [Getting Started](#-getting-started)
- [Current Features](#-current-features)
- [Configuration](#-configuration)
- [Design System](#-design-system)
- [Security](#-security)
- [Dependencies](#-dependencies)
- [Offline Support Details](#-offline-support-details)
- [Support](#-support)
- [Contributing](#-contributing)
- [License](#-license)

## 🎥 Demo

<!-- Add screenshots or GIFs here -->
<p align="center">
  <img src="assets/images/briefcase-logo.png" alt="App Screenshot" width="250"/>
</p>

---

# FreeLancer Mobile 📱

A comprehensive freelance management mobile application built with Flutter, specifically designed for Algerian freelancers to manage their business efficiently with local tax compliance, offline support, and Arabic language support.

## ✨ Features

### 🎨 Design
- **Minimalist UI** - Clean, flat design with black and white theme
- **Simple Navigation** - Intuitive user experience
- **Responsive Layout** - Works on all screen sizes
- **Input Icons** - Clean icons for form fields only

### 🔐 Authentication
- **User Registration** - Sign up with email and password
- **User Login** - Secure authentication
- **Email Verification** - Verify accounts via email
- **Password Reset** - Reset forgotten passwords
- **Auto Login** - Remember user sessions

### 📊 **Business Management**
- **Dashboard** - Comprehensive overview with business health score and financial metrics
- **Client Management** - Manage client information, contacts, and relationships
- **Project Management** - Track projects, deadlines, progress, and deliverables
- **Payment Tracking** - Monitor payments, invoices, and financial transactions
- **Expense Management** - Track business expenses and costs
- **Invoice Generation** - Create professional invoices with automatic numbering
- **Tax Management** - Algerian tax calculations (IRG Simplifié, CASNOS)
- **Calendar & Events** - Manage deadlines, appointments, and important dates
- **Reports & Analytics** - Business insights and performance reports
- **Notifications** - Smart reminders and alerts

### 🔄 **Offline Support**
- **Local Database** - SQLite for offline data storage
- **Cached Data** - Access your data even without internet connection
- **Automatic Sync** - Synchronizes data when back online
- **Connectivity Monitoring** - Real-time connection status tracking
- **Conflict Resolution** - Smart handling of data conflicts during sync
- **Sync Queue** - Queues changes made while offline for later synchronization
- **Manual Sync** - Force sync when needed
- **Offline Indicators** - Visual indicators showing offline/online status

### 🇩🇿 **Algerian Market Specific**
- **IRG Simplifié** - 10,000 DA fixed (income < 2M DA) or 0.5% (income ≥ 2M DA)
- **CASNOS** - 24,000 DA annual social security payment
- **Tax Deadlines** - January 10 for taxes, June 20 for CASNOS
- **Dinar Algérien (DA)** - Local currency support
- **Arabic Interface** - Coming soon (RTL support)
- **Local Compliance** - Follows Algerian freelance regulations

### 🛠 Technical Features
- **Local Database** - All data stored locally (SQLite)
- **Form Validation** - Client-side validation with error messages
- **Error Handling** - User-friendly error messages
- **State Management** - Clean authentication state handling
- **Security** - Local data protection

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code

### Installation

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Current Features

### Authentication Flow
1. **App Launch** → Check if user is logged in
2. **Not Logged In** → Show Login Screen
3. **Login/Register** → Authenticate locally
4. **Success** → Navigate to Home Screen
5. **Logout** → Return to Login Screen

### Screens
- **Login Screen** - Email/password login with validation
- **Register Screen** - User registration with terms agreement
- **Home Screen** - Welcome dashboard with user info and quick actions

## 🔧 Configuration

All configuration is handled locally. No cloud setup required.

## 🎨 Design System

### Colors
- **Primary**: Black (#000000)
- **Background**: White (#FFFFFF)
- **Surface**: Light Gray (#F8F8F8)
- **Text Primary**: Black (#000000)
- **Text Secondary**: Gray (#666666)
- **Border**: Light Gray (#E0E0E0)

### Typography
- **Font**: Poppins (Google Fonts)
- **Weights**: 400 (regular), 500 (medium), 600 (semi-bold)

### Components
- **Flat Design** - No shadows or gradients
- **Sharp Corners** - 4px border radius
- **Minimal Icons** - Only functional icons
- **High Contrast** - Black text on white background

## 🛡 Security

### Current Security Features
- Local authentication
- Email verification (if implemented)
- Secure password handling
- Client-side validation

## 📚 Dependencies

### Main Dependencies
- `flutter` - UI framework
- `google_fonts` - Typography
- `font_awesome_flutter` - Icons
- `sqflite` - Local SQLite database for offline storage
- `connectivity_plus` - Network connectivity monitoring
- `shared_preferences` - Local preferences and cache
- `table_calendar` - Calendar widget for events
- `json_annotation` - JSON serialization support

### Offline Support Dependencies
- `sqflite: ^2.3.3+1` - SQLite database for local storage
- `path: ^1.9.0` - File path utilities
- `connectivity_plus: ^6.0.3` - Network connectivity monitoring
- `shared_preferences: ^2.2.3` - Local preferences storage
- `json_annotation: ^4.9.0` - JSON serialization
- `build_runner: ^2.4.9` - Code generation for JSON
- `json_serializable: ^6.8.0` - JSON serialization generator

## 🔄 Offline Support Details

### How It Works
The app provides comprehensive offline support to ensure you can work even without an internet connection:

1. **Local Storage** - All data is stored locally using SQLite database
2. **Sync Queue** - Changes made offline are queued for synchronization
3. **Connectivity Monitoring** - App continuously monitors network status
4. **Automatic Sync** - Data automatically syncs when connection is restored
5. **Conflict Resolution** - Smart handling of data conflicts using timestamps

### Offline Features
- ✅ **View all data** - Access clients, projects, payments, expenses, invoices
- ✅ **Create new records** - Add new clients, projects, payments while offline
- ✅ **Edit existing data** - Modify any information offline
- ✅ **Delete records** - Remove data with sync queue tracking
- ✅ **Generate reports** - Create reports from locally stored data
- ✅ **View dashboard** - See business metrics and statistics
- ✅ **Calendar events** - Access and manage calendar offline

### Sync Process
1. **User makes changes** while offline
2. **Changes stored locally** in SQLite database
3. **Added to sync queue** with action type (INSERT/UPDATE/DELETE)
4. **When online** - sync service processes the queue (optional for future cloud support)
5. **Queue cleanup** - remove successfully synced items

### Connectivity Indicators
- 🟢 **Green WiFi icon** - Online and connected
- 🔴 **Red WiFi off icon** - Offline mode
- **Status screen** - Detailed connectivity and sync information
- **Sync progress** - Visual indicators during synchronization
- **Error handling** - Clear messages for sync failures

### Data Flow
```
User Action → Local SQLite → Sync Queue → (When Online) → Supabase → Local SQLite
```

### Accessing Offline Status
1. Tap the **connectivity icon** in the app bar (WiFi/WiFi-off)
2. View detailed **connectivity information**
3. See **pending changes** count
4. **Manual sync** trigger
5. **Clear offline data** option
6. **Sync error** details and resolution

## 🆘 Support

### Common Issues
- **Build errors**: Run `flutter clean` and `flutter pub get`
- **Authentication issues**: Check your local configuration

### Getting Help
- Review error messages in the console

---

## 🤝 Contributing

Contributions are welcome! Please open issues or submit pull requests for improvements, bug fixes, or new features. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed for non-commercial use only. See the [LICENSE](LICENSE) file for details in English and Arabic.
