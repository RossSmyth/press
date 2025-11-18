Value of "sys.inputs.language" is #sys.inputs.language

#if sys.inputs.name != "John Doe" {
  panic("Expected 'John Doe' in 'sys.inputs.name' but got " + sys.inputs.name)
}
