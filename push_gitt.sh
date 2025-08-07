#!/bin/bash
set -e  # Dừng script nếu có lỗi

# Màu sắc cho thông báo
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# === 1. Kiểm tra Git repo ===
if [ ! -d ".git" ]; then
  echo -e "${RED}⚠️  Đây không phải Git repository! Đang khởi tạo...${NC}"
  git init
  echo -e "${GREEN}✅ Đã khởi tạo Git repository!${NC}"
fi

# === 2. Gắn remote nếu chưa có ===
if ! git remote get-url origin &>/dev/null; then
  echo -e "${RED}⚠️  Chưa có remote origin!${NC}"
  read -p "🌐 Nhập URL GitHub (ví dụ: https://github.com/tenuser/tenrepo.git): " url
  if [[ -z "$url" ]]; then
    echo -e "${RED}❌ URL không được để trống!${NC}"
    exit 1
  fi
  git remote add origin "$url"
  # Kiểm tra quyền truy cập remote
  if ! git ls-remote "$url" &>/dev/null; then
    echo -e "${RED}❌ Remote không hợp lệ hoặc bạn không có quyền truy cập!${NC}"
    exit 1
  fi
  echo -e "${GREEN}✅ Đã gắn remote origin!${NC}"
fi

# === 3. Tạo .gitignore nếu chưa tồn tại ===
if [ ! -f ".gitignore" ]; then
  touch .gitignore
  echo -e "${GREEN}✅ Đã tạo file .gitignore!${NC}"
fi

# Thêm script này vào .gitignore nếu chưa có
if ! grep -qx "push_git.sh" .gitignore 2>/dev/null; then
  echo "push_git.sh" >> .gitignore
  echo -e "${GREEN}✅ Đã thêm push_git.sh vào .gitignore!${NC}"
fi

# Xóa script khỏi vùng theo dõi nếu đã add trước đó
git rm --cached push_git.sh 2>/dev/null || true

# === 4. Thêm tất cả file mới ===
git add .

# === 5. Nhập nội dung commit ===
read -p "📝 Nhập nội dung commit (mặc định: 'Update'): " message
message=${message:-Update}  # Mặc định nếu không nhập
echo -e "${GREEN}✅ Commit message: $message${NC}"

# Xác nhận trước khi commit
read -p "🤔 Xác nhận commit và push? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo -e "${RED}❌ Đã hủy thao tác!${NC}"
  exit 0
fi

git commit -m "$message"

# === 6. Đẩy lên GitHub ===
branch=$(git branch --show-current)
if [ -z "$branch" ]; then
  read -p "🌿 Nhập tên nhánh (mặc định: main): " branch
  branch=${branch:-main}
  git branch -M "$branch"
fi

# Thiết lập upstream và đẩy
if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
  if ! git push --set-upstream origin "$branch" 2>/dev/null; then
    echo -e "${RED}❌ Lỗi khi đẩy lên GitHub! Kiểm tra quyền truy cập hoặc kết nối.${NC}"
    exit 1
  fi
else
  if ! git push 2>/dev/null; then
    echo -e "${RED}❌ Lỗi khi đẩy lên GitHub! Kiểm tra quyền truy cập hoặc kết nối.${NC}"
    exit 1
  fi
fi

echo -e "${GREEN}✅ Đã đẩy code lên GitHub thành công!${NC}"
