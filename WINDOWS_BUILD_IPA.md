# Windows 用户：生成 IPA

这个工程不能在 Windows 本地编译 iOS 二进制，因为 iPhoneOS SDK/Xcode 构建工具只由 Apple 的 macOS/Xcode 工具链提供。

本工程已经附带 GitHub Actions：`.github/workflows/build-ipa.yml`。

## 你只需要做一次

1. 在 GitHub 新建一个空仓库。
2. 把这个项目目录里的所有文件上传到仓库根目录（不是把 ZIP 当一个文件上传）。
3. 打开仓库的 **Actions**。
4. 选择 **Build iPad IPA**。
5. 点击 **Run workflow**。
6. 构建完成后，在该次运行页面底部 **Artifacts** 下载 `DOneCAD-iPad-unsigned-IPA`。
7. 解压 Artifact，得到 `DOneCAD-unsigned.ipa`。

## 在 Windows 安装到 iPad

`DOneCAD-unsigned.ipa` 是已经为真实 iPad 编译、但未使用你的 Apple 身份签名的 IPA。

在 Windows 上可用支持 Apple ID 个人签名的 sideload 工具重新签名并安装。安装时使用你自己的 Apple ID；不要把 Apple ID 密码、证书私钥或 provisioning profile 发给别人。

个人免费签名通常有有效期/设备限制；Apple Developer Program 的正式签名则适合更稳定的设备分发或 TestFlight。

## 重要

- 这个 IPA 对应的是 Native v0.01 原型：Metal 视口 + C++ Prototype Core。
- **还没有集成 OCCT**，所以它还不是完整 CAD。
- 最低目标系统当前设为 iPadOS 17.0。
