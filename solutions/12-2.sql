create temp table cells as (
  with lines as (
    select row_number() over () y, string_to_array(line, null) cells
    from string_to_table(:'input', E'\n') line
  ),
  cells as (
    select generate_subscripts(cells, 1) x, y, unnest(cells) cell
    from lines
  )
  select
    *,
    row_number() over (order by y, x) id,
    ascii(case cell when 'S' then 'a' when 'E' then 'z' else cell end) - ascii('a') height
  from cells
);

alter table cells add primary key (id);

create temp table edges as (
  with edges as (
    select
      cs.id a,
      ce.id b
    from cells cs
    inner join cells ce
      on ce.height <= cs.height + 1
      and (
        cs.x = ce.x and abs(ce.y - cs.y) = 1 or
        cs.y = ce.y and abs(ce.x - cs.x) = 1
      )
  )
  select * from edges
);

alter table edges add primary key (a, b);

with recursive paths as (
  select
    id current,
    array[id] visited
  from cells
  where cell = 'E'
  union all
  select * from (
    with paths as (select * from paths)
    select distinct on (e.a)
      e.a,
      array_append(visited, e.a)
    from paths p
    inner join edges e
      on e.b = p.current and e.a not in (select unnest(visited) from paths)
    order by e.a, array_length(visited, 1)
  ) q
)
select min(array_length(visited, 1) - 1) steps
from paths p
inner join cells c
  on c.id = p.current
where c.height = 0
