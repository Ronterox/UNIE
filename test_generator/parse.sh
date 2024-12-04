if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path>"
    exit 1
fi

path="$*"

cp index.php "$path/" && cd "$path" || exit
php index.php > index.html && open index.html
