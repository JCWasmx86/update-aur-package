#!/bin/bash

set -o errexit -o pipefail -o nounset

NEW_RELEASE=${GITHUB_REF##*/${INPUT_TAG_VERSION_PREFIX:-v}}

export HOME=/home/builder

echo "::group::Setup"

echo "Getting AUR SSH Public keys"
ssh-keyscan aur.archlinux.org >>$HOME/.ssh/known_hosts

echo "Writing SSH Private keys to file"
echo -e "${INPUT_SSH_PRIVATE_KEY//_/\\n}" >$HOME/.ssh/aur

chmod 600 $HOME/.ssh/aur*

echo "Setting up Git"
git config --global user.name "$INPUT_COMMIT_USERNAME"
git config --global user.email "$INPUT_COMMIT_EMAIL"

REPO_URL="ssh://aur@aur.archlinux.org/${INPUT_PACKAGE_NAME}.git"

echo "Cloning repo"
cd /tmp
git clone "$REPO_URL"
cd "$INPUT_PACKAGE_NAME"
git switch master

echo "Setting version: ${NEW_RELEASE}"
sed -i "s/pkgver=.*$/pkgver=${NEW_RELEASE}/" PKGBUILD
sed -i "s/pkgrel=.*$/pkgrel=1/" PKGBUILD
updpkgsums

echo "::endgroup::Setup"

echo "::group::Build"

echo "Updating SRCINFO"
makepkg --printsrcinfo >.SRCINFO

echo "::endgroup::Build"

echo "::group::Publish"

echo "Publishing new version"
# Update aur
git add PKGBUILD .SRCINFO
git commit --allow-empty -m "Update to $NEW_RELEASE"
git push

echo "Publish Done"

echo "::endgroup::Publish"
