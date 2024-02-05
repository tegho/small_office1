#!/bin/bash

current_dir=$(dirname $(realpath -ms $0))
package_dir=$(realpath "$current_dir/..")
package_name=$(basename "$package_dir")
source "$current_dir/vars" || exit 1
source "$current_dir/version" || exit 1

rm -rf "$package_dir/debian"
rm -f "${package_dir}_"*

cd "$package_dir"
DEBEMAIL="no@mail.plz" DEBFULLNAME="admin" dh_make --indep -f "$(dirname $package_dir)/empty.orig.tar.xz"  -p "${package_name}_0.1"
[ -d "$package_dir/debian" ] || exit 1

rm -f "$package_dir/debian/"README* "$package_dir/debian/"*.docs "$package_dir/debian/"*.ex
sed -i 's,^Homepage: .*,Homepage: '"$package_url"',' "$package_dir/debian/control"
sed -i 's,^Depends: .*,Depends: '"$package_depends"',' "$package_dir/debian/control"
sed -i 's,^Description: .*,Description: '"$package_short"',' "$package_dir/debian/control"
sed -n 's/^\(.*\)$/ \1/p' $current_dir/doc.txt | sed -i '/ <insert long description, indented with spaces>/{r /dev/stdin
d}' "$package_dir/debian/control"

echo "###########"
echo "NEXT:"
echo "  Check initial changelog"
echo "  THEN"
echo "  2. Add/change files"

