# SQL Firewall

https://docs.oracle.com/en/database/oracle/oracle-database/23/dbseg/using-sql-firewall.html

This new security feature allows you to define allow-list of common SQL that can
be run, and for any detect and rogue SQL statements to block and log. The firewall
allows the use of session context data (such as IP address) to block.

Set up (as DBA)

```sql
grant execute on dbms_sql_firewall to devver;
grant sql_firewall_viewer to devver;
grant sql_firewall_admin to devver;

create user app1 identified by app1;
grant connect,resource to app1;
```

Enable the firewall

```plsql
exec dbms_sql_firewall.enable;
```

Configure it to capture

```plsql
begin
  dbms_sql_firewall.create_capture (
    username         => 'APP1',
    -- top_level_onl = statements the schema directly runs; The inverse
    -- includes sql from plsql units being called
    top_level_only   => true,
    -- you can start this later by `dbms_sql_firewall.start_capture`
    start_capture    => true
  );
end;
/
```

Capture is just to record common SQL to get some patterns. You don't want this
permanently enabled. Once you have got a good baseline, `dbms_sql_firewall` has
a procedure to generate the allow list, and this is driven off the SQL that was
recorded in the capture phase.

Connect to the schema and run some stuff

```bash
podman exec -it db bash -c "sqlplus app1/app1@localhost:1521/freepdb1"

SQL> select table_name from user_tables;
SQL> create table x(id number);
SQL> exit
```

Reconnect to devver, and check for recorded SQL.

```
SELECT SQL_TEXT FROM DBA_SQL_FIREWALL_CAPTURE_LOGS WHERE USERNAME = 'APP1';
```

This shows three entries

```
SQL_TEXT
--------------------------------------------------------------------------------
SELECT TABLE_NAME FROM USER_TABLES
CREATE TABLE X (ID NUMBER)
SELECT DECODE (USER,:"SYS_B_0",XS_SYS_CONTEXT (:"SYS_B_1",:"SYS_B_2"),USER) FROM
 SYS.DUAL
```

Now stop the capture.

```
exec dbms_sql_firewall.stop_capture('APP1');
```

And generate the allow list.

```
exec dbms_sql_firewall.generate_allow_list ('APP1');
```

This data gets recorded and you can view what is allowed from the following views:

* dba_sql_firewall_allowed_ip_addr
* dba_sql_firewall_allowed_os_prog
* dba_sql_firewall_allowed_os_user
* dba_sql_firewall_allowed_sql

So in the capture period, it will record all this information and this then forms
what gets added into the allow list.

For the non-sql attributes, the firewall package includes procedures so you can
tweak what is allowed via the procedures:

* ADD_ALLOWED_CONTEXT
* DELETE_ALLOWED_CONTEXT

At this point we have our list but the firewall isn't in-force. We need to actually
enable the ruleset. We can enable just the SQL, just the connection context, or both.
This is controlled by the `enforce` attribute.

```
begin
  dbms_sql_firewall.enable_allow_list (
    username => 'APP1',
    enforce => dbms_sql_firewall.enforce_all,
    block => true
   );
end;
/
```

Once enabled, any SQL violating the rule will be blocked. For example:

```
SQL> select table_name from user_tables;

TABLE_NAME
--------------------------------------------------------------------------------
X

SQL> select object_name from user_objects;
select object_name from user_objects
                        *
ERROR at line 1:
ORA-47605: SQL Firewall violation
```

And all violations you can find logged in the view `dba_sql_firewall_violations`.

```
select 
  sql_text, 
  firewall_action, 
  ip_address, 
  cause, 
  occurred_at
from 
  dba_sql_firewall_violations 
where username = 'APP1';
```
