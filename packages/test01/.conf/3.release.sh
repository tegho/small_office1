#!/bin/bash

current_dir=$(dirname $(realpath -ms $0))
package_dir=$(realpath "$current_dir/..")
package_name=$(basename "$package_dir")
source "$current_dir/vars" || exit 1
source "$current_dir/version" || exit 1

cd "$package_dir"
[ -d "$package_dir/debian" ] || exit 1

DEBEMAIL="no@mail.plz" DEBFULLNAME="admin" debchange --release ""

echo "###########"
echo "NEXT:"
echo "  4. Build"
