import LLVM

let module = Module(name: "main")

let testInput = """
(do
    (fn (z)
        (let (x 1)
            (print x)
            (print x))

        (let (y 2)
            (print y)))
    (fn (w)
        (print w)))
"""

//let testInput = "(fn (x) x)"

let form = try Reader.read(testInput)

let compiler = Compiler()

print(String(describing: form))
print(String(describing: compiler.compile(input: form)))
