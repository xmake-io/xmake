

cd "$1"
rm actions core includes languages modules platforms plugins repository rules scripts templates themes -rf
cp "$2" "$1/.." -rf