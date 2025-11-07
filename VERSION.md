# 版本管理说明

## 版本号存储位置

**核心版本文件**: `config/version`

该文件是项目的**唯一版本真相源**，只包含一行版本号（例如：`3.1.1`）。

## 需要同步更新的文件

当更新版本号时，需要同步更新以下文件：

1. **config/version** - 核心版本文件（无前缀v）
   ```
   3.1.1
   ```

2. **install.sh** - 安装脚本
   ```bash
   last_version="v3.1.1"
   ```

3. **README.md** - 中文文档
   ```markdown
   **当前版本**: v3.1.1
   **更新日期**: 2025-11-08
   ```

   还需要在"版本更新"章节添加新版本的更新日志

4. **README.en.md** - 英文文档
   ```markdown
   **Current Version**: v3.1.1
   **Update Date**: 2025-11-08
   ```

5. **BUILD.md** - 构建文档
   ```markdown
   版本：v3.1.1
   ```

## 一键更新脚本

### Linux/macOS

使用 `update-version.sh` 脚本：

```bash
# 赋予执行权限
chmod +x update-version.sh

# 更新版本号（不要加v前缀）
./update-version.sh 3.1.2
```

该脚本会自动更新所有文件中的版本号和日期。

### Windows

使用 `update-version.bat` 脚本：

```cmd
update-version.bat 3.1.2
```

该脚本会更新 `config/version`，并提示你需要手动更新的其他文件。

或者使用 Git Bash：
```bash
bash update-version.sh 3.1.2
```

## 手动更新步骤

如果不使用自动脚本，请按以下步骤手动更新：

1. 更新 `config/version` 文件，写入新版本号（不带v前缀）
2. 搜索所有文件中的旧版本号，替换为新版本号
3. 更新日期为当前日期
4. 在 README.md 的"版本更新"章节添加新版本的更新日志

## 发布流程

1. **更新版本号**
   ```bash
   ./update-version.sh 3.1.2
   ```

2. **编辑更新日志**
   在 `README.md` 的"版本更新"章节添加新版本的内容

3. **提交更改**
   ```bash
   git add .
   git commit -m "发布 v3.1.2"
   ```

4. **创建标签**
   ```bash
   git tag -a v3.1.2 -m "Release v3.1.2"
   ```

5. **推送到远程**
   ```bash
   git push origin main
   git push origin v3.1.2
   ```

6. **GitHub/Gitee自动构建**
   - GitHub Actions 会自动构建所有平台并创建 Release
   - Gitee Go 流水线会自动构建所有平台并上传到 Release

## 版本号规范

采用语义化版本 (Semantic Versioning)：

- **主版本号** (MAJOR): 不兼容的 API 修改
- **次版本号** (MINOR): 向下兼容的功能性新增
- **修订号** (PATCH): 向下兼容的问题修正

示例：
- `3.0.0` - 大版本更新，可能有破坏性变更
- `3.1.0` - 新增功能，向下兼容
- `3.1.1` - Bug修复

## 注意事项

- ⚠️ **永远不要**在 `config/version` 文件中添加 `v` 前缀
- ⚠️ **务必同步更新**所有文件中的版本号
- ⚠️ **创建标签**时要加 `v` 前缀（例如：`v3.1.1`）
- ⚠️ **更新日志**要详细描述本次更新的内容

## 版本号自动读取

程序在运行时会自动读取 `config/version` 文件的内容作为版本号，无需硬编码。

Go代码示例：
```go
import (
    _ "embed"
)

//go:embed config/version
var version string
```

这样只需要更新 `config/version` 文件，程序就能自动获取新版本号。
