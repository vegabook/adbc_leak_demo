# AdbcLeakDemo
Tests memory leaks across sqlite and duckdb native vs adbc drivers by synthetically
generating 500k inserts and reporting BEAM and Resident Set (OS) memory usage for the process. 

## Usage

```
mix deps.get
mix run -e "AdbcLeakDemo.run_all()"

# Custom iteration count
mix run -e "AdbcLeakDemo.run_all(10_000)"
```

CSV summary output in priv/results

