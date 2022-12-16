with shape_scores (shape, score) as (
  values
    ('rock', 1),
    ('paper', 2),
    ('scissors', 3)
),
outcome_scores (outcome, score) as (
  values
    ('loss', 0),
    ('draw', 3),
    ('win', 6)
),
shapes (shape, losing_shape, winning_shape) as (
  values
    ('rock', 'scissors', 'paper'),
    ('paper', 'rock', 'scissors'),
    ('scissors', 'paper', 'rock')
),
matches as (
  with lines as (
    select
      string_to_array(unnest(string_to_array(:'input', E'\n')), ' ') match
  )
  select
    case match[1]
      when 'A' then 'rock'
      when 'B' then 'paper'
      when 'C' then 'scissors'
    end their_play,
    case match[2]
      when 'X' then 'loss'
      when 'Y' then 'draw'
      when 'Z' then 'win'
    end outcome
  from lines
),
outcomes as (
  select
    case m.outcome
      when 'draw' then m.their_play
      when 'win' then s.winning_shape
      when 'loss' then s.losing_shape
    end my_play,
    m.outcome
  from matches m
  inner join shapes s on s.shape = m.their_play
)
select
  sum(ss.score + os.score) total_score
from outcomes o
inner join shape_scores ss on ss.shape = o.my_play
inner join outcome_scores os on os.outcome = o.outcome
