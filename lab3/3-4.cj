import std.collection.*

// LL(1) 分析器类
class LL1Analyzer {
    public var grammar: HashMap<String, ArrayList<String>> = HashMap<String, ArrayList<String>>()
    public var first: HashMap<String, HashSet<String>> = HashMap<String, HashSet<String>>()
    public var follow: HashMap<String, HashSet<String>> = HashMap<String, HashSet<String>>()
    public var parsingTable: HashMap<String, HashMap<String, String>> = HashMap<String, HashMap<String, String>>()
    public var startSymbol: String = ""
    
    public init(grammarInput: HashMap<String, ArrayList<String>>, start: String) {
        grammar = grammarInput
        startSymbol = start
        
        // 初始化 FIRST 和 FOLLOW 集
        for ((nt, _) in grammar) {
            first[nt] = HashSet<String>()
            follow[nt] = HashSet<String>()
        }
    }
    
    // 计算 FIRST 集
    public func computeFirst(): Unit {
        for ((nt, _) in grammar) {
            computeFirstForSymbol(nt)
        }
    }
    
    private func computeFirstForSymbol(nonTerminal: String): HashSet<String> {
        let resultOpt = first.get(nonTerminal)
        if (resultOpt.isSome() && !resultOpt.getOrThrow().isEmpty()) {
            return resultOpt.getOrThrow()
        }
        
        let result = HashSet<String>()
        let prodsOpt = grammar.get(nonTerminal)
        if (prodsOpt.isNone()) {
            return result
        }
        
        let prods = prodsOpt.getOrThrow()
        for (production in prods) {
            if (production == "ε") {
                result.add("ε")
                continue
            }
            
            var allHaveEpsilon = true
            for (i in 0..production.size) {
                let symbol = production[i..i+1]
                
                if (isLower(symbol)) {
                    // 终结符直接加入
                    result.add(symbol)
                    allHaveEpsilon = false
                    break
                } else if (isUpper(symbol)) {
                    // 非终结符,递归计算
                    let symbolFirst = computeFirstForSymbol(symbol)
                    for (s in symbolFirst) {
                        if (s != "ε") {
                            result.add(s)
                        }
                    }
                    
                    if (!symbolFirst.contains("ε")) {
                        allHaveEpsilon = false
                        break
                    }
                }
                
                // 如果是最后一个符号且所有都有空串
                if (i == production.size - 1 && allHaveEpsilon) {
                    result.add("ε")
                }
            }
        }
        
        first[nonTerminal] = result
        return result
    }
    
