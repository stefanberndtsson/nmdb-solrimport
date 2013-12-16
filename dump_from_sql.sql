\t on
\a
\pset fieldsep '	'
\o data/movie_connection_texts.dat
SELECT id,movie_id,linked_movie_id,movie_connection_type_id,value,created_at,updated_at
  FROM movie_connection_texts;

