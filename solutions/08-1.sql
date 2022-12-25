with trees as (
  with rows as (
    select unnest(string_to_array(:'input', E'\n')) row
  ),
  cols as (
    select
      row_number() over () y,
      unnest(string_to_array(row, null))::integer height
    from rows
  )
  select
    row_number() over (partition by y) x,
    y,
    height
  from cols
)
select count(*)
from trees t
where
  coalesce((select max(height) from trees n where n.x = t.x and n.y < t.y), -1) < t.height
  or coalesce((select max(height) from trees s where s.x = t.x and s.y > t.y), -1) < t.height
  or coalesce((select max(height) from trees w where w.y = t.y and w.x < t.x), -1) < t.height
  or coalesce((select max(height) from trees e where e.y = t.y and e.x > t.x), -1) < t.height
