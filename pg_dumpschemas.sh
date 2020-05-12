#!/bin/bash
# pg_dumpschemas.sh
# Bash script that dumps all the schema DDL for a particular database.  It does this in parallel as asynchronous background tasks.
# Modify QUERY to restrict or loosen restrictions for finding the schema list you want to export.
# example:
# pg_dumpschemas.sh localhost mydb mydbuser 5432 /apps/opt/postgres/sc FILEIT

set -e
set -u

args=$#
if [ $args -ne 6 ]; then
    echo "ERROR: `date`   Invalid parameters. Expected 6, got ${args}.  pg_dumpschemas.sh <host> <dbname> <dbuser> <dbport> <target directory> FILEIT | RUNIT." 
    exit 1
fi
action=`echo "${6}" | tr '[:upper:]' '[:lower:]'`
if [ "${action}" == "fileit" ]; then
    echo "FILEIT mode"
elif [ "${action}" == "runit" ]; then
    echo "RUNIT mode"
else
    echo "ERROR: `date`   Invalid action parameter. Expected FILEIT OR RUNIT, but got ${6}.  pg_dumpschemas.sh <host> <dbname> <dbuser> <dbport> <target directory> FILEIT | RUNIT." 
    exit 1
fi

PSQL=/usr/pgsql-12/bin/psql
PGDMP=/usr/pgsql-12/bin/pg_dump

DBHOST=$1
DBNAME=$2
DBUSER=$3
DBPORT=$4
DMPDIR=$5

QUERY="SELECT n.nspname schemaname, pg_catalog.pg_get_userbyid(n.nspowner) schemaowner FROM pg_catalog.pg_namespace n WHERE pg_catalog.pg_get_userbyid(n.nspowner) not in ('rdsadmin') and  n.nspname !~ '^pg_' AND n.nspname not in ('information_schema', 'public') ORDER BY 1"
results=`$PSQL -h $DBHOST -U $DBUSER -p ${DBPORT} -c "${QUERY}" --field-separator '***' --record-separator='@@@' --single-transaction --set AUTOCOMMIT=off --set ON_ERROR_STOP=on --no-align -t  --quiet $DBNAME`

TODAY=`date +%Y-%m-%d`

### echo "Results: ${results[0]}"
IFS='@@@' read -r -a array1 <<< "${results[0]}"
rows=0
for arow in "${array1[@]}"
do
  if [ "$arow" == "''" ] || [ -z "$arow" ]; then
     continue
  fi
  let "rows=rows+1"
  ### echo "$rows:$arow"
  IFS='***' read -r -a array2 <<< "${arow}"
  cols=0
  for afield in "${array2[@]}"
  do
     if [ "$afield" == "''" ] || [ -z "$afield" ]; then
        continue
     fi
     let "cols=cols+1"
     if [ "$cols" -eq 1 ]; then
         #echo "schema:=$afield"
		 AFILE="${DMPDIR}/${afield}_ddlonly_${TODAY}.sql"
         if [ "${action}" == "fileit" ]; then		 
	     echo "nohup ${PGDMP} -h $DBHOST -d ${DBNAME} -p ${DBPORT} -U ${DBUSER}  --schema-only --schema ${afield} --format plain --clean --encoding UTF8 > ${AFILE} &"
	 else
	     echo "starting background dump for schema, ${afield}..."
	     results=`nohup ${PGDMP} -h $DBHOST -d ${DBNAME} -p ${DBPORT} -U ${DBUSER}  --schema-only --schema ${afield} --format plain --clean --encoding UTF8 > ${AFILE} & `
	 fi		 
     elif [ "$cols" -eq 2 ]; then
         #echo "owner:=$afield"
	 :
     else
         echo "Unhandled column: ${cols} value:=$afield"
     fi    
	 sleep 0.1
  done
done
exit 0
