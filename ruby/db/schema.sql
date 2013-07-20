CREATE TABLE IF NOT EXISTS temperatures (
  id INTEGER PRIMARY KEY ASC,
  logged_at varchar(255),
  reading real,
  brew_id integer DEFAULT 0
);
 --execcmd
CREATE INDEX IF NOT EXISTS temperature_id_index ON temperatures(id);

--execcmd
CREATE TABLE IF NOT EXISTS brews (
  id INTEGER PRIMARY KEY ASC,
  name varchar(255),
  active boolean DEFAULT 0
);
--execcmd
CREATE INDEX IF NOT EXISTS  brews_id_index ON brews(id);
--execcmd
CREATE TRIGGER IF NOT EXISTS  new_brew_trigger 
  BEFORE INSERT ON brews
  WHEN (NEW.active = 't')
  BEGIN
    UPDATE brews SET active = 'f' WHERE active = 't';
  END;