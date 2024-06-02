# Skipping Ubuntu system-wide compinit
# https://gist.github.com/ctechols/ca1035271ad134841284?permalink_comment_id=3401477#gistcomment-3401477
if [[ -f /etc/os-release ]] && [[ "$(awk -F= '/^NAME/{print $2}' /etc/os-release)" == *"Ubuntu"* ]]; then
    set skip_global_compinit 1
fi