#!/bin/bash

# Ad Removal Verification Script
# Run this script to verify all ad-related code has been removed

echo "🔍 Searching for remaining ad-related code..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for issues found
ISSUES=0

# Function to search and report
search_term() {
    local term=$1
    local description=$2
    
    echo "Searching for: $description ($term)"
    
    # Search in Swift files
    results=$(find . -name "*.swift" -type f ! -path "*/.*" -exec grep -l "$term" {} \; 2>/dev/null)
    
    if [ -z "$results" ]; then
        echo -e "${GREEN}✅ No occurrences found${NC}"
    else
        echo -e "${RED}❌ Found in:${NC}"
        echo "$results"
        ISSUES=$((ISSUES + 1))
    fi
    echo ""
}

echo "================================================"
echo "  Ad Code Removal Verification"
echo "================================================"
echo ""

# Search for common ad-related terms
search_term "AdManager" "Ad Manager References"
search_term "GoogleMobileAds" "Google Mobile Ads SDK Import"
search_term "BannerAdView" "Banner Ad View Component"
search_term "NativeAdView" "Native Ad View Component"
search_term "InterstitialAd" "Interstitial Ad References"
search_term "RewardedAd" "Rewarded Ad References"
search_term "GADNative" "Google Ad Native"
search_term "GADBanner" "Google Ad Banner"
search_term "trackNavigationForAds" "Ad Tracking Modifier"
search_term "showRewardedAd" "Rewarded Ad Methods"
search_term "loadInterstitialAd" "Interstitial Load Methods"

echo "================================================"
echo "  Files That Should Be Deleted"
echo "================================================"
echo ""

# Check if ad-related files still exist
ad_files=(
    "AdManager.swift"
    "BannerAdView.swift"
    "NativeAdView.swift"
    "InterstitialAdCoordinator.swift"
    "InterstitualAdCoordinator.swift"
    "RewardedAdView.swift"
    "EnhancedBannerAdView.swift"
)

for file in "${ad_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${RED}❌ Still exists: $file${NC}"
        ISSUES=$((ISSUES + 1))
    else
        echo -e "${GREEN}✅ Deleted: $file${NC}"
    fi
done

echo ""
echo "================================================"
echo "  Summary"
echo "================================================"
echo ""

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ SUCCESS: All ad-related code has been removed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Remove GoogleMobileAds from your Package Dependencies"
    echo "2. Clean build folder (⌘⇧K)"
    echo "3. Build and run the app (⌘R)"
    echo ""
    exit 0
else
    echo -e "${RED}❌ ISSUES FOUND: $ISSUES potential ad references remain${NC}"
    echo ""
    echo "Please review the files listed above and:"
    echo "1. Remove any remaining ad-related code"
    echo "2. Delete ad-related files"
    echo "3. Run this script again"
    echo ""
    exit 1
fi
