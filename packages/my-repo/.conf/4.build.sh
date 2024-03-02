#!/bin/bash

current_dir=$(dirname $(realpath -ms $0))
package_dir=$(realpath "$current_dir/..")
package_name=$(basename "$package_dir")
source "$current_dir/vars" || exit 1
source "$current_dir/version" || exit 1

cd "$package_dir"
[ -d "$package_dir/debian" ] || exit 1

#######################
#cp "$current_dir/postinst" "$current_dir/postrm" "$current_dir/prerm" "$package_dir/debian"
find . -type f,l | awk '(!/^\.\/debian\/*/&&!/^\.\/\.conf\/*/) {print substr($0,3),substr($0,2, match($0,"[^/]+$")-2 )}' > "$package_dir/debian/install"
#######################

debuild -i -us -uc -b
