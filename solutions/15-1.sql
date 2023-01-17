with sensor_beacons as (
  select
    regexp_match(line, 'Sensor at x=(\-?\d+), y=(\-?\d+):')::int[] sensor,
    regexp_match(line, 'beacon is at x=(\-?\d+), y=(\-?\d+)')::int[] beacon,
    *
  from string_to_table(:'input', E'\n') line
),
sensor_distances as (
  select
    sensor,
    abs(sensor[1] - beacon[1]) + abs(sensor[2] - beacon[2]) - abs(sensor[2] - 2000000) leftover
  from sensor_beacons
),
horizontal_positions as (
  select distinct
    unnest(array(select * from generate_series(sensor[1] - leftover, sensor[1] + leftover)))
  from sensor_distances
  except
  select beacon[1]
  from sensor_beacons
  where beacon[2] = 2000000
)
select count(*)
from horizontal_positions
