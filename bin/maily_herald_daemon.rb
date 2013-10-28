#!/usr/bin/env ruby

require 'rubygems'
require 'daemons'
require 'maily_herald'

Daemons.run('bin/maily_herald.rb')
