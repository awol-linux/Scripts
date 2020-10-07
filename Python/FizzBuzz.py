#!/bin/python

number_rules = dict([(5,'Buzz'), (3,'Fizz')])

for i in range (15):
	for x in number_rules:
		if i > 1 and x > 1:
			if (i % x == 0):
				print(number_rules[x])
	else: 
		print(i)
