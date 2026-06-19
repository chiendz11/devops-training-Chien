# Part B — Recover a Lost Commit with Git Reflog

## Mục tiêu

Tạo một commit, xóa commit khỏi lịch sử branch bằng `git reset --hard`, sau đó dùng `git reflog` để tìm SHA và khôi phục commit vào branch mới tên `recovered`.

## Điều kiện ban đầu

Thực hiện trong repo `git-lab` và bảo đảm working tree sạch:

```bash
git status
git switch main
```

## 1. Tạo branch cho bài lab

```bash
git switch -c reflog-lab
```

## 2. Tạo file và commit

```bash
echo "This commit will be recovered" > lost-file.txt

git add lost-file.txt
git commit -m "feat(reflog): add file to recover"
```

Kiểm tra commit vừa tạo:

```bash
git log --oneline -2
```

Kết quả gần giống:

```text
<lost-sha> feat(reflog): add file to recover
<previous-sha> ...
```

## 3. Xóa commit khỏi branch

```bash
git reset --hard HEAD~1
```

Kiểm tra lại:

```bash
git log --oneline -2
ls
```

Commit `feat(reflog): add file to recover` và file `lost-file.txt` không còn xuất hiện trên branch hiện tại.

## 4. Tìm commit bằng reflog

```bash
git reflog --oneline
```

Tìm dòng có message:

```text
commit: feat(reflog): add file to recover
```

Ví dụ:

```text
a1b2c3d HEAD@{1}: commit: feat(reflog): add file to recover
```

Trong ví dụ trên, SHA cần khôi phục là `a1b2c3d`.

## 5. Khôi phục commit vào branch `recovered`

Thay `<LOST_COMMIT_SHA>` bằng SHA tìm được từ `git reflog`:

```bash
git switch -c recovered <LOST_COMMIT_SHA>
```

Ví dụ:

```bash
git switch -c recovered a1b2c3d
```

## 6. Xác minh kết quả

```bash
git branch --show-current
git log --oneline --graph --all --decorate
cat lost-file.txt
```

Kết quả mong đợi:

- Branch hiện tại là `recovered`.
- Commit `feat(reflog): add file to recover` xuất hiện trở lại.
- File `lost-file.txt` được khôi phục.
- Branch `reflog-lab` vẫn trỏ về commit trước khi tạo `lost-file.txt`.

## 7. Push các branch lên GitHub

```bash
git push -u origin reflog-lab
git push -u origin recovered
```

## Giải thích

`git reset --hard HEAD~1` di chuyển branch về commit trước đó và xóa thay đổi khỏi working tree, nhưng Git vẫn lưu lịch sử di chuyển của `HEAD` trong reflog. Vì vậy, commit có thể được tìm lại bằng SHA và giữ lại bằng cách tạo một branch mới trỏ đến commit đó.

- Reflog chỉ tồn tại trong repository local và không được push lên GitHub.
