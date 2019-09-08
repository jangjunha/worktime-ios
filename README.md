HeekTime iOS
===

## Prerequisites

- Ruby 2.4

- Xcode


## Installation

```bash
# Install gem dependencies
$ bundle install

# Install pod dependencies
$ bundle exec pod install
```


## Lint

```bash
$ bundle exec fastlane lint
```


## Deploy

Make release branch and follow the deploy process.

1. Update version

```bash
$ bundle exec fastlane run increment_version_number version_number:0.0.0
$ bundle exec fastlane run increment_build_number
# and commit changes
```

2. Update metadata

Update fastlane/metadata including update nodes. Commit changes.

3. (Optional) Take screenshot

```bash
$ bundle exec fastlane ios take_screenshot
```

4. Deploy to App Store

```bash
$ bundle exec fastlane ios release
```

5. Request app review

Request review on app store connect.

6. Merge release

Merge release branch when review is approved.
