#!/bin/bash
# ============================================================
# 无悔华夏 · Unrepentant Cathay — 发布脚本
# 用法: bash publish.sh [手动版本号]
# 示例: bash publish.sh          # 自动判断版本
#       bash publish.sh v1.2.0   # 手动指定版本
# ============================================================

# set -e commented out: git commands often return non-zero
# for benign reasons (no tags, network flaky, etc.)

# ── 配置 ──
MOD_DIR="c:/Users/drj13/Desktop/unciv4.16/mods/无悔华夏"
REPO="Permanent995/unciv-unrepentant-cathay"
REPO_URL="https://github.com/$REPO"
MANUAL_VERSION="${1:-}"

cd "$MOD_DIR"

# ── 颜色 ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD}  无悔华夏 · Unrepentant Cathay 发布${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""

# ── 1. 检查状态 ──
echo -e "${BLUE}[1/7]${NC} 检查仓库状态..."

if [ -z "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠ 没有检测到任何变更，退出。${NC}"
    exit 0
fi

# ── 2. 分析变更 ──
echo -e "${BLUE}[2/7]${NC} 分析变更文件..."

git fetch --tags --quiet 2>/dev/null || true

STAGED=$(git diff --cached --name-only 2>/dev/null || echo "")
UNSTAGED=$(git diff --name-only 2>/dev/null || echo "")
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null || echo "")
ALL_CHANGES=$(echo -e "$STAGED\n$UNSTAGED\n$UNTRACKED" | sort -u | grep -v '^$' || true)

if [ -z "$ALL_CHANGES" ]; then
    echo -e "${YELLOW}⚠ 没有检测到文件变更，退出。${NC}"
    exit 0
fi

# 统计
NEW_FILES=(); MOD_FILES=(); DEL_FILES=()
JSON_FILES=(); IMG_FILES=(); MUSIC_FILES=(); DOC_FILES=(); OTHER_FILES=()

