# Advent of Code 2022

Solutions using PostgreSQL.

## Usage

- Paste puzzle inputs into `inputs/??` files where `??` is the zero-padded day number (e.g. `01` for day 1).
- Run the postgres server via `./server` (requires docker).
- Run a solution via `./run solutions/??-?.sql` (requires psql).
- Once you get a correct answer, write it to `answers/??-?` where `??` is the zero-padded day number and `?` is the part number (e.g. `./run solutions/01-2.sql > answers/01-2`.
- Running a solution that has a corresponding file under `answers/` will output a diff of the current output against the recorded output, allowing for simple regression testing.