    // 计算 FOLLOW 集
    public func computeFollow(): Unit {
        // 起始符号的 FOLLOW 集包含 $
        follow[startSymbol].add("$")
        
        var changed = true
        while (changed) {
            changed = false
            
            for ((nt, prods) in grammar) {
                for (production in prods) {
                    if (production == "ε") {
                        continue
                    }
                    
                    for (i in 0..production.size) {
                        let B = production[i..i+1]
                        
                        if (isUpper(B)) {
                            let beforeSize = follow[B].size
                            
                            if (i + 1 < production.size) {
                                let nextSymbol = production[i+1..i+2]
                                
                                if (isLower(nextSymbol)) {
                                    follow[B].add(nextSymbol)
                                } else {
                                    let nextFirstOpt = first.get(nextSymbol)
                                    if (nextFirstOpt.isSome()) {
                                        for (s in nextFirstOpt.getOrThrow()) {
                                            if (s != "ε") {
                                                follow[B].add(s)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // 如果是最后一个符号或下一个符号的FIRST包含ε
                            if (i + 1 == production.size) {
                                let ntFollowOpt = follow.get(nt)
                                if (ntFollowOpt.isSome()) {
                                    for (s in ntFollowOpt.getOrThrow()) {
                                        follow[B].add(s)
                                    }
                                }
                            } else if (i + 1 < production.size) {
                                let nextSymbol = production[i+1..i+2]
                                let nextFirstOpt = first.get(nextSymbol)
                                if (nextFirstOpt.isSome() && nextFirstOpt.getOrThrow().contains("ε")) {
                                    let ntFollowOpt = follow.get(nt)
                                    if (ntFollowOpt.isSome()) {
                                        for (s in ntFollowOpt.getOrThrow()) {
                                            follow[B].add(s)
                                        }
                                    }
                                }
                            }
                            
                            if (follow[B].size > beforeSize) {
                                changed = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 检查是否为 LL(1) 文法
    public func isLL1(): Bool {
        for ((nt, prods) in grammar) {
            let firstSets = ArrayList<HashSet<String>>()
            
            for (production in prods) {
                let prodFirst = HashSet<String>()
                
                if (production == "ε") {
                    prodFirst.add("ε")
                } else {
                    var allHaveEpsilon = true
                    for (i in 0..production.size) {
                        let symbol = production[i..i+1]
                        
                        if (isLower(symbol)) {
                            prodFirst.add(symbol)
                            allHaveEpsilon = false
                            break
                        } else if (isUpper(symbol)) {
                            let symbolFirstOpt = first.get(symbol)
                            if (symbolFirstOpt.isSome()) {
                                for (s in symbolFirstOpt.getOrThrow()) {
                                    if (s != "ε") {
                                        prodFirst.add(s)
                                    }
                                }
                                
                                if (!symbolFirstOpt.getOrThrow().contains("ε")) {
                                    allHaveEpsilon = false
                                    break
                                }
                            } else {
                                allHaveEpsilon = false
                                break
                            }
                        }
                        
                        if (i == production.size - 1 && allHaveEpsilon) {
                            prodFirst.add("ε")
                        }
                    }
                }
                
                // 检查是否与之前的 FIRST 集有交集
                for (existingFirst in firstSets) {
                    for (s in prodFirst) {
                        if (existingFirst.contains(s)) {
                            return false
                        }
                    }
                }
                
                firstSets.add(prodFirst)
            }
            
            // 如果 FIRST 集包含 ε,检查 FOLLOW 集是否冲突
            let ntFirstOpt = first.get(nt)
            if (ntFirstOpt.isSome() && ntFirstOpt.getOrThrow().contains("ε")) {
                let ntFollowOpt = follow.get(nt)
                if (ntFollowOpt.isSome()) {
                    for (terminal in ntFollowOpt.getOrThrow()) {
                        for (prodFirst in firstSets) {
                            if (prodFirst.contains(terminal)) {
                                return false
                            }
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    // 构造预测分析表
    public func constructParsingTable(): Unit {
        for ((nt, prods) in grammar) {
            if (!parsingTable.contains(nt)) {
                parsingTable[nt] = HashMap<String, String>()
            }
            
            for (production in prods) {
                let prodFirst = HashSet<String>()
                
                if (production == "ε") {
                    prodFirst.add("ε")
                } else {
                    var allHaveEpsilon = true
                    for (i in 0..production.size) {
                        let symbol = production[i..i+1]
                        
                        if (isLower(symbol)) {
                            prodFirst.add(symbol)
                            allHaveEpsilon = false
                            break
                        } else if (isUpper(symbol)) {
                            let symbolFirstOpt = first.get(symbol)
                            if (symbolFirstOpt.isSome()) {
                                for (s in symbolFirstOpt.getOrThrow()) {
                                    if (s != "ε") {
                                        prodFirst.add(s)
                                    }
                                }
                                
                                if (!symbolFirstOpt.getOrThrow().contains("ε")) {
                                    allHaveEpsilon = false
                                    break
                                }
                            }
                        }
                        
                        if (i == production.size - 1 && allHaveEpsilon) {
                            prodFirst.add("ε")
                        }
                    }
                }
                
                // 将 FIRST 集中的终结符添加到预测分析表
                for (terminal in prodFirst) {
                    if (terminal != "ε") {
                        parsingTable[nt][terminal] = production
                    }
                }
                
                // 如果包含 ε,将 FOLLOW 集中的终结符添加到预测分析表
                if (prodFirst.contains("ε")) {
                    let ntFollowOpt = follow.get(nt)
                    if (ntFollowOpt.isSome()) {
                        for (terminal in ntFollowOpt.getOrThrow()) {
                            if (!parsingTable[nt].contains(terminal)) {
                                parsingTable[nt][terminal] = production
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 显示 FIRST 和 FOLLOW 集
    public func displayTable(): Unit {
        println("+--------------+---------------+---------------+")
        println("| 非终结符     | FIRST 集      | FOLLOW 集     |")
        println("+--------------+---------------+---------------+")
        
        for ((nt, _) in grammar) {
            var firstStr = ""
            var firstCount = 0
            let firstSetOpt = first.get(nt)
            if (firstSetOpt.isSome()) {
                for (s in firstSetOpt.getOrThrow()) {
                    if (firstCount > 0) {
                        firstStr = firstStr + ", "
                    }
                    firstStr = firstStr + s
                    firstCount++
                }
            }
            
            var followStr = ""
            var followCount = 0
            let followSetOpt = follow.get(nt)
            if (followSetOpt.isSome()) {
                for (s in followSetOpt.getOrThrow()) {
                    if (followCount > 0) {
                        followStr = followStr + ", "
                    }
                    followStr = followStr + s
                    followCount++
                }
            }
            
            print("| ")
            print(nt)
            for (_ in 0..(12 - nt.size)) {
                print(" ")
            }
            print(" | ")
            print(firstStr)
            for (_ in 0..(13 - firstStr.size)) {
                print(" ")
            }
            print(" | ")
            print(followStr)
            for (_ in 0..(13 - followStr.size)) {
                print(" ")
            }
            println(" |")
        }
        
        println("+--------------+---------------+---------------+")
    }
    
    // 显示预测分析表
    public func displayParsingTable(terminals: ArrayList<String>): Unit {
        println("\n预测分析表:")
        
        // 打印表头
        print("+---------------")
        for (_ in terminals) {
            print("+---------------")
        }
        println("+")
        
        print("| 非终结符      ")
        for (t in terminals) {
            print("| ")
            print(t)
            for (_ in 0..(13 - t.size)) {
                print(" ")
            }
            print(" ")
        }
        println("|")
        
        print("+---------------")
        for (_ in terminals) {
            print("+---------------")
        }
        println("+")
        
        // 打印表格内容
        for ((nt, _) in grammar) {
            print("| ")
            print(nt)
            for (_ in 0..(13 - nt.size)) {
                print(" ")
            }
            print(" ")
            
            for (t in terminals) {
                print("| ")
                
                let tableOpt = parsingTable.get(nt)
                if (tableOpt.isSome()) {
                    let prodOpt = tableOpt.getOrThrow().get(t)
                    if (prodOpt.isSome()) {
                        let entry = nt + " -> " + prodOpt.getOrThrow()
                        print(entry)
                        for (_ in 0..(13 - entry.size)) {
                            print(" ")
                        }
                        print(" ")
                    } else {
                        print("              ")
                    }
                } else {
                    print("              ")
                }
            }
            println("|")
        }
        
        print("+---------------")
        for (_ in terminals) {
            print("+---------------")
        }
        println("+")
    }
    
    // LL(1) 语法分析
    public func parse(inputString: String): (Bool, ArrayList<String>) {
        var stack = ArrayList<String>()
        stack.add(startSymbol)
        
        let inputBuffer = ArrayList<String>()
        for (c in inputString) {
            // 将字符转换为字符串
            var charStr = ""
            let charA: UInt8 = 'a'
            let charZ: UInt8 = 'z'
            if (c >= charA && c <= charZ) {
                let offset = c - charA
                charStr = "abcdefghijklmnopqrstuvwxyz"[Int64(offset)..Int64(offset + 1)]
            }
            if (!charStr.isEmpty()) {
                inputBuffer.add(charStr)
            }
        }
        inputBuffer.add("$")
        
        let process = ArrayList<String>()
        var inputIndex = 0
        
        while (!stack.isEmpty()) {
            let top = stack[stack.size - 1]
            // 移除最后一个元素
            let newStack = ArrayList<String>()
            for (i in 0..(stack.size - 1)) {
                newStack.add(stack[i])
            }
            stack = newStack
            
            let currentSymbol = inputBuffer[inputIndex]
            
            // 记录解析过程
            var stackStr = "栈: ["
            for (i in 0..stack.size) {
                stackStr = stackStr + stack[i]
                if (i < stack.size - 1) {
                    stackStr = stackStr + ", "
                }
            }
            stackStr = stackStr + "], 当前符号: " + currentSymbol + ", 栈顶: " + top
            process.add(stackStr)
            
            if (isLower(top) || top == "$") {
                // 终结符或结束符
                if (top == currentSymbol) {
                    inputIndex++
                } else {
                    return (false, process)
                }
            } else if (isUpper(top)) {
                // 非终结符
                let tableOpt = parsingTable.get(top)
                if (tableOpt.isSome()) {
                    let prodOpt = tableOpt.getOrThrow().get(currentSymbol)
                    if (prodOpt.isSome()) {
                        let production = prodOpt.getOrThrow()
                        if (production != "ε") {
                            // 逆序入栈
                            for (i in 0..production.size) {
                                let idx = production.size - 1 - i
                                stack.add(production[idx..idx+1])
                            }
                        }
                    } else {
                        return (false, process)
                    }
                } else {
                    return (false, process)
                }
            }
        }
        
        let success = inputIndex >= inputBuffer.size || inputBuffer[inputIndex] == "$"
        return (success, process)
    }
    
    // 辅助函数：判断是否为小写字母
    private func isLower(s: String): Bool {
        if (s.isEmpty()) {
            return false
        }
        let c = s[0]
        let charA: UInt8 = 'a'
        let charZ: UInt8 = 'z'
        return c >= charA && c <= charZ
    }
    
    // 辅助函数：判断是否为大写字母
    private func isUpper(s: String): Bool {
        if (s.isEmpty()) {
            return false
        }
        let c = s[0]
        let charA: UInt8 = 'A'
        let charZ: UInt8 = 'Z'
        return c >= charA && c <= charZ
    }
}

// 主函数
main() {
    // 定义文法字符串
    let grammarContent = """
    S -> AB
    A -> aA | ε
    B -> b
    """
    
    println("文法定义:")
    println(grammarContent)
    
    // 解析文法
    let grammar = HashMap<String, ArrayList<String>>()
    let lines = grammarContent.split('\n')
    
    let spaceChar: UInt8 = ' '
    let tabChar: UInt8 = '\t'
    let crChar: UInt8 = '\r'
    
    var startSymbol = ""
    
    for (line in lines) {
        var trimmed = line
        while (!trimmed.isEmpty() && (trimmed[0] == spaceChar || trimmed[0] == tabChar || trimmed[0] == crChar)) {
            trimmed = trimmed[1..]
        }
        while (!trimmed.isEmpty() && (trimmed[trimmed.size - 1] == spaceChar || trimmed[trimmed.size - 1] == tabChar || trimmed[trimmed.size - 1] == crChar)) {
            trimmed = trimmed[0..(trimmed.size - 1)]
        }
        
        if (trimmed.isEmpty() || !trimmed.contains("->")) {
            continue
        }
        
        let parts = trimmed.split("->")
        if (parts.size < 2) {
            continue
        }
        
        var left = parts[0]
        while (!left.isEmpty() && (left[0] == spaceChar || left[0] == tabChar)) {
            left = left[1..]
        }
        while (!left.isEmpty() && (left[left.size - 1] == spaceChar || left[left.size - 1] == tabChar)) {
            left = left[0..(left.size - 1)]
        }
        
        // 第一个非终结符是起始符号
        if (startSymbol.isEmpty()) {
            startSymbol = left
        }
        
        var right = parts[1]
        while (!right.isEmpty() && (right[0] == spaceChar || right[0] == tabChar)) {
            right = right[1..]
        }
        while (!right.isEmpty() && (right[right.size - 1] == spaceChar || right[right.size - 1] == tabChar)) {
            right = right[0..(right.size - 1)]
        }
        
        let prods = ArrayList<String>()
        let prodParts = right.split('|')
        for (prod in prodParts) {
            var trimmedProd = prod
            while (!trimmedProd.isEmpty() && (trimmedProd[0] == spaceChar || trimmedProd[0] == tabChar)) {
                trimmedProd = trimmedProd[1..]
            }
            while (!trimmedProd.isEmpty() && (trimmedProd[trimmedProd.size - 1] == spaceChar || trimmedProd[trimmedProd.size - 1] == tabChar)) {
                trimmedProd = trimmedProd[0..(trimmedProd.size - 1)]
            }
            if (!trimmedProd.isEmpty()) {
                prods.add(trimmedProd)
            }
        }
        
        grammar[left] = prods
    }
    
    // 创建分析器
    let analyzer = LL1Analyzer(grammar, startSymbol)
    
    // 计算 FIRST 和 FOLLOW 集
    analyzer.computeFirst()
    analyzer.computeFollow()
    
    // 检查是否为 LL(1) 文法
    if (analyzer.isLL1()) {
        println("\n该文法是 LL(1) 文法")
        
        // 构造预测分析表
        analyzer.constructParsingTable()
        
        // 显示 FIRST 和 FOLLOW 集
        analyzer.displayTable()
        
        // 显示预测分析表
        let terminals = ArrayList<String>()
        terminals.add("a")
        terminals.add("b")
        terminals.add("$")
        analyzer.displayParsingTable(terminals)
        
        // 解析输入字符串
        let testInputs = ArrayList<String>()
        testInputs.add("ab")
        testInputs.add("b")
        
        for (inputStr in testInputs) {
            println("\n输入字符串: '${inputStr}'")
            let (success, process) = analyzer.parse(inputStr)
            
            if (success) {
                println("结果: 解析成功")
            } else {
                println("结果: 语法错误")
            }
            
            println("\n解析过程:")
            for (step in process) {
                println(step)
            }
        }
    } else {
        println("\n该文法不是 LL(1) 文法")
    }
}
