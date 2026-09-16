# D-One CAD Native v0.01

这是从网页原型切换到“真正 iPad 原生 CAD 架构”的第一版工程。

## 这版能做什么

- SwiftUI 原生界面
- Metal 原生 3D 视口
- Objective-C++ / C++ CAD Core 边界
- C++ 生成 Box 几何（当前为可立即编译的原型 Core）
- Apple Pencil 点选 Face
- Apple Pencil 选面后上下拖动 = Push/Pull
- 单指旋转视角
- 双指平移 / 捏合缩放
- 选中 Face 高亮
- 精确输入 Box W / D / H
- 精确输入 Push/Pull 距离
- 已预留 OCCT B-Rep 接入层

## 为什么暂时没把 OCCT 强塞进去

当前 OCCT 源码里仍有 iOS 条件分支，但 2026 年当前官方公开构建说明列出的第一等目标是 Windows/Linux/macOS/Android/Web，没有把 iOS 列在支持平台列表里。也就是说 iOS 不是“不可能”，而是需要我们自己维护交叉编译/XCFramework 链。

因此 v0.01 先确保：

`SwiftUI -> Pencil/Touch -> Metal -> C API -> C++ Core`

整条架构在 Xcode/iPad 上成立。下一步只替换 C++ Core，UI 和输入层不推倒重来。

## 打开方式

需要 macOS + Xcode。

1. 解压。
2. 打开 `DOneCAD.xcodeproj`。
3. Signing & Capabilities 中选择你自己的 Team。
4. 选 iPad Simulator 或你的 iPad。
5. Run。

如果真机提示开发者签名问题，按 Xcode 的正常个人开发签名流程处理即可。

## 第一轮测试

1. 启动后看到 50 × 40 × 30 mm Box。
2. Apple Pencil 点顶部面，面会变黄色。
3. Pencil 上下拖动，选中面会 Push/Pull。
4. 单指拖动旋转；双指拖动平移；双指捏合缩放。
5. 右下角可直接输入精确尺寸和 Push/Pull 数值。

## 下一里程碑

- OCCT `TopoDS_Shape` 替换当前原型 Box 数据
- BRep tessellation -> Metal mesh cache
- STEP import/export
- Box/Cylinder/Sphere 真 B-Rep
- Face/Edge picking ID
- Extrude / Boolean / Fillet / Chamfer
- Undo/Redo command stack

之后再进入 Plasticity 风格的：Curve、Sweep、Loft、Shell、direct editing、参数化 Thread。

## Windows-only: build an IPA without a Mac

This repository now includes `.github/workflows/build-ipa.yml`. Upload the project contents to a GitHub repository, run **Actions → Build iPad IPA → Run workflow**, and download the `DOneCAD-iPad-unsigned-IPA` artifact. See `WINDOWS_BUILD_IPA.md` for the exact steps.
