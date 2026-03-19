# stash.vim

**Persist unsaved buffers across Vim restarts. Continue where you left off.**

Sublime Text, Notepad++, Visual Studio Code and many other text editors don't give an error or ask to save or discard changes made in unsaved files when exiting, but saves them within a temporary location and restores on a next launch. This plugin brings similar functionality to Vim.

Note this is not the same as a swap file, because swap files are used to (mostly) recover your work when something's went wrong, while stash.vim is here to let you save and restore buffers when you like it.

This plugin is only responsible for buffer's state, such as content and undo history, and not a window state, such as current line, opened folds, etc., for which you can still use sessions.

## Requirements

Vim v8.1+ is supported. Tested on Vim v8.1.2424 and Neovim v0.11.6.

`:set hidden`. Currently plugin doesn't work without this option.

## Installation

Like any other plugin. If you don't know how to install plugins in Vim, [here](./docs/plugin-install.md) is a quick guide.

## Quick Start

Add to your vimrc:

```vim
let g:stash#directory = $HOME. '/.vim/stash'
let g:stash#default_filename_as_session = 1
let g:stash#name_unnamed = 1
command -bar -bang -nargs=? Mksession mksession<bang> <args> | StashPatchSession
command -bar -nargs=1 SourceSession StashPreExit | source <args>
autocmd ExitPre * StashPreExit
autocmd VimEnter * StashPostEnter
```

This setup will stash modified buffers when exiting Vim or switching sessions if using `:Mksession` for session creation and `:SourceSession` for switching. When entering Vim, buffers from the latest exit without session are restored. When sourcing a session, corresponding buffers are restored. You can replace `mksession` and `source` with your session manager's commands.

## Usage

##### Stash

```vim
Stash[!] [filename]
```

Stash all modified buffers. If `[!]` is specified, existing stash will be overwritten; an error will be thrown otherwise.

##### StashRestore

```vim
StashRestore[!] [filename]
```

Restore previously stashed buffers. If `[!]` is specified, nothing will happen if stash doesn't exist; an error will be thrown otherwise.

##### StashDelete

```vim
StashDelete [filename]
```

Delete a stash if it exists.

### Filename

##### directory

```vim
let g:stash#directory = ''
```

A directory where all stashes will be stored.

##### default_filename

```vim
let g:stash#default_filename = 'stash'
```

Filename for a stash when it's not provided as an argument.

---

So the full file path for a commands with `filename` argument will be `g:stash#directory/filename` when `g:stash#directory` is supplied, `filename` otherwise. When `filename` is optional and not provided, it will be `g:stash#directory/g:stash#default_filename` with `g:stash#directory` and `g:stash#default_filename` without.

### Session integration

stash.vim uses `v:this_session` to determine the latest saved or loaded session. This works with pure `:mksession` and should work with any session manager which uses `:mksession` under the hood. See `:help v:this_session`.

##### directory_as_session

```vim
let g:stash#directory_as_session = 0
```

When non-zero and `v:this_session` is present, the head of this path (i.e. directory where session file lies) will be used instead of [g:stash#directory](#directory).

##### default_filename_as_session

```vim
let g:stash#default_filename_as_session = 0
```

When non-zero and `v:this_session` is present, the tail of this path (i.e. name of session file) will be used instead of [g:stash#default_filename](#default_filename).

##### StashPatchSession

```vim
StashPatchSession [filename] [session_filename]
```

Patch session file provided by `[session_filename]` (`v:this_session` by default) so that stash `[filename]` will be restored when sourcing it and deleted after success. A session extra file and [injection file](#injectsessionbeforebuffers) will be written. If `[filename]` is equals to `-` it will be ignored.

A common use case is to write a wrapper command for `:mksession` (or your session manager's save command) which will execute this after session is written. Also setting [g:stash#name_unnamed](#name_unnamed) is recommended.

### Seamless exit and enter

##### StashPreExit

```vim
StashPreExit [filename]
StashPreExitSession [filename]
StashPreExitNoSession [filename]
```

A thing you probably want to do when exiting Vim. Run [:Stash](#stash) `[filename]`, then rewrite and patch a current session if it exists, then run [:StashRevertModifications](#stashrevertmodifications). `StashPreExitSession` runs only if `v:this_session` exists, and `StashPreExitNoSession` if it doesn't. This commands will make all buffers unmodified, so immediate exit by `:qa` becomes possible.

##### StashPostEnter

```vim
StashPostEnter [filename]
```

A thing you probably want to do when entering Vim. If stash `[filename]` exists, restores and deletes it. Ignores [g:stash#name_unnamed](#name_unnamed).

## Advanced

Read this if everything above didn't satisfied your needs and you need something more flexible.

### Revert modifications

##### StashRevertModifications

```vim
StashRevertModifications
```

For each modified buffer, undo to it's unmodified state, usually is the latest file save.

##### StashDeleteUnnamed

```vim
StashDeleteUnnamed[!]
```

Delete all unnamed buffers while trying to keep window layout by switching to other buffers. With `[!]` all buffers will be deleted even if this will cause some windows to close; otherwise one unnamed buffer may be kept if this is the only buffer left.

### Sessions

##### WriteSessionExtra

```vim
function stash#WriteSessionExtra(
   \ script,
   \ session_filename = v:this_session
\ )
function stash#WriteSessionExtraIfNotExist(
   \ script,
   \ session_filename = v:this_session
\ )
```

Write a `script` (list of strings, where each item is a line) to a session's extra file. If you don't know what it is, search `:help mksession` for a mention of `x.vim`.

You can write [:StashRestore](#stashrestore) and (optionally) [:StashDelete](#stashdelete) here so stash will be restored alongside of the session.

##### InjectSessionBeforeBuffers

```vim
function stash#InjectSessionBeforeBuffers(
   \ script,
   \ session_filename = v:this_session
\ )
```

Write a `script` (same format as for [stash#WriteSessionExtra](#writesessionextra)) in `<session_name>i.vim` (similarly to an extra file; "i" here means "injection"), then edit session script in such a way that this file will be sourced before any file is read, but after they are added. I.e. before `:edit`'s, `:enew`'s and so on, but after `:badd`'s.

If you do a [:Stash](#stash) before `:mksession` and then place [:StashRestore](#stashrestore) in your injection, you can preserve all the session stuff for a stashed buffers.

### Name unnamed buffers

##### name_unnamed
##### StashUnname

By default [:Stash](#stash) has no side-effects in Vim's state itself, so it doesn't set filenames for unnamed buffers. But sometimes it may be needed: for example, to preserve all stashed buffers's state in session, but Vim's `:mksession` doesn't take into account unnamed ones. For that there is an option:

```vim
let g:stash#name_unnamed = 0
```

When non-zero, [:Stash](#stash) and [:StashRestore](#stashrestore) will assign filenames for stashed and restored unnamed buffers to where they're actually was stashed. For making all such buffers unnamed again there is a command:

```vim
StashUnname
```

### Other options

##### buffer_filter

```vim
let g:stash#buffer_filter = #{buflisted: 1, bufmodified: 1}
```

Which buffers [:Stash](#stash) should save. The value is an argument for a `getbufinfo` function, see `:help getbufinfo`.

## TODO

- Command arguments completion.
- Function for injection right at the start of a session.
- `g:stash#name_unnamed`, `g:stash#dirname_as_session`, `g:stash#filename_as_session` as a commands arguments.
- `g:stash#buffer_filter` custom function.
- Support `:set nohidden`.
- Don't stash buffers which are going to be saved when `wq` triggers `ExitPre`.
- Add buffers to and remove them from existing stash.
- Lazy restore (buffer restores only when switching to it).
