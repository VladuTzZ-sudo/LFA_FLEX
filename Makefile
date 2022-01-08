# Matei Vlad Cristian - 331CC
build:
	flex golang.l
	g++ -o golang lex.yy.c
run:
	./golang test1

run_debug:
	./golang test1 on

clear:
	rm golang
