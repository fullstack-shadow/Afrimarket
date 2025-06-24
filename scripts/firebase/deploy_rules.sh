#!/bin/bash
# Deploys Firebase security rules and indexes
# Usage: ./scripts/firebase/deploy_rules.sh

# Strict mode for error handling
set -euo pipefail

# Configuration variables
PROJECT_ID="your-project-id"
RULES_FILE="firebase/firestore.rules"
INDEXES_FILE="firebase/firestore.indexes.json"

echo "🚀 Deploying Firebase security rules..."

# Verify files exist
if [ ! -f "$RULES_FILE" ]; then
    echo "❌ Rules file not found at $RULES_FILE"
    exit 1
fi

if [ ! -f "$INDEXES_FILE" ]; then
    echo "❌ Indexes file not found at $INDEXES_FILE"
    exit 1
fi

# Deploy Firestore rules and indexes
firebase deploy --only firestore:rules --project=$PROJECT_ID
firebase deploy --only firestore:indexes --project=$PROJECT_ID

# Deploy Storage rules
firebase deploy --only storage --project=$PROJECT_ID

echo "✅ Firebase rules deployed successfully to $PROJECT_ID"