# # ssh ekatko@rorqual.alliancecan.ca
# # Edit these
USER_NAME=ekatko
PI_ACCOUNT=def-pollock
HOST=rorqual.alliancecan.ca
LOCAL_REPO=.
REPO_NAME=rQEB
REMOTE_DIR=~/links/projects/$PI_ACCOUNT/$USER_NAME/$REPO_NAME

rsync -avz --delete \
  --exclude '.git' --exclude '*.rds' --exclude 'renv/library' \
  --exclude 'results/' --exclude 'slurm-*.out' --exclude 'ollama-*.log' \
   --exclude '.Rproj.user/' \
  "$LOCAL_REPO"/ "$USER_NAME@$HOST:$REMOTE_DIR/"

rsync -avz "$USER_NAME@$HOST:$REMOTE_DIR/" .