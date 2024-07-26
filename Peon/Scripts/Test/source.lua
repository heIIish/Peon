local things = require "things"

echo("Test script config value:", Configuration.testValue)

for i = 1, #things do
	echo(i, things[i])
end