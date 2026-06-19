
## After three feature-a commits

```text
* 409cf08 (HEAD -> feature-a) feat: add feature-a-2.txt
* ec7f606 feat: add feature-a-1.txt
* f87dcf7 feat: add app.conf
* a54cae7 (origin/main, main, feature-b) chore : initial commit
```



## Before creating feature-b

```text
* 409cf08 (feature-a) feat: add feature-a-2.txt
* ec7f606 feat: add feature-a-1.txt
* f87dcf7 feat: add app.conf
* a54cae7 (HEAD -> main, origin/main, feature-b) chore : initial commit
```

## After two feature-b commits

```text
* e0ff857 (HEAD -> feature-b) feat(b): fix feature 1
* 665f1f9 feat(b): change app version to B
| * 409cf08 (feature-a) feat: add feature-a-2.txt
| * ec7f606 feat: add feature-a-1.txt
| * f87dcf7 feat: add app.conf
|/  
* a54cae7 (origin/main, main) chore : initial commit
```

## Before rebasing feature-b onto feature-a

```text
* e0ff857 (HEAD -> feature-b) feat(b): fix feature 1
* 665f1f9 feat(b): change app version to B
| * 409cf08 (feature-a) feat: add feature-a-2.txt
| * ec7f606 feat: add feature-a-1.txt
| * f87dcf7 feat: add app.conf
|/  
* a54cae7 (origin/main, main) chore : initial commit
```

## After rebasing and resolving conflicts

```text
* cf6fb1a (HEAD -> feature-b) feat(b): fix feature 1
* 4a68856 feat(b): change app version to B
* 409cf08 (feature-a) feat: add feature-a-2.txt
* ec7f606 feat: add feature-a-1.txt
* f87dcf7 feat: add app.conf
* a54cae7 (origin/main, main) chore : initial commit
```

## Before creating hotfix

```text
* cf6fb1a (feature-b) feat(b): fix feature 1
* 4a68856 feat(b): change app version to B
* 409cf08 (feature-a) feat: add feature-a-2.txt
* ec7f606 feat: add feature-a-1.txt
* f87dcf7 feat: add app.conf
* a54cae7 (HEAD -> main, origin/main, hotfix) chore : initial commit
```

## After hotfix commit

```text
* a46e56d (HEAD -> hotfix) fix: apply critical hotfix
| * cf6fb1a (feature-b) feat(b): fix feature 1
| * 4a68856 feat(b): change app version to B
| * 409cf08 (feature-a) feat: add feature-a-2.txt
| * ec7f606 feat: add feature-a-1.txt
| * f87dcf7 feat: add app.conf
|/  
* a54cae7 (origin/main, main) chore : initial commit
```

## Before cherry-picking hotfix onto main

```text
* a46e56d (hotfix) fix: apply critical hotfix
| * cf6fb1a (feature-b) feat(b): fix feature 1
| * 4a68856 feat(b): change app version to B
| * 409cf08 (feature-a) feat: add feature-a-2.txt
| * ec7f606 feat: add feature-a-1.txt
| * f87dcf7 feat: add app.conf
|/  
* a54cae7 (HEAD -> main, origin/main) chore : initial commit
```

## After cherry-picking hotfix onto main

```text
* d288039 (HEAD -> main) fix: apply critical hotfix
| * a46e56d (hotfix) fix: apply critical hotfix
|/  
| * cf6fb1a (feature-b) feat(b): fix feature 1
| * 4a68856 feat(b): change app version to B
| * 409cf08 (feature-a) feat: add feature-a-2.txt
| * ec7f606 feat: add feature-a-1.txt
| * f87dcf7 feat: add app.conf
|/  
* a54cae7 (origin/main) chore : initial commit
```

## Before cherry-picking hotfix onto feature-a

```text
* d288039 (main) fix: apply critical hotfix
| * a46e56d (hotfix) fix: apply critical hotfix
|/  
| * cf6fb1a (feature-b) feat(b): fix feature 1
| * 4a68856 feat(b): change app version to B
| * 409cf08 (HEAD -> feature-a) feat: add feature-a-2.txt
| * ec7f606 feat: add feature-a-1.txt
| * f87dcf7 feat: add app.conf
|/  
* a54cae7 (origin/main) chore : initial commit
```

## After cherry-picking hotfix onto feature-a

```text
* 6d07a6b (HEAD -> feature-a) fix: apply critical hotfix
| * d288039 (main) fix: apply critical hotfix
| | * a46e56d (hotfix) fix: apply critical hotfix
| |/  
| | * cf6fb1a (feature-b) feat(b): fix feature 1
| | * 4a68856 feat(b): change app version to B
| |/  
|/|   
* | 409cf08 feat: add feature-a-2.txt
* | ec7f606 feat: add feature-a-1.txt
* | f87dcf7 feat: add app.conf
|/  
* a54cae7 (origin/main) chore : initial commit
```

## Before squashing feature-a commits

```text
* 6d07a6b (HEAD -> feature-a) fix: apply critical hotfix
| * d288039 (main) fix: apply critical hotfix
| | * a46e56d (hotfix) fix: apply critical hotfix
| |/  
| | * cf6fb1a (feature-b) feat(b): fix feature 1
| | * 4a68856 feat(b): change app version to B
| |/  
|/|   
* | 409cf08 feat: add feature-a-2.txt
* | ec7f606 feat: add feature-a-1.txt
* | f87dcf7 feat: add app.conf
|/  
* a54cae7 (origin/main) chore : initial commit
```

## After squashing feature-a commits

```text
* 6d07a6b (HEAD -> feature-a) fix: apply critical hotfix
| * d288039 (main) fix: apply critical hotfix
| | * a46e56d (hotfix) fix: apply critical hotfix
| |/  
| | * cf6fb1a (feature-b) feat(b): fix feature 1
| | * 4a68856 feat(b): change app version to B
| |/  
|/|   
* | 409cf08 feat: add feature-a-2.txt
* | ec7f606 feat: add feature-a-1.txt
* | f87dcf7 feat: add app.conf
|/  
* a54cae7 (origin/main) chore : initial commit
```

## After squashing feature-a commits

```text
* 191b059 (HEAD -> feature-a) fix: apply critical hotfix
* 0c70561 feat: add app.conf
| * d288039 (main) fix: apply critical hotfix
|/  
| * a46e56d (hotfix) fix: apply critical hotfix
|/  
| * cf6fb1a (feature-b) feat(b): fix feature 1
| * 4a68856 feat(b): change app version to B
| * 409cf08 feat: add feature-a-2.txt
| * ec7f606 feat: add feature-a-1.txt
| * f87dcf7 feat: add app.conf
|/  
* a54cae7 (origin/main) chore : initial commit
```
