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
),
viewing_distances as (
  select
    *,
    (
      select count(*)
      from (
        select count(*) filter (where height >= t.height) over w
        from trees n
        where n.x = t.x and n.y < t.y
        window w as (
          order by y desc
          range between unbounded preceding and current row
          exclude current row
        )
      ) n
      where count = 0
    ) north,
    (
      select count(*)
      from (
        select count(*) filter (where height >= t.height) over w
        from trees s
        where s.x = t.x and s.y > t.y
        window w as (
          order by y
          range between unbounded preceding and current row
          exclude current row
        )
      ) s
      where count = 0
    ) south,
    (
      select count(*)
      from (
        select count(*) filter (where height >= t.height) over w
        from trees w
        where w.y = t.y and w.x < t.x
        window w as (
          order by x desc
          range between unbounded preceding and current row
          exclude current row
        )
      ) w
      where count = 0
    ) west,
    (
      select count(*)
      from (
        select count(*) filter (where height >= t.height) over w
        from trees e
        where e.y = t.y and e.x > t.x
        window w as (
          order by x
          range between unbounded preceding and current row
          exclude current row
        )
      ) e
      where count = 0
    ) east
  from trees t
)
select max(north * south * west * east) highest_scenic_score
from viewing_distances
