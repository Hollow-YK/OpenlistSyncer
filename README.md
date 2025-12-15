<div align="center">
<img style="width: 128px; height: 128px;" src="logo.svg" alt="logo" />

# Openlist 同步器

一个可以将Openlist里的文件夹同步到本地的软件

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

[English](README_en.md) | 简体中文 | [繁体中文](README_zh_tw.md)

---

</div>

## 下载与安装

请前往[Release](https://github.com/Hollow-YK/OpenlistSyncer/releases)下载最新安装包并安装。

## 功能

- 通过 API 登录 Openlist ，理论上支持 2FA
- 将 Openlist 里的文件夹同步到本地
- 记住 Openlist 信息，进行自动登录
- 记住上次使用的源路径，方便使用
- 15种个性化主题配色，自动切换明暗模式

> [!Tip]
>
> 默认情况下，记住 Openlist 地址功能与记住上次使用的源路径功能为开启状态。

> [!Warning]
>
> 登录时，你的密码可能会被其它程序通过部分手段获取。

> [!Warning]
>
> 2FA 相关功能未经测试，可能存在 Bug 。

> [!Caution]
>
> 密码会被以Base64编码后的形式保存，不保证储存的安全性。
> 你可以理解为密码是**明文**储存的。

### 画饼

*这些功能计划在将来实现，但是现在还没做

- 将本地的文件夹同步到 Openlist

## 使用说明

仅在 Android 14-16 进行过测试，不保证其它版本的兼容性。

### 准备工作

- 你需要有一个使用 [OpenList](https://github.com/OpenListTeam/OpenList) 搭建的<!--或 API 与 OpenList 相同的-->私有云。<!--（使用到了包括 [User logout](https://fox.oplist.org/364155678e0)、[User login](https://fox.oplist.org/364155681e0)、[List directory contents](https://fox.oplist.org/364155732e0)、[Get file or directory info](https://fox.oplist.org/364155733e0)、[Get directory tree](https://fox.oplist.org/364155735e0)）在内的多个API-->
- 你还需要有一个**基本路径为 `root` （根目录）的**账户。（欢迎提交 PR 帮忙适配基本路径不是 `root` 的账户。）
- 安装本软件。你可以前往 [Release](https://github.com/Hollow-YK/OpenlistSyncer/releases) 下载相应版本的最新安装包并安装。如果你不知道安装哪个版本，就直接下载并安装文件名为 `OpenlistSyncer-0.0.1-app-release.apk` 形式的安装包。

### 自动登录与记住Openlist信息

相关设置项可在 `设置->Openlist设置` 中找到。

#### 记住Openlist信息

默认情况下，记住 Openlist 地址功能将会启用。开启此功能时应用会保存你的 Openlist 地址并在下次自动填充至登录页面的相应输入框。

你可以在设置里打开记住 Openlist 账号和记住 Openlist 密码功能。

> [!Caution]
>
> Openlist 地址与 Openlist 账号将会被以明文的形式保存。
> Openlist 密码会被以 Base64 编码后的形式保存，不保证储存的安全性。（你可以理解为密码是**明文**储存的。）

#### 自动登录

在开启了记住 Openlist 地址、记住 Openlist 账号、记住 Openlist 密码功能并保存了以上信息后，你可以开启自动登录。

开启自动登录后，会在**每次进入登录页面时**尝试使用保存的信息登录。

### 自行编译

<details>

1. clone本仓库
2. 完成 `flutter pub get`
3. 执行 `flutter build apk --release` 打包 APK ，或 `flutter build apk --split-per-abi` 为每个 abi 打包 APK

</details>

## 致谢

### 开源项目

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

还参考了一些开源Flutter项目的代码结构

### 其它

- 使用Flutter进行开发
- ~~`README.md`照抄了我的另一个仓库的README~~
- `README.md`参考了[MaaAssistantArknights](https://github.com/MaaAssistantArknights/MaaAssistantArknights/)
- `README.md`使用了[shields.io](https://shields.io/)、[contrib.rocks](https://contrib.rocks/)提供的内容

### 贡献/参与者

感谢所有参与到开发/测试中的朋友们(\*´▽｀)ノノ

~~好像只有我自己~~

[![Contributors](https://contributors-img.web.app/image?repo=Hollow-YK/OpenlistSyncer&max=105&columns=15)](https://github.com/Hollow-YK/OpenlistSyncer/graphs/contributors)

## 声明

- 本软件使用 [GNU Affero General Public License v3.0 - only](LICENSE) 开源。
- 本软件开源、免费，仅供学习交流使用。
- 免责声明：将此软件用于任何用途均与开发者无关，不对使用者的任何行为负责。

## 广告

如果觉得软件对你有帮助，帮忙点个 Star 吧！~（网页最上方右上角的小星星），这就是对我们最大的支持了！