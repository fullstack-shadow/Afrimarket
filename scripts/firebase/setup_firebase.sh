#!/bin/bash
# Sets up Firebase for the project with proper configurations
# Usage: ./scripts/firebase/setup_firebase.sh

# Strict mode for error handling
set -euo pipefail

# Configuration variables
PROJECT_ID="your-project-id"
ANDROID_APP_ID="your-android-app-id"
IOS_APP_ID="your-ios-app-id"
WEB_APP_NAME="your-web-app-name"

echo "🚀 Starting Firebase setup for $PROJECT_ID"

# Verify Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install with: npm install -g firebase-tools"
    exit 1
fi

# Login to Firebase (if not already logged in)
firebase login --no-localhost

# Initialize Firebase project
echo "🔧 Initializing Firebase project..."
firebase projects:create $PROJECT_ID

# Configure Firebase services
echo "⚙️ Configuring Firebase services..."

# Set up Firestore
firebase firestore:databases:create --project=$PROJECT_ID \
  --database="(default)" \
  --location=us-central1 \
  --type=production

# Set up Storage
firebase storage:setup --project=$PROJECT_ID

# Add Firebase to platforms
echo "📱 Adding Firebase to platforms..."

# Android setup
firebase apps:create android $PROJECT_ID $ANDROID_APP_ID

# iOS setup
firebase apps:create ios $PROJECT_ID $IOS_APP_ID

# Web setup
firebase apps:create web $PROJECT_ID $WEB_APP_NAME

# Deploy initial rules
echo "🛡️ Deploying initial security rules..."
./scripts/firebase/deploy_rules.sh

echo "✅ Firebase setup completed successfully for $PROJECT_ID"