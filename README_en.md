<div align="center">
<img style="width: 128px; height: 128px;" src="logo.svg" alt="logo" />

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

- Login to Openlist via API, theoretically supports 2FA
- Synchronize folders from Openlist to local device
- Remember Openlist information for automatic login
- 15 personalized theme colors with automatic light/dark mode switching

> [!Tip]
>
> By default, the "Remember Openlist address" feature is enabled.

> [!Warning]
>
> During login, your password might be obtained by other programs through certain means.

> [!Warning]
>
> 2FA related features have not been tested and may contain bugs.

> [!Caution]
>
> Passwords are saved in Base64 encoded form, storage security is not guaranteed.
> You can consider passwords as stored in **plain text**.

### Future Plans

*These features are planned for future implementation but not yet available

- Sync local folders to Openlist
- Remember last used information

## Usage Instructions

Tested only on Android 14-16. Compatibility with other versions is not guaranteed.

### Preparation

- You need to have a private cloud built using [OpenList](https://github.com/OpenListTeam/OpenList).
- You also need an account with **base path as `root`** (the root directory). (PRs are welcome to help adapt accounts with base path is not `root`.)
- Install this application. You can go to [Release](https://github.com/Hollow-YK/OpenlistSyncer/releases) to download the latest installation package for the corresponding version and install it. If you don't know which version to install, simply download and install the package named in the format `OpenlistSyncer-0.0.1-app-release.apk`.

### Automatic Login & Remembering Openlist Information

Related settings can be found in `Settings -> Openlist Settings`.

<details>

#### Remember Openlist Information

By default, the "Remember Openlist address" feature is enabled. When this feature is enabled, the app will save your Openlist address and automatically fill it into the corresponding input field on the login page next time.

You can enable "Remember Openlist account" and "Remember Openlist password" features in settings.

> [!Caution]
>
> Openlist address and Openlist account will be saved in plain text.
> Openlist password will be saved in Base64 encoded form, storage security is not guaranteed. (You can consider passwords as stored in **plain text**.)

#### Automatic Login

After enabling "Remember Openlist address", "Remember Openlist account", and "Remember Openlist password" features and saving the above information, you can enable automatic login.

When automatic login is enabled, it will attempt to log in using the saved information **every time you enter the login page**.

</details>

### Building fron source

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

[![Contributors](https://contributors-img.web.app/image?repo=Hollow-YK/OpenlistSyncer&max=105&columns=15)](https://github.com/Hollow-YK/OpenlistSyncer/graphs/contributors)

## Disclaimer

- This software is open-sourced under the [GNU Affero General Public License v3.0 only](https://spdx.org/licenses/AGPL-3.0-only.html).
- This software is open-source and free, intended solely for learning and communication purposes.
- Disclaimer: The use of this software for any purpose is unrelated to the developers, who assume no responsibility for any actions taken by users.

## Advertisement

If you find this software helpful, please give it a Star! (The little star at the top right of the webpage). That would be your greatest support for us!