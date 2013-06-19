CREATE TABLE temperatures (
  logged_at varchar(255),
  temperature real
);

INSERT INTO 
  temperatures (logged_at, temperature)
VALUES
  ('2012-01-01 12:30:00', 25.5),
  ('2012-01-02 12:30:00', 19.0),
  ('2012-01-03 12:30:00', 21.0);