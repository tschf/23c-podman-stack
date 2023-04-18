# SQL

New SQL functionalities.

## values clause

You can insert many rows.

```sql
create table values_demo(
  value_name varchar2(20),
  age int
);

insert into values_demo (value_name, age)
values
('Bob', 23),
('Mary', 35)
;
```

And you can use the caluse as a row generator - instead of your traditional
select from dual union all.

```sql
-- must have alias and column definition at the end
select *
from ( values
    ('Bob', 23),
    ('Mary', 35)
) foo (value_name, age)

-- or you can use the traditional with clause - no select necessary inside the 
-- with clause
with data_set (value_name, age) as (
  values
  ('Bob', 23),
  ('Mary', 35)
)
select *
from data_set
```
