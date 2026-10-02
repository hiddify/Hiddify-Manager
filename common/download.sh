#!/bin/bash
# for backward compatibility: v12 servers fetch <branch>/common/download.sh with the
# package mode (release/beta/dev) as the first argument. Forward to the same
# branch, since main keeps the old layout until v13 is released there.
case "${1:-release}" in
    beta) ref=beta ;;
    dev|develop) ref=dev ;;
    *) ref=main ;;
esac
url="https://raw.githubusercontent.com/hiddify/Hiddify-Manager/refs/heads/$ref/scripts/common/download.sh"
tmp=$(mktemp)
if ! curl -sLf -o "$tmp" "$url"; then
    echo "Failed to download $url" >&2
    rm -f "$tmp"
    exit 1
fi
# Run from a file (not bash -c) so $0 is not "bash", which download.sh treats as deprecated usage.
bash "$tmp" "$@"
code=$?
rm -f "$tmp"
exit $code
