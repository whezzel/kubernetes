# Troubleshooting

For context, this is the error i was getting when trying to rebuild my cluster:

```sql
pg_basebackup: error: backup failed: ERROR: file name too long for tar format: "pg_vectors/indexes/000000000000000000000000000000006797019500ff10200000419800004672/segments/fda89865-9b1c-4838-92c7-0d6e44c1abaf"
```

i started my cluster with 1 instance, let it rebuild from s3, then i searched for indexes with:

```sql
SELECT indexname, indexdef, schemaname
FROM pg_indexes
WHERE indexdef ILIKE '%USING vectors%';
```

and got the following output:

```sql
indexname  |                                                        indexdef                                                        | schemaname
------------+------------------------------------------------------------------------------------------------------------------------+------------
 clip_index | CREATE INDEX clip_index ON public.smart_search USING vectors (embedding vector_cos_ops) WITH (options='[indexing.hnsw]+| public
            | m = 16                                                                                                                +|
            | ef_construction = 300')                                                                                                |
 face_index | CREATE INDEX face_index ON public.face_search USING vectors (embedding vector_cos_ops) WITH (options='[indexing.hnsw] +| public
            | m = 16                                                                                                                +|
            | ef_construction = 300')                                                                                                |
(2 rows)
```

I dropped the 2 indexes with:

```sql
DROP INDEX public.clip_index;
DROP INDEX public.face_index;
```

i was then able to scale up the number of instances without error. After verifying immich was running as expected, i recreated the indexes with:

```sql
CREATE INDEX clip_index ON public.smart_search USING vectors (embedding vector_cos_ops) WITH (options = $$
[indexing.hnsw]
m=16
ef_construction=300
$$);
```

and

```sql
CREATE INDEX face_index ON public.face_search USING vectors (embedding vector_cos_ops) WITH (options = $$
[indexing.hnsw]
m=16
ef_construction=300
$$);
```
