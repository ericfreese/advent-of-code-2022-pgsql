with item_type_priorities as (
  select
    case
      when priority between 1 and 26 then chr(priority + 96)
      when priority between 27 and 52 then chr(priority + 38)
    end item_type,
    priority
  from (
    select generate_series priority
    from generate_series(1, 52)
  ) p
),
lines as (
  select
    unnest(string_to_array(:'input', E'\n')) line
),
rucksacks as (
  select
    row_number() over () rucksack_id,
    substring(line, 1, length(line) / 2) first_compartment,
    substring(line, length(line) / 2 + 1, length(line) / 2) second_compartment
  from lines
),
rucksack_compartments as (
  select
    rucksack_id,
    unnest(array[1, 2]) compartment_number,
    unnest(array[first_compartment, second_compartment]) contents
  from rucksacks
),
rucksack_items as (
  select
    rucksack_id,
    compartment_number,
    unnest(string_to_array(contents, null)) item_type
  from rucksack_compartments
),
common_items as (
  select
    rucksack_id,
    item_type
  from rucksack_items
  group by 1, 2
  having count(distinct compartment_number) > 1
)
select
  sum(itp.priority) total_priority
from common_items ci
inner join item_type_priorities itp on itp.item_type = ci.item_type
