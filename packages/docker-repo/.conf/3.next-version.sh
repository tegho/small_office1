#!/bin/bash

current_dir=$(dirname $(realpath -ms $0))
package_dir=$(realpath "$current_dir/..")
package_name=$(basename "$package_dir")
source "$current_dir/vars" || exit 1
source "$current_dir/version" || exit 1

echo "Make sure you have changed version number"
echo "Current version is $package_ver"
read -p "Ctrl-C to exit or type OK to continue: " ans
if [ "${ans^^}" != "OK" ]; then
  echo "  Canceled"
  exit
fi

cd "$package_dir"
[ -d "$package_dir/debian" ] || exit 1

DEBEMAIL="no@mail.plz" DEBFULLNAME="admin" debchange -v "${package_ver}-1"

echo "###########"
echo "NEXT:"
echo "  3. Release"
echo "  OR"
echo "  4. Build"
