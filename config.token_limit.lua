local _, fluffy = ...

-- ---------------------------------------------------------------------------
-- Token processing limit
-- Controls the maximum number of tokens processed per calculation cycle.
-- Increased from 10000 to 20000 to allow more complex rotation analysis.
-- ---------------------------------------------------------------------------
fluffy.token_limit = 20000;
