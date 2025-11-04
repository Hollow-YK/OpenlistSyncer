<div align="center">

# Openlist Syncer

An application that syncs folders from Openlist to your local device.

<div>
    <img alt="platform" src="https://img.shields.io/badge/platform-Android-blueviolet">
    <a href="https://github.com/Hollow-YK/OpenlistSyncer/releases"><img src="https://img.shields.io/github/release/Hollow-YK/OpenlistSyncer" alt="latest version" /></a>
    <img alt="GitHub all releases" src="https://img.shields.io/github/downloads/Hollow-YK/OpenlistSyncer/total">
</div>
<div>
    <img alt="license" src="https://img.shields.io/github/license/Hollow-YK/OpenlistSyncer">
    <img alt="commit" src="https://img.shields.io/github/commit-activity/m/Hollow-YK/OpenlistSyncer">
    <img alt="stars" src="https://img.shields.io/github/stars/Hollow-YK/OpenlistSyncer?style=social">
</div>
<br>

English | [简体中文](README.md) | [繁體中文](README_zh_tw.md)

---

</div>

## Download & Installation

Please go to [Releases](https://github.com/Hollow-YK/OpenlistSyncer/releases) to download the latest installation package.

## Features

- Log in to Openlist via API
- Sync folders from Openlist to your local device
- 15 personalized theme colors with automatic light/dark mode switching

### Future Plans

*These features are planned for future implementation but are not currently available.

- Sync local folders to Openlist
- Remember previously used information

## Instructions

Tested only on Android 14-16. Compatibility with other versions is not guaranteed.

### Prerequisites

- You need to have a private cloud set up using [OpenList](https://github.com/OpenListTeam/OpenList) or one with an API identical to OpenList.
- You also need an account with a **base path of `root`** (the root directory). (PRs are welcome to help adapt for accounts where the base path is not `root`.)
- Install the application. You can go to [Releases](https://github.com/Hollow-YK/OpenlistSyncer/releases) to download the latest installation package for the corresponding version. If you are unsure which version to install, simply download and install the package named in the format `OpenlistSyncer-0.0.1-app-release.apk`.

### Usage Process

1.  Configure the Openlist address and log in to your Openlist account. Note: **Only accounts with a base path of `root` are supported**.
2.  Configure the source path (the Openlist path to sync from) and select the local path.
3.  Start the sync.

### Building from Source

<details>

1.  Clone this repository.
2.  Run `flutter pub get`.
3.  Execute `flutter build apk --release` to build the APK, or `flutter build apk --split-per-abi` to build APKs for each ABI.

</details>

## Acknowledgments

### Open Source Projects

- Built using the [Flutter](https://github.com/flutter/flutter) framework.
- Utilizes the [OpenList](https://github.com/OpenListTeam/OpenList) API.
- [http](https://github.com/dart-lang/http/tree/master/pkgs/http)
- [path_provider](https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider)
- [file_picker](https://github.com/miguelpruivo/flutter_file_picker)
- [path](https://github.com/dart-lang/core/tree/main/pkgs/path)
- [permission_handler](https://github.com/baseflow/flutter-permission-handler)
- [url_launcher](https://github.com/flutter/packages/tree/main/packages/url_launcher/url_launcher)
- [shared_preferences](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences)
- [flutter_test](https://github.com/dart-lang/test/tree/master/pkgs/test)
- [flutter_lints](https://github.com/flutter/packages/tree/main/packages/flutter_lints)

Also referenced the code structure of some open-source Flutter projects.

### Others

- Developed using Flutter.
- The `README.md` references the README from [MaaAssistantArknights](https://github.com/MaaAssistantArknights/MaaAssistantArknights/).
- The `README.md` uses content provided by [shields.io](https://shields.io/) and [contrib.rocks](https://contrib.rocks/).

### Contributors

Thanks to all friends who participated in development/testing (\*´▽｀)ノノ

~~Seems like it's just me for now~~

[![Contributors](https://contrib.rocks/image?repo=Hollow-YK/Yunhu_MinecraftStatus_Bot&max=105&columns=15)](https://github.com/Hollow-YK/Yunhu_MinecraftStatus_Bot/graphs/contributors)

## Disclaimer

- This software is open-sourced under the [GNU Affero General Public License v3.0 only](https://spdx.org/licenses/AGPL-3.0-only.html).
- This software is open-source and free, intended solely for learning and communication purposes.
- Disclaimer: The use of this software for any purpose is unrelated to the developers, who assume no responsibility for any actions taken by users.

## Advertisement

If you find this software helpful, please give it a Star! (The little star at the top right of the webpage). That would be your greatest support for us!