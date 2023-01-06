with monkey_data as (
  with monkey_chunks as (
    select monkey_chunk
    from string_to_table(:'input', E'\n\n') monkey_chunk
  ),
  parse_results as (
    select
      regexp_match(monkey_chunk, 'Monkey (\d+):') id,
      regexp_match(monkey_chunk, 'Starting items: (.*)\n', 'n') items,
      regexp_match(monkey_chunk, 'Operation: new = (old|\d+) ([\+\*]) (old|\d+)\n', 'n') operation,
      regexp_match(monkey_chunk, 'Test: divisible by (\d+)\n.*true:.*monkey (\d+)\n.*false:.*monkey (\d+)') test,
      *
    from monkey_chunks
  )
  select
    id[1]::int id,
    string_to_array(items[1], ', ')::bigint[] items,
    operation[2] operator,
    array[operation[1], operation[3]] operands,
    test[1]::int test_divisor,
    test[2]::int true_monkey,
    test[3]::int false_monkey
  from parse_results
),
monkeys as (
  select
    id,
    operator,
    operands,
    test_divisor,
    true_monkey,
    false_monkey
  from monkey_data
),
least_common_divisor_multiple as (
  with recursive lcm as (
    select 0 monkey_id, null::int lcm
    union all
    select monkey_id + 1, coalesce(lcm(lcm, test_divisor), test_divisor)
    from lcm
    inner join monkeys m on m.id = lcm.monkey_id
  )
  select lcm from lcm order by monkey_id desc limit 1
),
initial_state as (
  select
    id monkey_id,
    items
  from monkey_data
),
turns as (
  select * from (
    with recursive turns as (
      select -1 turn, monkey_id, items from initial_state
      union all
      select * from (
        with turns as (
          select * from turns
        ),
        thrown_items as (
          select
            turn,
            monkey_id,
            unnest(items) item,
            generate_subscripts(items, 1) item_order
          from turns
          where monkey_id = (turn + 1) % (select count(*) from monkeys)
        ),
        resolved_operands as (
          select
            *,
            array[
              case when operands[1] = 'old' then item else operands[1]::bigint end,
              case when operands[2] = 'old' then item else operands[2]::bigint end
            ] resolved_operands
          from thrown_items ti
          inner join monkeys m
            on m.id = ti.monkey_id
        ),
        new_items as (
          select
            *,
            case operator
              when '*' then
                resolved_operands[1] * resolved_operands[2]
              when '+' then
                resolved_operands[1] + resolved_operands[2]
            end % (select lcm from least_common_divisor_multiple) new_item
          from resolved_operands
        ),
        caught_items as (
          select
            case
              when new_item % test_divisor = 0 then
                true_monkey
              else
                false_monkey
            end monkey_id,
            array_agg(new_item order by monkey_id, item_order) caught_items
          from new_items
          group by 1
        )
        select
          turn + 1,
          monkey_id,
          case
            when (turn + 1) % (select count(*) from monkeys) = monkey_id then
              array[]::bigint[]
            else
              items || coalesce(ci.caught_items, array[]::bigint[])
          end
        from turns b
        left join caught_items ci using (monkey_id)
        where turn + 1 < (select count(*) from monkeys) * 10000
      ) q
    )
    select * from turns
  ) q
),
inspected_items as (
  select
    monkey_id,
    case
      when turn % (select count(*) from monkeys) = monkey_id then
        lag(items) over (partition by monkey_id order by turn)
    end inspected_items
  from turns
  order by turn, monkey_id
),
most_active_monkeys as (
  select
    monkey_id,
    sum(array_length(inspected_items, 1)) num_inspected
  from inspected_items
  group by monkey_id
  order by num_inspected desc
  limit 2
)
select
  (
    select num_inspected
    from most_active_monkeys
    order by num_inspected desc
    limit 1
  ) * (
    select num_inspected
    from most_active_monkeys
    order by num_inspected desc
    limit 1
    offset 1
  ) monkey_business
