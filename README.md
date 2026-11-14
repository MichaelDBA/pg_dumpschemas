# pg_dumpschemas
**pg_dumpschemas.sh** is a Bash utility that generates or executes parallel PostgreSQL schema-only dumps for a specified database. It supports PostgreSQL Custom and Directory archive formats and can either display the generated commands (DRYRUN) or execute them asynchronously (RUNIT). It excludes these schemas: pg_catalog, information_schema, and public.


(c) 2021-2026 SQLEXEC LLC
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
`DRYRUN | RUNIT`
<br/>
`CUSTOM | DIRECTORY`
<br/>
<br/>
In DRYRUN mode, pg dump commands are exported to STDOUT, but not actually run.  In RUNIT mode, they are immediately executed asynchronously in background.  DRYRUN mode is useful when you want to parse out the schema dumps and do them in smaller size batches, or globally change pg_dump parameters to do other things like instead of DDL just get data, or both.
<br/>
## Requirements
1. linux, pg_dump, psql
<br/>

## Examples
```pg_dumpschemas.sh localhost mydb mydbuser 5432 /my/output/dir/pg_dumpschemas RUNIT DIRECTORY```
<br/><br/>

<br/><br/>

