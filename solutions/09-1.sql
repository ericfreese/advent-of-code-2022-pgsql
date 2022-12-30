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
),
head_positions as (
  select
    motion_number,
    array[
      coalesce(sum(case direction when 'R' then 1 when 'L' then -1 end) over (order by motion_number), 0),
      coalesce(sum(case direction when 'U' then 1 when 'D' then -1 end) over (order by motion_number), 0)
    ] position
  from motions
),
tail_positions as (
  with recursive tail_positions as (
    select * from (
      values (0, array[0, 0]::bigint[])
    ) v(motion_number, position)
    union all
    select * from (
      with delta as (
        select
          tp.motion_number + 1 motion_number,
          hp.position head_position,
          tp.position tail_position,
          array[tp.position[1] - hp.position[1], tp.position[2] - hp.position[2]] delta
        from tail_positions tp
        inner join head_positions hp
          on hp.motion_number = tp.motion_number + 1
      )
      select
        motion_number,
        case
          when (delta[1] between -1 and 1) and abs(delta[2]) > 1 then
            array[head_position[1], head_position[2] + delta[2] / abs(delta[2])]
          when abs(delta[1]) > 1 and (delta[2] between -1 and 1) then
            array[head_position[1] + delta[1] / abs(delta[1]), head_position[2]]
          else
            tail_position
        end
      from delta
    ) q
  )
  select *
  from tail_positions
)
select count(distinct position) num_positions
from tail_positions
