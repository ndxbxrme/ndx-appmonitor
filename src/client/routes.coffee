'use strict'

angular.module 'appMon'
.config ($stateProvider, $locationProvider, $urlRouterProvider) ->
  $stateProvider
  .state 'dashboard',
    url: '/'
    templateUrl: 'routes/dashboard/dashboard.html'
    controller: 'DashboardCtrl'
  .state 'invited',
    url: '/invited'
    templateUrl: 'routes/invited/invited.html'
    controller: 'InvitedCtrl'
  $urlRouterProvider.otherwise '/'
  $locationProvider.html5Mode true