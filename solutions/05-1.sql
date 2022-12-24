with input_array as (
  select string_to_array(:'input', E'\n\n') input
),
stack_crates as (
  with lines as (
    select unnest(string_to_array(input[1], E'\n')) line
    from input_array
  ),
  rows as (
    select
      row_number() over () row_id,
      unnest(string_to_array(line, null)) cell
    from lines
  ),
  cells as (
    select
      row_id,
      row_number() over (partition by row_id) col_id,
      cell
    from rows
  ),
  column_crates as (
    select
      col_id,
      row_number() over (partition by col_id order by row_id desc) position,
      cell crate_contents
    from cells
    where cell between 'A' and 'Z'
  ),
  stacks as (
    with distinct_cols as (
      select distinct col_id
      from column_crates
    )
    select
      row_number() over (order by col_id) id,
      col_id
    from distinct_cols
  )
  select
    s.id stack_id,
    position,
    crate_contents
  from column_crates cc
  inner join stacks s on s.col_id = cc.col_id
),
rearrangement_procedure as (
  with parsed_lines as (
    select regexp_matches(unnest(string_to_array(input[2], E'\n')), '^move (\d+) from (\d+) to (\d+)$') data
    from input_array
  )
  select
    row_number() over () step_number,
    data[1]::integer count,
    data[2]::integer from_stack_id,
    data[3]::integer to_stack_id
  from parsed_lines
),
iterations as (
  with recursive stepped_stacks as (
    select
      0::bigint step_number,
      stack_id,
      array_agg(crate_contents order by position) crates
    from stack_crates
    group by stack_id
    union all
    select * from (
      with stepped_stacks as (
        select * from stepped_stacks
      ),
      crates_to_move as (
        select
          rp.from_stack_id,
          rp.to_stack_id,
          array(
            select crates[i]
            from generate_subscripts(crates, 1) as s(i)
            order by i desc
            limit rp.count
          ) crates
        from rearrangement_procedure rp
        inner join stepped_stacks ss
          on ss.step_number + 1 = rp.step_number
          and ss.stack_id = rp.from_stack_id
      )
      select
        step_number + 1,
        stack_id,
        case
          when stack_id = from_stack_id then
            trim_array(ss.crates, array_upper(ctm.crates, 1))
          when stack_id = to_stack_id then
            ss.crates || ctm.crates
          else
            ss.crates
        end crates
      from stepped_stacks ss
      cross join crates_to_move ctm
    ) q
  )
  select * from stepped_stacks
),
final_arrangement as (
  select distinct on (stack_id)
    stack_id,
    crates
  from iterations
  order by stack_id, step_number desc
)
select string_agg(crates[array_upper(crates, 1)], '') top_crates
from final_arrangement
