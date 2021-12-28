#/bin/sh

INCVER="minor"
if [[ "$1x" != "x" ]]
then
    INCVER="$1"
fi

TMPORB=$(mktemp)
circleci orb pack src/ > ${TMPORB} \
    && circleci orb validate ${TMPORB} \
    && circleci orb publish increment ${TMPORB} startribune/rundeck $INCVER

rm -f ${TMPORB}