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
    (row_number() over () - 1) / 3 group_id,
    substring(line, 1, length(line) / 2) first_compartment,
    substring(line, length(line) / 2 + 1, length(line) / 2) second_compartment
  from lines
),
rucksack_compartments as (
  select
    rucksack_id,
    group_id,
    unnest(array[1, 2]) compartment_number,
    unnest(array[first_compartment, second_compartment]) contents
  from rucksacks
),
rucksack_items as (
  select
    rucksack_id,
    group_id,
    compartment_number,
    unnest(string_to_array(contents, null)) item_type
  from rucksack_compartments
),
group_badges as (
  select
    group_id,
    item_type
  from rucksack_items
  group by 1, 2
  having count(distinct rucksack_id) > 2
)
select sum(priority) total_priority
from group_badges gb
inner join item_type_priorities itp on itp.item_type = gb.item_type
