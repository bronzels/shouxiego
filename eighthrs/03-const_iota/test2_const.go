package main

import "fmt"

const (
	BEIJING = 10*iota
	SHANGHAI
	SHENZHEN
)

const (
	a, b = iota + 1, iota + 2
	c, d
	e, f 

	g, h = iota * 2, iota * 3 
	i, j
)

func main() {
	const length int = 10

	fmt.Println("length = ", length)

	fmt.Println("BEIJING = ", BEIJING)
	fmt.Println("SHANGHAI = ", SHANGHAI)
	fmt.Println("SHENZHEN = ", SHENZHEN)

	fmt.Println("a = ", a, ", b = ", b)
	fmt.Println("c = ", c, ", d = ", d)
	fmt.Println("e = ", e, ", f = ", f)

	fmt.Println("g = ", g, ", h = ", h)
	fmt.Println("i = ", i, ", j = ", j)

	// iota只能配合const() 一起使用，iota只有在const进行累加效果。
	//var a int = iota

}

