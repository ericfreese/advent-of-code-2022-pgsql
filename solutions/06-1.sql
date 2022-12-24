with input as (
  select unnest(string_to_array(:'input', null)) as char
),
sequences as (
  select
    row_number() over () number,
    array_agg(char) over (rows between 3 preceding and current row) sequence
  from input
),
distinct_sequences as (
  select
    number,
    array(select distinct unnest(sequence)) distinct_sequence
  from sequences
),
markers as (
  select number
  from distinct_sequences
  where array_upper(distinct_sequence, 1) = 4
)
select number
from markers
order by number
limit 1
