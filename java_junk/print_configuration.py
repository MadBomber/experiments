#!/usr/bin/env jython
# print_configuration.py

from java.lang import System

props = System.getProperties()
names = []
for name in props.keys():
  names.append(name)

names.sort() # now you can list the keys in alpha order

print '\nThe following propertis are available:'
for k in names:
  print '\t', k

print '\nThe value of java.class.path is:' 

for val in props['java.class.path'].split(':'):
  print '\t', val

print
