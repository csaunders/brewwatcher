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
  LoggedAt string
  Temperature float64
  BrewName string
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

    err = selectStatement.Scan(&measurement.LoggedAt, &measurement.Temperature)
    if err != nil {
      fmt.Printf("Error while getting row data: %s\n", err)
    }
    ms = append(ms, measurement)
  }
  return ms
}

func openDatabase() *sqlite.Conn {
  conn, _ := sqlite.Open("test.db")
  return conn
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

func main() {
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