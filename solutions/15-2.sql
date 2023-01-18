-- TODO: This takes a few minutes to run. Try to optimize. The primary keys
-- probably don't do anything currently. Maybe try using polygons and possibly
-- an R-tree index.

create temp table sensor_distances as (
  with sensor_beacons as (
    select
      regexp_match(line, 'Sensor at x=(\-?\d+), y=(\-?\d+):')::int[] sensor,
      regexp_match(line, 'beacon is at x=(\-?\d+), y=(\-?\d+)')::int[] beacon,
      *
    from string_to_table(:'input', E'\n') line
  )
  select
    sensor,
    abs(sensor[1] - beacon[1]) + abs(sensor[2] - beacon[2]) distance
  from sensor_beacons
);

alter table sensor_distances add primary key (sensor);

-- This produces about 57 million rows in 1.5 mins
create temp table candidates as (
  with sensor_outlines as (
    select
      sensor,
      distance + 1 outline
    from sensor_distances
  )
  select distinct x, y from (
    select
      sensor[1] + unnest(
        array(
          select * from generate_series(-outline, outline)
          union all
          select * from generate_series(outline - 1, -outline + 1, -1)
        )
      ) x,
      sensor[2] + unnest(
        array(
          select * from generate_series(0, outline - 1)
          union all
          select * from generate_series(outline, -outline, -1)
          union all
          select * from generate_series(-outline + 1, -1, 1)
        )
      ) y
    from sensor_outlines
  ) q
  where x between 0 and 4000000 and y between 0 and 4000000
);

alter table candidates add primary key (x, y);

-- This takes around 4 mins
select distinct x::bigint * 4000000 + y tuning_frequency
from candidates c
left join sensor_distances sd
  on abs(c.x - sd.sensor[1]) + abs(c.y - sd.sensor[2]) <= sd.distance
where sd.sensor is null and x between 0 and 4000000 and y between 0 and 4000000
