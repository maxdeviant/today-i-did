# today-i-did

`today-i-did` is a small utility to help you compile a list of things you did today.

I built this to streamline my process for assembling async standup notes.

## How does it work?

I keep a `TODAY.md` file in my home directory that I use to list out the things I did today.

It looks something like this:

```md
## What are you working on?

- Added examples for Directory Sync operations https://github.com/workos/workos-rust/pull/70
- Renamed `VerifyFactor` to `VerifyChallenge` https://github.com/workos/workos-rust/pull/71

## What's up next?

- Continue work on Rust SDK
```

At the end of each day, I'll list out what I did, including links to PRs I've opened.

Then I run it through `today-i-did`:

```md
today-i-did ~/TODAY.md
```

This will write a formatted report to stdout:

```md
## What are you working on?

- Added examples for Directory Sync operations ([SDK-539](https://linear.app/workos/issue/SDK-539/add-examples-for-directory-sync-operations), [PR 70](https://github.com/workos/workos-rust/pull/70))
- Renamed `VerifyFactor` to `VerifyChallenge` ([SDK-540](https://linear.app/workos/issue/SDK-540/rename-verifyfactor-to-verifychallenge), [PR 71](https://github.com/workos/workos-rust/pull/71))

## What's up next?

- Continue work on Rust SDK
```

The output is then pasted into our daily standup [Thread](https://threads.com/).

## Features

Currently `today-i-did` supports linking to GitHub PRs and extracting any [Linear](https://linear.app/) issues referenced in those PRs.
