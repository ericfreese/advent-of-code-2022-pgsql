with valve_data as (
  with line_data as (
    select regexp_match(line, 'Valve (\w+) has flow rate=(\d+); .* valves? (.*)') line_data
    from string_to_table(:'input', E'\n') line
  )
  select
    line_data[1] valve_id,
    line_data[2]::int flow_rate,
    string_to_array(line_data[3], ', ') accessible
  from line_data
),
valves as (
  with distinct_valves as (
    select distinct
      valve_id id,
      flow_rate
    from valve_data
  )
  select
    id,
    row_number() over () index,
    flow_rate
  from distinct_valves
),
tunnels as (
  select
    valve_id a,
    unnest(accessible) b
  from valve_data
),
important_valves as (
  select *
  from valves
  where flow_rate > 0
),
weighted_tunnels as (
  -- Use Floyd-Warshall to determine shortest paths in minutes between all
  -- valves with non-zero flow rates
  with recursive minutes as (
    select
      0 step,
      va.id a,
      vb.id b,
      case
        when va.id = vb.id then 0
        when t.a is not null then 1
      end minutes
    from valves va
    cross join valves vb
    left join tunnels t
      on t.a = va.id and t.b = vb.id
    union all
    select * from (
      with minutes as (
        select * from minutes
      ),
      next as (
        select step + 1 step, a, b, minutes
        from minutes
      )
      select
        n.step,
        n.a,
        n.b,
        case
          when n.minutes is null or m1.minutes + m2.minutes < n.minutes then
            m1.minutes + m2.minutes
          else
            n.minutes
        end minutes
      from next n
      inner join valves v on v.index = n.step
      inner join minutes m1 on m1.a = n.a and m1.b = v.id
      inner join minutes m2 on m2.a = v.id and m2.b = n.b
      where n.step <= (select max(index) from valves)
    ) q
  )
  select distinct on (a, b)
    a,
    b,
    minutes
  from minutes m
  inner join valves va on va.id = m.a
  inner join valves vb on vb.id = m.b
  where a != b
    and (va.id in (select id from important_valves) or va.id = 'AA')
    and vb.id in (select id from important_valves)
  order by a, b, step desc
),
valve_sequences as (
  -- Examine every possible order that you could open the important valves in
  -- and determine how much pressure that sequence could release
  with recursive valve_sequences as (
    select
      26 mins_left,
      array[]::text[] sequence,
      0 pressure_released
    union
    select * from (
      with next as (
        select
          -- It takes wt.minutes to move to the valve and 1 minute to open it
          mins_left - wt.minutes - 1 mins_left,
          sequence,
          iv.id next,
          iv.flow_rate next_flow_rate,
          pressure_released
        from valve_sequences vs
        inner join important_valves iv
          on not vs.sequence @> array[iv.id]
        inner join weighted_tunnels wt
          on wt.a = coalesce(vs.sequence[cardinality(vs.sequence)], 'AA')
          and wt.b = iv.id
      )
      select
        mins_left,
        array_append(sequence, next),
        pressure_released + mins_left * next_flow_rate
      from next
    ) q
    where mins_left> 0
  )
  select *
  from valve_sequences
)
-- This takes about 8 minutes to run but I can't think of anything better to do
select
  mvs.sequence my_sequence,
  mvs.pressure_released my_pressure_released,
  evs.sequence elephant_sequence,
  evs.pressure_released elephant_pressure_released,
  mvs.pressure_released + evs.pressure_released total_pressure_released
from valve_sequences mvs
inner join valve_sequences evs
  on not mvs.sequence && evs.sequence
order by mvs.pressure_released + evs.pressure_released desc
limit 1
