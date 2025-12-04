<div align="center">
<img style="width: 128px; height: 128px;" src="logo.svg" alt="logo" />

# Openlist 同步器

一個可以將Openlist裡的資料夾同步到本地的軟體

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

[English](README_en.md) | [简体中文](README.md) | 繁體中文

---

</div>

## 下載與安裝

請前往[Release](https://github.com/Hollow-YK/OpenlistSyncer/releases)下載最新安裝包並安裝。

## 功能

- 透過 API 登入 Openlist ，理論上支援 2FA
- 將 Openlist 裡的資料夾同步到本地
- 記住 Openlist 資訊，進行自動登入
- 記憶上次使用的源路徑，方便使用
- 15種個性化主題配色，自動切換明暗模式

> [!Tip]
>
> 預設情況下，記住 Openlist 地址功能與記憶上次使用的源路徑功能為開啟狀態。

> [!Warning]
>
> 登入時，你的密碼可能會被其它程式透過部分手段取得。

> [!Warning]
>
> 2FA 相關功能未經測試，可能存在 Bug 。

> [!Caution]
>
> 密碼會被以Base64編碼後的形式儲存，不保證儲存的安全性。
> 你可以理解為密碼是**明文**儲存的。

### 未來規劃

*這些功能計劃在將來實現，但是現在還沒做

- 將本地的資料夾同步到 Openlist

## 使用說明

僅在 Android 14-16 進行過測試，不保證其它版本的相容性。

### 準備工作

- 你需要有一個使用 [OpenList](https://github.com/OpenListTeam/OpenList) 搭建的私有雲。
- 你還需要有一個**基本路徑為 `root` （根目錄）的**帳戶。（歡迎提交 PR 幫忙適配基本路徑不是 `root` 的帳戶。）
- 安裝本軟體。你可以前往 [Release](https://github.com/Hollow-YK/OpenlistSyncer/releases) 下載相應版本的最新安裝包並安裝。如果你不知道安裝哪個版本，就直接下載並安裝檔名為 `OpenlistSyncer-0.0.1-app-release.apk` 形式的安裝包。

### 自動登入與記住Openlist資訊

相關設定項可在 `設定->Openlist設定` 中找到。

<details>

#### 記住Openlist資訊

預設情況下，記住 Openlist 地址功能將會啟用。開啟此功能時應用會儲存你的 Openlist 地址並在下次自動填入至登入頁面的相應輸入框。

你可以在設定裡開啟記住 Openlist 帳號和記住 Openlist 密碼功能。

> [!Caution]
>
> Openlist 地址與 Openlist 帳號將會被以明文的形式儲存。
> Openlist 密碼會被以 Base64 編碼後的形式儲存，不保證儲存的安全性。（你可以理解為密碼是**明文**儲存的。）

#### 自動登入

在開啟了記住 Openlist 地址、記住 Openlist 帳號、記住 Openlist 密碼功能並儲存了以上資訊後，你可以開啟自動登入。

開啟自動登入後，會在**每次進入登入頁面時**嘗試使用儲存的資訊登入。

</details>

### 自行編譯

<details>

1. clone本倉庫
2. 完成 `flutter pub get`
3. 執行 `flutter build apk --release` 打包 APK ，或 `flutter build apk --split-per-abi` 為每個 abi 打包 APK

</details>

## 致謝

### 開源專案

- 使用了 [Flutter](https://github.com/flutter/flutter) 框架
- 使用了 [OpenList](https://github.com/OpenListTeam/OpenList) 的 API
- [http](https://github.com/dart-lang/http/tree/master/pkgs/http)
- [path_provider](https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider)
- [file_picker](https://github.com/miguelpruivo/flutter_file_picker)
- [path](https://github.com/dart-lang/core/tree/main/pkgs/path)
- [permission_handler](https://github.com/baseflow/flutter-permission-handler)
- [url_launcher](https://github.com/flutter/packages/tree/main/packages/url_launcher/url_launcher)
- [shared_preferences](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences)
- [flutter_test](https://github.com/dart-lang/test/tree/master/pkgs/test)
- [flutter_lints](https://github.com/flutter/packages/tree/main/packages/flutter_lints)

還參考了一些開源Flutter專案的程式碼結構

### 其它

- 使用Flutter進行開發
- ~~`README.md`照抄了我的另一個倉庫的README~~
- `README.md`參考了[MaaAssistantArknights](https://github.com/MaaAssistantArknights/MaaAssistantArknights/)
- `README.md`使用了[shields.io](https://shields.io/)、[contrib.rocks](https://contrib.rocks/)提供的內容

### 貢獻/參與者

感謝所有參與到開發/測試中的朋友們(\*´▽｀)ノノ

~~好像只有我自己~~

[![Contributors](https://contributors-img.web.app/image?repo=Hollow-YK/OpenlistSyncer&max=105&columns=15)](https://github.com/Hollow-YK/OpenlistSyncer/graphs/contributors)

## 聲明

- 本軟體使用 [GNU Affero General Public License v3.0 only](https://spdx.org/licenses/AGPL-3.0-only.html) 開源。
- 本軟體開源、免費，僅供學習交流使用。
- 免責聲明：將此軟體用於任何用途均與開發者無關，不對使用者的任何行為負責。

## 推廣

如果覺得軟體對你有幫助，幫忙點個 Star 吧！~（網頁最上方右上角的小星星），這就是對我們最大的支持了！