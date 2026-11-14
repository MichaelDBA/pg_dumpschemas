#!/bin/bash
# pg_dumpschemas.sh
# Bash script that dumps all the schema DDL for a particular database.  It does this in parallel as asynchronous background tasks.
# Modify QUERY to restrict or loosen restrictions for finding the schema list you want to export.
# example:
# pg_dumpschemas.sh localhost mydb mydbuser 5432 /apps/opt/postgres/sc DRYRUN

set -e
set -u

# Validate parameter count
if [ $# -ne 7 ]; then
    echo "ERROR: $(date) Invalid parameters. Expected 7, got $#."
    echo "Usage: pg_dumpschemas.sh <host> <dbname> <dbuser> <dbport> <target directory> DRYRUN|RUNIT CUSTOM|DIRECTORY"
    exit 1
fi

# Assign connection parameters
DBHOST=$1
DBNAME=$2
DBUSER=$3
DBPORT=$4
DMPDIR=$5

# Normalize and validate execution mode
ACTION=$(printf '%s' "$6" | tr '[:lower:]' '[:upper:]')

case "$ACTION" in
    DRYRUN)
        echo "DRYRUN mode"
        ;;
    RUNIT)
        echo "RUNIT mode"
        ;;
    *)
        echo "ERROR: $(date) Invalid action parameter: $6"
        echo "Expected DRYRUN or RUNIT."
        exit 1
        ;;
esac

# Normalize and validate dump format
DUMP_TYPE=$(printf '%s' "$7" | tr '[:lower:]' '[:upper:]')

case "$DUMP_TYPE" in
    CUSTOM)
        echo "CUSTOM dump format"
        ;;
    DIRECTORY)
        echo "DIRECTORY dump format"
        ;;
    *)
        echo "ERROR: $(date) Invalid dump format: $7"
        echo "Expected CUSTOM or DIRECTORY."
        exit 1
        ;;
esac

QUERY="SELECT n.nspname schemaname, pg_catalog.pg_get_userbyid(n.nspowner) schemaowner FROM pg_catalog.pg_namespace n WHERE pg_catalog.pg_get_userbyid(n.nspowner) not in ('rdsadmin') and  n.nspname !~ '^pg_' AND n.nspname not in ('information_schema', 'public') ORDER BY 1"
##results=`psql -h $DBHOST -U $DBUSER -p ${DBPORT} -c "${QUERY}" --field-separator '***' --record-separator='@@@' --single-transaction --set AUTOCOMMIT=off --set ON_ERROR_STOP=on --no-align -t  --quiet $DBNAME`
results=$(psql -X -h "$DBHOST" -U "$DBUSER" -p "$DBPORT" -c "$QUERY" --field-separator '***' --record-separator='@@@' --set ON_ERROR_STOP=on --no-align -t --quiet "$DBNAME" 2>/dev/null)

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
         if [ "$DUMP_TYPE" == "CUSTOM" ]; then
	     AFILE="${DMPDIR}/${afield}_ddlonly_${TODAY}.dat"
	     DUMP_OPTIONS="-Fc --clean --encoding UTF8"
	 else
	     AFILE="${DMPDIR}/${afield}_ddlonly_${TODAY}"
	     DUMP_OPTIONS="-Fd --clean --encoding UTF8"
	 fi
	 
	 if [ "$ACTION" == "DRYRUN" ]; then
	     if [ "$DUMP_TYPE" == "CUSTOM" ]; then
	         echo "nohup pg_dump -h \"$DBHOST\" -d \"$DBNAME\" -p \"$DBPORT\" -U \"$DBUSER\" --schema-only --schema \"$afield\" $DUMP_OPTIONS > \"$AFILE\" 2>&1 < /dev/null &"
	     else
	         echo "nohup pg_dump -h \"$DBHOST\" -d \"$DBNAME\" -p \"$DBPORT\" -U \"$DBUSER\" --schema-only --schema \"$afield\" $DUMP_OPTIONS --file \"$AFILE\" < /dev/null &"
	     fi
	 else
	     echo "Starting background $DUMP_TYPE dump for schema, ${afield}..."
	     if [ "$DUMP_TYPE" == "CUSTOM" ]; then
	         nohup pg_dump -h "$DBHOST" -d "$DBNAME" -p "$DBPORT" -U "$DBUSER" --schema-only --schema "$afield" $DUMP_OPTIONS > "$AFILE" 2>&1 < /dev/null &
	     else
	         nohup pg_dump -h "$DBHOST" -d "$DBNAME" -p "$DBPORT" -U "$DBUSER" --schema-only --schema "$afield" $DUMP_OPTIONS --file "$AFILE" < /dev/null &
	     fi
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
