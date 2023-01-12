create temp table rocks as (
  with paths as (
    select
      row_number() over () path_id,
      string_to_array(line, ' -> ') path
    from string_to_table(:'input', E'\n') line
  ),
  path_points as (
    with point_arrays as (
      select
        path_id,
        generate_subscripts(path, 1) number,
        string_to_array(unnest(path), ',')::int[] point
      from paths
    )
    select
      path_id,
      number,
      point[1] x,
      point[2] y
    from point_arrays
  ),
  segments as (
    select
      lag(x) over (partition by path_id order by number) x1,
      lag(y) over (partition by path_id order by number) y1,
      x x2,
      y y2
    from path_points
  ),
  ranges as (
    select
      case when y2 = y1 then array(select * from generate_series(x1, x2, sign(x2 - x1)::int)) else array[x2] end x,
      case when x2 = x1 then array(select * from generate_series(y1, y2, sign(y2 - y1)::int)) else array[y2] end y
    from segments
  )
  select distinct
    unnest(case when array_length(x, 1) = 1 then array_fill(x[1], array[array_length(y, 1)]) else x end) x,
    unnest(case when array_length(y, 1) = 1 then array_fill(y[1], array[array_length(x, 1)]) else y end) y
  from ranges
);

alter table rocks add primary key (x, y);

create temp table bounds as (
  select
    min(x) min_x,
    max(x) max_x,
    0 min_y,
    max(y) max_y
  from rocks
);

create temp table final_sand_grains as (
  with recursive sand_grains as (
    select
      500 x,
      0 y
    union
    select * from (
      select
        unnest(array[x - 1, x, x + 1]),
        y + 1
      from sand_grains
      where y + 1 < (select max_y + 2 from bounds)
      except
      select x, y from rocks
    ) q
  )
  select * from sand_grains
);

select count(*) from final_sand_grains;

select
  string_agg(
    case
      when bx.x = 500 and by.y = 0 then '+'
      when sg.x is not null then '.'
      when r.x is not null or by.y = (select max_y from bounds) + 2 then 'x'
      else ' '
    end,
    ''
    order by bx.x
  )
from generate_series((select min_x from bounds), (select max_x from bounds)) bx(x)
cross join generate_series((select min_y from bounds), (select max_y from bounds) + 2) by(y)
left join rocks r on r.x = bx.x and r.y = by.y
left join final_sand_grains sg on sg.x = bx.x and sg.y = by.y
group by by.y
