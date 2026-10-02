# Windows `.exe` 构建操作指南

这份文档用于让协作者在 Windows 电脑上把项目编译为
`MechanicsLearningLab.exe`。

## 1. Windows 电脑需要准备的环境

- Windows 10 或 Windows 11（64 位）；
- MATLAB R2025a，或与项目兼容的 MATLAB 版本；
- MATLAB Compiler；
- Git（用于克隆仓库）。

在 MATLAB 命令窗口运行以下命令，确认 Compiler 可用：

```matlab
ver
which compiler.build.standaloneWindowsApplication
```

`ver` 的输出中应包含 `MATLAB Compiler`，第二条命令应返回一个 MATLAB
文件路径。如果没有，请先通过 MathWorks 安装程序为现有 MATLAB 安装添加
MATLAB Compiler，并确认当前许可证包含该产品。

## 2. 克隆仓库

在 PowerShell 中运行：

```powershell
git clone <仓库链接>
cd <仓库文件夹名称>
```

也可以在 GitHub 网页点击 **Code > Download ZIP**，解压后进入该文件夹。

## 3. 先在 MATLAB 中验证源码

在 MATLAB 中将 Current Folder 切换到仓库根目录，然后依次运行：

```matlab
testRamp
testCollision
launchPhysicsTeachingApp
```

预期结果：

- 两个测试脚本均显示所有检查通过；
- 应用窗口可以打开；
- Ramp 和 Collision 模式均可点击 Run 并显示动画、图表和结果摘要。

完成检查后关闭应用窗口。

## 4. 构建 `.exe`

在仓库根目录的 MATLAB 命令窗口运行：

```matlab
results = buildWindowsExe;
```

脚本会：

1. 检查当前系统是否为 Windows；
2. 检查 MATLAB Compiler 是否可用；
3. 自动加入所有必需的源文件；
4. 生成名为 `MechanicsLearningLab.exe` 的 Windows 应用；
5. 在命令窗口打印输出目录和生成的文件列表。

输出目录格式为：

```text
build/windows_YYYYMMDD_HHMMSS/
```

## 5. 测试生成的程序

打开构建脚本打印的输出目录，双击：

```text
MechanicsLearningLab.exe
```

第一次启动可能需要等待 MATLAB Runtime 初始化。请至少测试：

- Ramp 默认参数；
- Perfectly Elastic collision 默认参数；
- 一个带摩擦的 Imperfectly Inelastic collision；
- Position Reached 或 Maximum Time 最终条件。

## 6. MATLAB Runtime

如果目标电脑没有安装 MATLAB，需要安装与构建版本匹配的 MATLAB
Runtime。例如，用 MATLAB R2025a 编译时，应使用 R2025a Runtime。

如果老师只要求上传 `.exe`，先确认老师的测试电脑是否已经安装对应 Runtime。
如果没有，应使用 MATLAB 的 Standalone Application Compiler 工具生成安装包：

```matlab
standaloneApplicationCompiler
```

在该工具中选择 **Standalone Windows Application**，并选择包含 MATLAB
Runtime 的安装包选项。

## 7. 交还给项目负责人

请提供：

- `MechanicsLearningLab.exe`；
- 构建时使用的 MATLAB 版本；
- 是否需要 MATLAB Runtime；
- Windows 上的测试结果；
- 如果 Canvas 允许 ZIP，建议将完整构建目录压缩后发送，避免遗漏配套文件。

请不要提交 `testRamp.m` 和 `testCollision.m` 生成的临时窗口截图，除非作业明确要求。
