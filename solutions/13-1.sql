with pairs as (
  with pair_lines as (
    select
      row_number() over () pair_id,
      string_to_array(lines, E'\n')::jsonb[] packets
    from string_to_table(:'input', E'\n\n') lines
  )
  select
    pair_id,
    packets[1] l,
    packets[2] r
  from pair_lines
),
results as (
  with recursive results as (
    select
      pair_id,
      null::boolean is_correct_order,
      array[0] next_path,
      l next_lp,
      r next_rp
    from pairs
    union all
    select * from (
      with start as (
        select
          pair_id,
          next_path path,
          next_lp lp,
          next_rp rp
        from results
        where is_correct_order is null
      ),
      resolved as (
        select
          *,
          lp #> path::text[] l,
          rp #> path::text[] r
        from start
      ),
      types as (
        select
          *,
          array[jsonb_typeof(l), jsonb_typeof(r)] types
        from resolved
      ),
      result as (
        select
          *,
          case
            when types = array['number', 'number'] then
              case when l = r then null else l < r end
            when types[1] is null and types[2] is not null then
              true
            when types[1] is not null and types[2] is null then
              false
          end is_correct_order
        from types
      ),
      next as (
        select
          *,
          case types
            when array[null, null] then
              array_append(trim_array(path, 2), path[array_upper(path, 1) - 1] + 1)
            when array['number', 'number'] then
              array_append(trim_array(path, 1), path[array_upper(path, 1)] + 1)
            when array['array', 'array'] then
              array_append(path, 0)
            else
              path
          end next_path,
          case types
            when array['number', 'array'] then
              jsonb_set(lp, path::text[], jsonb_build_array(l))
            else
              lp
          end next_lp,
          case types
            when array['array', 'number'] then
              jsonb_set(rp, path::text[], jsonb_build_array(r))
            else
              rp
          end next_rp
        from result
      )
      select
        pair_id,
        is_correct_order,
        next_path,
        next_lp,
        next_rp
      from next
    ) q
  )
  select * from results
)
select sum(pair_id)
from results
where is_correct_order
