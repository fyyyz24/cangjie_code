import std.collection.*

// 上下文无关文法类，用于计算每个非终结符的 FIRST 集和 FOLLOW 集
class CFG {
    public var productions: HashMap<String, ArrayList<String>> = HashMap<String, ArrayList<String>>()
    public var nonTerminals: HashSet<String> = HashSet<String>()
    public var terminals: HashSet<String> = HashSet<String>()
    public var startSymbol: String = ""
    public var first: HashMap<String, HashSet<String>> = HashMap<String, HashSet<String>>()
    public var follow: HashMap<String, HashSet<String>> = HashMap<String, HashSet<String>>()

    // 初始化上下文无关文法
    public init(productionInput: ArrayList<String>) {
        parseProductions(productionInput)
        findTerminals()
        
        // 设置起始符号为第一个非终结符
        let firstNT = nonTerminals.iterator().next()
        if (firstNT.isSome()) {
            startSymbol = firstNT.getOrThrow()
        }
        
        // 初始化 FIRST 集和 FOLLOW 集
        for (nt in nonTerminals) {
            first[nt] = HashSet<String>()
            follow[nt] = HashSet<String>()
        }
        
        // 起始符号 FOLLOW 集包含结束符号
        if (!startSymbol.isEmpty()) {
            follow[startSymbol].add("$")
        }
    }

    // 解析文法产生式，提取非终结符和对应的候选式
    private func parseProductions(productionInput: ArrayList<String>): Unit {
        for (line in productionInput) {
            let parts = line.split("->")
            if (parts.size < 2) {
                continue
            }
            
            var left = parts[0]
            // 去除空白
            let spaceChar: UInt8 = ' '
            let tabChar: UInt8 = '\t'
            while (!left.isEmpty() && (left[0] == spaceChar || left[0] == tabChar)) {
                left = left[1..]
            }
            while (!left.isEmpty() && (left[left.size - 1] == spaceChar || left[left.size - 1] == tabChar)) {
                left = left[0..(left.size - 1)]
            }
            
            nonTerminals.add(left)
            
            var right = parts[1]
            // 去除空白
            while (!right.isEmpty() && (right[0] == spaceChar || right[0] == tabChar)) {
                right = right[1..]
            }
            while (!right.isEmpty() && (right[right.size - 1] == spaceChar || right[right.size - 1] == tabChar)) {
                right = right[0..(right.size - 1)]
            }
            
            let rights = right.split("|")
            let rightsList = ArrayList<String>()
            
            for (r in rights) {
                var trimmed = r
                while (!trimmed.isEmpty() && (trimmed[0] == spaceChar || trimmed[0] == tabChar)) {
                    trimmed = trimmed[1..]
                }
                while (!trimmed.isEmpty() && (trimmed[trimmed.size - 1] == spaceChar || trimmed[trimmed.size - 1] == tabChar)) {
                    trimmed = trimmed[0..(trimmed.size - 1)]
                }
                rightsList.add(trimmed)
            }
            
            productions[left] = rightsList
        }
    }

    // 从产生式中自动提取终结符
    private func findTerminals(): Unit {
        for ((_, rights) in productions) {
            for (production in rights) {
                // 跳过空串
                if (production == "ε") {
                    continue
                }
                
                // 按空格分割符号
                let symbols = production.split(' ')
                for (symbol in symbols) {
                    if (symbol.isEmpty()) {
                        continue
                    }
                    
                    // 如果不是非终结符且不是空串,就是终结符
                    if (!nonTerminals.contains(symbol) && symbol != "ε") {
                        // 检查是否是大写字母开头(非终结符通常是大写)
                        let charA: UInt8 = 'A'
                        let charZ: UInt8 = 'Z'
                        if (symbol.size > 0) {
                            let firstChar = symbol[0]
                            if (!(firstChar >= charA && firstChar <= charZ)) {
                                terminals.add(symbol)
                            }
                        }
                    }
                }
            }
        }
    }

