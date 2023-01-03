create temp table knot_positions as (
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
    1 knot_number,
    motion_number,
    array[
      coalesce(sum(case direction when 'R' then 1 when 'L' then -1 end) over (order by motion_number), 0),
      coalesce(sum(case direction when 'U' then 1 when 'D' then -1 end) over (order by motion_number), 0)
    ] position
  from motions
);

alter table knot_positions add primary key (knot_number, motion_number);

prepare simulate_knot(int) as
  with recursive positions as (
    select * from (
      values (0::bigint, array[0, 0]::bigint[])
    ) v(motion_number, position)
    union all
    select * from (
      with delta as (
        select
          kp.motion_number,
          p.position,
          array[p.position[1] - kp.position[1], p.position[2] - kp.position[2]] delta
        from positions p
        inner join knot_positions kp
          on kp.motion_number = p.motion_number + 1 and kp.knot_number = $1 - 1
      )
      select
        motion_number,
        case
          when abs(delta[1]) > 1 or abs(delta[2]) > 1 then
            array[
              position[1] - sign(delta[1])::bigint,
              position[2] - sign(delta[2])::bigint
            ]
          else
            position
        end
      from delta
    ) q
  )
  insert into knot_positions (knot_number, motion_number, position)
  select $1, motion_number, position from positions;

execute simulate_knot(2);
execute simulate_knot(3);
execute simulate_knot(4);
execute simulate_knot(5);
execute simulate_knot(6);
execute simulate_knot(7);
execute simulate_knot(8);
execute simulate_knot(9);
execute simulate_knot(10);

select count(distinct position)
from knot_positions
where knot_number = 10
