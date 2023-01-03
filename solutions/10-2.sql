with instructions as (
  select
    row_number() over () number,
    instruction
  from string_to_table(:'input', E'\n') instruction
),
with_previous as (
  select
    number,
    instruction,
    lag(instruction) over (order by number) previous_instruction
  from instructions
),
cycles as (
  select
    sum(case when previous_instruction ~ '^addx ' then 2 else 1 end) over (order by number) cycle,
    instruction,
    1 + coalesce(sum((regexp_match(previous_instruction, '^addx (\-?\d+)$'))[1]::integer) over (order by number), 0) x
  from with_previous
),
cycle_ranges as (
  select
    int4range(cycle::integer, lead(cycle) over (order by cycle)::integer) cycles,
    instruction,
    x
  from cycles
)
select string_agg(case when position % 40 between x - 1 and x + 1 then '#' else ' ' end, '' order by position) image
from generate_series(0, 239) position
inner join cycle_ranges cr on cr.cycles @> position + 1
group by position / 40
order by position / 40
