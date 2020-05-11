# pg_dumpschemas
This is a bash script which does pg dumps in parallel for all schemas in a given database as linux background jobs.

(c) 2020 SQLEXEC LLC
<br/>
GNU V3 and MIT licenses are conveyed accordingly.
<br/>
Bugs can be reported @ michaeldba@sqlexec.com


## History
The first version of this program was created in 2020.  

## Parameters
Here are the parameters:
<br/>
`host name`
<br/>
`database name`
<br/>
`db user name`
<br/>
`db port` 
<br/>
`dump directory`
<br/>
`DRYRUN | RUN`      In DRYRUN mode, pg dump commands are exported to STDOUT.  In RUN mode, they are immediately execute in background
<br/>
<br/>

## Requirements
1. pg_dump, psql
<br/>

## Examples
pg_dumpschemas.sh localhost mydb mydbuser 5432 /apps/opt/postgres/sc DRYRUN
<br/><br/>

