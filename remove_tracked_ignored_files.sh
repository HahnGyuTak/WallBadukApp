#!/bin/bash

# Git 루트 디렉토리로 이동
cd "$(git rev-parse --show-toplevel)"

# .gitignore에 명시된 경로 중 Git이 추적 중인 항목만 제거
echo "🔍 .gitignore에 있는 트래킹 중인 파일 제거 중..."

# .gitignore에 있는 파일 목록 가져오기
git ls-files -i --exclude-from=.gitignore | while read file; do
    if [ -e "$file" ]; then
        echo "🧹 제거: $file"
        git rm --cached "$file"
    fi
done

echo "✅ 완료. 이제 커밋 후 푸시하세요:"
echo "    git commit -m 'Remove tracked ignored files'"
echo "    git push"