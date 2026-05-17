# 新锐鲁班工匠 - Revit to WebAR

将 Revit 建筑模型一键转化为 AR 展示，扫码即可在手机浏览器中查看。

## 目录结构

```
webar-revit/
├── index.html         ← 主页面（所有功能已内置）
├── assets/
│   └── model.glb      ← ← 放你从 Revit 导出的模型
└── README.md
```

## 快速开始（3 步）

### 1. 安装工具

| 工具 | 用途 | 下载地址 |
|------|------|---------|
| VS Code | 可选，编辑文件 | code.visualstudio.com |
| Node.js | 启动本地服务器 | nodejs.org (LTS 版) |
| ngrok | 让手机访问本机 | ngrok.com (注册免费账号) |

### 2. Revit 导出模型

**推荐插件：Leia（免费，MIT 开源）**
- Autodesk App Store 搜索 "Leia glTF" 安装
- 也可用国产付费插件 **Revit2Glft**

操作：
1. 打开 Revit 建筑模型，切换到 **3D 视图**
2. 关闭不需要显示的构件（管线、标注、结构层等）
3. 点击 Leia 插件 → 导出为 **GLB 格式**
4. 重命名为 `model.glb`，放入 `assets/` 文件夹
5. 可选：用 https://polyforge.xyz 在线压缩减小文件体积

> 注意：如果模型导出后纹理丢失或发黑，尝试在 Leia 设置中勾选 "Export Materials"。

### 3. 启动测试

在项目目录打开终端，执行：

```bash
# 启动 HTTP 服务器
npx http-server . -p 8080

# 另开一个终端，用 ngrok 映射到公网
ngrok http 8080
```

ngrok 会输出 `https://xxxx.ngrok.io` 地址，手机扫码打开。

---

## AR 功能说明

| 模式 | 说明 | 支持设备 |
|------|------|---------|
| **WebXR AR** | 模型直接出现在真实环境中，可以走动环绕查看 | 安卓 Chrome (ARCore) |
| **Scene Viewer** | 调用 Google 3D 查看器，支持地面放置 | 安卓全系 |
| **Quick Look** | 苹果原生 AR 查看器 | iPhone (iOS 12+) |

页面加载后：
1. 自动播放品牌展示 + 四步流程动画（约 7 秒）
2. 进入 3D 模型视图，可直接旋转缩放查看
3. 点击 **"在你空间中查看"** 按钮 → 进入 AR 模式 → 模型出现在真实地面

---

## 快速迭代

```
Revit 改模型 → 点 Leia 重新导出 GLB → 覆盖 assets/model.glb
                                          ↓
                               手机浏览器刷新页面
                                          ↓
                               立刻看到新模型
```

全程约 **1-2 分钟**。

---

## 部署上线

完成测试后，可用 GitHub Pages 永久部署：

1. GitHub 创建仓库 → 上传本项目（包括 `assets/model.glb`）
2. 仓库 Settings → Pages → 选择 main 分支
3. 等待生成网址 → 用二维码生成器制作二维码

---

## 常见问题

**Q: 点 AR 按钮后没反应？**
A: 手机需要支持 ARCore (安卓) 或 ARKit (苹果)。老机型可能不兼容。

**Q: 模型加载不出来 / 白屏？**
A: 检查 F12 控制台是否有 404 错误。确认 `assets/model.glb` 文件存在且路径正确。

**Q: 手机扫码显示黑屏？**
A: 浏览器需要 HTTPS 才能调用 AR。ngrok 会自动提供 HTTPS，直接访问 HTTP 地址不行。

**Q: 模型太大加载慢？**
A: 用 https://polyforge.xyz 压缩 GLB。目标控制在 5-20MB。

**Q: 需要联网吗？**
A: 首次加载需要下载模型。之后浏览器会缓存。

---

新锐鲁班工匠 © 2026
