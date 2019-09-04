#!/usr/bin/env bash
temporary_commit=false
if ! git diff-index --quiet HEAD --; then
  temporary_commit=true
  git add .
  git commit -am "temporary commit"
  echo "Created temporary commit !"
fi

directory="$(
  cd "$(dirname "$0")" || exit
  pwd -P
)"

if hash wslpath 2>/dev/null; then
  directory="$(wslpath -w "$directory")"
fi

docker run --rm -v "$directory:/home/latex/" aergus/latex /bin/bash -c "cd /home/latex; shell_escape=t latexmk -pdf master.tex"
echo "$directory"

git add .
git rm --cached master.pdf
git reset --hard
echo "Cleaned working directory to last commit"

if [[ "$temporary_commit" == true ]]; then
  git reset HEAD^
  echo "Removed temporary commit"
fi

{
  open master.pdf 2>/dev/null && echo "Opend file."
} || echo -e "Couldn't open the file"
echo -e "Compilation was \033[1;32msuccessful"
