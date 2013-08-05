var aspectRatio = 3 / 4;
var chart = $('#chart');
var margin = {top: 20, right: 30, bottom: 50, left: 50},
    width = chart.width() - margin.left - margin.right,
    height = (chart.width() * aspectRatio) - margin.top - margin.bottom;

var DEG = "\u00B0";
var LIGHT_BLUE  = '#7375D8';
var LIGHT_GREEN = '#74E868';
var LIGHT_RED   = '#FF8073';
var SAFE_UPPER_BOUND = 22;
var SAFE_LOWER_BOUND = 18;

// Fermentation ranges for an Ale
var COLORED_RANGES = [
  {lowerBound: SAFE_UPPER_BOUND, color: LIGHT_RED}, // above preferred fermentation range
  {upperBound: SAFE_UPPER_BOUND, lowerBound: SAFE_LOWER_BOUND, color: LIGHT_GREEN}, // preferred fermentation range
  {upperBound: SAFE_LOWER_BOUND, color: LIGHT_BLUE} // below preferred fermentation range
]

var parseDate = d3.time.format("%Y-%m-%d %H:%M:%S").parse;

var x = d3.time.scale()
        .range([0, width]);

var y = d3.scale.linear()
        .range([height, 0]);

var xAxis = d3.svg.axis()
            .scale(x)
            .orient("bottom");

var yAxis = d3.svg.axis()
            .scale(y)
            .orient("left");

var line = d3.svg.line()
           .x(function(d) { return x(d.logged_at); })
           .y(function(d) { return y(d.reading); });

var svg = d3.select("#chart").append("svg")
          .attr("width", width + margin.left + margin.right)
          .attr("height", height + margin.top + margin.bottom)
          .append("g")
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

var determineRange = function(data) {
  // return [0, 30];
  return [
    Math.min(d3.min(data, function(d) { return d.reading }), SAFE_LOWER_BOUND) - 2,
    Math.max(d3.max(data, function(d) { return d.reading }), SAFE_UPPER_BOUND) + 2
  ];
}

var applyColors = function(svg) {
  yDomain = y.domain()
  yTop = yDomain[1]
  yBottom = yDomain[0]
  barHeight = height / (yTop - yBottom)
  COLORED_RANGES.forEach(function (entry){
    entry.y = (entry.upperBound ? yTop - entry.upperBound : 0) * barHeight;
    entry.height = (entry.lowerBound ? yTop - entry.lowerBound : yBottom) * barHeight
  });

  var rectangles = svg.selectAll('rect')
     .data(COLORED_RANGES)
     .enter()
     .append('rect');

  var rectangleAttributes = rectangles
                            .attr("x", function(d){ return 0; })
                            .attr("y", function(d){ return d.y; })
                            .attr("height", function(d){ return d.height; })
                            .attr("width", function(d){ return width; })
                            .style("fill", function(d){ return d.color });
}
var success = function(data) {
  data.forEach(function(d){
    d.logged_at = parseDate(d.logged_at);
    d.reading = +d.reading;
    console.log(d);
  });

  x.domain(d3.extent(data, function(d) { return d.logged_at; }));
  y.domain(determineRange(data));

  applyColors(svg);

  svg.append("g")
     .attr("class", "x axis")
     .attr("transform", "translate(0, " + height + ")")
     .call(xAxis);

  svg.append("g")
     .attr("class", "y axis")
     .call(yAxis)
     .append("text")
     .attr("transform", "rotate(-90)")
     .attr("y", 6)
     .attr("dy", "0.71em")
     .style("text-anchor", "end")
     .text("Reading (" + DEG + "C)");

  svg.append("path")
     .datum(data)
     .attr("class", "line")
     .attr("d", line);
};

reqwest({
  url: document.location.pathname + '/temperatures',
  type: 'json',
  contentType: 'application/json',
  method: 'get',
  error: function(err) { alert("Something has gone wrong"); console.log(err);},
  success: function(resp) { success(resp); }
});