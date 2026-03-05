# Recovering Dropped Changes via Git Dangling Commits

I recently hit a scenario where I mistakenly dropped test files after a branch cleanup. The files were staged and committed on an unintended branch, in an attempt to clean-up, I mistakenly dropped the commit. `git status` showed a clean tree, and the files were physically gone from the disk.

In Git, objects (commits, blobs, trees) aren't immediately deleted when a branch is removed. They become "dangling" until the garbage collector runs.

### 1. Identify the Loss

The working tree was clean, but `tests/unit/` was missing.

```bash
$ git log --oneline -5
1c8b1bb implement auth middleware
32ac0cd Merge pull request #25 
...

$ ls tests/unit/
ls: cannot access 'tests/unit/': No such file or directory

```

### 2. Scanning for Dangling Objects

Since the commit was no longer reachable via any branch or the reflog (if the reflog was also cleared), `git fsck` is the tool to verify the database integrity and find "lost" objects.

```bash
$ git fsck --lost-found
Checking object directories: 100% (256/256), done.
dangling commit b6c8f8efbb7d1ce8c53e04611ee4d8d40d52e092
dangling commit 25cc8b34b9346d9e084402d96cd2d1278f2338cd

```

### 3. Inspecting the Fragments

I used `git show` with `--stat` to find which dangling commit held the missing test files.

```bash
$ git show b6c8f8efbb7d1ce8c53e04611ee4d8d40d52e092 --stat
commit b6c8f8efbb7d1ce8c53e04611ee4d8d40d52e092
Author: nully0x <myemail@something.com>
Date:   Thu Mar 5 19:19:16 2026 +0100

    add testing

 tests/unit/middleware/authenticate.test.ts | 229 +++++++++++++++++++++++++++++
 tests/unit/services/jwt.test.ts            | 128 ++++++++++++++++
 2 files changed, 356 insertions(+)
```

### 4. Restoration

Since the object is a valid commit, I simply cherry-picked the hash back into the current branch.

```bash
$ git cherry-pick b6c8f8efbb7d1ce8c53e04611ee4d8d40d52e092
[feat-auth-middleware d31c34f] add testing
 2 files changed, 356 insertions(+)
 create mode 100644 tests/unit/middleware/authenticate.test.ts
 create mode 100644 tests/unit/services/jwt.test.ts

```

### Why this works

Git's storage model is additive. When you "delete" a commit, you are usually just deleting the **reference** (the branch pointer) to that commit. The actual commit object persists in `.git/objects` until:

1. `git gc` runs (usually triggered after a certain number of loose objects).
2. The object exceeds the `gc.pruneExpire` grace period (defaulting to 2 weeks for unreachable objects).

As long as you haven't run `git gc --prune=now`, your "deleted" work is likely still recoverable via `fsck`.
