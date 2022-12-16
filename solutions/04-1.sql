with pair_assignments as (
  with lines as (
    select
      string_to_array(unnest(string_to_array(:'input', E'\n')), ',') line_array
  ),
  assignment_arrays as (
    select
      row_number() over () pair_id,
      string_to_array(unnest(line_array), '-') assignment_array
    from lines
  )
  select
    row_number() over () elf_id,
    pair_id,
    int4range(
      assignment_array[1]::integer,
      assignment_array[2]::integer,
      '[]'
    ) assignment
  from assignment_arrays
)
select
  count(distinct pa1.pair_id) num_containing_pairs
from pair_assignments pa1
inner join pair_assignments pa2
  on pa2.pair_id = pa1.pair_id
  and pa2.elf_id != pa1.elf_id
where pa1.assignment @> pa2.assignment
