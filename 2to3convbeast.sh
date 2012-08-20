#! /usr/bin/env bash

usage()
{
echo "python mass converter"
echo "usage: 2to3convbeast.sh <dir> <dir for patches> [filter]"
echo "filter removes path part"
echo "use the single files or the monster patch (condensed2_to_3_converter_beast.patch) via:"
echo "\"patch -Np0 -i <patchfile>\""
exit 1
}
if [ "$1" = "help" ] || [ "$1" = "--help" ] || [[ "$#" < "2" ]] ;then
  usage
fi
targetdir="$(echo "$1" | sed "s|/$||")"
patchdir="$(realpath "$2")/patches-$(basename "$targetdir")"
filter="$3"

mkdir -p "$patchdir"
mkdir -p "$patchdir"/splitted
rm "$patchdir"/"$(basename "$targetdir")"-condensed.patch 2> /dev/null

# echo $(ls "$targetdir"/*.py)
# exit 1

#loopbreaker=0

# crawler <crawldir> <prevsave>
crawler()
{
  local curtargetdir="$1"
  local prevsave="$2"
  local cursave="$prevsave/$(basename "$curtargetdir")"
  mkdir "$cursave" 2> /dev/null
  #local difftarget="$(echo $curtargetdir | sed -e "s|$targetdir||")"
  local difftarget="$curtargetdir"
  
  for curfile in $(basename -a "$curtargetdir"/*)
  do
    if [ -f "$curtargetdir"/"$curfile" ]; then
      echo "diff -u -r $difftarget/$curfile $difftarget/$curfile" > "$cursave"/"${curfile}.patch"
      2to3 "$curtargetdir"/"$curfile" >> "$cursave"/"${curfile}.patch" 2> /dev/null

      if [ "$(cat "$cursave"/"${curfile}.patch")" = "diff -u -r $difftarget/$curfile $difftarget/$curfile" ]; then
        rm "$cursave"/"${curfile}.patch"
      else
        sed -i -e "s|$filter||g" "$cursave"/"${curfile}.patch" 2> /dev/null
        cat "$cursave"/"${curfile}.patch" >> "$patchdir"/"$(basename "$targetdir")"-condensed.patch
      fi
    elif [ -d "$curtargetdir"/"$curfile" ]; then
      crawler "$curtargetdir"/"$curfile" "$cursave"
    fi
    
  done
  if [ "$(ls "$cursave")" = "" ]; then
    rmdir "$cursave"
  fi 

}

crawler "$targetdir" "$patchdir"/splitted

#for curfile in $(basename -a "$targetdir"/*)
#do
#  echo "diff -u -r $targetdir/$curfile $targetdir/$curfile" > "$patchdir"/splitted/"${curfile}.patch"
#  2to3 "$targetdir"/"$curfile" >> "$patchdir"/splitted/"${curfile}.patch" 2> /dev/null
#
#  if [ "$(cat "$patchdir"/splitted/"${curfile}.patch")" = "diff -u -r $targetdir/$curfile $targetdir/$curfile" ]; then
#    rm "$patchdir"/splitted/"${curfile}.patch"
#  else
#    cat "$patchdir"/splitted/"${curfile}.patch" >> "$patchdir"/"$(basename "$targetdir")"-condensed.patch
#  fi
#done
echo "patch generation complete. Generate sha512…"
sha512sum "$patchdir"/"$(basename "$targetdir")"-condensed.patch | sed -e "s/ .*$//" > "$patchdir"/"$(basename "$targetdir")"-condensed.sha512

echo "finished"
