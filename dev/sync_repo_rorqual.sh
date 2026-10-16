# Guide for syncing repo with Rorqual remote cluster for heavy computation

# If on windows, run this in WSL (windows subsystem for linux)
# To set up WSL:
wsl --install
wsl --install -d Ubuntu 

# Follow prompts for installation you will end up in a linux shell
# You can exit using Ctrl-C
wsl --set-default Ubuntu
wsl # to open linux shell

# Set your username on windows
WINDOWS_USER=Egor
# And run
cp /mnt/c/Users/$WINDOWS_USER/.ssh/config ~/.ssh/config
chmod 600 ~/.ssh/config

## Edit these
USER_NAME=ekatko
PI_ACCOUNT=def-pollock
HOST=rorqual.alliancecan.ca
LOCAL_REPO=.
REPO_NAME=rQEB
REMOTE_DIR=links/projects/$PI_ACCOUNT/$USER_NAME/$REPO_NAME

# Log in via SSH at least once
ssh $USER_NAME@rorqual.alliancecan.ca

# Copy folder from your machine to Roqual cluster

rsync -avz --delete --info=progress2,name --stats \
  --exclude '.git' --exclude '*.rds' --exclude 'renv/library' \
  --exclude 'slurm-*.out' --exclude 'ollama-*.log' \
   --exclude '.Rproj.user/' --exclude './_maps' \
   --exclude "_QC_biodiv_docx" --exclude "./_private" \
  "$LOCAL_REPO"/ "$USER_NAME@$HOST:$REMOTE_DIR/"


# Retreive files from Roqual cluster
rsync -avz "$USER_NAME@$HOST:$REMOTE_DIR/" $LOCAL_REPO