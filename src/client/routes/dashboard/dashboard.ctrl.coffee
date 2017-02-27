'use strict'

angular.module 'appMon'
.controller 'DashboardCtrl', ($scope, $http, $interval, $filter, base64) ->
  $scope.url = ''
  $scope.username = ''
  $scope.password = ''
  $scope.tickTime = 3
  $scope.minsToShow = 30
  Series = (legend, color, type) ->
    type: type or 'area'
    name: legend
    color: color
    fillColor:
      linearGradient:
        x1: 0
        y1: 0
        x2: 0
        y2: 1
      stops: [
        [0, color]
        [1, Highcharts.Color(color).setOpacity(0).get('rgba')]
      ]
    data: []
  Options = (title, yTitle, series) ->
    options:
      chart:
        type: 'area'
        zoomType: 'x'
    credits:
      enabled: false
    func: (chart) ->
      $scope.$evalAsync ->
        chart.reflow()
    series: series
    xAxis:
      type: 'datetime'
    yAxis:
      title:
        text: yTitle
    title:
      text: title
    plotOptions:
      marker:
        radius: 1
      lineWidth: 1
      states:
        hover:
          lineWidth: 1
      threshold: null
  memchart = Options 'Memory', 'Mb', [Series('Memory Usage', '#D31996')]
  cacheChart = Options 'Sql Cache', 'Size', [Series('Sql Cache Size', Highcharts.getOptions().colors[0])]
  dbChart = Options 'Database', 'No Events', [Series('Select', '#19D396', 'line'), Series('Insert', '#9619D3', 'line')]
  reqChart = Options 'Requests', 'No Requests', [Series('All', '#19D396', 'line'), Series('GET', '#9619D3', 'line'), Series('POST', '#96D319', 'line')]
  cpuChart = Options 'Cpu', 'Percentage', [Series('Cpu Usage', '#96D319')]
  resChart = Options 'Response Time', 'Time / ms', [Series('Avg Response Time', '#1996d3')]
  $scope.charts = [memchart, cacheChart, dbChart, reqChart, cpuChart, resChart]
  stop = null
  last = {}
  getChange = (now, last, field) ->
    if now and last
      return (now[field] - last[field]) / $scope.tickTime
    else
      null
  scroll = ->
    len = Math.floor($scope.minsToShow * 60 / $scope.tickTime)
    for chart in $scope.charts
      for series in chart.series
        if series.data.length > len
          series.data.splice 0, series.data.length - len
  $scope.connect = ->
    if angular.isDefined stop
      $interval.cancel stop
      stop = undefined
    $scope.connected = false
    user = "#{$scope.username}:#{$scope.password}"
    $http.defaults.headers.common['Authorization'] = 'Basic ' + base64.encode(user)
    $http.post "#{$scope.url}/auth/token"
    .then (response) ->
      if response.data and response.data.accessToken
        for chart in $scope.charts
          for series in chart.series
            series.data = []
        $scope.connected = true
        $http.defaults.headers.common['Authorization'] = 'Bearer ' + response.data.accessToken
        stop = $interval ->
          $http.get "#{$scope.url}/api/profiler"
          .then (response) ->
            $scope.serverVersion = response.data.version
            $scope.databaseVersion = response.data.dbVersion
            $scope.startTime = $filter('timeAgo') response.data.start
            memchart.series[0].data.push [new Date().valueOf(), response.data.memory]
            cacheChart.series[0].data.push [new Date().valueOf(), response.data.sqlCacheSize]
            dbChart.series[0].data.push [new Date().valueOf(), response.data.db.select]
            dbChart.series[1].data.push [new Date().valueOf(), response.data.db.insert]
            reqChart.series[0].data.push [new Date().valueOf(), response.data.count.all]
            reqChart.series[1].data.push [new Date().valueOf(), response.data.count.GET]
            reqChart.series[2].data.push [new Date().valueOf(), response.data.count.POST]
            ###
            dbChart.series[0].data.push [new Date().valueOf(), getChange(response.data.db, last.db, 'select')]
            dbChart.series[1].data.push [new Date().valueOf(), getChange(response.data.db, last.db, 'insert')]
            reqChart.series[0].data.push [new Date().valueOf(), getChange(response.data.count, last.count, 'all')]
            reqChart.series[1].data.push [new Date().valueOf(), getChange(response.data.count, last.count, 'GET')]
            reqChart.series[2].data.push [new Date().valueOf(), getChange(response.data.count, last.count, 'POST')]
            ###
            cpuChart.series[0].data.push [new Date().valueOf(), response.data.cpu.percent]
            resChart.series[0].data.push [new Date().valueOf(), response.data.responseTime / response.data.count.total]
            scroll()
            last = response.data
          , (err) ->
            false
        , $scope.tickTime * 1000
    , (err) ->
      false
  $scope.connect()