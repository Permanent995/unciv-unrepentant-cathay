---
name: publish-mod
description: 将无悔华夏 Unciv 模组发布到 GitHub。自动检测变更、生成更新日志、智能判断版本号、创建 tag 和 Release。Use when 用户说"上传模组到github"、"发布新版本"、"更新模组并提醒我"、"release"等。
---

# 无悔华夏模组发布

## 触发词

- "上传模组到 GitHub"
- "发布新版本"
- "更新模组到 GitHub 并提醒我"
- "release 模组"
- "发布 vX.Y.Z"（手动指定版本号）

## 一次配置（仅需首次）

发布脚本需要 GitHub Personal Access Token 来创建 Release：
1. 打开 https://github.com/settings/tokens
2. 点 **Generate new token (classic)**
3. 勾选 `repo` 权限
4. 生成后复制 token（以 `ghp_` 开头）
5. 在此终端运行：
```bash
cd "c:/Users/drj13/Desktop/unciv4.16/mods/无悔华夏"
git config --local github.token "ghp_你的token"
```

## 工作流

执行发布脚本：
```bash
bash .claude/skills/publish-mod/scripts/publish.sh [手动版本号]
```

脚本会依次：
1. 扫描所有变更文件
2. 自动生成中文更新日志
3. 智能建议版本号（或使用你指定的版本）
4. 展示摘要，**等待你确认**
5. 确认后：commit → tag → push → 创建 GitHub Release
6. 打印 Release 链接

## 版本号规则

- 新增文明/单位/建筑 → **minor**（v1.1.0 → v1.2.0）
- 修复 bug/调整平衡 → **patch**（v1.1.0 → v1.1.1）
- 模组重构/不兼容改动 → **major**（v1.x.x → v2.0.0）
- 手动指定优先：说"发布 v2.0.0"就用 2.0.0

## 文件结构

```
无悔华夏/
├── .claude/skills/publish-mod/
│   ├── SKILL.md              ← 本文件
│   └── scripts/
│       └── publish.sh        ← 发布脚本
├── jsons/                    ← 模组数据
├── music/                    ← 音乐文件
├── Images/                   ← 图标资源
└── ...
```
