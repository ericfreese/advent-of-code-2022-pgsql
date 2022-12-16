with chunks as (
  select
    unnest(string_to_array(:'input', E'\n\n')) chunk
),
food_items as (
  select
    row_number() over () elf_id,
    unnest(string_to_array(chunk, E'\n'))::integer calories
  from chunks
),
total_elf_calories as (
  select
    sum(calories) calories
  from food_items
  group by elf_id
)
select
  max(calories) total_calories
from total_elf_calories
