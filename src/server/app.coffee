'use strict'

ndx = require 'ndx-server'
.config
  database: 'nam'
  tables: ['users']
  localStorage: './data'
.use 'ndx-static-routes'
.start()
