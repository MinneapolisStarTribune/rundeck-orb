#/bin/sh

TMPORB=$(mktemp)
circleci orb pack src/ > ${TMPORB} \
    && circleci orb validate ${TMPORB} \
    && circleci orb publish ${TMPORB} startribune/rundeck@dev:init
rm -f ${TMPORB}