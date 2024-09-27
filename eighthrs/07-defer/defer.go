package main

import "fmt"

func main() {
	defer fmt.Println("deferred main end1")
	defer fmt.Println("deferred main end2")

	fmt.Println("main end1")
	fmt.Println("main end2")
}