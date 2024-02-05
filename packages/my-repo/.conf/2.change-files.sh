#!/bin/bash

current_dir=$(dirname $(realpath -ms $0))
package_dir=$(realpath "$current_dir/..")
package_name=$(basename "$package_dir")
source "$current_dir/vars" || exit 1
source "$current_dir/version" || exit 1

project_root=$(realpath "$current_dir/../../..")
source "$project_root/vars" || exitinfo "Cannot include $project_root/vars"
pubkey_cmdline=$1

[ -z "$pubkey_cmdline" ] && [ -z "$secret_dir" ] && exitinfo "Cannot find puplic key. Check secret_dir in project_root/vars or provide a filename in command line"
pubkey=$(realpath -ms ${pubkey_cmdline:-"$project_root/$secret_dir/apt-repo/apt-repo.public"})
[ ! -f "$pubkey" ] || [ ! -r "$pubkey" ] && exitinfo "No access to keyfile $pubkey"

mkdir -p "$package_dir/etc/apt/sources.list.d/" "$package_dir/etc/apt/keyrings/" && \
  cp "$pubkey" "$package_dir/etc/apt/keyrings/my-repo.gpg" || exit 1

cat << EOF > "$package_dir/etc/apt/sources.list.d/my-repo.list"
deb [arch=amd64 signed-by=/etc/apt/keyrings/my-repo.gpg] http://tegho.github.io/small_office1/apt-repo stable main
EOF

echo "###########"
echo "NEXT:"
echo "  4. Build if it's a first version"
echo "  OR"
echo "  3. Update changelog if it's a next revision"
echo "  OR"
echo "  3. Update changelog if it's a next version"
echo "  OR"
echo "  3. Update changelog if it's a release"
