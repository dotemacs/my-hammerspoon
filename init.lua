-- First run:
-- $ brew install luarocks
-- $ luarocks install fennel

local fennel = require "fennel"

table.insert(package.loaders or package.searchers, fennel.searcher)

local spork = require "spork"
