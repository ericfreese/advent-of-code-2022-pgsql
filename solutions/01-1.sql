with food_items as (
  with chunks as (
    select
      unnest(string_to_array(:'input', E'\n\n')) chunk
  )
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