    // 计算文法中每个非终结符的 FIRST 集
    public func computeFirst(): Unit {
        var changed = true
        
        while (changed) {
            changed = false
            
            for (nt in nonTerminals) {
                let prodsOpt = productions.get(nt)
                if (prodsOpt.isNone()) {
                    continue
                }
                
                let prods = prodsOpt.getOrThrow()
                for (production in prods) {
                    let beforeSize = first[nt].size
                    
                    // 如果产生式就是 ε
                    if (production == "ε") {
                        first[nt].add("ε")
                        if (first[nt].size > beforeSize) {
                            changed = true
                        }
                        continue
                    }
                    
                    // 将产生式按空格分割成符号,如果没有空格则整个字符串是一个符号
                    var symbolsList = ArrayList<String>()
                    let symbolsArr = production.split(' ')
                    for (s in symbolsArr) {
                        symbolsList.add(s)
                    }
                    
                    // 如果没有空格,尝试逐个字符处理(对于像"AB"这样的产生式)
                    if (symbolsList.size == 1 && symbolsList[0].size > 1) {
                        // 检查是否是连续的非终结符(都是大写字母)
                        var allNonTerminals = true
                        let charA: UInt8 = 'A'
                        let charZ: UInt8 = 'Z'
                        
                        for (c in symbolsList[0]) {
                            if (!(c >= charA && c <= charZ)) {
                                allNonTerminals = false
                                break
                            }
                        }
                        
                        // 如果都是大写字母,分割成单个字符
                        if (allNonTerminals) {
                            symbolsList = ArrayList<String>()
                            for (c in production) {
                                let charStr = charToString(c)
                                symbolsList.add(charStr)
                            }
                        }
                    }
                    
                    var allHaveEpsilon = true
                    
                    for (i in 0..symbolsList.size) {
                        let symbol = symbolsList[i]
                        
                        if (symbol.isEmpty()) {
                            continue
                        }
                        
                        if (symbol == "ε") {
                            first[nt].add("ε")
                            break
                        }
                        
                        if (terminals.contains(symbol)) {
                            // 终结符直接加入 FIRST 集
                            first[nt].add(symbol)
                            allHaveEpsilon = false
                            break
                        } else if (nonTerminals.contains(symbol)) {
                            // 将非终结符的 FIRST 集（去除空串）加入
                            let symbolFirstOpt = first.get(symbol)
                            if (symbolFirstOpt.isSome()) {
                                let symbolFirst = symbolFirstOpt.getOrThrow()
                                for (s in symbolFirst) {
                                    if (s != "ε") {
                                        first[nt].add(s)
                                    }
                                }
                                
                                // 如果不包含空串，停止
                                if (!symbolFirst.contains("ε")) {
                                    allHaveEpsilon = false
                                    break
                                }
                            } else {
                                allHaveEpsilon = false
                                break
                            }
                        } else {
                            // 未知符号,当作终结符处理
                            first[nt].add(symbol)
                            allHaveEpsilon = false
                            break
                        }
                        
                        // 如果是最后一个符号且所有都有空串
                        if (i == symbolsList.size - 1 && allHaveEpsilon) {
                            first[nt].add("ε")
                        }
                    }
                    
                    if (first[nt].size > beforeSize) {
                        changed = true
                    }
                }
            }
        }
    }

    // 计算文法中每个非终结符的 FOLLOW 集
    public func computeFollow(): Unit {
        var changed = true
        
        while (changed) {
            changed = false
            for (nt in nonTerminals) {
                let prodsOpt = productions.get(nt)
                if (prodsOpt.isNone()) {
                    continue
                }
                
                let prods = prodsOpt.getOrThrow()
                for (production in prods) {
                    let followOpt = follow.get(nt)
                    if (followOpt.isNone()) {
                        continue
                    }
                    
                    var followTemp = HashSet<String>()
                    for (s in followOpt.getOrThrow()) {
                        followTemp.add(s)
                    }
                    
                    // 将产生式按空格分割成符号
                    var symbolsList = ArrayList<String>()
                    let symbolsArr = production.split(' ')
                    for (s in symbolsArr) {
                        symbolsList.add(s)
                    }
                    
                    // 如果没有空格,尝试逐个字符处理(对于像"AB"这样的产生式)
                    if (symbolsList.size == 1 && symbolsList[0].size > 1) {
                        var allNonTerminals = true
                        let charA: UInt8 = 'A'
                        let charZ: UInt8 = 'Z'
                        
                        for (c in symbolsList[0]) {
                            if (!(c >= charA && c <= charZ)) {
                                allNonTerminals = false
                                break
                            }
                        }
                        
                        if (allNonTerminals) {
                            symbolsList = ArrayList<String>()
                            for (c in production) {
                                let charStr = charToString(c)
                                symbolsList.add(charStr)
                            }
                        }
                    }
                    
                    // 从右向左遍历产生式
                    for (i in 0..symbolsList.size) {
                        let idx = symbolsList.size - 1 - i
                        let symbol = symbolsList[idx]
                        
                        if (symbol.isEmpty()) {
                            continue
                        }
                        
                        if (nonTerminals.contains(symbol)) {
                            let beforeSize = follow[symbol].size
                            
                            // FOLLOW 集加入 followTemp
                            for (s in followTemp) {
                                follow[symbol].add(s)
                            }
                            
                            // 如果 FIRST 集包含空串
                            let symbolFirstOpt = first.get(symbol)
                            if (symbolFirstOpt.isSome() && symbolFirstOpt.getOrThrow().contains("ε")) {
                                let symbolFirst = symbolFirstOpt.getOrThrow()
                                for (s in symbolFirst) {
                                    if (s != "ε") {
                                        followTemp.add(s)
                                    }
                                }
                            } else if (symbolFirstOpt.isSome()) {
                                followTemp.clear()
                                for (s in symbolFirstOpt.getOrThrow()) {
                                    followTemp.add(s)
                                }
                            }
                            
                            if (follow[symbol].size > beforeSize) {
                                changed = true
                            }
                        } else if (terminals.contains(symbol)) {
                            followTemp.clear()
                            followTemp.add(symbol)
                        }
                    }
                }
            }
        }
    }

