## Edit these
USER_NAME=ekatko
PI_ACCOUNT=def-pollock
HOST=rorqual.alliancecan.ca
LOCAL_REPO=.
REPO_NAME=rQEB
REMOTE_DIR=links/projects/$PI_ACCOUNT/$USER_NAME/$REPO_NAME

## See dev/sync_repo_rorqual.sh for setup instructions

rsync -avzr --files-from="$LOCAL_REPO/P3_moteurs_changement/R/jaureguiberry2022/5_required_files.txt" --mkpath \
  -e "/usr/bin/ssh" \
  "$LOCAL_REPO"/ "$USER_NAME@$HOST:$REMOTE_DIR/"
  
ssh $USER_NAME@$HOST