package main

import (
  "fmt"
  "code.google.com/p/gosqlite/sqlite"
  "net/http"
  "encoding/json"
)

const InsertMeasurement string = "INSERT INTO temperatures(logged_at, temperature) VALUES"
const GetAllMeasurement string = "SELECT * FROM temperatures;"

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

type Brew struct {
  Id int
  Name string
  Active bool
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

const measurementsPath = "/measurements"
const measurementsPathLen = len(measurementsPath)
func measurementsHandler(w http.ResponseWriter, r *http.Request) {
  switch r.Method {
  case "POST":
    return
    //createMeasurement(w, r)
  case "GET":
    remainingPath := r.URL.Path[measurementsPathLen:]
    if len(remainingPath) == 0 {
      listMeasurements(w, r)
    } else {
      //showMeasurement(remainingPath, w, r)
    }
  }
}

func listMeasurements(w http.ResponseWriter, r *http.Request) {
  if(r.Header.Get("Content-Type") != "application/json") {
    fmt.Fprintf(w, "Invalid Request")
    return
  }
  w.Header().Set("Content-Type", "application/json")
  j, _  := json.Marshal(measurements())
  w.Write([]byte(j))
}

func main() {
  http.HandleFunc(measurementsPath, measurementsHandler)
  http.HandleFunc("/", indexHandler)
  http.ListenAndServe(":8080", nil)
}

// func main() {

//   conn, _ := sqlite.Open("test.db")
//   defer conn.Close()

//   var m Measurement
//   ms := m.all(conn)
//   for _, measurement := range ms {
//     fmt.Println(measurement.toString())
//   }
// }