while IFS= read -r f; do
    [ -z "$f" ] && continue
    if echo "$UNTRACKED" | grep -qF "$f" 2>/dev/null; then
        NEW_FILES+=("$f")
    elif [ ! -f "$f" ]; then
        DEL_FILES+=("$f")
    else
        MOD_FILES+=("$f")
    fi

    case "$f" in
        jsons/*.json)          JSON_FILES+=("$f") ;;
        Images/*.png|Images/**/*.png) IMG_FILES+=("$f") ;;
        music/*.mp3|music/*.ogg)      MUSIC_FILES+=("$f") ;;
        *.md|README*|credits*)        DOC_FILES+=("$f") ;;
        translations/*)               JSON_FILES+=("$f") ;;
        *)                      OTHER_FILES+=("$f") ;;
    esac
done <<< "$ALL_CHANGES"

TOTAL=${#ALL_CHANGES[@]}

# ── 3. 生成更新日志 ──
echo -e "${BLUE}[3/7]${NC} 生成更新日志..."

CHANGELOG=""

# 新增文明
NEW_NATIONS=$(for f in "${NEW_FILES[@]}" "${JSON_FILES[@]}"; do
    echo "$f" | grep -q "Nations.json" && echo "$f"
done)
if [ -n "$NEW_NATIONS" ] || echo "${MOD_FILES[@]}" | grep -q "Nations.json"; then
    CHANGELOG+="- 🏯 新增/更新文明数据（Nations.json）"$'\n'
fi

# 新增单位
if echo "${ALL_CHANGES}" | grep -q "Units.json"; then
    CHANGELOG+="- ⚔️ 新增/更新单位（Units.json）"$'\n'
fi

# 新增建筑
if echo "${ALL_CHANGES}" | grep -q "Buildings.json"; then
    CHANGELOG+="- 🏛️ 新增/更新建筑（Buildings.json）"$'\n'
fi

# 改进设施
if echo "${ALL_CHANGES}" | grep -q "TileImprovements.json"; then
    CHANGELOG+="- 🏗️ 新增/更新改良设施（TileImprovements.json）"$'\n'
fi

# 资源
if echo "${ALL_CHANGES}" | grep -q "TileResources.json"; then
    CHANGELOG+="- 💎 新增/更新资源（TileResources.json）"$'\n'
fi

# 晋升
if echo "${ALL_CHANGES}" | grep -q "UnitPromotions.json"; then
    CHANGELOG+="- 🎖️ 新增/更新单位晋升（UnitPromotions.json）"$'\n'
fi

# 图标
if [ ${#IMG_FILES[@]} -gt 0 ]; then
    CHANGELOG+="- 🎨 新增/更新图标（${#IMG_FILES[@]} 个文件）"$'\n'
fi

# 音乐
if [ ${#MUSIC_FILES[@]} -gt 0 ]; then
    CHANGELOG+="- 🎵 新增/更新音乐（${#MUSIC_FILES[@]} 个文件）"$'\n'
fi

# 翻译
TRANSLATION_FILES=$(echo "${ALL_CHANGES}" | grep "translations/" || true)
if [ -n "$TRANSLATION_FILES" ]; then
    CHANGELOG+="- 🌐 更新翻译"$'\n'
fi

# 文档
if [ ${#DOC_FILES[@]} -gt 0 ]; then
    CHANGELOG+="- 📝 更新文档"$'\n'
fi

# 修复（默认归类）
if echo "${ALL_CHANGES}" | grep -qE "ModOptions|\.gitignore|game\.atlas"; then
    CHANGELOG+="- 🔧 修复/优化配置"$'\n'
fi

# 未分类
if echo "${ALL_CHANGES}" | grep -qE "jsons/" && [ -z "$(echo "$CHANGELOG" | grep 'jsons')" ]; then
    CHANGELOG+="- 📦 更新 JSON 数据"$'\n'
fi

if [ -z "$CHANGELOG" ]; then
    CHANGELOG="- 更新模组文件"$'\n'
fi

# ── 4. 版本号 ──
echo -e "${BLUE}[4/7]${NC} 确定版本号..."

# 获取最新 tag
LATEST_TAG=$(git tag --sort=-v:refname 2>/dev/null | grep -E '^v[0-9]' | head -1 || echo "v0.0.0")
if [ -z "$LATEST_TAG" ]; then LATEST_TAG="v0.0.0"; fi
MAJOR=$(echo "$LATEST_TAG" | sed 's/v//' | cut -d. -f1)
MINOR=$(echo "$LATEST_TAG" | sed 's/v//' | cut -d. -f2)
PATCH=$(echo "$LATEST_TAG" | sed 's/v//' | cut -d. -f3)
[ -z "$MAJOR" ] && MAJOR=0
[ -z "$MINOR" ] && MINOR=0
[ -z "$PATCH" ] && PATCH=0

if [ -n "$MANUAL_VERSION" ]; then
    NEW_VERSION="$MANUAL_VERSION"
    NEW_VERSION="${NEW_VERSION#v}"
    echo -e "  手动指定: ${GREEN}v$NEW_VERSION${NC}"
else
    # 自动判断 bump 类型
    BUMP="patch"  # 默认小补丁
    if echo "${ALL_CHANGES}" | grep -qE "Nations.json|Units.json|Buildings.json"; then
        BUMP="minor"  # 新增内容 = 次版本
    fi
    if [ ${#NEW_FILES[@]} -ge 5 ] && echo "${ALL_CHANGES}" | grep -q "jsons/"; then
        BUMP="minor"
    fi
    # 大量删除或重构
    if [ ${#DEL_FILES[@]} -gt 10 ]; then
        BUMP="major"
    fi

    case "$BUMP" in
        major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
        minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
        patch) PATCH=$((PATCH + 1)) ;;
    esac
    NEW_VERSION="$MAJOR.$MINOR.$PATCH"
    echo -e "  自动判断: ${GREEN}v$NEW_VERSION${NC} (bump: $BUMP, 上一版: $LATEST_TAG)"
fi

# ── 5. 确认 ──
echo ""
echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD}  发布预览${NC}"
echo -e "${BOLD}========================================${NC}"
echo -e "  版本: ${GREEN}v$NEW_VERSION${NC}"
echo -e "  文件: ${TOTAL} 个变更"
echo ""
echo -e "  变更文件:"
while IFS= read -r f; do
    [ -z "$f" ] && continue
    echo -e "    ${YELLOW}$f${NC}"
done <<< "$ALL_CHANGES"
echo ""
echo -e "${BOLD}  更新日志:${NC}"
echo -e "$CHANGELOG"
echo ""
echo -e "${BOLD}========================================${NC}"

echo -n "确认发布 v$NEW_VERSION? [y/N]: "
read -r CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${RED}已取消。${NC}"
    exit 0
fi

# ── 6. 提交与推送 ──
echo ""
echo -e "${BLUE}[5/7]${NC} 提交变更..."

git add -A
COMMIT_MSG="v$NEW_VERSION: 无悔华夏模组更新"
git commit -m "$COMMIT_MSG" -m "$CHANGELOG" 2>/dev/null || {
    echo -e "${YELLOW}⚠ 没有需要 commit 的内容，跳过。${NC}"
}

echo -e "${BLUE}[6/7]${NC} 推送代码..."

# 尝试 push，网络不通时重试
RETRIES=3
for i in $(seq 1 $RETRIES); do
    if git push 2>/dev/null; then
        break
    else
        if [ "$i" -lt "$RETRIES" ]; then
            echo -e "${YELLOW}  推送失败，重试 ($i/$RETRIES)...${NC}"
            sleep 5
        else
            echo -e "${YELLOW}  ⚠ 推送可能失败，网络不稳定。稍后手动 push。${NC}"
        fi
    fi
done

# ── 7. Tag 与 Release ──
echo -e "${BLUE}[7/7]${NC} 创建 Tag 与 Release..."

TAG="v$NEW_VERSION"

# 检查 tag 是否存在
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo -e "${YELLOW}  Tag $TAG 已存在，删除旧的...${NC}"
    git tag -d "$TAG" 2>/dev/null || true
    git push origin ":refs/tags/$TAG" 2>/dev/null || true
fi

git tag -a "$TAG" -m "无悔华夏 $TAG" -m "$CHANGELOG"
git push origin "$TAG" 2>/dev/null || true

# 创建 GitHub Release
TOKEN=$(git config --local github.token 2>/dev/null || echo "")
RELEASE_BODY="## 无悔华夏 · Unrepentant Cathay — $TAG

$CHANGELOG

---
📦 [下载 ZIP]($REPO_URL/archive/refs/tags/$TAG.zip)
"

if [ -n "$TOKEN" ]; then
    RELEASE_JSON=$(cat <<EOF
{
  "tag_name": "$TAG",
  "name": "无悔华夏 $TAG",
  "body": $(echo "$RELEASE_BODY" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null || echo "\"$RELEASE_BODY\""),
  "draft": false,
  "prerelease": false
}
EOF
)
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: token $TOKEN" \
        -H "Accept: application/vnd.github+json" \
        -H "Content-Type: application/json" \
        -d "$RELEASE_JSON" \
        "https://api.github.com/repos/$REPO/releases" 2>/dev/null || echo "")

    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    if [ "$HTTP_CODE" = "201" ]; then
        RELEASE_URL="$REPO_URL/releases/tag/$TAG"
        echo -e "${GREEN}✅ Release 创建成功${NC}"
    else
        echo -e "${YELLOW}⚠ GitHub API 返回 $HTTP_CODE，Release 可能未创建${NC}"
        RELEASE_URL="$REPO_URL/releases/new?tag=$TAG"
    fi
else
    echo -e "${YELLOW}⚠ 未配置 GitHub Token，请手动创建 Release:${NC}"
    echo -e "  $REPO_URL/releases/new?tag=$TAG"
    RELEASE_URL="$REPO_URL/releases/new?tag=$TAG"
fi

# ── 完成 ──
echo ""
echo -e "${BOLD}========================================${NC}"
echo -e "${GREEN}${BOLD}  🎉 发布完成!${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""
echo -e "  版本: ${GREEN}$TAG${NC}"
echo -e "  仓库: $REPO_URL"
echo -e "  Release: $RELEASE_URL"
echo ""
echo -e "${YELLOW}⚠ 请检查以上链接确认发布无误。${NC}"
