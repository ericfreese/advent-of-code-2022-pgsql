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
top_elf_calories as (
  select
    sum(calories) calories
  from food_items
  group by elf_id
  order by sum(calories) desc
  limit 3
)
select
  sum(calories) total_calories
from top_elf_calories
