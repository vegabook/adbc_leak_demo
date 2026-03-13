# adbc_leak_demo
Tests memory leaks across sqlite and duckdb native vs adbc drivers by synthetically
generating 500k inserts and reporting BEAM and Resident Set (OS) memory usage for the process. 

## Usage

```
mix deps.get
mix run -e "AdbcLeakDemo.run_all()"

# Custom iteration count
mix run -e "AdbcLeakDemo.run_all(10_000)"
```

## Output
Tables for each of duckdb and sqlite via adbc, also sqlite and exqlite.  
delta_mb is the column to watch for whole process memory usage change over time. 

```
adbc :duckdb — 100 rows/insert, 5000 iterations
 iter | beam_mb | resident_set_mb | delta_mb
------|---------|-----------------|----------
    0 |    43.8 |           138.0 |     0.1
  500 |    44.0 |           214.0 |    76.1
 1000 |    44.7 |           294.8 |   156.9

CSV summary output in priv/results

