import LLVM

let module = Module(name: "main")

let src = """
(print (+ 1 2 3 (+ 2.0 3.0)))

(print (+ 3 4 5))
"""

let form = try Reader.read(src)
//let ir = formToMothIR(form)

let builder = Builder()
//try builder.buildIR(MothIR.defineGlobal(name: "test", value: .integer(1)))
builder.module.dump()
