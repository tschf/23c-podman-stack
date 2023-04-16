# Annotations

Docs link: <https://docs.oracle.com/en/database/oracle/oracle-database/23/adfns/registering-application-data-usage-database.html#GUID-2DAF069E-0938-40AF-B05B-75AFE71D666C>

Annotations can be added to any object and it is a key value pairing, where the value
does not need be specified.

```sql
create table annotation_example(
    id number primary key
)
annotations(
    app 'NotesApp'
);

alter table annotation_example
annotations (add display_name 'Annotation Example');

alter table annotation_example
modify id annotations (add identifier);
```

You can report on these from the `USER_ANNOTATIONS_USAGE` table

```sql
select *
from USER_ANNOTATIONS_USAGE
```

It includes the columns:

* OBJECT_NAME
* OBJECT_tYPE
* COLUMN_NAME
* DOMAIN_NAME
* DOMAIN_OWNER
* ANNOTATION_NAME
* ANNOTATION_VALUE