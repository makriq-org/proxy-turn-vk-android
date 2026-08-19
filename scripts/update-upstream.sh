#!/usr/bin/env bash
set -euo pipefail

FORK_REPOSITORY="makriq-org/proxy-turn-vk-android"
FORK_BRANCH="master"
UPSTREAM_REPOSITORY="SpaceNeuroX/proxy-turn-vk-android"
UPSTREAM_BRANCH="master"
UPSTREAM_URL="https://github.com/${UPSTREAM_REPOSITORY}.git"

REPOSITORY_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPOSITORY_ROOT"

if ! command -v gh >/dev/null; then
  echo "Не найден GitHub CLI (gh)." >&2
  exit 1
fi
gh auth status --hostname github.com >/dev/null

if git remote get-url upstream >/dev/null 2>&1; then
  CONFIGURED_UPSTREAM="$(git remote get-url upstream)"
  case "$CONFIGURED_UPSTREAM" in
    "https://github.com/${UPSTREAM_REPOSITORY}.git"|"git@github.com:${UPSTREAM_REPOSITORY}.git") ;;
    *)
      echo "Remote upstream указывает на неожиданный адрес: $CONFIGURED_UPSTREAM" >&2
      exit 1
      ;;
  esac
else
  git remote add upstream "$UPSTREAM_URL"
fi

git fetch --no-tags origin "$FORK_BRANCH"
git fetch --no-tags upstream "$UPSTREAM_BRANCH"

FORK_SHA="$(git rev-parse "origin/$FORK_BRANCH")"
UPSTREAM_SHA="$(git rev-parse "upstream/$UPSTREAM_BRANCH")"
SHORT_SHA="$(git rev-parse --short=12 "$UPSTREAM_SHA")"
NEW_COMMITS="$(git rev-list --count "$UPSTREAM_SHA" --not "$FORK_SHA")"

if [ "$NEW_COMMITS" -eq 0 ]; then
  echo "Форк уже содержит все коммиты upstream/$UPSTREAM_BRANCH."
  exit 0
fi

if ! git merge-base "$UPSTREAM_SHA" "$FORK_SHA" >/dev/null; then
  echo "У форка и апстрима не найдена общая история." >&2
  exit 1
fi

VERSION_NAME="$(
  git show "$UPSTREAM_SHA:app/build.gradle.kts" |
    sed -n 's/.*versionName = "\([^"]*\)".*/\1/p' |
    head -n1
)"
SYNC_BRANCH="sync/upstream-$SHORT_SHA"

git push origin "$UPSTREAM_SHA:refs/heads/$SYNC_BRANCH"

EXISTING_PR="$(
  gh pr list \
    --repo "$FORK_REPOSITORY" \
    --state all \
    --head "$SYNC_BRANCH" \
    --json url \
    --jq '.[0].url // empty'
)"
if [ -n "$EXISTING_PR" ]; then
  echo "Pull request уже существует: $EXISTING_PR"
  exit 0
fi

TITLE="Обновить апстрим до $SHORT_SHA"
if [ -n "$VERSION_NAME" ]; then
  TITLE="Обновить апстрим до v${VERSION_NAME#v}"
fi

BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT
{
  echo "Обновление из \`$UPSTREAM_REPOSITORY\`."
  echo
  echo "- Ветка: \`$UPSTREAM_BRANCH\`"
  echo "- Коммит: \`$UPSTREAM_SHA\`"
  echo "- Новых upstream-коммитов: $NEW_COMMITS"
  echo
  echo "Для слияния используйте merge commit, чтобы сохранить отслеживание истории апстрима."
} > "$BODY_FILE"

gh pr create \
  --repo "$FORK_REPOSITORY" \
  --base "$FORK_BRANCH" \
  --head "$SYNC_BRANCH" \
  --title "$TITLE" \
  --body-file "$BODY_FILE"
