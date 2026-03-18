# Targetor — Claude Code Remote Execution Instructions

This file tells Claude Code how to operate on a **remote embedded Linux device** using the Targetor infrastructure. When these instructions are active, all file I/O and command execution must go through the remote agent — not the local machine.

---

## Setup

### 1. Deploy the agent to the target (one-time)

```bash
scp agent.py protocol.py <USER>@<HOST>:~/
```

### 2. Set the target in your environment (or substitute values below)

```bash
export TARGETOR_HOST=<HOST>        # e.g. 192.168.1.100
export TARGETOR_USER=<USER>        # e.g. pi
export TARGETOR_KEY=~/.ssh/id_ed25519   # optional
```

### 3. Verify connectivity

```bash
python /data/sync/agents/targetor/client.py \
  --host $TARGETOR_HOST --user $TARGETOR_USER ping
```

---

## Instructions for Claude Code

> **All commands and file operations below target the remote device.**
> Do not run shell commands or access files locally unless explicitly asked.

### Running commands on the remote device

Instead of using the Bash tool directly, run commands through the Targetor client:

```bash
# Remote shell command (buffered)
python /data/sync/agents/targetor/client.py \
  --host $TARGETOR_HOST --user $TARGETOR_USER \
  exec "<COMMAND>"

# Remote shell command (streaming — use for long-running or verbose commands)
python /data/sync/agents/targetor/client.py \
  --host $TARGETOR_HOST --user $TARGETOR_USER \
  exec "<COMMAND>" --stream

# With working directory
python /data/sync/agents/targetor/client.py \
  --host $TARGETOR_HOST --user $TARGETOR_USER \
  exec "<COMMAND>" --cwd /remote/path

# With timeout
python /data/sync/agents/targetor/client.py \
  --host $TARGETOR_HOST --user $TARGETOR_USER \
  exec "<COMMAND>" --timeout 60
```

### Reading remote files

```bash
python /data/sync/agents/targetor/client.py \
  --host $TARGETOR_HOST --user $TARGETOR_USER \
  read /remote/path/to/file
```

### Writing remote files

```bash
# Write a string value
python /data/sync/agents/targetor/client.py \
  --host $TARGETOR_HOST --user $TARGETOR_USER \
  write /remote/path/to/file "content here"

# Pipe content (e.g. from a heredoc or local file)
cat local_file.txt | python /data/sync/agents/targetor/client.py \
  --host $TARGETOR_HOST --user $TARGETOR_USER \
  write /remote/path/to/file

# Append
python /data/sync/agents/targetor/client.py \
  --host $TARGETOR_HOST --user $TARGETOR_USER \
  write /remote/path/to/file "new line" --append
```

### Listing remote directories

```bash
python /data/sync/agents/targetor/client.py \
  --host $TARGETOR_HOST --user $TARGETOR_USER \
  ls /remote/path
```

### Checking the remote environment

```bash
python /data/sync/agents/targetor/client.py \
  --host $TARGETOR_HOST --user $TARGETOR_USER \
  env
```

---

## Tool mapping

When working on the remote device, substitute the standard Claude Code tools as follows:

| Instead of...                    | Use...                                      |
|----------------------------------|---------------------------------------------|
| `Bash` (run a shell command)     | `client.py exec "<cmd>"`                    |
| `Read` (read a file)             | `client.py read <path>`                     |
| `Glob` / `find` a file           | `client.py exec "find <path> -name <pat>"`  |
| `Grep` (search file content)     | `client.py exec "grep -r <pat> <path>"`     |
| `Write` (create/overwrite file)  | `client.py write <path> "<content>"`        |
| `Edit` (patch a file)            | Read → modify locally → write back          |

### Edit workflow for remote files

Since there is no native remote Edit tool, patch files with this pattern:

```
1. Read the remote file:
   client.py read /remote/file > /tmp/remote_file_local_copy

2. Apply edits to the local copy using the Edit tool on /tmp/remote_file_local_copy

3. Write it back:
   cat /tmp/remote_file_local_copy | client.py write /remote/file
```

Or in a single pipeline for small changes:

```bash
python /data/sync/agents/targetor/client.py \
  --host $TARGETOR_HOST --user $TARGETOR_USER \
  exec "sed -i 's/old/new/g' /remote/path/to/file"
```

---

## Using --local for testing without a real device

If no remote device is available, use `--local` to run the agent as a local subprocess. The interface is identical.

```bash
python /data/sync/agents/targetor/client.py --local exec "uname -a"
python /data/sync/agents/targetor/client.py --local ls /tmp
python /data/sync/agents/targetor/client.py --local env
```

---

## Optional: shorter alias

To avoid typing the full path repeatedly, set an alias at the start of a session:

```bash
alias remote="python /data/sync/agents/targetor/client.py --host $TARGETOR_HOST --user $TARGETOR_USER"

# Then use:
remote ping
remote exec "uname -a"
remote read /etc/os-release
remote ls /var/log
```

---

## Important rules for Claude Code

1. **Never assume a local file exists on the remote device.** Always use `client.py read` to fetch it first.
2. **Prefer `--stream` for commands that produce continuous output** (logs, builds, tests) so output appears incrementally.
3. **Use `--timeout`** for commands that might hang (e.g. package installs, network operations).
4. **Do not use the local `Bash` tool for things that should happen on the target.** The whole point of this setup is that the embedded device is the execution environment.
5. **The agent is stateless between requests** — environment variables set in one `exec` call do not persist to the next. Use `--cwd` for directory context, and chain commands with `&&` when order matters.
