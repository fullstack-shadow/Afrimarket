# Afrimarket
AFRIMARKET is a modern Flutter-based e-commerce platform designed for African markets. It connects buyers and sellers across the continent through a beautifully crafted, modular, and scalable app architecture.
AFRIMARKET is a modern Flutter-based e-commerce platform designed for African markets. It connects buyers and sellers across the continent through a beautifully crafted, modular, and scalable app architecture.

🚀 Features
🛍️ Multi-category product listings (fashion, beauty, digital, etc.)

🔐 Secure user authentication with login & signup

💬 Real-time chat between buyers and sellers

💳 Integrated payments (e.g. M-Pesa, card, mobile money)

🧾 Order tracking, history & referrals

🔔 Push notifications

📊 Admin dashboard with user management & analytics

📦 Mock data & test coverage included

🌐 Internationalization support via .arb files

📸 Cloud storage for images & media

🧪 Widget, integration, and unit tests

🧱 Tech Stack
Flutter + Dart

Firebase (Auth, Firestore, Cloud Storage)

Riverpod / BLoC (for state management)

VS Code + WSL Dev Setup

CI/CD via GitHub Actions

Structured architecture: core, features, data, services, widgets

🧪 Test Strategy
Unit tests (test/unit/)

Widget tests (test/widget/)

Integration tests (test/integration/)

Golden tests (test/golden/)

Contract tests (test/contract/)

📁 Folder Highlights
lib/core/ → App-wide services (analytics, config, theming, etc.)

lib/features/ → Feature-first modules (auth, chat, shop, etc.)

lib/services/ → Shared service layer (API, auth, storage)

test/ → Cleanly separated test types

mock_data/ → Product & user mock JSON

assets/ → Images, fonts, Lottie, language files

scripts/ → Firebase setup, testing, coverage, docs

.vscode/ → Workspace settings and launch configs

📦 Getting Started
bash
Copy
Edit
git clone https://github.com/fullstack-shadow/afrimarket.git
cd afrimarket
flutter pub get
flutter run
🤝 Contributing
Pull requests are welcome! Please read the CONTRIBUTING.md (coming soon) for guidelines.

📝 License
This project is licensed under the MIT License.
