CREATE TABLE temperatures (
  _id INTEGER PRIMARY KEY ASC,
  logged_at varchar(255),
  temperature real,
  brew_id integer DEFAULT 0
);
CREATE INDEX temperature_id_index ON temperatures(_id);

CREATE TABLE brews (
  _id INTEGER PRIMARY KEY ASC,
  name varchar(255),
  active boolean
);
CREATE INDEX brews_id_index ON brews(_id);
CREATE TRIGGER new_brew_trigger 
  BEFORE INSERT ON brews
  BEGIN
    UPDATE brews SET active = 0 WHERE active == 1;
  END;

INSERT INTO 
  temperatures (logged_at, temperature)
VALUES
  ('2012-01-01 12:30:00', 25.5),
  ('2012-01-02 12:30:00', 19.0),
  ('2012-01-03 12:30:00', 21.0);