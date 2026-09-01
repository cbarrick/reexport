# Releasing

> [!TIP]
> The `release.zsh` script and GitHub Actions can be used to automate the
> release process.

This project maintains releases on both GitHub and crates.io. This doc describes
the release process and how the release pipeline is setup, circa the initial
2.0.0 release.


## Overview

As a release manager, you must complete these tasks:

1. Tag the commit being released,
2. Push the tag to the upstream remote,
3. Publish a release on GitHub, and
4. Publish the crate to crates.io.

The `release.zsh` script and GitHub Actions together handle most of that work.

First, `release.zsh` will verify that the working directory is clean and in a
publishable state. Then it will create a signed tag matching the version number
in Cargo.toml and push the tag to GitHub.

From there, a GitHub workflow will trigger to package the crate, sign an
attestation, and create a draft release on GitHub.

You must review this release carefully. Once published, releases are immutable.
When you are satisfied with the release, click "publish."

Once the release is published, a second workflow will trigger to publish the
crate to crates.io. This uses the [Trusted Publishing] mechanism provided by
crates.io to publish the crate without the use of long-lived API keys.

Continue reading to learn about more about the release process.

[Trusted Publishing]: https://crates.io/docs/trusted-publishing


## Prework

The following must be true before publishing a release:

- **The working directory is clean.** A dirty working directory may be hiding
  issues, like test failures, or may mean that some assets will be excluded from
  the release. Make sure that all work is committed and pushed to GitHub before
  continuing.

- **The release tag must agree with Cargo.toml.** The version tag that is used
  in the release should match the version in Cargo.toml, with a `v` prepended.
  For example, if Cargo.toml lists the version as `2.3.4-rc9`, then the
  corresponding release tag must be `v2.3.4-rc9`. The version string must be a
  semantic version.

- **A git tag for this version must not already exist.** A git tag indicates a
  release. If there is already a tag for this version, it has already been
  released. Update Cargo.toml to a new version.


## Step 1: Tag the Commit

The first step in the release process is to tag the release.

Before creating the tag, ensure that the working directory is clean, that you
are on the appropriate branch, that the current commit is pushed to the upstream
remote, and that it is passing all CI checks.

The tag should take the form `vX.Y.Z` where `X.Y.Z` is the same version listed
in Cargo.toml.

The tag should be signed using a PGP or SSH key associated with your GitHub
account.

The `release.zsh` script creates the tag and uploads it to the remote using
these commands, e.g. for a tag `v2.3.4`:

```shell
$ git tag v2.3.4 --sign --message="Release v2.3.4"
$ git push origin tag v2.3.4
```


## Step 2: Create the Release

Once the tag is pushed to GitHub, a workflow will trigger to create a new
draft release. The workflow will sign an attestation proving that the crate
was built from the same source in the repository.

That workflow is defined in `.github/workflows/release.yml`.

Alternatively, you can create the release by hand by following the steps below.
This process is highly discouraged because the resulting crate will not have an
attestation.

First, build the crate:

```shell
$ cargo package
```

The crate will be output to a path like:

```txt
./target/package/reexport-2.3.4.crate
```

Then create a new release draft with the `gh` CLI:

```shell
$ gh release create v2.3.4 ./target/package/reexport-2.3.4.crate \
  --title=v2.3.4 \
  --verify-tag \
  --generate-notes \
  --draft
```


## Step 3: Review and Publish to GitHub

The release draft can be found at
<https://github.com/cbarrick/reexport/releases>.

You must finalize the release before proceeding.

> [!IMPORTANT]
> **Review this draft carefully.** Releases are immutable once published.

> [!CAUTION]
> If you abandon a release, you should also delete the corresponding attestation
> at https://github.com/cbarrick/reexport/attestations.

Verify that the release contains the correct artifacts and update the release
notes as needed. Verify that the commit associated with the release is passing
all CI tests.

When you are satisfied with a release, mark it as published.


## Step 4: Publish to crates.io

Once the release is finalized, an action will trigger to publish the crate to
crates.io. This workflow uses the [Trusted Publishing] mechanism provided by
crates.io to publish the crate without the use of long-lived API keys.

That workflow is defined in `.github/workflows/publish.yml`.

Alternatively, you can publish the crate by hand by following the steps below.
This process is highly discouraged because it is unlikely that the resulting
crate will be compatible with the attestation generated in step 2.

To publish the crate manually, you will need to authenticate with crates.io. If
you haven't authenticated in the past 90 days, visit <https://crates.io/me> and
generate a new API token. At minimum, it must have the `publish-update` scope.
Then you can use that API token to authenticate:

```shell
$ cargo login
```

Next, double check that your working directory is clean and on the correct
commit, then you can publish the crate with:

```shell
$ cargo publish
```

[Trusted Publishing]: https://crates.io/docs/trusted-publishing


## Attestations

To prove that the crate was built from a checked-in source and workflow, the
release workflows will generate *attestations*. These are certificates, signed
by GitHub, that describes the crate and build process, including a hash of the
crate tarball, name of the workflow that performed the build, and the exact
commit hash it was built from.

You can view all attestations at
<https://github.com/cbarrick/reexport/attestations>.

For a given version on crates.io, you can download the crate and verify that it
was packaged from the public source at the corresponding tag using the following
command:

```shell
$ curl https://crates.io/api/v1/crates/reexport/2.0.0/download \
| gh attestation verify /dev/stdin --repo cbarrick/reexport --source-ref refs/tags/v2.0.0
```

Note that this only verifies that the tag pointed to the source of the crate
*at the time the crate was published*. If the tag is ever moved to a different
commit, the attestation check will continue to pass. Use the `--source-digest`
flag to verify the crate against a specific commit hash.


## Caveats

The `release.zsh` script is written in Zsh and will not work with Bash.
