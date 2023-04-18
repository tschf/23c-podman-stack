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

## Schema Design

You can use the `json_dataguide` SQL function on order to get a starting point
for your schema. The docs highlight that using this structure usually isn't suitable
for using as your schema, but serves as a good mechanism to get your starting point.

```sql
select  
  json_dataguide(
    '{
  "name": "Bob",
  "on_vacation": false,
  "salary": 200.50,
  "manager": "KING"
}', 
    dbms_json.format_hierarchical, 
    dbms_json.pretty
  )
from 
  emp_schema;
```

Note that this function includes some Oracle specific fields that describe the data.
These being with `o:` and one example is `o:length` which describes the length
of a given field.

With our structure, removing the `o:` fields, we end up with the following:

```json
{
  "type" : "object",
  "properties" :
  {
    "name" : {"type" : "string"},
    "salary" : {"type" : "number"},
    "manager" : {"type" : "string"},
    "on_vacation" : {"type" : "boolean"}
  }
}
```

So applying this to a table to test:

```sql
create table emp_recs (
  jdoc json validate '{
  "type" : "object",
  "properties" :
  {
    "name" : {"type" : "string"},
    "salary" : {"type" : "number"},
    "manager" : {"type" : "string"},
    "on_vacation" : {"type" : "boolean"}
  }
}'
);
```

Now we can load data ensuring it conforms to our standard. To trigger a failure
we can specify a non boolean in the "on_vacation" field and you will expect to get
a `ORA-40875: JSON schema validation error`.

To extend and make this schema more useful, a couple of things you might like to change
is to require certain fields, and prevent additional ones. We tweak our schema to
the following:

```json
{
  "type" : "object",
  "properties" :
  {
    "name" : {"type" : "string"},
    "salary" : {"type" : "number"},
    "manager" : {"type" : "string"},
    "on_vacation" : {"type" : "boolean"}
  },
  "required": ["name", "manager"],
  "additionalProperties": false
}
```

The full spec about schema configuration options can be found here: <https://json-schema.org/understanding-json-schema/>.