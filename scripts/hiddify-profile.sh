# Source hiddify CLI completion for interactive bash shells.
if [ -n "${BASH_VERSION:-}" ] && [[ $- == *i* ]] && [ -f /opt/hiddify-manager/scripts/hiddify-completion.bash ]; then
    . /opt/hiddify-manager/scripts/hiddify-completion.bash
fi
