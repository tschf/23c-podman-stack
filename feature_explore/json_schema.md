# JSON Schema

Docs link: <https://docs.oracle.com/en/database/oracle/oracle-database/23/adjsn/json-schema.html>

The JSON schema added into 23c allows you to make sure your JSON documents conform
to a standard, which to date hasn't been possible. This is based off the
<https://json-schema.org/> project.

At the table level, using the `json` data type you can add the validate clause
where you specify a string literal which is your JSON schema.

```sql
create table t (jdoc json validate '{"type" : "array"}');
create table t2 (jdoc json, check (jdoc is json validate '{"type" : "array"}'));
```

The view `USER_JSON_SCHEMA_COLUMNS` will report any columns that have a schema validation
in place.

..

From the PL/SQL side, there is a new package `DBMS_JSON_SCHEMA`. There is currently
no documentation that I can find for this package, but it is referenced in the
JSON developers guide so the presumption is it just hasn't made the cut yet. For
now, we have to rely on the data dictionary to see the function defintion(s).

```sql
select text
from all_source
where name = 'DBMS_JSON_SCHEMA'
order by line
```

This includes 2 functions which we can use to check:

* is_schema_valid - takes one argument only which is the JSON document and can be
in the form of `json` or `varchar2`.
* is_valid - takes 2 arguments, the json and the schema. They are set up that the
json and schema can be provided in one of: varhcar2, blob, bfile, clob or json.
There is 2 execution options - 1: signal to raise error, or 2: return some out
parameters which is a boolean of the result and a JSON doc of errors (this option
is only supported when working with the `json` data type).

At a basic level, you may want to make sure the JSON you store or reference is
an object.

```sql
declare
    is_valid_result pls_integer;
begin

    -- deliberately configured to fail my passing an array
    is_valid_result := 
        dbms_json_schema.is_valid(
            json_data => '[{"name": "Bob"}]',
            json_schema => '{"type" : "object"}',
            -- could be dbms_json_schema.raise_error and will raise ORA-40875
            raise_err => dbms_json_schema.raise_none
        );
    dbms_output.put_line(
        case is_valid_result
        when dbms_json_schema.result_invalid then 'INVALID'
        when dbms_json_schema.result_valid then 'VALID'
        end
    );
end;
/
```

## Generate schema
