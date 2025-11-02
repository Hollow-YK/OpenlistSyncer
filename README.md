<div align="center">

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

---

</div>

## 下载与安装

请前往[Release](https://github.com/Hollow-YK/OpenlistSyncer/releases)下载最新安装包并安装。

## 功能

- 通过 API 登录 Openlist
- 将 Openlist 里的文件夹同步到本地

### 画饼

*这些功能计划在将来实现，但是现在还没做

- 明暗主题
- 将本地的文件夹同步到Openlist

## 使用说明

仅在Android 14-16 进行过测试，不保证其它版本的兼容性。

### 准备工作

- 你需要有一个使用 [OpenList](https://github.com/OpenListTeam/OpenList) 搭建的或 API 与 OpenList 相同的私有云（使用到了 [User logout](https://fox.oplist.org/364155678e0)、[User login](https://fox.oplist.org/364155681e0)、[List directory contents](https://fox.oplist.org/364155732e0)、[Get file or directory info](https://fox.oplist.org/364155733e0)、[Get directory tree](https://fox.oplist.org/364155735e0)）
- 你还需要有一个**基本路径为`root`（根目录）的**账户。（欢迎提交PR帮忙适配基本路径不是`root`的账户。）
- 安装本软件。你可以前往[Release](https://github.com/Hollow-YK/OpenlistSyncer/releases)下载相应版本的最新安装包并安装。如果你不知道安装哪个版本，就直接下载并安装文件名为`OpenlistSyncer-0.0.1-app-release.apk`形式的安装包。

### 使用过程

1. 配置好Openlist地址并登录Openlist账号。注意，**仅支持基本路径为`root`（根目录）的账户**。
2. 配置好源路径（即要同步的Openlist路径），并选择本地路径。
3. 开始同步

### 自行编译

<details>

1. clone本仓库
2. 完成`flutter pub get`
3. 执行`flutter build apk --release`打包 APK ，或`flutter build apk --split-per-abi`为每个 abi 打包 APK

</details>

## 致谢

### 开源项目

- 使用了 [OpenList](https://github.com/OpenListTeam/OpenList) 的 API

还参考了一些开源Flutter项目的代码结构

### 其它

- 使用Flutter进行开发
- ~~`README.md`照抄了我的另一个仓库的README~~
- `README.md`参考了[MaaAssistantArknights](https://github.com/MaaAssistantArknights/MaaAssistantArknights/)
- `README.md`使用了[shields.io](https://shields.io/)、[contrib.rocks](https://contrib.rocks/)提供的内容

### 贡献/参与者

感谢所有参与到开发/测试中的朋友们(\*´▽｀)ノノ

~~好像只有我自己~~

[![Contributors](https://contrib.rocks/image?repo=Hollow-YK/Yunhu_MinecraftStatus_Bot&max=105&columns=15)](https://github.com/Hollow-YK/Yunhu_MinecraftStatus_Bot/graphs/contributors)

## 声明

- 本软件使用 [GNU Affero General Public License v3.0 only](https://spdx.org/licenses/AGPL-3.0-only.html) 开源。
- 本软件开源、免费，仅供学习交流使用。
- 免责声明：将此软件用于任何用途均与开发者无关，不对使用者的任何行为负责。

## 广告

如果觉得软件对你有帮助，帮忙点个 Star 吧！~（网页最上方右上角的小星星），这就是对我们最大的支持了！