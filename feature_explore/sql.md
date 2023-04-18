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

## update on join

Assuming the following structure:

```sql
create table dep(
  dnum number primary key,
  dname varchar2(20) not null
);

create table emp(
  empno number primary key,
  ename varchar2(20) not null,
  sal number default on null 0 not null,
  dnum number not null
);

insert into dep 
values
  (10, 'MANAGEMENT'),
  (20, 'ACCOUNTING'),
  (30, 'IT')
;

insert into emp
values
  (10, 'KING', 5000, 10),
  (20, 'CLARK', 400, 20),
  (30, 'SANJAY', 300, 20),
  (40, 'SMITH', 700, 20),
  (50, 'ROGERS', 200, 30),
  (60, 'BARTY', 250, 30),
  (70, 'FERGUSON', 129, 40),
  (80, 'JORDAN', 900, 40)
;
```

It is usually the case if you wanted to update records based on a join, you would
have to use a sub-query to match relevant rows that you want to update. With the
latest version, you can do a single statement to match only relevant records.

Here is an example to increase the salary of people in department 20 by 10%.

```sql
update emp
set emp.sal = sal * 1.1
from dep 
where dep.dnum = emp.dnum
and dep.dnum = 20
```

Previously, you would have had to do something like this:

```sql
update emp
set sal = sal*1.1
where empno in (
  select empno
  from emp
  join dep on dep.dnum = emp.dnum
  where dep.dnum = 20
);
```
