create temp table head_positions as (
  with motions as (
    with line_arrays as (
      select string_to_array(unnest(string_to_array(:'input', E'\n')), ' ') line
    ),
    decomposed as (
      select unnest(array_fill(line[1], array[line[2]::integer])) direction
      from line_arrays
    )
    select
      row_number() over () motion_number,
      direction
    from decomposed
  )
  select
    motion_number,
    direction,
    array[
      coalesce(sum(case direction when 'R' then 1 when 'L' then -1 end) over (order by motion_number), 0),
      coalesce(sum(case direction when 'U' then 1 when 'D' then -1 end) over (order by motion_number), 0)
    ] position
  from motions
);

alter table head_positions add primary key (motion_number);

with recursive tail_positions as (
  select * from (
    values (0::bigint, array[0, 0]::bigint[])
  ) v(motion_number, position)
  union all
  select
    hp.motion_number,
    case
      when abs(hp.position[1] - tp.position[1]) > 1 or abs(hp.position[2] - tp.position[2]) > 1 then
        case hp.direction
          when 'U' then array[hp.position[1], hp.position[2] - 1]
          when 'D' then array[hp.position[1], hp.position[2] + 1]
          when 'R' then array[hp.position[1] - 1, hp.position[2]]
          when 'L' then array[hp.position[1] + 1, hp.position[2]]
        end
      else
        tp.position
    end
  from tail_positions tp
  inner join head_positions hp
    on hp.motion_number = tp.motion_number + 1
)
select count(distinct position) num_positions
from tail_positions
