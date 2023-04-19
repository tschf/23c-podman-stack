# Domains

Domain are a new re-usable component that can be applied to columns. So instead
of adding a constraints to multiple columns, you define it once as a domain and specify
the domain on all the columns it should apply.

There are pre-installed ones that can be leveraged, which you can find by querying
the `all_domains` dictionary view.

Just to highlight a few (there are 22 available as at time of writing):

* EMAIL_D
* POSITIVE_NUMBER_D
* NEGATIVE_NUMBER_D
* CREDIT_CARD_NUMBER_D
* CIDR_D

To see the details, you would join to the `all_domain_constaints`.

```sql
select *
from all_domain_constraints
where domain_name = 'PHONE_NUMBER_D'
```

So to see how one is defined for phone number, we can look at the search condition
and reproduce it like so:

```sql
create domain phone_number_domain 
-- specify input type
as varchar2(20)
default on null '515 553 2849'
constraint phone_number_domain_ck check (REGEXP_LIKE (phone_number_domain,'^[+]{0,1}[0-9]{1,16}$'))
display 'ph: ' || phone_number_domain;

create table phones (ph varchar2(20) domain phone_number_domain);
```

As you can notice, by default the input is the name of the domain (in your expression).
If the domain needs to drive off multiple columns you can specify a columns list
instead of a single input data type. These get mapped by a typical function call
as you will note in the example below.

```sql
create domain ab_domain as (
  a as varchar2(1),
  b as varchar2(1)
)
constraint ab_ck check (a = 'A' and (b = 'B' or b is null));

create table ab_table(
  a varchar2(1),
  b varchar2(1),
  domain ab_domain(a,b)
);
```
