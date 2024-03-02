#!/bin/bash

current_dir=$(dirname $(realpath -ms $0))
package_dir=$(realpath "$current_dir/..")
package_name=$(basename "$package_dir")
source "$current_dir/vars" || exit 1
source "$current_dir/version" || exit 1

cp -f "$current_dir/links" "$package_dir/debian/${package_name}.links"

echo "###########"
echo "NEXT:"
echo "  4. Build if it's a first version"
echo "  OR"
echo "  3. Update changelog if it's a next revision"
echo "  OR"
echo "  3. Update changelog if it's a next version"
echo "  OR"
echo "  3. Update changelog if it's a release"
