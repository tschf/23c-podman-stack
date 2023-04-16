# MLE

Grant the following to the parsing schema:

```sql
GRANT EXECUTE DYNAMIC MLE to XYZ;
GRANT EXECUTE ON JAVASCRIPT TO XYZ;
```

Sample dynamic content region:

```js
const dataSet = [];
const rows = apex.conn.execute( `
    select owner "owner", object_name "object_name" 
    from all_objects 
    fetch first 100 rows only
` ).rows;

for(let row of rows) {
    dataSet.push(`OWNER=${row.owner} and OBJECT=${row.object_name}<br>`);
}

return dataSet.join('');
```
