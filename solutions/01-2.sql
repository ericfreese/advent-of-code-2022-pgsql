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
top_total_elf_calories as (
  select
    sum(calories) calories
  from food_items
  group by elf_id
  order by sum(calories) desc
  limit 3
)
select
  sum(calories) total_calories
from top_total_elf_calories