    // 展示 FIRST 和 FOLLOW 集
    public func displayFirstAndFollow(): Unit {
        println("\n文法的产生式规则:")
        for ((nt, prods) in productions) {
            for (prod in prods) {
                println("  ${nt} -> ${prod}")
            }
        }
        
        println("\nFIRST 和 FOLLOW 集:")
        println("+---------------+------------------+------------------+")
        println("| 非终结符      | FIRST 集         | FOLLOW 集        |")
        println("+---------------+------------------+------------------+")
        
        for (nt in nonTerminals) {
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
            
            // 格式化输出
            print("| ")
            print(nt)
            for (_ in 0..(13 - nt.size)) {
                print(" ")
            }
            print(" | ")
            print(firstStr)
            for (_ in 0..(16 - firstStr.size)) {
                print(" ")
            }
            print(" | ")
            print(followStr)
            for (_ in 0..(16 - followStr.size)) {
                print(" ")
            }
            println(" |")
        }
        
        println("+---------------+------------------+------------------+")
    }
}

// UInt8转String的辅助函数
func charToString(char: UInt8): String {
    let charA: UInt8 = 'a'
    let charZ: UInt8 = 'z'
    let charAUpper: UInt8 = 'A'
    let charZUpper: UInt8 = 'Z'
    let char0: UInt8 = '0'
    let char9: UInt8 = '9'
    let charSpace: UInt8 = ' '
    let charPlus: UInt8 = '+'
    let charMinus: UInt8 = '-'
    let charStar: UInt8 = '*'
    let charSlash: UInt8 = '/'
    let charLParen: UInt8 = '('
    let charRParen: UInt8 = ')'
    
    if (char >= charA && char <= charZ) {
        let offset = char - charA
        return "abcdefghijklmnopqrstuvwxyz"[Int64(offset)..Int64(offset + 1)]
    } else if (char >= charAUpper && char <= charZUpper) {
        let offset = char - charAUpper
        return "ABCDEFGHIJKLMNOPQRSTUVWXYZ"[Int64(offset)..Int64(offset + 1)]
    } else if (char >= char0 && char <= char9) {
        let offset = char - char0
        return "0123456789"[Int64(offset)..Int64(offset + 1)]
    } else if (char == charSpace) {
        return " "
    } else if (char == charPlus) {
        return "+"
    } else if (char == charMinus) {
        return "-"
    } else if (char == charStar) {
        return "*"
    } else if (char == charSlash) {
        return "/"
    } else if (char == charLParen) {
        return "("
    } else if (char == charRParen) {
        return ")"
    }
    
    return " "
}

// 主函数
main() {
    // 内置的文法字符串 - 使用多行字符串
    let grammarContent = """
S -> AB
A -> a | ε
B -> b
"""
    
    println("输入的文法:")
    let lines = grammarContent.split('\n')
    let productions = ArrayList<String>()
    
    for (line in lines) {
        let spaceChar: UInt8 = ' '
        let tabChar: UInt8 = '\t'
        let crChar: UInt8 = '\r'
        
        var trimmed = line
        while (!trimmed.isEmpty() && (trimmed[0] == spaceChar || trimmed[0] == tabChar || trimmed[0] == crChar)) {
            trimmed = trimmed[1..]
        }
        while (!trimmed.isEmpty() && (trimmed[trimmed.size - 1] == spaceChar || trimmed[trimmed.size - 1] == tabChar || trimmed[trimmed.size - 1] == crChar)) {
            trimmed = trimmed[0..(trimmed.size - 1)]
        }
        
        if (!trimmed.isEmpty() && trimmed.contains("->")) {
            productions.add(trimmed)
            println("  ${trimmed}")
        }
    }
    
    // 创建文法对象
    let cfg = CFG(productions)
    
    // 计算 FIRST 集和 FOLLOW 集
    cfg.computeFirst()
    cfg.computeFollow()
    
    // 打印结果
    cfg.displayFirstAndFollow()
}
