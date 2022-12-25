with depths as (
  with input as (
    select unnest(string_to_array(:'input', E'\n')) line
  ),
  lines as (
    select
      row_number() over () number,
      line
    from input
  )
  select
    number,
    line,
    sum(
      case
        when line ~ '\$ cd (?!\.\.$)' then 1
        when line = '$ cd ..' then -1
      end
    ) over (order by number) depth
  from lines
),
directory_sizes as (
  with counts as (
    select
      di.number id,
      de.line,
      count(*) filter (where de.depth < di.depth) over w count
    from depths di
    inner join depths de on de.number > di.number
    where di.line ~ '\$ cd (?!\.\.$)'
    window w as (partition by di.number order by de.number)
  )
  select
    id,
    sum((string_to_array(line, ' '))[1]::integer) directory_size
  from counts
  where count = 0 and line ~ '^[0-9]'
  group by id
)
select directory_size
from directory_sizes
where directory_size >= (select max(directory_size) from directory_sizes) - 40000000
order by directory_size
limit 1
