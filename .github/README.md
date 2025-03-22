# GitHub Workflows for Inventory Manager

This directory contains GitHub Actions workflows that automate the build and release process for the Inventory Manager Flutter application.

## Available Workflows

### 1. Android Build (`android_build.yml`)

- Builds the Android APK and AAB on push or PR to main/master branches
- Uploads artifacts for download

### 2. iOS Build (`ios_build.yml`)

- Builds the iOS IPA (unsigned) on push or PR to main/master branches
- Uploads artifacts for download

### 3. Flutter Build (`flutter_build.yml`)

- Combined workflow that:
  - Analyzes the code
  - Builds Android APK/AAB
  - Builds iOS IPA
- Uses job dependencies to only build if analysis passes

### 4. Release Workflow (`release.yml`)

- Triggered when a tag is pushed (format: `v*`)
- Builds both Android and iOS artifacts
- Creates a GitHub Release with all artifacts attached

## Using These Workflows

### Manually Triggering Builds

All workflows have the `workflow_dispatch` trigger, allowing you to manually run them from the GitHub Actions tab.

### Creating a Release

To create a new release:

1. Tag your commit: `git tag v1.0.0`
2. Push the tag: `git push origin v1.0.0`
3. The release workflow will automatically build all artifacts and create a release

## Notes for iOS Builds

The current iOS workflow builds an **unsigned** IPA file that cannot be directly installed on devices. For distributing iOS apps, you'll need to:

1. Set up proper code signing certificates
2. Configure provisioning profiles
3. Use Apple Developer account credentials

For production deployments, consider extending the workflow with Fastlane for proper signing and distribution.
