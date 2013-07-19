package main

import (
  "fmt"
  "code.google.com/p/gosqlite/sqlite"
  "net/http"
  "encoding/json"
  "strconv"
)

const InsertMeasurement string = "INSERT INTO temperatures(logged_at, temperature) VALUES"
const GetAllMeasurement string = "SELECT * FROM temperatures;"
const FindMeasurement string = "SELECT * FROM temperatures where _id = ?"

type Measurement struct {
  Id int
  LoggedAt string
  Temperature float64
  BrewId int
}

func (m *Measurement) save(c *sqlite.Conn) {
  insert := fmt.Sprintf("%s(%s, %g);", InsertMeasurement, m.LoggedAt, m.Temperature)
  fmt.Println(insert)
}

func (m *Measurement) toString() (string){
  return fmt.Sprintf("[logged_at: %s, temperature: %g]", m.LoggedAt, m.Temperature)
}

func (m *Measurement) all(c *sqlite.Conn) []Measurement{
  var ms []Measurement;
  selectStatement, err := c.Prepare(GetAllMeasurement)
  if err != nil {
    fmt.Println("Error while selecting: %s", err)
  }

  for i := 0; selectStatement.Next(); i++ {
    var measurement Measurement

    err = selectStatement.Scan(&measurement.Id, &measurement.LoggedAt, &measurement.Temperature, &measurement.BrewId)
    if err != nil {
      fmt.Printf("Error while getting row data: %s\n", err)
    }
    ms = append(ms, measurement)
  }
  return ms
}

func (m *Measurement) find(id int, c *sqlite.Conn) Measurement {
  statement, err := c.Prepare(FindMeasurement)
  if err != nil {
    fmt.Println("Error while finding", err)
  }
  err = statement.Exec(id)
  statement.Next()
  var measurement Measurement
  err = statement.Scan(&measurement.Id, &measurement.LoggedAt, &measurement.Temperature, &measurement.BrewId)
  if err != nil {
    fmt.Printf("Error while getting row data: %s\n", err)
  }
  return measurement
}

func (m *Measurement) isValid() bool {
  return m.Id > 0
}

const InsertBrew string = "INSERT INTO brews(name, active) VALUES"
const GetAllBrew string = "SELECT * FROM brews;"
const FindBrew string = "SELECT * FROM brews where _id = ?"

type Brew struct {
  Id int
  Name string
  Active bool
}

func (m *Brew) save(c *sqlite.Conn) {
  insert := fmt.Sprintf("%s(%s, %b)", InsertBrew, m.Name, m.Active)
  fmt.Println(insert)
}

func (m *Brew) all(c *sqlite.Conn) {
  
}

func openDatabase() *sqlite.Conn {
  conn, _ := sqlite.Open("test.db")
  return conn
}

func measurements() []Measurement {
  conn := openDatabase()
  defer conn.Close()

  var m Measurement
  return m.all(conn)
}

func measurement(id int) Measurement {
  conn := openDatabase()
  defer conn.Close()

  var m Measurement
  return m.find(id, conn)
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
  conn := openDatabase()
  defer conn.Close()

  var m Measurement
  ms := m.all(conn)
  for i, measurement := range ms {
    j, _ := json.Marshal(measurement)
    fmt.Fprintf(w, "<h1>Reading #%d</h1><p>%s</p>", i, j)
  }
}

const measurementsPath = "/measurements/"
const measurementsPathLen = len(measurementsPath)
func measurementsHandler(w http.ResponseWriter, r *http.Request) {
  if(r.Header.Get("Content-Type") != "application/json") {
    fmt.Fprintf(w, "Invalid Request")
    return
  }
  w.Header().Set("Content-Type", "application/json")
  switch r.Method {
  case "POST":
    return
    //createMeasurement(w, r)
  case "GET":
    remainingPath := r.URL.Path[measurementsPathLen:]
    if len(remainingPath) == 0 {
      listMeasurements(w, r)
    } else {
      showMeasurement(remainingPath, w, r)
    }
  }
}

const brewsPath = "/brews/"
const brewsPathLen = len(brewsPath)
func brewsHandler(w http.ResponseWriter, r *http.Request) {
  if(r.Header.Get("Content-Type") != "application/json") {
    fmt.Printf(w, "Invalid Request")
    return
  }
  w.Header().Set("Content-Type", "application/json")
  switch r.Method {
  case "POST":
    // createBrew(w, r)
    return
  case "GET":
    // listBrews(w, r)
    return
  }
}

func listMeasurements(w http.ResponseWriter, r *http.Request) {
  j, _  := json.Marshal(measurements())
  w.Write([]byte(j))
}

func showMeasurement(path string, w http.ResponseWriter, r *http.Request) {
  id, err := strconv.Atoi(path)
  if err != nil {
    w.WriteHeader(http.StatusNotFound)
    fmt.Fprintf(w, "%q is not a valid identifier", path)
    return
  }
  measurement := measurement(id)
  if !measurement.isValid() {
    w.WriteHeader(http.StatusNotFound)
    fmt.Fprintf(w, "No measurement exists with id %d", id)
    return
  }
  j, _ := json.Marshal(measurement)
  w.Write([]byte(j))
}

func main() {
  http.HandleFunc(measurementsPath, measurementsHandler)
  http.HandleFunc(brewsPath, brewsHandler)
  http.HandleFunc("/", indexHandler)
  http.ListenAndServe(":8080", nil)
}